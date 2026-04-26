import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias windowSectionTarget: windowCard.sectionTarget
    readonly property bool focusedOnlySettingsActive: rootSettings?.isVisibleByConditions(["focusedOnly"]) ?? false
    readonly property bool iconSettingsActive: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
    readonly property bool titleSettingsActive: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: windowCard
        sectionKey: "window"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.section.window.label")
        description: rootSettings?.pluginApi?.tr("settings.section.window.desc")

        SettingsSubCard {
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

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.dragReorderEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.window.dragReorderEnabled.desc")
                checked: rootSettings?.settingValue("window", "dragReorderEnabled") ?? true
                onToggled: checked => rootSettings?.setSetting("window", "dragReorderEnabled", checked)
                defaultValue: rootSettings?.defaultValue("window", "dragReorderEnabled") ?? true
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.focusedOnlySettingsActive
                opacity: root.focusedOnlySettingsActive ? 1.0 : 0.45
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

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.window.paddingTop.label")
                description: rootSettings?.pluginApi?.tr("settings.window.paddingTop.desc")
                from: 0
                to: 32
                stepSize: 1
                value: rootSettings?.settingValue("window", "paddingTop") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "paddingTop") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "paddingTop", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.window.paddingBottom.label")
                description: rootSettings?.pluginApi?.tr("settings.window.paddingBottom.desc")
                from: 0
                to: 32
                stepSize: 1
                value: rootSettings?.settingValue("window", "paddingBottom") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "paddingBottom") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "paddingBottom", Math.round(sliderValue))
            }

            NSearchableComboBox {
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.font.label")
                description: rootSettings?.pluginApi?.tr("settings.window.font.desc")
                model: FontService.availableFonts
                currentKey: rootSettings?.settingValue("window", "font") ?? ""
                defaultValue: rootSettings?.defaultValue("window", "font") ?? ""
                onSelected: key => rootSettings?.setSetting("window", "font", key)
            }

            NValueSlider {
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
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
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.fontWeights.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontWeights.focused.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("window", "fontWeights", "focused") ?? "semibold"
                defaultValue: rootSettings?.defaultNestedValue("window", "fontWeights", "focused") ?? "semibold"
                onSelected: key => rootSettings?.setNestedSetting("window", "fontWeights", "focused", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.fontWeights.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontWeights.hover.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("window", "fontWeights", "hover") ?? "medium"
                defaultValue: rootSettings?.defaultNestedValue("window", "fontWeights", "hover") ?? "medium"
                onSelected: key => rootSettings?.setNestedSetting("window", "fontWeights", "hover", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.fontWeights.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.fontWeights.default.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("window", "fontWeights", "default") ?? "medium"
                defaultValue: rootSettings?.defaultNestedValue("window", "fontWeights", "default") ?? "medium"
                onSelected: key => rootSettings?.setNestedSetting("window", "fontWeights", "default", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.iconSettingsActive
                opacity: root.iconSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.iconAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconAlign.desc")
                model: rootSettings?.horizontalAlignModel
                currentKey: rootSettings?.settingValue("window", "iconAlign") ?? "center"
                defaultValue: rootSettings?.defaultValue("window", "iconAlign") ?? "center"
                onSelected: key => rootSettings?.setSetting("window", "iconAlign", key)
            }

            NValueSlider {
                enabled: root.iconSettingsActive
                opacity: root.iconSettingsActive ? 1.0 : 0.45
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
                Layout.fillWidth: true
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.titleAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleAlign.desc")
                model: rootSettings?.horizontalAlignModel
                currentKey: rootSettings?.settingValue("window", "titleAlign") ?? "left"
                defaultValue: rootSettings?.defaultValue("window", "titleAlign") ?? "left"
                onSelected: key => rootSettings?.setSetting("window", "titleAlign", key)
            }

            NValueSlider {
                enabled: root.titleSettingsActive
                opacity: root.titleSettingsActive ? 1.0 : 0.45
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
}
