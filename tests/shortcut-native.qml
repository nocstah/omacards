import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui as Ui
import "Cards" as Cards
ShellRoot {
    id: harness
    function findItem(item, name) {
        if (item.objectName === name) return item
        for (const child of item.children || []) { const result = findItem(child,name); if (result) return result }
        return null
    }
    function editor() { return findItem(panel.contentView,"shortcutSettings") }
    Cards.Service { id: service }
    FileView {
        path: Quickshell.env("OMACARDS_FIXTURE")
        onLoaded: { service.snapshot = JSON.parse(text()); service.context=service.snapshot.context;service.page="shortcuts";service.selectedKey="";opening.start() }
    }
    Ui.PluginBarApi { id: bar;pluginId:"io.github.nocstah.omacards";moduleName:pluginId;barSize:30;position:"top" }
    PanelWindow {
        id: anchor
        anchors {top:true;left:true;right:true}
        implicitHeight:30
        color:Color.background
        Rectangle { id: button; width:30;height:30;anchors.right:parent.right;color:Color.accent }
    }
    Cards.Panel { id: panel;bar:bar;anchorItem:button;service:service }
    Timer { id:opening;interval:500;onTriggered:panel.reveal() }
    IpcHandler {
        target:"capturetest"
        function arm():string {
            const e=harness.editor(); if(!e) return "missing"
            e.choose(service.snapshot.shortcuts.rows[0]);
            Qt.callLater(function(){e.recording=true})
            return "ok"
        }
        function status():string {
            const e=harness.editor()
            return JSON.stringify({opened:panel.opened,recording:e?e.recording:false,key:e?e.candidateKey:"",mask:e?e.candidateMask:0,error:e?e.conflictError:""})
        }
        function hide():void { panel.controller.hide() }
        function quit():void { Qt.quit() }
    }
}
