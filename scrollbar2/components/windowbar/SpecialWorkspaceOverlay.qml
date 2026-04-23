import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

Rectangle {
    id: overlay

    required property var view

    visible: view.showSpecialWorkspaceOverlay
    x: Math.round(((parent ? parent.width : 0) - width) / 2)
    y: view.specialWorkspaceOverlayY()
    width: view.specialWorkspaceOverlayWidth
    height: view.specialWorkspaceOverlayHeight
    radius: Math.min(view.specialWorkspaceOverlayBorderRadius, Math.min(width, height) / 2)
    color: Qt.alpha(view.specialWorkspaceOverlayBackgroundColor, view.specialWorkspaceOverlayBackgroundOpacity)
    z: 22
    opacity: view.showSpecialWorkspaceOverlay ? 1 : 0
    scale: view.showSpecialWorkspaceOverlay ? 1 : 0.92

    Behavior on opacity {
        enabled: view.specialWorkspaceOverlayAnimationEnabled
        NumberAnimation {
            duration: view.specialWorkspaceOverlayAnimationSpeed
            easing.type: view.specialWorkspaceOverlayEasingType()
            easing.overshoot: view.specialWorkspaceOverlayOvershoot()
        }
    }

    Behavior on scale {
        enabled: view.specialWorkspaceOverlayAnimationEnabled
        NumberAnimation {
            duration: view.specialWorkspaceOverlayAnimationSpeed
            easing.type: view.specialWorkspaceOverlayEasingType()
            easing.overshoot: view.specialWorkspaceOverlayOvershoot()
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: (view.outgoingSpecialWorkspaceText !== "" && view.outgoingSpecialWorkspaceIcons.length > 0) ? view.specialWorkspaceOverlayIconGap : 0
            visible: view.outgoingSpecialWorkspaceText !== "" && view.specialWorkspaceOverlayTransitionProgress < 1
            opacity: 1 - view.specialWorkspaceOverlayTransitionProgress
            x: view.specialWorkspaceOverlayAnimationAxis === "horizontal" ? Math.round(-view.specialWorkspaceOverlayTransitionOffset() * view.specialWorkspaceOverlayTransitionProgress) : 0
            y: view.specialWorkspaceOverlayAnimationAxis === "vertical" ? Math.round(-view.specialWorkspaceOverlayTransitionOffset() * view.specialWorkspaceOverlayTransitionProgress) : 0

            NText {
                readonly property real iconsWidth: view.outgoingSpecialWorkspaceIcons.length > 0 ? (view.outgoingSpecialWorkspaceIcons.length * view.specialWorkspaceOverlayIconSize) + ((view.outgoingSpecialWorkspaceIcons.length - 1) * view.specialWorkspaceOverlayIconGap) : 0
                readonly property real maxTextWidth: Math.max(0, overlay.width - (view.specialWorkspaceOverlayContentPadding * 2) - iconsWidth - (view.outgoingSpecialWorkspaceIcons.length > 0 ? view.specialWorkspaceOverlayIconGap : 0))
                width: Math.min(implicitWidth, maxTextWidth)
                text: view.outgoingSpecialWorkspaceText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Qt.alpha(view.specialWorkspaceOverlayTextColor, view.specialWorkspaceOverlayTextOpacity)
                font.family: view.specialWorkspaceOverlayFontFamily || Qt.application.font.family
                font.weight: view.fontWeightValue(view.specialWorkspaceOverlayFontWeightKey, Style.fontWeightMedium)
                pointSize: view.specialWorkspaceOverlayFontSize
            }

            Repeater {
                model: view.outgoingSpecialWorkspaceIcons

                delegate: IconImage {
                    required property var modelData

                    width: view.specialWorkspaceOverlayIconSize
                    height: width
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    source: ThemeIcons.iconForAppId(String(modelData || ""))
                    smooth: true
                    asynchronous: true
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: (view.displayedSpecialWorkspaceText !== "" && view.displayedSpecialWorkspaceIcons.length > 0) ? view.specialWorkspaceOverlayIconGap : 0
            opacity: view.specialWorkspaceOverlayAnimationEnabled ? view.specialWorkspaceOverlayTransitionProgress : 1
            x: view.specialWorkspaceOverlayAnimationEnabled && view.specialWorkspaceOverlayAnimationAxis === "horizontal" ? Math.round((1 - view.specialWorkspaceOverlayTransitionProgress) * view.specialWorkspaceOverlayTransitionOffset()) : 0
            y: view.specialWorkspaceOverlayAnimationEnabled && view.specialWorkspaceOverlayAnimationAxis === "vertical" ? Math.round((1 - view.specialWorkspaceOverlayTransitionProgress) * view.specialWorkspaceOverlayTransitionOffset()) : 0

            NText {
                readonly property real iconsWidth: view.displayedSpecialWorkspaceIcons.length > 0 ? (view.displayedSpecialWorkspaceIcons.length * view.specialWorkspaceOverlayIconSize) + ((view.displayedSpecialWorkspaceIcons.length - 1) * view.specialWorkspaceOverlayIconGap) : 0
                readonly property real maxTextWidth: Math.max(0, overlay.width - (view.specialWorkspaceOverlayContentPadding * 2) - iconsWidth - (view.displayedSpecialWorkspaceIcons.length > 0 ? view.specialWorkspaceOverlayIconGap : 0))
                width: Math.min(implicitWidth, maxTextWidth)
                text: view.displayedSpecialWorkspaceText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Qt.alpha(view.specialWorkspaceOverlayTextColor, view.specialWorkspaceOverlayTextOpacity)
                font.family: view.specialWorkspaceOverlayFontFamily || Qt.application.font.family
                font.weight: view.fontWeightValue(view.specialWorkspaceOverlayFontWeightKey, Style.fontWeightMedium)
                pointSize: view.specialWorkspaceOverlayFontSize
            }

            Repeater {
                model: view.displayedSpecialWorkspaceIcons

                delegate: IconImage {
                    required property var modelData

                    width: view.specialWorkspaceOverlayIconSize
                    height: width
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    source: ThemeIcons.iconForAppId(String(modelData || ""))
                    smooth: true
                    asynchronous: true
                }
            }
        }
    }
}

