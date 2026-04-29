import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias displaySectionTarget: displayCard.sectionTarget
    property alias trackSectionTarget: trackCard.sectionTarget
    readonly property bool floatingPanelSettingsActive: root.rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
    readonly property bool displayGradientSettingsActive: root.rootSettings?.isVisibleByConditions(["floatingPanelMode", "displayGradientEnabled"]) ?? false

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: displayCard
        sectionKey: "display"
        rootSettings: root.rootSettings

        title: root.rootSettings?.pluginApi?.tr("settings.section.display.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.display.desc")

        SettingsSubCard {
            NComboBox {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.display.mode.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.mode.desc")
                model: root.rootSettings?.displayModeModel
                currentKey: root.rootSettings?.settingValue("display", "mode") ?? "floatingPanel"
                defaultValue: root.rootSettings?.defaultValue("display", "mode") ?? "floatingPanel"
                onSelected: key => root.rootSettings?.setSetting("display", "mode", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.track.position.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.position.desc")
                model: root.rootSettings?.trackPositionModel
                currentKey: root.rootSettings?.settingValue("track", "position") ?? "bottom"
                defaultValue: root.rootSettings?.defaultValue("track", "position") ?? "bottom"
                onSelected: key => root.rootSettings?.setSetting("track", "position", key)
            }
        }

        SettingsSubCard {
            NValueSlider {
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.scale.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.scale.desc")
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: root.rootSettings?.settingValue("display", "scale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: root.rootSettings?.defaultValue("display", "scale") ?? 1.0
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("display", "scale", Math.round(sliderValue * 100) / 100)
            }

            NValueSlider {
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.margin.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.margin.desc")
                from: 0
                to: 48
                stepSize: 1
                value: root.rootSettings?.settingValue("display", "margin") ?? 0
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("display", "margin") ?? 0
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("display", "margin", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.offsetH.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.offsetH.desc")
                from: -200
                to: 200
                stepSize: 1
                value: root.rootSettings?.settingValue("display", "offsetH") ?? 0
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("display", "offsetH") ?? 0
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("display", "offsetH", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.offsetV.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.offsetV.desc")
                from: -200
                to: 200
                stepSize: 1
                value: root.rootSettings?.settingValue("display", "offsetV") ?? 0
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("display", "offsetV") ?? 0
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("display", "offsetV", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.radiusScale.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.radiusScale.desc")
                from: 0
                to: 3
                stepSize: 0.05
                value: root.rootSettings?.settingValue("display", "radiusScale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: root.rootSettings?.defaultValue("display", "radiusScale") ?? 1.0
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("display", "radiusScale", Math.round(sliderValue * 100) / 100)
            }
        }

        SettingsSubCard {
            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.backgroundColor.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.backgroundColor.desc")
                currentColor: root.rootSettings?.objectSettingValue("display", "background", "color") ?? "none"
                defaultColor: root.rootSettings?.defaultObjectValue("display", "background", "color") ?? "none"
                currentOpacity: root.rootSettings?.objectSettingValue("display", "background", "opacity") ?? 0
                defaultOpacity: root.rootSettings?.defaultObjectValue("display", "background", "opacity") ?? 0
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setObjectSetting("display", "background", "color", value)
                onOpacitySelected: value => root.rootSettings?.setObjectSetting("display", "background", "opacity", value)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.gradientEnabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.gradientEnabled.desc")
                checked: root.rootSettings?.settingValue("display", "gradientEnabled") ?? false
                onToggled: checked => root.rootSettings?.setSetting("display", "gradientEnabled", checked)
                defaultValue: root.rootSettings?.defaultValue("display", "gradientEnabled") ?? false
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.displayGradientSettingsActive
                opacity: root.displayGradientSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.gradientColor.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.gradientColor.desc")
                currentColor: root.rootSettings?.objectSettingValue("display", "gradient", "color") ?? "none"
                defaultColor: root.rootSettings?.defaultObjectValue("display", "gradient", "color") ?? "none"
                currentOpacity: root.rootSettings?.objectSettingValue("display", "gradient", "opacity") ?? 0
                defaultOpacity: root.rootSettings?.defaultObjectValue("display", "gradient", "opacity") ?? 0
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setObjectSetting("display", "gradient", "color", value)
                onOpacitySelected: value => root.rootSettings?.setObjectSetting("display", "gradient", "opacity", value)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.displayGradientSettingsActive
                opacity: root.displayGradientSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.display.gradientDirection.label")
                description: root.rootSettings?.pluginApi?.tr("settings.display.gradientDirection.desc")
                model: root.rootSettings?.gradientDirectionModel
                currentKey: root.rootSettings?.settingValue("display", "gradientDirection") ?? "vertical"
                defaultValue: root.rootSettings?.defaultValue("display", "gradientDirection") ?? "vertical"
                onSelected: key => root.rootSettings?.setSetting("display", "gradientDirection", key)
            }
        }
    }

    SettingsSectionCard {
        id: trackCard
        sectionKey: "track"
        rootSettings: root.rootSettings

        title: root.rootSettings?.pluginApi?.tr("settings.section.track.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.track.desc")

        SettingsSubCard {
            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.track.width.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.width.desc")
                from: 5
                to: 100
                stepSize: 1
                value: root.rootSettings?.settingValue("track", "width") ?? 90
                text: Math.round(value) + "%"
                defaultValue: root.rootSettings?.defaultValue("track", "width") ?? 90
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("track", "width", Math.round(sliderValue))
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.track.thickness.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.thickness.desc")
                from: 1
                to: 40
                stepSize: 1
                value: root.rootSettings?.settingValue("track", "thickness") ?? 6
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("track", "thickness") ?? 6
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("track", "thickness", Math.round(sliderValue))
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.thickness.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.thickness.desc")
                from: 1
                to: 40
                stepSize: 1
                value: root.rootSettings?.settingValue("focusLine", "thickness") ?? 6
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("focusLine", "thickness") ?? 6
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("focusLine", "thickness", Math.round(sliderValue))
            }
        }

        SettingsSubCard {
            NComboBox {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.track.verticalAlign.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.verticalAlign.desc")
                model: root.rootSettings?.focusVerticalModel
                currentKey: root.rootSettings?.settingValue("track", "verticalAlign") ?? "bottom"
                defaultValue: root.rootSettings?.defaultValue("track", "verticalAlign") ?? "bottom"
                onSelected: key => root.rootSettings?.setSetting("track", "verticalAlign", key)
            }

            NComboBox {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.verticalAlign.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.verticalAlign.desc")
                model: root.rootSettings?.focusVerticalModel
                currentKey: root.rootSettings?.settingValue("focusLine", "verticalAlign") ?? "bottom"
                defaultValue: root.rootSettings?.defaultValue("focusLine", "verticalAlign") ?? "bottom"
                onSelected: key => root.rootSettings?.setSetting("focusLine", "verticalAlign", key)
            }
        }

        SettingsSubCard {
            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.track.segmentSpacing.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.segmentSpacing.desc")
                from: 0
                to: 20
                stepSize: 1
                value: root.rootSettings?.settingValue("track", "segmentSpacing") ?? 4
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("track", "segmentSpacing") ?? 4
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("track", "segmentSpacing", Math.round(sliderValue))
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.track.borderRadius.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.rootSettings?.settingValue("track", "borderRadius") ?? 3
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("track", "borderRadius") ?? 3
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("track", "borderRadius", Math.round(sliderValue))
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.borderRadius.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.rootSettings?.settingValue("focusLine", "borderRadius") ?? 3
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("focusLine", "borderRadius") ?? 3
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("focusLine", "borderRadius", Math.round(sliderValue))
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.focusLine.width.label")
                description: root.rootSettings?.pluginApi?.tr("settings.focusLine.width.desc")
                from: 1
                to: 100
                stepSize: 1
                value: root.rootSettings?.settingValue("focusLine", "width") ?? 100
                text: Math.round(value) + "%"
                defaultValue: root.rootSettings?.defaultValue("focusLine", "width") ?? 100
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("focusLine", "width", Math.round(sliderValue))
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.track.shadowEnabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.track.shadowEnabled.desc")
                checked: root.rootSettings?.settingValue("track", "shadowEnabled") ?? true
                onToggled: checked => root.rootSettings?.setSetting("track", "shadowEnabled", checked)
                defaultValue: root.rootSettings?.defaultValue("track", "shadowEnabled") ?? true
            }
        }
    }
}
