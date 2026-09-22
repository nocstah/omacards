# OmaCards

OmaCards is the optional Omarchy bar interface for Hyprflip. People use it to
find saved cards, switch between two app arrangements, edit their panes, and
choose motion and keyboard shortcuts. Hyprflip owns windows and
saved definitions; OmaCards is an interface to its shared Python workflows.

The confirmed everyday surface is a compact native bar popup alongside existing
keyboard shortcuts. Use Omarchy's current palette, fonts, controls and focus
behavior. Native desktop consistency and completing the workflow matter more
than decorative branding.

There are two faces, one to three apps per face with the optional hy3 provider.
Native pairs can be flipped; multi-app editing and saved arrangements require
containers. Live edits never silently overwrite saved definitions. Removing an
app from a card keeps the app open. Open saved cards directly, asking only when
an app or launcher is ambiguous.

Card actions have explicit targets. Looking at a hidden face does not turn it;
Show and edit explicitly activates it. Cancel should leave opened apps usable.
Motion preferences apply to all cards and honor Hyprland's animation setting.

Settings groups Motion and Keyboard shortcuts. The shortcut list shows active
bindings; choosing an editable action opens and focuses its inline editor.
People can record a combination, review conflicts, or choose that action's
default, then save the change. Conflicting desktop actions are never silently
replaced. Recording temporarily captures desktop shortcuts and releases them
when recording ends or the panel closes. Failed saves keep the draft available
for correction or retry. The Cards footer reflects the current Edit and Saved
cards bindings.

When the backend supports floating cards, Float card makes the arrangement
movable and resizable as one card; Tile card returns it to the desktop layout.
A saved card's Manage workflow can keep opening on the current workspace or
always use a chosen workspace. These choices use Hyprflip's existing workflows
and saved library, alongside the existing card questions and feedback.

This first version excludes additional faces, arbitrary nested groups, automatic
login restoration, live thumbnails, cloud accounts and per-card animation rules.

Working name: OmaCards, powered by Hyprflip. OmaFlip is already used by another
Omarchy project. The name does not imply affiliation with Omarchy or Hyprland.
