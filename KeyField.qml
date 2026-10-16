import QtQuick
import qs.Ui as Ui

// A line editor that takes text only from typed keys. An editable Qt text
// input reads the clipboard's text whenever any app copies, even while hidden,
// so this field stays read-only (no clipboard reads, no paste) and applies key
// presses itself. insert() and remove() keep maximumLength and any text
// binding working; Qt.ImhDigitsOnly drops anything but digits.
Ui.TextField {
    id: root
    readOnly: true
    cursorVisible: activeFocus
    Accessible.role: Accessible.EditableText
    Accessible.readOnly: false
    function removeSelection() {
        if (selectionStart === selectionEnd) return false
        remove(selectionStart, selectionEnd)
        return true
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            accepted(); event.accepted = true
        } else if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
            if (!removeSelection()) {
                const back = event.key === Qt.Key_Backspace
                const at = cursorPosition
                if (back && at > 0) remove(at - (at > 1 && /[\udc00-\udfff]/.test(text[at - 1]) ? 2 : 1), at)
                else if (!back && at < length) remove(at, at + (/[\ud800-\udbff]/.test(text[at]) ? 2 : 1))
            }
            textEdited(); event.accepted = true
        } else if (!(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            const typed = event.text.replace(inputMethodHints & Qt.ImhDigitsOnly ? /\D/g : /[\u0000-\u001f\u007f]/g, "")
            if (!typed) return
            removeSelection()
            insert(cursorPosition, typed)
            textEdited(); event.accepted = true
        }
    }
}
