import QtQuick
import QtQuick.Layouts
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
    property real scale: 1.0
    property string leadColorKey: "primary"
    property string glowColorKey: "primary"
    property string effectColorKey: "tertiary"
    property real blurRadius: 6
    property int transparency: 15
    property string verticalPosition: "bottom"

    property real iconScale: 0.8
    property int itemGapUnits: 2
    property bool showTitle: false
    property int titleWidth: 120
    property real hoverIconScaleMultiplier: 1.0
    property real hoverItemScalePercent: 0
    property string titleFontFamily: ""
    property real titleFontScale: 1.0
    property string titleFontWeight: "medium"
    property bool colorizeIcons: false
    property var itemColors: ({})

    property int focusedIndex: 0
    property int direction: 1
    property var indicatorRectsByIndex: ({})

    readonly property int placeholderCount: 4
    readonly property real itemGap: Math.max(0, Math.round(itemGapUnits * Style.uiScaleRatio))
    readonly property real capsuleHeight: Math.max(34, Math.round(38 * Style.uiScaleRatio))
    readonly property real itemSize: Style.toOdd(capsuleHeight * Math.max(0.1, iconScale))
    readonly property real intensityRatio: Math.max(0, Math.min(100, intensity)) / 100
    readonly property real opacityRatio: 1 - (Math.max(0, Math.min(90, transparency)) / 100)

    readonly property var stateDefs: [
        { "stateKey": "inactive", "iconMult": 1.0, "itemMult": 1.0, "washOpacity": 0, "glowOpacity": 0, "lift": 0, "iconOpacity": 0.78, "indicatorOpacity": 0, "indicatorWidthFrac": 0.22, "titleOpacity": 0.6, "dimIcon": true },
        { "stateKey": "default", "iconMult": 1.0, "itemMult": 1.0, "washOpacity": 0, "glowOpacity": 0, "lift": 0, "iconOpacity": 1.0, "indicatorOpacity": 0, "indicatorWidthFrac": 0.22, "titleOpacity": 0.84, "dimIcon": false },
        { "stateKey": "hovered", "iconMult": Math.max(hoverIconScaleMultiplier, 1.05), "itemMult": 1 + (hoverItemScalePercent / 100.0), "washOpacity": 0.1, "glowOpacity": 0.12, "lift": 0, "iconOpacity": 1.0, "indicatorOpacity": 0.72, "indicatorWidthFrac": 0.32, "titleOpacity": 0.94, "dimIcon": false },
        { "stateKey": "focused", "iconMult": 1.18, "itemMult": 1.0, "washOpacity": 0.22, "glowOpacity": 0.32, "lift": -1, "iconOpacity": 1.0, "indicatorOpacity": 1.0, "indicatorWidthFrac": 0.40, "titleOpacity": 1.0, "dimIcon": false }
    ]

    readonly property real previewItemWidth: isVerticalBar ? capsuleHeight : Math.max(64, Math.round((itemSize + (showTitle ? (Style.marginS + Math.round(titleWidth * 0.4)) : 0) + Style.marginM * 2) * Math.max(stateDefs[3].itemMult, stateDefs[2].itemMult)))
    readonly property real previewItemHeight: isVerticalBar ? Math.max(64, Math.round(capsuleHeight * Math.max(stateDefs[3].itemMult, stateDefs[2].itemMult))) : capsuleHeight

    readonly property real contentWidth: isVerticalBar ? previewItemWidth : (placeholderCount * previewItemWidth) + (Math.max(0, placeholderCount - 1) * itemGap)
    readonly property real contentHeight: isVerticalBar ? (placeholderCount * previewItemHeight) + (Math.max(0, placeholderCount - 1) * itemGap) : previewItemHeight

    readonly property real stateLabelHeight: 18 * Style.uiScaleRatio

    implicitWidth: contentWidth
    implicitHeight: contentHeight + stateLabelHeight

    function resolveItemStateColor(stateKey, colorRole) {
        const stateColors = itemColors?.[stateKey];
        const colorKey = stateColors ? stateColors[colorRole] : "none";
        if (!colorKey || colorKey === "none") {
            if (colorRole === "border")
                return "transparent";
            if (colorRole === "text")
                return (stateKey === "hovered" || stateKey === "focused") ? Color.mOnHover : Color.mOnSurface;
            return (stateKey === "hovered" || stateKey === "focused") ? Color.mHover : Style.capsuleColor;
        }
        if (colorRole === "text")
            return Color.resolveColorKey(colorKey);
        return Color.resolveColorKeyOptional(colorKey);
    }

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
        focusedIndex = 0;
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
    onScaleChanged: resetLoop()
    onLeadColorKeyChanged: resetLoop()
    onGlowColorKeyChanged: resetLoop()
    onBlurRadiusChanged: resetLoop()
    onTransparencyChanged: resetLoop()
    onIsVerticalBarChanged: resetLoop()
    onEffectColorKeyChanged: resetLoop()
    onVerticalPositionChanged: resetLoop()
    onIconScaleChanged: resetLoop()
    onItemGapUnitsChanged: resetLoop()
    onHoverIconScaleMultiplierChanged: resetLoop()
    onHoverItemScalePercentChanged: resetLoop()

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

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.contentHeight

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

                        readonly property var sd: root.stateDefs[index]
                        readonly property string stateKey: sd.stateKey
                        readonly property color itemBgColor: root.resolveItemStateColor(stateKey, "background")
                        readonly property color itemBorderColor: root.resolveItemStateColor(stateKey, "border")
                        readonly property color itemTextColor: root.resolveItemStateColor(stateKey, "text")
                        readonly property color accentColor: overlay.mixTransitionColors(0.18)
                        readonly property color secondaryColor: overlay.mixTransitionColors(0.9)
                        readonly property bool isAnimFocused: index === root.focusedIndex
                        readonly property real effectiveItemScale: sd.itemMult

                        readonly property real entryContentWidth: root.itemSize + (root.showTitle && !root.isVerticalBar ? (Style.marginS + Math.round(root.titleWidth * 0.4)) : 0)
                        readonly property real contentPaddingH: (root.showTitle && !root.isVerticalBar) ? Style.marginM : Style.marginS
                        readonly property real visualWidth: root.isVerticalBar ? root.previewItemHeight : Math.round(entryContentWidth + contentPaddingH * 2)

                        function syncIndicatorRect() {
                            const iconPoint = iconContainer.mapToItem(previewSurface, 0, 0);
                            const itemPoint = previewItem.mapToItem(previewSurface, 0, 0);
                            const availableMainSpace = root.isVerticalBar ? iconContainer.height : iconContainer.width;
                            const availableCrossSpace = (root.isVerticalBar ? previewItem.width - 4 : previewItem.height - 4) * 1.5;
                            const markerLength = Math.min(availableMainSpace, Math.max(6, Math.round(root.itemSize * 0.25 * root.scale)));
                            const markerThickness = Math.min(Math.max(2, availableCrossSpace), Math.round(6 * root.scale));
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

                        x: root.isVerticalBar ? (parent.width - width) / 2 : index * (visualWidth + root.itemGap) + (root.contentWidth - (root.placeholderCount * visualWidth + (root.placeholderCount - 1) * root.itemGap)) / 2
                        y: root.isVerticalBar ? index * (root.previewItemHeight + root.itemGap) : (root.contentHeight - height) / 2
                        width: visualWidth
                        height: root.isVerticalBar ? root.previewItemHeight : root.capsuleHeight
                        scale: effectiveItemScale
                        transformOrigin: Item.Center

                        Component.onCompleted: {
                            syncIndicatorRect();
                            iconForegroundProxy.syncPosition();
                        }
                        onXChanged: {
                            syncIndicatorRect();
                            iconForegroundProxy.syncPosition();
                        }
                        onYChanged: {
                            syncIndicatorRect();
                            iconForegroundProxy.syncPosition();
                        }
                        onWidthChanged: {
                            syncIndicatorRect();
                            iconForegroundProxy.syncPosition();
                        }
                        onHeightChanged: {
                            syncIndicatorRect();
                            iconForegroundProxy.syncPosition();
                        }
                        onScaleChanged: iconForegroundProxy.syncPosition()

                        Rectangle {
                            anchors.fill: parent
                            radius: Math.max(width, height) / 2
                            color: previewItem.itemBgColor
                            border.width: previewItem.itemBorderColor.a > 0 ? Style.borderS : 0
                            border.color: previewItem.itemBorderColor

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
                                opacity: previewItem.sd.washOpacity
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
                            anchors.centerIn: parent
                            width: previewItem.entryContentWidth
                            height: root.itemSize

                            RowLayout {
                                anchors.fill: parent
                                spacing: Style.marginS

                                Item {
                                    id: iconContainer
                                    Layout.preferredWidth: root.itemSize
                                    Layout.preferredHeight: root.itemSize
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                                    onXChanged: {
                                        previewItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }
                                    onYChanged: {
                                        previewItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }
                                    onWidthChanged: {
                                        previewItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }
                                    onHeightChanged: {
                                        previewItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }

                                    Item {
                                        anchors.fill: parent
                                    }

                                    Rectangle {
                                        visible: !root.isVerticalBar
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: Math.max(8, Math.round(root.itemSize * previewItem.sd.indicatorWidthFrac))
                                        height: 4
                                        radius: Math.min(Style.radiusXXS, width / 2)
                                        color: previewItem.sd.stateKey === "focused" ? previewItem.accentColor : previewItem.secondaryColor
                                        opacity: previewItem.sd.indicatorOpacity

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: Style.animationNormal
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Style.animationFast
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Item {
                                        id: iconForegroundProxy
                                        parent: previewForegroundLayer
                                        z: 1
                                        visible: previewForegroundLayer.visible
                                        enabled: false
                                        property rect mappedRect: Qt.rect(0, 0, 0, 0)

                                        function syncPosition() {
                                            if (!previewForegroundLayer || !iconContainer) {
                                                mappedRect = Qt.rect(0, 0, 0, 0);
                                                return;
                                            }

                                            const topLeft = iconContainer.mapToItem(previewForegroundLayer, 0, 0);
                                            const bottomRight = iconContainer.mapToItem(previewForegroundLayer, iconContainer.width, iconContainer.height);
                                            const left = Math.min(topLeft.x, bottomRight.x);
                                            const top = Math.min(topLeft.y, bottomRight.y);
                                            const right = Math.max(topLeft.x, bottomRight.x);
                                            const bottom = Math.max(topLeft.y, bottomRight.y);
                                            mappedRect = Qt.rect(
                                                Math.round(left),
                                                Math.round(top),
                                                Math.max(0, Math.round(right - left)),
                                                Math.max(0, Math.round(bottom - top))
                                            );
                                        }

                                        x: mappedRect.x
                                        y: mappedRect.y
                                        width: mappedRect.width
                                        height: mappedRect.height

                                        Item {
                                            anchors.fill: parent
                                            y: previewItem.sd.lift
                                            scale: previewItem.sd.iconMult
                                            opacity: previewItem.sd.dimIcon ? 0.45 : previewItem.sd.iconOpacity
                                            transformOrigin: Item.Center

                                            Behavior on y {
                                                NumberAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: Style.animationNormal
                                                    easing.type: Easing.OutQuad
                                                }
                                            }

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Math.round(parent.width * 0.9)
                                                height: Math.round(parent.height * 0.9)
                                                radius: Math.max(width, height) / 2
                                                color: Qt.rgba(previewItem.secondaryColor.r, previewItem.secondaryColor.g, previewItem.secondaryColor.b, 1)
                                                opacity: previewItem.sd.glowOpacity
                                                scale: 0.86 + (previewItem.sd.glowOpacity > 0 ? (previewItem.sd.stateKey === "focused" ? 0.28 : 0.14) : 0)

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: Style.animationNormal
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: Style.animationNormal
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Math.round(parent.width * 0.62)
                                                height: Math.round(parent.height * 0.62)
                                                radius: Math.max(width, height) / 2
                                                color: previewItem.sd.dimIcon ? Qt.rgba(Color.mOnSurfaceVariant.r, Color.mOnSurfaceVariant.g, Color.mOnSurfaceVariant.b, 0.4) : (previewItem.sd.stateKey === "focused" ? previewItem.accentColor : Color.mOnSurfaceVariant)
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: root.showTitle && !root.isVerticalBar
                                    Layout.preferredWidth: Math.round(root.titleWidth * 0.4)
                                    Layout.preferredHeight: root.itemSize
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    radius: 3
                                    color: Qt.rgba(previewItem.itemTextColor.r, previewItem.itemTextColor.g, previewItem.itemTextColor.b, previewItem.sd.titleOpacity * 0.18)
                                }
                            }
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
                    thickness: 6 * root.scale
                    leadColorKey: root.leadColorKey
                    glowColorKey: root.glowColorKey
                    effectColorKey: root.effectColorKey
                    verticalPosition: root.verticalPosition
                    blurRadius: root.blurRadius * root.scale
                    opacityRatio: root.opacityRatio
                    onTransitionFinished: {
                        if (root.transitionEnabled)
                            settleTimer.restart();
                    }
                }

                Item {
                    id: previewForegroundLayer
                    anchors.fill: parent
                    z: 20
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.stateLabelHeight
            spacing: 0

            Repeater {
                model: root.placeholderCount

                delegate: NText {
                    required property int index
                    readonly property string stateKey: root.stateDefs[index].stateKey

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    pointSize: Math.max(Style.fontSizeXS, 9 * Style.uiScaleRatio)
                    color: Color.mOnSurfaceVariant
                    text: {
                        switch (stateKey) {
                        case "inactive": return qsTr("Inactive");
                        case "default": return qsTr("Default");
                        case "hovered": return qsTr("Hovered");
                        case "focused": return qsTr("Focused");
                        default: return stateKey;
                        }
                    }
                }
            }
        }
    }
}
