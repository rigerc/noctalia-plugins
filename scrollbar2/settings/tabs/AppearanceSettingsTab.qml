import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../sections"

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.appearance")
    description: rootSettings?.pluginApi?.tr("settings.pages.appearance")
    icon: "palette"
    navigationSections: [
        {
            "id": "window",
            "label": rootSettings?.pluginApi?.tr("settings.section.window.label"),
            "icon": "typography",
            "target": windowSection.windowSectionTarget
        },
        {
            "id": "colors",
            "label": rootSettings?.pluginApi?.tr("settings.section.trackColors.label"),
            "icon": "paint",
            "target": colorSection.trackColorsSectionTarget
        },
        {
            "id": "segment-colors",
            "label": rootSettings?.pluginApi?.tr("settings.section.focusColors.label"),
            "icon": "layers-subtract",
            "target": colorSection.focusColorsSectionTarget
        },
        {
            "id": "window-colors",
            "label": rootSettings?.pluginApi?.tr("settings.section.windowColors.label"),
            "icon": "text-color",
            "target": colorSection.windowColorsSectionTarget
        }
    ]

    WindowSettingsSection {
        id: windowSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    ColorSettingsSection {
        id: colorSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
