import QtQuick
import qs.Commons

Item {
    id: root

    property var barRoot: null

    anchors.fill: parent
    clip: true
    visible: (barRoot?.showTrackLine ?? false) || (barRoot?.showFocusLine ?? false)

    Repeater {
        model: (barRoot?.showTrackLine ?? false) ? (barRoot?.combinedModel ?? []) : []

        Rectangle {
            required property int index

            readonly property var geometry: barRoot?.indicatorGeometryForIndex(index) ?? null
            readonly property bool vertical: barRoot?.isVertical ?? false

            visible: geometry !== null
            x: vertical ? (barRoot?.indicatorCrossOffset(width) ?? 0) : (geometry ? geometry.offset - (barRoot?.flickableRef?.contentX ?? 0) : 0)
            y: vertical ? (geometry ? geometry.offset - (barRoot?.flickableRef?.contentY ?? 0) : 0) : (barRoot?.indicatorCrossOffset(height) ?? 0)
            width: vertical ? (barRoot?.trackThickness ?? 1) : (geometry ? geometry.length : 0)
            height: vertical ? (geometry ? geometry.length : 0) : (barRoot?.trackThickness ?? 1)
            radius: vertical ? width / 2 : height / 2
            color: Qt.alpha(Color.mOutline, barRoot?.trackOpacity ?? 1)
            z: 0
        }
    }

    Rectangle {
        visible: (barRoot?.showTrackLine ?? false) && !(barRoot?.isVertical ?? false) && (barRoot?.logicalContentExtent ?? 0) > 0
        x: (barRoot?.logicalOverflowRange ?? 0) > 0 ? Math.round(((barRoot?.logicalScrollOffset ?? 0) / Math.max(1, barRoot?.logicalOverflowRange ?? 1)) * Math.max(0, parent.width - width)) : 0
        y: barRoot?.indicatorCrossOffset(height) ?? 0
        height: barRoot?.trackThickness ?? 1
        radius: height / 2
        width: Math.min(parent.width, Math.max(Style.marginXL, Math.round(((barRoot?.logicalViewportExtent ?? 0) / Math.max(1, barRoot?.logicalContentExtent ?? 1)) * parent.width)))
        color: Qt.alpha(barRoot?.trackThumbColor ?? Color.mPrimary, 0.85)
        z: 1
    }

    Rectangle {
        visible: (barRoot?.showFocusLine ?? false) && !(barRoot?.isVertical ?? false) && (barRoot?.focusedIndicatorInView ?? false)
        x: (barRoot?.animatedIndicatorOffset ?? 0) - (barRoot?.flickableRef?.contentX ?? 0)
        y: barRoot?.indicatorCrossOffset(height) ?? 0
        height: barRoot?.focusLineThickness ?? 1
        radius: height / 2
        width: barRoot?.animatedIndicatorLength ?? 0
        color: Qt.alpha(barRoot?.focusLineColor ?? Color.mSecondary, barRoot?.focusLineOpacity ?? 1)
        z: 2
    }

    Rectangle {
        visible: (barRoot?.showTrackLine ?? false) && (barRoot?.isVertical ?? false) && (barRoot?.logicalContentExtent ?? 0) > 0
        x: barRoot?.indicatorCrossOffset(width) ?? 0
        y: (barRoot?.logicalOverflowRange ?? 0) > 0 ? Math.round(((barRoot?.logicalScrollOffset ?? 0) / Math.max(1, barRoot?.logicalOverflowRange ?? 1)) * Math.max(0, parent.height - height)) : 0
        width: barRoot?.trackThickness ?? 1
        radius: width / 2
        height: Math.min(parent.height, Math.max(Style.marginXL, Math.round(((barRoot?.logicalViewportExtent ?? 0) / Math.max(1, barRoot?.logicalContentExtent ?? 1)) * parent.height)))
        color: Qt.alpha(barRoot?.trackThumbColor ?? Color.mPrimary, 0.85)
        z: 1
    }

    Rectangle {
        visible: (barRoot?.showFocusLine ?? false) && (barRoot?.isVertical ?? false) && (barRoot?.focusedIndicatorInView ?? false)
        x: barRoot?.indicatorCrossOffset(width) ?? 0
        y: (barRoot?.animatedIndicatorOffset ?? 0) - (barRoot?.flickableRef?.contentY ?? 0)
        width: barRoot?.focusLineThickness ?? 1
        radius: width / 2
        height: barRoot?.animatedIndicatorLength ?? 0
        color: Qt.alpha(barRoot?.focusLineColor ?? Color.mSecondary, barRoot?.focusLineOpacity ?? 1)
        z: 2
    }
}
