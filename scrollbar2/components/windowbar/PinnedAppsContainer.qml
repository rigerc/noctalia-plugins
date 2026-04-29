pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: container

    required property var view

    visible: container.view.pinnedSegmentCount > 0
    x: {
        if (container.view.pinnedAppsPosition === "left")
            return container.view.pinnedAppsMarginLeft;
        return container.view.leftAccessoryWidth + container.view.actualTrackWidth + (container.view.showWorkspaceIndicator && container.view.workspaceIndicatorPosition === "right" ? container.view.totalIndicatorWidth : 0) + container.view.pinnedAppsMarginLeft;
    }
    y: container.view.pinnedAppsAlignedY()
    width: container.view.pinnedAreaContentWidth
    height: container.view.pinnedSegmentCount > 0 ? container.view.pinnedSlotSize : 0
    z: 25

    Row {
        anchors.fill: parent
        spacing: container.view.segmentSpacing

        Repeater {
            model: container.view.pinnedEntries

            delegate: Item {
                id: pinnedItem

                required property var modelData

                readonly property string appId: modelData?.appId ?? ""
                readonly property string title: modelData?.name ?? appId

                width: container.view.pinnedSlotSize
                height: container.view.pinnedSlotSize

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(container.view.windowBorderRadius, Math.min(width, height) / 2)
                    color: container.view.pinnedSlotBackgroundColor(pinnedItem.appId)

                    Behavior on color {
                        enabled: container.view.animationEnabled
                        ColorAnimation {
                            duration: container.view.animationSpeed
                        }
                    }
                }

                IconImage {
                    id: pinnedCustomIcon
                    anchors.centerIn: parent
                    width: container.view.computedIconSize
                    height: container.view.computedIconSize
                    source: container.view.pinnedAppIconSource(pinnedItem.modelData)
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: visible && container.view.pinnedAppsIconColorKey !== "none"
                    layer.effect: ShaderEffect {
                        property color targetColor: container.view.pinnedAppsIconColor
                        property real colorizeMode: 0.0

                        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                }

                NText {
                    anchors.centerIn: parent
                    visible: !pinnedCustomIcon.visible
                    text: pinnedItem.title.length > 0 ? pinnedItem.title.charAt(0).toUpperCase() : "?"
                    pointSize: Math.max(Style.fontSizeXS, container.view.titleFontSize * container.view.titleScale * 0.95)
                    font.weight: Style.fontWeightBold
                    color: container.view.pinnedAppsIconColorKey === "none" ? Color.mOnSurface : container.view.pinnedAppsIconColor
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    onEntered: {
                        container.view.hoveredPinnedAppId = pinnedItem.appId;
                        if (pinnedItem.title)
                            TooltipService.show(pinnedItem, pinnedItem.title, BarService.getTooltipDirection(container.view.screen?.name));
                    }

                    onExited: {
                        if (container.view.hoveredPinnedAppId === pinnedItem.appId)
                            container.view.hoveredPinnedAppId = "";
                        TooltipService.hide();
                    }

                    onReleased: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            TooltipService.hide();
                            container.view.openContextMenu(pinnedItem, null, pinnedItem.modelData);
                        } else if (mouse.button === Qt.LeftButton) {
                            container.view.activatePinnedApp(pinnedItem.appId);
                        }
                    }
                }
            }
        }
    }
}

