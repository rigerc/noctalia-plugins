pragma ComponentBehavior: Bound
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

    property var mainInstance: root.pluginApi?.mainInstance
    property var activeProvider: root.mainInstance?.activeProvider

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    property string barMetric: root.mainInstance?.barMetric ?? "prompts"
    property bool barShowRemaining: root.mainInstance?.barShowRemaining ?? false
    property bool barTextShowOnHover: root.mainInstance?.barTextShowOnHover ?? false
    property bool barIconAlertOnLimit: root.mainInstance?.barIconAlertOnLimit ?? false
    property int barIconAlertThreshold: Math.max(50, Math.min(100, Number(root.mainInstance?.barIconAlertThreshold ?? 95)))
    property string barIconAlertWindow: root.mainInstance?.barIconAlertWindow ?? "usage7d"
    property bool barCycleEnabled: root.mainInstance?.barCycleEnabled ?? false

    readonly property color resolvedProviderIconColor: {
        if (!root.barIconAlertOnLimit || !root.activeProvider)
            return Color.mOnSurface;

        if (root.providerCrossesAlertThreshold(root.activeProvider))
            return Color.mError;

        return Color.mOnSurface;
    }

    property string tooltipText: {
        if (!activeProvider) {
            const ep = root.mainInstance?.barProviders ?? [];
            if (ep.length === 0)
                return "Model Usage";
            return "Model Usage \u2014 " + ep.length + " providers";
        }
        if (!root.barCycleEnabled) {
            const ep = root.mainInstance?.barProviders ?? [];
            let tip = "All providers:";
            for (const p of ep) {
                tip += "\n" + p.providerName + ": " + root.providerDisplayText(p);
                const rl = p.rateLimitPercent;
                if (rl >= 0)
                    tip += " (" + p.rateLimitLabel + ": " + Math.round(rl * 100) + "%)";
            }
            return tip;
        }
        const name = activeProvider.providerName;
        const prompts = activeProvider.todayPrompts;
        const sess = activeProvider.todaySessions;
        const tokens = root.mainInstance?.formatTokenCount(root.activeProvider.todayTotalTokens) ?? "0";
        let tip = name + " \u2014 Today: " + prompts + " prompts, " + sess + " sessions, " + tokens + " tokens";
        const rl = activeProvider.rateLimitPercent;
        if (rl >= 0)
            tip += " \u00b7 " + activeProvider.rateLimitLabel + ": " + Math.round(rl * 100) + "%";
        else if ((activeProvider.usageStatusText ?? "") !== "")
            tip += " \u00b7 " + activeProvider.usageStatusText;
        return tip;
    }

    // Show-on-hover internal state (matches BarPillHorizontal pattern)
    property bool showPill: false
    readonly property bool revealed: !root.barTextShowOnHover || root.showPill

    readonly property real collapsedContentWidth: root.barCycleEnabled ? root.capsuleHeight : content.implicitWidth
    readonly property real collapsedContentHeight: root.barCycleEnabled ? root.capsuleHeight : content.implicitHeight
    readonly property real contentWidth: root.isBarVertical ? root.capsuleHeight : (root.revealed ? content.implicitWidth : root.collapsedContentWidth) + Style.marginM * 2
    readonly property real contentHeight: root.isBarVertical ? (root.revealed ? content.implicitHeight : root.collapsedContentHeight) + Style.marginM * 2 : root.capsuleHeight

    function resolvedProviderIconColorFor(provider) {
        if (!root.barIconAlertOnLimit || !provider)
            return Color.mOnSurface;

        if (root.providerCrossesAlertThreshold(provider))
            return Color.mError;

        return Color.mOnSurface;
    }

    function providerCrossesAlertThreshold(provider) {
        if (!provider)
            return false;
        const percent = root.barIconAlertWindow === "usage5h"
            ? (provider.secondaryRateLimitPercent ?? -1)
            : (provider.rateLimitPercent ?? -1);
        return percent >= 0 && Math.round(percent * 100) >= root.barIconAlertThreshold;
    }

    function formatUsagePercent(rawPercent) {
        const used = Math.round(rawPercent * 100);
        if (root.barShowRemaining)
            return Math.max(0, 100 - used) + "%";
        return used + "%";
    }

    function formatUsageWithPrefix(percent, prefix) {
        if (!(percent >= 0))
            return "—";
        return prefix + ": " + root.formatUsagePercent(percent);
    }

    function providerDisplayText(provider) {
        if (!provider)
            return "—";
        if (barMetric === "usage") {
            const rl = provider.rateLimitPercent ?? -1;
            if (!(rl >= 0)) {
                const status = String(provider.usageStatusText ?? "");
                if (status !== "")
                    return status;
                return "—";
            }
            return root.formatUsageWithPrefix(rl, "7d");
        }
        if (barMetric === "usage5h") {
            const rl = provider.secondaryRateLimitPercent ?? -1;
            if (!(rl >= 0)) {
                const status = String(provider.usageStatusText ?? "");
                if (status !== "")
                    return status;
                return "—";
            }
            return root.formatUsageWithPrefix(rl, "5h");
        }
        if (barMetric === "usage5h7d") {
            const rl5h = provider.secondaryRateLimitPercent ?? -1;
            const rl7d = provider.rateLimitPercent ?? -1;
            if (!(rl5h >= 0) && !(rl7d >= 0)) {
                const status = String(provider.usageStatusText ?? "");
                if (status !== "")
                    return status;
                return "—";
            }
            const part5h = rl5h >= 0 ? root.formatUsageWithPrefix(rl5h, "5h") : "—";
            const part7d = rl7d >= 0 ? root.formatUsageWithPrefix(rl7d, "7d") : "—";
            return part5h + "  " + part7d;
        }
        if (barMetric === "tokens")
            return root.mainInstance?.formatTokenCount(provider.todayTotalTokens) ?? "0";
        return String(provider.todayPrompts);
    }

    anchors.centerIn: parent
    implicitWidth: contentWidth
    implicitHeight: contentHeight

    function showDelayed() {
        if (root.barTextShowOnHover && !root.showPill)
            showTimer.restart();
    }

    function hidePill() {
        if (root.barTextShowOnHover && root.showPill) {
            if (root.isBarVertical)
                hideAnimVertical.start();
            else
                hideAnim.start();
        }
        showTimer.stop();
    }

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
                root.mainInstance?.refresh();
            } else if (action === "toggle-show-on-hover") {
                if (root.pluginApi) {
                    if (!root.pluginApi.pluginSettings)
                        root.pluginApi.pluginSettings = {};
                    root.pluginApi.pluginSettings.barTextShowOnHover = !root.barTextShowOnHover;
                    root.pluginApi.saveSettings();
                }
            } else if (action === "settings") {
                BarService.openPluginSettings(root.screen, root.pluginApi.manifest);
            }
        }
    }

    Timer {
        id: showTimer
        interval: Style.pillDelay
        onTriggered: {
            if (!root.showPill) {
                // Set state first so revealed is true before animation captures to values
                root.showPill = true;
                if (root.isBarVertical)
                    showAnimVertical.start();
                else
                    showAnim.start();
            }
        }
    }

    ParallelAnimation {
        id: showAnim
        running: false

        NumberAnimation {
            target: textContainer
            property: "opacity"
            from: 0
            to: 1
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: textContainer
            property: "Layout.preferredWidth"
            from: 0
            to: textItem.implicitWidth
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: hideAnim
        running: false

        NumberAnimation {
            target: textContainer
            property: "opacity"
            from: 1
            to: 0
            duration: Style.animationFast
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: textContainer
            property: "Layout.preferredWidth"
            from: textItem.implicitWidth
            to: 0
            duration: Style.animationNormal
            easing.type: Easing.InCubic
        }

        onStopped: {
            root.showPill = false;
        }
    }

    ParallelAnimation {
        id: showAnimVertical
        running: false

        NumberAnimation {
            target: textContainerVertical
            property: "opacity"
            from: 0
            to: 1
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: textContainerVertical
            property: "Layout.preferredHeight"
            from: 0
            to: textItemVertical.implicitHeight
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: hideAnimVertical
        running: false

        NumberAnimation {
            target: textContainerVertical
            property: "opacity"
            from: 1
            to: 0
            duration: Style.animationFast
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: textContainerVertical
            property: "Layout.preferredHeight"
            from: textItemVertical.implicitHeight
            to: 0
            duration: Style.animationNormal
            easing.type: Easing.InCubic
        }

        onStopped: {
            root.showPill = false;
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
            implicitWidth: {
                if (!root.barCycleEnabled)
                    return root.isBarVertical ? allColLayout.implicitWidth : allRowLayout.implicitWidth;
                return root.isBarVertical ? colLayout.implicitWidth : rowLayout.implicitWidth;
            }
            implicitHeight: {
                if (!root.barCycleEnabled)
                    return root.isBarVertical ? allColLayout.implicitHeight : allRowLayout.implicitHeight;
                return root.isBarVertical ? colLayout.implicitHeight : rowLayout.implicitHeight;
            }

            // ---- Single-provider layouts (cycle) ----

            RowLayout {
                id: rowLayout
                visible: !root.isBarVertical && root.barCycleEnabled
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

                Item {
                    id: textContainer
                    clip: true
                    Layout.alignment: Qt.AlignVCenter
                    opacity: root.revealed ? 1 : 0
                    Layout.preferredWidth: root.revealed ? textItem.implicitWidth : 0
                    Layout.preferredHeight: textItem.implicitHeight

                    NText {
                        id: textItem
                        visible: root.revealed
                        text: root.providerDisplayText(root.activeProvider)
                        pointSize: root.barFontSize
                        applyUiScale: false
                        color: Color.mOnSurface
                    }
                }
            }

            ColumnLayout {
                id: colLayout
                visible: root.isBarVertical && root.barCycleEnabled
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

                Item {
                    id: textContainerVertical
                    clip: true
                    Layout.alignment: Qt.AlignHCenter
                    opacity: root.revealed ? 1 : 0
                    Layout.preferredHeight: root.revealed ? textItemVertical.implicitHeight : 0
                    Layout.preferredWidth: textItemVertical.implicitWidth

                    NText {
                        id: textItemVertical
                        visible: root.revealed
                        text: root.providerDisplayText(root.activeProvider)
                        pointSize: root.barFontSize
                        applyUiScale: false
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                    }
                }
            }

            // ---- All providers layout ----

            RowLayout {
                id: allRowLayout
                visible: !root.isBarVertical && !root.barCycleEnabled
                spacing: Style.marginL

                Repeater {
                    model: root.mainInstance?.barProviders ?? []

                    delegate: RowLayout {
                        id: rowDel
                        required property var modelData
                        spacing: Style.marginS
                        Layout.alignment: Qt.AlignVCenter

                        ProviderVisual {
                            Layout.alignment: Qt.AlignVCenter
                            visualData: root.mainInstance?.providerVisualData(rowDel.modelData.providerId) ?? ({
                                "source": "icon",
                                "icon": "ai"
                            })
                            pointSize: root.barFontSize
                            applyUiScale: false
                            color: root.resolvedProviderIconColorFor(rowDel.modelData)
                            colorize: root.resolvedProviderIconColorFor(rowDel.modelData) !== Color.mOnSurface
                            colorizeColor: root.resolvedProviderIconColorFor(rowDel.modelData)
                        }

                        Item {
                            clip: true
                            Layout.alignment: Qt.AlignVCenter
                            opacity: root.revealed ? 1 : 0
                            Layout.preferredWidth: root.revealed ? textAllItem.implicitWidth : 0
                            Layout.preferredHeight: textAllItem.implicitHeight

                            NText {
                                id: textAllItem
                                visible: root.revealed
                                text: root.providerDisplayText(rowDel.modelData)
                                pointSize: root.barFontSize
                                applyUiScale: false
                                color: Color.mOnSurface
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                id: allColLayout
                visible: root.isBarVertical && !root.barCycleEnabled
                spacing: Style.marginXS

                Repeater {
                    model: root.mainInstance?.barProviders ?? []

                    delegate: RowLayout {
                        id: colDel
                        required property var modelData
                        spacing: Style.marginS
                        Layout.alignment: Qt.AlignHCenter

                        ProviderVisual {
                            Layout.alignment: Qt.AlignVCenter
                            visualData: root.mainInstance?.providerVisualData(colDel.modelData.providerId) ?? ({
                                "source": "icon",
                                "icon": "ai"
                            })
                            pointSize: root.barFontSize
                            applyUiScale: false
                            color: root.resolvedProviderIconColorFor(colDel.modelData)
                            colorize: root.resolvedProviderIconColorFor(colDel.modelData) !== Color.mOnSurface
                            colorizeColor: root.resolvedProviderIconColorFor(colDel.modelData)
                        }

                        Item {
                            clip: true
                            Layout.alignment: Qt.AlignVCenter
                            opacity: root.revealed ? 1 : 0
                            Layout.preferredWidth: root.revealed ? textAllVItem.implicitWidth : 0
                            Layout.preferredHeight: textAllVItem.implicitHeight

                            NText {
                                id: textAllVItem
                                visible: root.revealed
                                text: root.providerDisplayText(colDel.modelData)
                                pointSize: root.barFontSize
                                applyUiScale: false
                                color: Color.mOnSurface
                            }
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
                root.pluginApi?.togglePanel(root.screen, root);
            } else if (mouse.button === Qt.RightButton) {
                TooltipService.hide();
                PanelService.showContextMenu(contextMenu, root, root.screen);
            }
        }

        onEntered: {
            TooltipService.show(root, root.tooltipText, BarService.getTooltipDirection(root.screenName));
            root.showDelayed();
        }

        onExited: {
            TooltipService.hide();
            root.hidePill();
        }
    }
}
