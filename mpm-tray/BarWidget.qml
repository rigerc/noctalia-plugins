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

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property bool hideOnZero: cfg.hideOnZero ?? defaults.hideOnZero ?? false
    readonly property bool isRefreshing: mainInstance?.isRefreshing ?? false
    readonly property int updateCount: mainInstance?.totalUpdateCount ?? 0
    readonly property bool hasError: mainInstance?.hasError ?? false
    readonly property bool mpmAvailable: mainInstance?.mpmAvailable ?? false

    readonly property color iconColor: {
        if (!root.mpmAvailable || root.hasError)
            return Color.resolveColorKey("destructive");
        if (root.updateCount > 0)
            return Color.mPrimary;
        return Color.mOnSurface;
    }

    readonly property real contentWidth: {
        if (root.isVertical)
            return root.capsuleHeight;
        var w = Style.marginM * 2 + iconSize.implicitWidth;
        if (root.updateCount > 0 || root.isRefreshing)
            w += Style.marginS + countText.implicitWidth;
        return w;
    }
    readonly property real contentHeight: {
        if (!root.isVertical)
            return root.capsuleHeight;
        var h = Style.marginM * 2 + iconSize.implicitHeight;
        if (root.updateCount > 0 || root.isRefreshing)
            h += Style.marginS + countText.implicitHeight;
        return h;
    }

    implicitWidth: root.isVertical ? root.capsuleHeight : root.contentWidth
    implicitHeight: root.isVertical ? root.contentHeight : root.capsuleHeight

    visible: !(root.hideOnZero && root.updateCount === 0 && !root.isRefreshing)

    NPopupContextMenu {
        id: contextMenu
        model: [
            { "label": root.pluginApi?.tr("menu.refresh"), "action": "refresh", "icon": "refresh" },
            { "label": root.pluginApi?.tr("menu.settings"), "action": "settings", "icon": "settings" }
        ]
        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);
            if (action === "refresh") {
                root.mainInstance?.refresh("manual");
            } else if (action === "settings") {
                BarService.openPluginSettings(root.screen, root.pluginApi.manifest);
            }
        }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on width {
            NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
        }
        Behavior on height {
            NumberAnimation { duration: Style.animationNormal; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.centerIn: parent
            visible: !root.isVertical
            spacing: Style.marginS

            Item {
                id: iconSize
                readonly property real iconPt: Style.toOdd(root.capsuleHeight * 0.48)
                implicitWidth: iconPt
                implicitHeight: iconPt
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    visible: !root.isRefreshing
                    source: Qt.resolvedUrl("assets/icon.svg")
                    sourceSize: Qt.size(parent.iconPt, parent.iconPt)
                    fillMode: Image.PreserveAspectFit
                }

                NIcon {
                    anchors.centerIn: parent
                    visible: root.isRefreshing
                    icon: "loader"
                    color: mouseArea.containsMouse ? Color.mOnHover : root.iconColor
                    pointSize: parent.iconPt
                    applyUiScale: false

                    RotationAnimation on rotation {
                        running: root.isRefreshing
                        from: 0; to: 360; duration: 1200; loops: Animation.Infinite
                    }
                }
            }

            NText {
                id: countText
                visible: root.updateCount > 0 || root.isRefreshing
                text: root.isRefreshing ? "" : String(root.updateCount)
                color: mouseArea.containsMouse ? Color.mOnHover : root.iconColor
                pointSize: root.barFontSize
                applyUiScale: false
                Layout.alignment: Qt.AlignVCenter
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: root.isVertical
            spacing: Style.marginS

            Item {
                readonly property real iconPt: Style.toOdd(root.capsuleHeight * 0.48)
                implicitWidth: iconPt
                implicitHeight: iconPt
                Layout.alignment: Qt.AlignHCenter

                Image {
                    anchors.fill: parent
                    visible: !root.isRefreshing
                    source: Qt.resolvedUrl("assets/icon.svg")
                    sourceSize: Qt.size(parent.iconPt, parent.iconPt)
                    fillMode: Image.PreserveAspectFit
                }

                NIcon {
                    anchors.centerIn: parent
                    visible: root.isRefreshing
                    icon: "loader"
                    color: mouseArea.containsMouse ? Color.mOnHover : root.iconColor
                    pointSize: parent.iconPt
                    applyUiScale: false

                    RotationAnimation on rotation {
                        running: root.isRefreshing
                        from: 0; to: 360; duration: 1200; loops: Animation.Infinite
                    }
                }
            }

            NText {
                visible: root.updateCount > 0 || root.isRefreshing
                text: root.isRefreshing ? "" : String(root.updateCount)
                color: mouseArea.containsMouse ? Color.mOnHover : root.iconColor
                pointSize: root.barFontSize
                applyUiScale: false
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.pluginApi)
                    root.pluginApi.togglePanel(root.screen, root);
            } else if (mouse.button === Qt.MiddleButton) {
                root.mainInstance?.refresh("manual");
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, root.screen);
            }
        }

        onEntered: {
            TooltipService.show(root, root.buildTooltip(),
                BarService.getTooltipDirection(root.screenName));
        }

        onExited: TooltipService.hide()
    }

    function buildTooltip() {
        if (root.isRefreshing)
            return pluginApi?.tr("tooltip.checkingNow") ?? "";
        if (!root.mpmAvailable && (mainInstance?.mpmPath ?? "") !== "")
            return pluginApi?.tr("tooltip.mpmBroken") ?? "";
        if (!root.mpmAvailable)
            return pluginApi?.tr("tooltip.mpmMissing") ?? "";
        if (root.hasError && root.updateCount === 0)
            return pluginApi?.tr("tooltip.genericError") ?? "";
        if (root.updateCount === 0)
            return pluginApi?.tr("tooltip.noUpdates") ?? "";
        return pluginApi?.tr("tooltip.updatesAvailable", { "count": root.updateCount }) ?? "";
    }
}
