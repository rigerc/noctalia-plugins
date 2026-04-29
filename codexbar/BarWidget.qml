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
    property bool temporarilyExpanded: false
    property string previousStableContentSignature: ""
    property bool hoverTextVisible: false
    property real animatedTextWidth: 0
    property real animatedTextOpacity: 0

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

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
        var allowed = ["primary", "secondary", "tertiary", "status"];
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

    function normalizeBarProviderFields(providerFields) {
        var source = (providerFields && typeof providerFields === "object" && !Array.isArray(providerFields)) ? providerFields : ({});
        var normalized = ({});
        var keys = Object.keys(source);
        for (var index = 0; index < keys.length; index++) {
            var providerId = String(keys[index] || "").trim();
            if (providerId === "")
                continue;
            var fieldArray = normalizeBarTextFields(source[providerId]);
            normalized[providerId] = fieldArray;
        }
        return normalized;
    }

    function effectiveFieldsForProvider(providerId) {
        var id = String(providerId || "");
        var fields = root.barProviderFields;
        if (fields && fields[id] && Array.isArray(fields[id]) && fields[id].length > 0)
            return fields[id];
        return root.barTextFields;
    }

    function normalizeProviderIds(providerIds) {
        var normalized = [];
        var source = Array.isArray(providerIds) ? providerIds : [providerIds];
        for (var index = 0; index < source.length; index++) {
            var providerId = String(source[index] || "").trim();
            if (providerId === "" || normalized.indexOf(providerId) >= 0)
                continue;
            normalized.push(providerId);
            if (normalized.length >= 3)
                break;
        }
        return normalized;
    }

    function normalizeProviderLabelMode(mode) {
        return String(mode || "").trim() === "prefix" ? "prefix" : "icon";
    }

    function normalizeBarProviderIcons(providerIcons) {
        var source = (providerIcons && typeof providerIcons === "object" && !Array.isArray(providerIcons)) ? providerIcons : ({});
        var normalized = ({});
        var keys = Object.keys(source);
        for (var index = 0; index < keys.length; index++) {
            var providerId = String(keys[index] || "").trim();
            var iconName = root.normalizeIconName(source[providerId]);
            if (providerId === "" || iconName === "")
                continue;
            normalized[providerId] = iconName;
        }
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

    function usageLeftPercent(usage) {
        var usedPercent = Number(usage?.usedPercent);
        if (!isFinite(usedPercent) || usedPercent < 0)
            return -1;
        return Math.max(0, Math.min(100, Math.round(100 - usedPercent)));
    }

    function normalizeLowUsageAlertWindow(windowKey) {
        var key = String(windowKey || "").trim();
        return (key === "secondary" || key === "tertiary") ? key : "primary";
    }

    function normalizeCountdownWindows(windows) {
        var allowed = ["primary", "secondary", "tertiary"];
        var normalized = [];
        var source = Array.isArray(windows) ? windows : [windows];
        for (var index = 0; index < source.length; index++) {
            var key = String(source[index] || "").trim();
            if (allowed.indexOf(key) < 0 || normalized.indexOf(key) >= 0)
                continue;
            normalized.push(key);
        }
        if (normalized.length === 0)
            normalized.push("primary");
        return normalized;
    }

    function windowLabel(provider, fieldKey) {
        if (!provider)
            return "";
        var label = provider._windowLabels ? provider._windowLabels[fieldKey] : root.usageWindowLabel(provider.usage && provider.usage[fieldKey] ? provider.usage[fieldKey].windowMinutes : 0, fieldKey);
        if (!label)
            label = fieldKey.charAt(0).toUpperCase() + fieldKey.slice(1);
        return label;
    }

    function lastRefreshedTooltipLine() {
        if (!mainInstance?.lastUpdated)
            return "";

        var _ = Time.now;
        var refreshedAt = new Date(mainInstance.lastUpdated);
        if (isNaN(refreshedAt.getTime()))
            return "";

        var relative = Time.formatRelativeTime(refreshedAt);
        if (relative === "")
            return "";

        return pluginApi?.tr("widget.lastRefreshed") + " " + relative;
    }

    function escapeTooltipHtml(text) {
        return String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function tooltipBlockHtml(lines) {
        var escapedLines = [];
        for (var index = 0; index < lines.length; index++)
            escapedLines.push(root.escapeTooltipHtml(lines[index]));
        return "<div style=\"text-align:center;\">" + escapedLines.join("<br/>") + "</div>";
    }

    function showTextNow() {
        hoverRevealTimer.stop();
        textHideAnim.stop();
        textShowAnim.stop();
        root.hoverTextVisible = true;
        root.animatedTextWidth = root.textTargetWidth;
        root.animatedTextOpacity = root.textTargetWidth > 0 ? 1 : 0;
    }

    function showTextDelayed() {
        if (!root.barTextShowOnHover || root.forceRevealText || root.textTargetWidth <= 0)
            return;
        if (!root.hoverTextVisible)
            hoverRevealTimer.restart();
    }

    function hideTextNow() {
        hoverRevealTimer.stop();
        textShowAnim.stop();
        textHideAnim.stop();
        root.hoverTextVisible = false;
        root.animatedTextWidth = 0;
        root.animatedTextOpacity = 0;
    }

    function hideTextAnimated() {
        if (!root.barTextShowOnHover || root.forceRevealText)
            return;
        hoverRevealTimer.stop();
        textShowAnim.stop();
        if (root.animatedTextWidth <= 0) {
            root.hideTextNow();
            return;
        }
        textHideAnim.start();
    }

    function syncTextRevealState() {
        if (root.forceRevealText || !root.barTextShowOnHover) {
            root.showTextNow();
            return;
        }
        if (mouseArea.containsMouse) {
            root.showTextDelayed();
            return;
        }
        root.hideTextNow();
    }

    function toggleShowOnHover() {
        if (!pluginApi)
            return;
        if (!pluginApi.pluginSettings)
            pluginApi.pluginSettings = {};

        pluginApi.pluginSettings.barTextShowOnHover = !root.barTextShowOnHover;
        pluginApi.saveSettings();
    }

    function barTextJoiner() {
        var padding = "";
        for (var index = 0; index < root.barTextSeparatorSpacing; index++)
            padding += " ";

        if (root.barTextSeparator === "")
            return padding === "" ? " " : padding;
        return padding + root.barTextSeparator + padding;
    }

    function providerJoiner() {
        var padding = "";
        for (var index = 0; index < root.barProviderSeparatorSpacing; index++)
            padding += " ";

        if (root.barProviderSeparator === "")
            return padding === "" ? " " : padding;
        return padding + root.barProviderSeparator + padding;
    }

    function fieldText(provider, fieldKey, providerFields) {
        if (!provider)
            return "";

        if (fieldKey === "status") {
            var statusText = root.formatStatusText(provider.status);
            return statusText === "" ? "" : "Status: " + statusText;
        }

        var usage = provider?.usage ? provider.usage[fieldKey] : null;
        if (!usage)
            return "";

        var leftPercent = root.usageLeftPercent(usage);
        if (leftPercent < 0)
            return "";

        var fields = Array.isArray(providerFields) ? providerFields : root.barTextFields;
        if (fields.length === 1)
            return leftPercent + "%";

        var label = root.windowLabel(provider, fieldKey);
        return label + " " + leftPercent + "%";
    }

    function countdownEntriesForProvider(provider) {
        if (!root.barCountdownOnEmpty || !provider?.usage)
            return [];
        var entries = [];
        for (var index = 0; index < root.barCountdownWindows.length; index++) {
            var fieldKey = root.barCountdownWindows[index];
            var usage = provider.usage[fieldKey];
            if (!usage || !usage.resetsAt)
                continue;
            if (root.usageLeftPercent(usage) !== 0)
                continue;
            entries.push(fieldKey);
        }
        return entries;
    }

    function providerContentText(provider, hideNonCountdown) {
        if (!provider)
            return "";
        if (provider.error)
            return pluginApi?.tr("widget.error");

        var providerId = String(provider.provider || "");
        var fields = root.effectiveFieldsForProvider(providerId);
        var parts = [];
        var countdownEntries = root.countdownEntriesForProvider(provider);
        var countdownSet = {};
        for (var index = 0; index < countdownEntries.length; index++)
            countdownSet[countdownEntries[index]] = true;

        for (var fieldIndex = 0; fieldIndex < fields.length; fieldIndex++) {
            var fieldKey = fields[fieldIndex];
            if (fieldKey === "status") {
                if (!hideNonCountdown) {
                    var statusPart = root.fieldText(provider, fieldKey, fields);
                    if (statusPart !== "")
                        parts.push(statusPart);
                }
                continue;
            }

            if (countdownSet[fieldKey]) {
                var usage = provider.usage ? provider.usage[fieldKey] : null;
                if (!usage || !usage.resetsAt)
                    continue;
                parts.push(root.windowLabel(provider, fieldKey) + " " + pluginApi?.tr("widget.resetsIn") + " " + mainInstance.formatResetsCountdown(usage.resetsAt));
                delete countdownSet[fieldKey];
                continue;
            }

            if (hideNonCountdown)
                continue;

            var part = root.fieldText(provider, fieldKey, fields);
            if (part !== "")
                parts.push(part);
        }

        var remainingCountdownKeys = Object.keys(countdownSet);
        for (var countdownIndex = 0; countdownIndex < remainingCountdownKeys.length; countdownIndex++) {
            var remainingKey = remainingCountdownKeys[countdownIndex];
            var remainingUsage = provider.usage ? provider.usage[remainingKey] : null;
            if (!remainingUsage || !remainingUsage.resetsAt)
                continue;
            parts.push(root.windowLabel(provider, remainingKey) + " " + pluginApi?.tr("widget.resetsIn") + " " + mainInstance.formatResetsCountdown(remainingUsage.resetsAt));
        }

        if (parts.length === 0)
            return "—";

        return parts.join(root.barTextJoiner());
    }

    function providerTooltipLines(provider) {
        var name = mainInstance?.providerDisplayName(provider.provider) || provider.provider;
        var providerError = provider.error;
        if (providerError) {
            var message = String(providerError.message || "").trim();
            if (message === "")
                message = JSON.stringify(providerError);
            return [name, pluginApi?.tr("widget.providerError"), message];
        }

        var primary = provider?.usage?.primary;
        var secondary = provider?.usage?.secondary;
        var tertiary = provider?.usage?.tertiary;
        var status = provider?.status;
        var lines = [name];
        if (primary) {
            var pLine = root.windowLabel(provider, "primary") + ": " + (100 - primary.usedPercent) + "% left";
            var pCountdown = mainInstance.formatResetsCountdown(primary.resetsAt);
            if (pCountdown !== "")
                pLine += " (" + pluginApi?.tr("panel.resetsIn") + " " + pCountdown + ")";
            lines.push(pLine);
        }
        if (secondary) {
            var sLine = root.windowLabel(provider, "secondary") + ": " + (100 - secondary.usedPercent) + "% left";
            var sCountdown = mainInstance.formatResetsCountdown(secondary.resetsAt);
            if (sCountdown !== "")
                sLine += " (" + pluginApi?.tr("panel.resetsIn") + " " + sCountdown + ")";
            lines.push(sLine);
        }
        if (tertiary) {
            var tLine = root.windowLabel(provider, "tertiary") + ": " + (100 - tertiary.usedPercent) + "% left";
            var tCountdown = mainInstance.formatResetsCountdown(tertiary.resetsAt);
            if (tCountdown !== "")
                tLine += " (" + pluginApi?.tr("panel.resetsIn") + " " + tCountdown + ")";
            lines.push(tLine);
        }
        if (status && root.formatStatusText(status) !== "")
            lines.push("Status: " + root.formatStatusText(status));
        return lines;
    }

    readonly property string barIcon: normalizeIconName(cfg.barIcon ?? defaults.barIcon ?? "sparkles")
    readonly property string barIconColor: cfg.barIconColor ?? defaults.barIconColor ?? "on-surface"
    readonly property var barProviderIds: normalizeProviderIds(cfg.barProviderIds ?? defaults.barProviderIds ?? [])
    readonly property var barProviderIcons: normalizeBarProviderIcons(cfg.barProviderIcons ?? defaults.barProviderIcons ?? ({}))
    readonly property var providerVisuals: mainInstance?.normalizeProviderVisuals(cfg.providerVisuals ?? defaults.providerVisuals ?? ({})) || ({})
    readonly property string barProviderLabelMode: normalizeProviderLabelMode(cfg.barProviderLabelMode ?? defaults.barProviderLabelMode ?? "icon")
    readonly property string barProviderSeparator: String(cfg.barProviderSeparator ?? defaults.barProviderSeparator ?? "|")
    readonly property int barProviderSeparatorSpacing: Math.max(0, Math.min(4, Number(cfg.barProviderSeparatorSpacing ?? defaults.barProviderSeparatorSpacing ?? 1)))
    readonly property var barTextFields: normalizeBarTextFields(cfg.barTextFields ?? defaults.barTextFields ?? ["primary"])
    readonly property var barProviderFields: normalizeBarProviderFields(cfg.barProviderFields ?? defaults.barProviderFields ?? ({}))
    readonly property string barTextSeparator: String(cfg.barTextSeparator ?? defaults.barTextSeparator ?? "·")
    readonly property int barTextSeparatorSpacing: Math.max(0, Math.min(4, Number(cfg.barTextSeparatorSpacing ?? defaults.barTextSeparatorSpacing ?? 1)))
    readonly property string barTextColorKey: String(cfg.barTextColor ?? defaults.barTextColor ?? "on-surface")
    readonly property real barTextOpacity: Math.max(0, Math.min(1, Number(cfg.barTextOpacity ?? defaults.barTextOpacity ?? 1)))
    readonly property bool barTextShowOnHover: cfg.barTextShowOnHover ?? defaults.barTextShowOnHover ?? false
    readonly property bool barTextExpandOnChange: cfg.barTextExpandOnChange ?? defaults.barTextExpandOnChange ?? false
    readonly property bool barLowUsageAlertEnabled: cfg.barLowUsageAlertEnabled ?? defaults.barLowUsageAlertEnabled ?? false
    readonly property string barLowUsageAlertWindow: normalizeLowUsageAlertWindow(cfg.barLowUsageAlertWindow ?? defaults.barLowUsageAlertWindow ?? "primary")
    readonly property string barLowUsageAlertColorKey: String(cfg.barLowUsageAlertColor ?? defaults.barLowUsageAlertColor ?? "error")
    readonly property bool barCountdownOnEmpty: cfg.barCountdownOnEmpty ?? defaults.barCountdownOnEmpty ?? false
    readonly property var barCountdownWindows: normalizeCountdownWindows(cfg.barCountdownWindows ?? defaults.barCountdownWindows ?? ["primary"])
    readonly property bool providerIconColorize: cfg.providerIconColorize ?? defaults.providerIconColorize ?? true
    readonly property string providerIconColorizeColorKey: cfg.providerIconColorizeColor ?? defaults.providerIconColorizeColor ?? "on-surface"
    readonly property color resolvedProviderIconColorizeColor: Color.resolveColorKey(root.providerIconColorizeColorKey)
    readonly property string defaultProvider: cfg.defaultProvider ?? defaults.defaultProvider ?? ""
    readonly property int lowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))
    readonly property color resolvedBaseBarIconColor: Color.resolveColorKey(root.barIconColor)
    readonly property color resolvedLowUsageAlertBaseColor: Color.resolveColorKey(root.barLowUsageAlertColorKey)
    readonly property color resolvedBarTextBaseColor: Color.resolveColorKey(root.barTextColorKey)
    readonly property color resolvedBarTextColor: Qt.alpha(root.resolvedBarTextBaseColor, root.barTextOpacity)
    readonly property bool usingExplicitProviderSelection: root.barProviderIds.length > 0

    readonly property var displayProviders: {
        if (!mainInstance || !Array.isArray(mainInstance.providerData) || mainInstance.providerData.length === 0)
            return [];

        var ordered = [];
        var dataById = {};
        for (var dataIndex = 0; dataIndex < mainInstance.providerData.length; dataIndex++) {
            var entry = mainInstance.providerData[dataIndex];
            var providerId = String(entry?.provider || "").trim();
            if (providerId === "")
                continue;
            dataById[providerId] = entry;
        }

        if (root.usingExplicitProviderSelection) {
            for (var selectedIndex = 0; selectedIndex < root.barProviderIds.length; selectedIndex++) {
                var selectedId = root.barProviderIds[selectedIndex];
                if (dataById[selectedId])
                    ordered.push(dataById[selectedId]);
            }
            return ordered;
        }

        if (root.defaultProvider && dataById[root.defaultProvider])
            return [dataById[root.defaultProvider]];

        return mainInstance.providerData[0] ? [mainInstance.providerData[0]] : [];
    }

    readonly property bool countdownActive: {
        for (var index = 0; index < root.displayProviders.length; index++) {
            if (root.countdownEntriesForProvider(root.displayProviders[index]).length > 0)
                return true;
        }
        return false;
    }

    readonly property bool forceRevealText: !root.barTextShowOnHover || root.temporarilyExpanded || root.countdownActive

    readonly property var providerSegments: {
        if (!mainInstance || mainInstance.isRefreshing)
            return [{
                    "provider": "",
                    "showIcon": false,
                    "icon": "cpu",
                    "label": "",
                    "text": "...",
                    "signature": "refreshing"
                }];
        if (root.displayProviders.length === 0)
            return [{
                    "provider": "",
                    "showIcon": false,
                    "icon": "cpu",
                    "label": "",
                    "text": "—",
                    "signature": "empty"
                }];

        var hideNonCountdown = root.barTextShowOnHover && root.countdownActive;
        var segments = [];
        for (var index = 0; index < root.displayProviders.length; index++) {
            var provider = root.displayProviders[index];
            var providerId = String(provider.provider || "");
            var label = root.barProviderLabelMode === "prefix" ? (mainInstance?.providerDisplayName(providerId) || providerId) : "";
            var showIcon = root.barProviderLabelMode === "icon";
            var segmentText = root.providerContentText(provider, hideNonCountdown);
            var visual = mainInstance?.providerVisual(providerId, root.providerVisuals, root.barProviderIcons) || ({
                "source": "icon",
                "icon": root.barProviderIcons[providerId] || mainInstance?.providerIcon(providerId) || "cpu",
                "asset": "",
                "assetUrl": ""
            });
            segments.push({
                "provider": providerId,
                "showIcon": showIcon,
                "visual": visual,
                "label": label,
                "text": segmentText,
                "signature": providerId + "|" + label + "|" + segmentText + "|" + String(visual.source || "icon") + "|" + String(visual.icon || "") + "|" + String(visual.asset || "")
            });
        }
        return segments;
    }

    readonly property string stableContentSignature: root.providerSegments.map(function (segment) {
        return segment.signature;
    }).join("||")

    readonly property var tooltipText: {
        if (root.displayProviders.length === 0)
            return root.tooltipBlockHtml([pluginApi?.tr("widget.noData")]);

        var blocks = [];
        for (var index = 0; index < root.displayProviders.length; index++)
            blocks.push(root.tooltipBlockHtml(root.providerTooltipLines(root.displayProviders[index])));
        var refreshedLine = root.lastRefreshedTooltipLine();
        if (refreshedLine !== "")
            blocks.push(root.tooltipBlockHtml([refreshedLine]));
        return blocks.join("<br/><br/>");
    }

    readonly property color resolvedBarIconColor: {
        var hasCritical = false;
        var hasLow = false;

        for (var index = 0; index < root.displayProviders.length; index++) {
            var provider = root.displayProviders[index];
            var usage = provider?.usage ? provider.usage[root.barLowUsageAlertWindow] : null;
            var remainingPercent = root.usageLeftPercent(usage);

            if (!root.barLowUsageAlertEnabled || remainingPercent < 0)
                continue;
            if (remainingPercent === 0)
                hasCritical = true;
            else if (remainingPercent <= root.lowUsageThreshold)
                hasLow = true;
        }

        if (hasCritical)
            return Color.mError;
        if (hasLow)
            return Qt.alpha(root.resolvedLowUsageAlertBaseColor, 0.5);
        return root.resolvedBaseBarIconColor;
    }

    readonly property real textTargetWidth: root.barTextOpacity > 0 ? providerTextRow.implicitWidth : 0
    readonly property real contentWidth: root.capsuleHeight + (root.animatedTextWidth > 0 ? Style.marginS + root.animatedTextWidth : 0) + Style.marginM * 2
    readonly property real contentHeight: root.capsuleHeight

    implicitWidth: root.contentWidth
    implicitHeight: root.contentHeight

    onForceRevealTextChanged: root.syncTextRevealState()
    onTextTargetWidthChanged: {
        if (root.forceRevealText || root.hoverTextVisible) {
            root.animatedTextWidth = root.textTargetWidth;
            root.animatedTextOpacity = root.textTargetWidth > 0 ? 1 : 0;
        }
    }

    onStableContentSignatureChanged: {
        if (mainInstance?.isRefreshing)
            return;

        if (previousStableContentSignature !== "" && stableContentSignature !== previousStableContentSignature && barTextShowOnHover && barTextExpandOnChange) {
            temporarilyExpanded = true;
            expandTimer.restart();
        }

        previousStableContentSignature = stableContentSignature;
    }

    Timer {
        id: expandTimer
        interval: 2500
        repeat: false
        onTriggered: root.temporarilyExpanded = false
    }

    Timer {
        id: hoverRevealTimer
        interval: Style.pillDelay
        repeat: false
        onTriggered: {
            if (root.forceRevealText || !root.barTextShowOnHover || root.textTargetWidth <= 0)
                return;
            textHideAnim.stop();
            textShowAnim.restart();
        }
    }

    ParallelAnimation {
        id: textShowAnim
        running: false

        NumberAnimation {
            target: root
            property: "animatedTextWidth"
            from: 0
            to: root.textTargetWidth
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root
            property: "animatedTextOpacity"
            from: 0
            to: 1
            duration: Style.animationFast
            easing.type: Easing.OutCubic
        }

        onStarted: root.hoverTextVisible = true
    }

    ParallelAnimation {
        id: textHideAnim
        running: false

        NumberAnimation {
            target: root
            property: "animatedTextWidth"
            from: root.animatedTextWidth
            to: 0
            duration: Style.animationNormal
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: root
            property: "animatedTextOpacity"
            from: root.animatedTextOpacity
            to: 0
            duration: Style.animationFast
            easing.type: Easing.InCubic
        }

        onStopped: root.hoverTextVisible = false
    }

    NPopupContextMenu {
        id: contextMenu
        model: [
            {
                "label": root.pluginApi?.tr("menu.refresh"),
                "action": "refresh",
                "icon": "refresh"
            },
            {
                "label": root.barTextShowOnHover ? root.pluginApi?.tr("menu.disableShowOnHover") : root.pluginApi?.tr("menu.enableShowOnHover"),
                "action": "toggle-show-on-hover",
                "icon": root.barTextShowOnHover ? "eye-off" : "eye"
            },
            {
                "label": root.pluginApi?.tr("menu.settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]
        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(screen);
            if (action === "refresh") {
                if (root.mainInstance)
                    root.mainInstance.refresh();
            } else if (action === "toggle-show-on-hover") {
                root.toggleShowOnHover();
            } else if (action === "settings") {
                BarService.openPluginSettings(screen, root.pluginApi.manifest);
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
            enabled: textShowAnim.running || textHideAnim.running

            NumberAnimation {
                duration: Style.animationNormal
                easing.type: Easing.OutCubic
            }
        }

        RowLayout {
            id: capsuleRow
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                icon: root.barIcon
                color: mouseArea.containsMouse ? Color.mOnHover : root.resolvedBarIconColor
                pointSize: Style.toOdd(root.capsuleHeight * 0.48)
                applyUiScale: false
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                clip: true
                visible: root.animatedTextWidth > 0 || root.forceRevealText
                opacity: root.animatedTextOpacity
                Layout.preferredWidth: root.animatedTextWidth
                Layout.preferredHeight: providerTextRow.implicitHeight
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: providerTextRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.marginS

                    Repeater {
                        model: root.providerSegments

                        delegate: RowLayout {
                            id: segmentRow
                            required property int index
                            required property var modelData
                            readonly property bool showJoiner: index > 0
                            readonly property bool showIcon: modelData.showIcon
                            readonly property var segmentVisual: modelData.visual || ({})
                            readonly property string segmentLabel: modelData.label || ""
                            readonly property string segmentText: modelData.text || ""

                            spacing: Style.marginXS
                            Layout.alignment: Qt.AlignVCenter

                            NText {
                                visible: segmentRow.showJoiner
                                text: root.providerJoiner()
                                color: mouseArea.containsMouse ? Color.mOnHover : root.resolvedBarTextColor
                                pointSize: root.barFontSize
                                applyUiScale: false
                            }

                            ProviderVisual {
                                visible: segmentRow.showIcon
                                visualData: segmentRow.segmentVisual
                                color: mouseArea.containsMouse ? Color.mOnHover : root.resolvedBarTextColor
                                colorize: root.providerIconColorize
                                colorizeColor: mouseArea.containsMouse ? Color.mOnHover : root.resolvedProviderIconColorizeColor
                                pointSize: Math.max(12, root.barFontSize)
                                applyUiScale: false
                                Layout.alignment: Qt.AlignVCenter
                                Layout.rightMargin: Style.marginS
                            }

                            NText {
                                visible: segmentRow.segmentLabel !== ""
                                text: segmentRow.segmentLabel
                                color: mouseArea.containsMouse ? Color.mOnHover : root.resolvedBarTextColor
                                pointSize: root.barFontSize
                                applyUiScale: false
                            }

                            NText {
                                text: segmentRow.segmentText
                                color: mouseArea.containsMouse ? Color.mOnHover : root.resolvedBarTextColor
                                pointSize: root.barFontSize
                                applyUiScale: false
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                if (root.pluginApi)
                    root.pluginApi.togglePanel(root.screen, root);
            } else if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, root.screen);
            }
        }

        onEntered: {
            TooltipService.show(visualCapsule, root.tooltipText, BarService.getTooltipDirection(root.screenName));
            root.showTextDelayed();
        }
        onExited: {
            root.hideTextAnimated();
            TooltipService.hide();
        }
    }

    Component.onCompleted: root.syncTextRevealState()
}
