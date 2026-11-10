import QtQuick
import qs.Ui as Ui

Ui.Button {
    // Screen readers hear the target as well as the verb ("Preview Fade").
    property string accessibleName: text
    focusable: true
    opacity: enabled ? 1 : 0.45
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.description: tooltipText
    Accessible.onPressAction: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()
}
