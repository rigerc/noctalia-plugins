import QtQuick
import qs.Commons

Item {
    id: root

    property var barRoot: null

    anchors.fill: parent
    visible: (barRoot?.showTrackLine ?? false) || (barRoot?.showFocusLine ?? false)

    Rectangle {
        visible: (barRoot?.showTrackLine ?? false) && !(barRoot?.isVertical ?? false)
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        height: barRoot?.trackThickness ?? 1
        radius: height / 2
        color: Qt.alpha(Color.mOutline, barRoot?.trackOpacity ?? 1)
    }

    Rectangle {
        visible: (barRoot?.showTrackLine ?? false) && !(barRoot?.isVertical ?? false) && (barRoot?.flickableRef?.contentWidth ?? 0) > 0
        anchors.bottom: parent.bottom
        height: barRoot?.trackThickness ?? 1
        radius: height / 2
        width: Math.max(Style.marginXL, Math.round(((barRoot?.flickableRef?.width ?? 0) / Math.max(1, barRoot?.flickableRef?.contentWidth ?? 1)) * parent.width))
        x: (barRoot?.flickableRef?.contentWidth ?? 0) > (barRoot?.flickableRef?.width ?? 0) ? Math.round(((barRoot?.flickableRef?.contentX ?? 0) / Math.max(1, (barRoot?.flickableRef?.contentWidth ?? 0) - (barRoot?.flickableRef?.width ?? 0))) * Math.max(0, parent.width - width)) : 0
        color: Qt.alpha(barRoot?.trackThumbColor ?? Color.mPrimary, 0.85)
        z: 0
    }

    Rectangle {
        visible: (barRoot?.showFocusLine ?? false) && !(barRoot?.isVertical ?? false) && (barRoot?.focusedIndicatorInView ?? false)
        anchors.bottom: parent.bottom
        height: barRoot?.focusLineThickness ?? 1
        radius: height / 2
        width: barRoot?.animatedIndicatorLength ?? 0
        x: (barRoot?.animatedIndicatorOffset ?? 0) - (barRoot?.flickableRef?.contentX ?? 0)
        color: Qt.alpha(barRoot?.focusLineColor ?? Color.mSecondary, barRoot?.focusLineOpacity ?? 1)
        z: 0
    }

    Rectangle {
        visible: (barRoot?.showTrackLine ?? false) && (barRoot?.isVertical ?? false)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: 1
        width: barRoot?.trackThickness ?? 1
        radius: width / 2
        color: Qt.alpha(Color.mOutline, barRoot?.trackOpacity ?? 1)
        z: 0
    }

    Rectangle {
        visible: (barRoot?.showTrackLine ?? false) && (barRoot?.isVertical ?? false) && (barRoot?.flickableRef?.contentHeight ?? 0) > 0
        anchors.right: parent.right
        anchors.rightMargin: 1
        width: barRoot?.trackThickness ?? 1
        radius: width / 2
        height: Math.max(Style.marginXL, Math.round(((barRoot?.flickableRef?.height ?? 0) / Math.max(1, barRoot?.flickableRef?.contentHeight ?? 1)) * parent.height))
        y: (barRoot?.flickableRef?.contentHeight ?? 0) > (barRoot?.flickableRef?.height ?? 0) ? Math.round(((barRoot?.flickableRef?.contentY ?? 0) / Math.max(1, (barRoot?.flickableRef?.contentHeight ?? 0) - (barRoot?.flickableRef?.height ?? 0))) * Math.max(0, parent.height - height)) : 0
        color: Qt.alpha(barRoot?.trackThumbColor ?? Color.mPrimary, 0.85)
        z: 0
    }

    Rectangle {
        visible: (barRoot?.showFocusLine ?? false) && (barRoot?.isVertical ?? false) && (barRoot?.focusedIndicatorInView ?? false)
        anchors.right: parent.right
        width: barRoot?.focusLineThickness ?? 1
        radius: width / 2
        height: barRoot?.animatedIndicatorLength ?? 0
        y: (barRoot?.animatedIndicatorOffset ?? 0) - (barRoot?.flickableRef?.contentY ?? 0)
        color: Qt.alpha(barRoot?.focusLineColor ?? Color.mSecondary, barRoot?.focusLineOpacity ?? 1)
        z: 0
    }
}
