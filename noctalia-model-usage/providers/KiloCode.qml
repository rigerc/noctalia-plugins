import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Item {
    id: root
    visible: false

    property var pluginApi: null

    function tr(key, vars) {
        return root.pluginApi?.tr(key, vars);
    }

    property string providerId: "kilocode"
    property string providerName: root.tr("providers.names.kilocode")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/kilocode.svg"
    property bool providerEnabled: false
    property bool ready: false
    property int pendingRefreshRequests: 0
    readonly property bool refreshing: codexbarFetcher.running || root.pendingRefreshRequests > 0

    property real rateLimitPercent: -1
    property string rateLimitLabel: root.tr("providers.rateLimits.credits")
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
    property string authHelpText: root.tr("providers.help.kilocode")
    property string usageStatusText: ""
    property bool hasLocalStats: false

    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "kilo"
    property var utils: ProviderUtils {}
    property int apiRefreshIntervalMin: 1
    property double lastApiRefreshAtMs: 0

    property string _accessToken: ""

    readonly property string apiKey: {
        const envKey = Quickshell.env("KILO_API_KEY") ?? "";
        return envKey || (providerSettings?.apiKey ?? "");
    }



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

    FileView {
        id: authFile
        path: (Quickshell.env("HOME") ?? "/home") + "/.local/share/kilo/auth.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root._accessToken = data.accessToken ?? data.access_token ?? "";
                if (root._accessToken && root.providerEnabled && !root.useCodexbar)
                    root.fetchUsage();
            } catch (e) {
                Logger.d("model-usage/kilocode", "Failed to parse auth.json: " + e);
            }
        }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                Logger.d("model-usage/kilocode", "auth.json load failed: " + error);
        }
    }

    readonly property string effectiveToken: root.apiKey || root._accessToken

    ApiRefreshTimer {
        providerEnabled: root.providerEnabled && !root.useCodexbar && root.effectiveToken !== ""
        intervalMin: root.apiRefreshIntervalMin
        onTick: root.fetchUsage()
    }

    onProviderEnabledChanged: {
        if (providerEnabled) {
            if (root.useCodexbar)
                codexbarFetcher.fetch();
            else if (effectiveToken !== "")
                fetchUsage();
        }
    }

    onApiKeyChanged: {
        if (providerEnabled && !root.useCodexbar && apiKey !== "")
            fetchUsage();
    }

    function fetchUsage() {
        const token = root.effectiveToken;
        if (!token) {
            root.usageStatusText = root.tr("providers.status.noApiKeyFound", { "help": root.authHelpText });
            return;
        }

        root.pendingRefreshRequests += 1;
        root.lastApiRefreshAtMs = Date.now();
        const input = encodeURIComponent(JSON.stringify({ "0": {}, "1": {} }));
        const url = "https://app.kilo.ai/api/trpc/user.getCreditBlocks,kiloPass.getState?batch=1&input=" + input;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.setRequestHeader("Authorization", "Bearer " + token);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            root.pendingRefreshRequests = Math.max(0, root.pendingRefreshRequests - 1);
            if (xhr.status !== 200) {
                Logger.e("model-usage/kilocode", "tRPC request failed (status " + xhr.status + ")");
                if (xhr.status === 401 || xhr.status === 403)
                    root.usageStatusText = root.tr("providers.status.authenticationFailed", { "help": root.authHelpText });
                return;
            }

            try {
                const results = JSON.parse(xhr.responseText);
                root.parseCreditBlocks(results[0]?.result?.data ?? []);
                root.parseKiloPassState(results[1]?.result?.data ?? null);
                root.usageStatusText = "";
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/kilocode", "Failed to parse tRPC response: " + e);
            }
        };

        xhr.send();
    }

    function normalizeCurrency(value, currency) {
        const n = Number(value);
        if (!isFinite(n))
            return 0;
        const cur = String(currency ?? "").toUpperCase();
        if (cur === "CENTS")
            return n / 100;
        if (cur === "MILLI_USD")
            return n / 1000;
        return n;
    }

    function parseCreditBlocks(blocks) {
        if (!Array.isArray(blocks) || blocks.length === 0) {
            root.rateLimitPercent = -1;
            root.rateLimitLabel = "Credits";
            return;
        }

        let totalUsed = 0;
        let totalAmount = 0;

        for (const block of blocks) {
            const cur = block.currency ?? "";
            totalUsed += root.normalizeCurrency(block.used ?? 0, cur);
            totalAmount += root.normalizeCurrency(block.total ?? block.amount ?? 0, cur);
        }

        if (totalAmount > 0) {
            root.rateLimitPercent = Math.min(1, Math.max(0, totalUsed / totalAmount));
            root.rateLimitLabel = "Credits ($" + totalUsed.toFixed(2) + " / $" + totalAmount.toFixed(2) + ")";
        } else {
            root.rateLimitPercent = -1;
            root.rateLimitLabel = "Credits";
        }
    }

    function parseKiloPassState(state) {
        if (!state) {
            root.tierLabel = root.ready ? "Active" : "";
            return;
        }
        const plan = state.planName ?? state.name ?? state.tier ?? "";
        root.tierLabel = plan ? String(plan) : "Active";
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
        return (Date.now() - root.lastApiRefreshAtMs) >= root.apiRefreshIntervalMin * 60 * 1000;
    }

    function refresh(force) {
        if (root.useCodexbar) {
            codexbarFetcher.fetch();
            return;
        }

        if (root.effectiveToken !== "" && root.shouldRefreshApi(force === true))
            fetchUsage();
    }
}
