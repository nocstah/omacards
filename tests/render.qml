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
        // OmaRelay's templates, answered by tests/fake-omarelay.py; the rest of the shots run with no OmaRelay.
        "templates-here", "templates-here-narrow", "templates-here-scaled", "templates-here-dark", "templates-only", "templates-search",
        "templates-nomatch", "templates-confirm-here", "templates-confirm-here-narrow", "templates-confirm-here-scaled",
        "templates-confirm-here-dark", "templates-confirm-elsewhere", "templates-confirm-nocard", "templates-escape", "templates-keep",
        "templates-enter-enter", "templates-apply", "templates-apply-changed", "templates-apply-garbage", "templates-applying",
        "templates-apply-hang", "templates-cards-off", "templates-no-helper", "templates-helper-busy", "templates-helper-old",
        "templates-other-machine", "templates-odd-code", "templates-unreadable", "templates-missing", "templates-in-use-changed",
        "templates-hostile", "templates-late", "templates-late-moved", "templates-absent-base", "templates-absent-no-marker",
        "templates-absent-usage", "templates-absent-garbage", "templates-absent-hang", "templates-absent-no-workspace",
        "templates-refresh-quiet",
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
    // OmaRelay's templates. The fake answers as the control file says; the record file holds each argv it got.
    readonly property string fakeOmarelay: Quickshell.env("OMACARDS_FAKE_OMARELAY")
    readonly property string missingOmarelay: Quickshell.env("OMACARDS_OMARELAY")
    // A shot can wait for a condition before its capture, then run one more step (which may wait again).
    property var waitFor: null
    property var afterWait: null
    property real waitUntil: 0
    property var noted: ({})
    function wait(test, ms, then) { waitFor = test; waitUntil = Date.now() + (ms || 5000); afterWait = then || null }
    function fake(control) { fakeControl.setText(JSON.stringify(control)); fakeControl.waitForJob() }
    // FileView loads and writes in the background: wait for each before trusting the file.
    function records() { fakeRecord.reload(); fakeRecord.waitForJob(); return fakeRecord.text().split("\n").filter(l => l.trim()).map(l => JSON.parse(l)) }
    function applies() { return records().filter(r => r[3] === "apply") }
    function lists() { return records().filter(r => r[3] === "list") }
    function clearRecords() { fakeRecord.setText(""); fakeRecord.waitForJob() }
    function search() { return findItem(content, "librarySearch") }
    function templateRows() { return visibleItems(content, i => i.title !== undefined && i.selected !== undefined && typeof i.detail === "string" && i.detail.startsWith("Template")) }
    function action(name) { return visibleItems(content, i => i.accessibleName !== undefined && i.clicked !== undefined && (i.accessibleName === name || i.text === name))[0] || null }
    function shown(text) { return visibleItems(content, i => i.text === text && i.font !== undefined).length > 0 }
    function listTemplates(answer, then, extra) {
        service.omarelay = fakeOmarelay
        fake(Object.assign({templates: answer, apply: "soon"}, extra || {}))
        service.readTemplates()
        wait(() => !service.readingTemplates, 5000, then)
    }
    // Enter on the Review template from the search field, as a person would.
    function enterReview() {
        content.focusEntry()
        content.cursor = content.libraryRows.findIndex(r => r.kind === "template" && r.row.name === "Review")
        search().accepted()
    }
    function untilKeep(then) { wait(() => focusName() === "accessibleName:Keep card", 2000, then) }
    readonly property var templateCases: ({"templates-cards-off": "cards-off", "templates-no-helper": "no-helper", "templates-helper-busy": "helper-busy",
        "templates-helper-old": "helper-old", "templates-other-machine": "other-machine", "templates-odd-code": "odd-code",
        "templates-unreadable": "unreadable", "templates-missing": "missing-template", "templates-in-use-changed": "in-use-changed",
        "templates-hostile": "hostile-label"})
    function templateSetup(next) {
        service.templatesTimeout = 9000
        // The apply from the shot before is still running: it ends with the fake answering and the panel open.
        if (next !== "templates-apply-hang") { service.omarelay = missingOmarelay; service.templateApplyTimeout = 45000; service.owner = null; fakeOwner.opened = false }
        content.templateConfirm = null
        content.filter = ""
        content.cursor = 0
        if (!next.startsWith("templates-")) { service.templates = null; return }
        const v = next.replace(/-(narrow|scaled|dark)$/, "")
        if (!v.startsWith("templates-absent")) window.height = 1100
        if (next.endsWith("-narrow")) { window.width = 340; window.height = 1500 }
        if (next.endsWith("-scaled")) { window.width = 936; window.height = 2600; Style.spacingScale = 2; Style.fontBaseSize = 24 }
        const clone = () => JSON.parse(JSON.stringify(harness.original))
        if (v === "templates-here") listTemplates("live-here")
        else if (v === "templates-only") {
            const d = clone(); d.cards = []; d.saved = []; service.snapshot = d; service.selectedKey = ""
            listTemplates("live-here", () => content.focusEntry())
        } else if (v === "templates-search") {
            const d = clone(); d.saved.push({name: "Code review", token: "fixture-zed", open: false, detail: "Open here", description: "Zed ↔ Terminal"})
            service.snapshot = d
            // Down from the saved row crosses to the template row.
            listTemplates("live-here", () => { content.focusEntry(); content.filter = "zed"; content.cursor = Math.min(content.libraryRows.length - 1, content.cursor + 1) })
        } else if (v === "templates-nomatch") listTemplates("live-here", () => { content.focusEntry(); content.filter = "qqq" })
        else if (v === "templates-confirm-here") listTemplates("live-here", () => { enterReview(); untilKeep() })
        else if (v === "templates-confirm-elsewhere" || v === "templates-confirm-nocard")
            listTemplates(v === "templates-confirm-elsewhere" ? "live-elsewhere" : "live-nocard", () => {
                const state = findItem(content, "templateState")
                noted.state = state.visible ? state.text : ""
                enterReview(); untilKeep()
            })
        else if (v === "templates-escape" || v === "templates-keep" || v === "templates-enter-enter") {
            clearRecords()
            listTemplates("live-here", () => {
                enterReview()
                // A second Enter at once lands on the row again; the next one on Keep card.
                if (v === "templates-enter-enter") search().accepted()
                noted.cursor = content.cursor
                untilKeep(() => { if (v === "templates-escape") content.back(); else action("Keep card").clicked() })
            })
        } else if (["templates-apply", "templates-apply-changed", "templates-apply-garbage", "templates-applying"].includes(v)) {
            service.owner = fakeOwner; fakeOwner.opened = true
            clearRecords()
            if (v === "templates-applying") service.templateApplyTimeout = 2500
            const answer = {"templates-apply": "soon", "templates-apply-changed": "changed", "templates-apply-garbage": "garbage", "templates-applying": "hang"}[v]
            listTemplates("live-here", () => {
                enterReview()
                untilKeep(() => {
                    action("Replace").clicked()
                    // The panel closes before OmaRelay is asked.
                    noted.closedFirst = !fakeOwner.opened && applies().length === 0
                    if (v === "templates-applying") wait(() => service.applyingTemplate, 3000, () => { fakeOwner.opened = true; service.readTemplates() })
                    else wait(() => !service.applyingTemplate && service.templateApplying === null && applies().length > 0, 5000)
                })
            }, {apply: answer})
        } else if (v === "templates-apply-hang") wait(() => !service.applyingTemplate && service.templateApplying === null, 6000)
        else if (templateCases[v]) listTemplates(templateCases[v])
        else if (v === "templates-absent-base") { service.readTemplates(); wait(() => !service.readingTemplates, 3000) }
        else if (v.startsWith("templates-absent-")) { service.templatesTimeout = 1500; listTemplates(v.slice("templates-absent-".length)) }
        else if (v === "templates-late" || v === "templates-late-moved") {
            const d = clone(); d.saved = []; service.snapshot = d
            service.templates = null
            content.focusEntry()
            if (v === "templates-late-moved") focusOn("accessibleName:Edit")
            listTemplates("live-here", null, {delay: 1})
        } else if (v === "templates-refresh-quiet") {
            clearRecords()
            service.omarelay = fakeOmarelay
            fake({templates: "live-here"})
            service.prepareOpen(fakeOwner)
            const start = Date.now()
            // Two 5 s polls, then a refresh as a Hyprland event makes one: none of them lists templates again.
            wait(() => Date.now() - start > 12000, 14000, () => { service.refresh(true); wait(() => !service.refreshing, 3000) })
        } else console.error("No setup for " + next)
    }
    function templateChecks(name) {
        const fail = message => console.error("Templates, " + name + ": " + message)
        const heading = findItem(content, "templateHeading"), state = findItem(content, "templateState")
        const rows = templateRows()
        const detail = title => (rows.find(r => r.title === title) || {detail: ""}).detail
        const stateText = state.visible ? state.text : ""
        const review = (content.templateRows.find(t => t.id === "t0123456789") || {}).token
        if (name === "templates-here") {
            if (!heading.visible || heading.text !== "Templates for omarelay") fail("heading " + heading.text)
            if (rows.map(r => r.title).join("|") !== "Browser ↔ terminals|Terminals ↔ terminals|Zed ↔ terminals|No card|Review") fail("rows " + rows.map(r => r.title))
            if (detail("Browser ↔ terminals") !== "Template · In use · Built-in · New spaces\nWorkspace browser ↔ Workspace terminal") fail(detail("Browser ↔ terminals"))
            if (detail("Review") !== "Template · Yours\nWorkspace browser + Obsidian ↔ Workspace terminal\nWide reading layout") fail(detail("Review"))
            if (detail("No card") !== "Template · Built-in\nHerdr alone, no card") fail(detail("No card"))
            if (stateText) fail("a live space here should have no state line: " + stateText)
            if (!shown("Edit templates in Inapse Spaces' settings: Spaces → Templates.")) fail("no footnote")
            if (search().placeholderText !== "Search saved cards and templates…") fail("placeholder " + search().placeholderText)
        }
        if (name === "templates-only") {
            if (!search().visible || !search().activeFocus) fail("the search field should show and take focus")
            if (search().placeholderText !== "Search saved cards and templates…") fail("placeholder " + search().placeholderText)
            if (!shown("Save a card to reopen its apps and layout later.")) fail("the empty saved line should stay")
            if (rows.length !== 5) fail(rows.length + " rows")
        }
        if (name === "templates-search") {
            const saved = visibleItems(content, i => i.title === "Code review" && i.selected !== undefined)[0]
            if (content.savedRows.length !== 1 || rows.length !== 1 || rows[0].title !== "Zed ↔ terminals") fail("zed should find one saved card and one template: " + rows.map(r => r.title))
            if (content.cursor !== 1 || !rows[0] || !rows[0].selected || !saved || saved.selected) fail("Down should select the template row")
        }
        if (name === "templates-nomatch") {
            if (!shown("Nothing matches your search. Escape clears it.")) fail("no no-match line")
            if (findItem(content, "templateGroup").visible) fail("templates that do not match should leave the group out")
            content.filter = ""
            if (templateRows().length !== 5 || shown("Nothing matches your search. Escape clears it.")) fail("clearing the search should bring the rows back")
        }
        if (name === "templates-confirm-here") {
            if (focusName() !== "accessibleName:Keep card") fail("focus should start on Keep card, not " + focusName())
            if (!shown("Replace this card with “Review”?") || !shown("Save it as a template first to keep it.")) fail("the question")
            if (!action("Replace this card with “Review”")) fail("Replace's accessible name")
            if (rows.length || shown("Edit templates in Inapse Spaces' settings: Spaces → Templates.")) fail("the rows and the footnote should hide")
        }
        if (name === "templates-confirm-elsewhere" || name === "templates-confirm-nocard") {
            if (noted.state !== "omarelay is open in Herdr away from this workspace. A template you pick applies to its card there.") fail("state line " + noted.state)
            if (!shown("Replace omarelay's card with “Review”?") || stateText) fail("the question should name the space, without the state line")
            if (focusName() !== "accessibleName:Keep card") fail("focus " + focusName())
        }
        if (["templates-escape", "templates-keep", "templates-enter-enter"].includes(name)) {
            if (content.templateConfirm || !search().activeFocus || content.cursor !== noted.cursor) fail("back to the search, on the same row")
            if (applies().length) fail("applied: " + JSON.stringify(applies()))
            if (rows.length !== 5) fail("the rows should come back")
        }
        if (name === "templates-apply") {
            const argv = applies()
            const expected = ["workspace-browsers", "cards", "template", "apply", "t0123456789", "--space", "spQ7xLm2", "--token", review, "--json", "--notify"]
            if (!noted.closedFirst) fail("the panel should close before OmaRelay is asked")
            if (argv.length !== 1 || JSON.stringify(argv[0]) !== JSON.stringify(expected)) fail("argv " + JSON.stringify(argv))
            if (argv.length && argv[0].some(a => a === "here" || a === "--app" || a.indexOf("Review") >= 0 || a.indexOf("omarelay") >= 0)) fail("argv carries more than ids")
            if (fakeOwner.opened || service.failed) fail("a protocol answer should leave the panel closed")
        }
        if (name === "templates-apply-changed" && (!noted.closedFirst || fakeOwner.opened || service.failed || service.notice)) fail("a refusal is OmaRelay's to say")
        const unknown = "OmaRelay did not say whether “Review” was applied to omarelay. Look at its card before you try again."
        if ((name === "templates-apply-garbage" || name === "templates-apply-hang") && (!service.failed || service.notice !== unknown)) fail("notice " + service.notice)
        if (name === "templates-apply-hang" && (service.applyingTemplate || service.templateApplying)) fail("the apply should be stopped")
        if (name === "templates-applying") {
            if (stateText !== "Applying “Review” to omarelay…") fail("state " + stateText)
            if (rows.length !== 5 || rows.some(r => r.enabled)) fail("the rows should show, disabled")
            content.askTemplate(content.templateRows[0])
            if (content.templateConfirm) fail("a template was offered while one applies")
        }
        const lines = {"templates-cards-off": "Card mode is off. A template you pick applies when card mode is on and omarelay is next shown.",
                       "templates-no-helper": "OmaRelay's desktop helper is not running. A template you pick applies when omarelay is next shown.",
                       "templates-helper-busy": "OmaRelay's desktop helper is busy. A template you pick applies when it can.",
                       "templates-other-machine": "The space in Herdr belongs to another machine. Change its card there.",
                       "templates-odd-code": "Templates can't be applied right now (settings_unreadable)."}
        if (lines[name] !== undefined && stateText !== lines[name]) fail("state " + stateText)
        if (["templates-cards-off", "templates-no-helper", "templates-helper-busy"].includes(name) && rows.length !== 5) fail(rows.length + " rows")
        if (["templates-helper-old", "templates-other-machine", "templates-odd-code"].includes(name) && rows.length) fail("no rows without a space")
        if (name === "templates-helper-old" && (findItem(content, "templateNotice").text !== "OmaRelay's desktop helper is older than OmaRelay. Restart it to apply templates." || stateText))
            fail("the restart notice")
        if (name === "templates-unreadable" && (rows.length !== 4 || !findItem(content, "templateUnreadable").visible)) fail("built-ins and the unreadable line: " + rows.map(r => r.title))
        if (name === "templates-missing" && (!shown("omarelay's template was deleted. Its card builds from the built-in one.") || rows.some(r => r.detail.indexOf("In use") >= 0)))
            fail("the deleted template")
        if (name === "templates-in-use-changed" && !detail("Browser ↔ terminals").startsWith("Template · In use · Changed since · Built-in · New spaces")) fail(detail("Browser ↔ terminals"))
        if (name === "templates-hostile") {
            const literal = visibleItems(content, i => i.text === "<i>T</i>" && i.textFormat !== undefined)
            if (heading.text !== "Templates for <b>x</b>\n<img src=a>" || heading.textFormat !== Text.PlainText) fail("heading " + heading.text)
            if (!literal.length || literal.some(l => l.textFormat !== Text.PlainText)) fail("the name should be plain text")
        }
        if (name.startsWith("templates-absent-") && name !== "templates-absent-base") {
            if (findItem(content, "templateGroup").visible || search().placeholderText !== "Search saved cards…") fail("the section should be absent")
            if (name !== "templates-absent-no-workspace" && service.templates) fail("the answer should not be accepted")
        }
        if (name === "templates-late" && !search().activeFocus) fail("the late answer's search should take focus from the key catcher, focus " + focusName())
        if (name === "templates-late-moved" && focusName() !== "accessibleName:Edit") fail("a late answer took focus from " + focusName())
        if (name === "templates-refresh-quiet" && lists().length !== 1) fail(lists().length + " list calls")
        const checked = {"templates-absent-no-workspace": "templates-absent", "templates-late-moved": "templates-late", "templates-late": ""}
        const logged = checked[name] !== undefined ? checked[name] : /-(narrow|scaled|dark)$/.test(name) || name === "templates-absent-base" || name.startsWith("templates-absent-") ? "" : name
        if (logged) console.log("OMACARDS_CHECKED " + logged)
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
            // Unfolding would only set the cover beside the card's one face; Fold stays for a card already unfolded.
            const action = text => harness.visibleItems(content, i => i.accessibleName !== undefined && i.text === text)
            const unfold = action("Unfold")
            if (unfold.length !== 1 || unfold[0].enabled || unfold[0].tooltipText !== "This card has one face of its own")
                console.error("Unfold should be offered disabled on a card with one face of its own")
            const unfolded = JSON.parse(JSON.stringify(service.snapshot))
            unfolded.cards[0].unfolded = true
            service.snapshot = unfolded
            if (action("Fold").length !== 1 || !action("Fold")[0].enabled) console.error("An unfolded card should offer Fold")
            service.snapshot = harness.original
            if (action("Unfold").length !== 1 || !action("Unfold")[0].enabled) console.error("A card of two faces should offer Unfold")
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
        if (name.startsWith("templates-")) templateChecks(name)
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
            service.readTemplates()
            capture.start()
        }
    }
    FileView { id: fakeControl; path: Quickshell.env("OMACARDS_FAKE_CONTROL"); blockWrites: true; printErrors: false }
    FileView { id: fakeRecord; path: Quickshell.env("OMACARDS_FAKE_RECORD"); blockLoading: true; blockWrites: true; printErrors: false }
    // Stands in for the bar widget: Service opens and dismisses it.
    QtObject {
        id: fakeOwner
        property bool opened: false
        function dismiss() { opened = false }
        function reveal() { opened = true }
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
            if (harness.waitFor) {
                const ready = harness.waitFor()
                if (!ready && Date.now() < harness.waitUntil) return
                if (!ready) console.error("Timed out waiting before the " + name + " capture")
                harness.waitFor = null
                const then = harness.afterWait
                harness.afterWait = null
                if (then) { then(); return }
            }
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
                        {event: "step", id: "download", title: "Download the pinned Hyprflip release", status: "ok", detail: "Hyprflip v0.3.0-rc.29"},
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
                    card.active = 0; card.current = "0xb"; card.covered = true; card.has_cover = true
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
                harness.templateSetup(next)
                if (next === "pane-edit") { service.page = "edit"; const d = JSON.parse(JSON.stringify(harness.original)); d.cards[0].active = 1; d.cards[0].current = "0xb"; service.snapshot = d; content.paneCardKey = "container:1"; content.paneAddress = "0xc"; window.height = 780 }
            })
        }
    }
}
