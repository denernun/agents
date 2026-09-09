"""Smoke test over real MCP stdio; prints bounded output, never credentials."""
import argparse
import json
import os
from pathlib import Path
import queue
import subprocess
import threading
import sys

sys.stdout.reconfigure(encoding='utf-8')

parser = argparse.ArgumentParser()
parser.add_argument('project')
parser.add_argument('--query')
parser.add_argument('--expect', help='Required text in the response (case sensitive)')
args = parser.parse_args()
env = dict(os.environ, DO_NOT_TRACK='1', CODEGRAPH_NO_DAEMON='1', CODEGRAPH_NO_DOWNLOAD='1')
proc = subprocess.Popen(['cmd', '/c', 'codegraph', 'serve', '--mcp', '--no-watch', '--path', str(Path(args.project).resolve())],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, encoding='utf-8', env=env)
responses = queue.Queue()
def read():
    for line in proc.stdout:
        try:
            responses.put(json.loads(line))
        except json.JSONDecodeError:
            pass
threading.Thread(target=read, daemon=True).start()
def send(method, params, ident=None):
    payload = dict(jsonrpc='2.0', method=method, params=params)
    if ident is not None:
        payload['id'] = ident
    proc.stdin.write(json.dumps(payload) + '\n')
    proc.stdin.flush()
    if ident is None:
        return
    while True:
        response = responses.get(timeout=90)
        if response.get('id') == ident:
            if 'error' in response:
                raise RuntimeError(response['error'])
            return response['result']
try:
    init = send('initialize', {'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'agenthub-smoke','version':'1'}}, 1)
    print('Handshake:', json.dumps(init.get('serverInfo')))
    send('notifications/initialized', {})
    tools = send('tools/list', {}, 2)['tools']
    explore = next(t for t in tools if t['name'] == 'codegraph_explore')
    print('Tools:', ', '.join(t['name'] for t in tools))
    if args.query:
        result = send('tools/call', {'name': explore['name'], 'arguments': {'query':args.query, 'projectPath':str(Path(args.project).resolve())}}, 3)
        if result.get('isError'):
            raise RuntimeError(result)
        body = '\n'.join(c.get('text','') for c in result.get('content', []))
        if args.expect and args.expect not in body:
            raise AssertionError('Expected response text missing: ' + args.expect)
        print('Response chars:', len(body))
        print(body[:7000])
    else:
        print(json.dumps(explore['inputSchema']))
finally:
    proc.stdin.close()
    try:
        proc.wait(timeout=15)
    except subprocess.TimeoutExpired:
        subprocess.run(['taskkill','/PID',str(proc.pid),'/T','/F'], capture_output=True)
