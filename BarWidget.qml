import QtQuick
import qs.Ui as Ui

Ui.BarWidget {
    id: root
    moduleName: "io.github.nocstah.omacards"
    readonly property var service: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
    readonly property bool opened: panelLoader.item ? panelLoader.item.opened : false
    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing : false
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    function injectPanel() {
        const panel = panelLoader.item
        if (!panel) return
        panel.bar = root.bar
        panel.anchorItem = button
        panel.hostWidget = root
        panel.service = root.service
    }
    function open() { if (service) service.prepareOpen(root) }
    function reveal() { if (panelLoader.item) panelLoader.item.reveal() }
    function dismiss() { if (panelLoader.item) panelLoader.item.controller.hide() }
    function close() { if (service) service.dismiss(); else dismiss() }
    function closeForPopoutSwitch() { close() }
    onBarChanged: injectPanel()
    onServiceChanged: injectPanel()
    Loader {
        id: panelLoader
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: { root.injectPanel(); Qt.callLater(root.injectPanel) }
    }
    Ui.BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "󰘸" // Material Design cards-outline, from Omarchy's Nerd Font.
        active: root.opened || (root.service && root.service.busy)
        tooltipText: root.service && root.service.busy ? "OmaCards · Opening card… Click for progress" : "OmaCards · Open, edit and flip cards"
        onPressed: root.opened ? root.close() : root.open()
    }
}
