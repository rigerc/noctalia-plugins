import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

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
            "target": trackBox.sectionTarget
        }
    ]

    DisplaySettingsSection {
        id: displaySection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    ConditionalSection {
        id: trackSection
        condition: (rootSettings?.getPath("display.mode") ?? "floatingPanel") === "bar"
        disabledHint: rootSettings?.pluginApi?.tr("settings.track.disabledHint") ?? ""

        SettingsSectionBox {
            id: trackBox
            title: rootSettings?.pluginApi?.tr("settings.section.track.label") ?? ""
            description: rootSettings?.pluginApi?.tr("settings.section.track.desc") ?? ""

            SettingsSlider {
                settingPath: "track.width"
                rootSettings: root.rootSettings
                from: 5; to: 100; stepSize: 1
                unit: "%"
                label: rootSettings?.pluginApi?.tr("settings.track.width.label")
                description: rootSettings?.pluginApi?.tr("settings.track.width.desc")
            }

            SettingsSlider {
                settingPath: "track.thickness"
                rootSettings: root.rootSettings
                from: 1; to: 40; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.track.thickness.label")
                description: rootSettings?.pluginApi?.tr("settings.track.thickness.desc")
            }

            SettingsComboBox {
                settingPath: "track.verticalAlign"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.focusVerticalModel
                label: rootSettings?.pluginApi?.tr("settings.track.verticalAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.track.verticalAlign.desc")
            }

            SettingsSlider {
                settingPath: "track.segmentSpacing"
                rootSettings: root.rootSettings
                from: 0; to: 20; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.track.segmentSpacing.label")
                description: rootSettings?.pluginApi?.tr("settings.track.segmentSpacing.desc")
            }

            SettingsSlider {
                settingPath: "track.borderRadius"
                rootSettings: root.rootSettings
                from: 0; to: 24; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.track.borderRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.track.borderRadius.desc")
            }

            SettingsToggle {
                settingPath: "track.shadowEnabled"
                rootSettings: root.rootSettings
                label: rootSettings?.pluginApi?.tr("settings.track.shadowEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.track.shadowEnabled.desc")
            }
        }
    }
}
