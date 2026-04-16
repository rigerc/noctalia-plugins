import QtQuick
import qs.Commons

Rectangle {
    id: root

    property var barRoot: null
    property bool leading: true
    readonly property real fadeMidpoint: 0.4
    readonly property bool cueVisible: leading ? (barRoot?.showLeadingFade ?? false) : (barRoot?.showTrailingFade ?? false)
    readonly property bool showFade: cueVisible && (barRoot?.edgeCueMode === "fade") && ((barRoot?.edgeFadeSize ?? 0) > 0)
    readonly property bool showBorder: cueVisible && (barRoot?.edgeCueMode === "border") && ((barRoot?.edgeBorderThickness ?? 0) > 0)
    readonly property bool shouldShowCue: showFade || showBorder
    property string renderedCueMode: showFade ? "fade" : (showBorder ? "border" : "off")
    property real renderedExtent: showFade ? (barRoot?.edgeFadeSize ?? 0) : (showBorder ? (barRoot?.edgeBorderThickness ?? 0) : 0)

    visible: opacity > 0 || shouldShowCue
    opacity: shouldShowCue ? 1.0 : 0.0

    z: 10
    color: "transparent"
    clip: true

    anchors.left: barRoot?.isVertical ? parent.left : (leading ? parent.left : undefined)
    anchors.right: barRoot?.isVertical ? parent.right : (!leading ? parent.right : undefined)
    anchors.top: !barRoot?.isVertical ? parent.top : (leading ? parent.top : undefined)
    anchors.bottom: !barRoot?.isVertical ? parent.bottom : (!leading ? parent.bottom : undefined)
    width: barRoot?.isVertical ? parent.width : renderedExtent
    height: barRoot?.isVertical ? renderedExtent : parent.height

    gradient: root.renderedCueMode === "fade" ? fadeGradient : null

    onShowFadeChanged: {
        if (showFade) {
            renderedCueMode = "fade";
            renderedExtent = barRoot?.edgeFadeSize ?? 0;
        }
    }

    onShowBorderChanged: {
        if (showBorder) {
            renderedCueMode = "border";
            renderedExtent = barRoot?.edgeBorderThickness ?? 0;
        }
    }

    Gradient {
        id: fadeGradient
        orientation: barRoot?.isVertical ? Gradient.Vertical : Gradient.Horizontal

        GradientStop {
            position: 0.0
            color: leading ? (barRoot?.fadeBaseColor ?? Color.mSurface) : Qt.alpha(barRoot?.fadeBaseColor ?? Color.mSurface, 0.0)
        }
        GradientStop {
            position: leading ? root.fadeMidpoint : (1.0 - root.fadeMidpoint)
            color: Qt.alpha(barRoot?.fadeBaseColor ?? Color.mSurface, barRoot?.edgeFadeOpacity ?? 1.0)
        }
        GradientStop {
            position: 1.0
            color: leading ? Qt.alpha(barRoot?.fadeBaseColor ?? Color.mSurface, 0.0) : (barRoot?.fadeBaseColor ?? Color.mSurface)
        }
    }

    Rectangle {
        visible: root.renderedCueMode === "border"
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
