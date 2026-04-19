import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.styleRules")
    description: rootSettings?.pluginApi?.tr("settings.pages.styleRules")
    icon: "filter-code"

    CustomStyleRulesSettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
