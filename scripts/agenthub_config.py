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
    """Write text verbatim. newline='' is required: without it Python turns
    every '\\n' into os.linesep, and a payload that already carries CRLF (every
    template and here-string coming from PowerShell) lands on disk as CR CR LF.
    Reading that back through universal newlines yields '\\n\\n', which never
    equals the CRLF stored in state, so every tracked file would look manually
    edited forever and stop being updated."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + '.tmp-' + uuid.uuid4().hex)
    with open(temporary, 'w', encoding='utf-8', newline='') as stream:
        stream.write(text)
    os.replace(temporary, path)


def read_state(state_path):
    """Our own metadata is advisory: a corrupt or unreadable state file must
    never abort an install. Falling back to {} treats every existing entry as
    unowned/manual, which is the conservative outcome."""
    if not state_path.exists():
        return {}
    try:
        return json.loads(state_path.read_text(encoding='utf-8'))
    except (ValueError, OSError):
        return {}


def read_previous(path):
    """Return the file's text, or None when it is absent or unrecoverable.

    An unclean shutdown can leave a freshly written file allocated but filled
    with NUL bytes. Such a file has no user content, so it is treated as absent
    and rewritten, instead of failing the parse or being preserved as garbage.

    newline='' matters as much as it does in atomic(): reading with universal
    newlines would collapse the CRLF on disk to '\\n' and never match the CRLF
    held in state, reintroducing the "everything looks manually edited" bug
    from the other direction."""
    if not path.exists():
        return None
    raw = path.read_bytes()
    if not raw or not raw.strip(b'\x00'):
        return None
    with open(path, 'r', encoding='utf-8-sig', newline='') as stream:
        return stream.read()


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


def unify(text):
    """Line endings normalised to LF, for comparing content regardless of the
    style an editor happened to leave behind."""
    if text is None:
        return None
    return text.replace('\r\n', '\n')


def update(request):
    path = Path(request['path']).absolute()
    root = Path(request['hub']).absolute() / '.agenthub-state'
    ident = hashlib.sha256(str(path).casefold().encode()).hexdigest()
    state_path = root / (ident + '.json')
    state = read_state(state_path)
    previous_text = read_previous(path)
    exists = previous_text is not None
    old = previous_text or ''
    desired = request.get('servers', {})
    if request.get('partial'):
        # A targeted refresh must retain other owned servers and their ownership.
        desired = {**state.get('servers', {}), **desired}
    remove = request.get('remove', False)
    managed = request.get('managed', [])
    adopt = request.get('adopt', False)
    messages = []
    if request.get('format') == 'text':
        previous = state.get('text')
        text_patch = request.get('text_patch')
        # Adoption is an explicit, user-invoked request (-AdoptLegacyConfigs) and
        # only ever targets paths the hub itself generates, so it must not depend
        # on finding a marker string in the body: templates such as
        # decorator-placement.mdc legitimately mention neither the hub nor its
        # path, and requiring one left those files permanently stuck as "manual"
        # with no way to hand them back. The pre-write backup under
        # .agenthub-state/backups is the recovery path.
        recognized = adopt
        # "Owned" means the bytes on disk are exactly what we recorded writing.
        # Only then may the hub replace the file wholesale; anything else is
        # either absent (write it) or user-modified (preserve it).
        owned = exists and previous is not None and old == previous
        if text_patch and exists and not owned and not recognized:
            # Untracked/legacy file: never clobber it. Inject the section once,
            # anchored, or leave it alone if it is already there.
            if text_patch['marker'] in old:
                return {'changed': False, 'messages': []}
            matches = list(re.finditer(text_patch['anchor'], old, flags=re.MULTILINE))
            if len(matches) != 1:
                return {'changed': False, 'messages': [
                    'Preserved manual file; safe text patch anchor missing or ambiguous: ' + str(path)
                ]}
            match = matches[0]
            patch = text_patch['content'].rstrip() + '\n\n'
            new = old[:match.start()] + patch + old[match.start():]
            # Deliberately does NOT claim ownership: this file was not created
            # by the hub, so it must never become a candidate for wholesale
            # rewriting. The injected marker makes the next run a no-op.
            new_state = dict(state)
            new_state['path'] = str(path)
        else:
            # Absent, hub-owned, or adopted: write the full desired text. This is
            # what makes a template edit in the hub reach every project on the
            # next run instead of being silently skipped.
            if exists and not owned and not recognized:
                return {'changed': False, 'messages': ['Preserved manual file: ' + str(path)]}
            new = '' if remove else request['text']
            new_state = {'path': str(path), 'text': new}
    elif request.get('format') == 'toml':
        parsed = tomllib.loads(old)
        # \r? everywhere: the file keeps whatever line endings an editor left,
        # and an LF-only pattern would silently fail to find an existing block
        # on a CRLF file, then append a second one.
        pattern = re.compile(r'(?ms)^# BEGIN AgentHub MCP\r?\n.*?^# END AgentHub MCP(?:\r?\n|$)')
        blocks = list(pattern.finditer(old))
        if old.count(BEGIN) != len(blocks) or old.count(END) != len(blocks) or len(blocks) > 1:
            raise ValueError('Invalid AgentHub TOML markers')
        block = blocks[0].group() if blocks else ''
        # Compare on content, not on line-ending style, so a CRLF round-trip
        # through an editor is not mistaken for a manual edit. Without `adopt`
        # an unrecognised block is preserved; with it the block is rebuilt, which
        # is the only way to recover a file whose state was lost (otherwise the
        # block stays untouchable forever, exactly like the JSON ratchet).
        if block and unify(block) != unify(state.get('block')) and not adopt:
            # Other local tools can append their own MCP table inside the
            # AgentHub marker block. Treat that exactly like a manual edit:
            # preserve it and let the wider install continue rather than
            # failing a dry run or risking removal of that tool's settings.
            return {'changed': False, 'messages': [
                'Preserved manually changed AgentHub TOML block: ' + str(path)
            ]}
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
        parsed = json.loads(old) if exists else {}
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
        # Reclaim entries that are already byte-identical to what we are about to
        # write. Ownership only records authorship, and losing it used to be
        # permanent: one divergence (another tool reformatting the file, a state
        # file lost) left the entry flagged "manual" forever, so the hub could
        # neither update nor prune it again even once the payload matched. If the
        # value on disk is exactly our intended payload it is not a foreign edit,
        # so adopting it changes nothing on disk and restores manageability.
        for name, value in current.items():
            if name not in owned and name in desired and value == desired[name]:
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
    for stream in (sys.stdin, sys.stdout):
        if hasattr(stream, 'reconfigure'):
            stream.reconfigure(encoding='utf-8', errors='surrogateescape')
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
