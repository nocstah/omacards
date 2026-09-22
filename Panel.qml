import QtQuick
import qs.Ui as Ui
import qs.Commons

Ui.Panel {
    id: root
    moduleName: "io.github.nocstah.omacards"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null
    property var service: null
    function reveal() { controller.show(); Qt.callLater(content.focusEntry) }
    function close() { if (service) service.dismiss(); else controller.hide() }
    Ui.KeyboardPanel {
        id: popup
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: content
        contentWidth: popup.fittedContentWidth(Style.space(440))
        contentHeight: popup.fittedContentHeight(content.implicitHeight, Style.space(680))
        CardsContent {
            id: content
            anchors.fill: parent
            service: root.service
            onCloseRequested: root.close()
        }
    }
}
