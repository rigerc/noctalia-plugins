import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias trackColorsSectionTarget: trackColorsCard.sectionTarget
    property alias focusColorsSectionTarget: focusColorsCard.sectionTarget
    property alias windowColorsSectionTarget: windowColorsCard.sectionTarget
    readonly property bool trackEdgeFadeSettingsActive: (root.rootSettings?.nestedSettingValue("track", "edgeFade", "leftEnabled") ?? false)
        || (root.rootSettings?.nestedSettingValue("track", "edgeFade", "rightEnabled") ?? false)
    readonly property bool iconSettingsActive: root.rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
    readonly property bool titleSettingsActive: root.rootSettings?.isVisibleByConditions(["showTitle"]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: trackColorsCard
        sectionKey: "track"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.trackColors.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.trackColors.desc")

        SettingsSubCard {
            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.track.color.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.color.desc")
                currentColor: root.rootSettings?.objectSettingValue("track", "fill", "color") ?? "surface"
                defaultColor: root.rootSettings?.defaultObjectValue("track", "fill", "color") ?? "surface"
                currentOpacity: root.rootSettings?.objectSettingValue("track", "fill", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultObjectValue("track", "fill", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setObjectSetting("track", "fill", "color", value)
                onOpacitySelected: value => root.rootSettings?.setObjectSetting("track", "fill", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.track.separatorColor.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.separatorColor.desc")
                currentColor: root.rootSettings?.settingValue("track", "separatorColor") ?? "outline"
                defaultColor: root.rootSettings?.defaultValue("track", "separatorColor") ?? "outline"
                onColorSelected: value => root.rootSettings?.setSetting("track", "separatorColor", value)
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.opacity.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.opacity.desc")
                from: 0
                to: 1
                stepSize: 0.01
                value: root.rootSettings?.settingValue("focusLine", "opacity") ?? 1
                text: Math.round(value * 100) + "%"
                defaultValue: root.rootSettings?.defaultValue("focusLine", "opacity") ?? 1
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("focusLine", "opacity", Math.round(sliderValue * 100) / 100)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.lineColor.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.lineColor.desc")
                currentColor: root.rootSettings?.objectSettingValue("focusLine", "lineColor", "color") ?? "primary"
                defaultColor: root.rootSettings?.defaultObjectValue("focusLine", "lineColor", "color") ?? "primary"
                currentOpacity: root.rootSettings?.objectSettingValue("focusLine", "lineColor", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultObjectValue("focusLine", "lineColor", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setObjectSetting("focusLine", "lineColor", "color", value)
                onOpacitySelected: value => root.rootSettings?.setObjectSetting("focusLine", "lineColor", "opacity", value)
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.track.edgeFade.leftEnabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.edgeFade.leftEnabled.desc")
                checked: root.rootSettings?.nestedSettingValue("track", "edgeFade", "leftEnabled") ?? false
                defaultValue: root.rootSettings?.defaultNestedValue("track", "edgeFade", "leftEnabled") ?? false
                onToggled: checked => root.rootSettings?.setNestedSetting("track", "edgeFade", "leftEnabled", checked)
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.track.edgeFade.rightEnabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.edgeFade.rightEnabled.desc")
                checked: root.rootSettings?.nestedSettingValue("track", "edgeFade", "rightEnabled") ?? false
                defaultValue: root.rootSettings?.defaultNestedValue("track", "edgeFade", "rightEnabled") ?? false
                onToggled: checked => root.rootSettings?.setNestedSetting("track", "edgeFade", "rightEnabled", checked)
            }

            NValueSlider {
                enabled: root.trackEdgeFadeSettingsActive
                opacity: root.trackEdgeFadeSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.track.edgeFade.width.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.edgeFade.width.desc")
                from: 0
                to: 120
                stepSize: 1
                value: root.rootSettings?.nestedSettingValue("track", "edgeFade", "width") ?? 24
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultNestedValue("track", "edgeFade", "width") ?? 24
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setNestedSetting("track", "edgeFade", "width", Math.round(sliderValue))
            }
        
        }
    }

    SettingsSectionCard {
        id: focusColorsCard
        sectionKey: "focusLine"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.focusColors.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.focusColors.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.enabled.desc")
                checked: root.rootSettings?.stateSettingValue("focusLine", "colors", "focused", "enabled") ?? true
                defaultValue: root.rootSettings?.defaultStateValue("focusLine", "colors", "focused", "enabled") ?? true
                onToggled: checked => root.rootSettings?.setStateSetting("focusLine", "colors", "focused", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.rootSettings?.stateSettingValue("focusLine", "colors", "focused", "enabled") ?? true
                opacity: enabled ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.desc")
                currentColor: root.rootSettings?.stateSettingValue("focusLine", "colors", "focused", "color") ?? "primary"
                defaultColor: root.rootSettings?.defaultStateValue("focusLine", "colors", "focused", "color") ?? "primary"
                currentOpacity: root.rootSettings?.stateSettingValue("focusLine", "colors", "focused", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("focusLine", "colors", "focused", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("focusLine", "colors", "focused", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("focusLine", "colors", "focused", "opacity", value)
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.enabled.desc")
                checked: root.rootSettings?.stateSettingValue("focusLine", "colors", "hover", "enabled") ?? true
                defaultValue: root.rootSettings?.defaultStateValue("focusLine", "colors", "hover", "enabled") ?? true
                onToggled: checked => root.rootSettings?.setStateSetting("focusLine", "colors", "hover", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.rootSettings?.stateSettingValue("focusLine", "colors", "hover", "enabled") ?? true
                opacity: enabled ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.desc")
                currentColor: root.rootSettings?.stateSettingValue("focusLine", "colors", "hover", "color") ?? "hover"
                defaultColor: root.rootSettings?.defaultStateValue("focusLine", "colors", "hover", "color") ?? "hover"
                currentOpacity: root.rootSettings?.stateSettingValue("focusLine", "colors", "hover", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("focusLine", "colors", "hover", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("focusLine", "colors", "hover", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("focusLine", "colors", "hover", "opacity", value)
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.enabled.desc")
                checked: root.rootSettings?.stateSettingValue("focusLine", "colors", "default", "enabled") ?? true
                defaultValue: root.rootSettings?.defaultStateValue("focusLine", "colors", "default", "enabled") ?? true
                onToggled: checked => root.rootSettings?.setStateSetting("focusLine", "colors", "default", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.rootSettings?.stateSettingValue("focusLine", "colors", "default", "enabled") ?? true
                opacity: enabled ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.desc")
                currentColor: root.rootSettings?.stateSettingValue("focusLine", "colors", "default", "color") ?? "surface-variant"
                defaultColor: root.rootSettings?.defaultStateValue("focusLine", "colors", "default", "color") ?? "surface-variant"
                currentOpacity: root.rootSettings?.stateSettingValue("focusLine", "colors", "default", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("focusLine", "colors", "default", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("focusLine", "colors", "default", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("focusLine", "colors", "default", "opacity", value)
            }
        
        }
    }

    SettingsSectionCard {
        id: windowColorsCard
        sectionKey: "window"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.windowColors.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.windowColors.desc")

        SettingsSubCard {
            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.iconSettingsActive
                opacity: root.iconSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.iconColors.focused.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.iconColors.focused.desc")
                currentColor: root.rootSettings?.stateSettingValue("window", "iconColors", "focused", "color") ?? "on-surface"
                defaultColor: root.rootSettings?.defaultStateValue("window", "iconColors", "focused", "color") ?? "on-surface"
                currentOpacity: root.rootSettings?.stateSettingValue("window", "iconColors", "focused", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("window", "iconColors", "focused", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("window", "iconColors", "focused", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("window", "iconColors", "focused", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.iconSettingsActive
                opacity: root.iconSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.desc")
                currentColor: root.rootSettings?.stateSettingValue("window", "iconColors", "hover", "color") ?? "on-hover"
                defaultColor: root.rootSettings?.defaultStateValue("window", "iconColors", "hover", "color") ?? "on-hover"
                currentOpacity: root.rootSettings?.stateSettingValue("window", "iconColors", "hover", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("window", "iconColors", "hover", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("window", "iconColors", "hover", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("window", "iconColors", "hover", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.iconSettingsActive
                opacity: root.iconSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.iconColors.default.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.iconColors.default.desc")
                currentColor: root.rootSettings?.stateSettingValue("window", "iconColors", "default", "color") ?? "on-surface-variant"
                defaultColor: root.rootSettings?.defaultStateValue("window", "iconColors", "default", "color") ?? "on-surface-variant"
                currentOpacity: root.rootSettings?.stateSettingValue("window", "iconColors", "default", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("window", "iconColors", "default", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("window", "iconColors", "default", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("window", "iconColors", "default", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.desc")
                currentColor: root.rootSettings?.stateSettingValue("window", "titleColors", "focused", "color") ?? "on-surface"
                defaultColor: root.rootSettings?.defaultStateValue("window", "titleColors", "focused", "color") ?? "on-surface"
                currentOpacity: root.rootSettings?.stateSettingValue("window", "titleColors", "focused", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("window", "titleColors", "focused", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("window", "titleColors", "focused", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("window", "titleColors", "focused", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.desc")
                currentColor: root.rootSettings?.stateSettingValue("window", "titleColors", "hover", "color") ?? "on-hover"
                defaultColor: root.rootSettings?.defaultStateValue("window", "titleColors", "hover", "color") ?? "on-hover"
                currentOpacity: root.rootSettings?.stateSettingValue("window", "titleColors", "hover", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("window", "titleColors", "hover", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("window", "titleColors", "hover", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("window", "titleColors", "hover", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.titleColors.default.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.titleColors.default.desc")
                currentColor: root.rootSettings?.stateSettingValue("window", "titleColors", "default", "color") ?? "on-surface-variant"
                defaultColor: root.rootSettings?.defaultStateValue("window", "titleColors", "default", "color") ?? "on-surface-variant"
                currentOpacity: root.rootSettings?.stateSettingValue("window", "titleColors", "default", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("window", "titleColors", "default", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("window", "titleColors", "default", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("window", "titleColors", "default", "opacity", value)
            }
        
        }
    }
}
