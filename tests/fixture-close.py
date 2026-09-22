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
state = json.loads(ctl('hyprflip', 'status'))
assert len(state['containers']) == 1
members = {a for face in state['containers'][0]['faces'] for a in face}
windows = {w['address']: w for w in json.loads(ctl('-j', 'clients'))}
assert len(members) == 3
assert {windows[a]['class'] for a in members} == {'hyprflip-front', 'hyprflip-back', 'hyprflip-notes'}
ctl('hyprflip', 'unpair')
for address in members:
    ctl('dispatch', 'hl.dsp.window.close({window="address:' + address + '"})')
deadline = time.monotonic() + 8
while members & {w['address'] for w in json.loads(ctl('-j', 'clients'))}:
    assert time.monotonic() < deadline
    time.sleep(.05)
