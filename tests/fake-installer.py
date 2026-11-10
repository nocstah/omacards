#!/usr/bin/env python3
"""A stand-in for install_hyprflip.py in render captures: reports the first
steps, pauses mid-build so a capture shows the panel while installing, then
reports success. It downloads and builds nothing."""
import json
import os
import time


def emit(**event):
    print(json.dumps(event), flush=True)


emit(event='step', id='download', title='Download the pinned Hyprflip release', status='ok', detail='Hyprflip v0.3.0-rc.17')
emit(event='step', id='check', title='Check prerequisites', status='ok', detail='Hyprland v0.56.2 with matching headers')
emit(event='step', id='build', title='Build Hyprflip', status='running')
time.sleep(float(os.environ.get('OMACARDS_FAKE_DELAY', '0.7')))
emit(event='step', id='build', title='Build Hyprflip', status='ok', detail='Built and self-tested')
emit(event='done', ok=True)
