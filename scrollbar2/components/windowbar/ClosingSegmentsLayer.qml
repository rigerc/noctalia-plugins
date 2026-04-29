pragma ComponentBehavior: Bound
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
    width: layer.view.effectiveTrackWidth
    height: layer.view.availableContainerHeight
    z: 19
    visible: (layer.view.closingEntries || []).length > 0

    Repeater {
        model: layer.view.closingEntries

        delegate: Item {
            id: closingSegment

            required property var modelData

            readonly property int closeUid: closingSegment.modelData?.uid ?? -1
            readonly property string appId: String(closingSegment.modelData?.appId ?? "")
            readonly property string title: String(closingSegment.modelData?.title ?? "")
            readonly property bool showLabel: closingSegment.modelData?.showLabel !== false

            x: closingSegment.modelData?.x ?? 0
            y: closingSegment.modelData?.y ?? 0
            width: closingSegment.modelData?.width ?? 0
            height: closingSegment.modelData?.height ?? 0
            clip: true
            opacity: 1
            scale: 1
            transformOrigin: Item.Center

            Rectangle {
                anchors.fill: parent
                anchors.margins: layer.view.windowMargin
                radius: Math.min(Math.max(0, layer.view.windowBorderRadius), Math.max(0, Math.min(width, height) / 2))
                color: closingSegment.modelData?.backgroundColor ?? "transparent"
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: layer.view.windowMargin
                anchors.leftMargin: layer.view.windowMargin + layer.view.windowPaddingLeft
                anchors.rightMargin: layer.view.windowMargin + layer.view.windowPaddingRight
                anchors.topMargin: layer.view.windowMargin + layer.view.windowPaddingTop
                anchors.bottomMargin: layer.view.windowMargin + layer.view.windowPaddingBottom
                spacing: layer.view.labelGap
                visible: layer.view.showIcon || layer.view.showTitle

                Item {
                    Layout.preferredWidth: layer.view.showIcon ? (layer.view.showTitle ? layer.view.computedIconSize : Math.max(layer.view.computedIconSize, closingSegment.width - (layer.view.windowMargin * 2) - layer.view.windowPaddingLeft - layer.view.windowPaddingRight)) : 0
                    Layout.preferredHeight: layer.view.showIcon ? layer.view.computedIconSize : 0
                    Layout.alignment: Qt.AlignVCenter
                    visible: layer.view.showIcon
                    opacity: closingSegment.showLabel ? 1 : 0

                    IconImage {
                        id: closingAppIcon
                        width: layer.view.computedIconSize
                        height: layer.view.computedIconSize
                        anchors.centerIn: parent
                        source: ThemeIcons.iconForAppId(closingSegment.appId)
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready && closingCustomIcon.visible === false
                    }

                    NIcon {
                        id: closingCustomIcon
                        width: layer.view.computedIconSize
                        height: layer.view.computedIconSize
                        anchors.centerIn: parent
                        icon: String(closingSegment.modelData?.customIcon ?? "")
                        pointSize: layer.view.computedIconSize
                        visible: icon !== ""
                        color: closingSegment.modelData?.iconColor ?? layer.view.titleColorDefault
                    }

                    NText {
                        width: layer.view.computedIconSize
                        anchors.centerIn: parent
                        horizontalAlignment: layer.view.horizontalAlignment(layer.view.iconAlign)
                        visible: !closingAppIcon.visible && !closingCustomIcon.visible
                        text: closingSegment.title.length > 0 ? closingSegment.title.charAt(0).toUpperCase() : "?"
                        pointSize: Math.max(Style.fontSizeXS, layer.view.titleFontSize * layer.view.titleScale * 0.95)
                        font.weight: Style.fontWeightBold
                        color: closingSegment.modelData?.iconColor ?? layer.view.titleColorDefault
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: closingTitle.implicitHeight
                    Layout.alignment: Qt.AlignVCenter
                    visible: layer.view.showTitle

                    NText {
                        id: closingTitle
                        anchors.fill: parent
                        text: closingSegment.title
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: closingSegment.showLabel ? 1 : 0
                        color: closingSegment.modelData?.titleColor ?? layer.view.titleColorDefault
                        horizontalAlignment: layer.view.horizontalAlignment(layer.view.titleAlign)
                        font.family: layer.view.titleFontFamily || Qt.application.font.family // qmllint disable missing-property
                        pointSize: layer.view.titleFontSize * layer.view.titleScale
                        font.weight: closingSegment.modelData?.titleWeight ?? Style.fontWeightMedium
                    }
                }
            }

            ParallelAnimation {
                id: closeAnimation
                running: layer.view.windowCloseAnimationActive

                NumberAnimation {
                    target: closingSegment
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: layer.view.windowAnimationSpeed
                    easing.type: layer.view.windowAnimationEasingType()
                    easing.overshoot: layer.view.windowAnimationOvershoot()
                }

                NumberAnimation {
                    target: closingSegment
                    property: "scale"
                    from: 1
                    to: 0.86
                    duration: layer.view.windowAnimationSpeed
                    easing.type: layer.view.windowAnimationEasingType()
                    easing.overshoot: layer.view.windowAnimationOvershoot()
                }

                onFinished: layer.view.removeClosingEntry(closingSegment.closeUid)
            }

            Component.onCompleted: {
                if (!layer.view.windowCloseAnimationActive)
                    layer.view.removeClosingEntry(closeUid);
            }
        }
    }
}

