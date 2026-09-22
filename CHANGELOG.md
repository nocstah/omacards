# Changelog

## Unreleased

- Pin the executable Hyprflip dependency to `f4051aa5970dc816875839968b2629e462cb0a46`.
  Installation verifies a clean checkout at that exact revision before running
  the shared helper installer; dependency documentation uses immutable links.

## 0.1.0 — 2026-09-22

First public release, tested with Omarchy 4.0.4 and Hyprflip 0.2.0 on Hyprland 0.56.2.

- Native bar panel for the card library, guided creation and two-face editing.
- Add, remove, replace, reorder and transfer panes, including apps from other workspaces.
- Open and manage saved cards, repair missing apps and assign workspace destinations.
- Float or tile a multi-app card as one movable and resizable unit.
- Motion controls with transition previews, presets and exact duration.
- Editable keyboard shortcuts with recording, conflict checks and per-action defaults.
- Shared Hyprflip workflow backend and saved library, with native-menu fallback.
- Follow Omarchy's active theme, typography, focus and popup conventions.

Compositor libraries are installed separately. See [installation](README.md#install)
and the [Hyprflip compatibility limits](https://github.com/nocstah/hyprflip#compatibility-and-limits).
