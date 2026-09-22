import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui

ColumnLayout {
    id: root
    required property var service
    readonly property var bindingData: service && service.snapshot.shortcuts ? service.snapshot.shortcuts : ({available: false, rows: [], occupied: []})
    property string selectedId: ""
    readonly property var selected: bindingData.rows.find(r => r.id === selectedId) || null
    property int candidateMask: 0
    property string candidateKey: ""
    property string error: ""
    property bool recording: false
    readonly property string conflictError: selected ? conflict(candidateMask, candidateKey) : ""
    signal revealEditor(var item)
    spacing: Style.space(8)
    function chord(mask, key) {
        let names = []
        if (mask & 64) names.push("Super")
        if (mask & 4) names.push("Ctrl")
        if (mask & 8) names.push("Alt")
        if (mask & 1) names.push("Shift")
        names.push(key === "space" ? "Space" : key)
        return names.join("+")
    }
    function choose(row) {
        selectedId = row.id
        candidateMask = row.mask
        candidateKey = row.key
        recording = false
        error = ""
        Qt.callLater(function() { recorder.forceActiveFocus(); root.revealEditor(editorBlock) })
    }
    function conflict(mask, key) {
        const found = bindingData.occupied.find(b => b.id !== selectedId && (!b.submap || b.universal) && b.mask === mask && (b.key.toLowerCase() === key.toLowerCase() || b.keycode))
        return found ? (found.keycode ? "These modifiers include a physical-key binding. Choose different modifiers." : "Used by " + found.label + ". Choose another shortcut.") : ""
    }
    function capture(event) {
        event.accepted = true
        if (event.isAutoRepeat) return
        if ([Qt.Key_Control, Qt.Key_Shift, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_AltGr].indexOf(event.key) >= 0) return
        if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) { recording = false; return }
        let mask = 0
        if (event.modifiers & Qt.MetaModifier) mask |= 64
        if (event.modifiers & Qt.ControlModifier) mask |= 4
        if (event.modifiers & Qt.AltModifier) mask |= 8
        if (event.modifiers & Qt.ShiftModifier) mask |= 1
        if (!(mask & 76)) { error = "Include Super, Ctrl or Alt."; return }
        let key = ""
        if ((event.key >= Qt.Key_A && event.key <= Qt.Key_Z) || (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)) key = String.fromCharCode(event.key)
        else if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F35) key = "F" + (event.key - Qt.Key_F1 + 1)
        else {
            const keys = {}
            keys[Qt.Key_Space] = "space"; keys[Qt.Key_Escape] = "Escape"
            keys[Qt.Key_Return] = "Return"; keys[Qt.Key_Tab] = "Tab"; keys[Qt.Key_Backtab] = "Tab"
            keys[Qt.Key_Backspace] = "BackSpace"; keys[Qt.Key_Delete] = "Delete"
            keys[Qt.Key_Insert] = "Insert"; keys[Qt.Key_Home] = "Home"; keys[Qt.Key_End] = "End"
            keys[Qt.Key_PageUp] = "Prior"; keys[Qt.Key_PageDown] = "Next"
            keys[Qt.Key_Left] = "Left"; keys[Qt.Key_Right] = "Right"; keys[Qt.Key_Up] = "Up"; keys[Qt.Key_Down] = "Down"
            key = keys[event.key] || ""
        }
        if (!key) { error = "Use a letter, number, function key or navigation key."; return }
        candidateMask = mask; candidateKey = key
        error = ""
        recording = false
    }
    onVisibleChanged: if (!visible) recording = false
    Connections {
        target: root.service
        function onPageChanged() { if (root.service.page !== "shortcuts") { root.recording = false; root.selectedId = "" } }
    }
    Label { Layout.fillWidth: true; text: root.bindingData.available ? "Choose an action to change its shortcut." : "Update Hyprflip’s guided setup to enable shortcut editing." }
    ColumnLayout {
        id: editorBlock
        visible: root.selected !== null
        Layout.fillWidth: true
        spacing: Style.space(8)
        Label { text: root.selected ? root.selected.label : ""; font.bold: true; Layout.fillWidth: true }
        Label { text: root.recording ? "Press your new shortcut. Escape cancels." : root.chord(root.candidateMask, root.candidateKey); Layout.fillWidth: true }
        Label { text: root.error || root.conflictError; visible: text.length > 0; color: Color.urgent; Layout.fillWidth: true }
        Flow {
            Layout.fillWidth: true
            spacing: Style.space(6)
            Action {
                id: recorder
                text: root.recording ? "Listening…" : "Record shortcut"
                onClicked: { root.error = ""; root.recording = true; forceActiveFocus() }
                Keys.priority: Keys.BeforeItem
                Keys.onPressed: event => { if (root.recording) root.capture(event); else event.accepted = false }
                onActiveFocusChanged: if (!activeFocus) root.recording = false
            }
            Action {
                text: "Use default"
                onClicked: { root.candidateMask = root.selected.default_mask; root.candidateKey = root.selected.default_key; root.error = "" }
            }
            Action {
                text: "Save shortcut"
                enabled: !root.recording && !root.error && !root.conflictError && root.selected && root.candidateKey.length > 0 && (root.candidateMask !== root.selected.mask || root.candidateKey.toLowerCase() !== root.selected.key.toLowerCase())
                onClicked: root.service.run("shortcut", {binding: root.selectedId, mask: root.candidateMask, key: root.candidateKey})
            }
            Action { text: "Cancel"; onClicked: { root.recording = false; root.selectedId = "" } }
        }
        Ui.PanelSeparator { Layout.fillWidth: true }
    }
    Repeater {
        model: root.bindingData.rows
        ChoiceRow {
            required property var modelData
            Layout.fillWidth: true
            title: modelData.label
            detail: modelData.shortcut + (modelData.editable ? "" : " · Not editable here")
            selected: modelData.id === root.selectedId
            enabled: modelData.editable
            onActivated: root.choose(modelData)
        }
    }
}
