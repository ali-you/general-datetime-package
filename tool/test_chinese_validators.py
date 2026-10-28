"""Offline failure-path tests for pinned Chinese data and comparison validators."""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def generator(root):
    spec = importlib.util.spec_from_file_location('chinese_generator', ROOT / 'tool/generate_chinese_calendar.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.ROOT = root
    return module


class ChineseValidatorTests(unittest.TestCase):
    def test_missing_offline_source_fails_without_generating_a_table(self):
        with tempfile.TemporaryDirectory(prefix='chinese-offline-') as folder:
            root = Path(folder)
            module = generator(root)
            with patch.object(sys, 'argv', ['generator', '--offline', '--check']):
                with self.assertRaisesRegex(ValueError, 'not cached'):
                    module.main()
            self.assertFalse((root / 'packages').exists())

    def test_tampered_source_fails_its_pin_before_any_generated_output(self):
        with tempfile.TemporaryDirectory(prefix='chinese-pin-') as folder:
            root = Path(folder)
            cache = root / 'tool/.chinese-cache/ChineseLunisolarCalendar.cs'
            cache.parent.mkdir(parents=True)
            cache.write_bytes(b'not the pinned Microsoft source')
            module = generator(root)
            with patch.object(sys, 'argv', ['generator', '--offline', '--check']):
                with self.assertRaisesRegex(ValueError, 'hash mismatch'):
                    module.main()
            self.assertFalse((root / 'packages').exists())

    @unittest.skipUnless(shutil.which('node'), 'Node is required for the ICU validator')
    def test_comparison_check_rejects_drift_without_overwriting_the_baseline(self):
        baseline = ROOT / 'docs/chinese-icu-comparison.json'
        original = baseline.read_bytes()
        data = json.loads(original)
        data['icuVersion'] = subprocess.check_output(
            ['node', '-p', 'process.versions.icu'], text=True).strip()
        data['checkedDays'] += 1
        with tempfile.TemporaryDirectory(prefix='chinese-baseline-') as folder:
            report = Path(folder) / 'changed-report.json'
            report.write_text(json.dumps(data), encoding='utf-8')
            before = report.read_bytes()
            result = subprocess.run(['node', str(ROOT / 'tool/validate_chinese_oracle.cjs'),
                                     '--check', str(report)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('comparison changed: checkedDays', result.stderr)
            self.assertEqual(report.read_bytes(), before)
        self.assertEqual(baseline.read_bytes(), original)


if __name__ == '__main__':
    unittest.main()
