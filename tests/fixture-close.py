#!/usr/bin/env python3
"""Close only the three named terminal fixtures in a disposable compositor."""
import json
import os
from pathlib import Path
import subprocess
import time

assert Path(os.environ['XDG_RUNTIME_DIR']).resolve().is_relative_to('/tmp')
def ctl(*args):
    return subprocess.check_output(['hyprctl', *args], text=True, timeout=8)
fixtures = {'hyprflip-front', 'hyprflip-back', 'hyprflip-notes'}
state = json.loads(ctl('hyprflip', 'status'))
windows = {w['address']: w for w in json.loads(ctl('-j', 'clients'))}
if state['containers']:
    assert len(state['containers']) == 1
    members = {a for face in state['containers'][0]['faces'] for a in face}
    assert len(members) == 3
    assert {windows[a]['class'] for a in members} == fixtures
    ctl('hyprflip', 'unpair')
else:
    # After Ungroup: the same three apps, still open as separate windows.
    members = {a for a, w in windows.items() if w['class'] in fixtures}
    assert len(members) == 3 and {windows[a]['class'] for a in members} == fixtures, 'ungrouped apps did not stay open'
for address in members:
    ctl('dispatch', 'hl.dsp.window.close({window="address:' + address + '"})')
deadline = time.monotonic() + 8
while members & {w['address'] for w in json.loads(ctl('-j', 'clients'))}:
    assert time.monotonic() < deadline
    time.sleep(.05)
