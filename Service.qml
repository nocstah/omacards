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
    // The Hyprflip commit this OmaCards version is built and tested against.
    // Keep it equal to the pin in README.md.
    readonly property string hyprflipPin: "2a71872bd57d029e1734befef86ddc89a6b3d20e"
    readonly property string hyprflipSource: Quickshell.env("HOME") + "/.local/share/omacards/hyprflip"
    readonly property string installer: Qt.resolvedUrl("install_hyprflip.py").toString().replace(/^file:\/\//, "")
    // ready, missing (no helper answered), outdated (old protocol, or a
    // recorded install that differs from the pin) or unloaded (core not loaded).
    property string hyprflipState: "ready"
    property var installSteps: []
    property bool installOk: false
    readonly property bool installing: installProcess.running
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
    readonly property bool busy: operationProcess.running || installProcess.running
    readonly property bool refreshing: snapshotProcess.running
    readonly property var cardsHere: (snapshot.cards || []).filter(c => context && c.workspace === context.workspace)
    readonly property var currentCard: cardsHere.find(c => c.key === selectedKey) || null
    // The accent ring follows the Omarchy theme; Hyprflip only stores a color.
    readonly property string accentHex: "#" + [Color.accent.r, Color.accent.g, Color.accent.b]
        .map(c => Math.round(c * 255).toString(16).padStart(2, "0")).join("").toUpperCase()
    onAccentHexChanged: accentSync.restart()

    function prepareOpen(widget) {
        if (owner && owner !== widget) owner.dismiss()
        owner = widget
        if (busy) { widget.reveal(); return }
        pendingOwner = widget
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
        if (!raw.trim()) {
            snapshot = {available: false, cards: [], saved: [], capabilities: {}}
            hyprflipState = "missing"
            failed = true
            notice = "Hyprflip is not installed. Install it here; nothing needs sudo unless a build tool is missing."
            return revealPending()
        }
        try {
            const data = JSON.parse(raw)
            if (data.protocol !== 1) {
                snapshot = {available: false, cards: [], saved: [], capabilities: {}}
                hyprflipState = "outdated"
                failed = true
                notice = "This OmaCards needs a newer Hyprflip. Update it here."
                return revealPending()
            }
            hyprflipState = !data.available ? "unloaded"
                : data.installed_commit && data.installed_commit !== hyprflipPin ? "outdated" : "ready"
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
            notice = "The Hyprflip helper did not answer. Reinstall Hyprflip here, then refresh Cards."
            console.warn("[omacards] " + error)
        }
        revealPending()
    }
    function revealPending() {
        if (pendingOwner) {
            const widget = pendingOwner
            pendingOwner = null
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
    function run(action, extra) {
        if (busy || refreshing || !snapshot.available || !context) return
        const request = Object.assign({protocol: 1, action: action, context: context}, extra || {})
        operation = request
        completed = false
        cancelled = false
        failed = false
        notice = ""
        question = null
        opening = null
        returnToPanel = ["edit", "manage", "transition", "duration", "preview", "shortcut", "floating", "appearance", "spacing", "accent", "divider", "fullscreen"].indexOf(action) >= 0
        operationProcess.command = ["python3", backend, "run", "--request", JSON.stringify(request)]
        operationProcess.running = true
    }
    // Fetch the pinned Hyprflip and run its bootstrap; progress arrives as
    // one JSON event per line and is kept in installSteps.
    function installHyprflip() {
        if (busy || refreshing) return
        installSteps = []
        installOk = false
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
            } else if (message.event === "done") {
                installOk = message.ok === true
            }
        } catch (error) {
            console.warn("[omacards] installer: " + error)
        }
    }
    function cardAction(action, extra) {
        if (!currentCard) return
        run(action, Object.assign({target: {kind: currentCard.kind, id: currentCard.id, token: currentCard.token}}, extra || {}))
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
    function cancel() {
        if (!busy || cancelled) return
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
            } else throw new Error("Unknown helper response")
        } catch (error) {
            failed = true
            notice = "The helper returned an unreadable response. Refresh Cards."
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
            root.notice = root.installOk ? "Hyprflip is installed. Your open cards were kept."
                : failure ? failure.title + " failed." : "Installing Hyprflip stopped unexpectedly."
            if (!root.installOk) console.warn("[omacards] installer exit " + exitCode + ": " + installErrors.text.slice(0, 2000))
            Qt.callLater(function() { root.refresh(false) })
        }
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
                root.notice = "The card helper stopped. Refresh Cards and try again."
                root.returnToPanel = true
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
