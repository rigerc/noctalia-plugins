import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias trackColorsSectionTarget: trackColorsBox.sectionTarget
    property alias focusColorsSectionTarget: focusColorsBox.sectionTarget
    property alias windowColorsSectionTarget: windowColorsBox.sectionTarget

    Layout.fillWidth: true
    spacing: Style.marginL

    SettingsSectionBox {
        id: trackColorsBox
        title: rootSettings?.pluginApi?.tr("settings.section.trackColors.label") ?? ""
        description: rootSettings?.pluginApi?.tr("settings.section.trackColors.desc") ?? ""

        SettingsColorField {
            pluginApi: rootSettings?.pluginApi
            rootSettings: root.rootSettings
            settingPath: "track.fill"
            label: rootSettings?.pluginApi?.tr("settings.track.color.label")
            description: rootSettings?.pluginApi?.tr("settings.track.color.desc")
        }

        SettingsColorField {
            pluginApi: rootSettings?.pluginApi
            rootSettings: root.rootSettings
            settingPath: "track.separatorColor"
            colorOnly: true
            label: rootSettings?.pluginApi?.tr("settings.track.separatorColor.label")
            description: rootSettings?.pluginApi?.tr("settings.track.separatorColor.desc")
        }

        SettingsToggle {
            settingPath: "track.edgeFade.leftEnabled"
            rootSettings: root.rootSettings
            label: rootSettings?.pluginApi?.tr("settings.track.edgeFade.leftEnabled.label")
            description: rootSettings?.pluginApi?.tr("settings.track.edgeFade.leftEnabled.desc")
        }

        SettingsToggle {
            settingPath: "track.edgeFade.rightEnabled"
            rootSettings: root.rootSettings
            label: rootSettings?.pluginApi?.tr("settings.track.edgeFade.rightEnabled.label")
            description: rootSettings?.pluginApi?.tr("settings.track.edgeFade.rightEnabled.desc")
        }

        SettingsSlider {
            settingPath: "track.edgeFade.width"
            rootSettings: root.rootSettings
            from: 0; to: 120; stepSize: 1
            unit: "px"
            label: rootSettings?.pluginApi?.tr("settings.track.edgeFade.width.label")
            description: rootSettings?.pluginApi?.tr("settings.track.edgeFade.width.desc")
            visible: (rootSettings?.getPath("track.edgeFade.leftEnabled") ?? false)
                || (rootSettings?.getPath("track.edgeFade.rightEnabled") ?? false)
        }
    }

    SettingsSectionBox {
        id: focusColorsBox
        title: rootSettings?.pluginApi?.tr("settings.section.focusColors.label") ?? ""
        description: rootSettings?.pluginApi?.tr("settings.section.focusColors.desc") ?? ""

        ColorStateEditor {
            rootSettings: root.rootSettings
            settingPath: "focusLine.colors"
            showEnabledToggles: true
            defaultColors: ({
                "focused": "primary",
                "hover": "hover",
                "default": "surface-variant"
            })
        }
    }

    SettingsSectionBox {
        id: windowColorsBox
        title: rootSettings?.pluginApi?.tr("settings.section.windowColors.label") ?? ""
        description: rootSettings?.pluginApi?.tr("settings.section.windowColors.desc") ?? ""

        ColorStateEditor {
            rootSettings: root.rootSettings
            settingPath: "window.iconColors"
            showEnabledToggles: false
            defaultColors: ({
                "focused": "on-surface",
                "hover": "on-hover",
                "default": "on-surface-variant"
            })
            visibilityConditions: ["showIcons"]
        }

        ColorStateEditor {
            rootSettings: root.rootSettings
            settingPath: "window.titleColors"
            showEnabledToggles: false
            defaultColors: ({
                "focused": "on-surface",
                "hover": "on-hover",
                "default": "on-surface-variant"
            })
            visibilityConditions: ["showTitle"]
        }
    }
}
