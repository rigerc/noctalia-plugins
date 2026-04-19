import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias displaySectionTarget: displayContent
    property alias trackSectionTarget: trackContent

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: displayContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: displayContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.display.label")
                description: rootSettings?.pluginApi?.tr("settings.section.display.desc")
            }

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.display.mode.label")
                description: rootSettings?.pluginApi?.tr("settings.display.mode.desc")
                model: rootSettings?.displayModeModel
                currentKey: rootSettings?.settingValue("display", "mode") ?? "floatingPanel"
                defaultValue: rootSettings?.defaultValue("display", "mode") ?? "floatingPanel"
                onSelected: key => rootSettings?.setSetting("display", "mode", key)
            }

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.position.label")
                description: rootSettings?.pluginApi?.tr("settings.track.position.desc")
                model: rootSettings?.trackPositionModel
                currentKey: rootSettings?.settingValue("track", "position") ?? "bottom"
                defaultValue: rootSettings?.defaultValue("track", "position") ?? "bottom"
                onSelected: key => rootSettings?.setSetting("track", "position", key)
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.display.scale.label")
                description: rootSettings?.pluginApi?.tr("settings.display.scale.desc")
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: rootSettings?.settingValue("display", "scale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("display", "scale") ?? 1.0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("display", "scale", Math.round(sliderValue * 100) / 100)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.display.margin.label")
                description: rootSettings?.pluginApi?.tr("settings.display.margin.desc")
                from: 0
                to: 48
                stepSize: 1
                value: rootSettings?.settingValue("display", "margin") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("display", "margin") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("display", "margin", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.display.offsetH.label")
                description: rootSettings?.pluginApi?.tr("settings.display.offsetH.desc")
                from: -200
                to: 200
                stepSize: 1
                value: rootSettings?.settingValue("display", "offsetH") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("display", "offsetH") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("display", "offsetH", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.display.offsetV.label")
                description: rootSettings?.pluginApi?.tr("settings.display.offsetV.desc")
                from: -200
                to: 200
                stepSize: 1
                value: rootSettings?.settingValue("display", "offsetV") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("display", "offsetV") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("display", "offsetV", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.display.radiusScale.label")
                description: rootSettings?.pluginApi?.tr("settings.display.radiusScale.desc")
                from: 0
                to: 3
                stepSize: 0.05
                value: rootSettings?.settingValue("display", "radiusScale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("display", "radiusScale") ?? 1.0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("display", "radiusScale", Math.round(sliderValue * 100) / 100)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.display.backgroundColor.label")
                description: rootSettings?.pluginApi?.tr("settings.display.backgroundColor.desc")
                currentColor: rootSettings?.objectSettingValue("display", "background", "color") ?? "none"
                defaultColor: rootSettings?.defaultObjectValue("display", "background", "color") ?? "none"
                currentOpacity: rootSettings?.objectSettingValue("display", "background", "opacity") ?? 0
                defaultOpacity: rootSettings?.defaultObjectValue("display", "background", "opacity") ?? 0
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setObjectSetting("display", "background", "color", value)
                onOpacitySelected: value => rootSettings?.setObjectSetting("display", "background", "opacity", value)
            }

            NToggle {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.display.gradientEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.display.gradientEnabled.desc")
                checked: rootSettings?.settingValue("display", "gradientEnabled") ?? false
                onToggled: checked => rootSettings?.setSetting("display", "gradientEnabled", checked)
                defaultValue: rootSettings?.defaultValue("display", "gradientEnabled") ?? false
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode", "displayGradientEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.display.gradientColor.label")
                description: rootSettings?.pluginApi?.tr("settings.display.gradientColor.desc")
                currentColor: rootSettings?.objectSettingValue("display", "gradient", "color") ?? "none"
                defaultColor: rootSettings?.defaultObjectValue("display", "gradient", "color") ?? "none"
                currentOpacity: rootSettings?.objectSettingValue("display", "gradient", "opacity") ?? 0
                defaultOpacity: rootSettings?.defaultObjectValue("display", "gradient", "opacity") ?? 0
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setObjectSetting("display", "gradient", "color", value)
                onOpacitySelected: value => rootSettings?.setObjectSetting("display", "gradient", "opacity", value)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode", "displayGradientEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.display.gradientDirection.label")
                description: rootSettings?.pluginApi?.tr("settings.display.gradientDirection.desc")
                model: rootSettings?.gradientDirectionModel
                currentKey: rootSettings?.settingValue("display", "gradientDirection") ?? "vertical"
                defaultValue: rootSettings?.defaultValue("display", "gradientDirection") ?? "vertical"
                onSelected: key => rootSettings?.setSetting("display", "gradientDirection", key)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: trackContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: trackContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.track.label")
                description: rootSettings?.pluginApi?.tr("settings.section.track.desc")
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.track.width.label")
                description: rootSettings?.pluginApi?.tr("settings.track.width.desc")
                from: 5
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("track", "width") ?? 90
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("track", "width") ?? 90
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("track", "width", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.track.thickness.label")
                description: rootSettings?.pluginApi?.tr("settings.track.thickness.desc")
                from: 1
                to: 40
                stepSize: 1
                value: rootSettings?.settingValue("track", "thickness") ?? 6
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("track", "thickness") ?? 6
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("track", "thickness", Math.round(sliderValue))
            }

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.verticalAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.track.verticalAlign.desc")
                model: rootSettings?.focusVerticalModel
                currentKey: rootSettings?.settingValue("track", "verticalAlign") ?? "bottom"
                defaultValue: rootSettings?.defaultValue("track", "verticalAlign") ?? "bottom"
                onSelected: key => rootSettings?.setSetting("track", "verticalAlign", key)
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.track.segmentSpacing.label")
                description: rootSettings?.pluginApi?.tr("settings.track.segmentSpacing.desc")
                from: 0
                to: 20
                stepSize: 1
                value: rootSettings?.settingValue("track", "segmentSpacing") ?? 4
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("track", "segmentSpacing") ?? 4
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("track", "segmentSpacing", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.track.borderRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.track.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("track", "borderRadius") ?? 3
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("track", "borderRadius") ?? 3
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("track", "borderRadius", Math.round(sliderValue))
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.shadowEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.track.shadowEnabled.desc")
                checked: rootSettings?.settingValue("track", "shadowEnabled") ?? true
                onToggled: checked => rootSettings?.setSetting("track", "shadowEnabled", checked)
                defaultValue: rootSettings?.defaultValue("track", "shadowEnabled") ?? true
            }
        }
    }
}
