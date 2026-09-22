---
name: OmaCards
description: A compact native Omarchy popup for operating Hyprflip cards.
typography:
  headline:
    fontFamily: "monospace"
    fontWeight: 700
  title:
    fontFamily: "monospace"
    fontWeight: 700
  body:
    fontFamily: "monospace"
    fontWeight: 400
  label:
    fontFamily: "monospace"
    fontWeight: 400
components:
  action:
    typography: "{typography.body}"
  choice-row:
    typography: "{typography.body}"
  text-field:
    typography: "{typography.body}"
---

# Design System: OmaCards

## Overview

**Creative North Star: "Omarchy's native card controls"**

OmaCards is an Operate surface: a compact bar popup for choosing a saved card,
acting on a running card, editing its two faces, and adjusting shared motion.
Its visual authority is the installed Omarchy shell. It inherits the user's
current theme, font alias, control states, and popup geometry; it introduces no
independent brand palette or display typography. This follows the confirmed
direction in [PRODUCT.md](PRODUCT.md).

The surface is dense, text-led, and explicit about its targets. Front and Back
stay understandable through names, app lists, small layout diagrams, and the
word “Showing.” App icons support recognition. Navigation, choices, progress,
and errors occupy the same native popup rather than creating another visual
layer.

**Key Characteristics:**

- Live Omarchy theme and font bindings.
- Compact, scrollable controls anchored to the invoking bar and screen.
- Plain text, recognizable app icons, and small structural diagrams.
- Shared pointer and keyboard state treatments with explicit action targets.

This document describes the QML artifact. The frontmatter records the system
font alias and stable text roles, not a resolved font face. Size, color, spacing,
and radius are runtime QML bindings; the tables below identify their normative
sources. CSS color strings cannot encode those bindings, so no theme snapshot
or invented CSS variables appear in the frontmatter. The sidecar records native
metadata without HTML/CSS component previews; a web shadow DOM cannot render
the host's QML controls or remain live-bound to `qs.Commons`.

## Colors

The palette is whichever Omarchy theme is active, including its per-surface
overrides. No fixed light or dark palette belongs to OmaCards.

### Primary

| Native reference | Use in OmaCards |
| --- | --- |
| `Color.accent` | “Showing” labels, diagrams for visible faces, and the inherited control accent input. |
| `Color.urgent` | Helper failure notices and saved-library errors. |

### Neutral

| Native reference | Use in OmaCards |
| --- | --- |
| `Color.popups.background` | Outer `Ui.KeyboardPanel` surface. |
| `Color.popups.text` | Local `Label` text, including secondary explanations, pane titles, and diagram/icon fallback strokes. |
| `Color.popups.border` | Popup border through `Border.surfaceSpec`. |
| `Color.foreground` | Host `Ui.Button`, `Ui.TextField`, `Ui.CursorSurface`, and separator defaults. Local popup text and host control text remain distinct bindings. |
| `Color.tooltip.background`, `.text`, `.border` | Tooltips supplied by the host button components. |
| `bar.barForeground`, `bar.urgent` | Host bar entry colors through `Ui.WidgetButton`, falling back to `Color.foreground` and `Color.urgent` if no bar is available. |

The source is [Commons/Color.qml](/usr/share/omarchy/shell/Commons/Color.qml).
It reads the current theme's `colors.toml`, then surface roles from the theme's
`shell.toml` merged with the user's `~/.config/omarchy/shell.toml`; absent surface
roles fall back to the foundational palette.
Control state colors and alpha values belong to
[Commons/Style.qml](/usr/share/omarchy/shell/Commons/Style.qml) and
[Commons/Border.qml](/usr/share/omarchy/shell/Commons/Border.qml), including
theme overrides. These bindings must stay live.

**The Native Binding Rule.** Use `Color`, `Style`, and `qs.Ui` at the point of
use. Do not copy a theme's resolved values into OmaCards or introduce a competing
palette.

**The Functional Text Rule.** Keep local explanatory text on
`Color.popups.text` at full opacity. Use hierarchy, spacing, and font size for
secondary information; reserve the action wrapper's disabled opacity for
disabled actions.

## Typography

**Body and label font:** the host's `monospace` fontconfig alias, bound through
`Style.fontFamily` or `Style.font.family`. The concrete family is chosen by
Omarchy; do not substitute `Style.resolvedFontFamily` as a fixed font binding.
There is no separate display face.

The hierarchy is the shell's compact monospace ramp. The frontmatter weights
describe the regular and bold roles; selection may make row titles or buttons
bold. All locally authored text uses `Text.PlainText` and wraps as required.

| Role | Native size | Use |
| --- | --- | --- |
| Headline | `Style.font.heading` | Cards, Edit card, and Motion for all cards headings; bold. |
| Title | `Style.font.title` | Current card name in Cards; bold. |
| Body | `Style.font.body` | Actions, face labels, row titles, questions, and explanations. |
| Label | `Style.font.bodySmall` | Workspace context, row details, consequences, and footer text. |

The installed shell derives these sizes from `Style.fontBaseSize` using
multipliers (heading 1.333, title 1.167, body 1, bodySmall 0.917), rounded to
integer pixels, unless the theme pins a size. At its 12-pixel base these are
16, 14, 12, and 11 pixels. Those numbers explain the current host scale; they
are not OmaCards overrides. QML supplies normal line metrics; no custom line
height, tracking, or uppercase label style is established.

## Layout

The native popup is [Panel.qml](Panel.qml), wrapping `Ui.Panel` and
`Ui.KeyboardPanel`. Its requested width is `Style.space(440)`. The content's
implicit height is capped at `Style.space(660)`; the outer popup uses
`fittedContentHeight` with a `Style.space(680)` cap. The host clamps the panel
to the invoking screen's available dimensions, accounts for the bar, padding,
and border, and uses `Style.gapsOut` for its edge/bar gap.

The host adds `Style.spacing.popupPadding`. Inside, a single clipped
`Flickable` holds a `ColumnLayout`; a vertical scrollbar appears when content
exceeds the viewport. Button groups use `Flow` to wrap. Rows wrap their text
rather than treating a narrow screen as a different layout mode. There are no
OmaCards breakpoint tokens. Focus and list cursor changes scroll their target
into view.

All custom spacing uses `Style.space(n)`. The durable observed rhythm is:

| Binding | Recurring purpose |
| --- | --- |
| `Style.space(12)` | Main sections and editor face sections. |
| `Style.space(10)` | Cards content separation and choice-row horizontal inset. |
| `Style.space(8)` | Current-card and motion content grouping. |
| `Style.space(6)` | General action groups. |
| `Style.space(4)` | Dense pane and face action groups. |
| `Style.space(2)` | Saved-row separation and diagram pane gaps. |

`Style.space` scales and rounds these inputs through the host's spacing and
font settings. Host controls use their own semantic spacing tokens, including
`controlPaddingX`, `controlPaddingY`, and `inputPaddingY`. Keep those bindings
rather than replacing them with the current pixel output.

## Elevation & Depth

OmaCards adds no shadows. The popup's theme border, separator rules, and shared
state fills convey structure. The background outside the visible popup is
transparent; the host handles dismissal and input capture. Do not reinterpret
that input layer as a visible dimming scrim.

Motion comes from the existing host components: `Ui.KeyboardPanel` fades its
card opacity over 140 ms with `Easing.OutCubic`; `Ui.Button` animates its fill
over 120 ms; `Ui.CursorSurface` animates its fill over 60 ms. These are inherited
implementation details, not new OmaCards motion tokens. The Motion view controls
Hyprflip's separate desktop transition; it does not change these shell effects.

## Shapes

Popup, button, field, and choice-row corners use `Style.cornerRadius`, which
the host obtains from Hyprland's `decoration:rounding`. A square theme remains
square. Popup borders use `Border.surfaceSpec`; interactive borders use
`Border.controlSpec`, preserving theme border geometry and state behavior.

Local face diagrams use one outlined rectangle per pane, arranged beside or
stacked according to the returned axis. Their corners are bounded by
`Math.min(Style.cornerRadius, Style.space(2))`; strokes are one pixel. The
missing-app-icon fallback is a small outlined window using the same bounded
rounding. Dividers come from `Ui.PanelSeparator`; they are structural rules,
not container outlines around every section.

## Components

### Actions

Direct text actions inherit [Ui.Button](/usr/share/omarchy/shell/Ui/Button.qml)
through [Action.qml](Action.qml). They are borderless at rest unless host state
styling requires a border. Padding, rounding, hover, focus, pressed, and selected
states belong to the host. The local wrapper enables Tab focus, exposes an
accessible button name, and uses opacity 0.45 only when disabled. Selected
layout and speed choices use the host selected state and bold text.

### Choice rows

[ChoiceRow.qml](ChoiceRow.qml) extends `Ui.CursorSurface`. It has a title,
optional smaller detail, and an optional app icon. Its height is the wrapped
label column plus `Style.space(16)`; the text inset is `Style.space(10)` or
`Style.space(38)` when an icon is present. Icons occupy `Style.space(20)` and
use the desktop icon theme or supplied local path. A drawn window fallback
keeps missing icons legible.

Persistent selection uses `current`; pointer hover or actual focus uses
`hasCursor`. Enter and Space activate a focused row. In backend choice lists,
arrow navigation moves actual row focus and synchronizes `choiceCursor`, so
the highlighted row and activated answer agree. In the saved library, focus
stays in search while arrows change its selected result; Enter performs that
result's stated open/go-to action.

### Fields

Search, card naming, and exact duration use
[Ui.TextField](/usr/share/omarchy/shell/Ui/TextField.qml) directly. Font, padding,
selection, placeholder, focus fill, and border behavior remain host-owned.
Each field exposes an accessible name. Search is the Cards entry focus; naming
questions focus the name field. Exact duration is revealed by “Exact time…”
and constrained to the backend's supported input range in the shipped UI.

### Two-face editor

Front and Back are stacked sections separated by native rules. Each header
combines a name, pane diagram, app count, and “Showing” when visible. Pane rows
show app icons and names. Selecting a visible pane reveals its inline action
group and the consequence “Removal keeps the app open.” Hidden faces offer an
explicit “Show and edit” action.

Pane selection is keyed by the card key and pane address, not the snapshot
object identity. It survives refresh while that card and pane still exist.
Changing target, removing the pane, leaving Edit, or issuing an edit clears it
as implemented in [CardsContent.qml](CardsContent.qml). These are in-memory UI
rules; they do not promise selection persistence across shell restarts.

**The Explicit Target Rule.** Inspecting a hidden face does not activate it.
Show the named activation action before editing that face, and keep pane actions
attached to the selected pane.

### Bar entry and navigation

[BarWidget.qml](BarWidget.qml) uses the host `Ui.BarIconButton` and optical
alignment. Its current cards-outline Nerd Font glyph is inherited compatibility
with the host bar, not a glyph-icon rule for new OmaCards controls. Opening or
working marks the button active; the tooltip explains its action/progress.

Cards, Edit, and Motion share a heading row with text navigation. Ordinary
opening starts at Cards; the supported summon routes can enter another view.
Escape backs out, cancels an active question, or closes from Cards. Search,
pane selection, and exact-time disclosure are UI state, not a new preferences
store. `Service.qml` delegates saved-card and motion writes to Hyprflip; this
design record does not certify backend persistence or restart behavior.

### Feedback

Backend questions, opening progress, cancellation, and actionable failures use
the same popup and local labels. Progress offers one Cancel action and explains
that opened apps stay open. When no card is selected, saved cards come before
a separate creation section that names the front app and offers a nearby
“Choose app for back…” action. With no saved cards, creation leads and search
is hidden. The footer names the Edit and Saved cards shortcuts explicitly.
Creation explains that apps resize to fit automatically; selecting a floating
app does not introduce a separate confirmation about tiling.
Capability-dependent controls and nearby explanations make unavailable
editing understandable without changing the surface's visual system.

## Do's and Don'ts

### Do:

- **Do** keep native `Color`, `Style`, `Border`, and `qs.Ui` bindings live.
- **Do** use full-opacity popup text for local functional explanations.
- **Do** pair face state with the word “Showing,” app names, and pane diagrams.
- **Do** preserve keyboard activation, visible focus, and scrolling to targets.
- **Do** verify narrow, scaled, light, and dark host configurations when extending the popup.

### Don't:

- **Don't** add a private palette, fixed resolved font, radius scale, or shadow system.
- **Don't** invent CSS tokens or HTML previews that claim to reproduce live QML bindings.
- **Don't** use glyph icons as a new app-control convention; preserve the existing host bar integration separately.
- **Don't** treat a refreshed snapshot object as a different selected card or pane.
- **Don't** imply that UI selection or documented tokens create durable preferences.
