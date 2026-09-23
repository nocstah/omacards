# OmaCards

**Keep a project or a workflow together in one two-sided card.** OmaCards is
the Omarchy bar panel for [Hyprflip](https://github.com/nocstah/hyprflip): create
cards, edit their apps, save arrangements and bring them back on a chosen workspace.

A card has a **Front** and a **Back**, with up to five real app windows on
each side. Flip it to reveal the other side in the same desktop space. Your
apps stay running, and the card remembers which app you were using on each side.
Temporarily **Unfold** it when you need to see both sides at once, then fold
it back when you are done.

## What could you use it for?

| Card | Front | Back | Where it opens |
| --- | --- | --- | --- |
| Project | Editor and terminal | Browser preview | Workspace 2 |
| Comms | Gmail | WhatsApp and Telegram | Workspace 3 |
| Research | Document reader | Notes and a browser | Your current workspace |

These are examples, not presets or required apps. Build a card from the windows
you already use. Give each project its own saved arrangement and workspace, or
keep a floating communications card that you can move and resize as one unit.

![Hyprflip demonstrating a two-sided card](https://raw.githubusercontent.com/nocstah/hyprflip/537c4d5fea96a393048f161e3a220abf4e502c15/media/dwindle-preview.gif)

[Watch the full desktop demo](https://github.com/nocstah/hyprflip/blob/537c4d5fea96a393048f161e3a220abf4e502c15/media/dwindle-demo.mp4).
The footage uses sample windows on native dwindle with the Hyprflip core alone.
OmaCards adds the native bar controls below.

![OmaCards editor with sample app names](media/editor.png)

The screenshot uses synthetic example content. OmaCards follows your current
Omarchy theme and font.

## Your first card

After [installing the backend and panel](#requirements):

1. Open the apps you want to use, then focus the app for the front, such as Gmail.
2. Click the OmaCards icon in the bar, choose **Create a new card**, then
   **Choose app for back…** and select WhatsApp. The apps are grouped automatically.
3. Open **Edit** to add Telegram to the back. Apps can come from this workspace
   or another one; you can arrange them beside each other or stack them vertically.
4. Save the arrangement as **Comms**. Under **Manage → Workspace… → Always use
   a workspace…**, choose `3` if that is where you want it to open every time.
5. Next time, select **Comms** from the saved-card library. OmaCards goes to the
   existing card or uses Hyprflip to restore the arrangement and launch missing
   apps that have a supported launcher.

Saved cards remember their app assignments, pane layouts, floating mode and
workspace destination. They do not back up application data or unsaved documents;
each app controls its own documents, browser tabs and login state.

## What it does

- **Cards:** flip, unfold/fold, save, or create an arrangement. Search your saved
  cards and select one to open it here or go to its existing workspace.
- **Edit:** see Front and Back, add apps from this or another workspace, replace
  or remove any pane, move it across sides, reorder panes, and switch between
  beside/stacked layouts. Removed apps remain open.
- **Saved arrangements:** rename, duplicate, delete, deliberately update the
  saved layout, choose a destination workspace, or reopen missing apps through
  the same Hyprflip workflows.
- **Floating cards:** float or tile the whole arrangement, then move and resize
  all of its apps together.
- **Settings:** Classic tabs or an experimental card frame, Desktop or Compact
  spacing, motion, and editable keyboard shortcuts with conflict checks and
  per-action defaults.
- **Motion:** seven transitions, individual previews, speed presets and exact
  duration. Dissolve and Portal are experimental. Settings apply to all cards.
- **Keyboard:** search with arrows and Enter, Tab through controls, Escape to
  go back or cancel. The footer shows the current Edit and Saved-card shortcuts.

OmaCards runs in Omarchy's shell. It does not replace the compositor plugin,
maintain a second card database, or start a background Python daemon.

## Appearance, spacing and dragging

With the pinned Hyprflip core and helper below, Settings
offers **Classic tabs** or **Card frame (Experimental)**, plus **Desktop
spacing** or **Compact spacing (12 logical pixels)** between apps. Choices apply
to existing cards and survive configuration reloads and restarts.

Cards support **five apps per side**, subject to the apps'
minimum sizes. Hold Super and drag an outside window onto the **Drop to add to
Front/Back** target to add it to that face. The highlighted slot previews the
placement; Escape or dropping elsewhere cancels the add. When unfolded, either
face can receive the app. Native one-app pairs need a multi-app container first.

These controls detect backend capabilities. Install the exact pinned revision
below, including its matching core and helper, to enable these features.
The hy3 provider is only needed on hy3 workspaces. Updating the panel alone
does not update the compositor libraries.

## Requirements

This is the **0.2.0-rc.1 preview**, paired with Hyprflip’s 0.3.0 dwindle preview.

- Omarchy 4's stock Quickshell bar; tested with 4.0.4.
- Hyprflip at **`537c4d5fea96a393048f161e3a220abf4e502c15`** (bridge ABI 7),
  including its JSON helper (protocol 1), Python 3 and GLib.
- **Dwindle:** multi-app and saved cards need only the core and helper. Keep
  Omarchy’s default workspace layout; no hy3 installation is required.
- **Hy3 (optional):** use the matching provider if you already use hy3.
  A basic native pair still supports Flip and Motion.

### Install the pinned Hyprflip dependency

This OmaCards revision is bound to Hyprflip commit
[`537c4d5fea96a393048f161e3a220abf4e502c15`](https://github.com/nocstah/hyprflip/tree/537c4d5fea96a393048f161e3a220abf4e502c15).
Use this exact revision for both the compositor components and the helper that
OmaCards executes. The optional hy3 provider is itself pinned by that revision to
`42b7ed8fd9aefd3f36e5f617afd5071245c67853`.

Create a separate checkout and verify its revision:

```sh
git clone --no-checkout https://github.com/nocstah/hyprflip.git hyprflip-omacards &&
git -C hyprflip-omacards checkout --detach 537c4d5fea96a393048f161e3a220abf4e502c15 &&
test "$(git -C hyprflip-omacards rev-parse HEAD)" = 537c4d5fea96a393048f161e3a220abf4e502c15
```

For a first installation on **dwindle**, run the block below from the directory
containing `hyprflip-omacards`. It verifies the revision, builds and installs the
core, then installs the shared helper. Dependencies and alternative installation
methods are in [the installation guide at that same commit](https://github.com/nocstah/hyprflip/blob/537c4d5fea96a393048f161e3a220abf4e502c15/docs/INSTALL.md).

For an existing installation, save and ungroup active dwindle cards before
updating, then reopen them. Existing hy3 cards use the guide’s provider updater.
Installing the OmaCards panel itself does not replace compositor libraries.

```sh
(
  set -eu
  cd hyprflip-omacards
  test "$(git rev-parse HEAD)" = 537c4d5fea96a393048f161e3a220abf4e502c15
  test -z "$(git status --porcelain --untracked-files=all)"
  make test
  python3 scripts/install.py --dry-run
  python3 scripts/install.py
  python3 scripts/install-setup.py --dry-run
  python3 scripts/install-setup.py
)
```

For basic pairs without multi-app controls, add `--backend-only` to both
`install-setup.py` commands.
This installs the helper and persistent motion preferences without rebinding
container shortcuts. The installer backs up replaced files and checks that
existing cards survive the configuration reload. The installed entry point is
`~/.local/lib/hyprflip/control.py`; it comes from this verified checkout.

## Install

After installing the Hyprflip helper above:

```sh
omarchy plugin add https://github.com/nocstah/omacards.git --enable --yes
```

`--yes` accepts Omarchy's plugin-installation prompt. The installer clones the repository to
`~/.config/omarchy/plugins/io.github.nocstah.omacards/` and adds the bar icon.
Click the cards icon to open the panel.

To update:

```sh
omarchy plugin update io.github.nocstah.omacards
```

Dependency updates are explicit: when a newer OmaCards release changes the
Hyprflip pin, install its documented immutable revision before updating the panel.
If an update leaves old controls visible, close the panel and run
`omarchy restart shell` on an unlocked desktop to clear its cached QML.

With the updated helper, **Super+Ctrl+Alt+C** opens Edit and
**Super+Ctrl+Alt+L** opens the library. If OmaCards is disabled or unavailable,
those shortcuts use the original native menus. **O** keeps guided creation and
fold/unfold, **F** keeps flip, and **Space** keeps hold-to-peek. Super+J is unchanged.

You can also open it from a terminal:

```sh
omarchy-shell omacards open cards
omarchy-shell omacards open edit
omarchy-shell omacards open library
omarchy-shell omacards open settings
omarchy-shell omacards open motion
omarchy-shell omacards open shortcuts
```

## Use and recovery

Focus an app before opening the panel to select its card. If it is ungrouped,
**Create a new card** names that app as the front. Choose **Choose app for back…**
and select another open app. Floating apps are resized to fit automatically;
you do not need to arrange them first or confirm a separate tiling step.
Saved cards appear separately above creation;
you can open them without creating anything. If several cards share a workspace,
choose one from the list. Hidden faces offer **Show and edit Front/Back**;
that action turns the card before offering edits.

In Edit, select a visible app to reveal its pane actions. **Manage saved** offers
Update when the running card can be saved. Ordinary live edits leave the saved
definition unchanged. Opening an already open card goes to it; it does not
launch a duplicate. Cancellation leaves launched apps open and uses Hyprflip's
existing partial-operation recovery.

If a window closes or moves while choosing, the operation stops with a refresh
message. Keep the original native menu available explicitly:

```sh
python3 ~/.local/lib/hyprflip/setup.py --legacy --cards
omarchy-shell omacards status
```

Motion, appearance and spacing preferences are stored with Hyprflip, in
`$XDG_STATE_HOME/hyprflip` (normally `~/.local/state/hyprflip`), alongside the existing saved-card library. Disabling
OmaCards leaves them, your apps, cards and compositor plugins intact:

```sh
omarchy plugin disable io.github.nocstah.omacards
omarchy plugin enable io.github.nocstah.omacards
```

To remove the panel entirely:

```sh
omarchy plugin remove io.github.nocstah.omacards
```

Removal disables OmaCards and removes its installed checkout. Your apps, saved
cards, motion preferences, keyboard shortcuts and separately installed Hyprflip
components remain available. The shared shortcuts fall back to Hyprflip's native
menus once OmaCards is unavailable.

Replacement bars and older Omarchy shell APIs have not been validated. No
compositor restart is needed for this QML interface.

## Development and checks

See [the protocol](https://github.com/nocstah/hyprflip/blob/537c4d5fea96a393048f161e3a220abf4e502c15/docs/PANEL_API.md).
The workflow backend belongs to Hyprflip; do not copy it into this project.

For local development, clone this repository and pass its absolute path to
`omarchy plugin add /absolute/path/to/omacards --enable --yes`. It must be a Git
checkout with `manifest.json` at the root. Run development checks from that checkout.

```sh
omarchy plugin validate .
python3 tests/render.py
python3 tests/run-native.py /tmp/oc-demo/session.json \
  --backend /path/to/hyprflip/scripts/control.py --dwindle
```

The last check requires Hyprflip's disposable three-window session:
`python3 tests/nested_session.py --directory /tmp/oc-demo --native-cards` from its
checkout. The runner rejects a live desktop connection, creates a headless
test output, and tests popup focus, flip/unfold, structured save/edit, motion
and direct saved-card activation. Rendering uses synthetic fixture data.
For the optional hy3 path, launch with `--containers` and omit `--dwindle`.

MIT licensed. Built on Hyprflip and Omarchy's native shell components.

## Floating cards, shortcuts and destinations

**Float card** turns the whole arrangement into one movable, resizable card.
Drag or resize any visible app with your normal desktop mouse shortcuts.
**Tile card** returns it to the layout. Guided creation keeps a floating front
app floating and fits the selected back apps into its frame.

Choose **Settings → Keyboard shortcuts**, select an action, then Record shortcut.
Press a combination containing Super, Ctrl or Alt and choose Save shortcut.
Conflicts identify the existing action; they are never silently replaced.
Use default restores one action's default. Recording temporarily inhibits normal
desktop shortcuts, then releases them on completion or closing the panel.
Bindings and motion preferences survive configuration reloads and restarts.

Under a saved card, choose **Manage → Workspace… → Always use a workspace…**.
Enter `3` to make Comms always open on workspace 3. If that card is already open,
opening it moves it to 3. Current workspace removes the fixed destination.
No second card database is created; updating a saved arrangement preserves its
destination. Saved floating mode is restored, while exact screen coordinates
are chosen by the current desktop layout.
