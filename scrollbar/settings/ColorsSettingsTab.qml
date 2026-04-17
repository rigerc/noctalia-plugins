import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

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
    readonly property bool focusedTitleSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["hideSlots", "focusedTitleEnabled"],
        ["hideSlots", "focusedTitleEnabled"]
    ]) ?? true
    readonly property bool workspaceIndicatorColorsSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["workspaceIndicatorEnabled"],
        ["workspaceIndicatorEnabled"]
    ]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: backgroundContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: backgroundContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.background.label")
                description: rootSettings?.pluginApi?.tr("settings.section.background.desc")
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.backgroundColor.label")
                description: rootSettings?.pluginApi?.tr("settings.backgroundColor.desc")
                currentValue: rootSettings?.settingValue("background", "color") ?? "none"
                defaultValue: rootSettings?.defaultValue("background", "color") ?? "none"
                onSelected: value => rootSettings?.setSetting("background", "color", value)
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
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: activeWindowContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: activeWindowContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.activeWindow.label")
                description: rootSettings?.pluginApi?.tr("settings.section.activeWindow.desc")
            }

            NToggle {
                visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.showFocusedFill.label")
                description: rootSettings?.pluginApi?.tr("settings.showFocusedFill.desc")
                checked: rootSettings?.settingValue("focused", "showFill") ?? true
                onToggled: checked => rootSettings?.setSetting("focused", "showFill", checked)
                defaultValue: rootSettings?.defaultValue("focused", "showFill") ?? true
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots", "showFocusedFill"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusedFillColor.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedFillColor.desc")
                currentValue: rootSettings?.settingValue("focused", "fillColor") ?? "primary"
                defaultValue: rootSettings?.defaultValue("focused", "fillColor") ?? "primary"
                onSelected: value => rootSettings?.setSetting("focused", "fillColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots", "showFocusedBorder"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusedBorderColor.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedBorderColor.desc")
                currentValue: rootSettings?.settingValue("focused", "borderColor") ?? "primary"
                defaultValue: rootSettings?.defaultValue("focused", "borderColor") ?? "primary"
                onSelected: value => rootSettings?.setSetting("focused", "borderColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusedTextColor.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTextColor.desc")
                currentValue: rootSettings?.settingValue("focused", "textColor") ?? "on-primary"
                defaultValue: rootSettings?.defaultValue("focused", "textColor") ?? "on-primary"
                onSelected: value => rootSettings?.setSetting("focused", "textColor", value)
            }

            NLabel {
                visible: !activeWindowSectionVisible
                description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
                descriptionColor: Color.mOnSurfaceVariant
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: inactiveWindowContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: inactiveWindowContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.inactiveWindows.label")
                description: rootSettings?.pluginApi?.tr("settings.section.inactiveWindows.desc")
            }

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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots", "showUnfocusedFill"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.unfocusedFillColor.label")
                description: rootSettings?.pluginApi?.tr("settings.unfocusedFillColor.desc")
                currentValue: rootSettings?.settingValue("unfocused", "fillColor") ?? "surface-variant"
                defaultValue: rootSettings?.defaultValue("unfocused", "fillColor") ?? "surface-variant"
                onSelected: value => rootSettings?.setSetting("unfocused", "fillColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots", "showUnfocusedBorder"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.unfocusedBorderColor.label")
                description: rootSettings?.pluginApi?.tr("settings.unfocusedBorderColor.desc")
                currentValue: rootSettings?.settingValue("unfocused", "borderColor") ?? "outline"
                defaultValue: rootSettings?.defaultValue("unfocused", "borderColor") ?? "outline"
                onSelected: value => rootSettings?.setSetting("unfocused", "borderColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.unfocusedTextColor.label")
                description: rootSettings?.pluginApi?.tr("settings.unfocusedTextColor.desc")
                currentValue: rootSettings?.settingValue("unfocused", "textColor") ?? "on-surface"
                defaultValue: rootSettings?.defaultValue("unfocused", "textColor") ?? "on-surface"
                onSelected: value => rootSettings?.setSetting("unfocused", "textColor", value)
            }

            NLabel {
                visible: !inactiveWindowSectionVisible
                description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
                descriptionColor: Color.mOnSurfaceVariant
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: hoveredWindowContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: hoveredWindowContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.hoveredWindow.label")
                description: rootSettings?.pluginApi?.tr("settings.section.hoveredWindow.desc")
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.hoverFillColor.label")
                description: rootSettings?.pluginApi?.tr("settings.hoverFillColor.desc")
                currentValue: rootSettings?.settingValue("hover", "fillColor") ?? "hover"
                defaultValue: rootSettings?.defaultValue("hover", "fillColor") ?? "hover"
                onSelected: value => rootSettings?.setSetting("hover", "fillColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots", "showHoverBorder"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.hoverBorderColor.label")
                description: rootSettings?.pluginApi?.tr("settings.hoverBorderColor.desc")
                currentValue: rootSettings?.settingValue("hover", "borderColor") ?? "outline"
                defaultValue: rootSettings?.defaultValue("hover", "borderColor") ?? "outline"
                onSelected: value => rootSettings?.setSetting("hover", "borderColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.hoverTextColor.label")
                description: rootSettings?.pluginApi?.tr("settings.hoverTextColor.desc")
                currentValue: rootSettings?.settingValue("hover", "textColor") ?? "on-hover"
                defaultValue: rootSettings?.defaultValue("hover", "textColor") ?? "on-hover"
                onSelected: value => rootSettings?.setSetting("hover", "textColor", value)
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
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: focusedTitleContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: focusedTitleContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.focusedTitle.label")
                description: rootSettings?.pluginApi?.tr("settings.section.focusedTitle.desc")
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusedTitleTextColor.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTitleTextColor.desc")
                currentValue: rootSettings?.settingValue("focusedTitle", "textColor") ?? "on-surface"
                defaultValue: rootSettings?.defaultValue("focusedTitle", "textColor") ?? "on-surface"
                onSelected: value => rootSettings?.setSetting("focusedTitle", "textColor", value)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.focusedTitleOpacity.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTitleOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("focusedTitle", "opacity") ?? 100
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("focusedTitle", "opacity") ?? 100
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("focusedTitle", "opacity", Math.round(sliderValue))
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusedTitleBackgroundColor.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTitleBackgroundColor.desc")
                currentValue: rootSettings?.settingValue("focusedTitle", "backgroundColor") ?? "none"
                defaultValue: rootSettings?.defaultValue("focusedTitle", "backgroundColor") ?? "none"
                onSelected: value => rootSettings?.setSetting("focusedTitle", "backgroundColor", value)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.focusedTitleBackgroundOpacity.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTitleBackgroundOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("focusedTitle", "backgroundOpacity") ?? 0
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("focusedTitle", "backgroundOpacity") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("focusedTitle", "backgroundOpacity", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.focusedTitleOffsetV.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTitleOffsetV.desc")
                from: -64
                to: 64
                stepSize: 1
                value: rootSettings?.settingValue("focusedTitle", "offsetV") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("focusedTitle", "offsetV") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("focusedTitle", "offsetV", Math.round(sliderValue))
            }

            NLabel {
                visible: !focusedTitleSectionVisible
                description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
                descriptionColor: Color.mOnSurfaceVariant
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: workspaceIndicatorColorsContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: workspaceIndicatorColorsContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicatorColors.label")
                description: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicatorColors.desc")
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorTextColor.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicatorTextColor.desc")
                currentValue: rootSettings?.settingValue("workspaceIndicator", "textColor") ?? "primary"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "textColor") ?? "primary"
                onSelected: value => rootSettings?.setSetting("workspaceIndicator", "textColor", value)
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
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: indicatorsContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: indicatorsContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.indicators.label")
                description: rootSettings?.pluginApi?.tr("settings.section.indicators.desc")
            }

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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTrackLine"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.trackThumbColor.label")
                description: rootSettings?.pluginApi?.tr("settings.trackThumbColor.desc")
                currentValue: rootSettings?.settingValue("indicators", "trackThumbColor") ?? "primary"
                defaultValue: rootSettings?.defaultValue("indicators", "trackThumbColor") ?? "primary"
                onSelected: value => rootSettings?.setSetting("indicators", "trackThumbColor", value)
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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTrackLine", "showFocusLine"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLineColor.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLineColor.desc")
                currentValue: rootSettings?.settingValue("indicators", "focusLineColor") ?? "secondary"
                defaultValue: rootSettings?.defaultValue("indicators", "focusLineColor") ?? "secondary"
                onSelected: value => rootSettings?.setSetting("indicators", "focusLineColor", value)
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
                to: 800
                stepSize: 10
                value: rootSettings?.settingValue("indicators", "focusLineAnimationMs") ?? 120
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultValue("indicators", "focusLineAnimationMs") ?? 120
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("indicators", "focusLineAnimationMs", Math.round(sliderValue))
            }
        }
    }
}
