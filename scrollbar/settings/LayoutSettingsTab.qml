import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    readonly property bool iconsSectionVisible: rootSettings?.sectionHasVisibleSettings([
        ["showSlots"],
        ["showSlots", "showIcons"],
        ["showSlots", "showIcons"],
        ["showSlots", "showIcons"]
    ]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: hostModeContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: hostModeContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.renderMode.label")
                description: rootSettings?.pluginApi?.tr("settings.section.renderMode.desc")
            }

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.renderMode.label")
                description: rootSettings?.pluginApi?.tr("settings.renderMode.desc")
                model: rootSettings?.renderModeModel
                currentKey: rootSettings?.settingValue("window", "renderMode") ?? "bar"
                defaultValue: rootSettings?.defaultValue("window", "renderMode") ?? "bar"
                onSelected: key => rootSettings?.setSetting("window", "renderMode", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["renderModeWindow"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowSpaceMode.label")
                description: rootSettings?.pluginApi?.tr("settings.windowSpaceMode.desc")
                model: rootSettings?.windowSpaceModeModel
                currentKey: rootSettings?.settingValue("window", "spaceMode") ?? "overlay"
                defaultValue: rootSettings?.defaultValue("window", "spaceMode") ?? "overlay"
                onSelected: key => rootSettings?.setSetting("window", "spaceMode", key)
            }
        }
    }

    NBox {
        visible: rootSettings?.isVisibleByConditions(["renderModeWindow"]) ?? false
        Layout.fillWidth: true
        Layout.preferredHeight: windowPanelContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: windowPanelContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.windowPanel.label")
                description: rootSettings?.pluginApi?.tr("settings.section.windowPanel.desc")
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowOffsetH.label")
                description: rootSettings?.pluginApi?.tr("settings.windowOffsetH.desc")
                from: -200
                to: 200
                stepSize: 1
                value: rootSettings?.settingValue("window", "offsetH") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "offsetH") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "offsetH", Math.round(sliderValue))
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowOffsetV.label")
                description: rootSettings?.pluginApi?.tr("settings.windowOffsetV.desc")
                from: -200
                to: 200
                stepSize: 1
                value: rootSettings?.settingValue("window", "offsetV") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "offsetV") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "offsetV", Math.round(sliderValue))
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowScale.label")
                description: rootSettings?.pluginApi?.tr("settings.windowScale.desc")
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: rootSettings?.settingValue("window", "scale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("window", "scale") ?? 1.0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "scale", Math.round(sliderValue * 100) / 100)
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowMargin.label")
                description: rootSettings?.pluginApi?.tr("settings.windowMargin.desc")
                from: 0
                to: 64
                stepSize: 1
                value: rootSettings?.settingValue("window", "margin") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "margin") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "margin", Math.round(sliderValue))
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowHeight.label")
                description: rootSettings?.pluginApi?.tr("settings.windowHeight.desc")
                from: 0
                to: 200
                stepSize: 1
                value: rootSettings?.settingValue("window", "height") ?? 0
                text: value <= 0 ? rootSettings?.pluginApi?.tr("common.auto") ?? "Auto" : Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("window", "height") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "height", Math.round(sliderValue))
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowRadiusScale.label")
                description: rootSettings?.pluginApi?.tr("settings.windowRadiusScale.desc")
                from: 0
                to: 1.5
                stepSize: 0.05
                value: rootSettings?.settingValue("window", "radiusScale") ?? 1.0
                text: Math.round(value * 100) + "%"
                defaultValue: rootSettings?.defaultValue("window", "radiusScale") ?? 1.0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "radiusScale", Math.round(sliderValue * 100) / 100)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowBackgroundColor.label")
                description: rootSettings?.pluginApi?.tr("settings.windowBackgroundColor.desc")
                currentValue: rootSettings?.settingValue("window", "backgroundColor") ?? "none"
                defaultValue: rootSettings?.defaultValue("window", "backgroundColor") ?? "none"
                onSelected: value => rootSettings?.setSetting("window", "backgroundColor", value)
            }

            NValueSlider {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowBackgroundOpacity.label")
                description: rootSettings?.pluginApi?.tr("settings.windowBackgroundOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("window", "backgroundOpacity") ?? 0
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("window", "backgroundOpacity") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "backgroundOpacity", Math.round(sliderValue))
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowGradientEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.windowGradientEnabled.desc")
                checked: rootSettings?.settingValue("window", "gradientEnabled") ?? false
                onToggled: checked => rootSettings?.setSetting("window", "gradientEnabled", checked)
                defaultValue: rootSettings?.defaultValue("window", "gradientEnabled") ?? false
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["renderModeWindow", "windowGradientEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowGradientColor.label")
                description: rootSettings?.pluginApi?.tr("settings.windowGradientColor.desc")
                currentValue: rootSettings?.settingValue("window", "gradientColor") ?? "none"
                defaultValue: rootSettings?.defaultValue("window", "gradientColor") ?? "none"
                onSelected: value => rootSettings?.setSetting("window", "gradientColor", value)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["renderModeWindow", "windowGradientEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowGradientOpacity.label")
                description: rootSettings?.pluginApi?.tr("settings.windowGradientOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("window", "gradientOpacity") ?? 0
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("window", "gradientOpacity") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("window", "gradientOpacity", Math.round(sliderValue))
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["renderModeWindow", "windowGradientEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.windowGradientDirection.label")
                description: rootSettings?.pluginApi?.tr("settings.windowGradientDirection.desc")
                model: rootSettings?.gradientDirectionModel
                currentKey: rootSettings?.settingValue("window", "gradientDirection") ?? "vertical"
                defaultValue: rootSettings?.defaultValue("window", "gradientDirection") ?? "vertical"
                onSelected: key => rootSettings?.setSetting("window", "gradientDirection", key)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: slotSizeContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: slotSizeContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.slotSize.label")
                description: rootSettings?.pluginApi?.tr("settings.section.slotSize.desc")
            }

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
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: iconsContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: iconsContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.icons.label")
                description: rootSettings?.pluginApi?.tr("settings.section.icons.desc")
            }

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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showSlots", "showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.iconTintColor.label")
                description: rootSettings?.pluginApi?.tr("settings.iconTintColor.desc")
                currentValue: rootSettings?.settingValue("icons", "iconTintColor") ?? "none"
                defaultValue: rootSettings?.defaultValue("icons", "iconTintColor") ?? "none"
                onSelected: value => rootSettings?.setSetting("icons", "iconTintColor", value)
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
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: windowTitleContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: windowTitleContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.windowTitle.label")
                description: rootSettings?.pluginApi?.tr("settings.section.windowTitle.desc")
            }

            NToggle {
                visible: rootSettings?.isVisibleByConditions(["showSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.showTitle.label")
                description: rootSettings?.pluginApi?.tr("settings.showTitle.desc")
                checked: rootSettings?.settingValue("title", "showTitle") ?? true
                onToggled: checked => rootSettings?.setSetting("title", "showTitle", checked)
                defaultValue: rootSettings?.defaultValue("title", "showTitle") ?? true
            }

            NToggle {
                visible: rootSettings?.isVisibleByConditions(["hideSlots"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusedTitleEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.focusedTitleEnabled.desc")
                checked: rootSettings?.settingValue("focusedTitle", "enabled") ?? false
                onToggled: checked => rootSettings?.setSetting("focusedTitle", "enabled", checked)
                defaultValue: rootSettings?.defaultValue("focusedTitle", "enabled") ?? false
            }

            NSearchableComboBox {
                visible: (rootSettings?.isVisibleByConditions(["showSlots", "showTitle"]) ?? false) || (rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? false)
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.titleFontFamily.label")
                description: rootSettings?.pluginApi?.tr("settings.titleFontFamily.desc")
                model: FontService.availableFonts
                currentKey: rootSettings?.settingValue("title", "titleFontFamily") ?? ""
                defaultValue: rootSettings?.defaultValue("title", "titleFontFamily") ?? ""
                onSelected: key => rootSettings?.setSetting("title", "titleFontFamily", key)
            }

            NValueSlider {
                visible: (rootSettings?.isVisibleByConditions(["showSlots", "showTitle"]) ?? false) || (rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? false)
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
                visible: (rootSettings?.isVisibleByConditions(["showSlots", "showTitle"]) ?? false) || (rootSettings?.isVisibleByConditions(["hideSlots", "focusedTitleEnabled"]) ?? false)
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.titleFontWeight.label")
                description: rootSettings?.pluginApi?.tr("settings.titleFontWeight.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.settingValue("title", "titleFontWeight") ?? "default"
                defaultValue: rootSettings?.defaultValue("title", "titleFontWeight") ?? "default"
                onSelected: key => rootSettings?.setSetting("title", "titleFontWeight", key)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: workspaceIndicatorContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: workspaceIndicatorContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.label")
                description: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.desc")
            }

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
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: edgeFadeContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: edgeFadeContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.edgeFade.label")
                description: rootSettings?.pluginApi?.tr("settings.section.edgeFade.desc")
            }

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
        }
    }
}
