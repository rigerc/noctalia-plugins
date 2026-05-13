import QtQuick
import Quickshell
import "../components"

Item {
    id: root
    visible: false

    property var pluginApi: null

    function tr(key, vars) {
        return root.pluginApi?.tr(key, vars);
    }

    property string providerId: "zen"
    property string providerName: root.tr("providers.names.zen")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/opencode.svg"
    property bool providerEnabled: false
    property bool ready: false
    property int pendingRefreshRequests: 0
    readonly property bool refreshing: codexbarFetcher.running || root.pendingRefreshRequests > 0

    property real rateLimitPercent: -1
    property string rateLimitLabel: ""
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: ""
    property string secondaryRateLimitResetAt: ""

    property int todayPrompts: 0
    property int todaySessions: 0
    property int todayTotalTokens: 0
    property var todayTokensByModel: ({})

    property var recentDays: []
    property int totalPrompts: 0
    property int totalSessions: 0
    property var modelUsage: ({})

    property string tierLabel: ""
    property string authHelpText: root.tr("providers.help.zen")
    property string usageStatusText: ""
    property bool hasLocalStats: true

    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "opencode"
    property var utils: ProviderUtils {}

    CodexbarFetcher {
        id: codexbarFetcher
        codexbarProvider: root.codexbarProviderName
        onDataReady: result => root.applyCodexbarData(result)
        onFetchError: msg => {
            root.usageStatusText = msg;
            root.ready = false;
            Logger.e("model-usage/" + root.providerId, "codexbar error: " + msg);
        }
    }

    property string apiBaseUrl: providerSettings?.apiBaseUrl ?? "https://opencode.ai/zen/v1"
    property string apiKey: {
        const envZen = Quickshell.env("OPENCODE_ZEN_API_KEY") ?? "";
        if (envZen !== "")
            return envZen;
        const envOpenCode = Quickshell.env("OPENCODE_API_KEY") ?? "";
        if (envOpenCode !== "")
            return envOpenCode;
        const envLegacy = Quickshell.env("ZEN_API_KEY") ?? "";
        if (envLegacy !== "")
            return envLegacy;
        return providerSettings?.apiKey ?? "";
    }

    property string validatedApiKey: ""
    property string authState: "unknown"
    property bool modelsLoaded: false
    property int availableModels: 0
    property string defaultModel: ""

    property int refreshIntervalSec: 30
    property double lastApiRefreshAtMs: 0

    onProviderEnabledChanged: {
        if (providerEnabled)
            refresh();
    }

    onApiKeyChanged: {
        if (root.useCodexbar)
            return;
        root.validatedApiKey = "";
        root.authState = apiKey === "" ? "unknown" : "checking";
        root.updateState();
        if (providerEnabled)
            refresh();
    }

    function updateState() {
        const hasKey = root.apiKey !== "";

        if (!hasKey) {
            root.tierLabel = root.tr("providers.tiers.apiKeyRequired");
            root.ready = false;
        } else if (root.authState === "invalid") {
            root.tierLabel = root.tr("providers.tiers.invalidApiKey");
            root.ready = false;
        } else if (root.authState === "valid") {
            root.tierLabel = root.tr("providers.tiers.apiKeyValid");
            root.ready = root.modelsLoaded;
        } else {
            root.tierLabel = root.tr("providers.tiers.checkingApiKey");
            root.ready = root.modelsLoaded;
        }

        root.rateLimitPercent = -1;
        root.rateLimitLabel = "Usage API unavailable";
        root.rateLimitResetAt = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "";
        root.secondaryRateLimitResetAt = "";
    }

    function extractErrorMessage(text) {
        if (!text)
            return "";
        try {
            const parsed = JSON.parse(text);
            return parsed?.error?.message ?? parsed?.message ?? "";
        } catch (e) {
            return "";
        }
    }

    function validateApiKey() {
        if (!root.apiKey)
            return;

        root.pendingRefreshRequests += 1;
        const xhr = new XMLHttpRequest();
        xhr.open("POST", root.apiBaseUrl + "/responses");
        xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.pendingRefreshRequests = Math.max(0, root.pendingRefreshRequests - 1);
            root.validatedApiKey = root.apiKey;

            if (xhr.status === 401 || xhr.status === 403) {
                const msg = root.extractErrorMessage(xhr.responseText);
                const msgLower = String(msg).toLowerCase();
                if (msgLower.indexOf("invalid api key") !== -1) {
                    Logger.e("model-usage/zen", "API key rejected (status " + xhr.status + "): " + msg);
                    root.authState = "invalid";
                } else {
                    Logger.e("model-usage/zen", "API key probe unauthorized (status " + xhr.status + ")" + (msg ? ": " + msg : ""));
                    root.authState = "unknown";
                }
            } else if (xhr.status >= 200 && xhr.status < 500) {
                root.authState = "valid";
            } else {
                Logger.e("model-usage/zen", "API key probe failed (status " + xhr.status + ")");
                root.authState = "unknown";
            }

            root.updateState();
        };

        xhr.send(JSON.stringify({
            model: "glm-5-free",
            input: "hi",
            max_output_tokens: 1
        }));
    }

    function fetchModels() {
        root.pendingRefreshRequests += 1;
        root.lastApiRefreshAtMs = Date.now();
        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiBaseUrl + "/models");
        if (root.apiKey)
            xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey);

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.pendingRefreshRequests = Math.max(0, root.pendingRefreshRequests - 1);

            if (xhr.status !== 200) {
                root.modelsLoaded = false;
                root.availableModels = 0;
                root.defaultModel = "";
                Logger.e("model-usage/zen", "Models request failed (status " + xhr.status + ")");
                root.updateState();
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const models = data?.data ?? [];
                root.availableModels = models.length;
                root.defaultModel = models.length > 0 ? (models[0]?.id ?? "") : "";
                root.modelsLoaded = models.length > 0;
                root.ready = root.modelsLoaded;
                root.updateState();
            } catch (e) {
                root.modelsLoaded = false;
                root.availableModels = 0;
                root.defaultModel = "";
                Logger.e("model-usage/zen", "Failed to parse models response:", e);
                root.updateState();
            }
        };

        xhr.send();
    }


    function applyCodexbarData(result) {
        const usage = result?.usage ?? null;
        const primary = usage?.primary ?? null;
        const secondary = usage?.secondary ?? null;
        const identity = usage?.identity ?? null;
        const credits = result?.credits ?? null;

        if (secondary) {
            root.rateLimitPercent = Math.min(1, Math.max(0, Number(secondary.usedPercent ?? 0) / 100));
            root.rateLimitLabel = utils.windowMinutesToLabel(secondary.windowMinutes) || "7d";
            root.rateLimitResetAt = secondary.resetsAt ?? "";
        } else {
            root.rateLimitPercent = -1;
            root.rateLimitLabel = "";
            root.rateLimitResetAt = "";
        }

        if (primary) {
            root.secondaryRateLimitPercent = Math.min(1, Math.max(0, Number(primary.usedPercent ?? 0) / 100));
            root.secondaryRateLimitLabel = utils.windowMinutesToLabel(primary.windowMinutes) || "5h";
            root.secondaryRateLimitResetAt = primary.resetsAt ?? "";
        } else {
            root.secondaryRateLimitPercent = -1;
            root.secondaryRateLimitLabel = "";
            root.secondaryRateLimitResetAt = "";
        }

        if (!secondary && credits && Number(credits.total ?? 0) > 0) {
            const used = Number(credits.used ?? 0);
            const total = Number(credits.total ?? 0);
            root.rateLimitPercent = Math.min(1, Math.max(0, used / total));
            root.rateLimitLabel = "Credits ($" + used.toFixed(2) + " / $" + total.toFixed(2) + ")";
            root.rateLimitResetAt = "";
        }

        root.tierLabel = identity?.loginMethod ?? root.tierLabel;
        root.usageStatusText = "";
        root.ready = true;
    }

    function shouldRefreshApi(force) {
        if (force || root.lastApiRefreshAtMs <= 0)
            return true;
        return (Date.now() - root.lastApiRefreshAtMs) >= Math.max(5, root.refreshIntervalSec) * 1000;
    }

    function refresh(force) {
        if (root.useCodexbar) {
            codexbarFetcher.fetch();
            return;
        }

        if (root.shouldRefreshApi(force === true))
            fetchModels();
        if (root.apiKey && (root.validatedApiKey !== root.apiKey || root.authState === "unknown" || root.authState === "checking"))
            validateApiKey();
        else
            updateState();
    }

}
