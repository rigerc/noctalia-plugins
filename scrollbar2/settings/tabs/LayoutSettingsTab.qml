import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../sections"

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.layout")
    description: rootSettings?.pluginApi?.tr("settings.pages.layout")
    icon: "layout-grid"
    navigationSections: [
        {
            "id": "display",
            "label": rootSettings?.pluginApi?.tr("settings.section.display.label"),
            "icon": "device-desktop",
            "target": displaySection.displaySectionTarget
        },
        {
            "id": "track",
            "label": rootSettings?.pluginApi?.tr("settings.section.track.label"),
            "icon": "line",
            "target": displaySection.trackSectionTarget
        }
    ]

    DisplaySettingsSection {
        id: displaySection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
