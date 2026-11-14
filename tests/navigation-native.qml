//@ pragma OmarchyLoadPatch
// The movement-shortcut offer and Settings switch, against an installed
// Hyprflip helper in a disposable session. navigation-native.py drives it over
// IPC and checks the compositor's keys between steps.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "Cards" as Cards

ShellRoot {
    id: harness
    // Set when the panel closes while a quiet action runs: switching must not close it.
    property bool quietClosed: false
    function panelContent() {
        for (const child of widget.children) if (child.item && child.item.contentView) return child.item.contentView
        return null
    }
    function findItem(item, test) {
        if (!item) return null
        if (test(item)) return item
        for (const child of item.children || []) { const found = findItem(child, test); if (found) return found }
        return null
    }
    function named(name) { return findItem(panelContent(), i => i.objectName === name) }
    // An offer button, by its text, so the test presses what a person would.
    function offerButton(text) { return findItem(named("navigationOffer"), i => i.text === text && i.clicked !== undefined) }
    Cards.Service { id: service; shell: shellApi }
    Connections {
        target: widget
        function onOpenedChanged() { if (!widget.opened && service.busy && service.quiet) harness.quietClosed = true }
    }
    QtObject { id: shellApi; function serviceFor(id) { return service } }
    Ui.PluginBarApi {
        id: bar
        pluginId: "io.github.nocstah.omacards"
        moduleName: pluginId
        shell: shellApi
        foreground: Color.foreground
        barForeground: foreground
        background: Color.background
        fontFamily: Style.fontFamily
        barSize: 30
        position: "top"
    }
    PanelWindow {
        anchors { top: true; left: true; right: true }
        implicitHeight: 30
        color: Color.background
        Cards.BarWidget { id: widget; bar: bar; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    Timer { interval: 400; running: true; onTriggered: widget.open() }
    IpcHandler {
        target: "navtest"
        function status(): string {
            const offer = harness.named("navigationOffer"), toggle = harness.named("navigationToggle"), s = service.snapshot
            return JSON.stringify({opened: widget.opened, busy: service.busy || service.refreshing, page: service.page,
                                   failed: service.failed, notice: service.notice, quietClosed: harness.quietClosed,
                                   available: s.available === true, capability: (s.capabilities || {}).navigation === true,
                                   navigation: s.navigation === undefined ? null : s.navigation,
                                   choice: s.navigation_choice === undefined ? null : s.navigation_choice,
                                   offer: !!offer && offer.visible, toggle: !!toggle && toggle.visible, checked: !!toggle && toggle.checked})
        }
        // "busy" while a refresh runs: the panel ignores actions then, so the test waits as a click would.
        function press(text: string): string {
            if (service.busy || service.refreshing) return "busy"
            const b = harness.offerButton(text); if (!b || !b.visible) return "missing"; b.clicked(); return "ok"
        }
        function toggle(): string {
            if (service.busy || service.refreshing) return "busy"
            const t = harness.named("navigationToggle"); if (!t || !t.visible) return "missing"; t.clicked(); return "ok"
        }
        function page(name: string): void { service.page = name }
        function refresh(): void { service.refresh(true) }
        function quit(): void { Qt.quit() }
    }
}
