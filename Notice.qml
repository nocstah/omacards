import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui

// Feedback text. An error sits in a surface tinted and outlined with the
// theme's urgent color, built from the shell's own selected-fill and normal
// border tokens, so it reads as an error by shape as well as hue while the
// words keep full-contrast popup text. Information stays plain text.
Ui.BorderSurface {
    id: root
    property string text: ""
    property bool error: false
    readonly property color urgent: Commons.Color.urgent
    visible: text.length > 0
    implicitHeight: label.implicitHeight + (error ? Style.space(16) : 0)
    radius: Style.cornerRadius
    color: error ? Style.selectedFillFor(urgent, urgent, urgent) : "transparent"
    borderSpec: error ? Border.controlSpec("normal", urgent, urgent, urgent) : Border.none()
    Accessible.role: error ? Accessible.AlertMessage : Accessible.StaticText
    Accessible.name: text
    Label {
        id: label
        anchors {
            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
            leftMargin: root.error ? Style.space(10) : 0; rightMargin: root.error ? Style.space(10) : 0
        }
        text: root.text
        wrapMode: Text.WordWrap
        Accessible.ignored: true
    }
}
