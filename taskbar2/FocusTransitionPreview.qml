import "FocusTransitionMetrics.js" as FocusTransitionMetrics
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
    property real scale: 1
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
    property real hoverIconScaleMultiplier: 1
    property real hoverItemScalePercent: 0
    property string titleFontFamily: ""
    property real titleFontScale: 1
    property string titleFontWeight: "medium"
    property bool itemStateFadeEnabled: true
    property int itemStateFadeMinOpacity: 88
    property int itemStateFadeOutDurationMs: 55
    property int itemStateFadeInDurationMs: 90
    property int itemPositionAnimationDurationMs: 120
    property int itemScaleAnimationDurationMs: 180
    property int itemOpacityAnimationDurationMs: 120
    property int itemColorAnimationDurationMs: 120
    property bool colorizeIcons: false
    property string iconColorKey: "primary"
    property int iconColorOpacity: 100
    property var itemColors: ({
    })
    property int focusedIndex: 0
    property int direction: 1
    property var indicatorRectsByIndex: ({
    })
    readonly property int placeholderCount: 4
    readonly property real itemGap: Math.max(0, Math.round(itemGapUnits * Style.uiScaleRatio))
    readonly property real capsuleHeight: Math.max(34, Math.round(38 * Style.uiScaleRatio))
    readonly property real itemSize: Style.toOdd(capsuleHeight * Math.max(0.1, iconScale))
    readonly property real intensityRatio: Math.max(0, Math.min(100, intensity)) / 100
    readonly property real opacityRatio: 1 - (Math.max(0, Math.min(90, transparency)) / 100)
    readonly property var stateDefs: [{
        "stateKey": "inactive",
        "iconMult": 1,
        "itemMult": 1,
        "washOpacity": 0,
        "glowOpacity": 0,
        "lift": 0,
        "iconOpacity": 0.78,
        "indicatorOpacity": 0,
        "indicatorWidthFrac": 0.22,
        "titleOpacity": 0.6,
        "dimIcon": true
    }, {
        "stateKey": "default",
        "iconMult": 1,
        "itemMult": 1,
        "washOpacity": 0,
        "glowOpacity": 0,
        "lift": 0,
        "iconOpacity": 1,
        "indicatorOpacity": 0,
        "indicatorWidthFrac": 0.22,
        "titleOpacity": 0.84,
        "dimIcon": false
    }, {
        "stateKey": "hovered",
        "iconMult": Math.max(hoverIconScaleMultiplier, 1.05),
        "itemMult": 1 + (hoverItemScalePercent / 100),
        "washOpacity": 0.1,
        "glowOpacity": 0.12,
        "lift": 0,
        "iconOpacity": 1,
        "indicatorOpacity": 0.72,
        "indicatorWidthFrac": 0.32,
        "titleOpacity": 0.94,
        "dimIcon": false
    }, {
        "stateKey": "focused",
        "iconMult": 1.18,
        "itemMult": 1,
        "washOpacity": 0.22,
        "glowOpacity": 0.32,
        "lift": -1,
        "iconOpacity": 1,
        "indicatorOpacity": 1,
        "indicatorWidthFrac": 0.4,
        "titleOpacity": 1,
        "dimIcon": false
    }]
    readonly property real previewItemWidth: isVerticalBar ? capsuleHeight : Math.max(64, Math.round((itemSize + (showTitle ? (Style.marginS + Math.round(titleWidth * 0.4)) : 0) + Style.marginM * 2) * Math.max(stateDefs[3].itemMult, stateDefs[2].itemMult)))
    readonly property real previewItemHeight: isVerticalBar ? Math.max(64, Math.round(capsuleHeight * Math.max(stateDefs[3].itemMult, stateDefs[2].itemMult))) : capsuleHeight
    readonly property real contentWidth: isVerticalBar ? previewItemWidth : (placeholderCount * previewItemWidth) + (Math.max(0, placeholderCount - 1) * itemGap)
    readonly property real contentHeight: isVerticalBar ? (placeholderCount * previewItemHeight) + (Math.max(0, placeholderCount - 1) * itemGap) : previewItemHeight
    readonly property real stateLabelHeight: 18 * Style.uiScaleRatio

    function resolveStateDef(stateKey) {
        for (let i = 0; i < stateDefs.length; i++) {
            if (stateDefs[i].stateKey === stateKey)
                return stateDefs[i];

        }
        return stateDefs[1];
    }

    function previewItemStateKey(index) {
        if (index === focusedIndex)
            return "focused";

        const offset = (index - focusedIndex + placeholderCount) % placeholderCount;
        switch (offset) {
        case 1:
            return "hovered";
        case 2:
            return "inactive";
        default:
            return "default";
        }
    }

    function resolveItemStateColor(stateKey, colorRole) {
        return itemStateColors.resolveItemStateColor(itemColors, stateKey, colorRole);
    }

    function resolveItemStateColorWithOpacity(stateKey, colorRole) {
        return itemStateColors.resolveItemStateColorWithOpacity(itemColors, stateKey, colorRole);
    }

    function resolvedIconTintColor() {
        const baseColor = (!iconColorKey || iconColorKey === "none") ? Color.mPrimary : Color.resolveColorKey(iconColorKey);
        const alpha = Math.max(0, Math.min(100, iconColorOpacity)) / 100;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, alpha);
    }

    function updateIndicatorRect(index, rect) {
        const nextRects = Object.assign({
        }, indicatorRectsByIndex);
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
        indicatorRectsByIndex = ({
        });
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
            return ;

        if (!hasCompleteIndicatorRects()) {
            kickoffTimer.restart();
            return ;
        }
        const nextIndex = nextFocusIndex();
        const startRect = indicatorRectsByIndex[focusedIndex];
        const endRect = indicatorRectsByIndex[nextIndex];
        focusedIndex = nextIndex;
        overlay.scheduleTransition(startRect, endRect);
    }

    implicitWidth: contentWidth
    implicitHeight: contentHeight + stateLabelHeight
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

    ItemStateColors {
        id: itemStateColors
    }

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
                        readonly property string effectiveStateKey: root.previewItemStateKey(index)
                        readonly property var effectiveState: root.resolveStateDef(effectiveStateKey)
                        readonly property color itemBgColor: root.resolveItemStateColorWithOpacity(stateKey, "background")
                        readonly property color itemBorderColor: root.resolveItemStateColorWithOpacity(stateKey, "border")
                        readonly property color itemTextColor: root.resolveItemStateColorWithOpacity(stateKey, "text")
                        readonly property bool useBackgroundGradient: itemStateColors.backgroundGradientEnabled(root.itemColors, stateKey)
                        readonly property color backgroundGradientStartColor: itemStateColors.resolveGradientStopColor(root.itemColors, stateKey, "backgroundGradientStart", "backgroundGradientStartOpacity", "background")
                        readonly property color backgroundGradientEndColor: itemStateColors.resolveGradientStopColor(root.itemColors, stateKey, "backgroundGradientEnd", "backgroundGradientEndOpacity", "background")
                        readonly property int backgroundGradientOrientation: itemStateColors.backgroundGradientOrientation(root.itemColors, stateKey, root.isVerticalBar)
                        readonly property color accentColor: overlay.mixTransitionColors(0.1, 0.04)
                        readonly property color secondaryColor: overlay.mixTransitionColors(0.58, 0.08)
                        readonly property color tertiaryColor: overlay.mixTransitionColors(0.82, 0.44)
                        readonly property bool isAnimFocused: index === root.focusedIndex
                        readonly property real effectiveItemScale: effectiveState.itemMult
                        readonly property string stateKey: effectiveStateKey
                        readonly property real entryContentWidth: root.itemSize + (root.showTitle && !root.isVerticalBar ? (Style.marginS + Math.round(root.titleWidth * 0.4)) : 0)
                        readonly property real contentPaddingH: (root.showTitle && !root.isVerticalBar) ? Style.marginM : Style.marginS
                        readonly property real visualWidth: root.isVerticalBar ? root.previewItemHeight : Math.round(entryContentWidth + contentPaddingH * 2)
                        property real stateFadeOpacity: 1.0

                        function syncIndicatorRect() {
                            const iconPoint = iconContainer.mapToItem(previewSurface, 0, 0);
                            const itemPoint = previewItem.mapToItem(previewSurface, 0, 0);
                            const rect = FocusTransitionMetrics.buildIndicatorRect({
                                "isVerticalBar": root.isVerticalBar,
                                "itemSize": root.itemSize,
                                "scale": root.scale,
                                "verticalPosition": root.verticalPosition,
                                "itemRect": {
                                    "x": itemPoint.x,
                                    "y": itemPoint.y,
                                    "width": previewItem.width,
                                    "height": previewItem.height
                                },
                                "iconRect": {
                                    "x": iconPoint.x,
                                    "y": iconPoint.y,
                                    "width": iconContainer.width,
                                    "height": iconContainer.height
                                }
                            });
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
                        Connections {
                            target: root

                            function onItemStateFadeEnabledChanged() {
                                if (!root.itemStateFadeEnabled) {
                                    previewItem.stateFadeAnimation.stop();
                                    previewItem.stateFadeOpacity = 1.0;
                                }
                            }
                        }
                        onStateKeyChanged: {
                            if (root.itemStateFadeEnabled) {
                                stateFadeOpacity = 1.0;
                                stateFadeAnimation.restart();
                            } else {
                                stateFadeAnimation.stop();
                                stateFadeOpacity = 1.0;
                            }
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
                        opacity: stateFadeOpacity

                        SequentialAnimation {
                            id: stateFadeAnimation
                            running: false

                            NumberAnimation {
                                target: previewItem
                                property: "stateFadeOpacity"
                                to: Math.max(0, Math.min(100, root.itemStateFadeMinOpacity)) / 100
                                duration: Math.max(0, root.itemStateFadeOutDurationMs)
                                easing.type: Easing.OutQuad
                            }

                            NumberAnimation {
                                target: previewItem
                                property: "stateFadeOpacity"
                                to: 1.0
                                duration: Math.max(0, root.itemStateFadeInDurationMs)
                                easing.type: Easing.OutQuad
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Math.max(width, height) / 2
                            color: previewItem.useBackgroundGradient ? "transparent" : previewItem.itemBgColor
                            border.width: previewItem.itemBorderColor.a > 0 ? Style.borderS : 0
                            border.color: previewItem.itemBorderColor

                            Rectangle {
                                visible: previewItem.useBackgroundGradient
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                gradient: Gradient {
                                    orientation: previewItem.backgroundGradientOrientation
                                    GradientStop {
                                        position: 0.0
                                        color: previewItem.backgroundGradientStartColor
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: previewItem.backgroundGradientEndColor
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Math.max(1, Style.borderS)
                                radius: Math.max(0, parent.radius - Style.borderS)
                                color: "transparent"
                                opacity: previewItem.effectiveState.washOpacity

                                gradient: Gradient {
                                    orientation: root.isVerticalBar ? Gradient.Vertical : Gradient.Horizontal

                                    GradientStop {
                                        position: 0
                                        color: Qt.rgba(previewItem.accentColor.r, previewItem.accentColor.g, previewItem.accentColor.b, 0.95)
                                    }

                                    GradientStop {
                                        position: 0.55
                                        color: Qt.rgba(previewItem.secondaryColor.r, previewItem.secondaryColor.g, previewItem.secondaryColor.b, 0.68)
                                    }

                                    GradientStop {
                                        position: 1
                                        color: Qt.rgba(previewItem.tertiaryColor.r, previewItem.tertiaryColor.g, previewItem.tertiaryColor.b, 0.22)
                                    }

                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: root.itemOpacityAnimationDurationMs
                                        easing.type: Easing.OutCubic
                                    }

                                }

                            }

                            Behavior on color {
                                ColorAnimation {
                                    duration: root.itemColorAnimationDurationMs
                                    easing.type: Easing.InOutQuad
                                }

                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: root.itemColorAnimationDurationMs
                                    easing.type: Easing.InOutQuad
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
                                        width: Math.max(8, Math.round(root.itemSize * previewItem.effectiveState.indicatorWidthFrac))
                                        height: 4
                                        radius: Math.min(Style.radiusXXS, width / 2)
                                        color: previewItem.stateKey === "focused" ? previewItem.accentColor : previewItem.secondaryColor
                                        opacity: previewItem.effectiveState.indicatorOpacity

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: root.itemScaleAnimationDurationMs
                                                easing.type: Easing.OutCubic
                                            }

                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: root.itemColorAnimationDurationMs
                                                easing.type: Easing.OutCubic
                                            }

                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: root.itemOpacityAnimationDurationMs
                                                easing.type: Easing.OutCubic
                                            }

                                        }

                                    }

                                    Item {
                                        id: iconForegroundProxy

                                        property rect mappedRect: Qt.rect(0, 0, 0, 0)

                                        function syncPosition() {
                                            if (!previewForegroundLayer || !iconContainer) {
                                                mappedRect = Qt.rect(0, 0, 0, 0);
                                                return ;
                                            }
                                            const topLeft = iconContainer.mapToItem(previewForegroundLayer, 0, 0);
                                            const bottomRight = iconContainer.mapToItem(previewForegroundLayer, iconContainer.width, iconContainer.height);
                                            const left = Math.min(topLeft.x, bottomRight.x);
                                            const top = Math.min(topLeft.y, bottomRight.y);
                                            const right = Math.max(topLeft.x, bottomRight.x);
                                            const bottom = Math.max(topLeft.y, bottomRight.y);
                                            mappedRect = Qt.rect(Math.round(left), Math.round(top), Math.max(0, Math.round(right - left)), Math.max(0, Math.round(bottom - top)));
                                        }

                                        parent: previewForegroundLayer
                                        z: 1
                                        visible: previewForegroundLayer.visible
                                        enabled: false
                                        x: mappedRect.x
                                        y: mappedRect.y
                                        width: mappedRect.width
                                        height: mappedRect.height

                                        Item {
                                            anchors.fill: parent
                                            y: previewItem.effectiveState.lift
                                            scale: previewItem.effectiveState.iconMult
                                            opacity: previewItem.effectiveState.dimIcon ? 0.45 : previewItem.effectiveState.iconOpacity
                                            transformOrigin: Item.Center

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Math.round(parent.width * 0.9)
                                                height: Math.round(parent.height * 0.9)
                                                radius: Math.max(width, height) / 2
                                                color: Qt.rgba(previewItem.tertiaryColor.r, previewItem.tertiaryColor.g, previewItem.tertiaryColor.b, 1)
                                                opacity: previewItem.effectiveState.glowOpacity
                                                scale: 0.86 + (previewItem.effectiveState.glowOpacity > 0 ? (previewItem.stateKey === "focused" ? 0.28 : 0.14) : 0)

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: root.itemOpacityAnimationDurationMs
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: root.itemScaleAnimationDurationMs
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }

                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Math.round(parent.width * 0.62)
                                                height: Math.round(parent.height * 0.62)
                                                radius: Math.max(width, height) / 2
                                                color: previewItem.effectiveState.dimIcon ? Qt.rgba(Color.mOnSurfaceVariant.r, Color.mOnSurfaceVariant.g, Color.mOnSurfaceVariant.b, 0.4) : (root.colorizeIcons ? root.resolvedIconTintColor() : (previewItem.stateKey === "focused" ? previewItem.accentColor : Color.mOnSurfaceVariant))

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: root.itemColorAnimationDurationMs
                                                        easing.type: Easing.OutCubic
                                                    }

                                                }
                                            }

                                            Behavior on y {
                                                NumberAnimation {
                                                    duration: root.itemPositionAnimationDurationMs
                                                    easing.type: Easing.OutCubic
                                                }

                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: root.itemScaleAnimationDurationMs
                                                    easing.type: Easing.OutQuad
                                                }

                                            }

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: root.itemOpacityAnimationDurationMs
                                                    easing.type: Easing.OutCubic
                                                }

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
                                    color: Qt.rgba(previewItem.itemTextColor.r, previewItem.itemTextColor.g, previewItem.itemTextColor.b, previewItem.effectiveState.titleOpacity * 0.18)

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: root.itemColorAnimationDurationMs
                                            easing.type: Easing.OutCubic
                                        }

                                    }
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
                    readonly property string stateKey: root.previewItemStateKey(index)

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    pointSize: Math.max(Style.fontSizeXS, 9 * Style.uiScaleRatio)
                    color: Color.mOnSurfaceVariant
                    text: {
                        switch (stateKey) {
                        case "inactive":
                            return qsTr("Inactive");
                        case "default":
                            return qsTr("Default");
                        case "hovered":
                            return qsTr("Hovered");
                        case "focused":
                            return qsTr("Focused");
                        default:
                            return stateKey;
                        }
                    }
                }

            }

        }

    }

}
