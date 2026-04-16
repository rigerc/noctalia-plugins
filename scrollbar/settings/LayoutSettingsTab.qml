import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    Layout.fillWidth: true
    spacing: Style.marginM

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.slotSize.label")
        description: rootSettings?.pluginApi?.tr("settings.section.slotSize.desc")
    }
    NDivider {}

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.slotWidth.label")
        description: rootSettings?.pluginApi?.tr("settings.slotWidth.desc")
        from: 72
        to: 220
        stepSize: 4
        value: rootSettings?.settingValue("layout", "slotWidth") ?? 112
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("layout", "slotWidth") ?? 112
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("layout", "slotWidth", Math.round(sliderValue))
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.maxWidgetWidth.label")
        description: rootSettings?.pluginApi?.tr("settings.maxWidgetWidth.desc")
        from: 20
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("layout", "maxWidgetWidth") ?? 40
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("layout", "maxWidgetWidth") ?? 40
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("layout", "maxWidgetWidth", Math.round(sliderValue))
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.slotSpacingUnits.label")
        description: rootSettings?.pluginApi?.tr("settings.slotSpacingUnits.desc")
        from: 0
        to: 6
        stepSize: 1
        value: rootSettings?.settingValue("layout", "slotSpacingUnits") ?? 1
        text: Math.round(value).toString()
        defaultValue: rootSettings?.defaultValue("layout", "slotSpacingUnits") ?? 1
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("layout", "slotSpacingUnits", Math.round(sliderValue))
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.radiusScale.label")
        description: rootSettings?.pluginApi?.tr("settings.radiusScale.desc")
        from: 0
        to: 1
        stepSize: 0.05
        value: rootSettings?.settingValue("layout", "radiusScale") ?? 1.0
        text: Math.round(value * 100) + "%"
        defaultValue: rootSettings?.defaultValue("layout", "radiusScale") ?? 1.0
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("layout", "radiusScale", Math.round(sliderValue * 100) / 100)
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.slotCapsuleScale.label")
        description: rootSettings?.pluginApi?.tr("settings.slotCapsuleScale.desc")
        from: 0.3
        to: 1.5
        stepSize: 0.05
        value: rootSettings?.settingValue("layout", "slotCapsuleScale") ?? 1.0
        text: Math.round(value * 100) + "%"
        defaultValue: rootSettings?.defaultValue("layout", "slotCapsuleScale") ?? 1.0
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("layout", "slotCapsuleScale", Math.round(sliderValue * 100) / 100)
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.icons.label")
        description: rootSettings?.pluginApi?.tr("settings.section.icons.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showIcons.label")
        description: rootSettings?.pluginApi?.tr("settings.showIcons.desc")
        checked: rootSettings?.settingValue("icons", "showIcons") ?? true
        onToggled: checked => rootSettings?.setSetting("icons", "showIcons", checked)
        defaultValue: rootSettings?.defaultValue("icons", "showIcons") ?? true
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.iconScale.label")
        description: rootSettings?.pluginApi?.tr("settings.iconScale.desc")
        from: 0.5
        to: 1.2
        stepSize: 0.05
        value: rootSettings?.settingValue("icons", "iconScale") ?? 0.8
        text: Math.round(value * 100) + "%"
        defaultValue: rootSettings?.defaultValue("icons", "iconScale") ?? 0.8
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("icons", "iconScale", Math.round(sliderValue * 100) / 100)
    }

    NColorChoice {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.iconTintColor.label")
        description: rootSettings?.pluginApi?.tr("settings.iconTintColor.desc")
        currentKey: rootSettings?.settingValue("icons", "iconTintColor") ?? "none"
        onSelected: key => rootSettings?.setSetting("icons", "iconTintColor", key)
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.iconTintOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.iconTintOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("icons", "iconTintOpacity") ?? 100
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("icons", "iconTintOpacity") ?? 100
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("icons", "iconTintOpacity", Math.round(sliderValue))
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.windowTitle.label")
        description: rootSettings?.pluginApi?.tr("settings.section.windowTitle.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showTitle.label")
        description: rootSettings?.pluginApi?.tr("settings.showTitle.desc")
        checked: rootSettings?.settingValue("title", "showTitle") ?? true
        onToggled: checked => rootSettings?.setSetting("title", "showTitle", checked)
        defaultValue: rootSettings?.defaultValue("title", "showTitle") ?? true
    }

    NSearchableComboBox {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.titleFontFamily.label")
        description: rootSettings?.pluginApi?.tr("settings.titleFontFamily.desc")
        model: FontService.availableFonts
        currentKey: rootSettings?.settingValue("title", "titleFontFamily") ?? ""
        defaultValue: rootSettings?.defaultValue("title", "titleFontFamily") ?? ""
        onSelected: key => rootSettings?.setSetting("title", "titleFontFamily", key)
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.titleFontSize.label")
        description: rootSettings?.pluginApi?.tr("settings.titleFontSize.desc")
        from: 0
        to: 24
        stepSize: 1
        value: rootSettings?.settingValue("title", "titleFontSize") ?? 0
        text: value === 0 ? rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
        defaultValue: rootSettings?.defaultValue("title", "titleFontSize") ?? 0
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("title", "titleFontSize", Math.round(sliderValue))
    }

    NSearchableComboBox {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.titleFontWeight.label")
        description: rootSettings?.pluginApi?.tr("settings.titleFontWeight.desc")
        model: rootSettings?.fontWeightModel
        currentKey: rootSettings?.settingValue("title", "titleFontWeight") ?? "default"
        defaultValue: rootSettings?.defaultValue("title", "titleFontWeight") ?? "default"
        onSelected: key => rootSettings?.setSetting("title", "titleFontWeight", key)
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.edgeFade.label")
        description: rootSettings?.pluginApi?.tr("settings.section.edgeFade.desc")
    }
    NDivider {}

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.edgeFadeSize.label")
        description: rootSettings?.pluginApi?.tr("settings.edgeFadeSize.desc")
        from: 0
        to: 48
        stepSize: 1
        value: rootSettings?.settingValue("edgeFade", "size") ?? 18
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("edgeFade", "size") ?? 18
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("edgeFade", "size", Math.round(sliderValue))
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.edgeFadeMidpoint.label")
        description: rootSettings?.pluginApi?.tr("settings.edgeFadeMidpoint.desc")
        from: 0.05
        to: 0.95
        stepSize: 0.05
        value: rootSettings?.settingValue("edgeFade", "midpoint") ?? 0.45
        text: Math.round(value * 100) + "%"
        defaultValue: rootSettings?.defaultValue("edgeFade", "midpoint") ?? 0.45
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("edgeFade", "midpoint", Math.round(sliderValue * 100) / 100)
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.edgeFadeMidOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.edgeFadeMidOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("edgeFade", "midOpacity") ?? 40
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("edgeFade", "midOpacity") ?? 40
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("edgeFade", "midOpacity", Math.round(sliderValue))
    }
}
