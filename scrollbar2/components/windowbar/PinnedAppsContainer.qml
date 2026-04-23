import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: container

    required property var view

    visible: view.pinnedSegmentCount > 0
    x: {
        if (view.pinnedAppsPosition === "left")
            return view.pinnedAppsMarginLeft;
        return view.leftAccessoryWidth + view.actualTrackWidth + (view.showWorkspaceIndicator && view.workspaceIndicatorPosition === "right" ? view.totalIndicatorWidth : 0) + view.pinnedAppsMarginLeft;
    }
    y: view.pinnedAppsAlignedY()
    width: view.pinnedAreaContentWidth
    height: view.pinnedSegmentCount > 0 ? view.pinnedSlotSize : 0
    z: 25

    Row {
        anchors.fill: parent
        spacing: view.segmentSpacing

        Repeater {
            model: view.pinnedEntries

            delegate: Item {
                id: pinnedItem

                required property var modelData

                readonly property string appId: modelData?.appId ?? ""
                readonly property string title: modelData?.name ?? appId

                width: view.pinnedSlotSize
                height: view.pinnedSlotSize

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(view.windowBorderRadius, Math.min(width, height) / 2)
                    color: view.pinnedSlotBackgroundColor(pinnedItem.appId)

                    Behavior on color {
                        enabled: view.animationEnabled
                        ColorAnimation {
                            duration: view.animationSpeed
                        }
                    }
                }

                IconImage {
                    id: pinnedCustomIcon
                    anchors.centerIn: parent
                    width: view.computedIconSize
                    height: view.computedIconSize
                    source: view.pinnedAppIconSource(pinnedItem.modelData)
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: visible && view.pinnedAppsIconColorKey !== "none"
                    layer.effect: ShaderEffect {
                        property color targetColor: view.pinnedAppsIconColor
                        property real colorizeMode: 0.0

                        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                }

                NText {
                    anchors.centerIn: parent
                    visible: !pinnedCustomIcon.visible
                    text: pinnedItem.title.length > 0 ? pinnedItem.title.charAt(0).toUpperCase() : "?"
                    pointSize: Math.max(Style.fontSizeXS, view.titleFontSize * view.titleScale * 0.95)
                    font.weight: Style.fontWeightBold
                    color: view.pinnedAppsIconColorKey === "none" ? Color.mOnSurface : view.pinnedAppsIconColor
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    onEntered: {
                        view.hoveredPinnedAppId = pinnedItem.appId;
                        if (pinnedItem.title)
                            TooltipService.show(pinnedItem, pinnedItem.title, BarService.getTooltipDirection(view.screen?.name));
                    }

                    onExited: {
                        if (view.hoveredPinnedAppId === pinnedItem.appId)
                            view.hoveredPinnedAppId = "";
                        TooltipService.hide();
                    }

                    onReleased: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            TooltipService.hide();
                            view.openContextMenu(pinnedItem, null, pinnedItem.modelData);
                        } else if (mouse.button === Qt.LeftButton) {
                            view.activatePinnedApp(pinnedItem.appId);
                        }
                    }
                }
            }
        }
    }
}

