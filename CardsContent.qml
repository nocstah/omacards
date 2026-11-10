import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as Controls
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui

FocusScope {
    id: root
    required property var service
    signal closeRequested()
    readonly property var snapshotData: service ? service.snapshot : ({})
    readonly property var caps: snapshotData.capabilities || ({})
    readonly property var card: service ? service.currentCard : null
    readonly property bool busy: service ? service.busy : false
    readonly property var question: service ? service.question : null
    readonly property string page: service ? service.page : "cards"
    // Saving a preference keeps the page in place; anything else shows progress.
    readonly property bool quietBusy: busy && !!service && service.quiet && !service.installing
    readonly property bool showProgress: busy && !quietBusy && !question
    readonly property bool pageVisible: !showProgress && !question
    property string paneAddress: ""
    property string paneCardKey: ""
    // The card whose Ungroup is waiting for confirmation.
    property string ungroupKey: ""
    readonly property bool confirmUngroup: ungroupKey !== "" && !!card && card.key === ungroupKey && page === "edit"
    property string filter: ""
    property int cursor: 0
    property int choiceCursor: 0
    property bool advanced: false
    // The last control the keyboard or pointer focused, so focus can come back
    // to it when the helper replaces the rows or the panel returns after an edit.
    property var lastFocus: null
    // Set when focus fell out of the page by itself (rows rebuilt, a page
    // hidden), not when the panel put it on the key catcher on purpose.
    property bool focusLost: false
    property bool placingFocus: false
    readonly property bool recordingShortcut: shortcutSettings.recording
    readonly property bool typing: recordingShortcut || search.activeFocus || nameInput.activeFocus || duration.activeFocus
    function stopRecording() { shortcutSettings.recording = false }
    readonly property var savedRows: (snapshotData.saved || []).filter(row => (row.name + " " + row.description).toLowerCase().includes(filter.toLowerCase()))
    readonly property bool hasSavedCards: (snapshotData.saved || []).length > 0
    readonly property bool hasFrontApp: !!(service && service.context && service.context.anchor)
    readonly property string frontAppName: hasFrontApp ? (service.context.anchor_label || "Selected app") : ""
    readonly property string progressTitle: !service ? ""
        : service.installing ? "Installing Hyprflip…"
        : service.cancelled ? "Cancelling…"
        : service.opening ? "Opening “" + service.opening.name + "”…"
        : actionTitle(service.operation)
    implicitWidth: Style.space(440)
    implicitHeight: Math.min(column.implicitHeight, Style.space(660))

    function actionTitle(operation) {
        const titles = {create: "Creating your card…", open: "Opening your saved card…", manage: "Updating saved cards…",
                        edit: "Editing your card…", preview: "Previewing the transition…", flip: "Flipping your card…"}
        return (operation && titles[operation.action]) || "Working on your card…"
    }
    function focusEntry() {
        if (question && question.mode === "input") { nameInput.forceActiveFocus(); return }
        if (question) { choices.forceActiveFocus(); return }
        // Back from an edit that closed the panel: return to the control used.
        if (service && service.resumed && restoreFocus()) return
        if (page === "cards" && pageVisible && search.visible) search.forceActiveFocus()
        else if (page === "cards" && pageVisible && chooseBack.visible && chooseBack.enabled) chooseBack.forceActiveFocus()
        else { placingFocus = true; keys.forceActiveFocus(); placingFocus = false }
    }
    function back() {
        if (question) service.cancel()
        else if (confirmUngroup) { ungroupKey = ""; ungroupButton.forceActiveFocus() }
        else if (page === "motion" || page === "shortcuts") { service.page = "settings"; focusEntry() }
        else if (page !== "cards") { service.page = "cards"; paneAddress = ""; focusEntry() }
        else closeRequested()
    }
    // Arranging a face keeps its selected app; anything that moves, swaps or
    // removes an app, or leaves the card, starts again without one.
    function edit(intent, face, pane) {
        if (["previous", "next", "horizontal", "vertical", "balance", ""].indexOf(intent) < 0) paneAddress = ""
        service.edit(intent, face, pane)
    }
    function choosePane(faceIndex, address, showing) {
        paneCardKey = card.key
        if (!showing) { paneAddress = address; edit("", faceIndex, null) }
        else paneAddress = paneAddress === address ? "" : address
    }
    function selectedPane() {
        if (!card || !paneAddress) return null
        for (const face of card.faces) {
            const index = face.panes.findIndex(p => p.address === paneAddress)
            if (index >= 0) return {face: face, index: index, showing: card.active === face.index || card.unfolded}
        }
        return null
    }
    function reorderPane(dy) {
        const found = selectedPane()
        if (!found || !found.showing) return
        const target = found.index + dy
        if (target >= 0 && target < found.face.panes.length) edit(dy < 0 ? "previous" : "next", found.face.index, paneAddress)
    }
    function removePane() {
        const found = selectedPane()
        const focused = root.Window.activeFocusItem
        if (!found || !found.showing || !focused || focused.paneAddress !== paneAddress) return
        if (found.face.panes.length > 1 || manyFaces) edit("remove", found.face.index, paneAddress)
    }
    // The helper names faces (Front, Back, Face 3, Face 4); older helpers only send two.
    function faceName(index) {
        const face = card && card.faces[index]
        return face && face.name ? face.name : index === 0 ? "Front" : index === 1 ? "Back" : "Face " + (index + 1)
    }
    function nextFace(index) { return card ? (index + 1) % card.faces.length : 0 }
    readonly property bool manyFaces: !!card && card.faces.length > 2
    function groupName(header, options, value) {
        const option = options.find(o => String(o.value) === String(value))
        return header + ", " + (option ? option.label + " selected" : "none selected")
    }

    // Keyboard movement walks the controls on the page in reading order;
    // arrows move by row and column, Tab by control.
    function focusables() {
        const found = []
        function walk(item) {
            if (!item || !item.visible) return
            if (item.activeFocusOnTab && item.enabled) found.push(item)
            for (const child of item.children) walk(child)
        }
        walk(column)
        return found
    }
    function focusKey(item) {
        for (const name of ["accessibleName", "title", "label", "text"])
            if (item[name] !== undefined && item[name] !== "") return name + ":" + item[name]
        return ""
    }
    function noteFocus(item) {
        const index = focusables().indexOf(item)
        if (index >= 0) { lastFocus = {page: page, key: focusKey(item), index: index}; focusLost = false }
        else if (!placingFocus) focusLost = true
    }
    function restoreFocus() {
        const saved = lastFocus
        if (!saved || saved.page !== page || !pageVisible) return false
        const list = focusables()
        if (!list.length) return false
        const match = list.find(i => saved.key && focusKey(i) === saved.key) || list[Math.min(saved.index, list.length - 1)]
        match.forceActiveFocus(Qt.OtherFocusReason)
        return true
    }
    // The rows were rebuilt, or the progress view gave the page back: if focus
    // fell out of the page, put it back where it was.
    function recoverFocus() {
        const window = root.Window.window
        if (!focusLost || !window || !window.visible || !pageVisible || typing) return
        if (!restoreFocus()) focusEntry()
    }
    function moveFocus(dx, dy) {
        const list = focusables()
        if (!list.length) return
        gate.reset()
        const current = root.Window.activeFocusItem
        if (list.indexOf(current) < 0) {
            (dy < 0 || dx < 0 ? list[list.length - 1] : list[0]).forceActiveFocus(Qt.TabFocusReason)
            return
        }
        const box = item => {
            const p = item.mapToItem(column, 0, 0)
            return {item: item, x: p.x, y: p.y, w: item.width, h: item.height, cx: p.x + item.width / 2, cy: p.y + item.height / 2}
        }
        const here = box(current)
        const others = list.filter(i => i !== current).map(box)
        let target = null
        if (dy !== 0) {
            const ahead = others.filter(b => dy > 0 ? b.y >= here.cy - 1 && b.cy > here.cy + 1 : b.y + b.h <= here.cy + 1 && b.cy < here.cy - 1)
            if (!ahead.length) return
            const nearest = ahead.reduce((a, b) => Math.abs(b.cy - here.cy) < Math.abs(a.cy - here.cy) ? b : a)
            const row = ahead.filter(b => b.y < nearest.y + nearest.h && b.y + b.h > nearest.y)
            const score = b => Math.max(0, b.x - (here.x + here.w), here.x - (b.x + b.w)) * 10000 + Math.abs(b.x - here.x)
            target = row.reduce((a, b) => score(b) < score(a) ? b : a)
        } else {
            const beside = others.filter(b => b.y < here.cy && b.y + b.h > here.cy && (dx > 0 ? b.cx > here.cx : b.cx < here.cx))
            if (!beside.length) return
            target = beside.reduce((a, b) => Math.abs(b.cx - here.cx) < Math.abs(a.cx - here.cx) ? b : a)
        }
        target.item.forceActiveFocus(Qt.TabFocusReason)
    }
    function moveTab(direction) {
        const list = focusables()
        if (!list.length) return
        gate.reset()
        const from = list.indexOf(root.Window.activeFocusItem)
        const next = from < 0 ? (direction > 0 ? 0 : list.length - 1) : (from + direction + list.length) % list.length
        list[next].forceActiveFocus(direction > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason)
    }
    function showItem(item) {
        if (!item) return
        let ancestor = item
        while (ancestor && ancestor !== root) ancestor = ancestor.parent
        if (!ancestor) return
        const y = item.mapToItem(column, 0, 0).y
        if (y < scroller.contentY) scroller.contentY = y
        else if (y + item.height > scroller.contentY + scroller.height) scroller.contentY = y + item.height - scroller.height
    }
    onChoiceCursorChanged: showItem(choiceRepeater.itemAt(choiceCursor))
    onCursorChanged: showItem(savedRepeater.itemAt(cursor))
    onConfirmUngroupChanged: if (confirmUngroup) Qt.callLater(() => keepCard.forceActiveFocus())
    Keys.onEscapePressed: back()
    // While someone types or records a shortcut, the pointer never takes focus.
    Ui.PointerMoveGate {
        id: gate
        referenceItem: root
        property bool paused: root.typing
    }
    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() {
            const item = root.Window.window.activeFocusItem
            root.showItem(item)
            root.noteFocus(item)
        }
    }
    Connections {
        target: root.service
        function onQuestionChanged() {
            root.choiceCursor = 0
            nameInput.text = ""
            scroller.contentY = 0
            Qt.callLater(root.focusEntry)
        }
        function onPageChanged() { root.ungroupKey = ""; scroller.contentY = 0; Qt.callLater(root.focusEntry) }
        function onSnapshotChanged() { Qt.callLater(root.recoverFocus) }
        function onBusyChanged() { Qt.callLater(root.recoverFocus) }
        function onCurrentCardChanged() {
            if (!root.card || root.card.key !== root.paneCardKey || !root.card.faces.some(f => f.panes.some(p => p.address === root.paneAddress))) root.paneAddress = ""
        }
    }

    Ui.PanelKeyCatcher {
        id: keys
        anchors.fill: parent
        blocked: root.recordingShortcut
        reorderable: root.page === "edit" && root.paneAddress !== ""
        onMoveRequested: function(dx, dy) { root.moveFocus(dx, dy) }
        onTabRequested: function(direction) { root.moveTab(direction) }
        onReorderRequested: function(dy) { root.reorderPane(dy) }
        onDeleteRequested: root.removePane()
        onCloseRequested: root.back()

        Flickable {
            id: scroller
            anchors.fill: parent
            contentHeight: column.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar { policy: scroller.contentHeight > scroller.height ? Controls.ScrollBar.AsNeeded : Controls.ScrollBar.AlwaysOff }
            ColumnLayout {
                id: column
                width: scroller.width
                spacing: Style.space(12)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(6)
                    Label {
                        text: root.question ? "Choose for your card" : (root.page === "settings" ? "Settings" : root.page === "shortcuts" ? "Keyboard shortcuts" : root.page === "motion" ? "Motion" : root.page === "edit" ? "Edit card" : "Cards")
                        font.pixelSize: Style.font.heading
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Label { text: "Saving…"; visible: root.quietBusy; font.pixelSize: Style.font.bodySmall }
                    Action { text: "Back"; visible: root.pageVisible && root.page !== "cards"; onClicked: root.back() }
                    Action { text: "Settings"; visible: root.pageVisible && root.page === "cards" && root.snapshotData.available; onClicked: root.service.page = "settings" }
                    Action { text: "Close"; onClicked: root.closeRequested() }
                }
                // Errors name the app and the sizes involved; show all of it.
                Notice {
                    Layout.fillWidth: true
                    text: root.service ? root.service.notice : "Starting OmaCards…"
                    error: !!root.service && root.service.failed
                }
                ColumnLayout {
                    visible: root.showProgress
                    Layout.fillWidth: true
                    spacing: Style.space(6)
                    Label { text: root.progressTitle; Layout.fillWidth: true; font.bold: true }
                    Label { text: root.service && root.service.opening ? "Waiting for " + root.service.opening.labels.join(", ") : ""; visible: text.length > 0; Layout.fillWidth: true }
                    Label {
                        Layout.fillWidth: true
                        text: !root.service ? "" : root.service.installing ? "You can close this panel. Installing continues, and the bar button shows when it is done."
                            : root.service.opening ? "Apps that have opened stay open if you cancel." : ""
                        visible: text.length > 0
                    }
                    // Only card operations can be cancelled; an install runs to the end.
                    Action { text: "Cancel"; visible: root.service && !root.service.installing; enabled: root.service && !root.service.cancelled; onClicked: root.service.cancel() }
                }
                // Installer progress: one row per step. A failed install keeps its
                // steps for the fix; a finished one says so in the notice instead.
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(6)
                    visible: root.service && root.service.installSteps.length > 0 && (root.service.installing || !root.service.installOk)
                    Repeater {
                        model: root.service ? root.service.installSteps : []
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Style.space(8)
                            Label {
                                Layout.alignment: Qt.AlignTop
                                text: modelData.status === "ok" ? "✓" : modelData.status === "failed" ? "✗" : "…"
                                color: modelData.status === "failed" ? Commons.Color.urgent : modelData.status === "ok" ? Commons.Color.accent : Commons.Color.popups.text
                                font.bold: true
                                Accessible.name: modelData.status === "ok" ? "Done" : modelData.status === "failed" ? "Failed" : "In progress"
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.space(2)
                                Label { Layout.fillWidth: true; text: modelData.title; wrapMode: Text.WordWrap; font.bold: modelData.status !== "ok" }
                                Label {
                                    Layout.fillWidth: true
                                    visible: !!modelData.detail
                                    text: modelData.detail || ""
                                    wrapMode: Text.WrapAnywhere
                                    font.pixelSize: Style.font.bodySmall
                                }
                                TextEdit {
                                    Layout.fillWidth: true
                                    visible: !!modelData.fix
                                    text: modelData.fix || ""
                                    readOnly: true
                                    selectByMouse: true
                                    selectByKeyboard: true
                                    activeFocusOnTab: true
                                    wrapMode: TextEdit.WrapAnywhere
                                    color: Commons.Color.popups.text
                                    font.family: "monospace"
                                    font.pixelSize: Style.font.bodySmall
                                    Accessible.role: Accessible.EditableText
                                    Accessible.readOnly: true
                                    Accessible.name: "Command to run: " + text
                                    // Selected while focused, so Ctrl+C copies it and focus is visible.
                                    onActiveFocusChanged: activeFocus ? selectAll() : deselect()
                                }
                            }
                        }
                    }
                }
                // The bootstrap stopped on missing build packages; install them in a terminal.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(8)
                    visible: !root.busy && root.service && root.service.missingPackages.length > 0
                    Label {
                        Layout.fillWidth: true
                        text: root.service && root.service.awaitingPackages
                            ? "Enter your password in the terminal. Hyprflip installs once " + root.service.missingPackages.join(", ") + " are in."
                            : "Hyprflip needs " + (root.service ? root.service.missingPackages.join(", ") : "") + " to build."
                        wrapMode: Text.WordWrap
                    }
                    Action {
                        objectName: "installPackages"
                        text: root.service && root.service.awaitingPackages ? "Open terminal again" : "Install build tools"
                        onClicked: root.service.installPackages()
                    }
                }
                RowLayout {
                    visible: !root.busy && !root.snapshotData.available && root.service && root.service.hyprflipState !== "ready"
                    Action {
                        objectName: "installHyprflip"
                        text: !root.service ? "" : root.service.hyprflipState === "outdated" ? "Update Hyprflip"
                            : root.service.hyprflipState === "unloaded" ? "Reinstall Hyprflip" : "Install Hyprflip"
                        enabled: root.service && !root.service.refreshing
                        onClicked: root.service.installHyprflip()
                    }
                }
                // Cards still work, but OmaCards is paired with a different Hyprflip.
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(8)
                    visible: !root.busy && root.snapshotData.available && root.service && root.service.hyprflipState === "outdated" && !root.service.failed && root.page === "cards"
                    Label { Layout.fillWidth: true; text: "A newer Hyprflip is paired with this OmaCards."; wrapMode: Text.WordWrap }
                    Action { text: "Update Hyprflip"; onClicked: root.service.installHyprflip() }
                }

                // Every backend question is displayed here, keeping a single UI flow.
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.question !== null
                    Label { Layout.fillWidth: true; text: root.question ? root.question.prompt : ""; font.bold: true }
                    KeyField {
                        id: nameInput
                        Layout.fillWidth: true
                        visible: root.question !== null && root.question.mode === "input"
                        placeholderText: root.question ? root.question.prompt : ""
                        maximumLength: 64
                        onAccepted: if (text.trim()) root.service.reply(text.trim())
                        Accessible.name: root.question ? root.question.prompt : "Card name"
                    }
                    FocusScope {
                        id: choices
                        Layout.fillWidth: true
                        implicitHeight: choiceList.implicitHeight
                        visible: root.question !== null && root.question.mode === "select"
                        Keys.onUpPressed: { root.choiceCursor = Math.max(0, root.choiceCursor - 1); const row = choiceRepeater.itemAt(root.choiceCursor); if (row) row.forceActiveFocus() }
                        Keys.onDownPressed: { root.choiceCursor = Math.min(choiceRepeater.count - 1, root.choiceCursor + 1); const row = choiceRepeater.itemAt(root.choiceCursor); if (row) row.forceActiveFocus() }
                        Keys.onReturnPressed: if (root.question && root.question.choices[root.choiceCursor]) root.service.reply(root.question.choices[root.choiceCursor].value)
                        Keys.onEnterPressed: if (root.question && root.question.choices[root.choiceCursor]) root.service.reply(root.question.choices[root.choiceCursor].value)
                        Column {
                            id: choiceList
                            width: parent.width
                            Repeater {
                                id: choiceRepeater
                                model: root.question ? root.question.choices : []
                                ChoiceRow {
                                    required property var modelData
                                    required property int index
                                    width: choiceList.width
                                    title: modelData.label
                                    detail: modelData.detail || ""
                                    selected: choices.activeFocus && root.choiceCursor === index
                                    pointerGate: gate
                                    onActiveFocusChanged: if (activeFocus) root.choiceCursor = index
                                    onActivated: root.service.reply(modelData.value)
                                }
                            }
                        }
                    }
                    RowLayout {
                        Action { text: "Continue"; visible: nameInput.visible; enabled: nameInput.text.trim().length > 0; onClicked: root.service.reply(nameInput.text.trim()) }
                        Action { text: "Cancel"; onClicked: root.service.cancel() }
                    }
                }

                ColumnLayout {
                    visible: root.pageVisible && root.snapshotData.available && root.page === "cards"
                    Layout.fillWidth: true
                    spacing: Style.space(10)
                    ColumnLayout {
                        visible: root.service && (root.service.cardsHere.length > 1 || (!root.card && root.service.cardsHere.length > 0))
                        Layout.fillWidth: true
                        Label { text: "Open cards on this workspace"; font.pixelSize: Style.font.bodySmall }
                        Repeater {
                            model: root.service ? root.service.cardsHere : []
                            ChoiceRow {
                                required property var modelData
                                Layout.fillWidth: true
                                title: modelData.name
                                detail: "Select to flip or edit"
                                checkable: true
                                selected: root.card && modelData.key === root.card.key
                                pointerGate: gate
                                onActivated: root.service.selectedKey = modelData.key
                            }
                        }
                    }
                    ColumnLayout {
                        visible: root.card !== null
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        Label { text: root.card ? root.card.name : ""; Layout.fillWidth: true; font.bold: true; font.pixelSize: Style.font.title }
                        Label { text: root.card ? "Workspace " + root.card.workspace_label + (root.card.unfolded ? (root.manyFaces ? " · All faces visible" : " · Both sides visible") : "") + (root.card.floating ? " · Floating" : "") + (root.card.fullscreen ? " · Fullscreen" : "") : ""; font.pixelSize: Style.font.bodySmall }
                        Repeater {
                            model: root.card ? root.card.faces : []
                            RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: Style.space(6)
                                Label { text: root.faceName(modelData.index); Layout.preferredWidth: Style.space(48); font.bold: root.card && root.card.active === modelData.index }
                                Label { text: modelData.panes.map(p => p.label).join(" · "); Layout.fillWidth: true }
                                Label { text: "Showing"; visible: root.card && (root.card.active === modelData.index || root.card.unfolded); color: Commons.Color.accent; font.pixelSize: Style.font.bodySmall }
                            }
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.space(6)
                            Action {
                                text: "Flip"
                                enabled: root.card && !root.card.unfolded
                                tooltipText: !root.card ? "" : root.card.unfolded ? "Fold the card first" : root.card.faces.length > 2 ? "Turn to " + root.faceName(root.nextFace(root.card.active)) : ""
                                onClicked: root.service.cardAction("flip")
                            }
                            Action { text: root.card && root.card.unfolded ? "Fold" : "Unfold"; visible: root.card && root.card.kind === "container"; onClicked: root.service.cardAction("unfold") }
                            Action { text: root.card && root.card.floating ? "Tile card" : "Float card"; visible: !!root.caps.floating; enabled: !(root.card && root.card.fullscreen); tooltipText: root.card && root.card.fullscreen ? "Leave fullscreen first" : ""; onClicked: root.service.cardAction("floating") }
                            Action { text: root.card && root.card.fullscreen ? "Leave fullscreen" : "Fullscreen"; visible: !!root.caps.fullscreen && root.card && root.card.native === true; tooltipText: "Fill the screen with the whole card · Apps keep their toolbars"; onClicked: root.service.cardAction("fullscreen") }
                            Action { text: "Edit"; visible: root.card && root.card.kind === "container"; onClicked: root.service.page = "edit" }
                            Action { text: "Save…"; visible: root.card && root.card.kind === "container"; onClicked: root.edit("save", root.card.active, null) }
                        }
                        Label { text: "Ungroup this pair, then choose Create a new card to enable editing and saved arrangements."; visible: root.card && root.card.kind === "pair"; Layout.fillWidth: true }
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true; visible: root.card !== null || (root.service && root.service.cardsHere.length > 0) }
                    ColumnLayout {
                        id: savedLibrary
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        visible: root.hasSavedCards || root.card !== null || !!root.snapshotData.library_error
                        Label { text: "Saved cards"; font.bold: true }
                        Notice { Layout.fillWidth: true; text: root.snapshotData.library_error || ""; error: true }
                        KeyField {
                            id: search
                            Layout.fillWidth: true
                            visible: root.hasSavedCards
                            placeholderText: "Search saved cards…"
                            Accessible.name: "Search saved cards"
                            text: root.filter
                            onTextEdited: { root.filter = text; root.cursor = 0 }
                            Keys.onUpPressed: root.cursor = Math.max(0, root.cursor - 1)
                            Keys.onDownPressed: root.cursor = Math.min(root.savedRows.length - 1, root.cursor + 1)
                            // Escape clears a search before it closes anything.
                            Keys.onEscapePressed: event => { if (text.length > 0) { root.filter = ""; root.cursor = 0 } else event.accepted = false }
                            onAccepted: if (root.savedRows[root.cursor]) root.service.savedAction("open", root.savedRows[root.cursor])
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Style.space(2)
                            Repeater {
                                id: savedRepeater
                                model: root.savedRows
                                RowLayout {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    spacing: Style.space(6)
                                    ChoiceRow {
                                        Layout.fillWidth: true
                                        title: modelData.name
                                        detail: modelData.detail + "\n" + modelData.description
                                        selected: search.activeFocus && root.cursor === index
                                        pointerGate: gate
                                        onPointed: if (search.activeFocus) root.cursor = index
                                        onActivated: root.service.savedAction("open", modelData)
                                    }
                                    Action { text: "Manage"; accessibleName: "Manage " + modelData.name; tooltipText: "Rename, duplicate or delete “" + modelData.name + "”"; onClicked: root.service.savedAction("manage", modelData) }
                                }
                            }
                        }
                        Label {
                            Layout.fillWidth: true
                            text: root.filter ? "No saved cards match your search. Escape clears it." : "Save a card to reopen its apps and layout later."
                            visible: root.savedRows.length === 0 && !root.snapshotData.library_error
                        }
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true; visible: root.card === null && savedLibrary.visible }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(8)
                        visible: root.card === null
                        Label { text: "Create a new card"; font.bold: true; Layout.fillWidth: true }
                        Label {
                            text: "Front: " + root.frontAppName
                            visible: root.hasFrontApp && !!root.caps.containers
                            Layout.fillWidth: true
                        }
                        Label {
                            text: !root.caps.containers
                                ? "Update Hyprflip and its helper to create multi-app cards on dwindle."
                                : root.hasFrontApp
                                    ? "Choose another open app for the back. Apps are resized to fit the card automatically. Flip to switch sides."
                                    : "Select the app you want on the front, then reopen Cards to choose an app for the back."
                            Layout.fillWidth: true
                        }
                        Action {
                            id: chooseBack
                            text: "Choose app for back…"
                            visible: root.hasFrontApp && !!root.caps.containers
                            onClicked: root.service.run("create")
                        }
                        Label {
                            text: "For a different front, focus that app and reopen Cards."
                            visible: chooseBack.visible
                            Layout.fillWidth: true
                            font.pixelSize: Style.font.bodySmall
                        }
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true }
                    Label {
                        text: (root.snapshotData.shortcuts ? root.snapshotData.shortcuts.rows : []).filter(r => r.id === "edit" || r.id === "library").map(r => r.label + ": " + r.shortcut).join("\n")
                        visible: text.length > 0
                        Layout.fillWidth: true
                        font.pixelSize: Style.font.bodySmall
                    }
                }

                ColumnLayout {
                    visible: root.pageVisible && root.page === "settings"
                    Layout.fillWidth: true
                    spacing: Style.space(8)
                    Label { text: "Preferences apply to all cards and are kept after a restart."; Layout.fillWidth: true }
                    ChoiceRow {
                        Layout.fillWidth: true
                        title: "Motion"
                        detail: "Transition, speed and preview · Instant turns off motion"
                        pointerGate: gate
                        onActivated: root.service.page = "motion"
                    }
                    ChoiceRow {
                        Layout.fillWidth: true
                        title: "Keyboard shortcuts"
                        detail: "Change a shortcut or restore its default"
                        pointerGate: gate
                        onActivated: root.service.page = "shortcuts"
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true; Layout.topMargin: Style.space(4) }

                    Ui.PanelSectionHeader { text: "Card appearance"; foreground: Commons.Color.popups.text; Layout.fillWidth: true }
                    Label {
                        visible: !root.caps.appearance
                        text: "Update Hyprflip to choose the card appearance."
                        Layout.fillWidth: true
                    }
                    Ui.ButtonGroup {
                        id: appearanceGroup
                        readonly property string accessibleName: root.groupName("Card appearance", options, value)
                        options: [
                            {value: "classic", label: "Classic tabs", detail: "Tab bars above tiled cards. Floating multi-app cards keep their window borders."},
                            {value: "frame", label: "Card frame", detail: "A shared outline and a small Flip control · Experimental"}
                        ]
                        value: root.snapshotData.appearance || ""
                        enabled: root.caps.appearance === true
                        opacity: enabled ? 1 : 0.45
                        Accessible.role: Accessible.Grouping
                        Accessible.name: accessibleName
                        Accessible.description: "Left and right choose, Enter applies"
                        onChanged: value => root.service.run("appearance", {style: value})
                    }
                    Label {
                        text: (appearanceGroup.options.find(o => o.value === appearanceGroup.value) || {detail: ""}).detail
                        visible: text.length > 0
                        Layout.fillWidth: true
                        font.pixelSize: Style.font.bodySmall
                    }

                    Ui.PanelSectionHeader { text: "App spacing"; visible: root.caps.spacing === true; foreground: Commons.Color.popups.text; Layout.fillWidth: true; Layout.topMargin: Style.space(4) }
                    Ui.ButtonGroup {
                        id: spacingGroup
                        readonly property string accessibleName: root.groupName("App spacing", options, value)
                        visible: root.caps.spacing === true
                        options: [
                            {value: -1, label: "Desktop", detail: "Card apps keep the gaps between ordinary tiled windows."},
                            {value: 12, label: "Compact", detail: "12 px between card apps. Desktop gaps stay unchanged."}
                        ]
                        value: String(root.snapshotData.card_gap)
                        Accessible.role: Accessible.Grouping
                        Accessible.name: accessibleName
                        Accessible.description: "Left and right choose, Enter applies"
                        onChanged: value => root.service.run("spacing", {gap: Number(value)})
                    }
                    Label {
                        text: (spacingGroup.options.find(o => String(o.value) === spacingGroup.value) || {detail: ""}).detail
                        visible: spacingGroup.visible && text.length > 0
                        Layout.fillWidth: true
                        font.pixelSize: Style.font.bodySmall
                    }

                    Ui.PanelSectionHeader { text: "Fullscreen divider"; visible: root.caps.divider === true; foreground: Commons.Color.popups.text; Layout.fillWidth: true; Layout.topMargin: Style.space(4) }
                    Ui.ButtonGroup {
                        id: dividerGroup
                        readonly property string accessibleName: root.groupName("Fullscreen divider", options, value)
                        visible: root.caps.divider === true
                        options: [{value: 0, label: "Off"}, {value: 1, label: "1 px"}, {value: 2, label: "2 px"}, {value: 3, label: "3 px"}, {value: 4, label: "4 px"}]
                        value: String(root.snapshotData.fullscreen_divider)
                        Accessible.role: Accessible.Grouping
                        Accessible.name: accessibleName
                        Accessible.description: "Left and right choose, Enter applies"
                        onChanged: value => root.service.run("divider", {width: Number(value)})
                    }
                    Label {
                        visible: dividerGroup.visible
                        text: "The line between the apps of a fullscreen card, in " +
                              (root.snapshotData.divider_color ? root.snapshotData.divider_color : "your accent color") + ". Off lets the apps touch."
                        Layout.fillWidth: true
                        font.pixelSize: Style.font.bodySmall
                    }

                    Ui.PanelSeparator { Layout.fillWidth: true; Layout.topMargin: Style.space(4); visible: accentToggle.visible || nearbyToggle.visible }
                    Ui.Toggle {
                        id: accentToggle
                        Layout.fillWidth: true
                        visible: root.caps.accent === true
                        label: "Accent ring"
                        description: "A ring in your theme’s accent color around every card · Follows theme changes"
                        checked: root.snapshotData.accent_ring === true
                        foreground: Commons.Color.popups.text
                        Accessible.role: Accessible.CheckBox
                        Accessible.checkable: true
                        Accessible.checked: checked
                        Accessible.name: label
                        Accessible.description: description
                        Accessible.onPressAction: clicked()
                        Accessible.onToggleAction: clicked()
                        onClicked: root.service.run("accent", {enabled: !checked, color: root.service.accentHex})
                    }
                    Ui.Toggle {
                        id: nearbyToggle
                        Layout.fillWidth: true
                        visible: root.caps.nearby === true
                        label: "Card keys beside a card"
                        description: "From a window in no card, such as a terminal, flip, faces, unfold and peek act on the one card on that workspace"
                        // On unless Hyprflip says otherwise; it is the core's default.
                    checked: root.snapshotData.nearby_card !== false
                        foreground: Commons.Color.popups.text
                        Accessible.role: Accessible.CheckBox
                        Accessible.checkable: true
                        Accessible.checked: checked
                        Accessible.name: label
                        Accessible.description: description
                        Accessible.onPressAction: clicked()
                        Accessible.onToggleAction: clicked()
                        onClicked: root.service.run("nearby", {enabled: !checked})
                    }
                    Label {
                        visible: root.caps.drag_to_add === true
                        text: "To add an app, drag its window onto the card’s Drop to add target. Escape cancels the add."
                        Layout.fillWidth: true
                        Layout.topMargin: Style.space(4)
                        font.pixelSize: Style.font.bodySmall
                    }
                }
                ShortcutsContent {
                    id: shortcutSettings
                    objectName: "shortcutSettings"
                    visible: root.pageVisible && root.page === "shortcuts"
                    Layout.fillWidth: true
                    service: root.service
                    pointerGate: gate
                    onRevealEditor: item => root.showItem(item)
                }

                ColumnLayout {
                    visible: root.pageVisible && root.page === "edit" && root.card !== null
                    Layout.fillWidth: true
                    spacing: Style.space(12)
                    Label { text: root.card ? root.card.name : ""; font.bold: true; Layout.fillWidth: true }
                    Repeater {
                        model: root.card ? root.card.faces : []
                        ColumnLayout {
                            id: face
                            required property var modelData
                            readonly property bool showing: root.card && (root.card.active === modelData.index || root.card.unfolded)
                            readonly property bool full: modelData.panes.length >= root.caps.max_panes
                            Layout.fillWidth: true
                            spacing: Style.space(5)
                            Ui.PanelSeparator { Layout.fillWidth: true }
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.space(6)
                                Label { text: root.faceName(face.modelData.index); font.bold: true; Layout.fillWidth: true }
                                Item {
                                    Layout.preferredWidth: Style.space(28)
                                    Layout.preferredHeight: Style.space(20)
                                    Accessible.role: Accessible.StaticText
                                    Accessible.name: face.modelData.panes.length + " apps " + (face.modelData.axis === "vertical" ? "stacked" : "beside each other")
                                    Repeater {
                                        model: face.modelData.panes.length
                                        Rectangle {
                                            required property int index
                                            readonly property bool stacked: face.modelData.axis === "vertical"
                                            readonly property int count: face.modelData.panes.length
                                            x: stacked ? 0 : index * (parent.width + Style.space(2)) / count
                                            y: stacked ? index * (parent.height + Style.space(2)) / count : 0
                                            width: stacked ? parent.width : (parent.width - Style.space(2) * (count - 1)) / count
                                            height: stacked ? (parent.height - Style.space(2) * (count - 1)) / count : parent.height
                                            color: "transparent"
                                            border.color: face.showing ? Commons.Color.accent : Commons.Color.popups.text
                                            border.width: 1
                                            radius: Math.min(Style.cornerRadius, Style.space(2))
                                        }
                                    }
                                }
                                Label { text: face.modelData.panes.length + " / " + (root.caps.max_panes || 3) + " apps" }
                                Label { text: "Showing"; visible: face.showing; color: Commons.Color.accent }
                            }
                            Repeater {
                                model: face.modelData.panes
                                ColumnLayout {
                                    id: paneBlock
                                    required property var modelData
                                    required property int index
                                    readonly property bool chosen: root.paneAddress === modelData.address
                                    readonly property bool open: face.showing && chosen
                                    readonly property string appName: modelData.label
                                    readonly property int otherFace: root.nextFace(face.modelData.index)
                                    readonly property bool otherFull: !!root.card && root.card.faces[otherFace].panes.length >= root.caps.max_panes
                                    Layout.fillWidth: true
                                    spacing: Style.space(4)
                                    ChoiceRow {
                                        // Lets Delete or x remove the app whose row has focus.
                                        readonly property string paneAddress: paneBlock.modelData.address
                                        Layout.fillWidth: true
                                        title: paneBlock.modelData.label
                                        showIcon: true
                                        appIcon: paneBlock.modelData.icon || ""
                                        detail: [paneBlock.modelData.title !== paneBlock.modelData.label ? paneBlock.modelData.title : "",
                                                 face.showing ? "" : "Select to show " + root.faceName(face.modelData.index)].filter(Boolean).join(" · ")
                                        selected: paneBlock.chosen
                                        pointerGate: gate
                                        onActivated: root.choosePane(face.modelData.index, paneBlock.modelData.address, face.showing)
                                    }
                                    // The selected app's own actions sit under its row.
                                    Flow {
                                        visible: paneBlock.open
                                        Layout.fillWidth: true
                                        Layout.leftMargin: Style.space(38)
                                        spacing: Style.space(4)
                                        Action {
                                            text: "Replace…"
                                            accessibleName: "Replace " + paneBlock.appName
                                            enabled: !!root.caps.replace
                                            tooltipText: root.caps.replace ? "Swap in another open app" : "Update Hyprflip to replace apps"
                                            onClicked: root.edit("replace", face.modelData.index, root.paneAddress)
                                        }
                                        Action {
                                            text: root.manyFaces ? "Move to " + root.faceName(paneBlock.otherFace) : "Other side"
                                            accessibleName: "Move " + paneBlock.appName + " to " + root.faceName(paneBlock.otherFace)
                                            enabled: face.modelData.panes.length > 1 && !paneBlock.otherFull
                                            tooltipText: face.modelData.panes.length <= 1 ? "The only app on " + root.faceName(face.modelData.index) + " stays"
                                                : paneBlock.otherFull ? root.faceName(paneBlock.otherFace) + " is full" : ""
                                            onClicked: root.edit("other_side", face.modelData.index, root.paneAddress)
                                        }
                                        // The only app of a third or fourth face leaves with its face.
                                        Action {
                                            text: "Remove"
                                            accessibleName: "Remove " + paneBlock.appName
                                            enabled: face.modelData.panes.length > 1 || root.manyFaces
                                            tooltipText: face.modelData.panes.length > 1 ? "The app stays open" : root.manyFaces ? "Removes this face · The app stays open"
                                                : "The only app on " + root.faceName(face.modelData.index) + " stays · Ungroup the card instead"
                                            onClicked: root.edit("remove", face.modelData.index, root.paneAddress)
                                        }
                                        Action {
                                            text: "Earlier"
                                            accessibleName: "Move " + paneBlock.appName + " earlier"
                                            visible: face.modelData.panes.length > 1
                                            enabled: paneBlock.index > 0
                                            tooltipText: "Ctrl+Up"
                                            onClicked: root.edit("previous", face.modelData.index, root.paneAddress)
                                        }
                                        Action {
                                            text: "Later"
                                            accessibleName: "Move " + paneBlock.appName + " later"
                                            visible: face.modelData.panes.length > 1
                                            enabled: paneBlock.index < face.modelData.panes.length - 1
                                            tooltipText: "Ctrl+Down"
                                            onClicked: root.edit("next", face.modelData.index, root.paneAddress)
                                        }
                                    }
                                }
                            }
                            // Actions for the whole face.
                            Flow {
                                Layout.fillWidth: true
                                Layout.topMargin: Style.space(4)
                                spacing: Style.space(6)
                                visible: face.showing
                                Action {
                                    text: face.full ? "Side full" : "Add app…"
                                    accessibleName: face.full ? root.faceName(face.modelData.index) + " is full" : "Add an app to " + root.faceName(face.modelData.index)
                                    enabled: !face.full
                                    onClicked: root.edit("add", face.modelData.index, null)
                                }
                                Ui.ButtonGroup {
                                    readonly property string accessibleName: root.groupName(root.faceName(face.modelData.index) + " layout", options, value)
                                    visible: face.modelData.panes.length > 1
                                    options: [{value: "horizontal", label: "Beside"}, {value: "vertical", label: "Stacked"}]
                                    value: face.modelData.axis || "horizontal"
                                    enabled: root.caps.layout === true
                                    opacity: enabled ? 1 : 0.45
                                    Accessible.role: Accessible.Grouping
                                    Accessible.name: accessibleName
                                    Accessible.description: "Left and right choose, Enter applies"
                                    onChanged: value => { if (value !== face.modelData.axis) root.edit(value, face.modelData.index, null) }
                                }
                                Action {
                                    text: "Equal sizes"
                                    accessibleName: "Equal sizes on " + root.faceName(face.modelData.index)
                                    visible: face.modelData.panes.length > 1
                                    enabled: root.caps.layout === true
                                    onClicked: root.edit("balance", face.modelData.index, null)
                                }
                            }
                            Action { text: "Show and edit " + root.faceName(face.modelData.index); visible: !face.showing; onClicked: root.edit("", face.modelData.index, null) }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: "Select an app for its actions. Removed apps stay open."
                        visible: root.paneAddress === ""
                        font.pixelSize: Style.font.bodySmall
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Style.space(6)
                        Action { text: "Add as new face…"; visible: root.card && root.card.kind === "container" && root.card.faces.length < (root.caps.faces || 2); enabled: !(root.card && root.card.fullscreen); tooltipText: root.card && root.card.fullscreen ? "Leave fullscreen first" : root.card ? "Becomes " + root.faceName(root.card.faces.length) + " · Choose an open app" : ""; onClicked: root.edit("add_face", root.card.active, null) }
                        Action { text: "Save as…"; onClicked: root.edit("save", root.card.active, null) }
                        Action { text: "Manage saved…"; onClicked: root.edit("manage", root.card.active, null) }
                        Action { text: "Reopen missing apps"; visible: !!root.caps.repair && root.card && root.card.saved_names.length > 0; enabled: !(root.card && root.card.fullscreen); tooltipText: root.card && root.card.fullscreen ? "Leave fullscreen first" : ""; onClicked: root.edit("repair", root.card.active, null) }
                        Action {
                            id: ungroupButton
                            text: "Ungroup card…"
                            visible: root.card && root.card.kind === "container" && !root.confirmUngroup
                            enabled: !(root.card && root.card.fullscreen)
                            tooltipText: root.card && root.card.fullscreen ? "Leave fullscreen first" : "Ends the card · Its apps stay open"
                            onClicked: root.ungroupKey = root.card.key
                        }
                    }
                    // Ungrouping ends the card, so it asks once, in place.
                    ColumnLayout {
                        visible: root.confirmUngroup
                        Layout.fillWidth: true
                        spacing: Style.space(6)
                        Label {
                            Layout.fillWidth: true
                            text: root.card ? "Ungroup “" + root.card.name + "”? Its apps stay open as separate windows." : ""
                            font.bold: true
                        }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.space(6)
                            Action {
                                text: "Ungroup"
                                accessibleName: root.card ? "Ungroup “" + root.card.name + "”" : "Ungroup"
                                onClicked: { root.ungroupKey = ""; root.edit("unpair", root.card.active, null) }
                            }
                            Action { id: keepCard; text: "Keep card"; onClicked: { root.ungroupKey = ""; ungroupButton.forceActiveFocus() } }
                        }
                    }
                    Label { Layout.fillWidth: true; text: "Live edits do not overwrite your saved arrangement. Use Manage saved to update it."; font.pixelSize: Style.font.bodySmall }
                }

                ColumnLayout {
                    visible: root.pageVisible && root.snapshotData.available && root.page === "motion"
                    Layout.fillWidth: true
                    spacing: Style.space(8)
                    Label { text: "Choose a transition. Preview turns the card over and back without changing your preference."; Layout.fillWidth: true }
                    Label { text: "Animations are disabled in Hyprland or Hyprflip. Your choice is saved for when they are enabled."; Layout.fillWidth: true; visible: root.snapshotData.motion_enabled === false; color: Commons.Color.accent }
                    Repeater {
                        model: root.snapshotData.transition_modes || []
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Style.space(6)
                            ChoiceRow {
                                Layout.fillWidth: true
                                title: modelData.label + (root.snapshotData.transition === modelData.value ? " · Current" : "")
                                detail: modelData.detail
                                checkable: true
                                selected: root.snapshotData.transition === modelData.value
                                pointerGate: gate
                                onActivated: root.service.run("transition", {mode: modelData.value})
                            }
                            Action {
                                text: "Preview"
                                accessibleName: "Preview " + modelData.label
                                visible: modelData.value !== "instant"
                                enabled: root.card && !root.card.unfolded && root.snapshotData.motion_enabled !== false
                                tooltipText: !root.card ? "Select a card to preview on" : root.card.unfolded ? "Fold the card first"
                                    : root.snapshotData.motion_enabled === false ? "Animations are off" : "Turn the card over and back"
                                onClicked: root.service.cardAction("preview", {mode: modelData.value})
                            }
                        }
                    }
                    Ui.PanelSeparator { Layout.fillWidth: true }
                    Ui.PanelSectionHeader { text: "Speed"; foreground: Commons.Color.popups.text; Layout.fillWidth: true }
                    Ui.ButtonGroup {
                        id: speedGroup
                        readonly property string accessibleName: root.groupName("Speed", options, value)
                        options: [{value: 280, label: "Fast", tooltip: "280 ms"}, {value: 420, label: "Normal", tooltip: "420 ms"}, {value: 600, label: "Relaxed", tooltip: "600 ms"}]
                        value: String(root.snapshotData.duration_ms)
                        Accessible.role: Accessible.Grouping
                        Accessible.name: accessibleName
                        Accessible.description: "Left and right choose, Enter applies"
                        onChanged: value => root.service.run("duration", {duration_ms: Number(value)})
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(6)
                        Label {
                            Layout.fillWidth: true
                            text: root.snapshotData.duration_ms === undefined ? "" : root.snapshotData.duration_ms + " ms" + (speedGroup.selectedOptionIndex() < 0 ? " · Exact time" : "")
                            font.pixelSize: Style.font.bodySmall
                        }
                        Action { text: root.advanced ? "Hide exact time" : "Exact time…"; onClicked: root.advanced = !root.advanced }
                    }
                    RowLayout {
                        visible: root.advanced
                        spacing: Style.space(6)
                        KeyField {
                            id: duration
                            Layout.fillWidth: true
                            text: String(root.snapshotData.duration_ms === undefined ? 420 : root.snapshotData.duration_ms)
                            validator: IntValidator { bottom: 0; top: 2000 }
                            inputMethodHints: Qt.ImhDigitsOnly
                            Accessible.name: "Transition duration in milliseconds, 0 to 2000"
                            onAccepted: if (acceptableInput) root.service.run("duration", {duration_ms: Number(text)})
                        }
                        Label { text: "ms" }
                        Action { text: "Apply"; enabled: duration.acceptableInput; onClicked: root.service.run("duration", {duration_ms: Number(duration.text)}) }
                    }
                }
            }
        }
    }
}
