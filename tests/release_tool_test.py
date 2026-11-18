#!/usr/bin/env python3
"""tools/release.py on a throwaway copy of this checkout: a Hyprflip pin and an OmaCards release, or nothing."""
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
# The whole plugin, as omarchy plugin validate checks it, and this checkout's tool.
FILES = subprocess.run(['git', '-C', str(ROOT), 'ls-files', '--cached', '--others', '--exclude-standard'], check=True,
                       capture_output=True, text=True).stdout.split()
COMMIT = 'c' * 40


class ReleaseToolTest(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        for name in FILES:
            if not (ROOT / name).is_file(): continue
            (self.root / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, self.root / name)
        # As after a release: no Unreleased section.
        changelog = (self.root / 'CHANGELOG.md').read_text()
        (self.root / 'CHANGELOG.md').write_text(re.sub(r'^## Unreleased\n.*?(?=^## )', '', changelog, flags=re.M | re.S))
        self.git('init', '--quiet', '--initial-branch', 'main')
        self.git('config', 'user.name', 'Release Test')
        self.git('config', 'user.email', 'release@example.invalid')
        self.git('add', '.')
        self.git('commit', '--quiet', '-m', 'released')
        self.before = self.git('rev-parse', 'HEAD')
        self.pin = re.search(r'hyprflipPin: "([0-9a-f]{40})"', self.read('Service.qml')).group(1)
        self.minimum = re.search(r'hyprflipMinimum: "([^"]+)"', self.read('Service.qml')).group(1)

    def git(self, *args):
        return subprocess.run(['git', '-C', str(self.root), *args], check=True, capture_output=True, text=True).stdout.strip()

    def read(self, name): return (self.root / name).read_text()

    def tool(self, *args):
        return subprocess.run([sys.executable, str(self.root / 'tools/release.py'), *args], capture_output=True, text=True,
                              timeout=120)

    def test_pin_moves_every_place_that_names_the_tested_hyprflip_and_commits(self):
        result = self.tool('pin', 'v0.3.0-rc.27', '--commit', COMMIT, '--note', 'Cards say which program manages them.')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(self.pin, self.read('Service.qml') + self.read('README.md'))
        self.assertIn(f'hyprflipPin: "{COMMIT}"', self.read('Service.qml'))
        self.assertIn('and was tested with Hyprflip 0.3.0-rc.27.\n', self.read('README.md'))
        for fixture in ('tests/fake-installer.py', 'tests/render.qml'):
            self.assertRegex(self.read(fixture), r'Hyprflip v0\.3\.0-rc\.27[\'"]')
        entry = self.read('CHANGELOG.md').split('## Unreleased\n\n', 1)[1].split('\n\n', 1)[0]
        self.assertTrue(entry.startswith('- Pin Hyprflip to [`v0.3.0-rc.27`]'), entry)
        self.assertIn(f'(`{COMMIT}`).', entry.replace('\n  ', ' '))
        self.assertIn(f'Cards say which program manages them. Hyprflip {self.minimum} or later still counts as current.',
                      entry.replace('\n  ', ' '))
        self.assertTrue(all(len(line) <= 80 for line in entry.splitlines()[1:]), entry)
        self.assertEqual(self.git('log', '-1', '--format=%s%n%n%b'),
                         'Pin Hyprflip to 0.3.0-rc.27\n\nCards say which program manages them.')
        self.assertEqual(self.git('status', '--porcelain'), '')

    def test_pin_can_raise_the_oldest_release_the_panel_accepts(self):
        others = self.read('README.md').count(self.minimum)
        result = self.tool('pin', 'v0.3.0-rc.27', '--commit', COMMIT, '--minimum', '0.3.0-rc.26')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('hyprflipMinimum: "0.3.0-rc.26"', self.read('Service.qml'))
        readme = self.read('README.md')
        for sentence in ('**Hyprflip 0.3.0-rc.26 or later**', '- Hyprflip 0.3.0-rc.26 or later;', 'older\nthan 0.3.0-rc.26,'):
            self.assertIn(sentence, readme)
        # Only the three sentences that state the minimum: the movement shortcuts still came in their own release.
        self.assertEqual(readme.count(self.minimum), others - 3)
        self.assertIn('Hyprflip 0.3.0-rc.26 or later is now required.', self.read('CHANGELOG.md').replace('\n  ', ' '))

    def test_release_names_the_version_in_the_changelog_readme_and_manifest(self):
        self.assertEqual(self.tool('pin', 'v0.3.0-rc.27', '--commit', COMMIT).returncode, 0)
        previous = json.loads(self.read('manifest.json'))['version']
        result = self.tool('release', '0.2.0-rc.99', '--date', '2026-11-19')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('## 0.2.0-rc.99 — 2026-11-19\n\n- Pin Hyprflip to', self.read('CHANGELOG.md'))
        self.assertNotIn('## Unreleased', self.read('CHANGELOG.md'))
        self.assertIn('This is the **0.2.0-rc.99 preview**', self.read('README.md'))
        self.assertNotIn(previous, self.read('README.md').split('\n## ')[0] + self.read('manifest.json'))
        self.assertEqual(json.loads(self.read('manifest.json'))['version'], '0.2.0-rc.99')
        self.assertEqual(self.git('log', '--format=%s', '-2').splitlines(),
                         ['Release OmaCards 0.2.0-rc.99', 'Pin Hyprflip to 0.3.0-rc.27'])
        self.assertIn('git push origin HEAD:main', result.stdout)

    def test_a_dry_run_shows_the_change_and_makes_none(self):
        result = self.tool('pin', 'v0.3.0-rc.27', '--commit', COMMIT, '--dry-run')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f'+    readonly property string hyprflipPin: "{COMMIT}"', result.stdout)
        self.assertEqual((self.git('rev-parse', 'HEAD'), self.git('status', '--porcelain')), (self.before, ''))

    def test_it_refuses_and_changes_nothing_until_a_step_can_be_taken(self):
        def refused(*args, why):
            result = self.tool(*args)
            self.assertEqual(result.returncode, 1, result.stdout)
            self.assertIn(why, result.stderr)
            self.assertEqual(self.git('rev-parse', 'HEAD'), self.before)
        refused('release', '0.2.0-rc.99', why='no "## Unreleased" section with entries')
        refused('pin', 'v0.3.0-rc.27', '--commit', self.pin, why=f'OmaCards pins {self.pin} already')
        refused('pin', 'v0.3.0-rc.27', '--commit', 'abc', why='is not a full commit hash')
        refused('pin', 'next', '--commit', COMMIT, why='give releases such as')
        (self.root / 'README.md').write_text('changed\n')
        refused('pin', 'v0.3.0-rc.27', '--commit', COMMIT, why='commit or stash the changes to tracked files first')
        self.git('checkout', '--', 'README.md')
        # A check that fails puts every file back.
        (self.root / 'tests/pin_check.py').write_text('raise SystemExit("planted")\n')
        self.git('commit', '--quiet', '-am', 'planted')
        self.before = self.git('rev-parse', 'HEAD')
        refused('pin', 'v0.3.0-rc.27', '--commit', COMMIT, why='a check failed, and every file is as it was')
        self.assertEqual(self.git('status', '--porcelain'), '')


if __name__ == '__main__':
    unittest.main()
