import QtQuick
import "providers"

Item {
    id: root
    visible: false

    property var pluginApi: null
    property var pluginSettings: pluginApi?.pluginSettings ?? ({})

    Claude {
        id: claudeProvider
        enabled: root.providerEnabled("claude")
        providerSettings: root.pluginSettings?.providers?.claude ?? ({})
        includeCacheTokens: root.pluginSettings?.includeCacheTokens ?? true
    }

    Codex {
        id: codexProvider
        enabled: root.providerEnabled("codex")
        providerSettings: root.pluginSettings?.providers?.codex ?? ({})
        includeCacheTokens: root.pluginSettings?.includeCacheTokens ?? true
    }

    OpenRouter {
        id: openRouterProvider
        enabled: root.providerEnabled("openrouter")
        providerSettings: root.pluginSettings?.providers?.openrouter ?? ({})
    }

    Copilot {
        id: copilotProvider
        enabled: root.providerEnabled("copilot")
        providerSettings: root.pluginSettings?.providers?.copilot ?? ({})
    }

    Zen {
        id: zenProvider
        enabled: root.providerEnabled("zen")
        providerSettings: root.pluginSettings?.providers?.zen ?? ({})
    }

    DeepSeek {
        id: deepseekProvider
        enabled: root.providerEnabled("deepseek")
        providerSettings: root.pluginSettings?.providers?.deepseek ?? ({})
    }

    property var providers: [claudeProvider, codexProvider, copilotProvider, openRouterProvider, zenProvider, deepseekProvider]

    property var providerMap: ({
        "claude": claudeProvider,
        "codex": codexProvider,
        "copilot": copilotProvider,
        "openrouter": openRouterProvider,
        "zen": zenProvider,
        "deepseek": deepseekProvider
    })

    property var enabledProviders: {
        const order = pluginSettings?.providerOrder ?? ["claude", "codex", "copilot", "openrouter", "zen", "deepseek"];
        const result = [];
        for (const id of order) {
            const p = providerMap[id];
            if (p && p.enabled)
                result.push(p);
        }
        return result;
    }

    property int activeIndex: 0

    property var activeProvider: {
        if (enabledProviders.length === 0)
            return null;
        if (barDisplayMode === "cycle")
            return enabledProviders[Math.min(activeIndex, enabledProviders.length - 1)];
        return enabledProviders[0];
    }

    property string barDisplayMode: pluginSettings?.barDisplayMode ?? "active"
    property int barCycleIntervalSec: pluginSettings?.barCycleIntervalSec ?? 5
    property bool barShowRemaining: pluginSettings?.barShowRemaining ?? false
    property bool barTextShowOnHover: pluginSettings?.barTextShowOnHover ?? false
    property bool barIconAlertOnLimit: pluginSettings?.barIconAlertOnLimit ?? false
    property int barIconAlertThreshold: Math.max(50, Math.min(100, Number(pluginSettings?.barIconAlertThreshold ?? 95)))
    property int refreshIntervalSec: pluginSettings?.refreshIntervalSec ?? 30

    property string barMetric: {
        const raw = String(pluginSettings?.barMetric ?? "prompts").trim();
        // Migrate old usage24h/usage24h7d keys to usage5h/usage5h7d
        if (raw === "usage24h") return "usage5h";
        if (raw === "usage24h7d") return "usage5h7d";
        return raw;
    }

    Timer {
        interval: root.barCycleIntervalSec * 1000
        running: root.barDisplayMode === "cycle" && root.enabledProviders.length > 1
        repeat: true
        onTriggered: {
            root.activeIndex = (root.activeIndex + 1) % root.enabledProviders.length;
        }
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    onEnabledProvidersChanged: {
        if (enabledProviders.length === 0) {
            activeIndex = 0;
        } else if (activeIndex >= enabledProviders.length) {
            activeIndex = 0;
        }
    }

    function providerEnabled(id) {
        return pluginSettings?.providers?.[id]?.enabled ?? false;
    }

    function refresh() {
        refreshAll();
    }

    function refreshAll() {
        for (const p of providers) {
            if (p.enabled)
                p.refresh();
        }
    }

    function formatTokenCount(n) {
        if (n === undefined || n === null)
            return "0";
        if (n >= 1e9)
            return (n / 1e9).toFixed(1) + "B";
        if (n >= 1e6)
            return (n / 1e6).toFixed(1) + "M";
        if (n >= 1e3)
            return (n / 1e3).toFixed(1) + "K";
        return String(n);
    }

    function providerIconAsset(providerId) {
        if (!providerId)
            return "";
        var p = root.providerMap[providerId];
        if (p && p.providerIconAsset)
            return String(p.providerIconAsset);
        return "";
    }

    function providerAssetUrl(providerId) {
        var assetPath = root.providerIconAsset(providerId);
        if (!assetPath || !pluginApi?.pluginDir)
            return "";
        return Qt.resolvedUrl(pluginApi.pluginDir + "/" + assetPath);
    }

    function providerVisualData(providerId) {
        var id = String(providerId || "").trim();
        var p = root.providerMap[id];
        var assetPath = p ? String(p.providerIconAsset || "") : "";
        var iconName = p ? String(p.providerIcon || "ai") : "ai";

        if (assetPath !== "") {
            return {
                "source": "asset",
                "icon": iconName,
                "asset": assetPath,
                "assetUrl": root.providerAssetUrl(id)
            };
        }
        return {
            "source": "icon",
            "icon": iconName,
            "asset": "",
            "assetUrl": ""
        };
    }

    function friendlyModelName(id) {
        if (!id)
            return "Unknown";
        let name = id.replace(/^claude-/, "");
        name = name.replace(/-\d{8}$/, "");
        const parts = name.split("-");
        if (parts.length >= 3) {
            const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            return family + " " + parts[1] + "." + parts[2];
        }
        if (parts.length === 2) {
            const family = parts[0].charAt(0).toUpperCase() + parts[0].slice(1);
            return family + " " + parts[1];
        }
        return name.charAt(0).toUpperCase() + name.slice(1);
    }
}
