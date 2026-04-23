import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: container

    required property var view

    visible: view.showWorkspaceIndicator
    x: {
        if (view.workspaceIndicatorPosition === "left")
            return (view.pinnedSegmentCount > 0 && view.pinnedAppsPosition === "left" ? view.pinnedAreaWidth : 0) + view.workspaceIndicatorMarginLeft;
        return view.leftAccessoryWidth + view.actualTrackWidth + view.workspaceIndicatorMarginLeft;
    }
    y: view.workspaceIndicatorAlignedY()
    width: workspaceBackground.width
    height: workspaceBackground.height
    z: 30

    Rectangle {
        id: workspaceBackground
        width: Math.max(incomingIndicator.implicitWidth, outgoingIndicator.implicitWidth) + view.workspaceIndicatorPaddingX * 2
        height: Math.max(incomingIndicator.implicitHeight, outgoingIndicator.implicitHeight) + view.workspaceIndicatorPaddingY * 2
        radius: Math.min(view.workspaceIndicatorBorderRadius, Math.min(width, height) / 2)
        color: Qt.alpha(view.workspaceIndicatorBackgroundColor, view.workspaceIndicatorBackgroundOpacity)

        Item {
            anchors.fill: parent
            clip: true

            RowLayout {
                id: outgoingIndicator
                anchors.centerIn: parent
                spacing: Math.max(4, Math.round(4 * Style.uiScaleRatio))
                visible: view.outgoingWorkspaceText !== "" && view.workspaceIndicatorTransitionProgress < 1
                opacity: 1 - view.workspaceIndicatorTransitionProgress
                x: view.workspaceIndicatorAnimationAxis === "horizontal" ? Math.round((-view.workspaceIndicatorPaddingX * 1.5) * view.workspaceIndicatorTransitionProgress) : 0
                y: view.workspaceIndicatorAnimationAxis === "vertical" ? Math.round((-view.workspaceIndicatorPaddingY * 2) * view.workspaceIndicatorTransitionProgress) : 0

                NText {
                    text: view.outgoingWorkspaceText
                    color: Qt.alpha(view.workspaceIndicatorTextColor, view.workspaceIndicatorTextOpacity)
                    font.family: view.workspaceIndicatorFontFamily || Qt.application.font.family
                    font.weight: view.fontWeightValue(view.workspaceIndicatorFontWeightKey, Style.fontWeightMedium)
                    pointSize: view.workspaceIndicatorFontSize
                }

                Rectangle {
                    visible: view.workspaceIndicatorBadgeEnabled
                    radius: Math.min(height / 2, Math.round(999 * Style.uiScaleRatio))
                    color: Qt.alpha(view.workspaceIndicatorBadgeBackgroundColor, view.workspaceIndicatorBadgeBackgroundOpacity)
                    implicitWidth: badgeOutgoingText.implicitWidth + view.workspaceIndicatorPaddingX
                    implicitHeight: badgeOutgoingText.implicitHeight + view.workspaceIndicatorPaddingY

                    NText {
                        id: badgeOutgoingText
                        anchors.centerIn: parent
                        text: String(view.outgoingWorkspaceBadgeCount)
                        color: Qt.alpha(view.workspaceIndicatorBadgeTextColor, view.workspaceIndicatorBadgeTextOpacity)
                        font.family: view.workspaceIndicatorBadgeFontFamily || Qt.application.font.family
                        font.weight: view.fontWeightValue(view.workspaceIndicatorBadgeFontWeightKey, Style.fontWeightSemiBold)
                        pointSize: view.workspaceIndicatorBadgeFontSize
                    }
                }
            }

            RowLayout {
                id: incomingIndicator
                anchors.centerIn: parent
                spacing: Math.max(4, Math.round(4 * Style.uiScaleRatio))
                opacity: view.workspaceIndicatorAnimationEnabled ? view.workspaceIndicatorTransitionProgress : 1
                x: view.workspaceIndicatorAnimationAxis === "horizontal" ? Math.round((1 - view.workspaceIndicatorTransitionProgress) * view.workspaceIndicatorPaddingX * 1.5) : 0
                y: view.workspaceIndicatorAnimationAxis === "vertical" ? Math.round((1 - view.workspaceIndicatorTransitionProgress) * view.workspaceIndicatorPaddingY * 2) : 0

                NText {
                    text: view.displayedWorkspaceText
                    color: Qt.alpha(view.workspaceIndicatorTextColor, view.workspaceIndicatorTextOpacity)
                    font.family: view.workspaceIndicatorFontFamily || Qt.application.font.family
                    font.weight: view.fontWeightValue(view.workspaceIndicatorFontWeightKey, Style.fontWeightMedium)
                    pointSize: view.workspaceIndicatorFontSize
                }

                Rectangle {
                    visible: view.workspaceIndicatorBadgeEnabled
                    radius: Math.min(height / 2, Math.round(999 * Style.uiScaleRatio))
                    color: Qt.alpha(view.workspaceIndicatorBadgeBackgroundColor, view.workspaceIndicatorBadgeBackgroundOpacity)
                    implicitWidth: badgeIncomingText.implicitWidth + view.workspaceIndicatorPaddingX
                    implicitHeight: badgeIncomingText.implicitHeight + view.workspaceIndicatorPaddingY

                    NText {
                        id: badgeIncomingText
                        anchors.centerIn: parent
                        text: String(view.displayedWorkspaceBadgeCount)
                        color: Qt.alpha(view.workspaceIndicatorBadgeTextColor, view.workspaceIndicatorBadgeTextOpacity)
                        font.family: view.workspaceIndicatorBadgeFontFamily || Qt.application.font.family
                        font.weight: view.fontWeightValue(view.workspaceIndicatorBadgeFontWeightKey, Style.fontWeightSemiBold)
                        pointSize: view.workspaceIndicatorBadgeFontSize
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        visible: view.workspaceScrollSwitchEnabled
        onWheel: wheel => {
            const offset = wheel.angleDelta.y > 0 ? -1 : 1;
            view.mainInstance?.switchWorkspaceByOffset(view.screenName, offset);
            wheel.accepted = true;
        }
    }
}

