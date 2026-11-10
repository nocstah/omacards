import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons

// One owner for requests across monitors. The helper owns every window change.
Scope {
    id: root
    property var shell: null
    property var manifest: null
    property string omarchyPath: ""
    readonly property string pluginId: "io.github.nocstah.omacards"
    readonly property string backend: Quickshell.env("OMACARDS_BACKEND") || (Quickshell.env("HOME") + "/.local/lib/hyprflip/control.py")
    // The Hyprflip commit Install and Update fetch: the one this OmaCards
    // version is built and tested against. Keep it equal to the pin in README.md.
    readonly property string hyprflipPin: "5420498f1cce0295ec03c65ea0a81de2ab350448"
    // The oldest Hyprflip release this panel works with. An install recording
    // this release or a later one is current, so Hyprflip-only releases need no
    // OmaCards change. Raise it only when the panel needs newer backend behavior.
    readonly property string hyprflipMinimum: "0.3.0-rc.16"
    readonly property string hyprflipSource: Quickshell.env("HOME") + "/.local/share/omacards/hyprflip"
    readonly property string installer: Quickshell.env("OMACARDS_INSTALLER") || Qt.resolvedUrl("install_hyprflip.py").toString().replace(/^file:\/\//, "")
    // ready, missing (no helper answered), outdated (old protocol, or a
    // recorded install older than hyprflipMinimum) or unloaded (core not loaded).
    property string hyprflipState: "ready"
    property var installSteps: []
    property bool installOk: false
    // Build packages Hyprflip's bootstrap reported missing. Only these names
    // may be installed, through Omarchy's own terminal and package helper.
    readonly property var buildPackages: ["cmake", "ninja", "pkgconf", "gcc", "git", "python", "lua", "libglvnd"]
    property var missingPackages: []
    property bool awaitingPackages: false
    readonly property bool installing: installProcess.running
    // Preference saves change no window or focus, so the panel stays open with
    // its page in place while the helper writes them. Card operations hand off
    // focus: the panel closes and comes back when they finish.
    readonly property var quietActions: ["transition", "duration", "appearance", "spacing", "accent", "nearby", "divider", "shortcut"]
    property bool quiet: false
    property var snapshot: ({available: false, cards: [], saved: [], capabilities: {}})
    property var context: null
    property var owner: null
    property var pendingOwner: null
    property string pendingPage: "cards"
    property string requestedPage: "cards"
    property string page: "cards"
    property string selectedKey: ""
    property string notice: ""
    property bool failed: false
    property var question: null
    property var opening: null
    property var operation: null
    property bool completed: false
    property bool cancelled: false
    property bool returnToPanel: false
    property bool preserveContext: false
    property bool returning: false
    // The panel came back by itself after an edit, rather than being opened.
    property bool resumed: false
    // The last snapshot text, so an unchanged refresh leaves the rows (and focus) alone.
    property string snapshotText: ""
    readonly property bool busy: operationProcess.running || installProcess.running
    readonly property bool refreshing: snapshotProcess.running
    readonly property var cardsHere: (snapshot.cards || []).filter(c => context && c.workspace === context.workspace)
    readonly property var currentCard: cardsHere.find(c => c.key === selectedKey) || null
    // The accent ring follows the Omarchy theme; Hyprflip only stores a color.
    readonly property string accentHex: "#" + [Color.accent.r, Color.accent.g, Color.accent.b]
        .map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join("").toUpperCase()
    onAccentHexChanged: accentSync.restart()

    // Orders releases such as 0.3.0-rc.13 < 0.3.0-rc.16 < 0.3.0; null if malformed.
    function compareReleases(a, b) {
        const parse = v => { const m = /^(\d+)\.(\d+)\.(\d+)(?:-rc\.(\d+))?$/.exec(v || ""); return m ? [+m[1], +m[2], +m[3], m[4] === undefined ? Infinity : +m[4]] : null }
        const x = parse(a), y = parse(b)
        if (!x || !y) return null
        for (let i = 0; i < 4; i++) if (x[i] !== y[i]) return x[i] < y[i] ? -1 : 1
        return 0
    }
    // Whether a recorded install is good enough. Installs recording a release
    // compare it with the minimum, so a newer Hyprflip is never offered as an
    // "update" back to the pin. Older bootstraps recorded only a commit, which
    // cannot be ordered here, so that must equal the pin. Hand installs record neither.
    function hyprflipCurrent(data) {
        if (data.installed_release) { const order = compareReleases(data.installed_release, hyprflipMinimum); return order !== null && order >= 0 }
        return !data.installed_commit || data.installed_commit === hyprflipPin
    }
    function prepareOpen(widget) {
        if (owner && owner !== widget) owner.dismiss()
        owner = widget
        if (busy) { widget.reveal(); return }
        pendingOwner = widget
        resumed = false
        pendingPage = requestedPage
        requestedPage = "cards"
        notice = ""
        failed = false
        refresh(false)
    }
    function refresh(keepContext) {
        if (busy || snapshotProcess.running) return
        preserveContext = keepContext === true
        snapshotProcess.running = true
    }
    function acceptSnapshot(raw) {
        if (preserveContext && raw === snapshotText && !pendingOwner && snapshot.available) {
            if (snapshot.animating) settleRefresh.restart()
            return
        }
        snapshotText = ""
        if (!raw.trim()) {
            snapshot = {available: false, cards: [], saved: [], capabilities: {}}
            hyprflipState = "missing"
            // Expected on first use, so it is a next step rather than an error.
            failed = false
            notice = "Hyprflip is not installed. Install it here; if build tools are missing, OmaCards opens a terminal to install them."
            return revealPending()
        }
        try {
            const data = JSON.parse(raw)
            if (data.protocol !== 1) {
                snapshot = {available: false, cards: [], saved: [], capabilities: {}}
                hyprflipState = "outdated"
                failed = false
                notice = "This OmaCards needs a newer Hyprflip. Update it here."
                return revealPending()
            }
            snapshotText = raw
            if (data.animating) settleRefresh.restart()
            hyprflipState = !data.available ? "unloaded"
                : hyprflipCurrent(data) ? "ready" : "outdated"
            snapshot = data
            if (!preserveContext || !context) context = data.context
            const here = (data.cards || []).filter(c => context && c.workspace === context.workspace)
            if (!here.some(c => c.key === selectedKey) || pendingOwner) {
                const focused = here.find(c => c.faces.some(f => f.panes.some(p => p.address === (context || {}).anchor)))
                selectedKey = focused ? focused.key : ""
            }
            if (!data.available) { failed = true; notice = data.error || "Hyprflip is not loaded. Install or reinstall it here." }
        } catch (error) {
            snapshot = {available: false, cards: [], saved: [], capabilities: {}}
            hyprflipState = "missing"
            failed = true
            notice = "The Hyprflip helper did not answer. Reinstall Hyprflip here."
            console.warn("[omacards] " + error)
        }
        revealPending()
    }
    function revealPending() {
        if (pendingOwner) {
            const widget = pendingOwner
            pendingOwner = null
            resumed = returning
            if (returning) {
                returning = false
                const expected = operation && operation.target
                const target = expected ? (snapshot.cards || []).find(c => c.id === expected.id && c.kind === expected.kind) : null
                const anchor = context ? context.anchor : null
                const allowed = anchor === null || (target && target.faces.some(f => f.panes.some(p => p.address === anchor))) || (operation && anchor === operation.context.anchor)
                if (!allowed) return
            }
            page = ["settings", "motion", "shortcuts"].indexOf(pendingPage) >= 0 ? pendingPage : pendingPage === "edit" && currentCard && currentCard.kind === "container" ? "edit" : "cards"
            widget.reveal()
        }
    }
    // returning brings the panel back afterwards, as edits do: for a flip
    // asked for from the edit page.
    function run(action, extra, returning) {
        if (busy || refreshing || !snapshot.available || !context) return
        const request = Object.assign({protocol: 1, action: action, context: context}, extra || {})
        operation = request
        resumed = false
        completed = false
        cancelled = false
        failed = false
        notice = ""
        question = null
        opening = null
        quiet = quietActions.indexOf(action) >= 0
        returnToPanel = !quiet && (returning === true || ["edit", "manage", "preview", "floating", "fullscreen"].indexOf(action) >= 0)
        operationProcess.command = ["python3", backend, "run", "--request", JSON.stringify(request)]
        operationProcess.running = true
    }
    // Fetch the pinned Hyprflip and run its bootstrap; progress arrives as
    // one JSON event per line and is kept in installSteps.
    function installHyprflip() {
        if (busy || refreshing) return
        installSteps = []
        installOk = false
        missingPackages = []
        awaitingPackages = false
        failed = false
        notice = ""
        installProcess.command = ["python3", installer, hyprflipPin, hyprflipSource]
        installProcess.running = true
    }
    function receiveInstall(line) {
        if (!line.trim()) return
        try {
            const message = JSON.parse(line)
            if (message.event === "step") {
                const steps = installSteps.filter(s => s.id !== message.id)
                const index = installSteps.findIndex(s => s.id === message.id)
                steps.splice(index < 0 ? steps.length : index, 0, message)
                installSteps = steps
                if (message.status === "failed") missingPackages = packagesFrom(message.fix || "")
            } else if (message.event === "done") {
                installOk = message.ok === true
            }
        } catch (error) {
            console.warn("[omacards] installer: " + error)
        }
    }
    function packagesFrom(fix) {
        const match = /^sudo pacman -S --needed ([a-z0-9 ]+)$/.exec(fix)
        const names = match ? match[1].split(" ") : []
        return names.length > 0 && names.every(n => buildPackages.indexOf(n) >= 0) ? names : []
    }
    // The password is typed in a visible Omarchy terminal; OmaCards itself
    // never runs sudo. The launcher returns at once, so watch for the result.
    function installPackages() {
        if (busy || missingPackages.length === 0) return
        packageLauncher.command = ["omarchy-launch-floating-terminal-with-presentation", "omarchy-pkg-add " + missingPackages.join(" ")]
        packageLauncher.running = true
        awaitingPackages = true
        packageDeadline.restart()
    }
    function cardAction(action, extra, returning) {
        if (!currentCard) return
        run(action, Object.assign({target: {kind: currentCard.kind, id: currentCard.id, token: currentCard.token}}, extra || {}), returning)
    }
    function edit(intent, face, pane) {
        cardAction("edit", {intent: intent, face: face, pane: pane || null})
    }
    function savedAction(action, saved) {
        run(action, {name: saved.name, recipe_token: saved.token})
    }
    function reply(value) {
        if (!busy || !question) return
        const id = question.id
        question = null
        operationProcess.write(JSON.stringify({reply: id, value: value}) + "\n")
    }
    // Only card operations can be cancelled; an install runs to the end.
    function cancel() {
        if (!operationProcess.running || cancelled) return
        cancelled = true
        returnToPanel = false
        question = null
        operationProcess.write('{"cancel":true}\n')
        cancelTimer.restart()
    }
    function dismiss() {
        if (question) cancel()
        pendingOwner = null
        returnToPanel = false
        if (owner) owner.dismiss()
    }
    function receive(line) {
        if (!line.trim()) return
        try {
            const message = JSON.parse(line)
            if (message.type === "handoff") {
                if (quiet) { operationProcess.write(JSON.stringify({resume: message.id}) + "\n"); return }
                if (owner) owner.dismiss()
                // KeyboardPanel releases its grab as soon as open becomes false.
                Qt.callLater(function() {
                    if (root.busy && !root.cancelled) operationProcess.write(JSON.stringify({resume: message.id}) + "\n")
                })
            } else if (message.type === "question") {
                question = message
                if (owner) owner.reveal()
            } else if (message.type === "opening") {
                opening = message
            } else if (["done", "error", "cancelled"].indexOf(message.type) >= 0) {
                completed = true
                question = null
                opening = null
                notice = message.message || ""
                failed = message.type === "error"
                if (failed) returnToPanel = true
                if (message.type === "cancelled") returnToPanel = owner && owner.opened
                // A quiet save never closed the panel, so there is nothing to bring back.
                if (quiet) returnToPanel = false
            } else throw new Error("Unknown helper response")
        } catch (error) {
            failed = true
            notice = "The card helper sent a reply OmaCards cannot read. Try again; if it keeps happening, update Hyprflip."
            cancel()
            console.warn("[omacards] " + error)
        }
    }
    Process {
        id: installProcess
        stdout: SplitParser { onRead: data => root.receiveInstall(data) }
        stderr: StdioCollector { id: installErrors; waitForEnd: true }
        onExited: (exitCode, exitStatus) => {
            const failure = root.installSteps.find(s => s.status === "failed")
            root.failed = !root.installOk
            root.notice = root.installOk ? "Hyprflip is installed."
                : failure ? failure.title + " failed." : "Installing Hyprflip stopped unexpectedly."
            if (!root.installOk) console.warn("[omacards] installer exit " + exitCode + ": " + installErrors.text.slice(0, 2000))
            Qt.callLater(function() { root.refresh(false) })
        }
    }
    Process { id: packageLauncher }
    Process {
        id: packageCheck
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 || !root.awaitingPackages || root.refreshing) return
            root.awaitingPackages = false
            packageDeadline.stop()
            root.installHyprflip()
        }
    }
    // Only while the panel is open and waiting on the terminal.
    Timer {
        interval: 2000
        repeat: true
        running: root.awaitingPackages && root.owner !== null && root.owner.opened && !root.busy
        onTriggered: if (!packageCheck.running) {
            packageCheck.command = ["pacman", "-Q"].concat(root.missingPackages)
            packageCheck.running = true
        }
    }
    Timer {
        id: packageDeadline
        interval: 600000
        onTriggered: root.awaitingPackages = false
    }
    Process {
        id: snapshotProcess
        command: ["python3", root.backend, "snapshot"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.acceptSnapshot(text)
        }
    }
    Process {
        id: operationProcess
        stdinEnabled: true
        stdout: SplitParser { onRead: data => root.receive(data) }
        stderr: StdioCollector { id: operationErrors; waitForEnd: true }
        onExited: (exitCode, exitStatus) => {
            cancelTimer.stop()
            if (!root.completed && !root.cancelled) {
                root.failed = true
                root.notice = "The card helper stopped before finishing. Try again."
                root.returnToPanel = !root.quiet
                console.warn("[omacards] helper exit " + exitCode + ": " + operationErrors.text.slice(0, 2000))
            }
            root.question = null
            root.opening = null
            // Returning must not steal focus after the user navigates away.
            const sameWorkspace = root.context && Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === root.context.workspace
            if (root.returnToPanel && sameWorkspace && root.owner) {
                root.pendingOwner = root.owner
                root.pendingPage = root.page
                root.returning = true
            }
            Qt.callLater(function() { root.refresh(false) })
        }
    }
    // Theme switches update several colors at once; send the settled accent.
    // The helper skips unchanged colors, and older Hyprflip builds just refuse.
    Timer {
        id: accentSync
        interval: 400
        onTriggered: {
            if (accentProcess.running) { restart(); return }
            accentProcess.command = ["python3", root.backend, "accent-color", "--color", root.accentHex]
            accentProcess.running = true
        }
    }
    Process {
        id: accentProcess
        stdout: StdioCollector { waitForEnd: true }
    }
    Timer {
        id: cancelTimer
        interval: 9000
        onTriggered: if (operationProcess.running) operationProcess.signal(15)
    }
    // Refresh only while the panel is visible; never poll the desktop at idle.
    Timer {
        interval: 5000
        repeat: true
        running: root.owner !== null && root.owner.opened && !root.busy && !root.refreshing
        onTriggered: root.refresh(true)
    }
    Timer { id: eventRefresh; interval: 180; onTriggered: root.refresh(true) }
    // A card still turning reports the face it is leaving; look again once
    // the turn is over instead of showing the old face until the next refresh.
    Timer { id: settleRefresh; interval: 200; onTriggered: if (root.owner && root.owner.opened) root.refresh(true) }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!root.owner || !root.owner.opened || root.busy) return
            if (["openwindow", "closewindow", "movewindowv2", "workspacev2", "configreloaded"].indexOf(event.name) >= 0) eventRefresh.restart()
        }
    }
    IpcHandler {
        target: "omacards"
        function status(): string {
            return JSON.stringify({available: root.snapshot.available, opened: root.owner ? root.owner.opened : false,
                                   busy: root.busy, page: root.page, cards: root.snapshot.cards.length,
                                   saved: root.snapshot.saved.length, error: root.failed ? root.notice : ""})
        }
        function close(): void { root.dismiss() }
        function open(page: string): string {
            if (!root.shell) return "unavailable"
            root.requestedPage = ["cards", "library", "edit", "settings", "motion", "shortcuts"].indexOf(page) >= 0 ? page : "cards"
            return root.shell.summon(root.pluginId, "") ? "ok" : "unavailable"
        }
    }
    Component.onCompleted: accentSync.restart()
    Component.onDestruction: {
        if (operationProcess.running) {
            operationProcess.write('{"cancel":true}\n')
            operationProcess.signal(15)
        }
    }
}
