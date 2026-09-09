"""Conservative config writer. Python 3.11+, standard library only.

Receives requests on stdin so credentials never appear in command arguments.
State and backups stay in the hub's ignored .agenthub-state directory.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import tomllib
import uuid


def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp-' + uuid.uuid4().hex)
    temporary.write_text(text, encoding='utf-8')
    os.replace(temporary, path)


def legacy(name, value):
    """Recognize old hub launch signatures, never claim a name alone."""
    if not isinstance(value, dict):
        return False
    command = value.get('command', '')
    args = value.get('args', [])
    vector = command if isinstance(command, list) else [command, *args]
    text = ' '.join(str(x) for x in vector).lower()
    packages = {'context7': '@upstash/context7-mcp',
                'filesystem': '@modelcontextprotocol/server-filesystem',
                'mongodb': 'mongodb-mcp-server', 'openapi': '@ivotoby/openapi-mcp-server',
                'playwright': '@playwright/mcp', 'coreui': '@coreui/docs-mcp'}
    if name == 'codegraph':
        return 'codegraph' in text and 'serve' in vector and '--mcp' in vector
    return name in packages and packages[name] in text


def render_toml(servers):
    lines = []
    for name, server in sorted(servers.items()):
        lines.append('[mcp_servers.' + json.dumps(name) + ']')
        for key in ('command', 'args', 'cwd', 'enabled', 'startup_timeout_sec'):
            if key in server:
                lines.append(key + ' = ' + json.dumps(server[key], ensure_ascii=False))
        if server.get('env'):
            lines.append('[mcp_servers.' + json.dumps(name) + '.env]')
            for key, value in sorted(server['env'].items()):
                lines.append(json.dumps(key) + ' = ' + json.dumps(str(value), ensure_ascii=False))
        lines.append('')
    return '\n'.join(lines)


BEGIN = '# BEGIN AgentHub MCP'
END = '# END AgentHub MCP'


def update(request):
    path = Path(request['path']).absolute()
    root = Path(request['hub']).absolute() / '.agenthub-state'
    ident = hashlib.sha256(str(path).casefold().encode()).hexdigest()
    state_path = root / (ident + '.json')
    state = json.loads(state_path.read_text(encoding='utf-8')) if state_path.exists() else {}
    old = path.read_text(encoding='utf-8-sig') if path.exists() else ''
    desired = request.get('servers', {})
    remove = request.get('remove', False)
    managed = request.get('managed', [])
    adopt = request.get('adopt', False)
    messages = []
    if request.get('format') == 'text':
        previous = state.get('text')
        recognized = adopt and ('D:\\AGENTS' in old or 'AgentHub' in old or 'Install-AgentHub' in old)
        if path.exists() and old != previous and not recognized:
            return {'changed': False, 'messages': ['Preserved manual file: ' + str(path)]}
        new = '' if remove else request['text']
        new_state = {'path': str(path), 'text': new}
    elif request.get('format') == 'toml':
        parsed = tomllib.loads(old)
        pattern = re.compile(r'(?ms)^# BEGIN AgentHub MCP\n.*?^# END AgentHub MCP(?:\n|$)')
        blocks = list(pattern.finditer(old))
        if old.count(BEGIN) != len(blocks) or old.count(END) != len(blocks) or len(blocks) > 1:
            raise ValueError('Invalid AgentHub TOML markers')
        block = blocks[0].group() if blocks else ''
        if block and block != state.get('block'):
            raise ValueError('Managed TOML block changed manually; preserving file')
        base = pattern.sub('', old)
        if request.get('legacy_global'):
            eligible = set()
            for name in ('codegraph', 'context7'):
                value = parsed.get('mcp_servers', {}).get(name, {})
                if legacy(name, value) and set(value) <= {'command', 'args'} and value.get('command') == 'cmd':
                    args = value.get('args', [])
                    if (name == 'codegraph' and args == ['/c', 'codegraph', 'serve', '--mcp']) or (
                        name == 'context7' and args[:4] == ['/c', 'npx', '-y', '@upstash/context7-mcp']
                        and (len(args) == 4 or (len(args) == 6 and args[4] == '--api-key'))):
                        eligible.add(name)
            sections = re.split(r'(?m)(?=^\[)', base)
            kept = []
            for section in sections:
                header = re.match(r'^\[mcp_servers\.([a-z0-9_-]+)\]\s*\n', section)
                if header and header.group(1) in eligible:
                    continue
                kept.append(section)
            base = ''.join(kept)
            tomllib.loads(base)
        existing = tomllib.loads(base).get('mcp_servers', {})
        selected = {}
        if not remove:
            for name, value in desired.items():
                if name in existing:
                    messages.append('Preserved manual MCP: ' + name)
                else:
                    selected[name] = value
        new_block = BEGIN + '\n' + render_toml(selected) + END + '\n' if selected else ''
        new = base.rstrip() + ('\n\n' if base.strip() and new_block else '') + new_block
        tomllib.loads(new)
        new_state = {'path': str(path), 'block': new_block, 'servers': selected}
    else:
        parsed = json.loads(old) if path.exists() else {}
        if not isinstance(parsed, dict):
            raise ValueError('Config must be an object')
        prop = request.get('property', 'mcpServers')
        current = parsed.get(prop, {})
        if not isinstance(current, dict):
            raise ValueError('MCP map must be an object')
        previous = state.get('servers', {})
        owned = dict(previous)
        if adopt:
            for name, value in current.items():
                if name in managed and name not in owned and legacy(name, value):
                    owned[name] = value
        next_owned = {}
        for name, value in list(current.items()):
            if name in owned and value == owned[name]:
                if remove or name not in desired:
                    del current[name]
            elif name in owned:
                messages.append('Preserved manually modified MCP: ' + name)
        if not remove:
            for name, value in desired.items():
                if name not in current or (name in owned and current[name] == owned[name]):
                    current[name] = value
                    next_owned[name] = value
                else:
                    messages.append('Preserved manual MCP: ' + name)
        parsed[prop] = current
        new = json.dumps(parsed, ensure_ascii=False, indent=2) + '\n'
        new_state = {'path': str(path), 'servers': next_owned}
    if request.get('dry'):
        return {'changed': old != new, 'messages': messages}
    if new != old:
        if path.exists():
            backup = root / 'backups' / ident / (uuid.uuid4().hex + path.suffix)
            atomic(backup, old)
        # Persist intended ownership first; a failed write leaves a conservative
        # state mismatch instead of an untracked managed block on disk.
        atomic(state_path, json.dumps(new_state, ensure_ascii=False, indent=2))
        if remove and request.get('format') == 'text':
            path.unlink(missing_ok=True)
        else:
            atomic(path, new)
    else:
        atomic(state_path, json.dumps(new_state, ensure_ascii=False, indent=2))
    return {'changed': old != new, 'messages': messages}


def main():
    request = json.load(sys.stdin)
    try:
        if request.get('action') in ('validate-toml', 'inspect-toml'):
            with open(request['path'], 'rb') as stream:
                parsed = tomllib.load(stream)
            servers = parsed.get('mcp_servers', {})
            result = {'valid': True, 'servers': list(servers),
                      'disabled': [name for name, value in servers.items() if value.get('enabled') is False]}
        else:
            result = update(request)
        print(json.dumps(result))
    except Exception as error:
        # Parser messages can contain source text and credentials.
        print(json.dumps({'error': type(error).__name__, 'path': request.get('path'),
                          'message': 'Config update stopped; existing file preserved. Check syntax or manual edits.'}))
        sys.exit(1)


if __name__ == '__main__':
    main()
