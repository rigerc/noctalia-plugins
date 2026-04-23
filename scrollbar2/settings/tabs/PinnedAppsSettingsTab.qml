import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../sections"

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.pinnedApps")
    description: rootSettings?.pluginApi?.tr("settings.pages.pinnedApps")
    icon: "apps"
    navigationSections: [
        {
            "id": "behavior",
            "label": rootSettings?.pluginApi?.tr("settings.section.pinnedApps.label"),
            "icon": "settings",
            "target": pinnedAppsSection.behaviorSectionTarget
        },
        {
            "id": "items",
            "label": rootSettings?.pluginApi?.tr("settings.pinnedApps.items.label"),
            "icon": "apps",
            "target": pinnedAppsSection.itemsSectionTarget
        }
    ]

    PinnedAppsSettingsSection {
        id: pinnedAppsSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
