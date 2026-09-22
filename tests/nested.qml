import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "Cards" as Cards

ShellRoot {
    id: harness
    property int phase: 0
    property int ticks: 0
    property int previousFace: -1
    property int savedFace: -1
    property string expectedTransition: ""
    function assertThat(test, message) { if (!test) { console.error("FAIL " + message); Qt.quit(); throw new Error(message) } }
    Cards.Service { id: service; shell: shellApi }
    Process { id: closeFixtures; command: ["python3", Quickshell.env("OMACARDS_TEST_CLOSE")] }
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
        screen: Quickshell.screens.find(s => s.name === Quickshell.env("OMACARDS_TEST_OUTPUT")) || null
        anchors { top: true; left: true; right: true }
        implicitHeight: 30
        color: Color.background
        Cards.BarWidget { id: widget; bar: bar; anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter }
    }
    Timer {
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            harness.ticks++
            if (harness.ticks > 160) { console.error("FAIL timeout at " + harness.phase + " " + service.notice); Qt.quit(); return }
            if (service.failed) { console.error("FAIL phase " + harness.phase + ": " + service.notice); Qt.quit(); return }
            if (service.question) {
                if (service.question.mode === "input") service.reply("Nested card")
                else if (harness.phase === 9) service.reply("layout")
                else if (harness.phase === 10) service.reply("layout vertical")
                else { console.error("FAIL unexpected question " + JSON.stringify(service.question)); Qt.quit(); return }
                if (harness.phase === 9) harness.phase = 10
                return
            }
            if (service.busy || service.refreshing) return
            if (harness.phase === 0) { widget.open(); harness.phase = 1; return }
            const card = service.currentCard
            if (harness.phase === 1) {
                if (!widget.opened) return
                harness.assertThat(card !== null, "card discovery")
                harness.previousFace = card.active
                service.cardAction("flip"); harness.phase = 2; return
            }
            if (harness.phase === 2) {
                harness.assertThat(card.active !== harness.previousFace, "flip from layer focus")
                console.log("PASS flip from native popup")
                widget.open(); harness.phase = 3; return
            }
            if (harness.phase === 3) {
                if (!widget.opened) return
                service.cardAction("unfold"); harness.phase = 4; return
            }
            if (harness.phase === 4) {
                harness.assertThat(card.unfolded, "unfold")
                widget.open(); harness.phase = 5; return
            }
            if (harness.phase === 5) {
                if (!widget.opened) return
                service.cardAction("unfold"); harness.phase = 6; return
            }
            if (harness.phase === 6) {
                harness.assertThat(!card.unfolded, "fold")
                console.log("PASS unfold and fold")
                widget.open(); harness.phase = 7; return
            }
            if (harness.phase === 7) {
                if (!widget.opened) return
                harness.savedFace = card.active
                service.edit("save", card.active, null); harness.phase = 8; return
            }
            if (harness.phase === 8) {
                harness.assertThat(service.snapshot.saved.some(s => s.name === "Nested card"), "save")
                console.log("PASS structured card name and save")
                // Explicitly activate a hidden side before the existing editor.
                service.edit("", 1, null); harness.phase = 9; return
            }
            if (harness.phase === 10) {
                harness.assertThat(card.faces[1].axis === "vertical", "hidden side layout")
                console.log("PASS hidden side activation and layout menu")
                service.page = "motion"
                service.run("duration", {duration_ms: 280}); harness.phase = 11; return
            }
            if (harness.phase === 11) {
                harness.assertThat(service.snapshot.duration_ms === 280, "duration")
                harness.assertThat(widget.opened, "return to motion")
                service.run("transition", {mode: "fade"}); harness.phase = 12; return
            }
            if (harness.phase === 12) {
                harness.assertThat(service.snapshot.transition === "fade", "transition")
                harness.previousFace = card.active
                service.cardAction("preview", {mode: "slide"}); harness.phase = 13; return
            }
            if (harness.phase === 13) {
                harness.assertThat(card.active === harness.previousFace && service.snapshot.transition === "fade", "preview return")
                console.log("PASS persisted motion and preview return")
                service.savedAction("open", service.snapshot.saved.find(s => s.name === "Nested card")); harness.phase = 14; return
            }
            if (harness.phase === 14) {
                harness.assertThat(!widget.opened, "saved Go to dismisses popup")
                harness.assertThat(service.snapshot.cards.length === 1, "no duplicate card")
                console.log("PASS saved Go to without extra confirmation")
                closeFixtures.running = true
                harness.phase = 15; return
            }
            if (harness.phase === 15) {
                if (closeFixtures.running) return
                widget.open(); harness.phase = 16; return
            }
            if (harness.phase === 16) {
                if (!widget.opened) return
                harness.assertThat(service.snapshot.cards.length === 0, "all fixture apps closed")
                service.savedAction("open", service.snapshot.saved.find(s => s.name === "Nested card")); harness.phase = 17; return
            }
            if (harness.phase === 17) {
                harness.assertThat(card && card.faces[0].panes.length === 1 && card.faces[1].panes.length === 2 && card.active === harness.savedFace, "cold open rebuilds both faces")
                harness.assertThat(!widget.opened, "cold open dismisses popup")
                console.log("PASS all three closed apps reopen into the saved card without extra confirmation")
                console.log("OMACARDS_NATIVE_TEST_OK")
                Qt.quit()
            }
        }
    }
}
