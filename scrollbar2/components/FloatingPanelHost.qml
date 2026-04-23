import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

PanelWindow {
    id: windowHost

    required property var main
    required property ShellScreen hostScreen
    required property var pluginApi

    screen: hostScreen
    focusable: false
    color: "transparent"

    readonly property bool anchorTop: main.trackPosition !== "bottom"
    readonly property real effectiveOffsetH: Math.round(main.displayOffsetH * Style.uiScaleRatio)
    readonly property real effectiveOffsetV: Math.round(main.displayOffsetV * Style.uiScaleRatio)
    readonly property bool autoHideEnabled: main.objectSettingValue("display", "autoHide", "enabled", false) === true
    readonly property string autoHideRevealMode: main.objectSettingValue("display", "autoHide", "revealMode", "edgeSliver")
    readonly property int autoHideDelayMs: Math.max(0, Math.min(5000, Math.round(Number(main.objectSettingValue("display", "autoHide", "delayMs", 1000)))))
    readonly property int autoHideDurationMs: Math.max(0, Math.min(1500, Math.round(Number(main.objectSettingValue("display", "autoHide", "durationMs", 200)))))
    readonly property string autoHideEffect: main.objectSettingValue("display", "autoHide", "effect", "slideFade")
    readonly property bool autoHideDynamicMargin: main.objectSettingValue("display", "autoHide", "dynamicMargin", false) === true
    readonly property string autoHideSlideDirectionSetting: main.objectSettingValue("display", "autoHide", "slideDirection", "auto")
    readonly property bool autoHideSlideEnabled: autoHideEffect === "slideFade" || autoHideEffect === "slide"
    readonly property bool autoHideFadeEnabled: autoHideEffect === "slideFade" || autoHideEffect === "fade"
    readonly property int autoHideEffectiveDurationMs: main.motionAnimationsEnabled && autoHideEffect !== "instant" ? autoHideDurationMs : 0
    readonly property real autoHideCurrentMargin: autoHideEnabled && autoHideDynamicMargin ? Math.round(main.displayMargin * shownProgress) : main.displayMargin
    readonly property real autoHideCurrentOffsetH: autoHideEnabled && autoHideDynamicMargin ? Math.round(effectiveOffsetH * shownProgress) : effectiveOffsetH
    readonly property real autoHideCurrentOffsetV: autoHideEnabled && autoHideDynamicMargin ? Math.round(effectiveOffsetV * shownProgress) : effectiveOffsetV
    readonly property real contentBaseWidth: Math.ceil(windowView.implicitWidth * main.displayScale) + autoHideCurrentMargin * 2
    readonly property real contentBaseHeight: Math.ceil(windowView.implicitHeight * main.displayScale) + autoHideCurrentMargin * 2
    readonly property real contentBaseY: anchorTop ? Math.max(0, autoHideCurrentOffsetV) : Math.max(0, -autoHideCurrentOffsetV)
    readonly property string autoHideResolvedSlideDirection: {
        switch (autoHideSlideDirectionSetting) {
        case "up":
        case "down":
        case "left":
        case "right":
            return autoHideSlideDirectionSetting;
        default:
            return anchorTop ? "up" : "down";
        }
    }
    readonly property string autoHideEdgeSliverColorKey: main.objectSettingValue("display", "autoHide", "edgeSliverColor", "none")
    readonly property real autoHideEdgeSliverOpacity: main.normalizeOpacityValue(main.objectSettingValue("display", "autoHide", "edgeSliverOpacity", 1))
    readonly property real autoHideRevealThickness: Math.max(2, Math.round(Number(main.objectSettingValue("display", "autoHide", "edgeSliverSize", 8)) * Style.uiScaleRatio))
    readonly property real autoHideRevealWidthRatio: Math.max(0.1, Math.min(1, Number(main.objectSettingValue("display", "autoHide", "edgeSliverWidth", 100)) / 100))
    readonly property real autoHideRevealMargin: Math.max(0, Math.round(Number(main.objectSettingValue("display", "autoHide", "edgeSliverMargin", 0)) * Style.uiScaleRatio))
    readonly property real autoHideRevealRadiusSetting: Math.max(0, Math.round(Number(main.objectSettingValue("display", "autoHide", "edgeSliverRadius", 0)) * Style.uiScaleRatio))
    readonly property real autoHideHoverThickness: Math.max(autoHideRevealThickness, Math.round(14 * Style.uiScaleRatio))
    readonly property real autoHideRevealUsableWidth: Math.max(autoHideRevealThickness, contentBaseWidth - autoHideRevealMargin * 2)
    readonly property real autoHideRevealStripWidth: autoHideRevealMode === "edgeSliver" ? Math.max(autoHideRevealThickness, Math.round(autoHideRevealUsableWidth * autoHideRevealWidthRatio)) : contentBaseWidth
    readonly property real autoHideRevealStripX: Style.pixelAlignCenter(windowHost.width, autoHideRevealStripWidth) + autoHideCurrentOffsetH
    readonly property real autoHideRevealStripY: anchorTop ? autoHideRevealMargin : Math.max(0, windowHost.height - autoHideRevealMargin - autoHideRevealThickness)
    readonly property real autoHideRevealStripRadius: {
        const autoRadius = Math.min(main.effectiveDisplayRadius, autoHideRevealThickness / 2, autoHideRevealStripWidth / 2);
        if (autoHideRevealRadiusSetting <= 0)
            return autoRadius;
        return Math.min(autoHideRevealRadiusSetting, autoHideRevealThickness / 2, autoHideRevealStripWidth / 2);
    }
    readonly property real autoHideSlideDistance: {
        switch (autoHideResolvedSlideDirection) {
        case "left":
        case "right":
            return contentBaseWidth;
        case "up":
            return contentBaseHeight + contentBaseY;
        default:
            return contentBaseHeight;
        }
    }
    readonly property bool autoHideInteractionHold: windowView.dragSessionActive || windowView.contextMenuOpen
    readonly property color autoHideRevealFallbackColor: main.displayBackgroundEnabled ? main.displayBackgroundResolvedColor : Qt.alpha(Color.mSurfaceVariant, 0.82)
    readonly property color autoHideRevealColor: {
        if (autoHideEdgeSliverColorKey === "none")
            return autoHideRevealFallbackColor;
        return Qt.alpha(main.resolveSettingColor(autoHideEdgeSliverColorKey, Color.mSurfaceVariant), autoHideEdgeSliverOpacity);
    }
    readonly property real autoHideVisualOpacity: (autoHideFadeEnabled || autoHideEffect === "instant") ? shownProgress : 1
    readonly property real autoHideVisualOffsetX: {
        if (!autoHideSlideEnabled)
            return 0;
        switch (autoHideResolvedSlideDirection) {
        case "left":
            return Math.round(-autoHideSlideDistance * (1 - shownProgress));
        case "right":
            return Math.round(autoHideSlideDistance * (1 - shownProgress));
        default:
            return 0;
        }
    }
    readonly property real autoHideVisualOffsetY: {
        if (!autoHideSlideEnabled)
            return 0;
        switch (autoHideResolvedSlideDirection) {
        case "up":
            return Math.round(-autoHideSlideDistance * (1 - shownProgress));
        case "down":
            return Math.round(autoHideSlideDistance * (1 - shownProgress));
        default:
            return 0;
        }
    }
    readonly property bool autoHideContentVisible: !autoHideEnabled || shownProgress > 0 || autoHideSlideEnabled
    readonly property real autoHideRevealStripOpacity: {
        if (!autoHideEnabled || autoHideRevealMode !== "edgeSliver")
            return 0;
        if (autoHideEffectiveDurationMs <= 0)
            return autoHideTargetHidden ? 1 : 0;
        return Math.max(0, 1 - shownProgress * 1.4);
    }
    property bool autoHideTargetHidden: false
    property real shownProgress: autoHideTargetHidden ? 0 : 1

    function updateAutoHideState() {
        if (!autoHideEnabled || autoHideInteractionHold) {
            autoHideDelayTimer.stop();
            autoHideTargetHidden = false;
            return;
        }

        if (panelHoverHandler.hovered || revealZoneHover.hovered) {
            autoHideDelayTimer.stop();
            autoHideTargetHidden = false;
            return;
        }

        if (autoHideTargetHidden)
            return;

        if (autoHideDelayMs <= 0) {
            autoHideTargetHidden = true;
            return;
        }

        autoHideDelayTimer.interval = autoHideDelayMs;
        autoHideDelayTimer.restart();
    }

    anchors.top: anchorTop
    anchors.bottom: !anchorTop
    anchors.left: true
    anchors.right: true

    implicitWidth: Math.round(screen?.width || contentBaseWidth)
    implicitHeight: contentBaseHeight + Math.abs(autoHideCurrentOffsetV)

    WlrLayershell.namespace: "scrollbar2-window-" + (screen?.name || "unknown")
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusionMode: ExclusionMode.Auto

    visible: contentBaseWidth > 0 && contentBaseHeight > 0
    mask: Region {
        item: maskItem
    }

    onAutoHideEnabledChanged: updateAutoHideState()
    onAutoHideDelayMsChanged: updateAutoHideState()
    onAutoHideInteractionHoldChanged: updateAutoHideState()

    Component.onCompleted: updateAutoHideState()

    Behavior on shownProgress {
        NumberAnimation {
            duration: windowHost.autoHideEffectiveDurationMs
            easing.type: Easing.InOutQuad
        }
    }

    Timer {
        id: autoHideDelayTimer
        interval: windowHost.autoHideDelayMs
        repeat: false
        onTriggered: {
            if (!windowHost.autoHideEnabled || windowHost.autoHideInteractionHold)
                return;
            if (panelHoverHandler.hovered || revealZoneHover.hovered)
                return;
            windowHost.autoHideTargetHidden = true;
        }
    }

    Item {
        id: maskItem
        width: contentBaseWidth
        height: windowHost.autoHideEnabled ? parent.height : contentBaseHeight
        x: Style.pixelAlignCenter(parent.width, width) + windowHost.autoHideCurrentOffsetH
        y: windowHost.autoHideEnabled ? 0 : windowHost.contentBaseY
        opacity: 0
    }

    Item {
        id: revealZone
        width: windowHost.autoHideRevealMode === "edgeSliver" ? windowHost.autoHideRevealStripWidth : contentBaseWidth
        height: windowHost.autoHideEnabled ? windowHost.autoHideHoverThickness : 0
        x: windowHost.autoHideRevealMode === "edgeSliver" ? windowHost.autoHideRevealStripX : Style.pixelAlignCenter(parent.width, width) + windowHost.autoHideCurrentOffsetH
        y: windowHost.autoHideRevealMode === "edgeSliver" ? windowHost.autoHideRevealStripY : windowHost.anchorTop ? 0 : Math.max(0, parent.height - height)
        z: 10

        HoverHandler {
            id: revealZoneHover
            onHoveredChanged: windowHost.updateAutoHideState()
        }
    }

    Rectangle {
        id: revealStrip
        visible: windowHost.autoHideEnabled && windowHost.autoHideRevealMode === "edgeSliver" && windowHost.shownProgress < 1
        width: windowHost.autoHideRevealStripWidth
        height: windowHost.autoHideRevealThickness
        x: windowHost.autoHideRevealStripX
        y: windowHost.autoHideRevealStripY
        radius: windowHost.autoHideRevealStripRadius
        color: windowHost.autoHideRevealColor
        opacity: windowHost.autoHideRevealStripOpacity
        z: 5
    }

    Item {
        id: windowContent
        visible: windowHost.autoHideContentVisible
        width: contentBaseWidth
        height: contentBaseHeight
        x: Style.pixelAlignCenter(parent.width, width) + windowHost.autoHideCurrentOffsetH + windowHost.autoHideVisualOffsetX
        y: windowHost.contentBaseY + windowHost.autoHideVisualOffsetY
        opacity: windowHost.autoHideVisualOpacity
        z: 20

        HoverHandler {
            id: panelHoverHandler
            enabled: windowHost.autoHideContentVisible
            onHoveredChanged: windowHost.updateAutoHideState()
        }

        Rectangle {
            anchors.fill: parent
            radius: main.effectiveDisplayRadius
            color: main.displayBackgroundResolvedColor
            visible: main.displayBackgroundEnabled || main.displayGradientActive

            Rectangle {
                anchors.fill: parent
                radius: main.effectiveDisplayRadius
                visible: main.displayGradientActive
                color: "transparent"

                gradient: Gradient {
                    orientation: main.displayGradientDirection === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
                    GradientStop {
                        position: 0.0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1.0
                        color: main.displayGradientResolvedColor
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            anchors.margins: windowHost.autoHideCurrentMargin

            WindowBarView {
                id: windowView
                anchors.centerIn: parent
                width: implicitWidth
                height: implicitHeight
                enabled: !windowHost.autoHideEnabled || !windowHost.autoHideTargetHidden
                pluginApi: windowHost.pluginApi
                screen: windowHost.screen
                hostMode: "floatingPanel"
                visibleInCurrentMode: main.displayMode === "floatingPanel"

                transform: Scale {
                    origin.x: windowView.width / 2
                    origin.y: windowView.height / 2
                    xScale: main.displayScale
                    yScale: main.displayScale
                }
            }
        }
    }
}

