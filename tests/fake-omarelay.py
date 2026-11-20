#!/usr/bin/env python3
"""A stand-in OmaRelay for OmaCards' template checks (OmaRelay docs/workspace-browsers.md, "Templates in OmaCards").

It accepts exactly the two command lines OmaCards may run, appends each argv as one JSON line to
$OMACARDS_FAKE_RECORD, and answers from tests/templates/<case>.json. The cases come from the JSON file at
$OMACARDS_FAKE_CONTROL ({"templates": case, "apply": case, "delay": seconds}) when it names them, so one render run
can change them between shots, else from $OMACARDS_FAKE_TEMPLATES and $OMACARDS_FAKE_APPLY. Any other command line
exits 3 with BAD ARGV on stderr. It never touches the desktop or a real OmaRelay.

List cases: a file in tests/templates/, or usage (exit 2, no output, as an OmaRelay before templates), garbage
(exit 0, not JSON) and hang (15 s). Apply cases: soon, pending, changed (refused, exit 1), garbage and hang (60 s).
"""
import json
import os
from pathlib import Path
import re
import sys
import time

LIST = ['workspace-browsers', 'cards', 'template', 'list', '--space', 'here', '--json']


def apply_shape(argv):
    return (len(argv) == 11 and argv[:4] == ['workspace-browsers', 'cards', 'template', 'apply']
            and re.fullmatch(r'browser|terminals|editor|none|t[0-9a-f]{10}', argv[4]) is not None
            and argv[5] == '--space' and re.fullmatch(r'[A-Za-z0-9_-]{1,64}', argv[6]) is not None
            and argv[7] == '--token' and re.fullmatch(r'[0-9a-f]{64}', argv[8]) is not None
            and argv[9:] == ['--json', '--notify'])


argv = sys.argv[1:]
if argv != LIST and not apply_shape(argv):
    print('BAD ARGV ' + json.dumps(argv), file=sys.stderr)
    sys.exit(3)
if os.environ.get('OMACARDS_FAKE_RECORD'):
    with open(os.environ['OMACARDS_FAKE_RECORD'], 'a') as record:
        record.write(json.dumps(argv) + '\n')
control = {}
if os.environ.get('OMACARDS_FAKE_CONTROL'):
    try:
        control = json.loads(Path(os.environ['OMACARDS_FAKE_CONTROL']).read_text())
    except (OSError, ValueError):
        control = {}
time.sleep(float(control.get('delay') or 0))

if argv == LIST:
    case = control.get('templates') or os.environ.get('OMACARDS_FAKE_TEMPLATES', 'live-here')
    if case == 'usage':
        sys.exit(2)
    if case == 'garbage':
        print('not json')
        sys.exit(0)
    if case == 'hang':
        time.sleep(15)
        sys.exit(0)
    answer = json.loads((Path(__file__).resolve().parent / 'templates' / (case + '.json')).read_text())
    # OmaCards reads the last non-empty line; a line before it and a blank one after must not matter.
    print('fake OmaRelay')
    print(json.dumps(answer, ensure_ascii=False))
    print()
    sys.exit(0)

case = control.get('apply') or os.environ.get('OMACARDS_FAKE_APPLY', 'soon')
if case == 'garbage':
    print('not json')
    sys.exit(0)
if case == 'hang':
    time.sleep(60)
    sys.exit(0)
if case == 'changed':
    print(json.dumps({'ok': False, 'protocol': 1, 'code': 'changed'}))
    sys.exit(1)
print(json.dumps({'ok': True, 'protocol': 1, 'applies': case, 'space': {'id': argv[6], 'label': 'omarelay'}}))
