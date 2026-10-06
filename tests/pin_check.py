#!/usr/bin/env python3
"""The Hyprflip pin in Service.qml must match every pinned commit in README.md."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
service = re.search(r'hyprflipPin: "([0-9a-f]{40})"', (root / 'Service.qml').read_text()).group(1)
# Media links point at a fixed demo commit; the hy3 provider has its own pin.
lines = [line for line in (root / 'README.md').read_text().splitlines() if '/media/' not in line]
readme = set(re.findall(r'\b([0-9a-f]{40})\b', '\n'.join(lines))) - {'42b7ed8fd9aefd3f36e5f617afd5071245c67853'}
if readme != {service}:
    sys.exit(f'Service.qml pins {service}; README.md pins {sorted(readme)}')
print('Hyprflip pin consistent:', service)
