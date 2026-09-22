import QtQuick
import qs.Commons

Text {
    textFormat: Text.PlainText
    color: Color.popups.text
    font.family: Style.fontFamily
    font.pixelSize: Style.font.body
    wrapMode: Text.Wrap
    Accessible.role: Accessible.StaticText
    Accessible.name: text
}
