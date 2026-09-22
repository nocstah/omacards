import QtQuick
import Quickshell
import qs.Commons
import qs.Ui as Ui

Ui.CursorSurface {
    id: root
    property string title: ""
    property string detail: ""
    property bool selected: false
    property bool showIcon: false
    property string appIcon: ""
    signal activated()
    implicitHeight: labels.implicitHeight + Style.space(16)
    activeFocusOnTab: true
    current: selected
    hasCursor: mouse.containsMouse || activeFocus
    Accessible.role: Accessible.Button
    Accessible.name: title + (detail ? ", " + detail : "")
    Accessible.onPressAction: if (enabled) root.activated()
    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()
    Keys.onSpacePressed: root.activated()
    Column {
        id: labels
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Style.space(10) }
        anchors.leftMargin: Style.space(root.showIcon ? 38 : 10)
        spacing: Style.space(3)
        Label { width: parent.width; text: root.title; font.bold: root.selected }
        Label { width: parent.width; text: root.detail; visible: text.length > 0; font.pixelSize: Style.font.bodySmall }
    }
    Image {
        id: icon
        visible: root.showIcon
        anchors { left: parent.left; leftMargin: Style.space(10); verticalCenter: parent.verticalCenter }
        width: Style.space(20)
        height: width
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        source: root.appIcon.startsWith("/") ? "file://" + root.appIcon : Quickshell.iconPath(root.appIcon || "application-x-executable", true)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        Accessible.ignored: true
        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height * 0.8
            visible: icon.status !== Image.Ready
            color: "transparent"
            border.color: Color.popups.text
            radius: Math.min(Style.cornerRadius, Style.space(2))
            Rectangle { x: 1; y: Style.space(5); width: parent.width - 2; height: 1; color: Color.popups.text }
        }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.activated() }
}
