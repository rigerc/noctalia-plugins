import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    readonly property bool slotSizeSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        [],
        ["widgetSizeModeFixed"],
        ["widgetSizeModeDynamic"],
        ["showSlots"],
        ["showSlots"],
        ["showSlots"],
        ["showSlots"],
        []
    ]) ?? true
    readonly property bool iconsSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["showSlots"],
        ["showSlots", "showIcons"],
        ["showSlots", "showIcons"],
        ["showSlots", "showIcons"]
    ]) ?? true
    readonly property bool windowTitleSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["showSlots"],
        ["showSlots", "showTitle"],
        ["showSlots", "showTitle"],
        ["showSlots", "showTitle"]
    ]) ?? true
    readonly property bool workspaceIndicatorSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"]
    ]) ?? true
    readonly property bool edgeFadeSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        ["edgeFadeEnabled"],
        ["edgeFadeEnabled"]
    ]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginXL

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.slotSize.label")
        description: rootSettings?.pluginApi?.tr("settings.section.slotSize.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showSlots.label")
        description: rootSettings?.pluginApi?.tr("settings.showSlots.desc")
        checked: rootSettings?.settingValue("layout", "showSlots") ?? true
        onToggled: checked => rootSettings?.setSetting("layout", "showSlots", checked)
        defaultValue: rootSettings?.defaultValue("layout", "showSlots") ?? true
    }

    NComboBox {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.widgetSizeMode.label")
        description: rootSettings?.pluginApi?.tr("settings.widgetSizeMode.desc")
        model: rootSettings?.widgetSizeModeModel
        currentKey: rootSettings?.settingValue("layout", "widgetSizeMode") ?? "dynamic"
        defaultValue: rootSettings?.defaultValue("layout", "widgetSizeMode") ?? "dynamic"
        onSelected: key => rootSettings?.setSetting("layout", "widgetSizeMode", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["widgetSizeModeFixed"]) ?? false
        label: rootSettings?.pluginApi?.tr("settings.fixedWidgetSize.label")
        description: rootSettings?.pluginApi?.tr("settings.fixedWidgetSize.desc")
        from: 120
        to: 1200
        stepSize: 8
        value: rootSettings?.settingValue("layout", "fixedWidgetSize") ?? 360
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("layout", "fixedWidgetSize") ?? 360
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("layout", "fixedWidgetSize", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
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
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
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
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
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

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
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
        visible: rootSettings?.isVisibleByConditions(["widgetSizeModeDynamic"]) ?? true
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

    NLabel {
        visible: !slotSizeSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.icons.label")
        description: rootSettings?.pluginApi?.tr("settings.section.icons.desc")
    }
    NDivider {}

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showIcons.label")
        description: rootSettings?.pluginApi?.tr("settings.showIcons.desc")
        checked: rootSettings?.settingValue("icons", "showIcons") ?? true
        onToggled: checked => rootSettings?.setSetting("icons", "showIcons", checked)
        defaultValue: rootSettings?.defaultValue("icons", "showIcons") ?? true
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showIcons"]) ?? true
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
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showIcons"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.iconTintColor.label")
        description: rootSettings?.pluginApi?.tr("settings.iconTintColor.desc")
        currentKey: rootSettings?.settingValue("icons", "iconTintColor") ?? "none"
        onSelected: key => rootSettings?.setSetting("icons", "iconTintColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showIcons"]) ?? true
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

    NLabel {
        visible: !iconsSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.windowTitle.label")
        description: rootSettings?.pluginApi?.tr("settings.section.windowTitle.desc")
    }
    NDivider {}

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showTitle.label")
        description: rootSettings?.pluginApi?.tr("settings.showTitle.desc")
        checked: rootSettings?.settingValue("title", "showTitle") ?? true
        onToggled: checked => rootSettings?.setSetting("title", "showTitle", checked)
        defaultValue: rootSettings?.defaultValue("title", "showTitle") ?? true
    }

    NSearchableComboBox {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showTitle"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.titleFontFamily.label")
        description: rootSettings?.pluginApi?.tr("settings.titleFontFamily.desc")
        model: FontService.availableFonts
        currentKey: rootSettings?.settingValue("title", "titleFontFamily") ?? ""
        defaultValue: rootSettings?.defaultValue("title", "titleFontFamily") ?? ""
        onSelected: key => rootSettings?.setSetting("title", "titleFontFamily", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showTitle"]) ?? true
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
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showTitle"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.titleFontWeight.label")
        description: rootSettings?.pluginApi?.tr("settings.titleFontWeight.desc")
        model: rootSettings?.fontWeightModel
        currentKey: rootSettings?.settingValue("title", "titleFontWeight") ?? "default"
        defaultValue: rootSettings?.defaultValue("title", "titleFontWeight") ?? "default"
        onSelected: key => rootSettings?.setSetting("title", "titleFontWeight", key)
    }

    NLabel {
        visible: !windowTitleSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.label")
        description: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorEnabled.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorEnabled.desc")
        checked: rootSettings?.settingValue("workspaceIndicator", "enabled") ?? false
        onToggled: checked => rootSettings?.setSetting("workspaceIndicator", "enabled", checked)
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "enabled") ?? false
    }

    NComboBox {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorLabelMode.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorLabelMode.desc")
        model: rootSettings?.workspaceIndicatorLabelModeModel
        currentKey: rootSettings?.settingValue("workspaceIndicator", "labelMode") ?? "id"
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "labelMode") ?? "id"
        onSelected: key => rootSettings?.setSetting("workspaceIndicator", "labelMode", key)
    }

    NComboBox {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorPosition.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorPosition.desc")
        model: rootSettings?.workspaceIndicatorPositionModel
        currentKey: rootSettings?.settingValue("workspaceIndicator", "position") ?? "before"
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "position") ?? "before"
        onSelected: key => rootSettings?.setSetting("workspaceIndicator", "position", key)
    }

    NSearchableComboBox {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorFontFamily.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorFontFamily.desc")
        model: FontService.availableFonts
        currentKey: rootSettings?.settingValue("workspaceIndicator", "fontFamily") ?? ""
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "fontFamily") ?? ""
        onSelected: key => rootSettings?.setSetting("workspaceIndicator", "fontFamily", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorFontSize.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorFontSize.desc")
        from: 0
        to: 24
        stepSize: 1
        value: rootSettings?.settingValue("workspaceIndicator", "fontSize") ?? 0
        text: value === 0 ? rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "fontSize") ?? 0
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "fontSize", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorSpacing.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorSpacing.desc")
        from: 0
        to: 32
        stepSize: 1
        value: rootSettings?.settingValue("workspaceIndicator", "spacing") ?? 8
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "spacing") ?? 8
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "spacing", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorPadding.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorPadding.desc")
        from: 0
        to: 24
        stepSize: 1
        value: rootSettings?.settingValue("workspaceIndicator", "padding") ?? 0
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "padding") ?? 0
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "padding", Math.round(sliderValue))
    }

    NLabel {
        visible: !workspaceIndicatorSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.edgeFade.label")
        description: rootSettings?.pluginApi?.tr("settings.section.edgeFade.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.edgeFadeEnabled.label")
        description: rootSettings?.pluginApi?.tr("settings.edgeFadeEnabled.desc")
        checked: rootSettings?.settingValue("edgeFade", "enabled") ?? true
        defaultValue: rootSettings?.defaultValue("edgeFade", "enabled") ?? true
        onToggled: checked => rootSettings?.setSetting("edgeFade", "enabled", checked)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["edgeFadeEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.edgeFadeSize.label")
        description: rootSettings?.pluginApi?.tr("settings.edgeFadeSize.desc")
        from: 0
        to: 96
        stepSize: 1
        value: rootSettings?.settingValue("edgeFade", "fadeSize") ?? 48
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("edgeFade", "fadeSize") ?? 48
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("edgeFade", "fadeSize", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["edgeFadeEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.edgeFadeOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.edgeFadeOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("edgeFade", "fadeOpacity") ?? 100
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("edgeFade", "fadeOpacity") ?? 100
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("edgeFade", "fadeOpacity", Math.round(sliderValue))
    }

    NLabel {
        visible: !edgeFadeSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }
}
