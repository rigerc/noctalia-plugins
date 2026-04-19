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
    navigationSections: [
        {
            "id": "backup",
            "label": rootSettings?.pluginApi?.tr("settings.presets.backup.label"),
            "icon": "download",
            "target": presetsSection.backupSectionTarget
        },
        {
            "id": "built-in",
            "label": rootSettings?.pluginApi?.tr("settings.presets.builtin.label"),
            "icon": "template",
            "target": presetsSection.builtInSectionTarget
        },
        {
            "id": "custom",
            "label": rootSettings?.pluginApi?.tr("settings.presets.custom.label"),
            "icon": "device-floppy",
            "target": presetsSection.customSectionTarget
        }
    ]

    PresetsSection {
        id: presetsSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
