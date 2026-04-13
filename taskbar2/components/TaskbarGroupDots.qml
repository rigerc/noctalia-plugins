import QtQuick

Item {
    id: root

    required property var entryRoot
    required property var entryState

    readonly property int maxVisibleDots: 5
    readonly property int totalCount: Math.max(0, entryState.groupedCount)
    readonly property int focusedIndex: entryState.focusedWindowIndex >= 0 ? entryState.focusedWindowIndex : 0
    readonly property int visibleCount: Math.min(totalCount, maxVisibleDots)
    readonly property int dotSize: Math.max(2, Math.round(entryRoot.itemSize * 0.1))
    readonly property int dotSpacing: Math.max(1, Math.round(dotSize * 0.7))
    readonly property int windowStart: {
        if (totalCount <= maxVisibleDots)
            return 0;
        const centeredStart = focusedIndex - Math.floor(maxVisibleDots / 2);
        const maxStart = totalCount - maxVisibleDots;
        return Math.max(0, Math.min(maxStart, centeredStart));
    }

    width: entryRoot.isVerticalBar ? dotSize : (visibleCount * dotSize + Math.max(0, visibleCount - 1) * dotSpacing)
    height: entryRoot.isVerticalBar ? (visibleCount * dotSize + Math.max(0, visibleCount - 1) * dotSpacing) : dotSize

    Repeater {
        model: root.visibleCount
        delegate: Rectangle {
            required property int index
            readonly property int actualIndex: root.windowStart + index

            width: root.dotSize
            height: root.dotSize
            scale: actualIndex === root.entryState.focusedWindowIndex ? 1.35 : 1.0
            radius: width / 2
            x: root.entryRoot.isVerticalBar ? 0 : index * (root.dotSize + root.dotSpacing)
            y: root.entryRoot.isVerticalBar ? index * (root.dotSize + root.dotSpacing) : 0
            color: actualIndex === root.entryState.focusedWindowIndex ? root.entryState.focusAccentColor : root.entryState.focusTertiaryColor
            opacity: actualIndex === root.entryState.focusedWindowIndex ? 1.0 : 0.56

            Behavior on scale {
                NumberAnimation {
                    duration: root.entryRoot.itemScaleAnimationDurationMs
                    easing.type: Easing.OutBack
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: root.entryRoot.itemColorAnimationDurationMs
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.entryRoot.itemOpacityAnimationDurationMs
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
