import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
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
  property bool valueShowTrackLine: cfg.showTrackLine ?? defaults.showTrackLine ?? true
  property string valueAccentColor: cfg.accentColor ?? defaults.accentColor ?? "primary"
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
  property int valueUnfocusedFillOpacity: cfg.unfocusedFillOpacity ?? defaults.unfocusedFillOpacity ?? 8
  property int valueUnfocusedBorderOpacity: cfg.unfocusedBorderOpacity ?? defaults.unfocusedBorderOpacity ?? 45
  property int valueTrackOpacity: cfg.trackOpacity ?? defaults.trackOpacity ?? 35
  property bool valueShowFocusLine: cfg.showFocusLine ?? defaults.showFocusLine ?? true
  property string valueFocusLineColor: cfg.focusLineColor ?? defaults.focusLineColor ?? "secondary"
  property int valueFocusLineOpacity: cfg.focusLineOpacity ?? defaults.focusLineOpacity ?? 96
  property int valueFocusLineThickness: cfg.focusLineThickness ?? defaults.focusLineThickness ?? 2
  property int valueFocusLineAnimationMs: cfg.focusLineAnimationMs ?? defaults.focusLineAnimationMs ?? 120

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
    pluginApi.pluginSettings.showTrackLine = root.valueShowTrackLine;
    pluginApi.pluginSettings.accentColor = root.valueAccentColor;
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
    pluginApi.pluginSettings.unfocusedFillOpacity = root.valueUnfocusedFillOpacity;
    pluginApi.pluginSettings.unfocusedBorderOpacity = root.valueUnfocusedBorderOpacity;
    pluginApi.pluginSettings.trackOpacity = root.valueTrackOpacity;
    pluginApi.pluginSettings.showFocusLine = root.valueShowFocusLine;
    pluginApi.pluginSettings.focusLineColor = root.valueFocusLineColor;
    pluginApi.pluginSettings.focusLineOpacity = root.valueFocusLineOpacity;
    pluginApi.pluginSettings.focusLineThickness = root.valueFocusLineThickness;
    pluginApi.pluginSettings.focusLineAnimationMs = root.valueFocusLineAnimationMs;
    pluginApi.saveSettings();
  }

  NTabBar {
    id: tabBar
    Layout.fillWidth: true
    distributeEvenly: true
    currentIndex: tabView.currentIndex

    NTabButton {
      text: pluginApi?.tr("settings.tabs.behavior")
      tabIndex: 0
      checked: tabView.currentIndex === 0
      onClicked: tabView.currentIndex = 0
    }

    NTabButton {
      text: pluginApi?.tr("settings.tabs.layout")
      tabIndex: 1
      checked: tabView.currentIndex === 1
      onClicked: tabView.currentIndex = 1
    }

    NTabButton {
      text: pluginApi?.tr("settings.tabs.style")
      tabIndex: 2
      checked: tabView.currentIndex === 2
      onClicked: tabView.currentIndex = 2
    }
  }

  NTabView {
    id: tabView
    Layout.fillWidth: true

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

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

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.enableReorder.label")
        description: pluginApi?.tr("settings.enableReorder.desc")
        checked: root.valueEnableReorder
        onToggled: checked => root.valueEnableReorder = checked
        defaultValue: defaults.enableReorder ?? true
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.debugLogging.label")
        description: pluginApi?.tr("settings.debugLogging.desc")
        checked: root.valueDebugLogging
        onToggled: checked => root.valueDebugLogging = checked
        defaultValue: defaults.debugLogging ?? false
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

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
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.marginM

      NColorChoice {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.accentColor.label")
        description: pluginApi?.tr("settings.accentColor.desc")
        currentKey: root.valueAccentColor
        onSelected: key => root.valueAccentColor = key
      }

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
        label: pluginApi?.tr("settings.section.trackLines")
      }

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
