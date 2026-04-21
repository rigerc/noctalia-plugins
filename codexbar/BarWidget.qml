import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance

    readonly property string barPosition: Settings.getBarPositionForScreen(screen?.name)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screen?.name)

    function normalizeIconName(iconName) {
        var normalized = String(iconName || "").trim();
        if (normalized === "")
            return "sparkles";
        if (normalized.indexOf(":") >= 0)
            normalized = normalized.split(":").pop();
        if (normalized.indexOf("--") >= 0)
            normalized = normalized.split("--").pop();
        if (normalized.indexOf("tabler-") === 0)
            normalized = normalized.slice(7);
        switch (normalized) {
        case "robot-outline":
            return "cpu";
        case "robot":
            return "cpu";
        case "lightning-bolt":
            return "bolt";
        case "star-four-points":
            return "sparkles";
        default:
            return normalized;
        }
    }

    readonly property string barIcon: normalizeIconName(cfg.barIcon ?? defaults.barIcon ?? "sparkles")
    readonly property string barIconColor: cfg.barIconColor ?? defaults.barIconColor ?? "on-surface"
    readonly property string defaultProvider: cfg.defaultProvider ?? defaults.defaultProvider ?? ""
    readonly property color resolvedBarIconColor: Color.resolveColorKey(root.barIconColor)

    readonly property var displayProvider: {
        if (!mainInstance || !Array.isArray(mainInstance.providerData) || mainInstance.providerData.length === 0)
            return null;

        if (defaultProvider) {
            for (var i = 0; i < mainInstance.providerData.length; i++) {
                if (mainInstance.providerData[i].provider === defaultProvider)
                    return mainInstance.providerData[i];
            }
        }
        return mainInstance.providerData[0] || null;
    }

    readonly property int usedPercent: displayProvider?.usage?.primary?.usedPercent ?? -1
    readonly property bool hasData: displayProvider !== null && usedPercent >= 0

    readonly property string contentText: {
        if (!mainInstance || mainInstance.isRefreshing)
            return "...";
        if (!hasData)
            return "—";
        return (100 - usedPercent) + "%";
    }

    implicitWidth: isVertical ? capsuleHeight : row.width + Style.marginM * 2
    implicitHeight: isVertical ? row.width + Style.marginM * 2 : capsuleHeight

    NPopupContextMenu {
        id: contextMenu
        model: [
            {
                "label": pluginApi?.tr("menu.refresh"),
                "action": "refresh",
                "icon": "refresh"
            },
            {
                "label": pluginApi?.tr("menu.settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]
        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "refresh") {
                if (mainInstance) mainInstance.refresh();
            } else if (action === "settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest);
            }
        }
    }

    Rectangle {
        id: capsule

        readonly property real contentWidth: row.width + Style.marginM * 2
        readonly property real contentHeight: row.height + Style.marginM

        anchors.centerIn: parent
        width: isVertical ? parent.width : contentWidth
        height: isVertical ? contentHeight : parent.height
        radius: Style.radiusL
        color: Style.capsuleColor

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: Style.marginXS

            NIcon {
                id: iconDisplay
                Layout.preferredWidth: Style.fontSizeM
                Layout.preferredHeight: Style.fontSizeM
                icon: mainInstance?.isRefreshing ? "refresh" : root.barIcon
                color: root.resolvedBarIconColor

                RotationAnimator {
                    target: iconDisplay
                    from: 0
                    to: 360
                    duration: 1000
                    running: mainInstance?.isRefreshing ?? false
                    loops: Animation.Infinite
                }
            }

            NText {
                Layout.alignment: Qt.AlignVCenter
                text: root.contentText
                pointSize: Style.fontSizeXS
                color: root.resolvedBarIconColor
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (pluginApi) pluginApi.togglePanel(root.screen, root);
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen);
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                var tip;
                if (!hasData) {
                    tip = pluginApi?.tr("widget.noData") || "No data";
                } else {
                    var name = mainInstance?.providerDisplayName(displayProvider.provider) || displayProvider.provider;
                    var primary = displayProvider?.usage?.primary;
                    var secondary = displayProvider?.usage?.secondary;
                    var lines = [name];
                    if (primary) lines.push("Session: " + (100 - primary.usedPercent) + "% left");
                    if (secondary) lines.push("Weekly: " + (100 - secondary.usedPercent) + "% left");
                    tip = lines.join("\n");
                }
                TooltipService.show(root, tip, BarService.getTooltipDirection(root.screen?.name));
            } else {
                TooltipService.hide();
            }
        }
    }
}
