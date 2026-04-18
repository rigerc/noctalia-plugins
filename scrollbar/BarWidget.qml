import QtQuick
import Quickshell
import qs.Commons
import "./components"

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var currentSettings: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string screenName: screen?.name ?? ""
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property string renderMode: {
        const configuredMode = currentSettings?.window?.renderMode;
        if (configuredMode !== undefined)
            return configuredMode;

        const defaultMode = defaults?.window?.renderMode;
        if (defaultMode !== undefined)
            return defaultMode;

        return "bar";
    }
    readonly property bool renderInBar: renderMode !== "window"

    function refreshSettingsSnapshot() {
        currentSettings = pluginApi?.pluginSettings || ({});
    }

    onPluginApiChanged: refreshSettingsSnapshot()

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshSettingsSnapshot();
        }
    }

    implicitWidth: renderInBar ? view.implicitWidth : 0
    implicitHeight: renderInBar ? view.implicitHeight : 0
    opacity: renderInBar ? 1 : 0

    ScrollbarView {
        id: view
        anchors.fill: parent
        pluginApi: root.pluginApi
        screen: root.screen
        hostMode: "bar"
        fillHostThickness: true
        hostThickness: root.capsuleHeight
        visibleInCurrentMode: root.renderInBar
    }
}
