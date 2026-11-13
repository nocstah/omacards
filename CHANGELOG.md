# Changelog

## Unreleased

- Pin Hyprflip to [`v0.3.0-rc.22`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.22)
  (`910371b0c97fea19cfa9abb0357ab4a76a6030a4`). With rc.26's pin, updating
  or reinstalling Hyprflip from the panel over an earlier install stopped at
  the build step ("Hyprland links Lua 5.5, but pkg-config found Lua 5.4.9"),
  leaving the installed Hyprflip as it was; rc.22 builds there. Hyprflip 0.3.0-rc.16 or
  later still counts as current; helper protocol 1 is unchanged.

## 0.2.0-rc.26 — 2026-11-13

- Pin Hyprflip to [`v0.3.0-rc.21`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.21)
  (`e0cbedd7e91164ae734b39b6af1bbe6e276752aa`), which adds
  `scripts/uninstall.py` and builds its plugin against the Lua that Hyprland
  links (5.5 on current Arch). Building it now also needs `readelf`
  (binutils). Hyprflip 0.3.0-rc.16 or later still counts as current; helper
  protocol 1 is unchanged.
- **Install build tools** also accepts `binutils` and `lua54`, the packages
  Hyprflip 0.3.0-rc.21's prerequisite check can now name, for `readelf` and
  for a Hyprland that links Lua 5.4.

## 0.2.0-rc.25 — 2026-11-11

- The README names **Super+Ctrl+Alt+Tab** as the key that changes face, as
  Hyprflip 0.3.0-rc.20 binds it (F up to 0.3.0-rc.19). The panel reads its
  shortcut rows from Hyprflip, so Settings shows whichever key is bound.
- Pin Hyprflip to [`v0.3.0-rc.20`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.20)
  (`36f97a275ac1f94bd9ff3768a32c95b6197ae247`), which moves changing face to
  Tab, keeps the gap beside a card while its faces slide, lets apps a slide
  waits for draw while unseen, and rebuilds cards that name an app on two
  faces. Hyprflip 0.3.0-rc.16 or later still counts as current; helper
  protocol 1 is unchanged.

## 0.2.0-rc.24 — 2026-11-10

- Choosing an app on any hidden face, including a third or fourth one, shows
  that face, focuses the app and keeps it selected, with a Hyprflip helper
  that has the face action (`capabilities.show_face`). A hidden face's own
  action becomes **Show Face 3** and no longer opens Hyprflip's edit chooser.
  Older helpers keep rc.22's behaviour.
- Pin Hyprflip to [`v0.3.0-rc.19`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.19)
  (`3830874e3babd559affcb5fe702e14312c06142a`), which adds the face action.
  Hyprflip 0.3.0-rc.16 or later still counts as current; helper protocol 1 is
  unchanged.

## 0.2.0-rc.23 — 2026-11-10

- With a Hyprflip helper that reports `ungroup_any_face`, Ungroup goes through
  the shown side even when it holds several apps, so it is never disabled.
  Older helpers keep the one-app-side rule from rc.22.
- Pin Hyprflip to [`v0.3.0-rc.18`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.18)
  (`ed61e4f1635df27c8b5e42addabd6ea8713b015c`), which ungroups from any side
  and brings the core behind Settings' **Card keys beside a card** switch.
  Hyprflip 0.3.0-rc.16 or later still counts as current; helper protocol 1 is
  unchanged.

## 0.2.0-rc.22 — 2026-11-10

- Ungroup works again when the shown side has several apps. Hyprflip ungroups
  through a side with one app, so the panel now uses such a side; when every
  side has several apps, Ungroup is disabled and says how to get there.
  In rc.21 it failed with “That action is no longer available”.
- Choosing an app on a two-face card's hidden side flips to it and keeps it
  selected, instead of opening Hyprflip's edit chooser. On cards with three
  or more faces those rows are disabled and say which face the app is on.
- The panel catches up right after a card turns, instead of showing the old
  face for up to five seconds.
- The native test stops early with a clear message when the headless output
  stays 0×0 (an NVIDIA GPU without `--aquamarine`), and now also covers hidden-
  face selection, reordering and Ungroup. It can run repeatedly on one session.

## 0.2.0-rc.21 — 2026-11-10

- Settings has a **Card keys beside a card** switch, shown when Hyprflip
  supports it: flip, faces, unfold and peek can also act on the one card on a
  workspace from a window that is in no card, such as a terminal.
- Settings use the shell's own switches and button groups: Accent ring and
  Card keys beside a card are switches, and appearance, spacing, divider and
  speed are button groups with the chosen option explained beneath. Motion and
  Keyboard shortcuts come first.
- Saving a preference no longer blanks the panel or moves focus: the page
  stays, “Saving…” shows beside the heading, and the bar tooltip says so.
- Keyboard: arrows and h/j/k/l move between controls by row and column, Tab
  reaches every control, Space activates actions, and Escape clears a search
  before it closes anything. Focus returns to the control you used when an
  edit brings the panel back or a refresh rebuilds the rows. In the edit page,
  Ctrl+Up/Down moves the selected app and Delete or x removes it.
- The edit page puts an app's actions directly under it and names the app in
  them for screen readers. Moving apps, changing a face's layout and equal
  sizes keep the app selected. Beside and Stacked are one button group.
  Selecting an app on a hidden face shows that face. Ungroup moved to the card
  actions and asks first, in place. Disabled actions say why.
- Installing Hyprflip says so, explains that the panel can close while it
  continues, and no longer offers a Cancel that did nothing. A finished install
  drops its steps; a failed one keeps them, with the command to run
  selectable. A first run without Hyprflip reads as a next step, not an error,
  and the Refresh Cards button is gone (the panel refreshes itself).
- Errors sit in a callout outlined and tinted with the theme's urgent colour,
  with the words in full-contrast text, including saved-library and shortcut
  errors. Helper failures say what to do next.
- Rows highlight only where focus is, as the shell's own panels do, and the
  pointer moves focus only when it really moves. Choices report whether they
  are selected, and switches whether they are on, to screen readers.

## 0.2.0-rc.20 — 2026-11-10

- Hyprflip 0.3.0-rc.16 or any later release counts as current, so a newer
  Hyprflip is no longer offered as an "update" back to the pinned one, and
  Hyprflip-only releases need no OmaCards change. Install and Update still
  fetch the tested commit below. Installs from Hyprflip releases that record
  only a commit count as current when it is that commit.
- Pin Hyprflip to [`v0.3.0-rc.17`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.17)
  (`5420498f1cce0295ec03c65ea0a81de2ab350448`), which records the release it
  installs, and reveal slides. Helper protocol 1 is unchanged.

## 0.2.0-rc.19 — 2026-11-09

- Faces show their own names (such as Mail or Code) when they have one, in
  the cards list and the edit page.
- Pin Hyprflip to [`v0.3.0-rc.16`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.16)
  (`f9fcd81fdb8b50ec7de0c940836d8029aad53009`): cards with three or more faces
  slide sideways, the flip key's face switcher, the trackpad swipe,
  Super+Ctrl+Alt+1–4 and face names. Helper protocol 1 is unchanged.

## 0.2.0-rc.18 — 2026-11-09

- Cards with up to four faces. The cards list names every face (Front, Back,
  Face 3, Face 4) and says “All faces visible” when one is unfolded. The edit
  page shows and edits any face, moves an app to the next face (“Move to
  Face 3”), removes a face by removing its only app, and adds an open app as a
  new face with **Add as new face…**, offered while the card has room. Two-face
  cards look and work as before.
- Pin Hyprflip to [`v0.3.0-rc.15`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.15)
  (`17d8fc1d3e8a316389fbea90bee7a24372c70c68`). Helper protocol 1 is unchanged;
  it adds face names and `capabilities.faces`.

## 0.2.0-rc.17 — 2026-11-09

- Pin Hyprflip to [`v0.3.0-rc.14`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.14)
  (`94f44adccbb5b412bde2931bef193c74af5617a7`): hy3 is retired and cards are the
  core's own, tiled on dwindle or floating. Add beside (H), Add below (V) and
  Remove focused app (E) have default keys again. Releasing an app keeps the
  focus, moving one to the other face keeps the panes' proportions, and
  replacing a tiled app trades tiles at the same size. The README and test
  runner drop the hy3 provider. Helper protocol 1 is unchanged.

## 0.2.0-rc.16 — 2026-11-09

- Pin Hyprflip to [`v0.3.0-rc.13`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.13)
  (`dc2db6e26f7ef0fca624c645ed8354c700fe2d8d`): opening a saved card that is open
  on another workspace brings it to yours instead of sending you there, and one
  saved floating that became a tile floats again. Reopening missing apps rebuilds
  the card at a size that fits them. Saved rows read “Bring here from
  workspace …” or “Open on this workspace”. Bridge ABI 7 and helper protocol 1
  are unchanged.

## 0.2.0-rc.15 — 2026-11-08

- Pin Hyprflip to [`v0.3.0-rc.12`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.12)
  (`667302e2b668d5266a117a83839de278f0fefbfe`): saved cards open in one step at a
  size that fits their apps, so a floating card whose front app sits in a narrow
  tile no longer fails with “failed to add”. A refusal names the app and the
  sizes. Bridge ABI 7 and helper protocol 1 are unchanged.
- The panel's message wraps instead of being cut off at the panel's edge, so a
  longer explanation shows in full. The render fixtures add a narrow `refused`
  capture of one.

## 0.2.0-rc.14 — 2026-11-03

- Pin Hyprflip to [`v0.3.0-rc.11`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.11)
  (`c503ab643c259e43d7e6de1347cd4cef2b3ab9da`): quiet card lifecycle controls, unattended
  card definitions, native open/close animations and safer updates. Bridge ABI 7
  and helper protocol 1 are unchanged.
- An installation no longer claims every open card was kept. The installer’s
  step details report cards left as separate windows and any layout recovery
  limits.

## 0.2.0-rc.13 — 2026-11-01

- Pin Hyprflip to [`v0.3.0-rc.10`](https://github.com/nocstah/hyprflip/releases/tag/v0.3.0-rc.10)
  (`651aee31dd42007569252192bfb4a4cd6ba6e424`): other programs can drive a
  card by its id without taking the focus, and park a native card on a special
  workspace, where Find leaves it out. A card turned while the focus is
  elsewhere gets its resting opacity back. Bridge ABI 7 and helper protocol 1
  are unchanged.
- The panel keeps its colours with Qt 6.12, which adds a `Color` singleton of
  its own. An unversioned `import QtQuick.Window` brought Qt's back over
  Omarchy's, so the panel's text, borders and "Showing" labels lost their
  colours. The panel now names the module, as the stock shell does.

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
