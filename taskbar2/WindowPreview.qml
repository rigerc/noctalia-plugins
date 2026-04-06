import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

PopupWindow {
    id: root

    property var anchorItem: null
    property var targetWindow: null
    property var _toplevel: null
    property bool livePreview: true
    property real previewWidth: 320 * Style.uiScaleRatio
    property real previewHeight: 180 * Style.uiScaleRatio
    property real hoverDelayMs: 200
    property string windowTitle: ""

    visible: false
    color: "transparent"
    implicitWidth: previewWidth
    implicitHeight: previewHeight

    readonly property real radius: Style.radiusL
    readonly property real titleBarHeight: Style.fontSizeS * 1.5 + Style.marginS * 2

    property real _anchorX: 0
    property real _anchorY: 0

    Timer {
        id: showTimer
        interval: root.hoverDelayMs
        repeat: false
        onTriggered: root._doShow()
    }

    function requestShow(item, windowObj, title) {
        showTimer.stop();
        if (!item || !windowObj)
            return;
        root.anchorItem = item;
        root.targetWindow = windowObj;
        root.windowTitle = title || "";
        root._toplevel = null;
        root._computePosition();
        showTimer.start();
    }

    function hide() {
        showTimer.stop();
        root._toplevel = null;
        root.anchorItem = null;
        root.targetWindow = null;
        root.visible = false;
    }

    function _doShow() {
        if (!root.targetWindow || !root.anchorItem) {
            root.visible = false;
            return;
        }
        try {
            var w = root.anchorItem.width;
            if (typeof w !== "number" || w <= 0) {
                root.visible = false;
                return;
            }
        } catch (e) {
            root.visible = false;
            return;
        }
        root._toplevel = resolveToplevel(root.targetWindow);
        root.anchor.item = root.anchorItem;
        root.anchor.rect.x = root._anchorX;
        root.anchor.rect.y = root._anchorY;
        root.visible = true;
        Qt.callLater(function () {
            try {
                root.anchor.updateAnchor();
            } catch (e) {}
        });
    }

    function _computePosition() {
        if (!root.anchorItem)
            return;
        try {
            var barPos = Settings.getBarPositionForScreen(root.anchorItem.screen?.name || "");
        } catch (e) {
            barPos = "bottom";
        }
        var iw = root.anchorItem.width;
        var ih = root.anchorItem.height;
        var pw = root.previewWidth;
        var ph = root.previewHeight;
        var gap = Style.marginS;

        switch (barPos) {
        case "top":
            root._anchorX = (iw - pw) / 2;
            root._anchorY = ih + gap;
            break;
        case "bottom":
            root._anchorX = (iw - pw) / 2;
            root._anchorY = -ph - gap;
            break;
        case "left":
            root._anchorX = iw + gap;
            root._anchorY = (ih - ph) / 2;
            break;
        case "right":
            root._anchorX = -pw - gap;
            root._anchorY = (ih - ph) / 2;
            break;
        default:
            root._anchorX = (iw - pw) / 2;
            root._anchorY = -ph - gap;
            break;
        }
    }

    function resolveToplevel(windowObj) {
        if (!windowObj)
            return null;

        if (windowObj.handle)
            return windowObj.handle;
        if (windowObj.toplevel)
            return windowObj.toplevel;

        var wId = windowObj.id || "";
        var wTitle = windowObj.title || "";
        var wAppId = windowObj.appId || "";
        var wOutput = windowObj.output || "";

        try {
            var tmToplevels = ToplevelManager?.toplevels?.values;
            if (tmToplevels && tmToplevels.length > 0) {
                for (var i = 0; i < tmToplevels.length; i++) {
                    var tl = tmToplevels[i];
                    if (!tl)
                        continue;
                    var tlAppId = tl.appId || "";
                    var tlTitle = tl.title || "";
                    var tlScreens = tl.screens || [];
                    var tlScreenName = (tlScreens.length > 0 && tlScreens[0].name) ? tlScreens[0].name : "";

                    if (tlAppId && wAppId && tlAppId === wAppId) {
                        if (wOutput && tlScreenName && wOutput === tlScreenName) {
                            if (!tlTitle || tlTitle === wTitle || !wTitle)
                                return tl;
                        } else if (!wOutput || !tlScreenName) {
                            if (!tlTitle || tlTitle === wTitle || !wTitle)
                                return tl;
                        }
                    }
                }
            }
        } catch (e) {}

        try {
            if (typeof Hyprland !== "undefined" && Hyprland.toplevels) {
                var hlToplevels = Hyprland.toplevels.values;
                if (hlToplevels && hlToplevels.length > 0 && wId) {
                    for (var j = 0; j < hlToplevels.length; j++) {
                        var htl = hlToplevels[j];
                        if (!htl)
                            continue;
                        var htlAddr = htl.address || "";
                        if (htlAddr === wId || htlAddr === "0x" + wId || wId === "0x" + htlAddr)
                            return htl;
                    }
                }
            }
        } catch (e) {}

        return null;
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: root.radius
        color: Color.mSurface
        border.color: Color.mOutline
        border.width: Style.borderS
        clip: true
        opacity: root._scale

        Rectangle {
            id: titleBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.titleBarHeight
            color: Color.mSurface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.marginS
                anchors.rightMargin: Style.marginS
                anchors.topMargin: Style.marginXS
                anchors.bottomMargin: Style.marginXS
                spacing: Style.marginS

                NText {
                    Layout.fillWidth: true
                    text: root.windowTitle
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    color: Color.mOnSurface
                    pointSize: Style.fontSizeS
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Qt.alpha(Color.mOutline, 0.5)
            }
        }

        Item {
            id: previewArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: titleBar.bottom
            anchors.bottom: parent.bottom
            clip: true

            Loader {
                anchors.fill: parent
                active: root.visible && root._toplevel
                sourceComponent: Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.textureSize: Qt.size(root.previewWidth * 2, root.previewHeight * 2)

                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: root._toplevel
                        live: root.livePreview
                    }
                }
            }

            Loader {
                anchors.fill: parent
                active: root.visible && !root._toplevel && root.targetWindow
                sourceComponent: ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Style.marginS

                    Image {
                        Layout.alignment: Qt.AlignHCenter
                        source: Quickshell.iconPath(root.targetWindow.appId || "application-x-executable", "image-missing")
                        sourceSize.width: Math.round(previewArea.height * 0.3)
                        sourceSize.height: Math.round(previewArea.height * 0.3)
                    }

                    NText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.leftMargin: Style.marginM
                        Layout.rightMargin: Style.marginM
                        text: root.windowTitle
                        elide: Text.ElideMiddle
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        color: Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeXS
                    }
                }
            }
        }
    }
}
