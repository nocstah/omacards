#!/usr/bin/env python3
"""Capture the native contents with synthetic data, without opening desktop UI."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

project = Path(__file__).resolve().parents[1]
captures = project / '.impeccable/review'
captures.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='omacards-render-') as directory:
    root = Path(directory)
    for name in ('Ui', 'Commons'): (root / name).symlink_to('/usr/share/omarchy/shell/' + name)
    for name in ('Cards', 'runtime', 'config', 'cache'): (root / name).mkdir(mode=0o700)
    for source in project.glob('*.qml'): shutil.copy2(source, root / 'Cards' / source.name)
    shutil.copy2(project / 'tests/render.qml', root / 'shell.qml')
    env = os.environ | dict(XDG_RUNTIME_DIR=str(root / 'runtime'), XDG_CONFIG_HOME=str(root / 'config'),
                            XDG_CACHE_HOME=str(root / 'cache'), QT_QPA_PLATFORM='offscreen',
                            QT_QPA_PLATFORMTHEME='', QT_QUICK_BACKEND='software', LIBGL_ALWAYS_SOFTWARE='1',
                            OMACARDS_FIXTURE=str(project / 'tests/fixture.json'), OMACARDS_CAPTURE_DIR=str(captures),
                            # Stand-ins answer busy-state captures; nothing touches the desktop.
                            OMACARDS_BACKEND=str(project / 'tests/fake-helper.py'),
                            OMACARDS_INSTALLER=str(project / 'tests/fake-installer.py'),
                            # OmaRelay: none by default, and the template shots switch to the fake. Without this a
                            # capture would run this PC's real OmaRelay and ask its live desktop helper.
                            OMACARDS_OMARELAY=str(root / 'no-omarelay/ovis.py'),
                            OMACARDS_FAKE_OMARELAY=str(project / 'tests/fake-omarelay.py'),
                            OMACARDS_FAKE_CONTROL=str(root / 'fake-control.json'),
                            OMACARDS_FAKE_RECORD=str(root / 'fake-record.jsonl'))
    for name in ('OMACARDS_FAKE_TEMPLATES', 'OMACARDS_FAKE_APPLY'): env.pop(name, None)
    assert env.get('OMACARDS_OMARELAY') and not Path(env['OMACARDS_OMARELAY']).exists(), 'OMACARDS_OMARELAY must name no OmaRelay'
    env.pop('WAYLAND_DISPLAY', None)
    env.pop('DISPLAY', None)
    result = subprocess.run(['quickshell', '-p', str(root), '--no-color'], env=env,
                            capture_output=True, text=True, timeout=240)
    log = result.stdout + result.stderr
    (project / 'tests/render-result.log').write_text(log)
    # Layer-shell windows cannot load on offscreen; native tests cover them.
    allowed = ('Unable to find hyprland socket', 'Type Ui.KeyboardPanel unavailable', 'No PanelWindow backend loaded')
    unexpected = [line for line in log.splitlines() if ('ERROR' in line or 'WARN scene' in line) and not any(a in line for a in allowed)]
    assert not unexpected, '\n'.join(unexpected)
    assert result.returncode == 0 and 'OMACARDS_UI_CAPTURE_OK' in log, log
    assert 'BAD ARGV' not in log, 'OmaCards ran OmaRelay with another command line: ' + log
    # OmaRelay's output is never logged: one line per failed call, with the exit status and a protocol code at most.
    warned = sorted(line.split('[omacards] templates: ')[1].strip() for line in log.splitlines() if '[omacards] templates: ' in line)
    # No OmaRelay (at start, and the absent shots' own capture), an OmaRelay before templates, garbage and a hang killed
    # by its time limit (SIGTERM, 15); a refused apply, an apply answering garbage, and one killed by its limit.
    assert warned == sorted(['list exit 2', 'list exit 2', 'list exit 2', 'list exit 0', 'list exit 15', 'apply exit 1 changed',
                             'apply exit 0', 'apply exit 15']), 'template warnings: ' + str(warned)
    # With an OmaRelay that offers nothing to apply, the page is as with none.
    for case in ('no-marker', 'usage', 'garbage', 'hang', 'no-workspace'):
        assert (captures / f'templates-absent-{case}.png').read_bytes() == (captures / 'templates-absent-base.png').read_bytes(), case
    checked = {line.split('OMACARDS_CHECKED ')[1].strip() for line in log.splitlines() if 'OMACARDS_CHECKED ' in line}
    assert checked == {'settings', 'shortcuts', 'pane-edit', 'multi-face-edit', 'one-face-covered', 'one-face-edit', 'motion-refresh', 'ungroup-confirm', 'managed-ungroup', 'navigation-offer', 'applied', 'worked', 'installed',
                       'templates-here', 'templates-only', 'templates-search', 'templates-nomatch', 'templates-confirm-here',
                       'templates-confirm-elsewhere', 'templates-confirm-nocard', 'templates-escape', 'templates-keep',
                       'templates-enter-enter', 'templates-apply', 'templates-apply-changed', 'templates-apply-garbage',
                       'templates-apply-hang', 'templates-applying', 'templates-cards-off', 'templates-no-helper',
                       'templates-helper-busy', 'templates-helper-old', 'templates-other-machine', 'templates-odd-code',
                       'templates-unreadable', 'templates-missing', 'templates-in-use-changed', 'templates-absent', 'templates-late',
                       'templates-hostile', 'templates-refresh-quiet'}, 'checks that did not run: ' + log
    print('Captured Cards, Edit, Motion, choices, entry states, narrow, scaled and theme fixtures:', captures)
