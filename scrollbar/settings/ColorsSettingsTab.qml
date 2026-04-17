import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    readonly property bool backgroundSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        []
    ]) ?? true
    readonly property bool activeWindowSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["showSlots"],
        ["showSlots", "showFocusedFill"],
        ["showSlots", "showFocusedFill"],
        ["showSlots"],
        ["showSlots", "showFocusedBorder"],
        ["showSlots", "showFocusedBorder"],
        ["showSlots"]
    ]) ?? true
    readonly property bool inactiveWindowSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["showSlots"],
        ["showSlots"],
        ["showSlots", "showUnfocusedFill"],
        ["showSlots", "showUnfocusedFill"],
        ["showSlots"],
        ["showSlots", "showUnfocusedBorder"],
        ["showSlots", "showUnfocusedBorder"],
        ["showSlots"]
    ]) ?? true
    readonly property bool hoveredWindowSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["showSlots"],
        ["showSlots"],
        ["showSlots"],
        ["showSlots", "showHoverBorder"],
        ["showSlots", "showHoverBorder"],
        ["showSlots"],
        ["showSlots"],
        ["showSlots"]
    ]) ?? true
    readonly property bool workspaceIndicatorColorsSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"]
    ]) ?? true
    readonly property bool indicatorsSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        ["showTrackLine"],
        ["showTrackLine"],
        ["showTrackLine"],
        ["showTrackLine"],
        ["showTrackLine"],
        ["showTrackLine", "showFocusLine"],
        ["showTrackLine", "showFocusLine"],
        ["showTrackLine", "showFocusLine"],
        ["showTrackLine", "showFocusLine"]
    ]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginXL

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.background.label")
        description: rootSettings?.pluginApi?.tr("settings.section.background.desc")
    }
    NDivider {}

    NColorChoice {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.backgroundColor.label")
        description: rootSettings?.pluginApi?.tr("settings.backgroundColor.desc")
        currentKey: rootSettings?.settingValue("background", "color") ?? "none"
        onSelected: key => rootSettings?.setSetting("background", "color", key)
    }

    NValueSlider {
        label: rootSettings?.pluginApi?.tr("settings.backgroundOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.backgroundOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("background", "opacity") ?? 0
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("background", "opacity") ?? 0
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("background", "opacity", Math.round(sliderValue))
    }

    NLabel {
        visible: !backgroundSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.activeWindow.label")
        description: rootSettings?.pluginApi?.tr("settings.section.activeWindow.desc")
    }
    NDivider {}

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showFocusedFill.label")
        description: rootSettings?.pluginApi?.tr("settings.showFocusedFill.desc")
        checked: rootSettings?.settingValue("focused", "showFill") ?? true
        onToggled: checked => rootSettings?.setSetting("focused", "showFill", checked)
        defaultValue: rootSettings?.defaultValue("focused", "showFill") ?? true
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showFocusedFill"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.focusedFillColor.label")
        description: rootSettings?.pluginApi?.tr("settings.focusedFillColor.desc")
        currentKey: rootSettings?.settingValue("focused", "fillColor") ?? "primary"
        onSelected: key => rootSettings?.setSetting("focused", "fillColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showFocusedFill"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.focusedFillOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.focusedFillOpacity.desc")
        from: 20
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("focused", "fillOpacity") ?? 92
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("focused", "fillOpacity") ?? 92
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("focused", "fillOpacity", Math.round(sliderValue))
    }

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showFocusedBorder.label")
        description: rootSettings?.pluginApi?.tr("settings.showFocusedBorder.desc")
        checked: rootSettings?.settingValue("focused", "showBorder") ?? true
        onToggled: checked => rootSettings?.setSetting("focused", "showBorder", checked)
        defaultValue: rootSettings?.defaultValue("focused", "showBorder") ?? true
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showFocusedBorder"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.focusedBorderColor.label")
        description: rootSettings?.pluginApi?.tr("settings.focusedBorderColor.desc")
        currentKey: rootSettings?.settingValue("focused", "borderColor") ?? "primary"
        onSelected: key => rootSettings?.setSetting("focused", "borderColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showFocusedBorder"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.focusedBorderOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.focusedBorderOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("focused", "borderOpacity") ?? 100
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("focused", "borderOpacity") ?? 100
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("focused", "borderOpacity", Math.round(sliderValue))
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.focusedTextColor.label")
        description: rootSettings?.pluginApi?.tr("settings.focusedTextColor.desc")
        currentKey: rootSettings?.settingValue("focused", "textColor") ?? "on-primary"
        onSelected: key => rootSettings?.setSetting("focused", "textColor", key)
    }

    NLabel {
        visible: !activeWindowSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.inactiveWindows.label")
        description: rootSettings?.pluginApi?.tr("settings.section.inactiveWindows.desc")
    }
    NDivider {}

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.inactiveOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.inactiveOpacity.desc")
        from: 10
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("unfocused", "inactiveOpacity") ?? 45
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("unfocused", "inactiveOpacity") ?? 45
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("unfocused", "inactiveOpacity", Math.round(sliderValue))
    }

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showUnfocusedFill.label")
        description: rootSettings?.pluginApi?.tr("settings.showUnfocusedFill.desc")
        checked: rootSettings?.settingValue("unfocused", "showFill") ?? true
        onToggled: checked => rootSettings?.setSetting("unfocused", "showFill", checked)
        defaultValue: rootSettings?.defaultValue("unfocused", "showFill") ?? true
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showUnfocusedFill"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.unfocusedFillColor.label")
        description: rootSettings?.pluginApi?.tr("settings.unfocusedFillColor.desc")
        currentKey: rootSettings?.settingValue("unfocused", "fillColor") ?? "surface-variant"
        onSelected: key => rootSettings?.setSetting("unfocused", "fillColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showUnfocusedFill"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.unfocusedFillOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.unfocusedFillOpacity.desc")
        from: 0
        to: 60
        stepSize: 1
        value: rootSettings?.settingValue("unfocused", "fillOpacity") ?? 8
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("unfocused", "fillOpacity") ?? 8
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("unfocused", "fillOpacity", Math.round(sliderValue))
    }

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showUnfocusedBorder.label")
        description: rootSettings?.pluginApi?.tr("settings.showUnfocusedBorder.desc")
        checked: rootSettings?.settingValue("unfocused", "showBorder") ?? true
        onToggled: checked => rootSettings?.setSetting("unfocused", "showBorder", checked)
        defaultValue: rootSettings?.defaultValue("unfocused", "showBorder") ?? true
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showUnfocusedBorder"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.unfocusedBorderColor.label")
        description: rootSettings?.pluginApi?.tr("settings.unfocusedBorderColor.desc")
        currentKey: rootSettings?.settingValue("unfocused", "borderColor") ?? "outline"
        onSelected: key => rootSettings?.setSetting("unfocused", "borderColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showUnfocusedBorder"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.unfocusedBorderOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.unfocusedBorderOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("unfocused", "borderOpacity") ?? 45
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("unfocused", "borderOpacity") ?? 45
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("unfocused", "borderOpacity", Math.round(sliderValue))
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.unfocusedTextColor.label")
        description: rootSettings?.pluginApi?.tr("settings.unfocusedTextColor.desc")
        currentKey: rootSettings?.settingValue("unfocused", "textColor") ?? "on-surface"
        onSelected: key => rootSettings?.setSetting("unfocused", "textColor", key)
    }

    NLabel {
        visible: !inactiveWindowSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.hoveredWindow.label")
        description: rootSettings?.pluginApi?.tr("settings.section.hoveredWindow.desc")
    }
    NDivider {}

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.hoverFillColor.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverFillColor.desc")
        currentKey: rootSettings?.settingValue("hover", "fillColor") ?? "hover"
        onSelected: key => rootSettings?.setSetting("hover", "fillColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.hoverFillOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverFillOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("hover", "fillOpacity") ?? 55
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("hover", "fillOpacity") ?? 55
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("hover", "fillOpacity", Math.round(sliderValue))
    }

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showHoverBorder.label")
        description: rootSettings?.pluginApi?.tr("settings.showHoverBorder.desc")
        checked: rootSettings?.settingValue("hover", "showBorder") ?? true
        onToggled: checked => rootSettings?.setSetting("hover", "showBorder", checked)
        defaultValue: rootSettings?.defaultValue("hover", "showBorder") ?? true
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showHoverBorder"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.hoverBorderColor.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverBorderColor.desc")
        currentKey: rootSettings?.settingValue("hover", "borderColor") ?? "outline"
        onSelected: key => rootSettings?.setSetting("hover", "borderColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots", "showHoverBorder"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.hoverBorderOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverBorderOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("hover", "borderOpacity") ?? 100
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("hover", "borderOpacity") ?? 100
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("hover", "borderOpacity", Math.round(sliderValue))
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.hoverTextColor.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverTextColor.desc")
        currentKey: rootSettings?.settingValue("hover", "textColor") ?? "on-hover"
        onSelected: key => rootSettings?.setSetting("hover", "textColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.hoverScalePercent.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverScalePercent.desc")
        from: 0
        to: 10
        stepSize: 0.1
        value: rootSettings?.settingValue("hover", "scalePercent") ?? 2.5
        text: value.toFixed(1) + "%"
        defaultValue: rootSettings?.defaultValue("hover", "scalePercent") ?? 2.5
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("hover", "scalePercent", Math.round(sliderValue * 10) / 10)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.hoverTransitionDurationMs.label")
        description: rootSettings?.pluginApi?.tr("settings.hoverTransitionDurationMs.desc")
        from: 0
        to: 400
        stepSize: 10
        value: rootSettings?.settingValue("hover", "transitionDurationMs") ?? 120
        text: Math.round(value) + " ms"
        defaultValue: rootSettings?.defaultValue("hover", "transitionDurationMs") ?? 120
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("hover", "transitionDurationMs", Math.round(sliderValue))
    }

    NLabel {
        visible: !hoveredWindowSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicatorColors.label")
        description: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicatorColors.desc")
    }
    NDivider {}

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorTextColor.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorTextColor.desc")
        currentKey: rootSettings?.settingValue("workspaceIndicator", "textColor") ?? "primary"
        onSelected: key => rootSettings?.setSetting("workspaceIndicator", "textColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("workspaceIndicator", "opacity") ?? 100
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("workspaceIndicator", "opacity") ?? 100
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "opacity", Math.round(sliderValue))
    }

    NLabel {
        visible: !workspaceIndicatorColorsSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.indicators.label")
        description: rootSettings?.pluginApi?.tr("settings.section.indicators.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showTrackLine.label")
        description: rootSettings?.pluginApi?.tr("settings.showTrackLine.desc")
        checked: rootSettings?.settingValue("indicators", "showTrackLine") ?? true
        onToggled: checked => rootSettings?.setSetting("indicators", "showTrackLine", checked)
        defaultValue: rootSettings?.defaultValue("indicators", "showTrackLine") ?? true
    }

    NComboBox {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.trackLinePosition.label")
        description: rootSettings?.pluginApi?.tr("settings.trackLinePosition.desc")
        model: rootSettings?.trackLinePositionModel
        currentKey: rootSettings?.settingValue("indicators", "trackLinePosition") ?? "end"
        defaultValue: rootSettings?.defaultValue("indicators", "trackLinePosition") ?? "end"
        onSelected: key => rootSettings?.setSetting("indicators", "trackLinePosition", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.trackLineThickness.label")
        description: rootSettings?.pluginApi?.tr("settings.trackLineThickness.desc")
        from: 1
        to: 8
        stepSize: 1
        value: rootSettings?.settingValue("indicators", "trackLineThickness") ?? 2
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("indicators", "trackLineThickness") ?? 2
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("indicators", "trackLineThickness", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.trackOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.trackOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("indicators", "trackOpacity") ?? 35
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("indicators", "trackOpacity") ?? 35
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("indicators", "trackOpacity", Math.round(sliderValue))
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.trackThumbColor.label")
        description: rootSettings?.pluginApi?.tr("settings.trackThumbColor.desc")
        currentKey: rootSettings?.settingValue("indicators", "trackThumbColor") ?? "primary"
        onSelected: key => rootSettings?.setSetting("indicators", "trackThumbColor", key)
    }

    NToggle {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.showFocusLine.label")
        description: rootSettings?.pluginApi?.tr("settings.showFocusLine.desc")
        checked: rootSettings?.settingValue("indicators", "showFocusLine") ?? true
        onToggled: checked => rootSettings?.setSetting("indicators", "showFocusLine", checked)
        defaultValue: rootSettings?.defaultValue("indicators", "showFocusLine") ?? true
    }

    NColorChoice {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine", "showFocusLine"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.focusLineColor.label")
        description: rootSettings?.pluginApi?.tr("settings.focusLineColor.desc")
        currentKey: rootSettings?.settingValue("indicators", "focusLineColor") ?? "secondary"
        onSelected: key => rootSettings?.setSetting("indicators", "focusLineColor", key)
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine", "showFocusLine"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.focusLineOpacity.label")
        description: rootSettings?.pluginApi?.tr("settings.focusLineOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: rootSettings?.settingValue("indicators", "focusLineOpacity") ?? 96
        text: Math.round(value) + "%"
        defaultValue: rootSettings?.defaultValue("indicators", "focusLineOpacity") ?? 96
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("indicators", "focusLineOpacity", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine", "showFocusLine"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.focusLineThickness.label")
        description: rootSettings?.pluginApi?.tr("settings.focusLineThickness.desc")
        from: 1
        to: 6
        stepSize: 1
        value: rootSettings?.settingValue("indicators", "focusLineThickness") ?? 2
        text: Math.round(value) + " px"
        defaultValue: rootSettings?.defaultValue("indicators", "focusLineThickness") ?? 2
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("indicators", "focusLineThickness", Math.round(sliderValue))
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["showTrackLine", "showFocusLine"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.focusLineAnimationMs.label")
        description: rootSettings?.pluginApi?.tr("settings.focusLineAnimationMs.desc")
        from: 0
        to: 400
        stepSize: 10
        value: rootSettings?.settingValue("indicators", "focusLineAnimationMs") ?? 120
        text: Math.round(value) + " ms"
        defaultValue: rootSettings?.defaultValue("indicators", "focusLineAnimationMs") ?? 120
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("indicators", "focusLineAnimationMs", Math.round(sliderValue))
    }

    NLabel {
        visible: !indicatorsSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }
}
