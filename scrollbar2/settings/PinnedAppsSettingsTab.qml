import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.pinnedApps")
    description: rootSettings?.pluginApi?.tr("settings.pages.pinnedApps")
    icon: "apps"

    PinnedAppsSettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
