import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

Item {
    id: layer

    required property var view

    x: 0
    y: 0
    width: view.effectiveTrackWidth
    height: view.availableContainerHeight
    z: 19
    visible: (view.closingEntries || []).length > 0

    Repeater {
        model: view.closingEntries

        delegate: Item {
            id: closingSegment

            required property var modelData

            readonly property int closeUid: modelData?.uid ?? -1
            readonly property string appId: String(modelData?.appId ?? "")
            readonly property string title: String(modelData?.title ?? "")
            readonly property bool showLabel: modelData?.showLabel !== false

            x: modelData?.x ?? 0
            y: modelData?.y ?? 0
            width: modelData?.width ?? 0
            height: modelData?.height ?? 0
            clip: true
            opacity: 1
            scale: 1
            transformOrigin: Item.Center

            Rectangle {
                anchors.fill: parent
                anchors.margins: view.windowMargin
                radius: Math.min(Math.max(0, view.windowBorderRadius), Math.max(0, Math.min(width, height) / 2))
                color: modelData?.backgroundColor ?? "transparent"
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: view.windowMargin
                anchors.leftMargin: view.windowMargin + view.windowPaddingLeft
                anchors.rightMargin: view.windowMargin + view.windowPaddingRight
                anchors.topMargin: view.windowMargin + view.windowPaddingTop
                anchors.bottomMargin: view.windowMargin + view.windowPaddingBottom
                spacing: view.labelGap
                visible: view.showIcon || view.showTitle

                Item {
                    Layout.preferredWidth: view.showIcon ? (view.showTitle ? view.computedIconSize : Math.max(view.computedIconSize, closingSegment.width - (view.windowMargin * 2) - view.windowPaddingLeft - view.windowPaddingRight)) : 0
                    Layout.preferredHeight: view.showIcon ? view.computedIconSize : 0
                    Layout.alignment: Qt.AlignVCenter
                    visible: view.showIcon
                    opacity: closingSegment.showLabel ? 1 : 0

                    IconImage {
                        id: closingAppIcon
                        width: view.computedIconSize
                        height: view.computedIconSize
                        anchors.centerIn: parent
                        source: ThemeIcons.iconForAppId(closingSegment.appId)
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready && closingCustomIcon.visible === false
                    }

                    NIcon {
                        id: closingCustomIcon
                        width: view.computedIconSize
                        height: view.computedIconSize
                        anchors.centerIn: parent
                        icon: String(modelData?.customIcon ?? "")
                        pointSize: view.computedIconSize
                        visible: icon !== ""
                        color: modelData?.iconColor ?? view.titleColorDefault
                    }

                    NText {
                        width: view.computedIconSize
                        anchors.centerIn: parent
                        horizontalAlignment: view.horizontalAlignment(view.iconAlign)
                        visible: !closingAppIcon.visible && !closingCustomIcon.visible
                        text: closingSegment.title.length > 0 ? closingSegment.title.charAt(0).toUpperCase() : "?"
                        pointSize: Math.max(Style.fontSizeXS, view.titleFontSize * view.titleScale * 0.95)
                        font.weight: Style.fontWeightBold
                        color: modelData?.iconColor ?? view.titleColorDefault
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: closingTitle.implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    visible: view.showTitle

                    NText {
                        id: closingTitle
                        anchors.fill: parent
                        text: closingSegment.title
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: closingSegment.showLabel ? 1 : 0
                        color: modelData?.titleColor ?? view.titleColorDefault
                        horizontalAlignment: view.horizontalAlignment(view.titleAlign)
                        font.family: view.titleFontFamily || Qt.application.font.family
                        pointSize: view.titleFontSize * view.titleScale
                        font.weight: modelData?.titleWeight ?? Style.fontWeightMedium
                    }
                }
            }

            ParallelAnimation {
                id: closeAnimation
                running: view.windowCloseAnimationActive

                NumberAnimation {
                    target: closingSegment
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: view.windowAnimationSpeed
                    easing.type: view.windowAnimationEasingType()
                    easing.overshoot: view.windowAnimationOvershoot()
                }

                NumberAnimation {
                    target: closingSegment
                    property: "scale"
                    from: 1
                    to: 0.86
                    duration: view.windowAnimationSpeed
                    easing.type: view.windowAnimationEasingType()
                    easing.overshoot: view.windowAnimationOvershoot()
                }

                onFinished: view.removeClosingEntry(closingSegment.closeUid)
            }

            Component.onCompleted: {
                if (!view.windowCloseAnimationActive)
                    view.removeClosingEntry(closeUid);
            }
        }
    }
}

