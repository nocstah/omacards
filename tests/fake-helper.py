#!/usr/bin/env python3
"""A stand-in Hyprflip helper for render captures of busy states.

snapshot prints the render fixture; run answers like the helper after a short
wait, so a capture can show the panel while an operation is in flight. It never
touches the desktop.
"""
import json
import os
import sys
import time

if sys.argv[1:2] == ['snapshot']:
    with open(os.environ['OMACARDS_FIXTURE']) as fixture:
        print(fixture.read().strip())
elif sys.argv[1:3] == ['run', '--request']:
    request = json.loads(sys.argv[3])
    if request.get('action') == 'open':
        print(json.dumps({'type': 'opening', 'name': request.get('name', ''), 'labels': ['Browser', 'Notes']}), flush=True)
    time.sleep(float(os.environ.get('OMACARDS_FAKE_DELAY', '0.7')))
    print(json.dumps({'type': 'done', 'message': ''}), flush=True)
else:
    sys.exit('usage: fake-helper.py snapshot | run --request JSON')
