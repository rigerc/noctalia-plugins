import QtQuick
import "components"
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
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    Codex {
        id: codexProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("codex")
        providerSettings: root.pluginSettings?.providers?.codex ?? ({})
        includeCacheTokens: root.pluginSettings?.includeCacheTokens ?? true
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    OpenRouter {
        id: openRouterProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("openrouter")
        providerSettings: root.pluginSettings?.providers?.openrouter ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    Copilot {
        id: copilotProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("copilot")
        providerSettings: root.pluginSettings?.providers?.copilot ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    Zen {
        id: zenProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("zen")
        providerSettings: root.pluginSettings?.providers?.zen ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    DeepSeek {
        id: deepseekProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("deepseek")
        providerSettings: root.pluginSettings?.providers?.deepseek ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    KiloCode {
        id: kiloCodeProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("kilocode")
        providerSettings: root.pluginSettings?.providers?.kilocode ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    Zai {
        id: zaiProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("zai")
        providerSettings: root.pluginSettings?.providers?.zai ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    Gemini {
        id: geminiProvider
        pluginApi: root.pluginApi
        providerEnabled: root.providerEnabled("gemini")
        providerSettings: root.pluginSettings?.providers?.gemini ?? ({})
        refreshIntervalSec: root.networkRefreshIntervalSec
        onRateLimitPercentChanged: root.trackProviderUsageChange("usage7d", providerId, rateLimitPercent)
        onSecondaryRateLimitPercentChanged: root.trackProviderUsageChange("usage5h", providerId, secondaryRateLimitPercent)
    }

    readonly property var providerCatalog: ProviderCatalog {}
    readonly property var defaultProviderOrder: providerCatalog.defaultProviderOrder
    property var providers: [claudeProvider, codexProvider, copilotProvider, openRouterProvider, zenProvider, deepseekProvider, kiloCodeProvider, zaiProvider, geminiProvider]
    property bool refreshPulseActive: false
    readonly property bool refreshing: {
        if (root.refreshPulseActive)
            return true;
        for (const p of root.providers) {
            if (p.providerEnabled && (p.refreshing ?? false))
                return true;
        }
        return false;
    }

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
    readonly property var persistedRecentChangeState: pluginSettings?._recentChangeState ?? ({})
    property var lastSeenPercentByWindow: persistedRecentChangeState?.lastSeenPercentByWindow ?? ({})
    property var lastChangedOrderByWindow: persistedRecentChangeState?.lastChangedOrderByWindow ?? ({})
    property int providerChangeSequence: Number(persistedRecentChangeState?.providerChangeSequence ?? 0)
    property int providerSortRevision: 0
    property int recentChangeWidgetProviderLimit: Math.max(1, Math.min(root.defaultProviderOrder.length,
        Number(pluginSettings?.recentChangeWidgetProviderLimit ?? root.defaultProviderOrder.length)))

    property var manualProviderOrder: root.normalizedProviderOrder(pluginSettings?.providerOrder)

    property var enabledProviders: {
        const result = [];
        for (const id of root.manualProviderOrder) {
            const p = root.providerMap[id];
            if (p && p.providerEnabled)
                result.push(p);
        }
        return result;
    }

    property var barProviderOrder: {
        root.providerSortRevision;
        const order = root.manualProviderOrder.slice();
        const usageWindow = root.recentChangeUsageWindow();
        if (usageWindow === "")
            return order;

        const changedOrder = root.lastChangedOrderByWindow[usageWindow] ?? {};
        const manualIndex = {};
        for (let i = 0; i < order.length; i++)
            manualIndex[order[i]] = i;

        return order.sort((a, b) => {
            const aChanged = changedOrder[a] ?? 0;
            const bChanged = changedOrder[b] ?? 0;
            if (aChanged !== bChanged)
                return bChanged - aChanged;
            return (manualIndex[a] ?? 999) - (manualIndex[b] ?? 999);
        });
    }

    // Bar-only filtered subset (respects showInWidget and recent-change ordering)
    property var barProviders: {
        const result = [];
        for (const id of root.barProviderOrder) {
            const p = root.providerMap[id];
            const ps = pluginSettings?.providers?.[id] ?? {};
            if (p && p.providerEnabled && ps.showInWidget !== false)
                result.push(p);
        }
        if (root.recentChangeUsageWindow() !== "")
            return result.slice(0, root.recentChangeWidgetProviderLimit);
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

    property bool barCycleEnabled: pluginSettings?.barCycleEnabled ?? false
    property int barCycleIntervalSec: pluginSettings?.barCycleIntervalSec ?? 5
    property bool barShowRemaining: pluginSettings?.barShowRemaining ?? false
    property bool barTextShowOnHover: pluginSettings?.barTextShowOnHover ?? false
    property bool barIconAlertOnLimit: pluginSettings?.barIconAlertOnLimit ?? false
    property int barIconAlertThreshold: Math.max(50, Math.min(100, Number(pluginSettings?.barIconAlertThreshold ?? 95)))
    property string barIconAlertWindow: String(pluginSettings?.barIconAlertWindow ?? "usage7d") === "usage5h" ? "usage5h" : "usage7d"
    property int refreshIntervalSec: Math.max(5, Math.min(86400, Number(pluginSettings?.refreshIntervalSec ?? 30)))
    readonly property int networkRefreshIntervalSec: root.refreshIntervalSec
    property double currentTimeMs: Date.now()
    property double nextRefreshAtMs: 0
    readonly property int nextRefreshRemainingSec: Math.max(0, Math.ceil((root.nextRefreshAtMs - root.currentTimeMs) / 1000))

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
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTimeMs = Date.now()
    }

    Timer {
        id: initialRefreshTimer
        interval: 1
        repeat: false
        onTriggered: root.refreshAll(true)
    }

    Timer {
        id: periodicRefreshTimer
        interval: root.refreshIntervalSec * 1000
        running: true
        repeat: true
        onTriggered: {
            root.refreshAll(false);
            root.scheduleNextRefresh();
        }
    }

    Timer {
        id: persistRecentChangeStateTimer
        interval: 5000
        repeat: false
        onTriggered: root.persistRecentChangeState()
    }

    Timer {
        id: refreshPulseTimer
        interval: 800
        repeat: false
        onTriggered: root.refreshPulseActive = false
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

    onRefreshIntervalSecChanged: {
        periodicRefreshTimer.restart();
        root.scheduleNextRefresh();
    }

    Component.onCompleted: {
        root.scheduleNextRefresh();
        initialRefreshTimer.start();
    }

    function normalizedProviderOrder(savedOrder) {
        return root.providerCatalog.normalizeProviderOrder(savedOrder);
    }

    function recentChangeUsageWindow() {
        if (root.providerOrderMode === "recent7dChange")
            return "usage7d";
        if (root.providerOrderMode === "recent5hChange")
            return "usage5h";
        return "";
    }

    function trackProviderUsageChange(usageWindow, providerId, rawPercent) {
        const id = String(providerId || "");
        if (id === "" || !(rawPercent >= 0))
            return;

        const roundedPercent = Math.round(Number(rawPercent) * 100);
        const seenByWindow = Object.assign({}, root.lastSeenPercentByWindow);
        const changedByWindow = Object.assign({}, root.lastChangedOrderByWindow);
        const seen = Object.assign({}, seenByWindow[usageWindow] ?? ({}));
        const changed = Object.assign({}, changedByWindow[usageWindow] ?? ({}));
        const previous = seen[id];

        seen[id] = roundedPercent;
        seenByWindow[usageWindow] = seen;
        root.lastSeenPercentByWindow = seenByWindow;

        if (previous === undefined) {
            root.schedulePersistRecentChangeState();
            return;
        }
        if (previous === roundedPercent)
            return;

        root.providerChangeSequence += 1;
        changed[id] = root.providerChangeSequence;
        changedByWindow[usageWindow] = changed;
        root.lastChangedOrderByWindow = changedByWindow;
        root.providerSortRevision += 1;
        root.schedulePersistRecentChangeState();
    }

    function schedulePersistRecentChangeState() {
        if (root.pluginApi)
            persistRecentChangeStateTimer.restart();
    }

    function persistRecentChangeState() {
        if (!root.pluginApi)
            return;
        if (!root.pluginApi.pluginSettings)
            root.pluginApi.pluginSettings = {};
        root.pluginApi.pluginSettings._recentChangeState = {
            "lastSeenPercentByWindow": root.lastSeenPercentByWindow,
            "lastChangedOrderByWindow": root.lastChangedOrderByWindow,
            "providerChangeSequence": root.providerChangeSequence
        };
        root.pluginApi.saveSettings();
    }

    function providerEnabled(id) {
        return pluginSettings?.providers?.[id]?.enabled ?? false;
    }

    function refresh() {
        refreshAll(true);
        periodicRefreshTimer.restart();
        root.scheduleNextRefresh();
    }

    function scheduleNextRefresh() {
        root.currentTimeMs = Date.now();
        root.nextRefreshAtMs = root.currentTimeMs + Math.max(1, root.refreshIntervalSec) * 1000;
    }

    property string lastRefreshTime: ""

    function refreshAll(forceApiRefresh) {
        root.refreshPulseActive = true;
        refreshPulseTimer.restart();
        root.refreshTimestamp();
        for (const p of providers) {
            if (p.providerEnabled)
                p.refresh(forceApiRefresh === true);
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
