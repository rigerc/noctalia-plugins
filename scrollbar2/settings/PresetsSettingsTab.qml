import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.presets")
    description: rootSettings?.pluginApi?.tr("settings.pages.presets")
    icon: "template"

    PresetsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
