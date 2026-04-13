import QtQuick
import qs.Commons
import qs.Widgets

Rectangle {
    id: root

    required property var entryRoot
    required property var entryState

    readonly property real badgeHeight: Math.max(12, Math.round(entryRoot.itemSize * 0.48))
    readonly property real horizontalPadding: Math.max(3, Math.round(entryRoot.itemSize * 0.10))

    width: Math.max(badgeHeight, Math.round(numberLabel.implicitWidth + horizontalPadding * 2))
    height: badgeHeight
    scale: entryState.badgeFocusScale
    radius: height / 2
    color: entryState.focusedWindowIndex >= 0 ? entryState.focusAccentColor : Qt.alpha(entryState.focusTertiaryColor, 0.3)
    border.color: entryState.focusedWindowIndex >= 0 ? Qt.alpha(entryState.focusSecondaryColor, 0.9) : Qt.alpha(entryState.focusSecondaryColor, 0.58)
    border.width: Style.borderS

    Behavior on scale {
        NumberAnimation {
            duration: entryRoot.itemScaleAnimationDurationMs
            easing.type: Easing.OutBack
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: entryRoot.itemColorAnimationDurationMs
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: entryRoot.itemColorAnimationDurationMs
            easing.type: Easing.OutCubic
        }
    }

    NText {
        id: numberLabel
        anchors.centerIn: parent
        text: entryState.groupedIndicatorText
        family: Settings.data.ui.fontFixed
        pointSize: Math.max(Style.fontSizeXS, Math.min(entryRoot.barFontSize * 0.8, Style.fontSizeS))
        applyUiScale: false
        font.weight: Style.fontWeightBold
        color: entryState.focusedWindowIndex >= 0 ? Color.mOnPrimary : entryState.itemTextColor

        Behavior on color {
            ColorAnimation {
                duration: entryRoot.itemColorAnimationDurationMs
                easing.type: Easing.OutCubic
            }
        }
    }
}
