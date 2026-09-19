import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib
import unittest

spec = importlib.util.spec_from_file_location('config', Path(__file__).parents[1] / 'agenthub_config.py')
config = importlib.util.module_from_spec(spec)
spec.loader.exec_module(config)


class ConfigTests(unittest.TestCase):
    def test_partial_refresh_preserves_other_owned_servers(self):
        for fmt in ('json', 'toml'):
            with self.subTest(format=fmt):
                self.path = self.root / ('partial.' + fmt)
                self.call(format=fmt, servers={'codegraph': {'command': 'old'}, 'other': {'command': 'keep'}})
                self.call(format=fmt, partial=True, servers={'codegraph': {'command': 'new'}})
                raw = self.path.read_text()
                parsed = tomllib.loads(raw) if fmt == 'toml' else json.loads(raw)
                servers = parsed['mcp_servers' if fmt == 'toml' else 'mcpServers']
                self.assertEqual(servers['other']['command'], 'keep')
                self.assertEqual(servers['codegraph']['command'], 'new')
                self.call(format=fmt, partial=True, servers={'codegraph': {'command': 'new'}})
                self.assertEqual(self.path.read_text(), raw)

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.path = self.root / 'project' / 'config.json'
        self.path.parent.mkdir()

    def call(self, **kw):
        return config.update(dict(hub=str(self.root), path=str(self.path), **kw))

    def test_corrupt_state_file_does_not_abort_install(self):
        self.call(format='text', text='generated')
        state = next((self.root / '.agenthub-state').glob('*.json'))
        state.write_bytes(b'\x00' * len(state.read_bytes()))
        result = self.call(format='text', text='generated')
        self.assertFalse(result['changed'])
        self.assertTrue(any('Preserved manual file' in message for message in result['messages']))
        self.assertEqual(self.path.read_text(encoding='utf-8'), 'generated')

    def test_zero_filled_file_is_rewritten_not_preserved(self):
        self.call(format='text', text='generated')
        self.path.write_bytes(b'\x00' * 32)
        result = self.call(format='text', text='regenerated')
        self.assertTrue(result['changed'])
        self.assertEqual(self.path.read_text(encoding='utf-8'), 'regenerated')

    def test_manual_servers_and_top_level_survive(self):
        self.path.write_text(json.dumps({'model': 'keep', 'mcp': {'manual': {'command': ['custom']}}}))
        self.call(property='mcp', servers={'context7': {'command': ['new']}})
        self.call(property='mcp', remove=True)
        result = json.loads(self.path.read_text())
        self.assertEqual(result, {'model': 'keep', 'mcp': {'manual': {'command': ['custom']}}})

    def test_collision_and_manual_edit_preserved(self):
        self.path.write_text('{"mcpServers":{"context7":{"command":"custom"}}}')
        self.call(servers={'context7': {'command': 'hub'}})
        self.assertEqual(json.loads(self.path.read_text())['mcpServers']['context7']['command'], 'custom')
        self.call(servers={'new': {'command': 'hub'}})
        result = json.loads(self.path.read_text()); result['mcpServers']['new']['command'] = 'edited'
        self.path.write_text(json.dumps(result))
        self.call(remove=True)
        self.assertIn('new', json.loads(self.path.read_text())['mcpServers'])

    def test_invalid_json_is_untouched(self):
        self.path.write_text('{broken')
        with self.assertRaises(json.JSONDecodeError): self.call(servers={})
        self.assertEqual(self.path.read_text(), '{broken')

    def test_legacy_adoption_explicit_and_backed_up(self):
        old = {'command': 'cmd', 'args': ['/c','npx','-y','@upstash/context7-mcp']}
        self.path.write_text(json.dumps({'mcpServers': {'context7': old, 'mongodb': {'command': 'custom'}}}))
        self.call(adopt=True, managed=['context7','mongodb'], servers={})
        self.assertEqual(list(json.loads(self.path.read_text())['mcpServers']), ['mongodb'])
        self.assertEqual(len(list((self.root / '.agenthub-state/backups').rglob('*.json'))), 1)

    def test_toml_roundtrip_and_uninstall(self):
        self.path = self.path.with_suffix('.toml')
        self.path.write_text('model = "manual"\n[mcp_servers.custom]\ncommand="keep"\n')
        server = {'command': 'C:\\Program Files\\node.exe', 'args': ['x', 'a"b'], 'env': {'KEY': 'line\nnext'}}
        self.call(format='toml', servers={'test': server})
        self.assertEqual(tomllib.loads(self.path.read_text())['mcp_servers']['test'], server)
        self.assertFalse(self.call(format='toml', servers={'test': server})['changed'])
        self.call(format='toml', remove=True)
        self.assertEqual(tomllib.loads(self.path.read_text())['mcp_servers'], {'custom': {'command': 'keep'}})

    def test_edited_toml_and_invalid_toml_preserved(self):
        self.path = self.path.with_suffix('.toml')
        self.call(format='toml', servers={'x': {'command': 'original'}})
        self.path.write_text(self.path.read_text().replace('original', 'manual'))
        old = self.path.read_text()
        result = self.call(format='toml', remove=True)
        self.assertFalse(result['changed'])
        self.assertTrue(any('manually changed AgentHub TOML block' in message
                            for message in result['messages']))
        self.assertEqual(self.path.read_text(), old)
        self.path.write_text('broken = [')
        with self.assertRaises(tomllib.TOMLDecodeError): self.call(format='toml', servers={})

    def test_dry_run_writes_nothing(self):
        self.call(servers={'x': {'command': 'x'}}, dry=True)
        self.assertFalse(self.path.exists())
        self.assertFalse((self.root / '.agenthub-state').exists())

    def test_legacy_global_cleanup_preserves_other_servers(self):
        self.path = self.path.with_suffix('.toml')
        self.path.write_text('[mcp_servers.codegraph]\ncommand="cmd"\nargs=["/c","codegraph","serve","--mcp"]\n[mcp_servers.manual]\ncommand="keep"\n')
        self.call(format='toml', legacy_global=True, remove=True)
        self.assertEqual(list(tomllib.loads(self.path.read_text())['mcp_servers']), ['manual'])

    def test_text_manual_edit_preserved(self):
        self.call(format='text', text='generated')
        self.path.write_text('manual')
        self.call(format='text', remove=True)
        self.assertEqual(self.path.read_text(), 'manual')

    def test_safe_text_patch_updates_only_missing_managed_section(self):
        original = '# Project\n\n## Skills\n- existing\n\n## Local\nmanual note\n'
        self.path.write_text(original)
        self.call(
            format='text',
            text='ignored for a safe patch',
            text_patch={
                'marker': '## Eficiência de execução',
                'anchor': r'^## Skills\b',
                'content': '## Eficiência de execução\n- safe',
            },
        )
        expected = '# Project\n\n## Eficiência de execução\n- safe\n\n## Skills\n- existing\n\n## Local\nmanual note\n'
        self.assertEqual(self.path.read_text(encoding='utf-8'), expected)
        self.call(
            format='text',
            text='ignored for a safe patch',
            text_patch={
                'marker': '## Eficiência de execução',
                'anchor': r'^## Skills\b',
                'content': '## Eficiência de execução\n- safe',
            },
        )
        self.assertEqual(self.path.read_text(encoding='utf-8'), expected)

    def test_safe_text_patch_preserves_file_without_unique_anchor(self):
        self.path.write_text('# Project\n## Skills\n## Skills\n')
        result = self.call(
            format='text',
            text='ignored',
            text_patch={
                'marker': '## Eficiência de execução',
                'anchor': r'^## Skills\b',
                'content': '## Eficiência de execução\n- safe',
            },
        )
        self.assertFalse(result['changed'])
        self.assertNotIn('Eficiência', self.path.read_text())

    def test_ownership_is_reclaimed_when_disk_matches_desired(self):
        # Regression: ownership used to be a one-way ratchet. A single
        # divergence (another tool rewriting the config, a lost state file) made
        # the hub treat the entry as a manual edit forever, so it could never be
        # updated or pruned again even once the payload matched exactly.
        server = {'command': 'cmd', 'args': ['/c', 'x']}
        self.call(servers={'s': server}, managed=['s'])
        # Simulate the state being lost while the file keeps the hub's payload.
        state = next((self.root / '.agenthub-state').glob('*.json'))
        state.write_text(json.dumps({'path': str(self.path), 'servers': {}}))
        result = self.call(servers={'s': server}, managed=['s'])
        self.assertFalse(any('manual' in m for m in result['messages']))
        # Ownership restored, so a later removal actually prunes the entry.
        self.call(servers={}, managed=['s'], remove=True)
        self.assertEqual(json.loads(self.path.read_text())['mcpServers'], {})

    def test_genuine_manual_server_edit_is_still_preserved(self):
        # The reclaim above must not swallow real user edits.
        self.call(servers={'s': {'command': 'hub'}}, managed=['s'])
        edited = json.loads(self.path.read_text())
        edited['mcpServers']['s'] = {'command': 'mine'}
        self.path.write_text(json.dumps(edited))
        result = self.call(servers={'s': {'command': 'hub'}}, managed=['s'])
        self.assertTrue(any('manual' in m for m in result['messages']))
        self.assertEqual(json.loads(self.path.read_text())['mcpServers']['s']['command'], 'mine')

    def test_crlf_payload_is_written_verbatim_and_stays_owned(self):
        # Regression: atomic() used write_text(), so a CRLF payload (every
        # template and PowerShell here-string) landed on disk as CR CR LF and
        # never compared equal to state again. Every tracked file then looked
        # manually edited and silently stopped being updated.
        text = '# Title\r\n\r\n## Section\r\n- item\r\n'
        result = self.call(format='text', text=text)
        self.assertTrue(result['changed'])
        self.assertEqual(self.path.read_bytes(), text.encode('utf-8'))
        self.assertNotIn(b'\r\r\n', self.path.read_bytes())
        # Second identical run must be a no-op, proving state matches the disk.
        again = self.call(format='text', text=text)
        self.assertFalse(again['changed'])
        self.assertEqual(again['messages'], [])

    def test_owned_text_is_rewritten_when_the_template_changes(self):
        # A hub-written file must keep tracking the hub: editing a template has
        # to reach the project on the next run.
        self.call(format='text', text='v1\r\n')
        result = self.call(format='text', text='v2\r\n')
        self.assertTrue(result['changed'])
        self.assertEqual(self.path.read_bytes(), b'v2\r\n')

    def test_patched_untracked_file_never_becomes_hub_owned(self):
        # Injecting the managed section into a file the hub did not create must
        # not promote it to "owned", or the next run would replace its content.
        original = '# Legacy\r\n\r\n## Skills\r\n- keep\r\n'
        self.path.write_bytes(original.encode('utf-8'))
        patch = {'marker': '## Managed', 'anchor': r'^## Skills\b', 'content': '## Managed\n- x'}
        self.call(format='text', text='REPLACEMENT', text_patch=patch)
        self.assertIn('## Managed', self.path.read_text(encoding='utf-8'))
        self.assertIn('- keep', self.path.read_text(encoding='utf-8'))
        result = self.call(format='text', text='REPLACEMENT', text_patch=patch)
        self.assertFalse(result['changed'])
        self.assertNotIn('REPLACEMENT', self.path.read_text(encoding='utf-8'))

    def test_toml_block_is_found_on_a_crlf_file(self):
        # An LF-only pattern would miss the block on a CRLF file and append a
        # second one, producing duplicate markers.
        self.path = self.path.with_suffix('.toml')
        self.call(format='toml', servers={'x': {'command': 'a'}})
        crlf = self.path.read_bytes().replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
        self.path.write_bytes(crlf)
        self.call(format='toml', servers={'x': {'command': 'a'}})
        body = self.path.read_text(encoding='utf-8')
        self.assertEqual(body.count(config.BEGIN), 1)
        self.assertEqual(body.count(config.END), 1)

    def test_main_decodes_non_utf8_stdin_as_utf8(self):
        # PowerShell pipes UTF-8 bytes; a Windows Python reading stdin with the
        # active code page turns non-ASCII rule text into lone surrogates and
        # fails on write (see decorator-placement.mdc). PYTHONIOENCODING pins
        # the legacy behaviour so this stays a regression test.
        script = Path(__file__).parents[1] / 'agenthub_config.py'
        text = 'decorator \u2705 placement \u274c marker\n'
        request = json.dumps({'hub': str(self.root), 'path': str(self.path),
                              'format': 'text', 'text': text})
        env = {**os.environ, 'PYTHONIOENCODING': 'cp1252:surrogateescape'}
        result = subprocess.run([sys.executable, str(script)], input=request.encode('utf-8'),
                                capture_output=True, env=env)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.path.read_text(encoding='utf-8'), text)


if __name__ == '__main__':
    unittest.main()
