# Changelog

## 0.2.0-rc.1 — 2026-09-23

Preview for Hyprflip’s native dwindle cards on Hyprland 0.56.2.

- Use the core and helper on Omarchy’s default dwindle layout; hy3 remains optional.
- Update setup guidance and pair/empty-state messages for native multi-app cards.
- Pass seven real panel workflows with only the Hyprflip core on dwindle,
  including saving, hidden-face editing and cold reopening of three apps.
- Add persistent Classic tabs / experimental Card frame and Desktop / Compact
  spacing choices in Settings, with controls gated by backend capabilities.
- Support the matching ABI 7 backend's five apps per face and document its
  explicit drag-to-add targets, slot previews and cancellation.
- Pin the executable Hyprflip dependency to `537c4d5fea96a393048f161e3a220abf4e502c15`.
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
