import QtQuick
import Quickshell
import "../components"

Item {
    id: root
    visible: false

    property string providerId: "zai"
    property string providerName: "Z.ai"
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/zai.svg"
    property bool providerEnabled: false
    property bool ready: false

    property real rateLimitPercent: -1
    property string rateLimitLabel: "Tokens"
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
    property string authHelpText: "Set Z_AI_API_KEY in your environment."
    property string usageStatusText: ""
    property bool hasLocalStats: false

    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "zai"
    property int apiRefreshIntervalMin: 1

    readonly property string apiKey: {
        const envKey = Quickshell.env("Z_AI_API_KEY") ?? "";
        return envKey || (providerSettings?.apiKey ?? "");
    }

    readonly property string quotaUrl: {
        const override = Quickshell.env("Z_AI_QUOTA_URL") ?? "";
        if (override)
            return override;
        const host = Quickshell.env("Z_AI_API_HOST") ?? "https://api.z.ai";
        return host + "/api/monitor/usage/quota/limit";
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

    ApiRefreshTimer {
        providerEnabled: root.providerEnabled && !root.useCodexbar && root.apiKey !== ""
        intervalMin: root.apiRefreshIntervalMin
        onTick: root.fetchQuota()
    }

    onProviderEnabledChanged: {
        if (providerEnabled) {
            if (root.useCodexbar)
                codexbarFetcher.fetch();
            else if (apiKey !== "")
                fetchQuota();
        }
    }

    onApiKeyChanged: {
        if (providerEnabled && !root.useCodexbar && apiKey !== "")
            fetchQuota();
    }

    function fetchQuota() {
        if (!root.apiKey) {
            root.usageStatusText = "No API key found. " + root.authHelpText;
            return;
        }

        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.quotaUrl);
        xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey);

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                Logger.e("model-usage/zai", "Quota request failed (status " + xhr.status + ")");
                if (xhr.status === 401 || xhr.status === 403)
                    root.usageStatusText = "Authentication failed. " + root.authHelpText;
                return;
            }

            try {
                const resp = JSON.parse(xhr.responseText);
                root.parseQuota(resp);
                root.usageStatusText = "";
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/zai", "Failed to parse quota response: " + e);
            }
        };

        xhr.send();
    }

    function epochMsToIso(epochMs) {
        if (!epochMs)
            return "";
        return new Date(Number(epochMs)).toISOString();
    }

    function limitPercent(used, remaining) {
        const total = Number(used ?? 0) + Number(remaining ?? 0);
        if (total <= 0)
            return -1;
        return Math.min(1, Math.max(0, Number(used ?? 0) / total));
    }

    function parseQuota(resp) {
        const data = resp.data ?? resp;
        const limits = Array.isArray(data?.limits) ? data.limits : [];

        root.tierLabel = data?.planName ? String(data.planName) : "";

        let primary = null;
        let secondary = null;

        for (const limit of limits) {
            const type = String(limit.limitType ?? "").toUpperCase();
            if (type === "TOKENS_LIMIT" && !primary)
                primary = limit;
            else if (type === "TIME_LIMIT" && !secondary)
                secondary = limit;
            else if (!secondary)
                secondary = limit;
        }

        if (primary) {
            root.rateLimitPercent = root.limitPercent(primary.used, primary.remaining);
            const usedFmt = root.formatAmount(primary.used);
            const totalFmt = root.formatAmount(Number(primary.used ?? 0) + Number(primary.remaining ?? 0));
            root.rateLimitLabel = "Tokens (" + usedFmt + " / " + totalFmt + ")";
            root.rateLimitResetAt = root.epochMsToIso(primary.resetTime);
        } else {
            root.rateLimitPercent = -1;
            root.rateLimitLabel = "Tokens";
            root.rateLimitResetAt = "";
        }

        if (secondary) {
            root.secondaryRateLimitPercent = root.limitPercent(secondary.used, secondary.remaining);
            const type = String(secondary.limitType ?? "").toUpperCase();
            root.secondaryRateLimitLabel = type === "TIME_LIMIT" ? "Time window" : "Window";
            root.secondaryRateLimitResetAt = root.epochMsToIso(secondary.resetTime);
        } else {
            root.secondaryRateLimitPercent = -1;
            root.secondaryRateLimitLabel = "";
            root.secondaryRateLimitResetAt = "";
        }
    }

    function formatAmount(n) {
        const num = Number(n ?? 0);
        if (num >= 1e9)
            return (num / 1e9).toFixed(1) + "B";
        if (num >= 1e6)
            return (num / 1e6).toFixed(1) + "M";
        if (num >= 1e3)
            return (num / 1e3).toFixed(1) + "K";
        return String(Math.round(num));
    }


    function applyCodexbarData(result) {
        const usage = result?.usage ?? null;
        const primary = usage?.primary ?? null;
        const secondary = usage?.secondary ?? null;
        const identity = usage?.identity ?? null;
        const credits = result?.credits ?? null;

        if (primary) {
            root.rateLimitPercent = Math.min(1, Math.max(0, Number(primary.usedPercent ?? 0) / 100));
            root.rateLimitLabel = primary.resetDescription ?? "Usage";
            root.rateLimitResetAt = primary.resetsAt ?? "";
        } else {
            root.rateLimitPercent = -1;
            root.rateLimitLabel = "";
            root.rateLimitResetAt = "";
        }

        if (secondary) {
            root.secondaryRateLimitPercent = Math.min(1, Math.max(0, Number(secondary.usedPercent ?? 0) / 100));
            root.secondaryRateLimitLabel = secondary.resetDescription ?? "Secondary";
            root.secondaryRateLimitResetAt = secondary.resetsAt ?? "";
        } else {
            root.secondaryRateLimitPercent = -1;
            root.secondaryRateLimitLabel = "";
            root.secondaryRateLimitResetAt = "";
        }

        if (credits && Number(credits.total ?? 0) > 0) {
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

    function refresh() {
        if (root.useCodexbar) {
            codexbarFetcher.fetch();
            return;
        }

        if (root.apiKey !== "")
            fetchQuota();
    }
}
