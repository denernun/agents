import importlib.util
import json
from pathlib import Path
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
        with self.assertRaises(ValueError): self.call(format='toml', remove=True)
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


if __name__ == '__main__':
    unittest.main()
