# Changelog

## 0.2.0-rc.4 — 2026-09-26

- Pin Hyprflip to `3449c39d2c11d83659589360998d3bf1756a54a0`, which adds the accent ring.
  Bridge ABI 7, helper protocol 1 and the hy3 provider pin are unchanged.
- Add **Card highlight → Accent ring** in Settings. The ring uses the Omarchy
  theme accent and follows theme changes; the service syncs the color through
  the Hyprflip helper. Needs a Hyprflip build with the accent ring and stays
  hidden otherwise.

## 0.2.0-rc.3 — 2026-09-26

- Pin Hyprflip to `3dcb57cf10ec7181c88b7887b87936bdd2f72e15`. Saved cards now
  reopen web apps after the default browser changes, for example a Gmail card
  saved in Brave now opens with Helium or Chrome. Bridge ABI 7, helper
  protocol 1 and the hy3 provider pin are unchanged.

## 0.2.0-rc.2 — 2026-09-23

- Pin Hyprflip to `22db6eb9bff869ed5614976757bc76eb191ec165`, the matching
  0.3.0-rc.2 core/helper revision. The core can give unfolded faces unequal
  room to satisfy app size limits; the Comms example now fits its laptop tile.
- Keep the panel API and controls unchanged. Installation links select the
  tested core with the adaptive-unfold fix.

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
