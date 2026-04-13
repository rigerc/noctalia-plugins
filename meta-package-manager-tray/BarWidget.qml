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
  readonly property string countColorKey: cfg.countColor ?? defaults.countColor ?? "secondary"
  readonly property string errorColorKey: cfg.errorColor ?? defaults.errorColor ?? "destructive"

  readonly property color normalIconColor: resolveColor(iconColorKey, Color.mPrimary)
  readonly property color normalCountColor: resolveColor(countColorKey, Color.mOnSurface)
  readonly property color errorColor: resolveColor(errorColorKey, Color.resolveColorKey("destructive"))
  readonly property bool showCount: !(mainInstance?.isRefreshing ?? false) && (mainInstance?.mpmAvailable ?? false)
  readonly property color contentColor: (mainInstance?.hasError ?? false) || !(mainInstance?.mpmAvailable ?? false)
    ? errorColor
    : normalIconColor
  readonly property color countColor: (mainInstance?.hasError ?? false) || !(mainInstance?.mpmAvailable ?? false)
    ? errorColor
    : normalCountColor

  readonly property real contentWidth: capsuleRow.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

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

    RowLayout {
      id: capsuleRow
      anchors.centerIn: parent
      spacing: Style.marginS

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
        visible: root.showCount
        text: String(mainInstance?.totalUpdateCount ?? 0)
        color: root.hovered ? Color.mOnHover : root.countColor
        pointSize: root.barFontSize
        applyUiScale: false
        font.weight: Font.Bold
      }
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
}
