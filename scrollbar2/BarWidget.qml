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
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property string displayMode: {
        const configuredMode = currentSettings?.display?.mode;
        if (configuredMode !== undefined)
            return configuredMode;
        const defaultMode = defaults?.display?.mode;
        if (defaultMode !== undefined)
            return defaultMode;
        return "floatingPanel";
    }
    readonly property bool renderInBar: displayMode === "bar" && !isVerticalBar

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
    implicitHeight: renderInBar ? capsuleHeight : 0
    visible: renderInBar
    opacity: renderInBar ? 1 : 0

    WindowBarView {
        id: view
        anchors.fill: parent
        pluginApi: root.pluginApi
        screen: root.screen
        hostMode: "bar"
        visibleInCurrentMode: root.renderInBar
    }
}
