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

    function allowedBarTextFieldKeys() {
        return ["primary", "secondary", "status"];
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
    property int editRefreshInterval: normalizeRefreshInterval(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)
    property string editDefaultProvider: cfg.defaultProvider ?? defaults.defaultProvider ?? ""
    property bool editNotifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    property bool editNotifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    property int editLowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

    readonly property var mainInstance: pluginApi?.mainInstance

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
            root.editRefreshInterval = root.normalizeRefreshInterval(cfg.refreshInterval ?? defaults.refreshInterval ?? 120);
            root.editDefaultProvider = cfg.defaultProvider ?? defaults.defaultProvider ?? "";
            root.editNotifyOnReset = cfg.notifyOnReset ?? defaults.notifyOnReset ?? true;
            root.editNotifyOnLowUsage = cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true;
            root.editLowUsageThreshold = Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)));
            root.syncBarTextFieldToAdd();
        }
    }

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
        pluginApi.pluginSettings.barTextFields = normalizeBarTextFields(editBarTextFields);
        pluginApi.pluginSettings.barTextSeparator = editBarTextSeparator;
        pluginApi.pluginSettings.barTextSeparatorSpacing = editBarTextSeparatorSpacing;
        pluginApi.pluginSettings.barTextColor = editBarTextColor;
        pluginApi.pluginSettings.barTextOpacity = Math.max(0, Math.min(1, editBarTextOpacityPercent / 100));
        pluginApi.pluginSettings.barTextShowOnHover = editBarTextShowOnHover;
        pluginApi.pluginSettings.barTextExpandOnChange = editBarTextExpandOnChange;
        pluginApi.pluginSettings.barLowUsageAlertEnabled = editBarLowUsageAlertEnabled;
        pluginApi.pluginSettings.barLowUsageAlertWindow = editBarLowUsageAlertWindow === "secondary" ? "secondary" : "primary";
        pluginApi.pluginSettings.barLowUsageAlertColor = editBarLowUsageAlertColor;
        pluginApi.pluginSettings.refreshInterval = normalizeRefreshInterval(editRefreshInterval);
        pluginApi.pluginSettings.defaultProvider = editDefaultProvider;
        pluginApi.pluginSettings.notifyOnReset = editNotifyOnReset;
        pluginApi.pluginSettings.notifyOnLowUsage = editNotifyOnLowUsage;
        pluginApi.pluginSettings.lowUsageThreshold = editLowUsageThreshold;
        pluginApi.saveSettings();
    }
}
