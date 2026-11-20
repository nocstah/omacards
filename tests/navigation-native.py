#!/usr/bin/env python3
"""The movement-shortcut offer and Settings switch, end to end in a disposable session.

Usage: navigation-native.py <session.json> --hyprflip <checkout>

Start the session from a Hyprflip checkout that has the navigation switch:
  python3 tests/nested_session.py --directory /tmp/oc-nav --native-cards [--aquamarine <build>]
This installs that checkout's guided setup into a home inside the session folder,
points the session's configuration at that home, and runs the real panel against
the installed helper. After each switch it reads the compositor's own key list.
The session's configuration is put back at the end.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument('session', type=Path)
parser.add_argument('--hyprflip', type=Path, required=True, help='the Hyprflip checkout the session was started from')
args = parser.parse_args()
project = Path(__file__).resolve().parents[1]
session = args.session.resolve()
root = session.parent
connection = json.loads(session.read_text())
assert Path(connection['XDG_RUNTIME_DIR']).resolve().is_relative_to('/tmp'), 'Use a disposable session under /tmp'
assert connection['HYPRLAND_INSTANCE_SIGNATURE'] != os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'), 'Not the live desktop'
home = root / 'omacards-navigation-home'
env = os.environ | connection | {
    'HOME': str(home), 'XDG_CONFIG_HOME': str(home / '.config'), 'XDG_STATE_HOME': str(home / '.local/state'),
    'XDG_DATA_HOME': str(home / '.local/share'), 'XDG_CACHE_HOME': str(home / '.cache'), 'HYPRFLIP_MENU': 'fuzzel',
    # No OmaRelay: its templates must never reach this PC's live desktop helper.
    'OMACARDS_OMARELAY': str(home / 'no-omarelay/ovis.py')}
env.pop('DISPLAY', None)
OWN = 'OmaCards test: own Super+Shift+1'
helper = home / '.local/lib/hyprflip/control.py'
choice_file = home / '.local/state/hyprflip/navigation-choice'


def ctl(*command):
    result = subprocess.run(['hyprctl', *command], env=env, capture_output=True, text=True, timeout=8)
    if result.returncode or result.stdout.startswith('error'):
        raise RuntimeError(result.stdout + result.stderr)
    return result.stdout


def binds():
    return json.loads(ctl('-j', 'binds'))


def movement_keys():
    return sorted(b['description'] for b in binds() if b.get('description', '').startswith('Move card or window'))


def own_key():
    return any(b.get('description') == OWN for b in binds())


def cards():
    return sorted((c['id'], c['faces']) for c in json.loads(ctl('hyprflip', 'status'))['containers'])


def config_errors():
    text = ctl('configerrors').strip()
    return '' if text.lower() in ('', 'no errors') else text


def passed(text):
    print('PASS', text, flush=True)


config = root / 'hyprland.lua'
# The session's own configuration, kept once so that a second run starts from it too.
before = root / 'hyprland.lua.before-omacards-navigation'
if not before.exists():
    shutil.copy2(config, before)
try:
    for folder in ('.config/hypr', '.local/state', '.local/share', '.cache'):
        (home / folder).mkdir(parents=True, exist_ok=True)
    shutil.rmtree(home / '.local/state/hyprflip', ignore_errors=True)
    main = home / '.config/hypr/hyprland.lua'
    overrides = ''.join(f'hl.env({json.dumps(k)}, {json.dumps(env[k])})\n'
                        for k in ('HOME', 'XDG_CONFIG_HOME', 'XDG_STATE_HOME', 'XDG_DATA_HOME', 'XDG_CACHE_HOME'))
    # A stand-in for a desktop's own Super+Shift+1, which the shortcuts take over while on.
    main.write_text(overrides + before.read_text() + '\nhl.bind("SUPER + SHIFT + code:10", '
                    'hl.dsp.window.move({workspace="1"}), {description=' + json.dumps(OWN) + '})\n')
    for stale in ('hyprflip-navigation.lua', 'hyprflip-setup.lua'):
        (home / '.config/hypr' / stale).unlink(missing_ok=True)
    config.write_text('dofile(' + json.dumps(str(main)) + ')\n')
    ctl('reload')
    assert not config_errors(), config_errors()
    deadline = time.monotonic() + 15
    while not cards() and time.monotonic() < deadline: time.sleep(.1)
    assert cards(), 'Start the session with --native-cards'
    card_windows = cards()
    # A plain guided setup: an install from before the shortcuts, with no choice made.
    result = subprocess.run([sys.executable, str(args.hyprflip.resolve() / 'scripts/install-setup.py')], env=env,
                            capture_output=True, text=True, timeout=60)
    assert result.returncode == 0, result.stdout + result.stderr
    assert not movement_keys() and own_key(), 'a plain setup should leave the movement shortcuts off'

    with tempfile.TemporaryDirectory(prefix='omacards-navigation-') as directory:
        shell = Path(directory)
        for name in ('Ui', 'Commons'): (shell / name).symlink_to('/usr/share/omarchy/shell/' + name)
        (shell / 'Cards').mkdir()
        for source in project.glob('*.qml'): shutil.copy2(source, shell / 'Cards' / source.name)
        shutil.copy2(project / 'tests/navigation-native.qml', shell / 'shell.qml')
        panel_env = env | {'OMACARDS_BACKEND': str(helper), 'QT_QPA_PLATFORM': 'wayland', 'QT_QPA_PLATFORMTHEME': '',
                           'QT_QUICK_BACKEND': 'software'}
        with (project / 'tests/navigation-native.log').open('w') as log:
            process = subprocess.Popen(['quickshell', '-p', str(shell), '--no-color'], env=panel_env, stdout=log, stderr=log)
            try:
                def ipc(*call):
                    return subprocess.run(['quickshell', '-p', str(shell), 'ipc', 'call', 'navtest', *call], env=panel_env,
                                          capture_output=True, text=True, timeout=5).stdout.strip()

                def status():
                    try:
                        return json.loads(ipc('status'))
                    except ValueError:
                        return {}

                def wait(test, what, timeout=40):
                    deadline = time.monotonic() + timeout
                    while time.monotonic() < deadline:
                        state = status()
                        if state and not state['busy'] and test(state): return state
                        time.sleep(.2)
                    raise AssertionError(f'{what}: {json.dumps(status())}')

                def act(*call):
                    # The panel takes an action only when no refresh is running, as a person's click would wait.
                    deadline = time.monotonic() + 10
                    while (answer := ipc(*call)) == 'busy' and time.monotonic() < deadline: time.sleep(.2)
                    assert answer == 'ok', f'{call}: {answer}'

                def settled(state, page):
                    assert state['opened'] and not state['quietClosed'], 'switching closed the panel'
                    assert not state['failed'] and state['page'] == page, state
                    assert cards() == card_windows, 'a card changed'

                state = wait(lambda s: s.get('available') and s.get('opened'), 'the panel did not open')
                assert state['capability'] and state['navigation'] == 'off' and state['choice'] is None, state
                assert state['offer'], 'the panel did not offer the shortcuts on an install without them'
                passed('An install without the shortcuts and with no choice is offered them on the Cards page')

                act('press', 'No thanks')
                state = wait(lambda s: s['choice'] == 'off', 'No thanks was not recorded')
                settled(state, 'cards')
                assert state['navigation'] == 'off' and not state['offer'], state
                assert not movement_keys() and own_key() and choice_file.read_text().strip() == 'off'
                passed('No thanks records off, hides the offer and leaves the keys as they were')

                choice_file.unlink()
                ipc('refresh')
                wait(lambda s: s['offer'], 'the offer did not come back without a recorded choice')
                act('press', 'Turn on')
                state = wait(lambda s: s['navigation'] == 'on', 'Turn on did not switch the shortcuts on')
                settled(state, 'cards')
                assert state['choice'] == 'on' and not state['offer'], state
                assert state['notice'].startswith('Movement shortcuts on'), state['notice']
                keys = movement_keys()
                assert len(keys) == 24 and not own_key(), keys
                passed('Turn on loads all 24 movement keys over the desktop\'s own, with the panel left open')

                ipc('page', 'settings')
                state = wait(lambda s: s['toggle'], 'Settings did not show the switch')
                assert state['checked'], state
                act('toggle')
                state = wait(lambda s: s['navigation'] == 'off', 'the Settings switch did not turn them off')
                settled(state, 'settings')
                assert state['choice'] == 'off' and not state['checked'], state
                assert not movement_keys() and own_key()
                passed('The Settings switch turns them off: the desktop\'s own key is back')

                act('toggle')
                state = wait(lambda s: s['navigation'] == 'on', 'the Settings switch did not turn them on again')
                settled(state, 'settings')
                assert state['checked'] and len(movement_keys()) == 24 and not own_key()
                act('toggle')
                state = wait(lambda s: s['navigation'] == 'off', 'the Settings switch did not turn them off again')
                settled(state, 'settings')
                assert not movement_keys() and own_key()
                passed('The Settings switch turns them on and off again, and no card changed')
            finally:
                ipc('quit')
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=5)
finally:
    config.write_text(before.read_text())
    ctl('reload')
print('OMACARDS_NAVIGATION_TEST_OK')
