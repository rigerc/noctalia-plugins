import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./settings"

ColumnLayout {
    id: root

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property real preferredWidth: 720 * Style.uiScaleRatio
    property int selectedTab: 0
    property var configProvidersModel: []

    function allowedBarTextFieldKeys() {
        return ["primary", "secondary", "tertiary", "status"];
    }

    function allowedRefreshIntervals() {
        return [60, 120, 300, 600, 900, 1800, 3600, 7200, 21600, 43200, 86400];
    }

    function normalizeRefreshInterval(intervalValue) {
        var allowed = root.allowedRefreshIntervals();
        var numeric = Number(intervalValue);
        if (!isFinite(numeric))
            numeric = 120;

        var best = allowed[0];
        var smallestDiff = Math.abs(best - numeric);
        for (var index = 1; index < allowed.length; index++) {
            var candidate = allowed[index];
            var diff = Math.abs(candidate - numeric);
            if (diff < smallestDiff) {
                best = candidate;
                smallestDiff = diff;
            }
        }
        return best;
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

    function firstAvailableCountdownWindow(currentWindows) {
        var windows = Array.isArray(currentWindows) ? currentWindows : [];
        var allowed = ["primary", "secondary", "tertiary"];
        for (var index = 0; index < allowed.length; index++) {
            if (windows.indexOf(allowed[index]) < 0)
                return allowed[index];
        }
        return allowed[0];
    }

    function syncCountdownWindowToAdd() {
        root.editCountdownWindowToAdd = root.firstAvailableCountdownWindow(root.editBarCountdownWindows);
    }

    function addCountdownWindow(windowKey) {
        var key = String(windowKey || "").trim();
        if (key === "" || root.editBarCountdownWindows.indexOf(key) >= 0)
            return;
        root.editBarCountdownWindows = root.editBarCountdownWindows.concat([key]);
        root.syncCountdownWindowToAdd();
    }

    function removeCountdownWindow(index) {
        if (!Array.isArray(root.editBarCountdownWindows) || root.editBarCountdownWindows.length <= 1)
            return;
        if (index < 0 || index >= root.editBarCountdownWindows.length)
            return;
        var next = root.editBarCountdownWindows.slice();
        next.splice(index, 1);
        root.editBarCountdownWindows = root.normalizeCountdownWindows(next);
        root.syncCountdownWindowToAdd();
    }

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
        case "bell-outline":
            return "bell";
        case "cog-outline":
            return "settings";
        case "content-save":
            return "device-floppy";
        case "open-in-new":
            return "external-link";
        default:
            return normalized;
        }
    }

    function normalizeBarTextFields(fields) {
        var allowed = root.allowedBarTextFieldKeys();
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

    function normalizeBarProviderIds(providerIds) {
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

    function normalizeBarProviderLabelMode(mode) {
        var normalized = String(mode || "").trim();
        return normalized === "prefix" ? "prefix" : "icon";
    }

    function availableWidgetProviders() {
        var items = [];
        var seen = {};
        var configProviders = Array.isArray(root.configProvidersModel) ? root.configProvidersModel : [];

        for (var index = 0; index < configProviders.length; index++) {
            var provider = configProviders[index];
            var providerId = String(provider?.id || "").trim();
            if (providerId === "" || provider?.enabled === false || seen[providerId])
                continue;
            seen[providerId] = true;
            items.push({
                "key": providerId,
                "name": root.mainInstance?.providerDisplayName(providerId) || providerId
            });
        }

        if (items.length > 0)
            return items;

        var runtimeProviders = root.mainInstance?.providerData || [];
        for (var runtimeIndex = 0; runtimeIndex < runtimeProviders.length; runtimeIndex++) {
            var runtimeId = String(runtimeProviders[runtimeIndex]?.provider || "").trim();
            if (runtimeId === "" || seen[runtimeId])
                continue;
            seen[runtimeId] = true;
            items.push({
                "key": runtimeId,
                "name": root.mainInstance?.providerDisplayName(runtimeId) || runtimeId
            });
        }

        return items;
    }

    function providerOptionName(providerId) {
        var key = String(providerId || "").trim();
        if (key === "")
            return "";

        var options = Array.isArray(root.widgetProviderOptions) ? root.widgetProviderOptions : [];
        for (var index = 0; index < options.length; index++) {
            if (options[index].key === key)
                return options[index].name;
        }

        return root.mainInstance?.providerDisplayName(key) || key;
    }

    function syncSelectedWidgetProviders() {
        var availableIds = {};
        var options = Array.isArray(root.widgetProviderOptions) ? root.widgetProviderOptions : [];
        for (var index = 0; index < options.length; index++)
            availableIds[options[index].key] = true;

        var currentSelection = root.normalizeBarProviderIds(root.editBarProviderIds);
        var filtered = [];
        for (var selectedIndex = 0; selectedIndex < currentSelection.length; selectedIndex++) {
            var selectedId = currentSelection[selectedIndex];
            if (availableIds[selectedId])
                filtered.push(selectedId);
        }
        root.editBarProviderIds = filtered;
    }

    function addBarProvider(providerId) {
        var key = String(providerId || "").trim();
        if (key === "" || root.editBarProviderIds.indexOf(key) >= 0 || root.editBarProviderIds.length >= 3)
            return;
        root.editBarProviderIds = root.normalizeBarProviderIds(root.editBarProviderIds.concat([key]));
    }

    function removeBarProvider(index) {
        if (!Array.isArray(root.editBarProviderIds) || index < 0 || index >= root.editBarProviderIds.length)
            return;
        var next = root.editBarProviderIds.slice();
        next.splice(index, 1);
        root.editBarProviderIds = root.normalizeBarProviderIds(next);
    }

    function moveBarProvider(fromIndex, toIndex) {
        if (!Array.isArray(root.editBarProviderIds))
            return;
        if (fromIndex < 0 || fromIndex >= root.editBarProviderIds.length)
            return;
        if (toIndex < 0 || toIndex >= root.editBarProviderIds.length || fromIndex === toIndex)
            return;

        var next = root.editBarProviderIds.slice();
        var moved = next[fromIndex];
        next.splice(fromIndex, 1);
        next.splice(toIndex, 0, moved);
        root.editBarProviderIds = root.normalizeBarProviderIds(next);
    }

    function firstAvailableBarTextField(currentFields) {
        var fields = Array.isArray(currentFields) ? currentFields : [];
        var allowed = root.allowedBarTextFieldKeys();
        for (var index = 0; index < allowed.length; index++) {
            if (fields.indexOf(allowed[index]) < 0)
                return allowed[index];
        }
        return allowed[0];
    }

    function syncBarTextFieldToAdd() {
        root.editBarTextFieldToAdd = root.firstAvailableBarTextField(root.editBarTextFields);
    }

    function addBarTextField(fieldKey) {
        var key = String(fieldKey || "").trim();
        if (key === "" || root.editBarTextFields.indexOf(key) >= 0)
            return;
        root.editBarTextFields = root.editBarTextFields.concat([key]);
        root.syncBarTextFieldToAdd();
    }

    function removeBarTextField(index) {
        if (!Array.isArray(root.editBarTextFields) || root.editBarTextFields.length <= 1)
            return;
        if (index < 0 || index >= root.editBarTextFields.length)
            return;

        var next = root.editBarTextFields.slice();
        next.splice(index, 1);
        root.editBarTextFields = root.normalizeBarTextFields(next);
        root.syncBarTextFieldToAdd();
    }

    function moveBarTextField(index, delta) {
        var nextIndex = index + delta;
        if (!Array.isArray(root.editBarTextFields))
            return;
        if (index < 0 || index >= root.editBarTextFields.length)
            return;
        if (nextIndex < 0 || nextIndex >= root.editBarTextFields.length)
            return;

        var next = root.editBarTextFields.slice();
        var moved = next[index];
        next.splice(index, 1);
        next.splice(nextIndex, 0, moved);
        root.editBarTextFields = next;
    }

    property string editBarIcon: normalizeIconName(cfg.barIcon ?? defaults.barIcon ?? "sparkles")
    property string editBarIconColor: cfg.barIconColor ?? defaults.barIconColor ?? "on-surface"
    property var editBarProviderIds: normalizeBarProviderIds(cfg.barProviderIds ?? defaults.barProviderIds ?? [])
    property string editBarProviderLabelMode: normalizeBarProviderLabelMode(cfg.barProviderLabelMode ?? defaults.barProviderLabelMode ?? "icon")
    property string editBarProviderSeparator: String(cfg.barProviderSeparator ?? defaults.barProviderSeparator ?? "|")
    property int editBarProviderSeparatorSpacing: Math.max(0, Math.min(4, Number(cfg.barProviderSeparatorSpacing ?? defaults.barProviderSeparatorSpacing ?? 1)))
    property var editBarTextFields: normalizeBarTextFields(cfg.barTextFields ?? defaults.barTextFields ?? ["primary"])
    property string editBarTextSeparator: String(cfg.barTextSeparator ?? defaults.barTextSeparator ?? "·")
    property int editBarTextSeparatorSpacing: Math.max(0, Math.min(4, Number(cfg.barTextSeparatorSpacing ?? defaults.barTextSeparatorSpacing ?? 1)))
    property string editBarTextColor: String(cfg.barTextColor ?? defaults.barTextColor ?? "on-surface")
    property int editBarTextOpacityPercent: Math.max(0, Math.min(100, Math.round(Number(cfg.barTextOpacity ?? defaults.barTextOpacity ?? 1) * 100)))
    property string editBarTextFieldToAdd: firstAvailableBarTextField(editBarTextFields)
    property bool editBarTextShowOnHover: cfg.barTextShowOnHover ?? defaults.barTextShowOnHover ?? false
    property bool editBarTextExpandOnChange: cfg.barTextExpandOnChange ?? defaults.barTextExpandOnChange ?? false
    property bool editBarLowUsageAlertEnabled: cfg.barLowUsageAlertEnabled ?? defaults.barLowUsageAlertEnabled ?? false
    property string editBarLowUsageAlertWindow: String(cfg.barLowUsageAlertWindow ?? defaults.barLowUsageAlertWindow ?? "primary")
    property string editBarLowUsageAlertColor: String(cfg.barLowUsageAlertColor ?? defaults.barLowUsageAlertColor ?? "error")
    property bool editBarCountdownOnEmpty: cfg.barCountdownOnEmpty ?? defaults.barCountdownOnEmpty ?? false
    property var editBarCountdownWindows: normalizeCountdownWindows(cfg.barCountdownWindows ?? defaults.barCountdownWindows ?? ["primary"])
    property string editCountdownWindowToAdd: firstAvailableCountdownWindow(editBarCountdownWindows)
    property int editRefreshInterval: normalizeRefreshInterval(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)
    property string editDefaultProvider: cfg.defaultProvider ?? defaults.defaultProvider ?? ""
    property bool editNotifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    property bool editNotifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    property int editLowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property var widgetProviderOptions: availableWidgetProviders()
    readonly property var availableWidgetProviderOptions: {
        var selected = root.editBarProviderIds || [];
        var options = Array.isArray(root.widgetProviderOptions) ? root.widgetProviderOptions : [];
        return options.filter(function (option) {
            return selected.indexOf(option.key) < 0;
        });
    }
    readonly property var providerLabelModeOptions: [
        {
            "key": "icon",
            "name": pluginApi?.tr("settings.general.providers.labelMode.icon")
        },
        {
            "key": "prefix",
            "name": pluginApi?.tr("settings.general.providers.labelMode.prefix")
        }
    ]

    spacing: Style.marginL
    implicitWidth: preferredWidth

    readonly property var barTextFieldOptions: [
        {
            "key": "primary",
            "name": pluginApi?.tr("settings.general.textFields.options.primary")
        },
        {
            "key": "secondary",
            "name": pluginApi?.tr("settings.general.textFields.options.secondary")
        },
        {
            "key": "tertiary",
            "name": pluginApi?.tr("settings.general.textFields.options.tertiary")
        },
        {
            "key": "status",
            "name": pluginApi?.tr("settings.general.textFields.options.status")
        }
    ]

    readonly property var refreshIntervalOptions: [
        {
            "key": "60",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.oneMinute")
        },
        {
            "key": "120",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.twoMinutes")
        },
        {
            "key": "300",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.fiveMinutes")
        },
        {
            "key": "600",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.tenMinutes")
        },
        {
            "key": "900",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.fifteenMinutes")
        },
        {
            "key": "1800",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.thirtyMinutes")
        },
        {
            "key": "3600",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.oneHour")
        },
        {
            "key": "7200",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.twoHours")
        },
        {
            "key": "21600",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.sixHours")
        },
        {
            "key": "43200",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.twelveHours")
        },
        {
            "key": "86400",
            "name": pluginApi?.tr("settings.general.refreshInterval.options.twentyFourHours")
        }
    ]

    readonly property var lowUsageAlertWindowOptions: [
        {
            "key": "primary",
            "name": pluginApi?.tr("settings.general.lowUsageAlert.window.options.primary")
        },
        {
            "key": "secondary",
            "name": pluginApi?.tr("settings.general.lowUsageAlert.window.options.secondary")
        },
        {
            "key": "tertiary",
            "name": pluginApi?.tr("settings.general.lowUsageAlert.window.options.tertiary")
        }
    ]

    readonly property var countdownWindowOptions: [
        {
            "key": "primary",
            "name": pluginApi?.tr("settings.general.behavior.countdownWindows.options.primary")
        },
        {
            "key": "secondary",
            "name": pluginApi?.tr("settings.general.behavior.countdownWindows.options.secondary")
        },
        {
            "key": "tertiary",
            "name": pluginApi?.tr("settings.general.behavior.countdownWindows.options.tertiary")
        }
    ]

    readonly property var tabModel: [
        {
            "label": pluginApi?.tr("settings.tabs.general"),
            "icon": "sparkles"
        },
        {
            "label": pluginApi?.tr("settings.tabs.notifications"),
            "icon": "bell"
        },
        {
            "label": pluginApi?.tr("settings.tabs.config"),
            "icon": "settings"
        }
    ]

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.editBarIcon = root.normalizeIconName(cfg.barIcon ?? defaults.barIcon ?? "sparkles");
            root.editBarIconColor = cfg.barIconColor ?? defaults.barIconColor ?? "on-surface";
            root.editBarProviderIds = root.normalizeBarProviderIds(cfg.barProviderIds ?? defaults.barProviderIds ?? []);
            root.editBarProviderLabelMode = root.normalizeBarProviderLabelMode(cfg.barProviderLabelMode ?? defaults.barProviderLabelMode ?? "icon");
            root.editBarProviderSeparator = String(cfg.barProviderSeparator ?? defaults.barProviderSeparator ?? "|");
            root.editBarProviderSeparatorSpacing = Math.max(0, Math.min(4, Number(cfg.barProviderSeparatorSpacing ?? defaults.barProviderSeparatorSpacing ?? 1)));
            root.editBarTextFields = root.normalizeBarTextFields(cfg.barTextFields ?? defaults.barTextFields ?? ["primary"]);
            root.editBarTextSeparator = String(cfg.barTextSeparator ?? defaults.barTextSeparator ?? "·");
            root.editBarTextSeparatorSpacing = Math.max(0, Math.min(4, Number(cfg.barTextSeparatorSpacing ?? defaults.barTextSeparatorSpacing ?? 1)));
            root.editBarTextColor = String(cfg.barTextColor ?? defaults.barTextColor ?? "on-surface");
            root.editBarTextOpacityPercent = Math.max(0, Math.min(100, Math.round(Number(cfg.barTextOpacity ?? defaults.barTextOpacity ?? 1) * 100)));
            root.editBarTextShowOnHover = cfg.barTextShowOnHover ?? defaults.barTextShowOnHover ?? false;
            root.editBarTextExpandOnChange = cfg.barTextExpandOnChange ?? defaults.barTextExpandOnChange ?? false;
            root.editBarLowUsageAlertEnabled = cfg.barLowUsageAlertEnabled ?? defaults.barLowUsageAlertEnabled ?? false;
            root.editBarLowUsageAlertWindow = String(cfg.barLowUsageAlertWindow ?? defaults.barLowUsageAlertWindow ?? "primary");
            root.editBarLowUsageAlertColor = String(cfg.barLowUsageAlertColor ?? defaults.barLowUsageAlertColor ?? "error");
            root.editBarCountdownOnEmpty = cfg.barCountdownOnEmpty ?? defaults.barCountdownOnEmpty ?? false;
            root.editBarCountdownWindows = root.normalizeCountdownWindows(cfg.barCountdownWindows ?? defaults.barCountdownWindows ?? ["primary"]);
            root.editRefreshInterval = root.normalizeRefreshInterval(cfg.refreshInterval ?? defaults.refreshInterval ?? 120);
            root.editDefaultProvider = cfg.defaultProvider ?? defaults.defaultProvider ?? "";
            root.editNotifyOnReset = cfg.notifyOnReset ?? defaults.notifyOnReset ?? true;
            root.editNotifyOnLowUsage = cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true;
            root.editLowUsageThreshold = Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)));
            root.syncSelectedWidgetProviders();
            root.syncBarTextFieldToAdd();
            root.syncCountdownWindowToAdd();
        }
    }

    onConfigProvidersModelChanged: syncSelectedWidgetProviders()

    NTabBar {
        currentIndex: selectedTab
        Layout.fillWidth: true
        distributeEvenly: true

        Repeater {
            model: root.tabModel

            delegate: NTabButton {
                required property int index
                required property var modelData

                text: modelData.label
                icon: modelData.icon
                tabIndex: index
                checked: root.selectedTab === index
                onClicked: root.selectedTab = index
            }
        }
    }

    NTabView {
        currentIndex: selectedTab
        Layout.fillWidth: true

        GeneralSettingsTab {
            rootSettings: root
        }

        NotificationsSettingsTab {
            rootSettings: root
        }

        ConfigSettingsTab {
            rootSettings: root
        }
    }

    function saveSettings() {
        if (!pluginApi)
            return;

        pluginApi.pluginSettings.barIcon = normalizeIconName(editBarIcon);
        delete pluginApi.pluginSettings.barIconPath;
        pluginApi.pluginSettings.barIconColor = editBarIconColor;
        pluginApi.pluginSettings.barProviderIds = normalizeBarProviderIds(editBarProviderIds);
        pluginApi.pluginSettings.barProviderLabelMode = normalizeBarProviderLabelMode(editBarProviderLabelMode);
        pluginApi.pluginSettings.barProviderSeparator = editBarProviderSeparator;
        pluginApi.pluginSettings.barProviderSeparatorSpacing = Math.max(0, Math.min(4, Number(editBarProviderSeparatorSpacing)));
        pluginApi.pluginSettings.barTextFields = normalizeBarTextFields(editBarTextFields);
        pluginApi.pluginSettings.barTextSeparator = editBarTextSeparator;
        pluginApi.pluginSettings.barTextSeparatorSpacing = editBarTextSeparatorSpacing;
        pluginApi.pluginSettings.barTextColor = editBarTextColor;
        pluginApi.pluginSettings.barTextOpacity = Math.max(0, Math.min(1, editBarTextOpacityPercent / 100));
        pluginApi.pluginSettings.barTextShowOnHover = editBarTextShowOnHover;
        pluginApi.pluginSettings.barTextExpandOnChange = editBarTextExpandOnChange;
        pluginApi.pluginSettings.barLowUsageAlertEnabled = editBarLowUsageAlertEnabled;
        pluginApi.pluginSettings.barLowUsageAlertWindow = (editBarLowUsageAlertWindow === "secondary" || editBarLowUsageAlertWindow === "tertiary") ? editBarLowUsageAlertWindow : "primary";
        pluginApi.pluginSettings.barLowUsageAlertColor = editBarLowUsageAlertColor;
        pluginApi.pluginSettings.barCountdownOnEmpty = editBarCountdownOnEmpty;
        pluginApi.pluginSettings.barCountdownWindows = normalizeCountdownWindows(editBarCountdownWindows);
        pluginApi.pluginSettings.refreshInterval = normalizeRefreshInterval(editRefreshInterval);
        pluginApi.pluginSettings.defaultProvider = pluginApi.pluginSettings.barProviderIds.length > 0 ? pluginApi.pluginSettings.barProviderIds[0] : editDefaultProvider;
        pluginApi.pluginSettings.notifyOnReset = editNotifyOnReset;
        pluginApi.pluginSettings.notifyOnLowUsage = editNotifyOnLowUsage;
        pluginApi.pluginSettings.lowUsageThreshold = editLowUsageThreshold;
        pluginApi.saveSettings();
    }
}
