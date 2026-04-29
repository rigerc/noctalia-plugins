pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: indicator

    required property var view

    visible: indicator.view.effectiveFocusIndex >= 0 && indicator.view.availableContainerHeight > 0
    x: indicator.view.indicatorOffset(indicator.view.effectiveFocusIndex)
    y: 0
    width: indicator.view.segmentWidth
    height: indicator.view.availableContainerHeight
    // Keep the moving focus strip below segment content so state fills remain true backgrounds.
    z: 0

    Behavior on x {
        enabled: indicator.view.animationEnabled
        NumberAnimation {
            duration: indicator.view.animationSpeed
            easing.type: indicator.view.focusLineEasingType()
            easing.overshoot: indicator.view.focusLineOvershoot()
        }
    }

    Behavior on width {
        enabled: indicator.view.animationEnabled
        NumberAnimation {
            duration: indicator.view.animationSpeed
            easing.type: indicator.view.focusLineEasingType()
            easing.overshoot: indicator.view.focusLineOvershoot()
        }
    }

    Rectangle {
        id: focusLineFill
        readonly property real computedWidth: Math.max(0, Math.round(parent.width * indicator.view.focusLineWidthPercent / 100))
        x: Math.max(0, Math.round((parent.width - width) / 2))
        y: indicator.view.indicatorY()
        width: computedWidth
        height: indicator.view.visibleFocusLineThickness
        radius: indicator.view.focusLineRadius
        color: indicator.view.dragPreviewActive ? indicator.view.colorWithOpacity(indicator.view.focusLineHoverColor, indicator.view.focusLineOpacity * Math.max(indicator.view.focusLineHoverOpacity, indicator.view.focusLineIndicatorOpacity)) : indicator.view.colorWithOpacity(indicator.view.focusLineIndicatorColor, indicator.view.focusLineOpacity * indicator.view.focusLineIndicatorOpacity)

        Behavior on color {
            enabled: indicator.view.animationEnabled
            ColorAnimation {
                duration: indicator.view.animationSpeed
            }
        }
    }
}

