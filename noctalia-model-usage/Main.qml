import QtQuick
import "providers"

Item {
    id: root
    visible: false

    property var pluginApi: null
    property var pluginSettings: pluginApi?.pluginSettings ?? ({})

    Claude {
        id: claudeProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("claude")
        providerSettings: root.pluginSettings?.providers?.claude ?? ({})
        includeCacheTokens: root.pluginSettings?.includeCacheTokens ?? true
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    Codex {
        id: codexProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("codex")
        providerSettings: root.pluginSettings?.providers?.codex ?? ({})
        includeCacheTokens: root.pluginSettings?.includeCacheTokens ?? true
        apiRefreshIntervalMin: root.apiRefreshIntervalMin
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    OpenRouter {
        id: openRouterProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("openrouter")
        providerSettings: root.pluginSettings?.providers?.openrouter ?? ({})
        apiRefreshIntervalMin: root.apiRefreshIntervalMin
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    Copilot {
        id: copilotProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("copilot")
        providerSettings: root.pluginSettings?.providers?.copilot ?? ({})
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    Zen {
        id: zenProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("zen")
        providerSettings: root.pluginSettings?.providers?.zen ?? ({})
        apiRefreshIntervalMin: root.apiRefreshIntervalMin
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    DeepSeek {
        id: deepseekProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("deepseek")
        providerSettings: root.pluginSettings?.providers?.deepseek ?? ({})
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    KiloCode {
        id: kiloCodeProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("kilocode")
        providerSettings: root.pluginSettings?.providers?.kilocode ?? ({})
        apiRefreshIntervalMin: root.apiRefreshIntervalMin
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    Zai {
        id: zaiProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("zai")
        providerSettings: root.pluginSettings?.providers?.zai ?? ({})
        apiRefreshIntervalMin: root.apiRefreshIntervalMin
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    Gemini {
        id: geminiProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("gemini")
        providerSettings: root.pluginSettings?.providers?.gemini ?? ({})
        apiRefreshIntervalMin: root.apiRefreshIntervalMin
        onRateLimitPercentChanged: root.trackProvider7dUsageChange(providerId, rateLimitPercent)
    }

    readonly property var defaultProviderOrder: ["claude", "codex", "copilot", "openrouter", "zen", "deepseek", "kilocode", "zai", "gemini"]
    property var providers: [claudeProvider, codexProvider, copilotProvider, openRouterProvider, zenProvider, deepseekProvider, kiloCodeProvider, zaiProvider, geminiProvider]

    property var providerMap: ({
        "claude": claudeProvider,
        "codex": codexProvider,
        "copilot": copilotProvider,
        "openrouter": openRouterProvider,
        "zen": zenProvider,
        "deepseek": deepseekProvider,
        "kilocode": kiloCodeProvider,
        "zai": zaiProvider,
        "gemini": geminiProvider
    })

    property string providerOrderMode: String(pluginSettings?.providerOrderMode ?? "manual")
    property var lastSeen7dPercentByProvider: ({})
    property var lastChanged7dOrderByProvider: ({})
    property int providerChangeSequence: 0
    property int providerSortRevision: 0

    property var manualProviderOrder: root.normalizedProviderOrder(pluginSettings?.providerOrder)

    property var effectiveProviderOrder: {
        root.providerSortRevision;
        const order = root.manualProviderOrder.slice();
        if (root.providerOrderMode !== "recent7dChange")
            return order;

        const manualIndex = {};
        for (let i = 0; i < order.length; i++)
            manualIndex[order[i]] = i;

        return order.sort((a, b) => {
            const aChanged = root.lastChanged7dOrderByProvider[a] ?? 0;
            const bChanged = root.lastChanged7dOrderByProvider[b] ?? 0;
            if (aChanged !== bChanged)
                return bChanged - aChanged;
            return (manualIndex[a] ?? 999) - (manualIndex[b] ?? 999);
        });
    }

    property var enabledProviders: {
        const result = [];
        for (const id of root.effectiveProviderOrder) {
            const p = root.providerMap[id];
            if (p && p.providerEnabled)
                result.push(p);
        }
        return result;
    }

    // Bar-only filtered subset (respects showInWidget)
    property var barProviders: {
        const result = [];
        for (const p of root.enabledProviders) {
            const ps = pluginSettings?.providers?.[p.providerId] ?? {};
            if (ps.showInWidget !== false)
                result.push(p);
        }
        return result;
    }

    property int activeIndex: 0

    property var activeProvider: {
        if (barProviders.length === 0)
            return null;
        if (barCycleEnabled)
            return barProviders[Math.min(activeIndex, barProviders.length - 1)];
        return barProviders[0];
    }

    property int apiRefreshIntervalMin: Math.max(1, Math.min(360,
        Number(pluginSettings?.apiRefreshIntervalMin ?? 1)))

    property bool barCycleEnabled: pluginSettings?.barCycleEnabled ?? false
    property int barCycleIntervalSec: pluginSettings?.barCycleIntervalSec ?? 5
    property bool barShowRemaining: pluginSettings?.barShowRemaining ?? false
    property bool barTextShowOnHover: pluginSettings?.barTextShowOnHover ?? false
    property bool barIconAlertOnLimit: pluginSettings?.barIconAlertOnLimit ?? false
    property int barIconAlertThreshold: Math.max(50, Math.min(100, Number(pluginSettings?.barIconAlertThreshold ?? 95)))
    property string barIconAlertWindow: String(pluginSettings?.barIconAlertWindow ?? "usage7d") === "usage5h" ? "usage5h" : "usage7d"
    property int refreshIntervalSec: pluginSettings?.refreshIntervalSec ?? 30

    property string barMetric: String(pluginSettings?.barMetric ?? "prompts").trim()

    Timer {
        interval: root.barCycleIntervalSec * 1000
        running: root.barCycleEnabled && root.barProviders.length > 1
        repeat: true
        onTriggered: {
            root.activeIndex = (root.activeIndex + 1) % root.barProviders.length;
        }
    }

    Timer {
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refreshAll()
    }

    onBarProvidersChanged: {
        if (barProviders.length === 0) {
            activeIndex = 0;
        } else if (activeIndex >= barProviders.length) {
            activeIndex = 0;
        }
    }

    onProviderSortRevisionChanged: activeIndex = 0
    onProviderOrderModeChanged: activeIndex = 0

    function normalizedProviderOrder(savedOrder) {
        const result = [];
        const seen = {};
        const source = Array.isArray(savedOrder) ? savedOrder : [];

        for (const rawId of source) {
            const id = String(rawId || "");
            if (root.defaultProviderOrder.indexOf(id) !== -1 && !seen[id]) {
                result.push(id);
                seen[id] = true;
            }
        }

        for (const id of root.defaultProviderOrder) {
            if (!seen[id])
                result.push(id);
        }

        return result;
    }

    function trackProvider7dUsageChange(providerId, rawPercent) {
        const id = String(providerId || "");
        if (id === "" || !(rawPercent >= 0))
            return;

        const roundedPercent = Math.round(Number(rawPercent) * 100);
        const seen = Object.assign({}, root.lastSeen7dPercentByProvider);
        const changed = Object.assign({}, root.lastChanged7dOrderByProvider);
        const previous = seen[id];

        seen[id] = roundedPercent;
        root.lastSeen7dPercentByProvider = seen;

        if (previous === undefined || previous === roundedPercent)
            return;

        root.providerChangeSequence += 1;
        changed[id] = root.providerChangeSequence;
        root.lastChanged7dOrderByProvider = changed;
        root.providerSortRevision += 1;
    }

    function providerEnabled(id) {
        return pluginSettings?.providers?.[id]?.enabled ?? false;
    }

    function refresh() {
        refreshAll();
    }

    property string lastRefreshTime: ""

    function refreshAll() {
        root.refreshTimestamp();
        for (const p of providers) {
            if (p.providerEnabled)
                p.refresh();
        }
    }

    function refreshTimestamp() {
        const d = new Date();
        const h = String(d.getHours()).padStart(2, "0");
        const m = String(d.getMinutes()).padStart(2, "0");
        root.lastRefreshTime = h + ":" + m;
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
