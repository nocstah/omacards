import QtQuick
import qs.Ui as Ui

Ui.Button {
    focusable: true
    opacity: enabled ? 1 : 0.45
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: if (enabled) clicked()
}
