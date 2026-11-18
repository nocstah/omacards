#!/usr/bin/env python3
"""Pin a Hyprflip release, and release OmaCards, each in one command.

  python3 tools/release.py pin v0.3.0-rc.27 [--commit SHA] [--note TEXT] [--minimum 0.3.0-rc.27] [--no-render]
                                   [--trailer TEXT]... [--dry-run]
  python3 tools/release.py release 0.2.0-rc.32 [--date YYYY-MM-DD] [--trailer TEXT]... [--dry-run]

pin moves every place that names the tested Hyprflip to that release: the commit in Service.qml and README.md,
the release README.md was tested with, the installer fixtures, and a CHANGELOG.md entry under Unreleased (with
--note's words). It finds the tag's commit on GitHub unless --commit gives it. --minimum also raises the oldest
Hyprflip the panel accepts, in Service.qml and the README's three sentences that state it. Then it runs
tests/pin_check.py, tests/installer_test.py and tests/render.py (about half a minute; --no-render skips it) and
commits "Pin Hyprflip to <version>".

release turns Unreleased into the version's heading, names the version in README.md and manifest.json, checks
the pin and the plugin (omarchy plugin validate, when it is there), and commits "Release OmaCards <version>".

Both refuse while tracked files have changes, and push nothing. --dry-run prints what would change. --trailer
adds a trailer to the commit, such as "Co-Authored-By: Name <address>"; repeat it for more.
"""
import argparse
import datetime
import difflib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = 'https://github.com/nocstah/hyprflip.git'
RELEASE = re.compile(r'\d+\.\d+\.\d+(?:-rc\.\d+)?')


class Refused(Exception):
    pass


def run(*command, cwd=ROOT, check=True):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode:
        raise Refused(f'{" ".join(command)}: {(result.stderr or result.stdout).strip()[-1500:]}')
    return result.stdout.strip()


def read(path): return (ROOT / path).read_text()


def once(text, old, new, name):
    if text.count(old) != 1:
        raise Refused(f'{name}: expected "{old.strip()}" once, found it {text.count(old)} times')
    return text.replace(old, new, 1)


def unreleased(changelog, entry):
    """CHANGELOG.md with entry first under Unreleased, which it makes when there is none."""
    if re.search(r'^## Unreleased\n', changelog, re.M):
        return re.sub(r'^## Unreleased\n\n?', lambda _: f'## Unreleased\n\n{entry}\n', changelog, count=1, flags=re.M)
    return once(changelog, '# Changelog\n\n', f'# Changelog\n\n## Unreleased\n\n{entry}\n\n', 'CHANGELOG.md')


def wrap(text, first, rest, width=80):
    """Markdown list text wrapped at width, the first line after first and the others after rest."""
    lines, line = [], first
    for word in text.split():
        if len(line) + len(word) + 1 > width and line.strip() not in ('', first.strip()):
            lines.append(line.rstrip())
            line = rest
        line += word + ' '
    return '\n'.join(lines + [line.rstrip()])


def tag_commit(tag, given):
    if given:
        if not re.fullmatch(r'[0-9a-f]{40}', given):
            raise Refused(f'{given} is not a full commit hash')
        return given
    listed = run('git', 'ls-remote', REPOSITORY, f'refs/tags/{tag}', f'refs/tags/{tag}^{{}}')
    refs = {ref: sha for sha, ref in (line.split('\t') for line in listed.splitlines() if '\t' in line)}
    # An annotated tag names its commit in the peeled ref; a lightweight one is the commit.
    commit = refs.get(f'refs/tags/{tag}^{{}}') or refs.get(f'refs/tags/{tag}')
    if not commit:
        raise Refused(f'Hyprflip has no tag {tag} on GitHub; push it first, or give --commit')
    return commit


def pin_edits(version, commit, note, minimum):
    service, readme = read('Service.qml'), read('README.md')
    old = re.search(r'hyprflipPin: "([0-9a-f]{40})"', service).group(1)
    tested = re.search(r'and was tested with Hyprflip (\S+)\.\n', readme)
    if not tested:
        raise Refused('README.md does not say which Hyprflip it was tested with')
    if old == commit:
        raise Refused(f'OmaCards pins {commit} already')
    current = re.search(r'hyprflipMinimum: "([^"]+)"', service).group(1)
    service = service.replace(old, commit)
    readme = readme.replace(old, commit).replace(tested.group(0), f'and was tested with Hyprflip {version}.\n')
    if minimum and minimum != current:
        service = once(service, f'hyprflipMinimum: "{current}"', f'hyprflipMinimum: "{minimum}"', 'Service.qml')
        readme = once(readme, f'**Hyprflip {current} or later**', f'**Hyprflip {minimum} or later**', 'README.md')
        readme = once(readme, f'- Hyprflip {current} or later;', f'- Hyprflip {minimum} or later;', 'README.md')
        readme = once(readme, f'older\nthan {current},', f'older\nthan {minimum},', 'README.md')
    accepted = (f'Hyprflip {minimum} or later is now required.' if minimum and minimum != current else
                f'Hyprflip {current} or later still counts as current.')
    # The link stays whole on the first line, as the earlier entries have it.
    entry = (f'- Pin Hyprflip to [`v{version}`](https://github.com/nocstah/hyprflip/releases/tag/v{version})\n' +
             wrap(f'(`{commit}`).' + (f' {note.strip()}' if note else '') + f' {accepted}', '  ', '  '))
    edits = {'Service.qml': service, 'README.md': readme, 'CHANGELOG.md': unreleased(read('CHANGELOG.md'), entry)}
    for path in ('tests/fake-installer.py', 'tests/render.qml'):
        text = read(path)
        # The installer's download step, as each fixture quotes it.
        named = re.compile(rf'Hyprflip v{re.escape(tested.group(1))}(?=[\'"])')
        if len(named.findall(text)) != 1:
            raise Refused(f'{path}: expected "Hyprflip v{tested.group(1)}" once')
        edits[path] = named.sub(f'Hyprflip v{version}', text)
    return edits


def release_edits(version, date):
    changelog, readme, manifest = read('CHANGELOG.md'), read('README.md'), read('manifest.json')
    section = re.search(r'^## Unreleased\n(.*?)(?=^## |\Z)', changelog, re.M | re.S)
    if not section or not re.search(r'^- ', section.group(1), re.M):
        raise Refused('CHANGELOG.md has no "## Unreleased" section with entries')
    previous = json.loads(manifest)['version']
    return {'CHANGELOG.md': once(changelog, '## Unreleased\n', f'## {version} — {date}\n', 'CHANGELOG.md'),
            'README.md': once(readme, f'This is the **{previous} preview**', f'This is the **{version} preview**', 'README.md'),
            'manifest.json': once(manifest, f'"version": "{previous}"', f'"version": "{version}"', 'manifest.json')}


def apply(edits, dry_run, checks, message, trailers=()):
    """Writes the edits, runs the checks and commits; puts every file back when a check fails."""
    old = {path: read(path) for path in edits}
    if dry_run:
        for path, new in edits.items():
            sys.stdout.writelines(difflib.unified_diff(old[path].splitlines(True), new.splitlines(True), f'a/{path}', f'b/{path}'))
        print(f'\nWould commit "{message.splitlines()[0]}".')
        return None
    for path, new in edits.items():
        (ROOT / path).write_text(new)
    try:
        for check in checks:
            run(*check)
    except Refused as error:
        for path, text in old.items():
            (ROOT / path).write_text(text)
        raise Refused(f'a check failed, and every file is as it was: {error}') from None
    run('git', 'add', '--', *edits)
    run('git', 'commit', '--quiet', '-m', message, *(arg for trailer in trailers for arg in ('--trailer', trailer)))
    return run('git', 'rev-parse', '--short', 'HEAD')


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest='command', required=True)
    pin = commands.add_parser('pin', help='pin a Hyprflip release')
    pin.add_argument('tag', help='such as v0.3.0-rc.27')
    pin.add_argument('--commit', help="the tag's commit, instead of asking GitHub")
    pin.add_argument('--note', default='', help='what the release brings, for the changelog entry and the commit')
    pin.add_argument('--minimum', help='raise the oldest Hyprflip release the panel accepts')
    pin.add_argument('--no-render', action='store_true', help='skip tests/render.py')
    pin.add_argument('--trailer', action='append', default=[], help='a commit trailer, such as Co-Authored-By: …')
    pin.add_argument('--dry-run', action='store_true')
    release = commands.add_parser('release', help='release OmaCards')
    release.add_argument('version', help='such as 0.2.0-rc.32')
    release.add_argument('--date', default=datetime.date.today().isoformat())
    release.add_argument('--trailer', action='append', default=[], help='a commit trailer, such as Co-Authored-By: …')
    release.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    try:
        if run('git', 'status', '--porcelain', '--untracked-files=no'):
            raise Refused('commit or stash the changes to tracked files first')
        tests = [sys.executable, 'tests/pin_check.py'], [sys.executable, 'tests/installer_test.py']
        if args.command == 'pin':
            version = args.tag.removeprefix('v')
            if not RELEASE.fullmatch(version) or args.minimum and not RELEASE.fullmatch(args.minimum):
                raise Refused('give releases such as v0.3.0-rc.27')
            edits = pin_edits(version, tag_commit('v' + version, args.commit), args.note, args.minimum)
            message = f'Pin Hyprflip to {version}' + (f'\n\n{wrap(args.note, "", "", 72)}' if args.note else '')
            render = [] if args.no_render else [[sys.executable, 'tests/render.py']]
            done = apply(edits, args.dry_run, [*tests, *render], message, args.trailer)
        else:
            version = args.version.removeprefix('v')
            if not RELEASE.fullmatch(version) or not re.fullmatch(r'\d{4}-\d{2}-\d{2}', args.date):
                raise Refused('give a version such as 0.2.0-rc.32 and a date such as 2026-11-18')
            validate = [['omarchy', 'plugin', 'validate', '.']] if shutil.which('omarchy') else []
            done = apply(release_edits(version, args.date), args.dry_run, [tests[0], *validate],
                         f'Release OmaCards {version}', args.trailer)
    except Refused as error:
        print(f'Nothing changed: {error}', file=sys.stderr)
        return 1
    if done:
        print(f'Committed {done}. Nothing is pushed: git push origin HEAD:main')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
