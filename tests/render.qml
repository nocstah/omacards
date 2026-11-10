//@ pragma OmarchyLoadPatch
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import "Cards" as Cards

ShellRoot {
    id: harness
    property int step: 0
    property var original: null
    property var shots: ["cards", "settings", "preferences-narrow", "preferences-light", "preferences-dark", "preferences-scaled", "shortcuts", "shortcut-record", "shortcut-conflict", "settings-narrow", "settings-scaled", "edit", "motion", "motion-refresh", "question", "empty", "narrow", "scaled", "light", "dark", "pane-edit", "library-ungrouped", "no-front", "unselected-card", "long-front", "scaled-entry", "install-missing", "install-progress", "install-waiting", "outdated", "refused", "multi-face", "multi-face-narrow", "multi-face-scaled", "multi-face-edit", "multi-face-remove", "multi-face-edit-narrow", "multi-face-edit-scaled", "edit-add-face", "settings-dark", "error-dark", "ungroup-confirm",
        // In-flight shots come last, each followed by the moment it finishes.
        "applying", "applied", "working", "worked", "installing", "installed"]
    function findItem(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const found = findItem(child, name); if (found) return found }
        return null
    }
    // Every shot starts from one known theme, scale and size, so nothing
    // carries over from the shot before, including the live theme's [controls]
    // overrides. The urgent colors are the iOS Glass pair the live theme uses.
    function seed(dark) {
        Style.applyShellValues({})
        Commons.Color.shellValues = ({})
        Commons.Color.background = dark ? "#1c2026" : "#faf8f3"
        Commons.Color.foreground = dark ? "#e6e9ef" : "#242424"
        Commons.Color.accent = dark ? "#a9bfff" : "#2255aa"
        Commons.Color.muted = dark ? "#9ba6b5" : "#666666"
        Commons.Color.urgent = dark ? "#ff453a" : "#ff3b30"
    }
    // Keyboard checks: each move must land on the named control.
    function focusName() { return window.activeFocusItem ? content.focusKey(window.activeFocusItem) : "none" }
    function focusOn(key) {
        const item = content.focusables().find(i => content.focusKey(i) === key)
        if (item) item.forceActiveFocus(); else console.error("Keyboard: no control " + key)
    }
    function expectKeys(page, steps) {
        for (const [move, expected] of steps) {
            move()
            if (focusName() !== expected) console.error("Keyboard on " + page + ": expected " + expected + ", focused " + focusName())
        }
    }
    function checkKeys(name) {
        if (name === "settings") {
            content.focusEntry()
            expectKeys(name, [
                [() => content.moveFocus(0, 1), "accessibleName:Back"],
                [() => content.moveFocus(1, 0), "accessibleName:Close"],
                [() => content.moveFocus(0, 1), "title:Motion"],
                [() => content.moveFocus(0, 1), "title:Keyboard shortcuts"],
                [() => content.moveFocus(0, 1), "accessibleName:Card appearance, Classic tabs selected"],
                [() => content.moveFocus(0, 1), "accessibleName:App spacing, Compact selected"],
                [() => content.moveFocus(0, -1), "accessibleName:Card appearance, Classic tabs selected"],
                [() => content.moveTab(-1), "title:Keyboard shortcuts"],
                [() => { harness.focusOn("accessibleName:Back"); content.moveTab(-1) }, "label:Card keys beside a card"],
                [() => content.moveTab(1), "accessibleName:Back"]])
        }
        if (name === "pane-edit") {
            expectKeys(name, [
                [() => harness.focusOn("title:Telegram"), "title:Telegram"],
                [() => content.moveFocus(0, 1), "accessibleName:Replace Telegram"],
                [() => content.moveFocus(1, 0), "accessibleName:Move Telegram to Front"],
                [() => content.moveFocus(0, -1), "title:Telegram"]])
        }
        // Hyprflip ungroups from a side with one app: Front here. With
        // several apps on every side, Ungroup is offered nowhere.
        if (name === "ungroup-confirm") {
            if (content.ungroupFace !== 0) console.error("Ungroup should go through the one-app Front, not face " + content.ungroupFace)
            const crowded = JSON.parse(JSON.stringify(harness.original))
            crowded.cards[0].faces[0].panes.push(Object.assign({}, crowded.cards[0].faces[1].panes[0], {address: "0xfe"}))
            service.snapshot = crowded
            if (content.ungroupFace !== -1) console.error("Ungroup offered with several apps on every side")
            // A helper that ungroups from any side takes the shown one.
            const anyFace = JSON.parse(JSON.stringify(crowded))
            anyFace.capabilities.ungroup_any_face = true
            anyFace.cards[0].active = 1
            service.snapshot = anyFace
            if (content.ungroupFace !== 1) console.error("Ungroup should use the shown side, not face " + content.ungroupFace)
        }
        // A refresh that rebuilds the rows puts focus back on the same row.
        if (name === "motion-refresh" && focusName() !== "title:Slide") console.error("A refresh lost focus: " + focusName())
        // A saved preference keeps the page and the control in focus.
        if (name === "applied") {
            if (service.page !== "settings") console.error("Saving a preference left Settings")
            if (focusName() !== "label:Accent ring") console.error("Saving a preference moved focus to " + focusName())
        }
        if (name === "worked" && service.busy) console.error("The fake open did not finish in time")
        if (name === "installed" && service.installing) console.error("The fake install did not finish in time")
        if (["settings", "pane-edit", "motion-refresh", "ungroup-confirm", "applied", "worked", "installed"].includes(name)) console.log("OMACARDS_CHECKED " + name)
    }
    Cards.Service { id: service }
    FileView {
        path: Quickshell.env("OMACARDS_FIXTURE")
        onLoaded: {
            harness.original = JSON.parse(text())
            service.snapshot = JSON.parse(text())
            service.context = service.snapshot.context
            service.selectedKey = "container:1"
            harness.seed(false)
            capture.start()
        }
    }
    Window {
        id: window
        visible: true
        width: 468
        height: 700
        color: Commons.Color.popups.background
        Rectangle {
            id: area
            color: Commons.Color.popups.background
            anchors.fill: parent
            Cards.CardsContent { id: content; anchors.fill: parent; anchors.margins: 14; service: service }
        }
    }
    // Compile the real widget/popup too, without mapping a layer-shell surface.
    Cards.BarWidget { visible: false }
    Timer {
        id: capture
        interval: 500
        repeat: true
        onTriggered: {
            const name = harness.shots[harness.step]
            area.grabToImage(function(result) {
                if (!result.saveToFile(Quickshell.env("OMACARDS_CAPTURE_DIR") + "/" + name + ".png")) throw new Error("Capture failed")
                harness.checkKeys(name)
                harness.step++
                if (harness.step === harness.shots.length) { console.log("OMACARDS_UI_CAPTURE_OK"); Qt.quit(); return }
                const next = harness.shots[harness.step]
                harness.seed(next.includes("dark"))
                window.width = 468; window.height = 700
                // An "after" shot captures the operation started before it.
                if (["applied", "worked", "installed"].includes(next)) return
                service.question = null
                service.page = ["settings","shortcuts","edit","motion"].indexOf(next) >= 0 ? next : ["settings-dark", "applying"].includes(next) ? "settings" : next === "ungroup-confirm" ? "edit" : next === "motion-refresh" ? "motion" : "cards"
                service.snapshot = JSON.parse(JSON.stringify(harness.original))
                service.context = service.snapshot.context
                service.selectedKey = "container:1"
                if (next.startsWith("preferences-")) {
                    service.page = "settings"
                    window.width = next === "preferences-narrow" ? 340 : next === "preferences-scaled" ? 936 : 468
                    window.height = next === "preferences-narrow" ? 550 : next === "preferences-scaled" ? 1400 : 700
                    Style.spacingScale = next === "preferences-scaled" ? 2 : 1
                    Style.fontBaseSize = next === "preferences-scaled" ? 24 : 12
                    Commons.Color.shellValues = ({})
                    Commons.Color.background = next === "preferences-dark" ? "#1c2026" : "#faf8f3"
                    Commons.Color.foreground = next === "preferences-dark" ? "#e6e9ef" : "#242424"
                    Commons.Color.accent = next === "preferences-dark" ? "#a9bfff" : "#2255aa"
                    Commons.Color.muted = next === "preferences-dark" ? "#9ba6b5" : "#666666"
                }
                if (next === "shortcuts") {window.width=468;window.height=700;Style.spacingScale=1;Style.fontBaseSize=12}
                if (["shortcut-record", "shortcut-conflict", "settings-narrow", "settings-scaled"].includes(next)) {
                    service.page = "shortcuts"
                    const editor = harness.findItem(content, "shortcutSettings")
                    editor.choose(service.snapshot.shortcuts.rows[0])
                    editor.candidateMask = 76
                    editor.candidateKey = "C"
                    editor.error = next === "shortcut-conflict" ? editor.conflict(76,"C") : ""
                    editor.recording = next !== "shortcut-conflict"
                    if (next === "settings-narrow") { window.width = 340; window.height = 550 }
                    if (next === "settings-scaled") { window.width = 700; window.height = 900; Style.spacingScale = 2; Style.fontBaseSize = 18 }
                }
                if (next === "edit") {window.width=468;window.height=700;Style.spacingScale=1;Style.fontBaseSize=12}
                if (next === "question") service.question = {id: 1, mode: "select", prompt: "Choose an app for the back · Gmail stays on the front", choices: [{value: "a", label: "WhatsApp", detail: "Workspace 2"}, {value: "b", label: "Telegram", detail: "Workspace 2"}, {value: "w", label: "Add from workspace 5", detail: "Move an app here"}]}
                service.installSteps = []
                service.hyprflipState = "ready"
                service.failed = false
                service.notice = ""
                service.missingPackages = []
                service.awaitingPackages = false
                // A missing Hyprflip is a first-run step, not an error; a failed install is.
                if (["install-missing", "install-progress", "install-waiting", "installing"].includes(next)) {
                    service.snapshot = {available: false, cards: [], saved: [], capabilities: {}}
                    service.hyprflipState = "missing"
                    service.notice = "Hyprflip is not installed. Install it here; if build tools are missing, OmaCards opens a terminal to install them."
                }
                if (next === "install-progress" || next === "install-waiting") {
                    service.failed = true
                    service.notice = "Check prerequisites failed."
                }
                if (next === "install-progress" || next === "install-waiting") {
                    service.installSteps = [
                        {event: "step", id: "download", title: "Download the pinned Hyprflip release", status: "ok", detail: "Hyprflip v0.3.0-rc.18"},
                        {event: "step", id: "check", title: "Check prerequisites", status: "failed", detail: "Missing cmake, ninja", fix: "sudo pacman -S --needed cmake ninja"}]
                    service.missingPackages = service.packagesFrom(service.installSteps[1].fix)
                    service.awaitingPackages = next === "install-waiting"
                    if (service.missingPackages.join(" ") !== "cmake ninja") console.error("packagesFrom rejected the bootstrap fix")
                    if (service.packagesFrom("sudo pacman -S --needed cmake; reboot").length || service.packagesFrom("sudo pacman -S --needed evil").length)
                        console.error("packagesFrom accepted an unexpected command")
                }
                if (next === "outdated") {
                    service.hyprflipState = "outdated"
                    const pin = service.hyprflipPin, other = "a".repeat(40)
                    const cases = [
                        [{installed_release: service.hyprflipMinimum, installed_commit: other}, true],
                        [{installed_release: "0.3.0-rc.16", installed_commit: other}, true],
                        [{installed_release: "0.3.0"}, true],
                        [{installed_release: "0.4.0-rc.1"}, true],
                        [{installed_release: "0.3.0-rc.9", installed_commit: pin}, false],
                        [{installed_release: "0.2.0"}, false],
                        [{installed_release: "bogus"}, false],
                        [{installed_commit: pin}, true],
                        [{installed_commit: other}, false],
                        [{}, true]]
                    for (const [data, expected] of cases)
                        if (service.hyprflipCurrent(data) !== expected) console.error("hyprflipCurrent wrong for " + JSON.stringify(data))
                    if (service.compareReleases("0.3.0-rc.10", "0.3.0-rc.9") !== 1 || service.compareReleases("0.3.0-rc.16", "0.3.0") !== -1)
                        console.error("compareReleases misorders releases")
                }
                if (next === "refused") {
                    window.width = 340; window.height = 550; Style.spacingScale = 1; Style.fontBaseSize = 12
                    service.failed = true
                    service.notice = "Claude needs at least 600 px, so this card would have to be 1818 px wide, and the screen has 1512. Put fewer apps side by side, or give Claude a bigger share."
                }
                if (next === "empty") { const data = JSON.parse(JSON.stringify(harness.original)); data.cards = []; data.saved = []; service.snapshot = data }
                if (next === "narrow") { window.width = 340; window.height = 550 }
                if (next === "scaled") { window.width = 540; window.height = 800; Style.spacingScale = 1.25; Style.fontBaseSize = 15 }
                if (next === "light") { Style.spacingScale = 1; Style.fontBaseSize = 12; window.width = 468; window.height = 700; Commons.Color.shellValues = ({}); Commons.Color.background = "#faf8f3"; Commons.Color.foreground = "#242424"; Commons.Color.accent = "#2255aa"; Commons.Color.muted = "#666666" }
                if (next === "dark") { Commons.Color.shellValues = ({}); Commons.Color.background = "#1c2026"; Commons.Color.foreground = "#e6e9ef"; Commons.Color.accent = "#a9bfff"; Commons.Color.muted = "#9ba6b5" }
                if (["library-ungrouped", "no-front", "unselected-card", "long-front", "scaled-entry"].includes(next)) {
                    const data = JSON.parse(JSON.stringify(harness.original))
                    data.context.anchor = "0xd"
                    data.context.anchor_label = "Brave"
                    if (next !== "unselected-card") data.cards = []
                    if (next === "no-front" || next === "long-front") data.saved = []
                    if (next === "no-front") { data.context.anchor = null; data.context.anchor_label = null }
                    if (next === "long-front") data.context.anchor_label = "A long application name with project details and more context"
                    service.snapshot = data
                    service.context = data.context
                    service.selectedKey = ""
                    Style.spacingScale = next === "scaled-entry" ? 2 : 1
                    Style.fontBaseSize = next === "scaled-entry" ? 24 : 12
                    window.width = next === "scaled-entry" ? 936 : next === "long-front" ? 340 : 468
                    window.height = next === "scaled-entry" ? 1400 : 700
                    Commons.Color.shellValues = ({})
                    Commons.Color.background = "#faf8f3"; Commons.Color.foreground = "#242424"; Commons.Color.accent = "#2255aa"; Commons.Color.muted = "#666666"
                }
                // A three-face card from a core that allows four faces.
                if (next.startsWith("multi-face") || next === "edit-add-face") {
                    const d = JSON.parse(JSON.stringify(harness.original))
                    Object.assign(d.capabilities, d.multi_face.capabilities)
                    if (next !== "edit-add-face") d.cards = [d.multi_face.card]
                    const card = d.cards[0]
                    if (next === "multi-face-narrow") card.unfolded = true
                    if (next === "multi-face-edit" || next === "multi-face-edit-narrow" || next === "multi-face-edit-scaled") { card.active = 1; card.current = "0xe" }
                    if (next === "multi-face-remove") { card.active = 2; card.current = "0x10" }
                    service.page = next.includes("edit") || next === "multi-face-remove" ? "edit" : "cards"
                    service.snapshot = d
                    service.context = d.context
                    service.selectedKey = card.key
                    const narrow = next.endsWith("-narrow"), scaled = next.endsWith("-scaled")
                    window.width = narrow ? 340 : scaled ? 936 : 468
                    window.height = scaled ? (service.page === "edit" ? 2400 : 2000) : service.page === "edit" ? 1000 : narrow ? 550 : 700
                    Style.spacingScale = scaled ? 2 : 1
                    Style.fontBaseSize = scaled ? 24 : 12
                    Commons.Color.shellValues = ({})
                    Commons.Color.background = "#faf8f3"; Commons.Color.foreground = "#242424"; Commons.Color.accent = "#2255aa"; Commons.Color.muted = "#666666"
                    if (next === "multi-face-edit" || next === "multi-face-edit-narrow" || next === "multi-face-edit-scaled") { content.paneCardKey = card.key; content.paneAddress = "0xe" }
                    if (next === "multi-face-remove") { content.paneCardKey = card.key; content.paneAddress = "0x10" }
                }
                if (next === "error-dark") {
                    service.failed = true
                    service.notice = "Claude needs at least 600 px, so this card would have to be 1818 px wide, and the screen has 1512. Put fewer apps side by side, or give Claude a bigger share."
                }
                if (next === "ungroup-confirm") content.ungroupKey = "container:1"
                // Act after the page change's queued focusEntry, as a person would.
                if (next === "applying") Qt.callLater(() => { harness.focusOn("label:Accent ring"); service.run("accent", {enabled: false, color: service.accentHex}) })
                if (next === "motion-refresh") Qt.callLater(() => {
                    harness.focusOn("title:Slide")
                    // A changed model rebuilds every row; an identical one is left alone.
                    const changed = JSON.parse(JSON.stringify(harness.original))
                    changed.transition_modes.find(m => m.value === "fade").detail += " · Changed"
                    service.snapshot = changed
                })
                if (next === "working") service.savedAction("open", service.snapshot.saved[1])
                if (next === "installing") service.installHyprflip()
                if (next === "pane-edit") { service.page = "edit"; const d = JSON.parse(JSON.stringify(harness.original)); d.cards[0].active = 1; d.cards[0].current = "0xb"; service.snapshot = d; content.paneCardKey = "container:1"; content.paneAddress = "0xc"; window.height = 780 }
            })
        }
    }
}
