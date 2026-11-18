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
    property var shots: ["cards", "settings", "preferences-narrow", "preferences-light", "preferences-dark", "preferences-scaled", "shortcuts", "shortcut-record", "shortcut-conflict", "settings-narrow", "settings-scaled", "edit", "motion", "motion-refresh", "question", "empty", "narrow", "scaled", "light", "dark", "pane-edit", "library-ungrouped", "no-front", "unselected-card", "long-front", "scaled-entry", "install-missing", "install-progress", "install-waiting", "outdated", "navigation-offer", "refused", "multi-face", "multi-face-narrow", "multi-face-scaled", "multi-face-edit", "multi-face-remove", "multi-face-edit-narrow", "multi-face-edit-scaled", "edit-add-face", "one-face-covered", "one-face-edit", "settings-drift", "settings-dark", "error-dark", "ungroup-confirm", "managed-ungroup",
        // In-flight shots come last, each followed by the moment it finishes.
        "applying", "applied", "working", "worked", "installing", "installed"]
    // The edit page's pane row for an app, enabled or not.
    function paneRow(item, title) {
        if (item.title === title && item.detail !== undefined && item.selected !== undefined) return item
        for (const child of item.children || []) { const found = paneRow(child, title); if (found) return found }
        if (item.contentItem && item.contentItem !== item) return paneRow(item.contentItem, title)
        return null
    }
    // Every item that is on screen and passes the test.
    function visibleItems(item, test, found, seen) {
        found = found || []; seen = seen || new Set()
        if (seen.has(item)) return found
        seen.add(item)
        if (item.visible && test(item)) found.push(item)
        for (const child of item.children || []) visibleItems(child, test, found, seen)
        if (item.contentItem && item.contentItem !== item) visibleItems(item.contentItem, test, found, seen)
        return found
    }
    function showingLabels() { return harness.visibleItems(content, i => i.text === "Showing" && i.font !== undefined) }
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
                [() => { harness.focusOn("accessibleName:Back"); content.moveTab(-1) }, "label:Move whole cards with Omarchy’s keys"],
                [() => content.moveTab(1), "accessibleName:Back"]])
            // Said only when what runs is not what was installed, naming what differs.
            const drift = harness.findItem(content, "installDrift"), detail = harness.findItem(content, "installDriftDetail")
            const before = service.snapshot
            const checked = (value, label) => { const d = JSON.parse(JSON.stringify(before)); d.install_check = value; service.snapshot = d; return drift.visible }
            if (drift.visible) console.error("Without a record of the install, Settings should say nothing of it")
            if (checked({loaded: "same", changed: []})) console.error("An install as recorded should say nothing")
            if (checked({loaded: "unknown", changed: []})) console.error("A core that does not say should say nothing")
            if (!checked({loaded: "same", changed: ["control.py"]}) || detail.text !== "Changed: control.py")
                console.error("A helper copied over should be named: " + detail.text)
            if (!checked({loaded: "differs", changed: ["hyprflip.so"]}) ||
                detail.text !== "The running core is not the installed one · Changed: hyprflip.so")
                console.error("Another core loaded should be said: " + detail.text)
            service.snapshot = before
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
        // OmaRelay's card: said in Edit and in Cards, with what OmaRelay does with Ungroup, Remove and Fullscreen.
        if (name === "managed-ungroup") {
            const note = harness.findItem(content, "ownerNote"), ungroupNote = harness.findItem(content, "ungroupOwnerNote")
            if (!note || !note.visible || note.text !== "Managed by OmaRelay. It keeps your changes as its card.")
                console.error("Edit should say OmaRelay manages the card: " + (note && note.text))
            if (!ungroupNote || !ungroupNote.visible || ungroupNote.text !== "OmaRelay builds this card again on the next visit to its space.")
                console.error("Ungroup should say OmaRelay builds the card again: " + (ungroupNote && ungroupNote.text))
            if (content.ownerNote("remove") !== "OmaRelay saves the card without this app; it won't come back.") console.error("Remove's note for OmaRelay")
            const other = JSON.parse(JSON.stringify(service.snapshot))
            other.cards[0].owner = "Tiler"
            service.snapshot = other
            if (note.text !== "Managed by Tiler." || ungroupNote.text !== "Tiler may build this card again." || content.ownerNote("remove") !== "")
                console.error("Another program's card should say only who manages it: " + note.text + " / " + ungroupNote.text)
            const unmarked = JSON.parse(JSON.stringify(service.snapshot))
            delete unmarked.cards[0].owner
            service.snapshot = unmarked
            if (note.visible || ungroupNote.visible) console.error("A card nobody manages should say nothing of an owner")
            service.page = "cards"
            const detail = harness.findItem(content, "cardDetail")
            if (detail.text.indexOf("Managed by") >= 0) console.error("Cards said an owner for an unmarked card: " + detail.text)
            service.snapshot = other
            if (detail.text.indexOf(" · Managed by Tiler") < 0) console.error("Cards should say who manages the card: " + detail.text)
            service.page = "edit"
        }
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
        // A hidden third face's apps wait for "Show and edit" on an older
        // helper; with the face action they can be chosen directly.
        if (name === "multi-face-edit") {
            const hidden = () => harness.paneRow(content, "Spotify")
            if (!hidden() || hidden().enabled || hidden().detail.indexOf("On Face 3") < 0)
                console.error("Without the face action, Face 3's app should be disabled and say where it is")
            const d = JSON.parse(JSON.stringify(service.snapshot))
            d.capabilities.show_face = true
            service.snapshot = d
            if (!hidden() || !hidden().enabled || hidden().detail.indexOf("Select to show Face 3") < 0)
                console.error("With the face action, Face 3's app should be selectable and say it shows Face 3")
            if (content.actionTitle({action: "face", face: 2}) !== "Showing Face 3…") console.error("The face action's progress title")
            // A cover takes a face, shown or not: three faces and a cover fill a card of four.
            const addFace = harness.findItem(content, "addFace")
            if (!addFace || !addFace.visible) console.error("Three faces of four should offer Add as new face")
            const covered = JSON.parse(JSON.stringify(service.snapshot))
            for (const c of covered.cards) c.has_cover = true
            service.snapshot = covered
            if (addFace.visible) console.error("Three faces and a cover should not offer Add as new face")
            service.snapshot = d
        }
        // A card behind a cover (Herdr) with one face of its own: the cover
        // shows, so no face is marked Showing, and there is no other side.
        if (name === "one-face-covered") {
            const boldFront = () => harness.visibleItems(content, i => i.text === "Front" && i.font !== undefined && i.font.bold)
            if (harness.showingLabels().length) console.error("A covered card marked a face as Showing")
            if (boldFront().length) console.error("A covered card's own face name should not be bold")
            const d = JSON.parse(JSON.stringify(service.snapshot))
            d.cards[0].covered = false
            service.snapshot = d
            if (harness.showingLabels().length !== 1) console.error("An uncovered one-face card should mark its face as Showing")
            if (boldFront().length !== 1) console.error("An uncovered one-face card's face name should be bold")
        }
        if (name === "one-face-edit") {
            // The Action, not the label inside it, which carries the same text.
            const showAction = face => harness.visibleItems(content, i => i.accessibleName !== undefined && i.text === (content.canShowFace ? "Show " : "Show and edit ") + face)
            if (harness.showingLabels().length) console.error("The edit page marked a covered card's face as Showing")
            const other = harness.visibleItems(content, i => i.accessibleName === "Move Telegram to Front")
            if (other.length !== 1 || other[0].enabled || other[0].tooltipText !== "This card has one face of its own")
                console.error("Other side should be offered disabled on a card with one face of its own")
            // The cover shows, so the card's own face is offered to show.
            if (showAction("Front").length !== 1) console.error("A covered card should offer to show its own face")
            const uncovered = JSON.parse(JSON.stringify(service.snapshot))
            uncovered.cards[0].covered = false
            service.snapshot = uncovered
            if (showAction("Front").length) console.error("An uncovered card should not offer to show the face it shows")
            // The same face with a second face beside it can move the app again.
            const two = JSON.parse(JSON.stringify(harness.original))
            two.cards[0].active = 1; two.cards[0].current = "0xb"
            service.snapshot = two
            const back = harness.visibleItems(content, i => i.accessibleName === "Move Telegram to Front")
            if (back.length !== 1 || !back[0].enabled) console.error("Other side should be enabled on a two-face card")
        }
        // A refresh that rebuilds the rows puts focus back on the same row.
        if (name === "motion-refresh" && focusName() !== "title:Slide") console.error("A refresh lost focus: " + focusName())
        // A saved preference keeps the page and the control in focus.
        if (name === "applied") {
            if (service.page !== "settings") console.error("Saving a preference left Settings")
            if (focusName() !== "label:Accent ring") console.error("Saving a preference moved focus to " + focusName())
        }
        // A key another module claims shows its owner instead of a bare refusal.
        if (name === "shortcuts") {
            const before = service.snapshot, owned = JSON.parse(JSON.stringify(before))
            Object.assign(owned.shortcuts.rows.find(r => r.id === "create"), {owner: "OmaRelay", editable: false, shortcut: "Super+Ctrl+Alt+O"})
            service.snapshot = owned
            const details = [], seen = new Set(), walk = item => {
                if (seen.has(item)) return
                seen.add(item)
                if (typeof item.detail === "string" && item.title === "Create, unfold or fold") details.push([item.detail, item.enabled])
                for (const child of item.children || []) walk(child)
                if (item.contentItem && item.contentItem !== item) walk(item.contentItem)
            }
            walk(content)
            if (details.length !== 1 || details[0][0] !== "Super+Ctrl+Alt+O · Set by OmaRelay" || details[0][1])
                console.error("A claimed key should name its owner and not be chosen: " + JSON.stringify(details))
            service.snapshot = before
        }
        // Offered once: only while the shortcuts are off and no choice is recorded.
        if (name === "navigation-offer") {
            const offer = harness.findItem(content, "navigationOffer"), toggle = harness.findItem(content, "navigationToggle")
            if (!offer || !offer.visible) console.error("The movement-shortcut offer should show on an install without them")
            const variant = changes => { const d = JSON.parse(JSON.stringify(service.snapshot)); Object.assign(d, changes); service.snapshot = d }
            const before = service.snapshot
            for (const [changes, label] of [[{navigation_choice: "off"}, "after No thanks"], [{navigation: "on", navigation_choice: "on"}, "while on"],
                                            [{navigation: "edited", navigation_choice: null}, "while an edited copy is loaded"]]) {
                variant(changes)
                if (offer.visible) console.error("The movement-shortcut offer showed " + label)
                service.snapshot = before
            }
            const older = JSON.parse(JSON.stringify(before)); delete older.capabilities.navigation; service.snapshot = older
            if (offer.visible || toggle.visible) console.error("A Hyprflip without the movement-shortcut switch showed it")
            service.snapshot = before
            if (toggle.checked) console.error("The movement-shortcut toggle should be off")
            variant({navigation: "edited"})
            if (!toggle.checked || toggle.description.indexOf("backup") < 0) console.error("An edited copy should show as on and mention the backup")
            service.snapshot = before
            if (service.quietActions.indexOf("navigation") < 0) console.error("Switching the movement shortcuts should not close the panel")
        }
        if (name === "installed" && service.notice.indexOf("turn this off in Settings") < 0)
            console.error("A new setup's notice should say the movement shortcuts are on: " + service.notice)
        if (name === "worked" && service.busy) console.error("The fake open did not finish in time")
        if (name === "installed" && service.installing) console.error("The fake install did not finish in time")
        if (["settings", "shortcuts", "pane-edit", "multi-face-edit", "one-face-covered", "one-face-edit", "motion-refresh", "ungroup-confirm", "managed-ungroup", "navigation-offer", "applied", "worked", "installed"].includes(name)) console.log("OMACARDS_CHECKED " + name)
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
                service.page = ["settings","shortcuts","edit","motion"].indexOf(next) >= 0 ? next : ["settings-dark", "settings-drift", "applying"].includes(next) ? "settings" : ["ungroup-confirm", "managed-ungroup"].includes(next) ? "edit" : next === "motion-refresh" ? "motion" : "cards"
                service.snapshot = JSON.parse(JSON.stringify(harness.original))
                service.context = service.snapshot.context
                service.selectedKey = "container:1"
                // Hyprflip as installed no longer runs: another core loaded, and a helper copied over.
                if (next === "settings-drift") service.snapshot = Object.assign(JSON.parse(JSON.stringify(harness.original)),
                    {install_check: {loaded: "differs", changed: ["control.py", "hyprflip.so"]}})
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
                        {event: "step", id: "download", title: "Download the pinned Hyprflip release", status: "ok", detail: "Hyprflip v0.3.0-rc.26"},
                        {event: "step", id: "check", title: "Check prerequisites", status: "failed", detail: "Missing cmake, ninja", fix: "sudo pacman -S --needed cmake ninja"}]
                    service.missingPackages = service.packagesFrom(service.installSteps[1].fix)
                    service.awaitingPackages = next === "install-waiting"
                    if (service.missingPackages.join(" ") !== "cmake ninja") console.error("packagesFrom rejected the bootstrap fix")
                    if (service.packagesFrom("sudo pacman -S --needed cmake; reboot").length || service.packagesFrom("sudo pacman -S --needed evil").length)
                        console.error("packagesFrom accepted an unexpected command")
                    if (service.packagesFrom("sudo pacman -S --needed binutils lua54").join(" ") !== "binutils lua54")
                        console.error("packagesFrom rejected Hyprflip's readelf and Lua 5.4 packages")
                }
                if (next === "outdated") {
                    service.hyprflipState = "outdated"
                    const pin = service.hyprflipPin, other = "a".repeat(40)
                    const cases = [
                        [{installed_release: service.hyprflipMinimum, installed_commit: other}, true],
                        [{installed_release: "0.3.0-rc.22", installed_commit: other}, false],
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
                if (next === "navigation-offer") {
                    const d = JSON.parse(JSON.stringify(harness.original))
                    d.navigation = "off"
                    d.navigation_choice = null
                    service.snapshot = d
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
                // Herdr covers a card left with one face of its own (WhatsApp + Telegram).
                if (next.startsWith("one-face-")) {
                    const d = JSON.parse(JSON.stringify(harness.original))
                    const card = d.cards[0]
                    card.faces = [Object.assign(card.faces[1], {index: 0})]
                    card.active = 0; card.current = "0xb"; card.covered = true
                    card.name = "WhatsApp + Telegram"; card.saved_names = []
                    service.page = next === "one-face-edit" ? "edit" : "cards"
                    service.snapshot = d
                    service.selectedKey = card.key
                    if (next === "one-face-edit") { content.paneCardKey = card.key; content.paneAddress = "0xc"; window.height = 780 }
                }
                if (next === "error-dark") {
                    service.failed = true
                    service.notice = "Claude needs at least 600 px, so this card would have to be 1818 px wide, and the screen has 1512. Put fewer apps side by side, or give Claude a bigger share."
                }
                if (next === "ungroup-confirm") content.ungroupKey = "container:1"
                // A card OmaRelay manages, as Hyprflip 0.3.0-rc.27 marks it, asked to ungroup.
                if (next === "managed-ungroup") {
                    const managed = JSON.parse(JSON.stringify(harness.original))
                    managed.cards[0].owner = "OmaRelay"
                    service.snapshot = managed
                    content.ungroupKey = "container:1"
                }
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
