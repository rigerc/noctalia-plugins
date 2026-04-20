import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

PopupWindow {
    id: root

    property var model: []
    signal triggered(string action, var item)

    property ShellScreen screen: null
    property var anchorItem: null
    property bool isSubMenu: false

    // Stable base position, set once in showAt() before making visible.
    // Live bindings below clamp these against the screen edges.
    property real anchorX: 0
    property real anchorY: 0

    // Convenience: set these before calling openAtItem() (PanelService compat)
    property real targetOffsetX: 0
    property real targetOffsetY: 0

    readonly property int menuWidth: 220

    implicitWidth: menuWidth
    implicitHeight: Math.min(screen?.height * 0.9 ?? 600, flickable.contentHeight + Style.margin2S)

    // Re-anchor when content height resolves (mirrors TrayMenu pattern)
    onImplicitHeightChanged: {
        if (visible && anchorItem)
            Qt.callLater(() => anchor.updateAnchor());
    }

    visible: false
    color: "transparent"
    anchor.item: anchorItem

    // Live bindings clamp anchorX/Y against screen edges.
    // Using live bindings (not pre-calculated) so they recompute when
    // implicitHeight changes after layout resolves.
    anchor.rect.x: {
        if (!anchorItem || !screen)
            return anchorX;

        if (isSubMenu)
            return anchorItem.width;

        const g = anchorItem.mapToItem(null, 0, 0);
        let x = anchorX;
        const menuRight = g.x + x + implicitWidth;
        const menuLeft = g.x + x;
        if (menuRight > screen.width - Style.marginM)
            x -= menuRight - (screen.width - Style.marginM);
        else if (menuLeft < Style.marginM)
            x += Style.marginM - menuLeft;
        return x;
    }

    anchor.rect.y: {
        if (!anchorItem || !screen)
            return anchorY;

        if (isSubMenu)
            return 0;

        const g = anchorItem.mapToItem(null, 0, 0);
        let y = anchorY;
        const menuBottom = g.y + y + implicitHeight;
        if (menuBottom > screen.height - Style.marginM)
            y -= menuBottom - (screen.height - Style.marginM);
        return y;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    function showAt(item, x, y) {
        if (!item)
            return;
        anchorItem = item;
        anchorX = x;
        anchorY = y;
        visible = true;
        forceActiveFocus();
        Qt.callLater(() => anchor.updateAnchor());
    }

    // Compatibility shim for PanelService.showContextMenu()
    function openAtItem(item, itemScreen, centerOnItem) {
        if (itemScreen)
            screen = itemScreen;
        showAt(centerOnItem ?? item, targetOffsetX, targetOffsetY);
    }

    function hideMenu() {
        visible = false;
        hoverTimer.stop();
        pendingSubMenuTarget = null;
        for (var i = 0; i < columnLayout.children.length; i++) {
            const child = columnLayout.children[i];
            if (child?.subMenu) {
                child.subMenu.hideMenu();
                child.subMenu.destroy();
                child.subMenu = null;
            }
        }
    }

    // ── Submenu hover timer ───────────────────────────────────────────────────

    property var pendingSubMenuTarget: null

    Timer {
        id: hoverTimer
        interval: 150
        onTriggered: pendingSubMenuTarget?.openSubMenu()
    }

    // ── Keyboard ──────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent
        Keys.onEscapePressed: root.hideMenu()
    }

    // ── Background ────────────────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: Math.max(1, Style.borderS)
        radius: Style.radiusM
        opacity: root.visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutQuad
            }
        }
    }

    // ── Menu content ──────────────────────────────────────────────────────────

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
                model: root.model

                delegate: Rectangle {
                    id: entry
                    required property var modelData

                    Layout.preferredWidth: parent.width
                    Layout.preferredHeight: {
                        if (modelData?.visible === false)
                            return 0;
                        if (modelData?.isSeparator === true)
                            return 8;
                        return 28;
                    }

                    visible: modelData?.visible !== false
                    color: "transparent"
                    property var subMenu: null

                    NDivider {
                        anchors.centerIn: parent
                        width: parent.width - Style.margin2M
                        visible: modelData?.isSeparator === true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: mouseArea.containsMouse ? Color.mHover : "transparent"
                        radius: Style.radiusS
                        visible: modelData?.isSeparator !== true && modelData?.visible !== false
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
                                visible: !!modelData?.icon
                                icon: modelData?.icon ?? ""
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
                                Layout.fillWidth: true
                                text: modelData?.label ?? modelData?.text ?? ""
                                pointSize: Style.fontSizeS
                                color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Style.animationFast
                                    }
                                }
                            }

                            NIcon {
                                visible: modelData?.hasChildren ?? false
                                icon: "menu"
                                pointSize: Style.fontSizeS
                                applyUiScale: false
                                verticalAlignment: Text.AlignVCenter
                                color: mouseArea.containsMouse ? Color.mOnTertiary : Color.mOnSurface
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData?.isSeparator !== true && modelData?.enabled !== false && root.visible
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                            function openSubMenu() {
                                if (!modelData?.hasChildren)
                                    return;

                                // Close sibling submenus
                                for (var i = 0; i < columnLayout.children.length; i++) {
                                    const sib = columnLayout.children[i];
                                    if (sib !== entry && sib.subMenu) {
                                        sib.subMenu.hideMenu();
                                        sib.subMenu.destroy();
                                        sib.subMenu = null;
                                    }
                                }

                                entry.subMenu = Qt.createComponent("ScrollbarContextMenu.qml").createObject(root, {
                                    model: modelData.children ?? [],
                                    screen: root.screen,
                                    isSubMenu: true,
                                    anchorItem: entry,
                                    anchorX: entry.width,
                                    anchorY: 0
                                });

                                if (entry.subMenu) {
                                    entry.subMenu.triggered.connect(root.triggered);
                                    entry.subMenu.visible = true;
                                    Qt.callLater(() => entry.subMenu?.anchor.updateAnchor());
                                }
                            }

                            onEntered: {
                                for (var i = 0; i < columnLayout.children.length; i++) {
                                    const sib = columnLayout.children[i];
                                    if (sib !== entry && sib.subMenu) {
                                        sib.subMenu.hideMenu();
                                        sib.subMenu.destroy();
                                        sib.subMenu = null;
                                    }
                                }
                                if (modelData?.hasChildren && !entry.subMenu) {
                                    root.pendingSubMenuTarget = mouseArea;
                                    hoverTimer.restart();
                                }
                            }

                            onExited: {
                                if (root.pendingSubMenuTarget === mouseArea) {
                                    hoverTimer.stop();
                                    root.pendingSubMenuTarget = null;
                                }
                            }

                            onClicked: {
                                if (!modelData || modelData.isSeparator || modelData.enabled === false)
                                    return;
                                if (modelData.hasChildren) {
                                    hoverTimer.stop();
                                    root.pendingSubMenuTarget = null;
                                    if (!entry.subMenu)
                                        openSubMenu();
                                } else {
                                    root.triggered(modelData.action ?? modelData.key ?? "", modelData);
                                    root.hideMenu();
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
}
