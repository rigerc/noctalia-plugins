import QtQuick

Item {
    id: indicator

    required property var view

    visible: view.effectiveFocusIndex >= 0 && view.availableContainerHeight > 0
    x: view.indicatorOffset(view.effectiveFocusIndex)
    y: 0
    width: view.segmentWidth
    height: view.availableContainerHeight
    // Keep the moving focus strip below segment content so state fills remain true backgrounds.
    z: 0

    Behavior on x {
        enabled: view.animationEnabled
        NumberAnimation {
            duration: view.animationSpeed
            easing.type: view.focusLineEasingType()
            easing.overshoot: view.focusLineOvershoot()
        }
    }

    Behavior on width {
        enabled: view.animationEnabled
        NumberAnimation {
            duration: view.animationSpeed
            easing.type: view.focusLineEasingType()
            easing.overshoot: view.focusLineOvershoot()
        }
    }

    Rectangle {
        id: focusLineFill
        readonly property real computedWidth: Math.max(0, Math.round(parent.width * view.focusLineWidthPercent / 100))
        x: Math.max(0, Math.round((parent.width - width) / 2))
        y: view.indicatorY()
        width: computedWidth
        height: view.visibleFocusLineThickness
        radius: view.focusLineRadius
        color: view.dragPreviewActive ? view.colorWithOpacity(view.focusLineHoverColor, view.focusLineOpacity * Math.max(view.focusLineHoverOpacity, view.focusLineIndicatorOpacity)) : view.colorWithOpacity(view.focusLineIndicatorColor, view.focusLineOpacity * view.focusLineIndicatorOpacity)

        Behavior on color {
            enabled: view.animationEnabled
            ColorAnimation {
                duration: view.animationSpeed
            }
        }
    }
}

