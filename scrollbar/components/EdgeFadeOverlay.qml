import QtQuick
import qs.Commons

Rectangle {
    id: root

    property var barRoot: null
    property bool leading: true
    readonly property bool cueVisible: leading ? (barRoot?.showLeadingFade ?? false) : (barRoot?.showTrailingFade ?? false)
    readonly property bool showBorder: cueVisible && (barRoot?.edgeCueMode === "border") && ((barRoot?.edgeBorderThickness ?? 0) > 0)
    readonly property real renderedExtent: showBorder ? (barRoot?.edgeBorderThickness ?? 0) : 0

    visible: opacity > 0 || showBorder
    opacity: showBorder ? 1.0 : 0.0

    z: 10
    color: "transparent"
    clip: true

    anchors.left: barRoot?.isVertical ? parent.left : (leading ? parent.left : undefined)
    anchors.right: barRoot?.isVertical ? parent.right : (!leading ? parent.right : undefined)
    anchors.top: !barRoot?.isVertical ? parent.top : (leading ? parent.top : undefined)
    anchors.bottom: !barRoot?.isVertical ? parent.bottom : (!leading ? parent.bottom : undefined)
    width: barRoot?.isVertical ? parent.width : renderedExtent
    height: barRoot?.isVertical ? renderedExtent : parent.height

    Rectangle {
        visible: root.showBorder
        anchors.fill: parent
        color: barRoot?.edgeBorderColor ?? "transparent"
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Style.animationSlow
            easing.type: Easing.OutQuad
        }
    }
}
