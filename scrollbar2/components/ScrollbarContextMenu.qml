import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// Context menu with submenu and separator support for scrollbar2
// Based on NPopupContextMenu with enhancements from TrayMenu.qml
PopupWindow {
  id: root

  property alias model: repeater.model
  property real itemHeight: 28
  property real itemPadding: Style.marginM
  property int verticalPolicy: ScrollBar.AsNeeded
  property int horizontalPolicy: ScrollBar.AsNeeded

  property var anchorItem: null
  property ShellScreen screen: null
  property real minWidth: 120
  property real calculatedWidth: 180

  // For submenu support
  property bool isSubMenu: false
  property var parentMenu: null
  property var _subMenuComponent: null

  // Explicit offset for centering on target item (used by main menu via openAtItem)
  property real targetOffsetX: 0
  property real targetOffsetY: 0
  property real targetWidth: 0
  property real targetHeight: 0

  // Direct anchor offset for submenus (simpler positioning)
  property real anchorX: 0
  property real anchorY: 0

  // Hover timer for submenu delay
  property var pendingSubMenuTarget: null

  function _ensureSubMenuComponent() {
    if (root._subMenuComponent)
      return root._subMenuComponent;

    root._subMenuComponent = Qt.createComponent(Qt.resolvedUrl("ScrollbarContextMenu.qml"));
    if (root._subMenuComponent.status === Component.Error) {
      Logger.e("ScrollbarContextMenu", "Failed to load submenu component: " + root._subMenuComponent.errorString());
      root._subMenuComponent = null;
      return null;
    }
    return root._subMenuComponent;
  }

  readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
  readonly property real barHeight: Style.getBarHeightForScreen(screen?.name)

  signal triggered(string action, var item)

  implicitWidth: calculatedWidth
  implicitHeight: Math.min(600, flickable.contentHeight + Style.margin2S)
  visible: false
  color: "transparent"

  NText {
    id: textMeasure
    visible: false
    pointSize: Style.fontSizeS
    wrapMode: Text.NoWrap
    elide: Text.ElideNone
    width: undefined
  }

  NIcon {
    id: iconMeasure
    visible: false
    icon: "bell"
    pointSize: Style.fontSizeS
    applyUiScale: false
  }

  onModelChanged: Qt.callLater(calculateWidth)

  function calculateWidth() {
    let maxWidth = 0;
    if (model && model.length) {
      for (let i = 0; i < model.length; i++) {
        const item = model[i];
        if (item && item.visible !== false && !item.isSeparator) {
          const label = item.label || item.text || "";
          textMeasure.text = label;
          textMeasure.forceLayout();

          let itemWidth = textMeasure.contentWidth + 8;

          if (item.icon !== undefined) {
            itemWidth += iconMeasure.width + Style.marginS;
          }

          // Add space for submenu arrow if hasChildren
          if (item.hasChildren) {
            itemWidth += 16;
          }

          itemWidth += Style.margin2M;

          if (itemWidth > maxWidth) {
            maxWidth = itemWidth;
          }
        }
      }
    }
    calculatedWidth = Math.max(maxWidth + Style.margin2S, minWidth);
  }

  anchor.item: anchorItem

  // Positioning logic (same as NPopupContextMenu, with submenu support)
  anchor.rect.x: {
    if (anchorItem && screen) {
      // For submenus, use direct anchorX offset
      if (isSubMenu) {
        return anchorX;
      }

      const anchorGlobalPos = anchorItem.mapToItem(null, 0, 0);
      const effectiveWidth = targetWidth > 0 ? targetWidth : anchorItem.width;
      const targetGlobalX = anchorGlobalPos.x + targetOffsetX;

      if (root.barPosition === "right") {
        let baseX = targetOffsetX - implicitWidth - Style.marginM;
        return baseX;
      }

      if (root.barPosition === "left") {
        let baseX = targetOffsetX + effectiveWidth + Style.marginM;
        return baseX;
      }

      const targetCenterScreenX = targetGlobalX + (effectiveWidth / 2);
      const menuScreenX = targetCenterScreenX - (implicitWidth / 2);
      let baseX = menuScreenX - anchorGlobalPos.x;

      const menuRight = menuScreenX + implicitWidth;

      if (menuRight > screen.width - Style.marginM) {
        const overflow = menuRight - (screen.width - Style.marginM);
        return baseX - overflow;
      }
      if (menuScreenX < Style.marginM) {
        return baseX + (Style.marginM - menuScreenX);
      }
      return baseX;
    }
    return 0;
  }

  anchor.rect.y: {
    if (anchorItem && screen) {
      // For submenus, use direct anchorY offset (align top with parent)
      if (isSubMenu) {
        return anchorY;
      }

      const isAbsolutePosition = anchorItem.width <= 1 && anchorItem.height <= 1;

      if (isAbsolutePosition) {
        const anchorGlobalPos = anchorItem.mapToItem(null, 0, 0);
        const menuBottom = anchorGlobalPos.y + implicitHeight;

        if (menuBottom > screen.height - Style.marginM) {
          return -implicitHeight;
        }
        return 0;
      }

      const anchorGlobalPos = anchorItem.mapToItem(null, 0, 0);
      const effectiveHeight = targetHeight > 0 ? targetHeight : anchorItem.height;
      const effectiveOffsetY = targetOffsetY;

      let baseY;
      if (root.barPosition === "bottom") {
        baseY = -(implicitHeight + Style.marginS);
      } else if (root.barPosition === "top") {
        baseY = barHeight + Style.marginS - anchorGlobalPos.y;
      } else {
        const targetCenterY = effectiveOffsetY + (effectiveHeight / 2);
        baseY = targetCenterY - (implicitHeight / 2);
      }

      const menuScreenY = anchorGlobalPos.y + baseY;
      const menuBottom = menuScreenY + implicitHeight;

      const topLimit = Style.marginM;
      const bottomLimit = root.barPosition === "bottom" ? screen.height - barHeight - Style.marginS : screen.height - Style.marginM;

      if (menuScreenY < topLimit && root.barPosition !== "bottom") {
        const adjustment = topLimit - menuScreenY;
        return baseY + adjustment;
      }

      if (menuBottom > bottomLimit) {
        const overflow = menuBottom - bottomLimit;
        return baseY - overflow;
      }

      return baseY;
    }

    if (root.barPosition === "bottom") {
      return -implicitHeight - Style.marginS;
    }
    return barHeight;
  }

  Component.onCompleted: Qt.callLater(calculateWidth)

  Timer {
    id: hoverTimer
    interval: 150
    onTriggered: {
      if (pendingSubMenuTarget)
        pendingSubMenuTarget.openSubMenu();
    }
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: root.closeMenu()
  }

  Rectangle {
    id: menuBackground
    anchors.fill: parent
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: Style.borderS
    radius: Style.radiusM
    opacity: root.visible ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutQuad
      }
    }
  }

  Flickable {
    id: flickable
    anchors.fill: parent
    anchors.margins: Style.marginS
    contentHeight: columnLayout.implicitHeight
    interactive: true
    opacity: root.visible ? 1.0 : 0.0

    Behavior on opacity {
      NumberAnimation {
        duration: Style.animationNormal
        easing.type: Easing.OutQuad
      }
    }

    ColumnLayout {
      id: columnLayout
      width: flickable.width
      spacing: 0

      Repeater {
        id: repeater

        delegate: Rectangle {
          id: menuItem
          required property var modelData
          required property int index

          Layout.preferredWidth: parent.width
          Layout.preferredHeight: {
            if (modelData?.isSeparator) {
              return 8;
            }
            const textHeight = textMeasure.contentHeight || (Style.fontSizeS * 1.2);
            return Math.max(root.itemHeight, textHeight + Style.margin2S);
          }
          visible: modelData?.visible !== false
          color: "transparent"

          property var subMenu: null

          function openSubMenu() {
            // Close any other open submenus first
            for (var i = 0; i < columnLayout.children.length; i++) {
              const sibling = columnLayout.children[i];
              if (sibling !== menuItem && sibling.subMenu) {
                sibling.subMenu.closeMenu();
                sibling.subMenu.destroy();
                sibling.subMenu = null;
              }
            }

            // Determine submenu opening direction
            let openLeft = false;
            const barPosition = Settings.getBarPositionForScreen(root.screen?.name);

            if (barPosition === "right") {
              openLeft = true;
            } else if (barPosition === "left") {
              openLeft = false;
            } else {
              // For top/bottom bars, open left if menu is on right side of screen
              const globalPos = menuItem.mapToItem(null, 0, 0);
              openLeft = (globalPos.x > root.screen.width / 2);
            }

            // Create and show submenu
            const component = root._ensureSubMenuComponent();
            if (!component || component.status !== Component.Ready)
              return;

            menuItem.subMenu = component.createObject(root, {
              "model": modelData.children || [],
              "isSubMenu": true,
              "parentMenu": root,
              "screen": root.screen,
              "anchorItem": menuItem
            });

            if (menuItem.subMenu) {
              // Position submenu relative to parent item
              // Positive anchorX = open to right, Negative = open to left
              menuItem.subMenu.anchorX = openLeft ? -4 : menuItem.width - 4;
              menuItem.subMenu.anchorY = 0;  // Align top with parent item
              menuItem.subMenu.visible = true;
              // Connect submenu triggered to parent
              menuItem.subMenu.triggered.connect(root.triggered);
            } else {
              Logger.w("ScrollbarContextMenu", "Failed to create submenu object.");
            }
          }

          // Separator rendering
          NDivider {
            anchors.centerIn: parent
            width: parent.width - Style.margin2M
            visible: modelData?.isSeparator ?? false
          }

          Rectangle {
            id: innerRect
            anchors.fill: parent
            color: mouseArea.containsMouse ? Color.mHover : "transparent"
            radius: Style.radiusS
            visible: !(modelData?.isSeparator ?? false)
            opacity: modelData?.enabled !== false ? 1.0 : 0.5

            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Style.marginM
              anchors.rightMargin: Style.marginM
              spacing: Style.marginS

              NIcon {
                visible: modelData?.icon !== undefined && !modelData?.isSeparator
                icon: modelData?.icon || ""
                pointSize: Style.fontSizeS
                applyUiScale: false
                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
                verticalAlignment: Text.AlignVCenter

                Behavior on color {
                  ColorAnimation {
                    duration: Style.animationFast
                  }
                }
              }

              NText {
                id: itemText
                text: modelData?.label || modelData?.text || ""
                pointSize: Style.fontSizeS
                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
                verticalAlignment: Text.AlignVCenter
                Layout.fillWidth: true
                visible: !modelData?.isSeparator

                Behavior on color {
                  ColorAnimation {
                    duration: Style.animationFast
                  }
                }
              }

              // Submenu arrow indicator
              NIcon {
                visible: modelData?.hasChildren ?? false
                icon: "chevron-right"
                pointSize: Style.fontSizeXXS
                applyUiScale: false
                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurfaceVariant
                verticalAlignment: Text.AlignVCenter
              }
            }

            MouseArea {
              id: mouseArea
              anchors.fill: parent
              hoverEnabled: true
              enabled: (modelData?.enabled !== false) && !(modelData?.isSeparator ?? false) && root.visible
              cursorShape: Qt.PointingHandCursor
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onEntered: {
                if (modelData && modelData.hasChildren && !menuItem.subMenu) {
                  root.pendingSubMenuTarget = menuItem;
                  hoverTimer.restart();
                }
              }

              onExited: {
                hoverTimer.stop();
                root.pendingSubMenuTarget = null;
              }

              onClicked: mouse => {
                if (modelData && !modelData.isSeparator) {
                  if (modelData.hasChildren) {
                    // Toggle submenu
                    if (menuItem.subMenu) {
                      // Close existing submenu
                      menuItem.subMenu.closeMenu();
                      menuItem.subMenu.destroy();
                      menuItem.subMenu = null;
                    } else {
                      // Open submenu
                      menuItem.openSubMenu();
                    }
                  } else {
                    // Regular menu item - trigger action
                    const action = modelData.action || modelData.key || menuItem.index.toString();
                    if (isSubMenu) {
                      // For submenus, delay closing to let parent triggered signal complete
                      root.triggered(action, modelData);
                      Qt.callLater(function() { root.closeMenu(); });
                    } else {
                      // For main menu, close immediately
                      root.triggered(action, modelData);
                      root.closeMenu();
                    }
                  }
                }
              }
            }
          }

          Component.onDestruction: {
            if (subMenu) {
              subMenu.destroy();
              subMenu = null;
            }
          }
        }
      }
    }
  }

  function openAtItem(item, itemScreen, centerOnItem) {
    if (!item) {
      Logger.w("ScrollbarContextMenu", "anchorItem is undefined, won't show menu.");
      return;
    }

    anchorItem = item;
    screen = itemScreen || null;

    if (centerOnItem && centerOnItem !== item) {
      const relPos = centerOnItem.mapToItem(item, 0, 0);
      targetOffsetX = relPos.x;
      targetOffsetY = relPos.y;
      targetWidth = centerOnItem.width;
      targetHeight = centerOnItem.height;
    } else {
      targetOffsetX = 0;
      targetOffsetY = 0;
      targetWidth = 0;
      targetHeight = 0;
    }

    calculateWidth();
    visible = true;

    Qt.callLater(() => {
      anchor.updateAnchor();
    });
  }

  function close() {
    visible = false;
  }

  function closeMenu() {
    // Close all submenus first
    for (var i = 0; i < columnLayout.children.length; i++) {
      const child = columnLayout.children[i];
      if (child && child.subMenu) {
        child.subMenu.closeMenu();
        child.subMenu.destroy();
        child.subMenu = null;
      }
    }
    close();
  }
}
