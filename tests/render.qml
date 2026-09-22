import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import qs.Commons
import "Cards" as Cards

ShellRoot {
    id: harness
    property int step: 0
    property var original: null
    property var shots: ["cards", "edit", "motion", "question", "empty", "narrow", "scaled", "light", "dark", "pane-edit", "library-ungrouped", "no-front", "unselected-card", "long-front", "scaled-entry"]
    Cards.Service { id: service }
    FileView {
        path: Quickshell.env("OMACARDS_FIXTURE")
        onLoaded: {
            harness.original = JSON.parse(text())
            service.snapshot = JSON.parse(text())
            service.context = service.snapshot.context
            service.selectedKey = "container:1"
            capture.start()
        }
    }
    Window {
        id: window
        visible: true
        width: 468
        height: 700
        color: Color.popups.background
        Rectangle {
            id: area
            color: Color.popups.background
            anchors.fill: parent
            Cards.CardsContent { id: content; anchors.fill: parent; anchors.margins: 14; service: service }
        }
    }
    // Compile the real widget/popup too, without mapping a layer-shell surface.
    Cards.BarWidget { visible: false }
    Timer {
        id: capture
        interval: 500
        repeat: true
        onTriggered: {
            const name = harness.shots[harness.step]
            area.grabToImage(function(result) {
                if (!result.saveToFile(Quickshell.env("OMACARDS_CAPTURE_DIR") + "/" + name + ".png")) throw new Error("Capture failed")
                harness.step++
                if (harness.step === harness.shots.length) { console.log("OMACARDS_UI_CAPTURE_OK"); Qt.quit(); return }
                const next = harness.shots[harness.step]
                service.question = null
                service.page = next === "edit" || next === "motion" ? next : "cards"
                service.snapshot = JSON.parse(JSON.stringify(harness.original))
                service.context = service.snapshot.context
                service.selectedKey = "container:1"
                if (next === "question") service.question = {id: 1, mode: "select", prompt: "Choose an app for the back · Gmail stays on the front", choices: [{value: "a", label: "WhatsApp", detail: "Workspace 2"}, {value: "b", label: "Telegram", detail: "Workspace 2"}, {value: "w", label: "Add from workspace 5", detail: "Move an app here"}]}
                if (next === "empty") { const data = JSON.parse(JSON.stringify(harness.original)); data.cards = []; data.saved = []; service.snapshot = data }
                if (next === "narrow") { window.width = 340; window.height = 550 }
                if (next === "scaled") { window.width = 540; window.height = 800; Style.spacingScale = 1.25; Style.fontBaseSize = 15 }
                if (next === "light") { Style.spacingScale = 1; Style.fontBaseSize = 12; window.width = 468; window.height = 700; Color.shellValues = ({}); Color.background = "#faf8f3"; Color.foreground = "#242424"; Color.accent = "#2255aa"; Color.muted = "#666666" }
                if (next === "dark") { Color.shellValues = ({}); Color.background = "#1c2026"; Color.foreground = "#e6e9ef"; Color.accent = "#a9bfff"; Color.muted = "#9ba6b5" }
                if (["library-ungrouped", "no-front", "unselected-card", "long-front", "scaled-entry"].includes(next)) {
                    const data = JSON.parse(JSON.stringify(harness.original))
                    data.context.anchor = "0xd"
                    data.context.anchor_label = "Brave"
                    if (next !== "unselected-card") data.cards = []
                    if (next === "no-front" || next === "long-front") data.saved = []
                    if (next === "no-front") { data.context.anchor = null; data.context.anchor_label = null }
                    if (next === "long-front") data.context.anchor_label = "A long application name with project details and more context"
                    service.snapshot = data
                    service.context = data.context
                    service.selectedKey = ""
                    Style.spacingScale = next === "scaled-entry" ? 2 : 1
                    Style.fontBaseSize = next === "scaled-entry" ? 24 : 12
                    window.width = next === "scaled-entry" ? 936 : next === "long-front" ? 340 : 468
                    window.height = next === "scaled-entry" ? 1400 : 700
                    Color.shellValues = ({})
                    Color.background = "#faf8f3"; Color.foreground = "#242424"; Color.accent = "#2255aa"; Color.muted = "#666666"
                }
                if (next === "pane-edit") { service.page = "edit"; const d = JSON.parse(JSON.stringify(harness.original)); d.cards[0].active = 1; d.cards[0].current = "0xb"; service.snapshot = d; content.paneCardKey = "container:1"; content.paneAddress = "0xc"; window.height = 780 }
            })
        }
    }
}
