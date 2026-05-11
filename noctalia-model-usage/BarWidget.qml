import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "./components"

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var mainInstance: pluginApi?.mainInstance
    property var activeProvider: mainInstance?.activeProvider

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    property string barMetric: mainInstance?.barMetric ?? "prompts"
    property bool barShowRemaining: mainInstance?.barShowRemaining ?? false
    property bool barTextShowOnHover: mainInstance?.barTextShowOnHover ?? false
    property bool barIconAlertOnLimit: mainInstance?.barIconAlertOnLimit ?? false
    property int barIconAlertThreshold: Math.max(50, Math.min(100, Number(mainInstance?.barIconAlertThreshold ?? 95)))

    readonly property color resolvedProviderIconColor: {
        if (!root.barIconAlertOnLimit || !root.activeProvider)
            return Color.mOnSurface;

        const rl = root.activeProvider.rateLimitPercent ?? -1;
        const rl5h = root.activeProvider.secondaryRateLimitPercent ?? -1;

        if ((rl >= 0 && Math.round(rl * 100) >= root.barIconAlertThreshold) ||
            (rl5h >= 0 && Math.round(rl5h * 100) >= root.barIconAlertThreshold))
            return Color.mError;

        return Color.mOnSurface;
    }

    function formatUsagePercent(rawPercent) {
        const used = Math.round(rawPercent * 100);
        if (root.barShowRemaining)
            return Math.max(0, 100 - used) + "%";
        return used + "%";
    }

    function formatUsageWithPrefix(percent, prefix) {
        if (!(percent >= 0))
            return "\u2014";
        return prefix + ": " + root.formatUsagePercent(percent);
    }

    property string displayText: {
        if (!activeProvider)
            return "\u2014";
        if (barMetric === "usage") {
            const rl = activeProvider.rateLimitPercent ?? -1;
            if (!(rl >= 0)) {
                const status = String(activeProvider.usageStatusText ?? "");
                if (status !== "")
                    return status;
                return "\u2014";
            }
            return root.formatUsageWithPrefix(rl, "7d");
        }
        if (barMetric === "usage5h") {
            const rl = activeProvider.secondaryRateLimitPercent ?? -1;
            if (!(rl >= 0)) {
                const status = String(activeProvider.usageStatusText ?? "");
                if (status !== "")
                    return status;
                return "\u2014";
            }
            return root.formatUsageWithPrefix(rl, "5h");
        }
        if (barMetric === "usage5h7d") {
            const rl5h = activeProvider.secondaryRateLimitPercent ?? -1;
            const rl7d = activeProvider.rateLimitPercent ?? -1;
            if (!(rl5h >= 0) && !(rl7d >= 0)) {
                const status = String(activeProvider.usageStatusText ?? "");
                if (status !== "")
                    return status;
                return "\u2014";
            }
            const part5h = rl5h >= 0 ? root.formatUsageWithPrefix(rl5h, "5h") : "\u2014";
            const part7d = rl7d >= 0 ? root.formatUsageWithPrefix(rl7d, "7d") : "\u2014";
            return part5h + "  " + part7d;
        }
        if (barMetric === "tokens")
            return mainInstance?.formatTokenCount(activeProvider.todayTotalTokens) ?? "0";
        return String(activeProvider.todayPrompts);
    }

    property string tooltipText: {
        if (!activeProvider)
            return "Model Usage";
        const name = activeProvider.providerName;
        const prompts = activeProvider.todayPrompts;
        const sess = activeProvider.todaySessions;
        const tokens = mainInstance?.formatTokenCount(activeProvider.todayTotalTokens) ?? "0";
        let tip = name + " \u2014 Today: " + prompts + " prompts, " + sess + " sessions, " + tokens + " tokens";
        const rl = activeProvider.rateLimitPercent;
        if (rl >= 0)
            tip += " \u00b7 " + activeProvider.rateLimitLabel + ": " + Math.round(rl * 100) + "%";
        else if ((activeProvider.usageStatusText ?? "") !== "")
            tip += " \u00b7 " + activeProvider.usageStatusText;
        return tip;
    }

    readonly property bool textVisible: !root.barTextShowOnHover || mouseArea.containsMouse

    readonly property real contentWidth: isBarVertical ? capsuleHeight : (root.textVisible ? content.implicitWidth : capsuleHeight) + Style.marginM * 2
    readonly property real contentHeight: isBarVertical ? (root.textVisible ? content.implicitHeight : capsuleHeight) + Style.marginM * 2 : capsuleHeight

    anchors.centerIn: parent
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    NPopupContextMenu {
        id: contextMenu
        screen: root.screen

        model: [
            {
                "label": "Refresh",
                "action": "refresh",
                "icon": "refresh"
            },
            {
                "label": root.barTextShowOnHover ? "Show text always" : "Show text on hover",
                "action": "toggle-show-on-hover",
                "icon": root.barTextShowOnHover ? "eye-off" : "eye"
            },
            {
                "label": "Settings",
                "action": "settings",
                "icon": "settings"
            },
        ]

        onTriggered: (action, item) => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);
            if (action === "refresh") {
                mainInstance?.refresh();
            } else if (action === "toggle-show-on-hover") {
                if (pluginApi) {
                    if (!pluginApi.pluginSettings)
                        pluginApi.pluginSettings = {};
                    pluginApi.pluginSettings.barTextShowOnHover = !root.barTextShowOnHover;
                    pluginApi.saveSettings();
                }
            } else if (action === "settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            }
        }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        radius: Style.radiusL
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Behavior on width {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: content
            anchors.centerIn: parent
            implicitWidth: rowLayout.visible ? rowLayout.implicitWidth : colLayout.implicitWidth
            implicitHeight: rowLayout.visible ? rowLayout.implicitHeight : colLayout.implicitHeight

            RowLayout {
                id: rowLayout
                visible: !root.isBarVertical
                spacing: Style.marginS

                ProviderVisual {
                    Layout.alignment: Qt.AlignVCenter
                    visualData: root.mainInstance?.providerVisualData(root.activeProvider?.providerId) ?? ({
                        "source": "icon",
                        "icon": "ai"
                    })
                    pointSize: root.barFontSize
                    applyUiScale: false
                    color: root.resolvedProviderIconColor
                    colorize: root.resolvedProviderIconColor !== Color.mOnSurface
                    colorizeColor: root.resolvedProviderIconColor
                }

                NText {
                    text: root.displayText
                    opacity: root.textVisible ? 1 : 0
                    pointSize: root.barFontSize
                    applyUiScale: false
                    color: Color.mOnSurface
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.textVisible ? implicitWidth : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        NumberAnimation {
                            duration: Style.animationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            ColumnLayout {
                id: colLayout
                visible: root.isBarVertical
                spacing: Style.marginXS

                ProviderVisual {
                    Layout.alignment: Qt.AlignHCenter
                    visualData: root.mainInstance?.providerVisualData(root.activeProvider?.providerId) ?? ({
                        "source": "icon",
                        "icon": "ai"
                    })
                    pointSize: root.barFontSize
                    applyUiScale: false
                    color: root.resolvedProviderIconColor
                    colorize: root.resolvedProviderIconColor !== Color.mOnSurface
                    colorizeColor: root.resolvedProviderIconColor
                }

                NText {
                    text: root.displayText
                    opacity: root.textVisible ? 1 : 0
                    pointSize: root.barFontSize
                    applyUiScale: false
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredHeight: root.textVisible ? implicitHeight : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on Layout.preferredHeight {
                        NumberAnimation {
                            duration: Style.animationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                TooltipService.hide();
                pluginApi?.togglePanel(root.screen, root);
            } else if (mouse.button === Qt.RightButton) {
                TooltipService.hide();
                PanelService.showContextMenu(contextMenu, root, root.screen);
            }
        }

        onEntered: {
            TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screenName));
        }

        onExited: {
            TooltipService.hide();
        }
    }
}
