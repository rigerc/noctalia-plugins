import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  property bool hovered: false

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property string iconName: cfg.iconName ?? defaults.iconName ?? "package"
  readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "primary"
  readonly property bool showCountTextSetting: cfg.showCountText ?? defaults.showCountText ?? true
  readonly property string countTextPosition: normalizeCountTextPosition(cfg.countTextPosition ?? defaults.countTextPosition ?? "right")
  readonly property string countTextFontFamily: cfg.countTextFontFamily ?? defaults.countTextFontFamily ?? ""
  readonly property string countTextFontWeightKey: normalizeCountTextFontWeight(cfg.countTextFontWeight ?? defaults.countTextFontWeight ?? "bold")
  readonly property real countTextScale: normalizeCountTextScale(cfg.countTextScale ?? defaults.countTextScale ?? 1.0)
  readonly property string countColorKey: cfg.countColor ?? defaults.countColor ?? "secondary"
  readonly property string errorColorKey: cfg.errorColor ?? defaults.errorColor ?? "destructive"
  readonly property string countPlacement: isVertical
    ? (countTextPosition === "left" ? "top" : "bottom")
    : countTextPosition

  readonly property color normalIconColor: resolveColor(iconColorKey, Color.mPrimary)
  readonly property color normalCountColor: resolveColor(countColorKey, Color.mOnSurface)
  readonly property color errorColor: resolveColor(errorColorKey, Color.resolveColorKey("destructive"))
  readonly property bool showCount: showCountTextSetting
    && !(mainInstance?.isRefreshing ?? false)
    && (mainInstance?.mpmAvailable ?? false)
  readonly property color contentColor: (mainInstance?.hasError ?? false) || !(mainInstance?.mpmAvailable ?? false)
    ? errorColor
    : normalIconColor
  readonly property color countColor: (mainInstance?.hasError ?? false) || !(mainInstance?.mpmAvailable ?? false)
    ? errorColor
    : normalCountColor
  readonly property real countPointSize: Math.max(Style.fontSizeXS, barFontSize * countTextScale)

  readonly property real contentWidth: isVertical
    ? capsuleHeight
    : (contentLoader.item?.implicitWidth ?? 0) + Style.marginM * 2
  readonly property real contentHeight: isVertical
    ? (contentLoader.item?.implicitHeight ?? 0) + Style.marginM * 2
    : capsuleHeight

  implicitWidth: isVertical ? capsuleHeight : contentWidth
  implicitHeight: isVertical ? contentHeight : capsuleHeight

  NPopupContextMenu {
    id: contextMenu
    model: [
      {
        "label": pluginApi?.tr("menu.refresh"),
        "action": "refresh",
        "icon": "refresh"
      },
      {
        "label": pluginApi?.tr("menu.runUpgrades"),
        "action": "upgrade",
        "icon": "terminal-2",
        "enabled": mainInstance?.canRunUpgrade ?? false
      },
      {
        "label": pluginApi?.tr("menu.settings"),
        "action": "settings",
        "icon": "settings"
      }
    ]

    onTriggered: action => {
      contextMenu.close();
      PanelService.closeContextMenu(screen);

      if (action === "refresh") {
        mainInstance?.manualRefresh();
      } else if (action === "upgrade") {
        mainInstance?.upgrade();
      } else if (action === "settings") {
        BarService.openPluginSettings(screen, pluginApi.manifest);
      }
    }
  }

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: root.hovered ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    Loader {
      id: contentLoader
      anchors.centerIn: parent
      sourceComponent: root.isVertical ? verticalContentComponent : horizontalContentComponent
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      root.hovered = true;
      TooltipService.show(root, root.buildTooltip(), BarService.getTooltipDirection(root.screenName));
    }

    onExited: {
      root.hovered = false;
      TooltipService.hide();
    }

    onClicked: mouse => {
      TooltipService.hide();

      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) pluginApi.togglePanel(root.screen, root);
      } else if (mouse.button === Qt.MiddleButton) {
        mainInstance?.manualRefresh();
      } else if (mouse.button === Qt.RightButton) {
        PanelService.showContextMenu(contextMenu, root, screen);
      }
    }
  }

  function buildTooltip() {
    if (mainInstance?.isRefreshing) {
      return pluginApi?.tr("tooltip.checkingNow");
    }

    if (!(mainInstance?.mpmAvailable ?? false)) {
      return mainInstance?.mpmPath
        ? pluginApi?.tr("tooltip.mpmBroken")
        : pluginApi?.tr("tooltip.mpmMissing");
    }

    if ((mainInstance?.activeManagerIds?.length ?? 0) === 0) {
      return pluginApi?.tr("tooltip.noEnabledManagers");
    }

    if ((mainInstance?.hasError ?? false) && (mainInstance?.totalUpdateCount ?? 0) === 0) {
      return pluginApi?.tr("tooltip.genericError");
    }

    if ((mainInstance?.totalUpdateCount ?? 0) === 0) {
      return pluginApi?.tr("tooltip.noUpdates");
    }

    return pluginApi?.tr("tooltip.updatesAvailable", {
      "count": mainInstance?.totalUpdateCount ?? 0
    });
  }

  function resolveColor(key, fallbackColor) {
    if (!key || key === "none") return fallbackColor;
    return Color.resolveColorKey(key);
  }

  function fontWeightForKey(key) {
    switch (key) {
    case "regular":
      return Style.fontWeightRegular;
    case "medium":
      return Style.fontWeightMedium;
    case "semibold":
      return Style.fontWeightSemiBold;
    case "bold":
    default:
      return Style.fontWeightBold;
    }
  }

  function normalizeCountTextPosition(value) {
    return value === "left" ? "left" : "right";
  }

  function normalizeCountTextFontWeight(value) {
    switch (value) {
    case "regular":
    case "medium":
    case "semibold":
    case "bold":
      return value;
    default:
      return "bold";
    }
  }

  function normalizeCountTextScale(value) {
    var numericValue = Number(value);

    if (isNaN(numericValue)) return 1.0;
    return Math.max(0.8, Math.min(1.6, numericValue));
  }

  Component {
    id: horizontalContentComponent

    RowLayout {
      spacing: Style.marginS

      NText {
        visible: root.showCount && root.countPlacement === "left"
        text: String(mainInstance?.totalUpdateCount ?? 0)
        color: root.hovered ? Color.mOnHover : root.countColor
        pointSize: root.countPointSize
        applyUiScale: false
        font.family: root.countTextFontFamily !== "" ? root.countTextFontFamily : Qt.application.font.family
        font.weight: root.fontWeightForKey(root.countTextFontWeightKey)
      }

      NIcon {
        id: statusIcon
        icon: mainInstance?.isRefreshing ? "loader" : root.iconName
        color: root.hovered ? Color.mOnHover : root.contentColor

        RotationAnimation on rotation {
          running: mainInstance?.isRefreshing ?? false
          from: 0
          to: 360
          duration: 1000
          loops: Animation.Infinite
        }

        Binding {
          target: statusIcon
          property: "rotation"
          value: 0
          when: !(mainInstance?.isRefreshing ?? false)
        }
      }

      NText {
        visible: root.showCount && root.countPlacement === "right"
        text: String(mainInstance?.totalUpdateCount ?? 0)
        color: root.hovered ? Color.mOnHover : root.countColor
        pointSize: root.countPointSize
        applyUiScale: false
        font.family: root.countTextFontFamily !== "" ? root.countTextFontFamily : Qt.application.font.family
        font.weight: root.fontWeightForKey(root.countTextFontWeightKey)
      }
    }
  }

  Component {
    id: verticalContentComponent

    ColumnLayout {
      spacing: Style.marginXS

      NText {
        visible: root.showCount && root.countPlacement === "top"
        text: String(mainInstance?.totalUpdateCount ?? 0)
        color: root.hovered ? Color.mOnHover : root.countColor
        pointSize: root.countPointSize
        applyUiScale: false
        font.family: root.countTextFontFamily !== "" ? root.countTextFontFamily : Qt.application.font.family
        font.weight: root.fontWeightForKey(root.countTextFontWeightKey)
        Layout.alignment: Qt.AlignHCenter
      }

      NIcon {
        id: statusIcon
        icon: mainInstance?.isRefreshing ? "loader" : root.iconName
        color: root.hovered ? Color.mOnHover : root.contentColor
        Layout.alignment: Qt.AlignHCenter

        RotationAnimation on rotation {
          running: mainInstance?.isRefreshing ?? false
          from: 0
          to: 360
          duration: 1000
          loops: Animation.Infinite
        }

        Binding {
          target: statusIcon
          property: "rotation"
          value: 0
          when: !(mainInstance?.isRefreshing ?? false)
        }
      }

      NText {
        visible: root.showCount && root.countPlacement === "bottom"
        text: String(mainInstance?.totalUpdateCount ?? 0)
        color: root.hovered ? Color.mOnHover : root.countColor
        pointSize: root.countPointSize
        applyUiScale: false
        font.family: root.countTextFontFamily !== "" ? root.countTextFontFamily : Qt.application.font.family
        font.weight: root.fontWeightForKey(root.countTextFontWeightKey)
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }
}
