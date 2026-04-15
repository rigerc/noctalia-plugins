import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property real preferredWidth: 720 * Style.uiScaleRatio

    property bool valueOnlySameOutput: cfg.onlySameOutput ?? defaults.onlySameOutput ?? true
    property bool valueOnlyActiveWorkspaces: cfg.onlyActiveWorkspaces ?? defaults.onlyActiveWorkspaces ?? true
    property bool valueEnableReorder: cfg.enableReorder ?? defaults.enableReorder ?? true
    property bool valueDebugLogging: cfg.debugLogging ?? defaults.debugLogging ?? false
    property int valueMaxWidgetWidth: cfg.maxWidgetWidth ?? defaults.maxWidgetWidth ?? 40
    property int valueSlotWidth: cfg.slotWidth ?? defaults.slotWidth ?? 112
    property bool valueShowTitle: cfg.showTitle ?? defaults.showTitle ?? true
    property real valueIconScale: cfg.iconScale ?? defaults.iconScale ?? 0.8
    property int valueEdgeFadeSize: cfg.edgeFadeSize ?? defaults.edgeFadeSize ?? 18
    property real valueEdgeFadeMidpoint: cfg.edgeFadeMidpoint ?? defaults.edgeFadeMidpoint ?? 0.45
    property int valueEdgeFadeMidOpacity: cfg.edgeFadeMidOpacity ?? defaults.edgeFadeMidOpacity ?? 40
    property bool valueShowTrackLine: cfg.showTrackLine ?? defaults.showTrackLine ?? true
    property string valueTrackThumbColor: cfg.trackThumbColor ?? defaults.trackThumbColor ?? "primary"
    property int valueInactiveOpacity: cfg.inactiveOpacity ?? defaults.inactiveOpacity ?? 45
    property int valueSlotSpacingUnits: cfg.slotSpacingUnits ?? defaults.slotSpacingUnits ?? 1
    property real valueRadiusScale: cfg.radiusScale ?? defaults.radiusScale ?? 1.0
    property string valueHoverFillColor: cfg.hoverFillColor ?? defaults.hoverFillColor ?? "hover"
    property string valueHoverBorderColor: cfg.hoverBorderColor ?? defaults.hoverBorderColor ?? "outline"
    property string valueHoverTextColor: cfg.hoverTextColor ?? defaults.hoverTextColor ?? "on-hover"
    property int valueHoverFillOpacity: cfg.hoverFillOpacity ?? defaults.hoverFillOpacity ?? 55
    property real valueHoverScalePercent: cfg.hoverScalePercent ?? defaults.hoverScalePercent ?? 2.5
    property int valueHoverTransitionDurationMs: cfg.hoverTransitionDurationMs ?? defaults.hoverTransitionDurationMs ?? 120
    property int valueFocusedFillOpacity: cfg.focusedFillOpacity ?? defaults.focusedFillOpacity ?? 92
    property string valueFocusedFillColor: cfg.focusedFillColor ?? defaults.focusedFillColor ?? "primary"
    property string valueFocusedBorderColor: cfg.focusedBorderColor ?? defaults.focusedBorderColor ?? "primary"
    property string valueFocusedTextColor: cfg.focusedTextColor ?? defaults.focusedTextColor ?? "on-primary"
    property bool valueShowFocusedFill: cfg.showFocusedFill ?? defaults.showFocusedFill ?? true
    property int valueUnfocusedFillOpacity: cfg.unfocusedFillOpacity ?? defaults.unfocusedFillOpacity ?? 8
    property int valueUnfocusedBorderOpacity: cfg.unfocusedBorderOpacity ?? defaults.unfocusedBorderOpacity ?? 45
    property string valueUnfocusedFillColor: cfg.unfocusedFillColor ?? defaults.unfocusedFillColor ?? "surface-variant"
    property string valueUnfocusedBorderColor: cfg.unfocusedBorderColor ?? defaults.unfocusedBorderColor ?? "outline"
    property string valueUnfocusedTextColor: cfg.unfocusedTextColor ?? defaults.unfocusedTextColor ?? "on-surface"
    property bool valueShowUnfocusedFill: cfg.showUnfocusedFill ?? defaults.showUnfocusedFill ?? true
    property bool valueShowFocusedBorder: cfg.showFocusedBorder ?? defaults.showFocusedBorder ?? true
    property int valueFocusedBorderOpacity: cfg.focusedBorderOpacity ?? defaults.focusedBorderOpacity ?? 100
    property bool valueShowHoverBorder: cfg.showHoverBorder ?? defaults.showHoverBorder ?? true
    property int valueHoverBorderOpacity: cfg.hoverBorderOpacity ?? defaults.hoverBorderOpacity ?? 100
    property bool valueShowUnfocusedBorder: cfg.showUnfocusedBorder ?? defaults.showUnfocusedBorder ?? true
    property int valueTrackOpacity: cfg.trackOpacity ?? defaults.trackOpacity ?? 35
    property bool valueShowFocusLine: cfg.showFocusLine ?? defaults.showFocusLine ?? true
    property string valueFocusLineColor: cfg.focusLineColor ?? defaults.focusLineColor ?? "secondary"
    property int valueFocusLineOpacity: cfg.focusLineOpacity ?? defaults.focusLineOpacity ?? 96
    property int valueFocusLineThickness: cfg.focusLineThickness ?? defaults.focusLineThickness ?? 2
    property int valueFocusLineAnimationMs: cfg.focusLineAnimationMs ?? defaults.focusLineAnimationMs ?? 120
    property bool valueCenterFocusedWindow: cfg.centerFocusedWindow ?? defaults.centerFocusedWindow ?? true
    property int valueCenterAnimationMs: cfg.centerAnimationMs ?? defaults.centerAnimationMs ?? 200
    property bool valueShowIcons: cfg.showIcons ?? defaults.showIcons ?? true
    property string valueTitleFontFamily: cfg.titleFontFamily ?? defaults.titleFontFamily ?? ""
    property int valueTitleFontSize: cfg.titleFontSize ?? defaults.titleFontSize ?? 0
    property string valueTitleFontWeight: cfg.titleFontWeight ?? defaults.titleFontWeight ?? "default"
    property string valueIconTintColor: cfg.iconTintColor ?? defaults.iconTintColor ?? "none"
    property int valueIconTintOpacity: cfg.iconTintOpacity ?? defaults.iconTintOpacity ?? 100
    property string valueBackgroundColor: cfg.backgroundColor ?? defaults.backgroundColor ?? "none"
    property int valueBackgroundOpacity: cfg.backgroundOpacity ?? defaults.backgroundOpacity ?? 0

    readonly property var fontWeightModel: ListModel {
        ListElement { key: "default"; name: "Default" }
        ListElement { key: "light"; name: "Light" }
        ListElement { key: "normal"; name: "Normal" }
        ListElement { key: "medium"; name: "Medium" }
        ListElement { key: "semibold"; name: "Semibold" }
        ListElement { key: "bold"; name: "Bold" }
    }

    spacing: Style.marginM
    implicitWidth: preferredWidth

    function saveSettings() {
        if (!pluginApi)
            return;

        pluginApi.pluginSettings.onlySameOutput = root.valueOnlySameOutput;
        pluginApi.pluginSettings.onlyActiveWorkspaces = root.valueOnlyActiveWorkspaces;
        pluginApi.pluginSettings.enableReorder = root.valueEnableReorder;
        pluginApi.pluginSettings.debugLogging = root.valueDebugLogging;
        pluginApi.pluginSettings.maxWidgetWidth = root.valueMaxWidgetWidth;
        pluginApi.pluginSettings.slotWidth = root.valueSlotWidth;
        pluginApi.pluginSettings.showTitle = root.valueShowTitle;
        pluginApi.pluginSettings.iconScale = root.valueIconScale;
        pluginApi.pluginSettings.edgeFadeSize = root.valueEdgeFadeSize;
        pluginApi.pluginSettings.edgeFadeMidpoint = root.valueEdgeFadeMidpoint;
        pluginApi.pluginSettings.edgeFadeMidOpacity = root.valueEdgeFadeMidOpacity;
        pluginApi.pluginSettings.showTrackLine = root.valueShowTrackLine;
        pluginApi.pluginSettings.trackThumbColor = root.valueTrackThumbColor;
        pluginApi.pluginSettings.inactiveOpacity = root.valueInactiveOpacity;
        pluginApi.pluginSettings.slotSpacingUnits = root.valueSlotSpacingUnits;
        pluginApi.pluginSettings.radiusScale = root.valueRadiusScale;
        pluginApi.pluginSettings.hoverFillColor = root.valueHoverFillColor;
        pluginApi.pluginSettings.hoverBorderColor = root.valueHoverBorderColor;
        pluginApi.pluginSettings.hoverTextColor = root.valueHoverTextColor;
        pluginApi.pluginSettings.hoverFillOpacity = root.valueHoverFillOpacity;
        pluginApi.pluginSettings.hoverScalePercent = root.valueHoverScalePercent;
        pluginApi.pluginSettings.hoverTransitionDurationMs = root.valueHoverTransitionDurationMs;
        pluginApi.pluginSettings.focusedFillOpacity = root.valueFocusedFillOpacity;
        pluginApi.pluginSettings.focusedFillColor = root.valueFocusedFillColor;
        pluginApi.pluginSettings.focusedBorderColor = root.valueFocusedBorderColor;
        pluginApi.pluginSettings.focusedTextColor = root.valueFocusedTextColor;
        pluginApi.pluginSettings.showFocusedFill = root.valueShowFocusedFill;
        pluginApi.pluginSettings.unfocusedFillOpacity = root.valueUnfocusedFillOpacity;
        pluginApi.pluginSettings.unfocusedBorderOpacity = root.valueUnfocusedBorderOpacity;
        pluginApi.pluginSettings.unfocusedFillColor = root.valueUnfocusedFillColor;
        pluginApi.pluginSettings.unfocusedBorderColor = root.valueUnfocusedBorderColor;
        pluginApi.pluginSettings.unfocusedTextColor = root.valueUnfocusedTextColor;
        pluginApi.pluginSettings.showUnfocusedFill = root.valueShowUnfocusedFill;
        pluginApi.pluginSettings.showFocusedBorder = root.valueShowFocusedBorder;
        pluginApi.pluginSettings.focusedBorderOpacity = root.valueFocusedBorderOpacity;
        pluginApi.pluginSettings.showHoverBorder = root.valueShowHoverBorder;
        pluginApi.pluginSettings.hoverBorderOpacity = root.valueHoverBorderOpacity;
        pluginApi.pluginSettings.showUnfocusedBorder = root.valueShowUnfocusedBorder;
        pluginApi.pluginSettings.trackOpacity = root.valueTrackOpacity;
        pluginApi.pluginSettings.showFocusLine = root.valueShowFocusLine;
        pluginApi.pluginSettings.focusLineColor = root.valueFocusLineColor;
        pluginApi.pluginSettings.focusLineOpacity = root.valueFocusLineOpacity;
        pluginApi.pluginSettings.focusLineThickness = root.valueFocusLineThickness;
        pluginApi.pluginSettings.focusLineAnimationMs = root.valueFocusLineAnimationMs;
        pluginApi.pluginSettings.centerFocusedWindow = root.valueCenterFocusedWindow;
        pluginApi.pluginSettings.centerAnimationMs = root.valueCenterAnimationMs;
        pluginApi.pluginSettings.showIcons = root.valueShowIcons;
        pluginApi.pluginSettings.titleFontFamily = root.valueTitleFontFamily;
        pluginApi.pluginSettings.titleFontSize = root.valueTitleFontSize;
        pluginApi.pluginSettings.titleFontWeight = root.valueTitleFontWeight;
        pluginApi.pluginSettings.iconTintColor = root.valueIconTintColor;
        pluginApi.pluginSettings.iconTintOpacity = root.valueIconTintOpacity;
        pluginApi.pluginSettings.backgroundColor = root.valueBackgroundColor;
        pluginApi.pluginSettings.backgroundOpacity = root.valueBackgroundOpacity;
        pluginApi.saveSettings();
    }

    NTabBar {
        id: tabBar
        Layout.fillWidth: true
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            text: pluginApi?.tr("settings.tabs.general")
            tabIndex: 0
            checked: tabView.currentIndex === 0
            onClicked: tabView.currentIndex = 0
        }

        NTabButton {
            text: pluginApi?.tr("settings.tabs.behavior")
            tabIndex: 1
            checked: tabView.currentIndex === 1
            onClicked: tabView.currentIndex = 1
        }

        NTabButton {
            text: pluginApi?.tr("settings.tabs.appearance")
            tabIndex: 2
            checked: tabView.currentIndex === 2
            onClicked: tabView.currentIndex = 2
        }
    }

    NTabView {
        id: tabView
        Layout.fillWidth: true

        // ── General ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.filtering.label")
                description: pluginApi?.tr("settings.section.filtering.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.onlySameOutput.label")
                description: pluginApi?.tr("settings.onlySameOutput.desc")
                checked: root.valueOnlySameOutput
                onToggled: checked => root.valueOnlySameOutput = checked
                defaultValue: defaults.onlySameOutput ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.onlyActiveWorkspaces.label")
                description: pluginApi?.tr("settings.onlyActiveWorkspaces.desc")
                checked: root.valueOnlyActiveWorkspaces
                onToggled: checked => root.valueOnlyActiveWorkspaces = checked
                defaultValue: defaults.onlyActiveWorkspaces ?? true
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.debug.label")
                description: pluginApi?.tr("settings.section.debug.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.debugLogging.label")
                description: pluginApi?.tr("settings.debugLogging.desc")
                checked: root.valueDebugLogging
                onToggled: checked => root.valueDebugLogging = checked
                defaultValue: defaults.debugLogging ?? false
            }
        }

        // ── Behavior ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.interaction.label")
                description: pluginApi?.tr("settings.section.interaction.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.enableReorder.label")
                description: pluginApi?.tr("settings.enableReorder.desc")
                checked: root.valueEnableReorder
                onToggled: checked => root.valueEnableReorder = checked
                defaultValue: defaults.enableReorder ?? true
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.scrollCentering.label")
                description: pluginApi?.tr("settings.section.scrollCentering.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.centerFocusedWindow.label")
                description: pluginApi?.tr("settings.centerFocusedWindow.desc")
                checked: root.valueCenterFocusedWindow
                onToggled: checked => root.valueCenterFocusedWindow = checked
                defaultValue: defaults.centerFocusedWindow ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.centerAnimationMs.label")
                description: pluginApi?.tr("settings.centerAnimationMs.desc")
                from: 0
                to: 500
                stepSize: 10
                value: root.valueCenterAnimationMs
                text: Math.round(root.valueCenterAnimationMs) + " ms"
                defaultValue: defaults.centerAnimationMs ?? 200
                showReset: true
                onMoved: value => root.valueCenterAnimationMs = Math.round(value)
            }
        }

        // ── Appearance ──
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.slotLayout.label")
                description: pluginApi?.tr("settings.section.slotLayout.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showIcons.label")
                description: pluginApi?.tr("settings.showIcons.desc")
                checked: root.valueShowIcons
                onToggled: checked => root.valueShowIcons = checked
                defaultValue: defaults.showIcons ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.maxWidgetWidth.label")
                description: pluginApi?.tr("settings.maxWidgetWidth.desc")
                from: 20
                to: 100
                stepSize: 1
                value: root.valueMaxWidgetWidth
                text: Math.round(root.valueMaxWidgetWidth) + "%"
                defaultValue: defaults.maxWidgetWidth ?? 40
                showReset: true
                onMoved: value => root.valueMaxWidgetWidth = Math.round(value)
            }

            NValueSlider {
                label: pluginApi?.tr("settings.slotWidth.label")
                description: pluginApi?.tr("settings.slotWidth.desc")
                from: 72
                to: 220
                stepSize: 4
                value: root.valueSlotWidth
                text: Math.round(root.valueSlotWidth) + " px"
                defaultValue: defaults.slotWidth ?? 112
                showReset: true
                onMoved: value => root.valueSlotWidth = Math.round(value)
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showTitle.label")
                description: pluginApi?.tr("settings.showTitle.desc")
                checked: root.valueShowTitle
                onToggled: checked => root.valueShowTitle = checked
                defaultValue: defaults.showTitle ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.iconScale.label")
                description: pluginApi?.tr("settings.iconScale.desc")
                from: 0.5
                to: 1.2
                stepSize: 0.05
                value: root.valueIconScale
                text: Math.round(root.valueIconScale * 100) + "%"
                defaultValue: defaults.iconScale ?? 0.8
                showReset: true
                onMoved: value => root.valueIconScale = Math.round(value * 100) / 100
            }

            NValueSlider {
                label: pluginApi?.tr("settings.slotSpacingUnits.label")
                description: pluginApi?.tr("settings.slotSpacingUnits.desc")
                from: 0
                to: 6
                stepSize: 1
                value: root.valueSlotSpacingUnits
                text: Math.round(root.valueSlotSpacingUnits).toString()
                defaultValue: defaults.slotSpacingUnits ?? 1
                showReset: true
                onMoved: value => root.valueSlotSpacingUnits = Math.round(value)
            }

            NValueSlider {
                label: pluginApi?.tr("settings.radiusScale.label")
                description: pluginApi?.tr("settings.radiusScale.desc")
                from: 0.5
                to: 1.5
                stepSize: 0.05
                value: root.valueRadiusScale
                text: Math.round(root.valueRadiusScale * 100) + "%"
                defaultValue: defaults.radiusScale ?? 1.0
                showReset: true
                onMoved: value => root.valueRadiusScale = Math.round(value * 100) / 100
            }

            NValueSlider {
                label: pluginApi?.tr("settings.edgeFadeSize.label")
                description: pluginApi?.tr("settings.edgeFadeSize.desc")
                from: 0
                to: 48
                stepSize: 1
                value: root.valueEdgeFadeSize
                text: Math.round(root.valueEdgeFadeSize) + " px"
                defaultValue: defaults.edgeFadeSize ?? 18
                showReset: true
                onMoved: value => root.valueEdgeFadeSize = Math.round(value)
            }

            NValueSlider {
                label: pluginApi?.tr("settings.edgeFadeMidpoint.label")
                description: pluginApi?.tr("settings.edgeFadeMidpoint.desc")
                from: 0.05
                to: 0.95
                stepSize: 0.05
                value: root.valueEdgeFadeMidpoint
                text: Math.round(root.valueEdgeFadeMidpoint * 100) + "%"
                defaultValue: defaults.edgeFadeMidpoint ?? 0.45
                showReset: true
                onMoved: value => root.valueEdgeFadeMidpoint = Math.round(value * 100) / 100
            }

            NValueSlider {
                label: pluginApi?.tr("settings.edgeFadeMidOpacity.label")
                description: pluginApi?.tr("settings.edgeFadeMidOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueEdgeFadeMidOpacity
                text: Math.round(root.valueEdgeFadeMidOpacity) + "%"
                defaultValue: defaults.edgeFadeMidOpacity ?? 40
                showReset: true
                onMoved: value => root.valueEdgeFadeMidOpacity = Math.round(value)
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.iconTintColor.label")
                description: pluginApi?.tr("settings.iconTintColor.desc")
                currentKey: root.valueIconTintColor
                onSelected: key => root.valueIconTintColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.iconTintOpacity.label")
                description: pluginApi?.tr("settings.iconTintOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueIconTintOpacity
                text: Math.round(root.valueIconTintOpacity) + "%"
                defaultValue: defaults.iconTintOpacity ?? 100
                showReset: true
                onMoved: value => root.valueIconTintOpacity = Math.round(value)
            }

            NSearchableComboBox {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.titleFontFamily.label")
                description: pluginApi?.tr("settings.titleFontFamily.desc")
                model: FontService.availableFonts
                currentKey: root.valueTitleFontFamily
                defaultValue: defaults.titleFontFamily ?? ""
                onSelected: key => root.valueTitleFontFamily = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.titleFontSize.label")
                description: pluginApi?.tr("settings.titleFontSize.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.valueTitleFontSize
                text: root.valueTitleFontSize === 0 ? "Auto" : (Math.round(root.valueTitleFontSize) + " pt")
                defaultValue: defaults.titleFontSize ?? 0
                showReset: true
                onMoved: value => root.valueTitleFontSize = Math.round(value)
            }

            NSearchableComboBox {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.titleFontWeight.label")
                description: pluginApi?.tr("settings.titleFontWeight.desc")
                model: root.fontWeightModel
                currentKey: root.valueTitleFontWeight
                defaultValue: defaults.titleFontWeight ?? "default"
                onSelected: key => root.valueTitleFontWeight = key
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.background.label")
                description: pluginApi?.tr("settings.section.background.desc")
            }
            NDivider {}

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.backgroundColor.label")
                description: pluginApi?.tr("settings.backgroundColor.desc")
                currentKey: root.valueBackgroundColor
                onSelected: key => root.valueBackgroundColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.backgroundOpacity.label")
                description: pluginApi?.tr("settings.backgroundOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueBackgroundOpacity
                text: Math.round(root.valueBackgroundOpacity) + "%"
                defaultValue: defaults.backgroundOpacity ?? 0
                showReset: true
                onMoved: value => root.valueBackgroundOpacity = Math.round(value)
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.focusedSlot.label")
                description: pluginApi?.tr("settings.section.focusedSlot.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showFocusedFill.label")
                description: pluginApi?.tr("settings.showFocusedFill.desc")
                checked: root.valueShowFocusedFill
                onToggled: checked => root.valueShowFocusedFill = checked
                defaultValue: defaults.showFocusedFill ?? true
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusedFillColor.label")
                description: pluginApi?.tr("settings.focusedFillColor.desc")
                currentKey: root.valueFocusedFillColor
                onSelected: key => root.valueFocusedFillColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.focusedFillOpacity.label")
                description: pluginApi?.tr("settings.focusedFillOpacity.desc")
                from: 20
                to: 100
                stepSize: 1
                value: root.valueFocusedFillOpacity
                text: Math.round(root.valueFocusedFillOpacity) + "%"
                defaultValue: defaults.focusedFillOpacity ?? 92
                showReset: true
                onMoved: value => root.valueFocusedFillOpacity = Math.round(value)
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusedBorderColor.label")
                description: pluginApi?.tr("settings.focusedBorderColor.desc")
                currentKey: root.valueFocusedBorderColor
                onSelected: key => root.valueFocusedBorderColor = key
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showFocusedBorder.label")
                description: pluginApi?.tr("settings.showFocusedBorder.desc")
                checked: root.valueShowFocusedBorder
                onToggled: checked => root.valueShowFocusedBorder = checked
                defaultValue: defaults.showFocusedBorder ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.focusedBorderOpacity.label")
                description: pluginApi?.tr("settings.focusedBorderOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueFocusedBorderOpacity
                text: Math.round(root.valueFocusedBorderOpacity) + "%"
                defaultValue: defaults.focusedBorderOpacity ?? 100
                showReset: true
                onMoved: value => root.valueFocusedBorderOpacity = Math.round(value)
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusedTextColor.label")
                description: pluginApi?.tr("settings.focusedTextColor.desc")
                currentKey: root.valueFocusedTextColor
                onSelected: key => root.valueFocusedTextColor = key
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.unfocusedSlot.label")
                description: pluginApi?.tr("settings.section.unfocusedSlot.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showUnfocusedFill.label")
                description: pluginApi?.tr("settings.showUnfocusedFill.desc")
                checked: root.valueShowUnfocusedFill
                onToggled: checked => root.valueShowUnfocusedFill = checked
                defaultValue: defaults.showUnfocusedFill ?? true
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.unfocusedFillColor.label")
                description: pluginApi?.tr("settings.unfocusedFillColor.desc")
                currentKey: root.valueUnfocusedFillColor
                onSelected: key => root.valueUnfocusedFillColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.unfocusedFillOpacity.label")
                description: pluginApi?.tr("settings.unfocusedFillOpacity.desc")
                from: 0
                to: 60
                stepSize: 1
                value: root.valueUnfocusedFillOpacity
                text: Math.round(root.valueUnfocusedFillOpacity) + "%"
                defaultValue: defaults.unfocusedFillOpacity ?? 8
                showReset: true
                onMoved: value => root.valueUnfocusedFillOpacity = Math.round(value)
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.unfocusedBorderColor.label")
                description: pluginApi?.tr("settings.unfocusedBorderColor.desc")
                currentKey: root.valueUnfocusedBorderColor
                onSelected: key => root.valueUnfocusedBorderColor = key
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showUnfocusedBorder.label")
                description: pluginApi?.tr("settings.showUnfocusedBorder.desc")
                checked: root.valueShowUnfocusedBorder
                onToggled: checked => root.valueShowUnfocusedBorder = checked
                defaultValue: defaults.showUnfocusedBorder ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.unfocusedBorderOpacity.label")
                description: pluginApi?.tr("settings.unfocusedBorderOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueUnfocusedBorderOpacity
                text: Math.round(root.valueUnfocusedBorderOpacity) + "%"
                defaultValue: defaults.unfocusedBorderOpacity ?? 45
                showReset: true
                onMoved: value => root.valueUnfocusedBorderOpacity = Math.round(value)
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.unfocusedTextColor.label")
                description: pluginApi?.tr("settings.unfocusedTextColor.desc")
                currentKey: root.valueUnfocusedTextColor
                onSelected: key => root.valueUnfocusedTextColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.inactiveOpacity.label")
                description: pluginApi?.tr("settings.inactiveOpacity.desc")
                from: 10
                to: 100
                stepSize: 1
                value: root.valueInactiveOpacity
                text: Math.round(root.valueInactiveOpacity) + "%"
                defaultValue: defaults.inactiveOpacity ?? 45
                showReset: true
                onMoved: value => root.valueInactiveOpacity = Math.round(value)
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.hoveredSlot.label")
                description: pluginApi?.tr("settings.section.hoveredSlot.desc")
            }
            NDivider {}

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.hoverFillColor.label")
                description: pluginApi?.tr("settings.hoverFillColor.desc")
                currentKey: root.valueHoverFillColor
                onSelected: key => root.valueHoverFillColor = key
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.hoverBorderColor.label")
                description: pluginApi?.tr("settings.hoverBorderColor.desc")
                currentKey: root.valueHoverBorderColor
                onSelected: key => root.valueHoverBorderColor = key
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.hoverTextColor.label")
                description: pluginApi?.tr("settings.hoverTextColor.desc")
                currentKey: root.valueHoverTextColor
                onSelected: key => root.valueHoverTextColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.hoverFillOpacity.label")
                description: pluginApi?.tr("settings.hoverFillOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueHoverFillOpacity
                text: Math.round(root.valueHoverFillOpacity) + "%"
                defaultValue: defaults.hoverFillOpacity ?? 55
                showReset: true
                onMoved: value => root.valueHoverFillOpacity = Math.round(value)
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showHoverBorder.label")
                description: pluginApi?.tr("settings.showHoverBorder.desc")
                checked: root.valueShowHoverBorder
                onToggled: checked => root.valueShowHoverBorder = checked
                defaultValue: defaults.showHoverBorder ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.hoverBorderOpacity.label")
                description: pluginApi?.tr("settings.hoverBorderOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueHoverBorderOpacity
                text: Math.round(root.valueHoverBorderOpacity) + "%"
                defaultValue: defaults.hoverBorderOpacity ?? 100
                showReset: true
                onMoved: value => root.valueHoverBorderOpacity = Math.round(value)
            }

            NValueSlider {
                label: pluginApi?.tr("settings.hoverScalePercent.label")
                description: pluginApi?.tr("settings.hoverScalePercent.desc")
                from: 0
                to: 10
                stepSize: 0.1
                value: root.valueHoverScalePercent
                text: root.valueHoverScalePercent.toFixed(1) + "%"
                defaultValue: defaults.hoverScalePercent ?? 2.5
                showReset: true
                onMoved: value => root.valueHoverScalePercent = Math.round(value * 10) / 10
            }

            NValueSlider {
                label: pluginApi?.tr("settings.hoverTransitionDurationMs.label")
                description: pluginApi?.tr("settings.hoverTransitionDurationMs.desc")
                from: 0
                to: 400
                stepSize: 10
                value: root.valueHoverTransitionDurationMs
                text: Math.round(root.valueHoverTransitionDurationMs) + " ms"
                defaultValue: defaults.hoverTransitionDurationMs ?? 120
                showReset: true
                onMoved: value => root.valueHoverTransitionDurationMs = Math.round(value)
            }

            NHeader {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.section.trackFocusLine.label")
                description: pluginApi?.tr("settings.section.trackFocusLine.desc")
            }
            NDivider {}

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showTrackLine.label")
                description: pluginApi?.tr("settings.showTrackLine.desc")
                checked: root.valueShowTrackLine
                onToggled: checked => root.valueShowTrackLine = checked
                defaultValue: defaults.showTrackLine ?? true
            }

            NValueSlider {
                label: pluginApi?.tr("settings.trackOpacity.label")
                description: pluginApi?.tr("settings.trackOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueTrackOpacity
                text: Math.round(root.valueTrackOpacity) + "%"
                defaultValue: defaults.trackOpacity ?? 35
                showReset: true
                onMoved: value => root.valueTrackOpacity = Math.round(value)
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.trackThumbColor.label")
                description: pluginApi?.tr("settings.trackThumbColor.desc")
                currentKey: root.valueTrackThumbColor
                onSelected: key => root.valueTrackThumbColor = key
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusLine.label")
                description: pluginApi?.tr("settings.focusLine.desc")
                checked: root.valueShowFocusLine
                onToggled: checked => root.valueShowFocusLine = checked
                defaultValue: defaults.showFocusLine ?? true
            }

            NColorChoice {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusLineColor.label")
                description: pluginApi?.tr("settings.focusLineColor.desc")
                currentKey: root.valueFocusLineColor
                onSelected: key => root.valueFocusLineColor = key
            }

            NValueSlider {
                label: pluginApi?.tr("settings.focusLineOpacity.label")
                description: pluginApi?.tr("settings.focusLineOpacity.desc")
                from: 0
                to: 100
                stepSize: 1
                value: root.valueFocusLineOpacity
                text: Math.round(root.valueFocusLineOpacity) + "%"
                defaultValue: defaults.focusLineOpacity ?? 96
                showReset: true
                onMoved: value => root.valueFocusLineOpacity = Math.round(value)
            }

            NValueSlider {
                label: pluginApi?.tr("settings.focusLineThickness.label")
                description: pluginApi?.tr("settings.focusLineThickness.desc")
                from: 1
                to: 6
                stepSize: 1
                value: root.valueFocusLineThickness
                text: Math.round(root.valueFocusLineThickness) + " px"
                defaultValue: defaults.focusLineThickness ?? 2
                showReset: true
                onMoved: value => root.valueFocusLineThickness = Math.round(value)
            }

            NValueSlider {
                label: pluginApi?.tr("settings.focusLineAnimationMs.label")
                description: pluginApi?.tr("settings.focusLineAnimationMs.desc")
                from: 0
                to: 400
                stepSize: 10
                value: root.valueFocusLineAnimationMs
                text: Math.round(root.valueFocusLineAnimationMs) + " ms"
                defaultValue: defaults.focusLineAnimationMs ?? 120
                showReset: true
                onMoved: value => root.valueFocusLineAnimationMs = Math.round(value)
            }
        }
    }
}
