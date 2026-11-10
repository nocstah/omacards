#!/usr/bin/env python3
"""The Hyprflip pin and minimum release in Service.qml must match README.md."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parent.parent
service = re.search(r'hyprflipPin: "([0-9a-f]{40})"', (root / 'Service.qml').read_text()).group(1)
# Media links point at a fixed demo commit.
lines = [line for line in (root / 'README.md').read_text().splitlines() if '/media/' not in line]
readme = set(re.findall(r'\b([0-9a-f]{40})\b', '\n'.join(lines)))
if readme != {service}:
    sys.exit(f'Service.qml pins {service}; README.md pins {sorted(readme)}')
text = (root / 'README.md').read_text()
minimum = re.search(r'hyprflipMinimum: "([^"]+)"', (root / 'Service.qml').read_text()).group(1)
if f'Hyprflip {minimum} or later' not in text or f'older\nthan {minimum}' not in text:
    sys.exit(f'Service.qml requires Hyprflip {minimum}; README.md does not say so')
print('Hyprflip pin consistent:', service, '· minimum', minimum)
