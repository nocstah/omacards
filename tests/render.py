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
                            OMACARDS_FIXTURE=str(project / 'tests/fixture.json'), OMACARDS_CAPTURE_DIR=str(captures))
    env.pop('WAYLAND_DISPLAY', None)
    env.pop('DISPLAY', None)
    result = subprocess.run(['quickshell', '-p', str(root), '--no-color'], env=env,
                            capture_output=True, text=True, timeout=20)
    log = result.stdout + result.stderr
    (project / 'tests/render-result.log').write_text(log)
    # Layer-shell windows cannot load on offscreen; native tests cover them.
    allowed = ('Unable to find hyprland socket', 'Type Ui.KeyboardPanel unavailable', 'No PanelWindow backend loaded')
    unexpected = [line for line in log.splitlines() if ('ERROR' in line or 'WARN scene' in line) and not any(a in line for a in allowed)]
    assert not unexpected, '\n'.join(unexpected)
    assert result.returncode == 0 and 'OMACARDS_UI_CAPTURE_OK' in log, log
    print('Captured Cards, Edit, Motion, choices, entry states, narrow, scaled and theme fixtures:', captures)
