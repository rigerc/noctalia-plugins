pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

Rectangle {
    id: overlay

    required property var view

    visible: overlay.view.showSpecialWorkspaceOverlay
    x: Math.round(((parent ? parent.width : 0) - width) / 2)
    y: overlay.view.specialWorkspaceOverlayY()
    width: overlay.view.specialWorkspaceOverlayWidth
    height: overlay.view.specialWorkspaceOverlayHeight
    radius: Math.min(overlay.view.specialWorkspaceOverlayBorderRadius, Math.min(width, height) / 2)
    color: Qt.alpha(overlay.view.specialWorkspaceOverlayBackgroundColor, overlay.view.specialWorkspaceOverlayBackgroundOpacity)
    z: 22
    opacity: overlay.view.showSpecialWorkspaceOverlay ? 1 : 0
    scale: overlay.view.showSpecialWorkspaceOverlay ? 1 : 0.92

    Behavior on opacity {
        enabled: overlay.view.specialWorkspaceOverlayAnimationEnabled
        NumberAnimation {
            duration: overlay.view.specialWorkspaceOverlayAnimationSpeed
            easing.type: overlay.view.specialWorkspaceOverlayEasingType()
            easing.overshoot: overlay.view.specialWorkspaceOverlayOvershoot()
        }
    }

    Behavior on scale {
        enabled: overlay.view.specialWorkspaceOverlayAnimationEnabled
        NumberAnimation {
            duration: overlay.view.specialWorkspaceOverlayAnimationSpeed
            easing.type: overlay.view.specialWorkspaceOverlayEasingType()
            easing.overshoot: overlay.view.specialWorkspaceOverlayOvershoot()
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Row {
            anchors.centerIn: parent
            spacing: (overlay.view.outgoingSpecialWorkspaceText !== "" && overlay.view.outgoingSpecialWorkspaceIcons.length > 0) ? overlay.view.specialWorkspaceOverlayIconGap : 0
            visible: overlay.view.outgoingSpecialWorkspaceText !== "" && overlay.view.specialWorkspaceOverlayTransitionProgress < 1
            opacity: 1 - overlay.view.specialWorkspaceOverlayTransitionProgress
            x: overlay.view.specialWorkspaceOverlayAnimationAxis === "horizontal" ? Math.round(-overlay.view.specialWorkspaceOverlayTransitionOffset() * overlay.view.specialWorkspaceOverlayTransitionProgress) : 0
            y: overlay.view.specialWorkspaceOverlayAnimationAxis === "vertical" ? Math.round(-overlay.view.specialWorkspaceOverlayTransitionOffset() * overlay.view.specialWorkspaceOverlayTransitionProgress) : 0

            NText {
                readonly property real iconsWidth: overlay.view.outgoingSpecialWorkspaceIcons.length > 0 ? (overlay.view.outgoingSpecialWorkspaceIcons.length * overlay.view.specialWorkspaceOverlayIconSize) + ((overlay.view.outgoingSpecialWorkspaceIcons.length - 1) * overlay.view.specialWorkspaceOverlayIconGap) : 0
                readonly property real maxTextWidth: Math.max(0, overlay.width - (overlay.view.specialWorkspaceOverlayContentPadding * 2) - iconsWidth - (overlay.view.outgoingSpecialWorkspaceIcons.length > 0 ? overlay.view.specialWorkspaceOverlayIconGap : 0))
                width: Math.min(implicitWidth, maxTextWidth)
                text: overlay.view.outgoingSpecialWorkspaceText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Qt.alpha(overlay.view.specialWorkspaceOverlayTextColor, overlay.view.specialWorkspaceOverlayTextOpacity)
                font.family: overlay.view.specialWorkspaceOverlayFontFamily || Qt.application.font.family // qmllint disable missing-property
                font.weight: overlay.view.fontWeightValue(overlay.view.specialWorkspaceOverlayFontWeightKey, Style.fontWeightMedium)
                pointSize: overlay.view.specialWorkspaceOverlayFontSize
            }

            Repeater {
                model: overlay.view.outgoingSpecialWorkspaceIcons

                delegate: IconImage {
                    required property var modelData

                    width: overlay.view.specialWorkspaceOverlayIconSize
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
            spacing: (overlay.view.displayedSpecialWorkspaceText !== "" && overlay.view.displayedSpecialWorkspaceIcons.length > 0) ? overlay.view.specialWorkspaceOverlayIconGap : 0
            opacity: overlay.view.specialWorkspaceOverlayAnimationEnabled ? overlay.view.specialWorkspaceOverlayTransitionProgress : 1
            x: overlay.view.specialWorkspaceOverlayAnimationEnabled && overlay.view.specialWorkspaceOverlayAnimationAxis === "horizontal" ? Math.round((1 - overlay.view.specialWorkspaceOverlayTransitionProgress) * overlay.view.specialWorkspaceOverlayTransitionOffset()) : 0
            y: overlay.view.specialWorkspaceOverlayAnimationEnabled && overlay.view.specialWorkspaceOverlayAnimationAxis === "vertical" ? Math.round((1 - overlay.view.specialWorkspaceOverlayTransitionProgress) * overlay.view.specialWorkspaceOverlayTransitionOffset()) : 0

            NText {
                readonly property real iconsWidth: overlay.view.displayedSpecialWorkspaceIcons.length > 0 ? (overlay.view.displayedSpecialWorkspaceIcons.length * overlay.view.specialWorkspaceOverlayIconSize) + ((overlay.view.displayedSpecialWorkspaceIcons.length - 1) * overlay.view.specialWorkspaceOverlayIconGap) : 0
                readonly property real maxTextWidth: Math.max(0, overlay.width - (overlay.view.specialWorkspaceOverlayContentPadding * 2) - iconsWidth - (overlay.view.displayedSpecialWorkspaceIcons.length > 0 ? overlay.view.specialWorkspaceOverlayIconGap : 0))
                width: Math.min(implicitWidth, maxTextWidth)
                text: overlay.view.displayedSpecialWorkspaceText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                color: Qt.alpha(overlay.view.specialWorkspaceOverlayTextColor, overlay.view.specialWorkspaceOverlayTextOpacity)
                font.family: overlay.view.specialWorkspaceOverlayFontFamily || Qt.application.font.family // qmllint disable missing-property
                font.weight: overlay.view.fontWeightValue(overlay.view.specialWorkspaceOverlayFontWeightKey, Style.fontWeightMedium)
                pointSize: overlay.view.specialWorkspaceOverlayFontSize
            }

            Repeater {
                model: overlay.view.displayedSpecialWorkspaceIcons

                delegate: IconImage {
                    required property var modelData

                    width: overlay.view.specialWorkspaceOverlayIconSize
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

