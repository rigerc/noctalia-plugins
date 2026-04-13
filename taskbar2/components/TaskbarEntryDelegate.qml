import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "../FocusTransitionMetrics.js" as FocusTransitionMetrics

Item {
    id: taskbarItem

    required property var barWidgetRoot
    required property var modelData
    required property int index
    required property var stateColors
    required property Item capsuleItem

    readonly property int liveRevision: barWidgetRoot.liveDataRevision
    readonly property var liveEntry: {
        const _ = liveRevision;
        return barWidgetRoot.getLiveEntry(modelData.entryKey);
    }
    readonly property var windows: liveEntry && liveEntry.windows ? liveEntry.windows : []
    readonly property bool isRunning: windows.length > 0
    readonly property bool isPinned: modelData.type === "pinned" || modelData.type === "pinned-running"
    readonly property bool isFocused: liveEntry ? liveEntry.isFocused : false
    readonly property bool isHovered: barWidgetRoot.hoveredEntryKey === modelData.entryKey
    readonly property bool isInactive: isPinned && !isRunning
    readonly property bool shouldShowTitle: barWidgetRoot.showTitle && modelData.type !== "pinned"
    readonly property real itemSpacing: Style.marginS
    readonly property real contentPaddingHorizontal: shouldShowTitle ? Style.marginM : Style.marginS
    readonly property real entryContentWidth: barWidgetRoot.itemSize + (shouldShowTitle ? (itemSpacing + barWidgetRoot.titleWidth) : 0)
    readonly property real visualWidth: barWidgetRoot.isVerticalBar ? barWidgetRoot.barHeight : Math.round(entryContentWidth + contentPaddingHorizontal * 2)
    readonly property string title: (liveEntry && liveEntry.title) ? liveEntry.title : (modelData.fallbackTitle || modelData.appId || "Unknown application")
    readonly property string effectiveItemState: isFocused ? "focused" : (isHovered ? "hovered" : (isInactive ? "inactive" : "default"))
    readonly property color itemBackgroundColor: barWidgetRoot.resolveItemStateColorWithOpacity(effectiveItemState, "background")
    readonly property color itemBorderColor: barWidgetRoot.resolveItemStateColorWithOpacity(effectiveItemState, "border")
    readonly property real itemBorderWidth: itemBorderColor.a > 0 ? Style.borderS : 0
    readonly property color itemTextColor: barWidgetRoot.resolveItemStateColorWithOpacity(effectiveItemState, "text")
    readonly property bool useBackgroundGradient: stateColors.backgroundGradientEnabled(barWidgetRoot.itemColors, effectiveItemState)
    readonly property color backgroundGradientStartColor: stateColors.resolveGradientStopColor(barWidgetRoot.itemColors, effectiveItemState, "backgroundGradientStart", "backgroundGradientStartOpacity", "background")
    readonly property color backgroundGradientEndColor: stateColors.resolveGradientStopColor(barWidgetRoot.itemColors, effectiveItemState, "backgroundGradientEnd", "backgroundGradientEndOpacity", "background")
    readonly property int backgroundGradientOrientation: stateColors.backgroundGradientOrientation(barWidgetRoot.itemColors, effectiveItemState, barWidgetRoot.isVerticalBar)
    readonly property int groupedCount: liveEntry ? liveEntry.groupedCount : windows.length
    readonly property int focusedWindowIndex: liveEntry ? liveEntry.focusedWindowIndex : -1
    readonly property string groupedIndicatorText: focusedWindowIndex >= 0 ? ((focusedWindowIndex + 1) + "/" + groupedCount) : groupedCount.toString()
    readonly property bool showGroupedIndicator: barWidgetRoot.groupApps && groupedCount > 1 && isRunning
    readonly property real titlePointSize: Math.max(Style.fontSizeXS, barWidgetRoot.barFontSize * barWidgetRoot.titleFontScale)
    readonly property real hoverItemScale: 1 + (barWidgetRoot.hoverItemScalePercent / 100.0)
    readonly property color focusAccentColor: barWidgetRoot.mixTransitionColors(0.1, 0.04)
    readonly property color focusSecondaryColor: barWidgetRoot.mixTransitionColors(0.58, 0.08)
    readonly property color focusTertiaryColor: barWidgetRoot.mixTransitionColors(0.82, 0.44)
    readonly property real focusVisualStrength: isFocused ? 1.0 : (isHovered ? 0.4 : 0.0)
    readonly property real focusWashOpacity: isFocused ? 0.22 : (isHovered ? 0.1 : 0.0)
    readonly property real iconGlowOpacity: isFocused ? 0.32 : (isHovered ? 0.12 : 0.0)
    readonly property real iconFocusScale: isFocused ? 1.18 : (isHovered ? Math.max(barWidgetRoot.hoverIconScaleMultiplier, 1.05) : 1.0)
    readonly property real iconFocusLift: isFocused ? -1 : 0
    readonly property real titleFocusOpacity: isFocused ? 1.0 : (isHovered ? 0.94 : 0.84)
    readonly property real titleFocusOffset: isFocused ? -2 : (isHovered ? -1 : 0)
    readonly property real badgeFocusScale: isFocused ? 1.08 : 1.0
    readonly property real indicatorOpacity: isFocused ? 1.0 : (isHovered ? 0.72 : 0.0)
    readonly property bool isSeparator: modelData.type === "workspace-target"
    readonly property bool reorderDropEnabled: isSeparator ? barWidgetRoot.supportsLiveReorder : (!isRunning || barWidgetRoot.supportsLiveReorder)
    readonly property bool showSeparatorVisual: modelData.showSeparator ?? false
    readonly property string separatorLabel: barWidgetRoot.getWorkspaceLabel(modelData.workspaceIndex ?? 0)
    readonly property real separatorLabelWidth: barWidgetRoot.workspaceSeparatorShowLabel ? Math.max(0, Math.round(separatorLabel.length * barWidgetRoot.barFontSize * 0.62)) : 0
    readonly property real separatorLineLength: Math.max(Math.round(barWidgetRoot.itemSize * 0.9), Style.marginL * 2)
    readonly property real separatorVisualWidth: barWidgetRoot.isVerticalBar ? barWidgetRoot.barHeight : Math.round(Style.marginM * 2 + separatorLabelWidth + ((barWidgetRoot.workspaceSeparatorShowLabel && barWidgetRoot.workspaceSeparatorShowDivider && separatorLabelWidth > 0) ? Style.marginS : 0) + (barWidgetRoot.workspaceSeparatorShowDivider ? separatorLineLength : 0))
    readonly property real separatorVisualHeight: barWidgetRoot.isVerticalBar ? Math.round(Style.marginM * 2 + separatorLabelWidth + ((barWidgetRoot.workspaceSeparatorShowLabel && barWidgetRoot.workspaceSeparatorShowDivider && separatorLabelWidth > 0) ? Style.marginS : 0) + (barWidgetRoot.workspaceSeparatorShowDivider ? separatorLineLength : 0)) : barWidgetRoot.barHeight
    property real stateFadeOpacity: 1.0

    function syncIndicatorRect() {
        if (isSeparator)
            return;
        if (!capsuleItem || !iconContainer)
            return;

        const iconPoint = iconContainer.mapToItem(capsuleItem, 0, 0);
        const itemPoint = taskbarItem.mapToItem(capsuleItem, 0, 0);
        const rect = FocusTransitionMetrics.buildIndicatorRect({
            "isVerticalBar": barWidgetRoot.isVerticalBar,
            "itemSize": barWidgetRoot.itemSize,
            "scale": barWidgetRoot.focusTransitionScale,
            "verticalPosition": barWidgetRoot.focusTransitionVerticalPosition,
            "itemRect": {
                "x": itemPoint.x,
                "y": itemPoint.y,
                "width": taskbarItem.width,
                "height": taskbarItem.height
            },
            "iconRect": {
                "x": iconPoint.x,
                "y": iconPoint.y,
                "width": iconContainer.width,
                "height": iconContainer.height
            }
        });

        barWidgetRoot.updateEntryIndicatorRect(modelData.entryKey, rect);
    }

    Layout.preferredWidth: isSeparator ? (barWidgetRoot.isVerticalBar ? barWidgetRoot.barHeight : separatorVisualWidth) : (barWidgetRoot.isVerticalBar ? barWidgetRoot.barHeight : visualWidth)
    Layout.preferredHeight: isSeparator ? (barWidgetRoot.isVerticalBar ? separatorVisualHeight : barWidgetRoot.barHeight) : (barWidgetRoot.isVerticalBar ? barWidgetRoot.capsuleHeight : barWidgetRoot.barHeight)
    Layout.alignment: Qt.AlignCenter

    z: (barWidgetRoot.dragSourceIndex === index) ? 1000 : 1
    property int modelIndex: index
    objectName: isSeparator ? "taskbarSeparatorItem" : "taskbarAppItem"

    Behavior on x {
        enabled: !taskbarItem.isSeparator && barWidgetRoot.dragSourceIndex !== index
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Behavior on y {
        enabled: !taskbarItem.isSeparator && barWidgetRoot.dragSourceIndex !== index
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: syncIndicatorRect()
    Component.onDestruction: barWidgetRoot.clearEntryIndicatorRect(modelData.entryKey)
    onXChanged: syncIndicatorRect()
    onYChanged: syncIndicatorRect()
    onWidthChanged: syncIndicatorRect()
    onHeightChanged: syncIndicatorRect()

    Connections {
        target: barWidgetRoot

        function onItemStateFadeEnabledChanged() {
            if (!barWidgetRoot.itemStateFadeEnabled) {
                stateFadeAnimation.stop();
                taskbarItem.stateFadeOpacity = 1.0;
            }
        }
    }

    onEffectiveItemStateChanged: {
        if (!isSeparator && barWidgetRoot.itemStateFadeEnabled) {
            stateFadeOpacity = 1.0;
            stateFadeAnimation.restart();
        } else {
            stateFadeAnimation.stop();
            stateFadeOpacity = 1.0;
        }
    }

    DropArea {
        visible: true
        enabled: taskbarItem.reorderDropEnabled
        anchors.fill: parent
        keys: ["taskbar-app"]
    }

    TaskbarWorkspaceSeparator {
        anchors.fill: parent
        visible: taskbarItem.isSeparator
        entryRoot: taskbarItem.barWidgetRoot
        entryState: taskbarItem
    }

    Item {
        id: draggableContent
        visible: !taskbarItem.isSeparator
        width: parent.width
        height: parent.height
        anchors.centerIn: dragging ? undefined : parent
        opacity: taskbarItem.stateFadeOpacity

        readonly property bool isDragged: taskbarItem.barWidgetRoot.dragSourceIndex === index
        property real shiftOffset: 0
        property bool dragging: taskbarMouseArea.drag.active

        Binding on shiftOffset {
            value: {
                if (taskbarItem.barWidgetRoot.dragSourceIndex !== -1 && taskbarItem.barWidgetRoot.dragTargetIndex !== -1 && !draggableContent.isDragged) {
                    if (taskbarItem.barWidgetRoot.dragSourceIndex < taskbarItem.barWidgetRoot.dragTargetIndex) {
                        if (index > taskbarItem.barWidgetRoot.dragSourceIndex && index <= taskbarItem.barWidgetRoot.dragTargetIndex)
                            return -1 * (taskbarItem.barWidgetRoot.isVerticalBar ? draggableContent.height : draggableContent.width);
                    } else if (taskbarItem.barWidgetRoot.dragSourceIndex > taskbarItem.barWidgetRoot.dragTargetIndex) {
                        if (index >= taskbarItem.barWidgetRoot.dragTargetIndex && index < taskbarItem.barWidgetRoot.dragSourceIndex)
                            return taskbarItem.barWidgetRoot.isVerticalBar ? draggableContent.height : draggableContent.width;
                    }
                }
                return 0;
            }
        }

        transform: Translate {
            x: !taskbarItem.barWidgetRoot.isVerticalBar ? draggableContent.shiftOffset : 0
            y: taskbarItem.barWidgetRoot.isVerticalBar ? draggableContent.shiftOffset : 0

            Behavior on x {
                NumberAnimation {
                    duration: barWidgetRoot.itemPositionAnimationDurationMs
                    easing.type: Easing.OutQuad
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: barWidgetRoot.itemPositionAnimationDurationMs
                    easing.type: Easing.OutQuad
                }
            }
        }

        onDraggingChanged: {
            if (dragging) {
                taskbarItem.barWidgetRoot.dragSourceIndex = index;
                taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent);
            } else if (taskbarItem.barWidgetRoot.dragSourceIndex === index) {
                Qt.callLater(() => {
                    if (taskbarItem.barWidgetRoot.pendingDragCommitSourceIndex === index)
                        return;
                    if (!taskbarMouseArea.drag.active && taskbarItem.barWidgetRoot.dragSourceIndex === index) {
                        taskbarItem.barWidgetRoot.dragSourceIndex = -1;
                        taskbarItem.barWidgetRoot.dragTargetIndex = -1;
                    }
                });
            }
        }

        Drag.active: dragging
        Drag.source: taskbarItem
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.keys: ["taskbar-app"]
        z: dragging ? 1000 : 0
        scale: (dragging ? 1.05 : 1.0) * (taskbarItem.isHovered ? taskbarItem.hoverItemScale : 1.0)
        onXChanged: if (dragging)
            taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent)
        onYChanged: if (dragging)
            taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent)
        onWidthChanged: if (dragging)
            taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent)
        onHeightChanged: if (dragging)
            taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent)
        onScaleChanged: if (dragging)
            taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent)
        onShiftOffsetChanged: if (dragging)
            taskbarItem.barWidgetRoot.updateDragTargetForItem(index, draggableContent)

        Behavior on scale {
            NumberAnimation {
                duration: barWidgetRoot.itemScaleAnimationDurationMs
            }
        }

        SequentialAnimation {
            id: stateFadeAnimation
            running: false

            NumberAnimation {
                target: taskbarItem
                property: "stateFadeOpacity"
                to: barWidgetRoot.itemStateFadeMinOpacity
                duration: barWidgetRoot.itemStateFadeOutDurationMs
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: taskbarItem
                property: "stateFadeOpacity"
                to: 1.0
                duration: barWidgetRoot.itemStateFadeInDurationMs
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            id: capsuleBackground
            anchors.centerIn: parent
            width: barWidgetRoot.isVerticalBar ? barWidgetRoot.capsuleHeight : taskbarItem.visualWidth
            height: barWidgetRoot.capsuleHeight
            color: taskbarItem.useBackgroundGradient ? "transparent" : taskbarItem.itemBackgroundColor
            radius: Style.radiusM
            border.color: taskbarItem.itemBorderColor
            border.width: taskbarItem.itemBorderWidth

            Behavior on color {
                ColorAnimation {
                    duration: barWidgetRoot.itemColorAnimationDurationMs
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: barWidgetRoot.itemColorAnimationDurationMs
                    easing.type: Easing.InOutQuad
                }
            }

            Rectangle {
                visible: taskbarItem.useBackgroundGradient
                anchors.fill: parent
                radius: capsuleBackground.radius
                color: "transparent"
                gradient: Gradient {
                    orientation: taskbarItem.backgroundGradientOrientation
                    GradientStop {
                        position: 0.0
                        color: taskbarItem.backgroundGradientStartColor

                        Behavior on color {
                            ColorAnimation {
                                duration: barWidgetRoot.itemColorAnimationDurationMs
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                    GradientStop {
                        position: 1.0
                        color: taskbarItem.backgroundGradientEndColor

                        Behavior on color {
                            ColorAnimation {
                                duration: barWidgetRoot.itemColorAnimationDurationMs
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: Math.max(1, Style.borderS)
                radius: Math.max(0, capsuleBackground.radius - Style.borderS)
                color: "transparent"
                opacity: taskbarItem.focusWashOpacity
                gradient: Gradient {
                    orientation: barWidgetRoot.isVerticalBar ? Gradient.Vertical : Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(taskbarItem.focusAccentColor.r, taskbarItem.focusAccentColor.g, taskbarItem.focusAccentColor.b, 0.95)

                        Behavior on color {
                            ColorAnimation {
                                duration: barWidgetRoot.itemColorAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    GradientStop {
                        position: 0.55
                        color: Qt.rgba(taskbarItem.focusSecondaryColor.r, taskbarItem.focusSecondaryColor.g, taskbarItem.focusSecondaryColor.b, 0.68)

                        Behavior on color {
                            ColorAnimation {
                                duration: barWidgetRoot.itemColorAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(taskbarItem.focusTertiaryColor.r, taskbarItem.focusTertiaryColor.g, taskbarItem.focusTertiaryColor.b, 0.22)

                        Behavior on color {
                            ColorAnimation {
                                duration: barWidgetRoot.itemColorAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: barWidgetRoot.itemOpacityAnimationDurationMs
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Item {
            anchors.centerIn: parent
            width: taskbarItem.entryContentWidth
            height: barWidgetRoot.itemSize

            RowLayout {
                anchors.fill: parent
                spacing: taskbarItem.itemSpacing

                Item {
                    id: iconContainer
                    Layout.preferredWidth: barWidgetRoot.itemSize
                    Layout.preferredHeight: barWidgetRoot.itemSize
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    onXChanged: taskbarItem.syncIndicatorRect()
                    onYChanged: taskbarItem.syncIndicatorRect()
                    onWidthChanged: taskbarItem.syncIndicatorRect()
                    onHeightChanged: taskbarItem.syncIndicatorRect()

                    Item {
                        anchors.fill: parent
                    }

                    Rectangle {
                        visible: !taskbarItem.shouldShowTitle && !taskbarItem.showGroupedIndicator
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Style.toOdd(barWidgetRoot.itemSize * (0.22 + taskbarItem.focusVisualStrength * 0.18))
                        height: 4
                        color: taskbarItem.isFocused ? taskbarItem.focusAccentColor : taskbarItem.focusSecondaryColor
                        opacity: taskbarItem.indicatorOpacity
                        radius: Math.min(Style.radiusXXS, width / 2)

                        Behavior on width {
                            NumberAnimation {
                                duration: barWidgetRoot.itemScaleAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: barWidgetRoot.itemColorAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: barWidgetRoot.itemOpacityAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    TaskbarGroupBadge {
                        visible: taskbarItem.showGroupedIndicator && barWidgetRoot.groupIndicatorStyle === "number"
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: Math.round(-barWidgetRoot.itemSize * 0.08)
                        anchors.rightMargin: Math.round(-barWidgetRoot.itemSize * 0.08)
                        z: 2
                        entryRoot: barWidgetRoot
                        entryState: taskbarItem
                    }

                    TaskbarGroupDots {
                        visible: taskbarItem.showGroupedIndicator && barWidgetRoot.groupIndicatorStyle === "dots"
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: -2
                        z: 1
                        entryRoot: barWidgetRoot
                        entryState: taskbarItem
                    }

                    Item {
                        anchors.fill: parent
                        y: taskbarItem.iconFocusLift
                        scale: taskbarItem.iconFocusScale
                        opacity: 0.78 + taskbarItem.focusVisualStrength * 0.22
                        transformOrigin: Item.Center

                        Behavior on y {
                            NumberAnimation {
                                duration: barWidgetRoot.itemPositionAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: barWidgetRoot.itemScaleAnimationDurationMs
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: barWidgetRoot.itemOpacityAnimationDurationMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 0.9)
                            height: Math.round(parent.height * 0.9)
                            radius: Math.max(width, height) / 2
                            color: Qt.rgba(taskbarItem.focusTertiaryColor.r, taskbarItem.focusTertiaryColor.g, taskbarItem.focusTertiaryColor.b, 1)
                            opacity: taskbarItem.iconGlowOpacity
                            scale: 0.86 + taskbarItem.focusVisualStrength * 0.28

                            Behavior on color {
                                ColorAnimation {
                                    duration: barWidgetRoot.itemColorAnimationDurationMs
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: barWidgetRoot.itemOpacityAnimationDurationMs
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: barWidgetRoot.itemScaleAnimationDurationMs
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        IconImage {
                            anchors.fill: parent
                            source: ThemeIcons.iconForAppId(taskbarItem.modelData.appId)
                            smooth: true
                            asynchronous: true
                            layer.enabled: barWidgetRoot.colorizeIcons
                            layer.effect: ShaderEffect {
                                property color targetColor: barWidgetRoot.resolvedIconTintColor()
                                property real colorizeMode: 0.0

                                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                            }
                        }
                    }
                }

                NText {
                    visible: taskbarItem.shouldShowTitle
                    Layout.preferredWidth: barWidgetRoot.titleWidth
                    Layout.preferredHeight: barWidgetRoot.itemSize
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.fillWidth: false
                    Layout.leftMargin: taskbarItem.titleFocusOffset
                    text: taskbarItem.title
                    family: barWidgetRoot.titleFontFamilyValue()
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    pointSize: taskbarItem.titlePointSize
                    color: taskbarItem.itemTextColor
                    opacity: taskbarItem.titleFocusOpacity
                    font.weight: barWidgetRoot.titleFontWeightValue()

                    Behavior on opacity {
                        NumberAnimation {
                            duration: barWidgetRoot.itemOpacityAnimationDurationMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: barWidgetRoot.itemColorAnimationDurationMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: taskbarMouseArea
        objectName: "taskbarMouseArea"
        visible: !taskbarItem.isSeparator
        enabled: !taskbarItem.isSeparator && (!taskbarItem.isRunning || barWidgetRoot.supportsLiveReorder)
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        drag.target: draggableContent
        drag.axis: barWidgetRoot.isVerticalBar ? Drag.YAxis : Drag.XAxis
        drag.threshold: 8
        preventStealing: true

        onReleased: {
            if (draggableContent.dragging)
                barWidgetRoot.queueDragCommit(index, barWidgetRoot.dragTargetIndex);
        }

        onClicked: mouse => {
            if (!modelData)
                return;

            const runningWindows = taskbarItem.windows;
            const primaryWindow = barWidgetRoot.getPrimaryWindowForEntryKey(modelData.entryKey);

            if (mouse.button === Qt.LeftButton) {
                if (runningWindows.length === 0) {
                    barWidgetRoot.launchPinnedApp(modelData.appId);
                } else if (!barWidgetRoot.groupApps || runningWindows.length <= 1) {
                    barWidgetRoot.focusWindow(primaryWindow);
                } else if (barWidgetRoot.groupClickAction === "list") {
                    TooltipService.hideImmediately();
                    barWidgetRoot.openTaskbarContextMenu(taskbarItem, "list");
                } else {
                    const appKey = modelData.appId || "";
                    const state = barWidgetRoot.groupCycleIndices || {};
                    const nextIndex = (state[appKey] || 0) % runningWindows.length;
                    const nextWindow = runningWindows[nextIndex];
                    barWidgetRoot.focusWindow(nextWindow);
                    state[appKey] = (nextIndex + 1) % runningWindows.length;
                    barWidgetRoot.groupCycleIndices = Object.assign({}, state);
                }
            } else if (mouse.button === Qt.RightButton) {
                TooltipService.hide();
                barWidgetRoot.openTaskbarContextMenu(taskbarItem, "");
            }
        }

        onEntered: {
            barWidgetRoot.hoveredEntryKey = taskbarItem.modelData.entryKey;
            TooltipService.show(taskbarItem, taskbarItem.title, BarService.getTooltipDirection(barWidgetRoot.screen?.name));
        }

        onExited: {
            barWidgetRoot.hoveredEntryKey = "";
            TooltipService.hide();
        }
    }
}
