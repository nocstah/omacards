#!/usr/bin/env python3
"""When install_hyprflip.py asks Hyprflip's bootstrap for the movement shortcuts."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('install_hyprflip', Path(__file__).resolve().parents[1] / 'install_hyprflip.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class NewSetup(unittest.TestCase):
    def setUp(self):
        self.home = Path(tempfile.mkdtemp(prefix='omacards-installer-'))
        self.state = self.home / '.local/state/hyprflip'

    def test_nothing_recorded_is_a_new_setup(self):
        self.assertTrue(installer.new_setup({'HOME': str(self.home)}))
        self.state.mkdir(parents=True)
        self.assertTrue(installer.new_setup({'HOME': str(self.home)}))

    def test_an_install_or_a_choice_is_not(self):
        self.state.mkdir(parents=True)
        for name in ('installed-release', 'installed-commit', 'navigation-choice'):
            with self.subTest(name=name):
                (self.state / name).write_text('x\n')
                self.assertFalse(installer.new_setup({'HOME': str(self.home)}))
                (self.state / name).unlink()

    def test_state_home_is_honoured(self):
        other = self.home / 'state'
        (other / 'hyprflip').mkdir(parents=True)
        (other / 'hyprflip/installed-release').write_text('0.3.0-rc.22\n')
        self.assertFalse(installer.new_setup({'HOME': str(self.home), 'XDG_STATE_HOME': str(other)}))
        self.assertTrue(installer.new_setup({'HOME': str(self.home)}))


class Arguments(unittest.TestCase):
    def source(self, bootstrap):
        source = Path(tempfile.mkdtemp(prefix='omacards-source-'))
        (source / 'scripts').mkdir()
        (source / 'scripts/bootstrap.py').write_text(bootstrap)
        return source

    def test_new_setup_asks_for_the_shortcuts(self):
        source = self.source("parser.add_argument('--navigation', action='store_true')\n")
        self.assertEqual(installer.bootstrap_arguments(source, True), ['--json', '--navigation'])

    def test_updates_never_do(self):
        source = self.source("parser.add_argument('--navigation', action='store_true')\n")
        self.assertEqual(installer.bootstrap_arguments(source, False), ['--json'])

    def test_a_bootstrap_without_them_is_not_asked(self):
        source = self.source("parser.add_argument('--json', action='store_true')\n")
        self.assertEqual(installer.bootstrap_arguments(source, True), ['--json'])


if __name__ == '__main__':
    unittest.main()
