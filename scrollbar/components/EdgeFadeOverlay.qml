import QtQuick
import qs.Commons

Rectangle {
    id: root

    property var barRoot: null
    property bool leading: true

    visible: {
        if (!barRoot || barRoot.edgeFadeSize <= 0)
            return false;
        return leading ? barRoot.showLeadingFade : barRoot.showTrailingFade;
    }

    z: 10
    color: "transparent"

    anchors.left: barRoot?.isVertical ? parent.left : (leading ? parent.left : undefined)
    anchors.right: barRoot?.isVertical ? parent.right : (!leading ? parent.right : undefined)
    anchors.top: !barRoot?.isVertical ? parent.top : (leading ? parent.top : undefined)
    anchors.bottom: !barRoot?.isVertical ? parent.bottom : (!leading ? parent.bottom : undefined)
    width: barRoot?.isVertical ? parent.width : (barRoot?.edgeFadeSize ?? 0)
    height: barRoot?.isVertical ? (barRoot?.edgeFadeSize ?? 0) : parent.height

    gradient: Gradient {
        orientation: barRoot?.isVertical ? Gradient.Vertical : Gradient.Horizontal

        GradientStop {
            position: 0.0
            color: leading ? (barRoot?.fadeBaseColor ?? Color.mSurface) : Qt.alpha(barRoot?.fadeBaseColor ?? Color.mSurface, 0.0)
        }
        GradientStop {
            position: leading ? (barRoot?.edgeFadeMidpoint ?? 0.45) : (1.0 - (barRoot?.edgeFadeMidpoint ?? 0.45))
            color: Qt.alpha(barRoot?.fadeBaseColor ?? Color.mSurface, barRoot?.edgeFadeMidOpacity ?? 0)
        }
        GradientStop {
            position: 1.0
            color: leading ? Qt.alpha(barRoot?.fadeBaseColor ?? Color.mSurface, 0.0) : (barRoot?.fadeBaseColor ?? Color.mSurface)
        }
    }
}
