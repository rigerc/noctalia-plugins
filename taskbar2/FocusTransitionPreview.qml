import QtQuick
import qs.Commons
import qs.Widgets

Item {
    id: root

    property bool isVerticalBar: false
    property bool transitionEnabled: true
    property int delayMs: 350
    property int durationMs: 220
    property string styleKey: "soft-comet"
    property int intensity: 60
    property real thickness: 6
    property real markerScale: 1.4
    property string colorKey: "primary"
    property string glowColorKey: "primary"
    property string effectColorKey: "tertiary"
    property real blurRadius: 6
    property int transparency: 15
    property string verticalPosition: "bottom"

    property int focusedIndex: 1
    property int direction: 1
    property var indicatorRectsByIndex: ({})

    readonly property int placeholderCount: 4
    readonly property real itemGap: Style.marginM
    readonly property real capsuleHeight: Math.max(34, Math.round(38 * Style.uiScaleRatio))
    readonly property real itemSize: Style.toOdd(capsuleHeight * 0.62)
    readonly property real previewItemWidth: isVerticalBar ? capsuleHeight : Math.max(64, Math.round(86 * Style.uiScaleRatio))
    readonly property real previewItemHeight: isVerticalBar ? Math.max(64, Math.round(72 * Style.uiScaleRatio)) : capsuleHeight
    readonly property real intensityRatio: Math.max(0, Math.min(100, intensity)) / 100
    readonly property real opacityRatio: 1 - (Math.max(0, Math.min(90, transparency)) / 100)
    readonly property real contentWidth: isVerticalBar ? previewItemWidth : (placeholderCount * previewItemWidth) + (Math.max(0, placeholderCount - 1) * itemGap)
    readonly property real contentHeight: isVerticalBar ? (placeholderCount * previewItemHeight) + (Math.max(0, placeholderCount - 1) * itemGap) : previewItemHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    function updateIndicatorRect(index, rect) {
        const nextRects = Object.assign({}, indicatorRectsByIndex);
        nextRects[index] = rect;
        indicatorRectsByIndex = nextRects;
    }

    function refreshIndicatorRects() {
        for (let i = 0; i < placeholderRepeater.count; i++) {
            const item = placeholderRepeater.itemAt(i);
            if (item)
                item.syncIndicatorRect();
        }
    }

    function resetLoop() {
        kickoffTimer.stop();
        settleTimer.stop();
        overlay.cancelTransition();
        indicatorRectsByIndex = ({});
        focusedIndex = 1;
        direction = 1;

        Qt.callLater(refreshIndicatorRects);

        if (transitionEnabled)
            kickoffTimer.restart();
    }

    function hasCompleteIndicatorRects() {
        for (let i = 0; i < placeholderCount; i++) {
            if (!indicatorRectsByIndex[i])
                return false;
        }
        return true;
    }

    function nextFocusIndex() {
        let nextIndex = focusedIndex + direction;
        if (nextIndex >= placeholderCount || nextIndex < 0) {
            direction = -direction;
            nextIndex = focusedIndex + direction;
        }
        return Math.max(0, Math.min(placeholderCount - 1, nextIndex));
    }

    function advancePreview() {
        if (!transitionEnabled)
            return;

        if (!hasCompleteIndicatorRects()) {
            kickoffTimer.restart();
            return;
        }

        const nextIndex = nextFocusIndex();
        const startRect = indicatorRectsByIndex[focusedIndex];
        const endRect = indicatorRectsByIndex[nextIndex];
        focusedIndex = nextIndex;
        overlay.scheduleTransition(startRect, endRect);
    }

    onTransitionEnabledChanged: resetLoop()
    onDelayMsChanged: resetLoop()
    onDurationMsChanged: resetLoop()
    onStyleKeyChanged: resetLoop()
    onIntensityChanged: resetLoop()
    onThicknessChanged: resetLoop()
    onMarkerScaleChanged: resetLoop()
    onColorKeyChanged: resetLoop()
    onGlowColorKeyChanged: resetLoop()
    onBlurRadiusChanged: resetLoop()
    onTransparencyChanged: resetLoop()
    onIsVerticalBarChanged: resetLoop()
    onEffectColorKeyChanged: resetLoop()
    onVerticalPositionChanged: resetLoop()

    Component.onCompleted: resetLoop()

    Timer {
        id: kickoffTimer
        interval: 360
        repeat: false
        onTriggered: root.advancePreview()
    }

    Timer {
        id: settleTimer
        interval: 480
        repeat: false
        onTriggered: root.advancePreview()
    }

    Item {
        id: previewSurface
        anchors.centerIn: parent
        width: root.contentWidth
        height: root.contentHeight
        clip: true

        Repeater {
            id: placeholderRepeater
            model: root.placeholderCount

            delegate: Item {
                id: previewItem

                required property int index

                readonly property bool isFocused: index === root.focusedIndex
                readonly property real itemWidth: root.previewItemWidth
                readonly property real itemHeight: root.previewItemHeight
                readonly property color accentColor: overlay.mixTransitionColors(0.18)
                readonly property color secondaryColor: overlay.mixTransitionColors(0.9)
                readonly property color capsuleColor: isFocused ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.16) : Style.capsuleColor
                readonly property color borderColor: isFocused ? Qt.rgba(secondaryColor.r, secondaryColor.g, secondaryColor.b, 0.36) : Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, 0.28)

                function syncIndicatorRect() {
                    const iconPoint = iconContainer.mapToItem(previewSurface, 0, 0);
                    const itemPoint = previewItem.mapToItem(previewSurface, 0, 0);
                    const availableMainSpace = root.isVerticalBar ? iconContainer.height : iconContainer.width;
                    const availableCrossSpace = (root.isVerticalBar ? previewItem.width - 4 : previewItem.height - 4) * 1.5;
                    const markerLength = Math.min(availableMainSpace, Math.max(6, Math.round(root.itemSize * 0.25 * root.markerScale)));
                    const markerThickness = Math.min(Math.max(2, availableCrossSpace), Math.round(root.thickness));
                    let markerY;
                    if (root.verticalPosition === "top")
                        markerY = Math.round(itemPoint.y + 2);
                    else if (root.verticalPosition === "middle")
                        markerY = Math.round(itemPoint.y + (previewItem.height - markerThickness) / 2);
                    else
                        markerY = Math.round(itemPoint.y + previewItem.height - markerThickness - 2);
                    const rect = root.isVerticalBar ? {
                        "x": Math.round(itemPoint.x + previewItem.width - markerThickness - 2),
                        "y": Math.round(iconPoint.y + (iconContainer.height - markerLength) / 2),
                        "width": markerThickness,
                        "height": markerLength
                    } : {
                        "x": Math.round(iconPoint.x + (iconContainer.width - markerLength) / 2),
                        "y": markerY,
                        "width": markerLength,
                        "height": markerThickness
                    };

                    root.updateIndicatorRect(index, rect);
                }

                x: root.isVerticalBar ? 0 : index * (itemWidth + root.itemGap)
                y: root.isVerticalBar ? index * (itemHeight + root.itemGap) : 0
                width: itemWidth
                height: itemHeight

                Component.onCompleted: syncIndicatorRect()
                onXChanged: syncIndicatorRect()
                onYChanged: syncIndicatorRect()
                onWidthChanged: syncIndicatorRect()
                onHeightChanged: syncIndicatorRect()

                Rectangle {
                    anchors.fill: parent
                    radius: Math.max(width, height) / 2
                    color: previewItem.capsuleColor
                    border.width: Style.borderS
                    border.color: previewItem.borderColor

                    Behavior on color {
                        ColorAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.InOutQuad
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: Math.max(1, Style.borderS)
                        radius: Math.max(0, parent.radius - Style.borderS)
                        color: "transparent"
                        opacity: previewItem.isFocused ? 0.18 : 0
                        gradient: Gradient {
                            orientation: root.isVerticalBar ? Gradient.Vertical : Gradient.Horizontal

                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(previewItem.accentColor.r, previewItem.accentColor.g, previewItem.accentColor.b, 0.95)
                            }

                            GradientStop {
                                position: 0.55
                                color: Qt.rgba(previewItem.secondaryColor.r, previewItem.secondaryColor.g, previewItem.secondaryColor.b, 0.55)
                            }

                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(previewItem.accentColor.r, previewItem.accentColor.g, previewItem.accentColor.b, 0.18)
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Style.animationNormal
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Item {
                    id: iconContainer
                    anchors.left: parent.left
                    anchors.leftMargin: root.isVerticalBar ? Math.round((parent.width - width) / 2) : Style.marginM
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.itemSize
                    height: root.itemSize

                    onXChanged: previewItem.syncIndicatorRect()
                    onYChanged: previewItem.syncIndicatorRect()
                    onWidthChanged: previewItem.syncIndicatorRect()
                    onHeightChanged: previewItem.syncIndicatorRect()

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.9)
                        height: Math.round(parent.height * 0.9)
                        radius: Math.max(width, height) / 2
                        color: Qt.rgba(previewItem.secondaryColor.r, previewItem.secondaryColor.g, previewItem.secondaryColor.b, 1)
                        opacity: previewItem.isFocused ? 0.28 : 0.08
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.round(parent.width * 0.62)
                        height: Math.round(parent.height * 0.62)
                        radius: Math.max(width, height) / 2
                        color: previewItem.isFocused ? previewItem.accentColor : Color.mOnSurfaceVariant
                    }
                }

                Rectangle {
                    visible: !root.isVerticalBar
                    anchors.left: iconContainer.right
                    anchors.leftMargin: Style.marginS
                    anchors.right: parent.right
                    anchors.rightMargin: Style.marginM
                    anchors.verticalCenter: parent.verticalCenter
                    height: Math.max(6, Math.round(8 * Style.uiScaleRatio))
                    radius: height / 2
                    color: previewItem.isFocused ? Qt.rgba(previewItem.secondaryColor.r, previewItem.secondaryColor.g, previewItem.secondaryColor.b, 0.55) : Qt.rgba(Color.mOnSurfaceVariant.r, Color.mOnSurfaceVariant.g, Color.mOnSurfaceVariant.b, 0.25)
                }

                Rectangle {
                    visible: !root.isVerticalBar
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -2
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.max(8, Math.round(root.itemSize * (previewItem.isFocused ? 0.34 : 0.22)))
                    height: 4
                    radius: Math.min(Style.radiusXXS, width / 2)
                    color: previewItem.isFocused ? previewItem.accentColor : previewItem.secondaryColor
                    opacity: previewItem.isFocused ? 1 : 0.2
                }
            }
        }

        FocusTransitionOverlay {
            id: overlay
            anchors.fill: parent
            z: 10
            isVerticalBar: root.isVerticalBar
            transitionEnabled: root.transitionEnabled
            delayMs: root.delayMs
            durationMs: root.durationMs
            styleKey: root.styleKey
            intensityRatio: root.intensityRatio
            thickness: root.thickness
            colorKey: root.colorKey
            glowColorKey: root.glowColorKey
            effectColorKey: root.effectColorKey
            verticalPosition: root.verticalPosition
            blurRadius: root.blurRadius
            opacityRatio: root.opacityRatio
            onTransitionFinished: {
                if (root.transitionEnabled)
                    settleTimer.restart();
            }
        }
    }
}
