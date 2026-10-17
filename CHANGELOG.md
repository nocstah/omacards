# Changelog

## 0.2.0-rc.12 — 2026-10-17

- Pin Hyprflip to [`v0.3.0-rc.9`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.9)
  (`52322ae08ab4a7c1676a81fcf34942000b2c99be`): window titles no longer reach
  command lines. Its Omarchy-menu app pickers sent every candidate window's
  title as an `omarchy-shell` argument, readable by other local users; rows
  now show the app, workspace and status, and two windows of the same app are
  numbered. `HYPRFLIP_MENU_TITLES=1` brings titles back on a single-user
  computer. Opening a saved card also completes an open card that holds part
  of it. Bridge ABI 7 and helper protocol 1 are unchanged.

## 0.2.0-rc.11 — 2026-10-16

- Text fields no longer read the clipboard. Qt's editable text inputs fetch
  the clipboard's text every time any app copies, even while hidden, so a
  clipboard owner that streams endlessly could stall the shell. The card name,
  saved-card search and exact-duration fields are now read-only Qt inputs that
  take text only from typed keys: no clipboard reads and no paste. Hyprflip pin,
  bridge ABI 7 and helper protocol 1 are unchanged.

## 0.2.0-rc.10 — 2026-10-15

- Pin Hyprflip to [`v0.3.0-rc.8`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.8)
  (`e9587c60d72e658f023edc3531da6472ab0e88d7`): every app of a face turns
  during a flip again (since rc.7 only one did, the others hidden behind a
  blur), and Super+G on a floating card no longer aborts Hyprland. No panel
  changes. Bridge ABI 7, helper protocol 1 and the hy3 provider pin are
  unchanged.

## 0.2.0-rc.9 — 2026-10-09

- Pin Hyprflip to [`v0.3.0-rc.7`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.7)
  (`247cf5112cf4b95f017e6768615282ab8db52467`): tiled cards keep their
  `gaps_in`, faces turn at full opacity with themes that dim inactive
  windows, and glass faces stay frosted while they flip. No panel changes.
  Bridge ABI 7, helper protocol 1 and the hy3 provider pin are unchanged.

## 0.2.0-rc.8 — 2026-10-07

- Install missing build tools from the panel. A stock Omarchy system lacks
  CMake and Ninja, so a first install used to stop at **Check prerequisites**.
  When Hyprflip's bootstrap reports missing build packages, Cards now offers
  **Install build tools**, which opens Omarchy's floating terminal running
  `omarchy-pkg-add` for exactly those packages. Only Hyprflip's known build
  packages are accepted. While the panel is open, it checks with `pacman -Q`
  and installs Hyprflip once they are in. OmaCards itself still never runs
  sudo. The Hyprflip pin is unchanged.

## 0.2.0-rc.7 — 2026-10-06

- Install or update Hyprflip from the panel. When Hyprflip is missing, has an
  older helper protocol, is not loaded, or a recorded install differs from the
  pin, Cards offers **Install Hyprflip** or **Update Hyprflip**. The new
  `install_hyprflip.py` fetches the exact pinned commit into
  `~/.local/share/omacards/hyprflip`, verifies it, and runs Hyprflip's
  `scripts/bootstrap.py --json`. Each step and any fix command (such as the
  `pacman` line for a missing build tool) appear in the panel. Nothing runs
  with sudo, and a checkout with local changes is left alone.
- Pin Hyprflip to [`v0.3.0-rc.6`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.6)
  (`2a71872bd57d029e1734befef86ddc89a6b3d20e`): updates keep open cards in
  place, the one-command bootstrap, and Find in fullscreen cards. Bridge ABI 7, helper
  protocol 1 and the hy3 provider pin are unchanged.

## 0.2.0-rc.6 — 2026-10-05

- Pin Hyprflip to [`v0.3.0-rc.4`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.4)
  (`2d80550226dcdb05d7895ca73a8124578a3623fe`): floating cards stay on top
  while turning, translucent cards stay blurred during transitions, Super+J
  flips a card face with several apps, and cards can join a chilled
  workspace. No panel changes. Bridge ABI 7, helper protocol 1 and the hy3
  provider pin are unchanged.

## 0.2.0-rc.5 — 2026-09-30

- Shorten the marketplace description to 481 characters (catalog limit 500)
  and mention fullscreen cards.
- Add **Fullscreen / Leave fullscreen** to the selected card's actions for
  dwindle and floating cards, and show **· Fullscreen** in its summary. Float
  card, Ungroup card and Reopen missing apps are disabled while a card is
  fullscreen.
- Add **Settings → Fullscreen divider** (Off, 1, 2, 3 or 4 px). The divider
  uses the accent color unless Hyprflip's `divider_color` is set.
- The shortcut editor lists **Fullscreen whole card** (default
  Super+Ctrl+Alt+Return) when the guided setup provides it.
- Pin Hyprflip to `20dddeedb514c372f203227a8f394c7a1cf8275f`, which adds whole-card fullscreen, fullscreen
  editing, the divider settings and native-card Chill. Bridge ABI 7, helper
  protocol 1 and the hy3 provider pin are unchanged.

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
