#!/usr/bin/env python3
"""Run real layer-focus operations in an explicitly disposable Hyprland session."""
import argparse
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('session', type=Path)
p.add_argument('--backend', type=Path, required=True)
args = p.parse_args()
connection = json.loads(args.session.read_text())
session_root = Path(connection['XDG_RUNTIME_DIR']).resolve().parent
assert session_root.is_relative_to('/tmp')
assert connection['HYPRLAND_INSTANCE_SIGNATURE'] != os.environ.get('HYPRLAND_INSTANCE_SIGNATURE')
env = os.environ | connection
env.update(OMACARDS_BACKEND=str(args.backend.resolve()), XDG_STATE_HOME=str(session_root / 'state'),
           XDG_CONFIG_HOME=str(session_root / 'config'), XDG_CACHE_HOME=str(session_root / 'cache'),
           XDG_DATA_HOME=str(session_root / 'data'), QT_QPA_PLATFORM='wayland', QT_QUICK_BACKEND='software')
def ctl(*command):
    result = subprocess.run(['hyprctl', *command], env=env, capture_output=True, text=True, timeout=8)
    if result.returncode or result.stdout.startswith('error') or 'Lua error' in result.stdout:
        raise RuntimeError(result.stdout + result.stderr)
    return result.stdout

project = Path(__file__).resolve().parents[1]
names = {m['name'] for m in json.loads(ctl('-j', 'monitors'))}
ctl('output', 'create', 'headless')
output = next(m['name'] for m in json.loads(ctl('-j', 'monitors')) if m['name'] not in names)
try:
    workspace = max(w['id'] for w in json.loads(ctl('-j', 'workspaces'))) + 20
    ctl('eval', f'hl.monitor({{output="{output}",mode="1920x1080@60",position="2000x0",scale=1}}); '
               f'hl.workspace_rule({{workspace="{workspace}",monitor="{output}",layout="hy3"}})')
    cards = json.loads(ctl('hyprflip', 'status'))['containers']
    assert len(cards) == 1, 'Use the three-app nested container fixture'
    apps = session_root / 'data/applications'
    apps.mkdir(parents=True, exist_ok=True)
    members = {a for face in cards[0]['faces'] for a in face}
    for window in json.loads(ctl('-j', 'clients')):
        if window['address'] not in members: continue
        app = window['class']
        assert re.fullmatch('hyprflip-(front|back|notes)', app), 'Use only the nested-session terminal fixture'
        (apps / (app + '.desktop')).write_text('[Desktop Entry]\nType=Application\nName=' + app + '\nStartupWMClass=' + app +
            '\nExec=/usr/bin/foot --config=/dev/null --app-id=' + app + ' --title=' + app + ' /usr/bin/cat\n')
    ctl('dispatch', 'hl.dsp.focus({window="address:' + cards[0]['current'] + '"})')
    ctl('hyprflip', f'workspace {workspace}')
    # A real bar click starts on its monitor. Keep the nested pointer there;
    # the host's outside-click surfaces otherwise focus the unrelated output.
    ctl('dispatch', 'hl.dsp.cursor.move({x=2960,y=540})')
    env['OMACARDS_TEST_OUTPUT'] = output
    env['OMACARDS_TEST_CLOSE'] = str(project / 'tests/fixture-close.py')
    time.sleep(.5)
    pref = session_root / 'state/hyprflip/cards.json'
    # This recipe belongs only to the disposable session.
    if pref.exists(): pref.unlink()
    with tempfile.TemporaryDirectory(prefix='omacards-shell-') as directory:
        root = Path(directory)
        for name in ('Ui', 'Commons'): (root / name).symlink_to('/usr/share/omarchy/shell/' + name)
        (root / 'Cards').mkdir()
        for source in project.glob('*.qml'): shutil.copy2(source, root / 'Cards' / source.name)
        shutil.copy2(project / 'tests/nested.qml', root / 'shell.qml')
        result = subprocess.run(['quickshell', '-p', str(root), '--no-color'], env=env,
                                capture_output=True, text=True, timeout=60)
        log = result.stdout + result.stderr
        (project / 'tests/native-result.log').write_text(log)
        print(log)
        assert result.returncode == 0 and 'OMACARDS_NATIVE_TEST_OK' in log and 'FAIL ' not in log
finally:
    ctl('output', 'remove', output)
