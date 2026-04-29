import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: container

    required property var view

    visible: container.view.showWorkspaceIndicator
    x: {
        if (container.view.workspaceIndicatorPosition === "left")
            return (container.view.pinnedSegmentCount > 0 && container.view.pinnedAppsPosition === "left" ? container.view.pinnedAreaWidth : 0) + container.view.workspaceIndicatorMarginLeft;
        return container.view.leftAccessoryWidth + container.view.actualTrackWidth + container.view.workspaceIndicatorMarginLeft;
    }
    y: container.view.workspaceIndicatorAlignedY()
    width: workspaceBackground.width
    height: workspaceBackground.height
    z: 30

    Rectangle {
        id: workspaceBackground
        width: Math.max(incomingIndicator.implicitWidth, outgoingIndicator.implicitWidth) + container.view.workspaceIndicatorPaddingX * 2
        height: Math.max(incomingIndicator.implicitHeight, outgoingIndicator.implicitHeight) + container.view.workspaceIndicatorPaddingY * 2
        radius: Math.min(container.view.workspaceIndicatorBorderRadius, Math.min(width, height) / 2)
        color: Qt.alpha(container.view.workspaceIndicatorBackgroundColor, container.view.workspaceIndicatorBackgroundOpacity)

        Item {
            anchors.fill: parent
            clip: true

            RowLayout {
                id: outgoingIndicator
                anchors.centerIn: parent
                spacing: Math.max(4, Math.round(4 * Style.uiScaleRatio))
                visible: container.view.outgoingWorkspaceText !== "" && container.view.workspaceIndicatorTransitionProgress < 1
                opacity: 1 - container.view.workspaceIndicatorTransitionProgress
                x: container.view.workspaceIndicatorAnimationAxis === "horizontal" ? Math.round((-container.view.workspaceIndicatorPaddingX * 1.5) * container.view.workspaceIndicatorTransitionProgress) : 0
                y: container.view.workspaceIndicatorAnimationAxis === "vertical" ? Math.round((-container.view.workspaceIndicatorPaddingY * 2) * container.view.workspaceIndicatorTransitionProgress) : 0

                NText {
                    text: container.view.outgoingWorkspaceText
                    color: Qt.alpha(container.view.workspaceIndicatorTextColor, container.view.workspaceIndicatorTextOpacity)
                    font.family: container.view.workspaceIndicatorFontFamily || Qt.application.font.family // qmllint disable missing-property
                    font.weight: container.view.fontWeightValue(container.view.workspaceIndicatorFontWeightKey, Style.fontWeightMedium)
                    pointSize: container.view.workspaceIndicatorFontSize
                }

                Rectangle {
                    visible: container.view.workspaceIndicatorBadgeEnabled
                    radius: Math.min(height / 2, Math.round(999 * Style.uiScaleRatio))
                    color: Qt.alpha(container.view.workspaceIndicatorBadgeBackgroundColor, container.view.workspaceIndicatorBadgeBackgroundOpacity)
                    implicitWidth: badgeOutgoingText.implicitWidth + container.view.workspaceIndicatorPaddingX
                    implicitHeight: badgeOutgoingText.implicitHeight + container.view.workspaceIndicatorPaddingY

                    NText {
                        id: badgeOutgoingText
                        anchors.centerIn: parent
                        text: String(container.view.outgoingWorkspaceBadgeCount)
                        color: Qt.alpha(container.view.workspaceIndicatorBadgeTextColor, container.view.workspaceIndicatorBadgeTextOpacity)
                        font.family: container.view.workspaceIndicatorBadgeFontFamily || Qt.application.font.family // qmllint disable missing-property
                        font.weight: container.view.fontWeightValue(container.view.workspaceIndicatorBadgeFontWeightKey, Style.fontWeightSemiBold)
                        pointSize: container.view.workspaceIndicatorBadgeFontSize
                    }
                }
            }

            RowLayout {
                id: incomingIndicator
                anchors.centerIn: parent
                spacing: Math.max(4, Math.round(4 * Style.uiScaleRatio))
                opacity: container.view.workspaceIndicatorAnimationEnabled ? container.view.workspaceIndicatorTransitionProgress : 1
                x: container.view.workspaceIndicatorAnimationAxis === "horizontal" ? Math.round((1 - container.view.workspaceIndicatorTransitionProgress) * container.view.workspaceIndicatorPaddingX * 1.5) : 0
                y: container.view.workspaceIndicatorAnimationAxis === "vertical" ? Math.round((1 - container.view.workspaceIndicatorTransitionProgress) * container.view.workspaceIndicatorPaddingY * 2) : 0

                NText {
                    text: container.view.displayedWorkspaceText
                    color: Qt.alpha(container.view.workspaceIndicatorTextColor, container.view.workspaceIndicatorTextOpacity)
                    font.family: container.view.workspaceIndicatorFontFamily || Qt.application.font.family // qmllint disable missing-property
                    font.weight: container.view.fontWeightValue(container.view.workspaceIndicatorFontWeightKey, Style.fontWeightMedium)
                    pointSize: container.view.workspaceIndicatorFontSize
                }

                Rectangle {
                    visible: container.view.workspaceIndicatorBadgeEnabled
                    radius: Math.min(height / 2, Math.round(999 * Style.uiScaleRatio))
                    color: Qt.alpha(container.view.workspaceIndicatorBadgeBackgroundColor, container.view.workspaceIndicatorBadgeBackgroundOpacity)
                    implicitWidth: badgeIncomingText.implicitWidth + container.view.workspaceIndicatorPaddingX
                    implicitHeight: badgeIncomingText.implicitHeight + container.view.workspaceIndicatorPaddingY

                    NText {
                        id: badgeIncomingText
                        anchors.centerIn: parent
                        text: String(container.view.displayedWorkspaceBadgeCount)
                        color: Qt.alpha(container.view.workspaceIndicatorBadgeTextColor, container.view.workspaceIndicatorBadgeTextOpacity)
                        font.family: container.view.workspaceIndicatorBadgeFontFamily || Qt.application.font.family // qmllint disable missing-property
                        font.weight: container.view.fontWeightValue(container.view.workspaceIndicatorBadgeFontWeightKey, Style.fontWeightSemiBold)
                        pointSize: container.view.workspaceIndicatorBadgeFontSize
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        visible: container.view.workspaceScrollSwitchEnabled
        onWheel: wheel => {
            const offset = wheel.angleDelta.y > 0 ? -1 : 1;
            container.view.mainInstance?.switchWorkspaceByOffset(container.view.screenName, offset);
            wheel.accepted = true;
        }
    }
}

