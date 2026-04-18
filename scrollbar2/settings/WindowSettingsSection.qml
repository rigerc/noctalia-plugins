import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: windowContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: windowContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.window.label")
                description: rootSettings?.pluginApi?.tr("settings.section.window.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.showIcon.label")
                description: rootSettings?.pluginApi?.tr("settings.window.showIcon.desc")
                checked: rootSettings?.settingValue("window", "showIcon") ?? true
                onToggled: checked => rootSettings?.setSetting("window", "showIcon", checked)
                defaultValue: rootSettings?.defaultValue("window", "showIcon") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.showTitle.label")
                description: rootSettings?.pluginApi?.tr("settings.window.showTitle.desc")
                checked: rootSettings?.settingValue("window", "showTitle") ?? true
                onToggled: checked => rootSettings?.setSetting("window", "showTitle", checked)
                defaultValue: rootSettings?.defaultValue("window", "showTitle") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.focusedOnly.label")
                description: rootSettings?.pluginApi?.tr("settings.window.focusedOnly.desc")
                checked: rootSettings?.settingValue("window", "focusedOnly") ?? false
                onToggled: checked => rootSettings?.setSetting("window", "focusedOnly", checked)
                defaultValue: rootSettings?.defaultValue("window", "focusedOnly") ?? false
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["focusedOnly"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.focusedAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.window.focusedAlign.desc")
                model: rootSettings?.focusAlignModel
                currentKey: rootSettings?.settingValue("window", "focusedAlign") ?? "segment"
                defaultValue: rootSettings?.defaultValue("window", "focusedAlign") ?? "segment"
                onSelected: key => rootSettings?.setSetting("window", "focusedAlign", key)
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.window.borderRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.window.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("window", "borderRadius") ?? 6
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "borderRadius") ?? 6
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "borderRadius", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.window.margin.label")
                description: rootSettings?.pluginApi?.tr("settings.window.margin.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("window", "margin") ?? 2
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "margin") ?? 2
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "margin", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.window.paddingLeft.label")
                description: rootSettings?.pluginApi?.tr("settings.window.paddingLeft.desc")
                from: 0
                to: 32
                stepSize: 1
                value: rootSettings?.settingValue("window", "paddingLeft") ?? 7
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "paddingLeft") ?? 7
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "paddingLeft", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.window.paddingRight.label")
                description: rootSettings?.pluginApi?.tr("settings.window.paddingRight.desc")
                from: 0
                to: 32
                stepSize: 1
                value: rootSettings?.settingValue("window", "paddingRight") ?? 7
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "paddingRight") ?? 7
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "paddingRight", Math.round(sliderValue))
            }

            NSearchableComboBox {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.font.label")
                description: rootSettings?.pluginApi?.tr("settings.window.font.desc")
                model: FontService.availableFonts
                currentKey: rootSettings?.settingValue("window", "font") ?? ""
                defaultValue: rootSettings?.defaultValue("window", "font") ?? ""
                onSelected: key => rootSettings?.setSetting("window", "font", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.window.fontSize.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontSize.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("window", "fontSize") ?? 11
                text: value === 0 ? rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
                defaultValue: rootSettings?.defaultValue("window", "fontSize") ?? 11
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "fontSize", Math.round(sliderValue))
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.fontWeights.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontWeights.focused.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("window", "fontWeights", "focused") ?? "semibold"
                defaultValue: rootSettings?.defaultNestedValue("window", "fontWeights", "focused") ?? "semibold"
                onSelected: key => rootSettings?.setNestedSetting("window", "fontWeights", "focused", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.fontWeights.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontWeights.hover.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("window", "fontWeights", "hover") ?? "medium"
                defaultValue: rootSettings?.defaultNestedValue("window", "fontWeights", "hover") ?? "medium"
                onSelected: key => rootSettings?.setNestedSetting("window", "fontWeights", "hover", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.fontWeights.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontWeights.default.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("window", "fontWeights", "default") ?? "medium"
                defaultValue: rootSettings?.defaultNestedValue("window", "fontWeights", "default") ?? "medium"
                onSelected: key => rootSettings?.setNestedSetting("window", "fontWeights", "default", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconAlign.desc")
                model: rootSettings?.horizontalAlignModel
                currentKey: rootSettings?.settingValue("window", "iconAlign") ?? "center"
                defaultValue: rootSettings?.defaultValue("window", "iconAlign") ?? "center"
                onSelected: key => rootSettings?.setSetting("window", "iconAlign", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.window.iconScale.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconScale.desc")
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: rootSettings?.settingValue("window", "iconScale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("window", "iconScale") ?? 1.0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "iconScale", Math.round(sliderValue * 100) / 100)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleAlign.desc")
                model: rootSettings?.horizontalAlignModel
                currentKey: rootSettings?.settingValue("window", "titleAlign") ?? "left"
                defaultValue: rootSettings?.defaultValue("window", "titleAlign") ?? "left"
                onSelected: key => rootSettings?.setSetting("window", "titleAlign", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.window.titleScale.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleScale.desc")
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: rootSettings?.settingValue("window", "titleScale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("window", "titleScale") ?? 1.0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "titleScale", Math.round(sliderValue * 100) / 100)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: focusLineContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: focusLineContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.focusLine.label")
                description: rootSettings?.pluginApi?.tr("settings.section.focusLine.desc")
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.focusLine.thickness.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.thickness.desc")
                from: 1
                to: 40
                stepSize: 1
                value: rootSettings?.settingValue("focusLine", "thickness") ?? 6
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("focusLine", "thickness") ?? 6
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("focusLine", "thickness", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.focusLine.borderRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("focusLine", "borderRadius") ?? 3
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("focusLine", "borderRadius") ?? 3
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("focusLine", "borderRadius", Math.round(sliderValue))
            }

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.verticalAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.verticalAlign.desc")
                model: rootSettings?.focusVerticalModel
                currentKey: rootSettings?.settingValue("focusLine", "verticalAlign") ?? "bottom"
                defaultValue: rootSettings?.defaultValue("focusLine", "verticalAlign") ?? "bottom"
                onSelected: key => rootSettings?.setSetting("focusLine", "verticalAlign", key)
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.focusLine.opacity.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.opacity.desc")
                from: 0
                to: 1
                stepSize: 0.01
                value: rootSettings?.settingValue("focusLine", "opacity") ?? 1
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("focusLine", "opacity") ?? 1
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("focusLine", "opacity", Math.round(sliderValue * 100) / 100)
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.shadowEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.shadowEnabled.desc")
                checked: rootSettings?.settingValue("focusLine", "shadowEnabled") ?? true
                onToggled: checked => rootSettings?.setSetting("focusLine", "shadowEnabled", checked)
                defaultValue: rootSettings?.defaultValue("focusLine", "shadowEnabled") ?? true
            }
        }
    }
}
