pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var visualData: ({})
    property real pointSize: Style.fontSizeL
    property bool applyUiScale: true
    property color color: Color.mOnSurface
    property bool colorize: false
    property color colorizeColor: Color.mOnSurface

    readonly property string sourceMode: String(visualData?.source || "icon")
    readonly property string iconName: String(visualData?.icon || "ai")
    readonly property string assetUrl: String(visualData?.assetUrl || "")
    readonly property bool useAsset: sourceMode === "asset" && assetUrl !== ""

    implicitWidth: Math.max(1, applyUiScale ? root.pointSize * Style.uiScaleRatio : root.pointSize)
    implicitHeight: Math.max(1, applyUiScale ? root.pointSize * Style.uiScaleRatio : root.pointSize)

    NIcon {
        anchors.fill: parent
        visible: !root.useAsset
        icon: root.iconName
        color: root.colorize ? root.colorizeColor : root.color
        pointSize: root.pointSize
        applyUiScale: root.applyUiScale
    }

    Image {
        id: assetImage
        anchors.fill: parent
        visible: root.useAsset
        source: root.assetUrl
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        cache: true
        sourceSize: Qt.size(width, height)

        layer.enabled: root.colorize
        layer.effect: ShaderEffect {
            property color targetColor: root.colorizeColor
            property real colorizeMode: 1.0
            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
        }
    }
}
