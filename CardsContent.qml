import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as Controls
import qs.Commons
import qs.Ui as Ui

FocusScope {
    id: root
    required property var service
    signal closeRequested()
    readonly property var snapshotData: service ? service.snapshot : ({})
    readonly property var card: service ? service.currentCard : null
    readonly property bool busy: service ? service.busy : false
    readonly property var question: service ? service.question : null
    readonly property string page: service ? service.page : "cards"
    property string paneAddress: ""
    property string paneCardKey: ""
    property string filter: ""
    property int cursor: 0
    property int choiceCursor: 0
    property bool advanced: false
    readonly property bool recordingShortcut: shortcutSettings.recording
    function stopRecording() { shortcutSettings.recording = false }
    readonly property var savedRows: (snapshotData.saved || []).filter(row => (row.name + " " + row.description).toLowerCase().includes(filter.toLowerCase()))
    readonly property bool hasSavedCards: (snapshotData.saved || []).length > 0
    readonly property bool hasFrontApp: !!(service && service.context && service.context.anchor)
    readonly property string frontAppName: hasFrontApp ? (service.context.anchor_label || "Selected app") : ""
    implicitWidth: Style.space(440)
    implicitHeight: Math.min(column.implicitHeight, Style.space(660))
    function focusEntry() {
        if (question && question.mode === "input") nameInput.forceActiveFocus()
        else if (question) choices.forceActiveFocus()
        else if (page === "cards" && !busy && search.visible) search.forceActiveFocus()
        else if (page === "cards" && !busy && chooseBack.visible && chooseBack.enabled) chooseBack.forceActiveFocus()
        else root.forceActiveFocus()
    }
    function back() {
        if (question) service.cancel()
        else if (page === "motion" || page === "shortcuts") { service.page = "settings"; focusEntry() }
        else if (page !== "cards") { service.page = "cards"; paneAddress = ""; focusEntry() }
        else closeRequested()
    }
    function edit(intent, face, pane) { paneAddress = ""; service.edit(intent, face, pane) }
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
    Keys.onEscapePressed: back()
    Connections {
        target: root.Window.window
        function onActiveFocusItemChanged() { root.showItem(root.Window.window.activeFocusItem) }
    }
    Connections {
        target: root.service
        function onQuestionChanged() {
            root.choiceCursor = 0
            nameInput.text = ""
            scroller.contentY = 0
            Qt.callLater(root.focusEntry)
        }
        function onPageChanged() { scroller.contentY = 0; Qt.callLater(root.focusEntry) }
        function onCurrentCardChanged() {
            if (!root.card || root.card.key !== root.paneCardKey || !root.card.faces.some(f => f.panes.some(p => p.address === root.paneAddress))) root.paneAddress = ""
        }
    }

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
                Label {
                    text: root.question ? "Choose for your card" : (root.page === "settings" ? "Settings" : root.page === "shortcuts" ? "Keyboard shortcuts" : root.page === "motion" ? "Motion" : root.page === "edit" ? "Edit card" : "Cards")
                    font.pixelSize: Style.font.heading
                    font.bold: true
                    Layout.fillWidth: true
                }
                Action { text: "Back"; visible: !root.busy && root.page !== "cards"; onClicked: root.back() }
                Action { text: "Settings"; visible: !root.busy && !root.question && root.page === "cards" && root.snapshotData.available; onClicked: root.service.page = "settings" }
                Action { text: "Close"; onClicked: root.closeRequested() }
            }
            Label {
                Layout.fillWidth: true
                text: root.service ? root.service.notice : "Starting OmaCards…"
                visible: text.length > 0
                color: root.service && root.service.failed ? Color.urgent : Color.popups.text
            }
            RowLayout {
                visible: !root.busy && (!root.snapshotData.available || (root.service && root.service.failed))
                Action { text: root.service && root.service.refreshing ? "Refreshing…" : "Refresh Cards"; enabled: root.service && !root.service.refreshing; onClicked: root.service.refresh(true) }
            }

            // Every backend question is displayed here, keeping a single UI flow.
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.question !== null
                Label { Layout.fillWidth: true; text: root.question ? root.question.prompt : ""; font.bold: true }
                Ui.TextField {
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
                visible: root.busy && !root.question
                Layout.fillWidth: true
                Label { text: root.service && root.service.cancelled ? "Cancelling…" : root.service && root.service.opening ? "Opening “" + root.service.opening.name + "”…" : "Working on your card…"; Layout.fillWidth: true; font.bold: true }
                Label { text: root.service && root.service.opening ? "Waiting for " + root.service.opening.labels.join(", ") : ""; visible: text.length > 0; Layout.fillWidth: true }
                Label { text: "Apps that have opened will stay open if you cancel."; Layout.fillWidth: true; visible: root.service && root.service.opening !== null }
                Action { text: "Cancel"; enabled: root.service && !root.service.cancelled; onClicked: root.service.cancel() }
            }

            ColumnLayout {
                visible: !root.busy && !root.question && root.snapshotData.available && root.page === "cards"
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
                            selected: root.card && modelData.key === root.card.key
                            onActivated: root.service.selectedKey = modelData.key
                        }
                    }
                }
                ColumnLayout {
                    visible: root.card !== null
                    Layout.fillWidth: true
                    spacing: Style.space(8)
                    Label { text: root.card ? root.card.name : ""; Layout.fillWidth: true; font.bold: true; font.pixelSize: Style.font.title }
                    Label { text: root.card ? "Workspace " + root.card.workspace_label + (root.card.unfolded ? " · Both sides visible" : "") + (root.card.floating ? " · Floating" : "") : ""; font.pixelSize: Style.font.bodySmall }
                    Repeater {
                        model: root.card ? root.card.faces : []
                        RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Label { text: modelData.index === 0 ? "Front" : "Back"; Layout.preferredWidth: Style.space(48); font.bold: root.card && root.card.active === modelData.index }
                            Label { text: modelData.panes.map(p => p.label).join(" · "); Layout.fillWidth: true }
                            Label { text: "Showing"; visible: root.card && (root.card.active === modelData.index || root.card.unfolded); color: Color.accent; font.pixelSize: Style.font.bodySmall }
                        }
                    }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Style.space(6)
                        Action { text: "Flip"; enabled: root.card && !root.card.unfolded; onClicked: root.service.cardAction("flip") }
                        Action { text: root.card && root.card.unfolded ? "Fold" : "Unfold"; visible: root.card && root.card.kind === "container"; onClicked: root.service.cardAction("unfold") }
                        Action { text: root.card && root.card.floating ? "Tile card" : "Float card"; visible: !!root.snapshotData.capabilities.floating; onClicked: root.service.cardAction("floating") }
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
                    Label { text: root.snapshotData.library_error || ""; visible: text.length > 0; color: Color.urgent; Layout.fillWidth: true }
                    Ui.TextField {
                        id: search
                        Layout.fillWidth: true
                        visible: root.hasSavedCards
                        placeholderText: "Search saved cards…"
                        Accessible.name: "Search saved cards"
                        text: root.filter
                        onTextEdited: { root.filter = text; root.cursor = 0 }
                        Keys.onUpPressed: root.cursor = Math.max(0, root.cursor - 1)
                        Keys.onDownPressed: root.cursor = Math.min(root.savedRows.length - 1, root.cursor + 1)
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
                                ChoiceRow {
                                    Layout.fillWidth: true
                                    title: modelData.name
                                    detail: modelData.detail + "\n" + modelData.description
                                    selected: search.activeFocus && root.cursor === index
                                    onActivated: root.service.savedAction("open", modelData)
                                }
                                Action { text: "Manage"; tooltipText: "Rename, duplicate or delete “" + modelData.name + "”"; onClicked: root.service.savedAction("manage", modelData) }
                            }
                        }
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.filter ? "No saved cards match your search." : "Save a card to reopen its apps and layout later."
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
                        visible: root.hasFrontApp && !!root.snapshotData.capabilities.containers
                        Layout.fillWidth: true
                    }
                    Label {
                        text: !root.snapshotData.capabilities.containers
                            ? "Update Hyprflip and its helper to create multi-app cards on dwindle."
                            : root.hasFrontApp
                                ? "Choose another open app for the back. Apps are resized to fit the card automatically. Flip to switch sides."
                                : "Select the app you want on the front, then reopen Cards to choose an app for the back."
                        Layout.fillWidth: true
                    }
                    Action {
                        id: chooseBack
                        text: "Choose app for back…"
                        visible: root.hasFrontApp && !!root.snapshotData.capabilities.containers
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
                visible: !root.busy && !root.question && root.page === "settings"
                Layout.fillWidth: true
                spacing: Style.space(8)
                Label { text: "Preferences apply to all cards and are kept after a restart."; Layout.fillWidth: true }
                Label { text: "Card appearance"; Layout.fillWidth: true; font.weight: Font.DemiBold }
                Label {
                    visible: !root.snapshotData.capabilities.appearance
                    text: "Update Hyprflip to choose the card appearance."
                    Layout.fillWidth: true
                }
                Repeater {
                    model: [
                        {value: "classic", label: "Classic tabs", detail: "Tab bars above tiled cards. Floating multi-app cards keep their window borders."},
                        {value: "frame", label: "Card frame", detail: "Shared outline and a small Flip control · Experimental"}
                    ]
                    delegate: ChoiceRow {
                        required property var modelData
                        Layout.fillWidth: true
                        title: modelData.label
                        detail: modelData.detail
                        selected: root.snapshotData.appearance === modelData.value
                        enabled: root.snapshotData.capabilities.appearance === true
                        onActivated: root.service.run("appearance", {style: modelData.value})
                    }
                }
                Label {
                    text: "App spacing"
                    visible: root.snapshotData.capabilities.spacing === true
                    Layout.fillWidth: true
                    font.weight: Font.DemiBold
                }
                Repeater {
                    model: root.snapshotData.capabilities.spacing === true ? [
                        {value: -1, label: "Desktop spacing", detail: "Match the gaps between ordinary tiled windows"},
                        {value: 12, label: "Compact spacing", detail: "12 px between card apps · Leaves desktop gaps unchanged"}
                    ] : []
                    delegate: ChoiceRow {
                        required property var modelData
                        Layout.fillWidth: true
                        title: modelData.label
                        detail: modelData.detail
                        selected: root.snapshotData.card_gap === modelData.value
                        onActivated: root.service.run("spacing", {gap: modelData.value})
                    }
                }
                Label {
                    visible: root.snapshotData.capabilities.drag_to_add === true
                    text: "To add an app, drag its window onto the card’s Drop to add target. Escape cancels the add."
                    Layout.fillWidth: true
                }
                ChoiceRow {
                    Layout.fillWidth: true
                    title: "Motion"
                    detail: "Transition, speed and preview · Instant turns off motion"
                    onActivated: root.service.page = "motion"
                }
                ChoiceRow {
                    Layout.fillWidth: true
                    title: "Keyboard shortcuts"
                    detail: "Change a shortcut or restore its default"
                    onActivated: root.service.page = "shortcuts"
                }
            }
            ShortcutsContent {
                id: shortcutSettings
                objectName: "shortcutSettings"
                visible: !root.busy && !root.question && root.page === "shortcuts"
                Layout.fillWidth: true
                service: root.service
                onRevealEditor: item => root.showItem(item)
            }

            ColumnLayout {
                visible: !root.busy && !root.question && root.page === "edit" && root.card !== null
                Layout.fillWidth: true
                spacing: Style.space(12)
                Label { text: root.card ? root.card.name : ""; font.bold: true; Layout.fillWidth: true }
                Repeater {
                    model: root.card ? root.card.faces : []
                    ColumnLayout {
                        id: face
                        required property var modelData
                        readonly property bool showing: root.card && (root.card.active === modelData.index || root.card.unfolded)
                        Layout.fillWidth: true
                        spacing: Style.space(5)
                        Ui.PanelSeparator { Layout.fillWidth: true }
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: face.modelData.index === 0 ? "Front" : "Back"; font.bold: true; Layout.fillWidth: true }
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
                                        border.color: face.showing ? Color.accent : Color.popups.text
                                        border.width: 1
                                        radius: Math.min(Style.cornerRadius, Style.space(2))
                                    }
                                }
                            }
                            Label { text: face.modelData.panes.length + " / " + (root.snapshotData.capabilities.max_panes || 3) + " apps" }
                            Label { text: "Showing"; visible: face.showing; color: Color.accent }
                        }
                        Repeater {
                            model: face.modelData.panes
                            ChoiceRow {
                                required property var modelData
                                Layout.fillWidth: true
                                title: modelData.label
                                showIcon: true
                                appIcon: modelData.icon || ""
                                detail: modelData.title !== modelData.label ? modelData.title : ""
                                selected: root.paneAddress === modelData.address
                                enabled: face.showing
                                onActivated: { root.paneCardKey = root.card.key; root.paneAddress = root.paneAddress === modelData.address ? "" : modelData.address }
                            }
                        }
                        Flow {
                            visible: face.showing && face.modelData.panes.some(p => p.address === root.paneAddress)
                            Layout.fillWidth: true
                            spacing: Style.space(4)
                            Action { text: "Replace…"; enabled: !!root.snapshotData.capabilities.replace; onClicked: root.edit("replace", face.modelData.index, root.paneAddress) }
                            Action { text: "Other side"; enabled: face.modelData.panes.length > 1 && root.card && root.card.faces[1 - face.modelData.index].panes.length < root.snapshotData.capabilities.max_panes; onClicked: root.edit("other_side", face.modelData.index, root.paneAddress) }
                            Action { text: face.modelData.panes.length > 1 ? "Remove" : "Ungroup card"; tooltipText: "Keep all apps open"; onClicked: root.edit(face.modelData.panes.length > 1 ? "remove" : "unpair", face.modelData.index, root.paneAddress) }
                            Action { text: "Earlier"; visible: face.modelData.panes.length > 1; enabled: face.modelData.panes.findIndex(p => p.address === root.paneAddress) > 0; onClicked: root.edit("previous", face.modelData.index, root.paneAddress) }
                            Action { text: "Later"; visible: face.modelData.panes.length > 1; enabled: face.modelData.panes.findIndex(p => p.address === root.paneAddress) < face.modelData.panes.length - 1; onClicked: root.edit("next", face.modelData.index, root.paneAddress) }
                        }
                        Label { text: "Removal keeps the app open."; visible: face.showing && face.modelData.panes.some(p => p.address === root.paneAddress); font.pixelSize: Style.font.bodySmall }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.space(4)
                            visible: face.showing
                            Action { text: face.modelData.panes.length >= root.snapshotData.capabilities.max_panes ? "Side full" : "Add app…"; enabled: face.modelData.panes.length < root.snapshotData.capabilities.max_panes; onClicked: root.edit("add", face.modelData.index, null) }
                            Action { text: "Beside"; visible: face.modelData.panes.length > 1; enabled: root.snapshotData.capabilities.layout; selected: face.modelData.axis === "horizontal"; onClicked: root.edit("horizontal", face.modelData.index, null) }
                            Action { text: "Stacked"; visible: face.modelData.panes.length > 1; enabled: root.snapshotData.capabilities.layout; selected: face.modelData.axis === "vertical"; onClicked: root.edit("vertical", face.modelData.index, null) }
                            Action { text: "Equal sizes"; visible: face.modelData.panes.length > 1; enabled: root.snapshotData.capabilities.layout; onClicked: root.edit("balance", face.modelData.index, null) }
                        }
                        Action { text: "Show and edit " + (face.modelData.index === 0 ? "Front" : "Back"); visible: !face.showing; onClicked: root.edit("", face.modelData.index, null) }
                    }
                }
                Ui.PanelSeparator { Layout.fillWidth: true }
                Flow {
                    Layout.fillWidth: true
                    spacing: Style.space(6)
                    Action { text: "Save as…"; onClicked: root.edit("save", root.card.active, null) }
                    Action { text: "Manage saved…"; onClicked: root.edit("manage", root.card.active, null) }
                    Action { text: "Reopen missing apps"; visible: !!root.snapshotData.capabilities.repair && root.card && root.card.saved_names.length > 0; onClicked: root.edit("repair", root.card.active, null) }
                }
                Label { Layout.fillWidth: true; text: "Live edits do not overwrite your saved arrangement. Use Manage saved to update it."; font.pixelSize: Style.font.bodySmall }
            }

            ColumnLayout {
                visible: !root.busy && !root.question && root.snapshotData.available && root.page === "motion"
                Layout.fillWidth: true
                spacing: Style.space(8)
                Label { text: "Choose a transition. Preview turns the card over and back without changing your preference."; Layout.fillWidth: true }
                Label { text: "Animations are disabled in Hyprland or Hyprflip. Your choice is saved for when they are enabled."; Layout.fillWidth: true; visible: root.snapshotData.motion_enabled === false; color: Color.accent }
                Repeater {
                    model: root.snapshotData.transition_modes || []
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        ChoiceRow {
                            Layout.fillWidth: true
                            title: modelData.label + (root.snapshotData.transition === modelData.value ? " · Current" : "")
                            detail: modelData.detail
                            selected: root.snapshotData.transition === modelData.value
                            onActivated: root.service.run("transition", {mode: modelData.value})
                        }
                        Action { text: "Preview"; visible: modelData.value !== "instant"; enabled: root.card && !root.card.unfolded && root.snapshotData.motion_enabled !== false; onClicked: root.service.cardAction("preview", {mode: modelData.value}) }
                    }
                }
                Ui.PanelSeparator { Layout.fillWidth: true }
                Label { text: "Speed"; font.bold: true }
                Flow {
                    Layout.fillWidth: true
                    spacing: Style.space(6)
                    Repeater {
                        model: [{label: "Fast", ms: 280}, {label: "Normal", ms: 420}, {label: "Relaxed", ms: 600}]
                        Action {
                            required property var modelData
                            text: modelData.label
                            selected: root.snapshotData.duration_ms === modelData.ms
                            tooltipText: modelData.ms + " ms"
                            onClicked: root.service.run("duration", {duration_ms: modelData.ms})
                        }
                    }
                    Action { text: root.advanced ? "Less" : "Exact time…"; onClicked: root.advanced = !root.advanced }
                }
                RowLayout {
                    visible: root.advanced
                    Ui.TextField {
                        id: duration
                        Layout.fillWidth: true
                        text: String(root.snapshotData.duration_ms === undefined ? 420 : root.snapshotData.duration_ms)
                        validator: IntValidator { bottom: 0; top: 2000 }
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
