import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HUB = Path(__file__).resolve().parents[2]
SCRIPT = HUB / 'skills/skill-stocktake/scripts/stocktake.py'
spec = importlib.util.spec_from_file_location('stocktake', SCRIPT)
stocktake = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stocktake)


class StocktakeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.hub = Path(self.temp.name)
        self.skills = self.hub / 'skills'
        self.skill = self.skills / 'sample'
        self.skill.mkdir(parents=True)
        (self.skill / 'SKILL.md').write_text('---\nname: sample\ndescription: Use when testing.\n---\nBody\n')

    def test_duplicate_sources_keep_aliases_and_unknown_usage(self):
        result = stocktake.inventory([self.skills, self.skills])
        self.assertFalse(result['errors'])
        self.assertEqual(len(result['skills']), 1)
        self.assertEqual(len(result['skills'][0]['aliases']), 2)
        self.assertIsNone(result['skills'][0]['use_7d'])

    def test_support_files_and_removals_are_detected(self):
        old = stocktake.inventory([self.skills])
        (self.skill / 'reference.md').write_text('Changed support file')
        new = stocktake.inventory([self.skills])
        self.assertEqual(stocktake.changes(old, new)['changed'], [str(self.skill.resolve())])
        empty = dict(new, skills=[])
        self.assertEqual(stocktake.changes(new, empty)['removed'], [str(self.skill.resolve())])

    def test_missing_root_is_incomplete(self):
        result = stocktake.inventory([self.hub / 'absent'])
        self.assertEqual(result['status'], 'incomplete')
        self.assertTrue(result['errors'])

    def test_cli_protects_skill_sources_and_writes_external_snapshot(self):
        source = self.skill / 'SKILL.md'
        original = source.read_bytes()
        rejected = subprocess.run([sys.executable, str(SCRIPT), '--hub', str(self.hub), '--output', str(source)], capture_output=True)
        self.assertEqual(rejected.returncode, 1)
        self.assertEqual(source.read_bytes(), original)
        output = self.hub / 'audit.json'
        accepted = subprocess.run([sys.executable, str(SCRIPT), '--hub', str(self.hub), '--output', str(output)], capture_output=True)
        self.assertEqual(accepted.returncode, 0, accepted.stderr)
        self.assertEqual(json.loads(output.read_text())['status'], 'inventoried')

    def test_previous_roots_must_match(self):
        previous = self.hub / 'old.json'
        previous.write_text(json.dumps(stocktake.inventory([self.hub / 'missing'])))
        result = subprocess.run([sys.executable, str(SCRIPT), '--hub', str(self.hub), '--previous', str(previous)], capture_output=True)
        self.assertEqual(result.returncode, 1)

    def test_incomplete_current_snapshot_never_reports_removals(self):
        previous = self.hub / 'old.json'
        previous.write_text(json.dumps(stocktake.inventory([self.skills])))
        (self.skill / 'SKILL.md').write_text('Malformed metadata')
        result = subprocess.run([sys.executable, str(SCRIPT), '--hub', str(self.hub), '--previous', str(previous)], capture_output=True)
        self.assertEqual(result.returncode, 1)
        self.assertIn(b'comparison refused', result.stderr)
        self.assertEqual(result.stdout, b'')


if __name__ == '__main__':
    unittest.main()
