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

    property string editBarIcon: normalizeIconName(cfg.barIcon ?? defaults.barIcon ?? "sparkles")
    property string editBarIconColor: cfg.barIconColor ?? defaults.barIconColor ?? "on-surface"
    property int editBarIconTextSpacing: Math.max(0, Math.min(24, Number(cfg.barIconTextSpacing ?? defaults.barIconTextSpacing ?? 6)))
    property int editBarTextPointSize: Math.max(0, Math.min(24, Number(cfg.barTextPointSize ?? defaults.barTextPointSize ?? 0)))
    property string editBarTextFontFamily: String(cfg.barTextFontFamily ?? defaults.barTextFontFamily ?? "")
    property string editBarTextFontWeight: String(cfg.barTextFontWeight ?? defaults.barTextFontWeight ?? "normal")
    property bool editBarTextItalic: cfg.barTextItalic ?? defaults.barTextItalic ?? false
    property bool editBarTextUnderline: cfg.barTextUnderline ?? defaults.barTextUnderline ?? false
    property int editRefreshInterval: Math.max(30, Math.min(600, Number(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)))
    property string editDefaultProvider: cfg.defaultProvider ?? defaults.defaultProvider ?? ""
    property bool editNotifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    property bool editNotifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    property int editLowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

    readonly property var mainInstance: pluginApi?.mainInstance

    spacing: Style.marginL
    implicitWidth: preferredWidth

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
            root.editBarIconTextSpacing = Math.max(0, Math.min(24, Number(cfg.barIconTextSpacing ?? defaults.barIconTextSpacing ?? 6)));
            root.editBarTextPointSize = Math.max(0, Math.min(24, Number(cfg.barTextPointSize ?? defaults.barTextPointSize ?? 0)));
            root.editBarTextFontFamily = String(cfg.barTextFontFamily ?? defaults.barTextFontFamily ?? "");
            root.editBarTextFontWeight = String(cfg.barTextFontWeight ?? defaults.barTextFontWeight ?? "normal");
            root.editBarTextItalic = cfg.barTextItalic ?? defaults.barTextItalic ?? false;
            root.editBarTextUnderline = cfg.barTextUnderline ?? defaults.barTextUnderline ?? false;
            root.editRefreshInterval = Math.max(30, Math.min(600, Number(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)));
            root.editDefaultProvider = cfg.defaultProvider ?? defaults.defaultProvider ?? "";
            root.editNotifyOnReset = cfg.notifyOnReset ?? defaults.notifyOnReset ?? true;
            root.editNotifyOnLowUsage = cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true;
            root.editLowUsageThreshold = Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)));
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
        pluginApi.pluginSettings.barIconTextSpacing = editBarIconTextSpacing;
        pluginApi.pluginSettings.barTextPointSize = editBarTextPointSize;
        pluginApi.pluginSettings.barTextFontFamily = editBarTextFontFamily;
        pluginApi.pluginSettings.barTextFontWeight = editBarTextFontWeight;
        pluginApi.pluginSettings.barTextItalic = editBarTextItalic;
        pluginApi.pluginSettings.barTextUnderline = editBarTextUnderline;
        pluginApi.pluginSettings.refreshInterval = editRefreshInterval;
        pluginApi.pluginSettings.defaultProvider = editDefaultProvider;
        pluginApi.pluginSettings.notifyOnReset = editNotifyOnReset;
        pluginApi.pluginSettings.notifyOnLowUsage = editNotifyOnLowUsage;
        pluginApi.pluginSettings.lowUsageThreshold = editLowUsageThreshold;
        pluginApi.saveSettings();
    }
}
