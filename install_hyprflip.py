#!/usr/bin/env python3
"""Fetch the Hyprflip commit OmaCards is pinned to and run its bootstrap.

Usage: install_hyprflip.py <40-character commit> <source directory>

Prints one JSON event per line, in the format of Hyprflip's
scripts/bootstrap.py --json, which it runs after the download step:

  {"event": "step", "id": "download", "title": "...", "status": "running|ok|failed", "detail": "..."}
  {"event": "done", "ok": false}

Only the exact pinned commit is built. A source directory with local changes is
left alone. Nothing here uses sudo.
"""
import json
from pathlib import Path
import re
import subprocess
import sys

REPOSITORY = 'https://github.com/nocstah/hyprflip.git'
TITLE = 'Download the pinned Hyprflip release'


def emit(**event):
    print(json.dumps(event), flush=True)


def git(*arguments, cwd=None):
    result = subprocess.run(['git', *arguments], cwd=cwd, capture_output=True, text=True, timeout=300)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip().splitlines()[-1] if (result.stderr or result.stdout).strip()
                           else 'git ' + ' '.join(arguments) + ' failed')
    return result.stdout.strip()


def download(pin, source):
    if not (source / '.git').is_dir():
        if source.exists() and any(source.iterdir()):
            raise RuntimeError(f'{source} exists and is not a Hyprflip checkout; move it aside and try again')
        source.parent.mkdir(parents=True, exist_ok=True)
        git('clone', '--no-checkout', '--quiet', REPOSITORY, str(source))
    elif git('status', '--porcelain', '--untracked-files=no', cwd=source):
        raise RuntimeError(f'{source} has local changes; OmaCards will not overwrite them')
    if git('remote', 'get-url', 'origin', cwd=source) != REPOSITORY:
        raise RuntimeError(f'{source} does not track {REPOSITORY}')
    git('fetch', '--quiet', '--tags', 'origin', cwd=source)
    git('checkout', '--quiet', '--detach', pin, cwd=source)
    if git('rev-parse', 'HEAD', cwd=source) != pin:
        raise RuntimeError('The checkout does not match the pinned commit')
    if not (source / 'scripts/bootstrap.py').is_file():
        raise RuntimeError('The pinned Hyprflip has no bootstrap; update OmaCards')
    try:
        return git('describe', '--tags', '--exact-match', cwd=source)
    except RuntimeError:
        return pin[:12]


def main():
    if len(sys.argv) != 3 or not re.fullmatch(r'[0-9a-f]{40}', sys.argv[1]):
        emit(event='step', id='download', title=TITLE, status='failed', detail='OmaCards passed an invalid Hyprflip pin')
        emit(event='done', ok=False)
        return 2
    pin, source = sys.argv[1], Path(sys.argv[2]).expanduser()
    emit(event='step', id='download', title=TITLE, status='running')
    try:
        release = download(pin, source)
    except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
        emit(event='step', id='download', title=TITLE, status='failed', detail=str(error))
        emit(event='done', ok=False)
        return 1
    emit(event='step', id='download', title=TITLE, status='ok', detail=f'Hyprflip {release}')
    return subprocess.run([sys.executable, 'scripts/bootstrap.py', '--json'], cwd=source).returncode


if __name__ == '__main__':
    raise SystemExit(main())
