import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
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
    property bool temporarilyExpanded: false
    property string previousStableContentText: ""

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

    function normalizeBarTextFields(fields) {
        var allowed = ["primary", "secondary", "status"];
        var normalized = [];
        var source = Array.isArray(fields) ? fields : [fields];

        for (var index = 0; index < source.length; index++) {
            var fieldKey = String(source[index] || "").trim();
            if (allowed.indexOf(fieldKey) < 0 || normalized.indexOf(fieldKey) >= 0)
                continue;
            normalized.push(fieldKey);
        }

        if (normalized.length === 0)
            normalized.push("primary");
        return normalized;
    }

    function usageWindowLabel(windowMinutes, fallbackLabel) {
        var minutes = Number(windowMinutes || 0);
        if (!isFinite(minutes) || minutes <= 0)
            return fallbackLabel;
        if (minutes % 1440 === 0)
            return (minutes / 1440) + "d";
        if (minutes % 60 === 0)
            return (minutes / 60) + "h";
        return minutes + "m";
    }

    function formatStatusText(status) {
        var indicator = String(status?.indicator || "").trim();
        var description = String(status?.description || "").trim();

        if (indicator === "none")
            return "OK";
        if (indicator === "minor")
            return "Warn";
        if (indicator === "major")
            return "Down";
        if (indicator === "maintenance")
            return "Maint";
        if (description !== "")
            return description;
        if (indicator === "")
            return "";
        return indicator.charAt(0).toUpperCase() + indicator.slice(1);
    }

    function barTextJoiner() {
        var padding = "";
        for (var index = 0; index < root.barTextSeparatorSpacing; index++)
            padding += " ";

        if (root.barTextSeparator === "")
            return padding === "" ? " " : padding;
        return padding + root.barTextSeparator + padding;
    }

    function fieldText(fieldKey) {
        var provider = root.displayProvider;
        if (!provider)
            return "";

        if (fieldKey === "status") {
            var statusText = root.formatStatusText(provider.status);
            return statusText === "" ? "" : "Status: " + statusText;
        }

        var usage = fieldKey === "secondary" ? provider?.usage?.secondary : provider?.usage?.primary;
        if (!usage)
            return "";

        var usedPercent = Number(usage.usedPercent);
        if (!isFinite(usedPercent) || usedPercent < 0)
            return "";

        var leftPercent = Math.max(0, Math.min(100, Math.round(100 - usedPercent)));
        if (root.barTextFields.length === 1)
            return leftPercent + "%";

        var label = root.usageWindowLabel(
            usage.windowMinutes,
            fieldKey === "secondary" ? "7d" : "5h"
        );
        return label + " " + leftPercent + "%";
    }

    readonly property string barIcon: normalizeIconName(cfg.barIcon ?? defaults.barIcon ?? "sparkles")
    readonly property string barIconColor: cfg.barIconColor ?? defaults.barIconColor ?? "on-surface"
    readonly property var barTextFields: normalizeBarTextFields(cfg.barTextFields ?? defaults.barTextFields ?? ["primary"])
    readonly property string barTextSeparator: String(cfg.barTextSeparator ?? defaults.barTextSeparator ?? "·")
    readonly property int barTextSeparatorSpacing: Math.max(0, Math.min(4, Number(cfg.barTextSeparatorSpacing ?? defaults.barTextSeparatorSpacing ?? 1)))
    readonly property string barTextColorKey: String(cfg.barTextColor ?? defaults.barTextColor ?? "on-surface")
    readonly property real barTextOpacity: Math.max(0, Math.min(1, Number(cfg.barTextOpacity ?? defaults.barTextOpacity ?? 1)))
    readonly property bool barTextShowOnHover: cfg.barTextShowOnHover ?? defaults.barTextShowOnHover ?? false
    readonly property bool barTextExpandOnChange: cfg.barTextExpandOnChange ?? defaults.barTextExpandOnChange ?? false
    readonly property string defaultProvider: cfg.defaultProvider ?? defaults.defaultProvider ?? ""
    readonly property color resolvedBarIconColor: Color.resolveColorKey(root.barIconColor)
    readonly property color resolvedBarTextBaseColor: Color.resolveColorKey(root.barTextColorKey)
    readonly property color resolvedBarTextColor: Qt.alpha(root.resolvedBarTextBaseColor, root.barTextOpacity)

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

    readonly property bool hasData: {
        if (!displayProvider)
            return false;
        if (displayProvider.error)
            return true;
        for (var index = 0; index < root.barTextFields.length; index++) {
            if (root.fieldText(root.barTextFields[index]) !== "")
                return true;
        }
        return false;
    }

    readonly property string contentText: {
        if (!mainInstance || mainInstance.isRefreshing)
            return "...";
        if (!displayProvider)
            return "—";
        if (displayProvider.error)
            return pluginApi?.tr("widget.error");

        var parts = [];
        for (var index = 0; index < root.barTextFields.length; index++) {
            var part = root.fieldText(root.barTextFields[index]);
            if (part !== "")
                parts.push(part);
        }

        if (parts.length === 0)
            return "—";
        return parts.join(root.barTextJoiner());
    }

    readonly property var tooltipText: {
        if (!hasData)
            return pluginApi?.tr("widget.noData");

        if (!displayProvider)
            return "";

        var name = mainInstance?.providerDisplayName(displayProvider.provider) || displayProvider.provider;
        var providerError = displayProvider.error;
        if (providerError) {
            var message = String(providerError.message || "").trim();
            if (message === "")
                message = JSON.stringify(providerError);
            return [name, pluginApi?.tr("widget.providerError"), message].join("\n");
        }

        var primary = displayProvider?.usage?.primary;
        var secondary = displayProvider?.usage?.secondary;
        var status = displayProvider?.status;
        var lines = [name];
        if (primary)
            lines.push("Session: " + (100 - primary.usedPercent) + "% left");
        if (secondary)
            lines.push("Weekly: " + (100 - secondary.usedPercent) + "% left");
        if (status && root.formatStatusText(status) !== "")
            lines.push("Status: " + root.formatStatusText(status));
        return lines.join("\n");
    }

    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight

    onContentTextChanged: {
        if (mainInstance?.isRefreshing)
            return;

        if (previousStableContentText !== ""
                && contentText !== previousStableContentText
                && barTextShowOnHover
                && barTextExpandOnChange) {
            temporarilyExpanded = true;
            expandTimer.restart();
        }

        previousStableContentText = contentText;
    }

    Timer {
        id: expandTimer
        interval: 2500
        repeat: false
        onTriggered: root.temporarilyExpanded = false
    }

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

    BarPill {
        id: pill

        screen: root.screen
        oppositeDirection: BarService.getPillDirection(root)
        icon: mainInstance?.isRefreshing ? "refresh" : root.barIcon
        text: root.barTextOpacity > 0 ? root.contentText : ""
        tooltipText: root.tooltipText
        autoHide: false
        forceOpen: !root.barTextShowOnHover || root.temporarilyExpanded
        customIconColor: root.resolvedBarIconColor
        customTextColor: root.barTextOpacity > 0 ? root.resolvedBarTextColor : "transparent"

        onClicked: {
            if (pluginApi)
                pluginApi.togglePanel(root.screen, pill);
        }

        onRightClicked: {
            PanelService.showContextMenu(contextMenu, pill, screen);
        }
    }
}
