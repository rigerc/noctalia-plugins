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

    property string providerId: "openrouter"
    property string providerName: root.tr("providers.names.openrouter")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/openrouter.svg"
    property bool providerEnabled: false
    property bool ready: false

    property real rateLimitPercent: -1
    property string rateLimitLabel: root.tr("providers.rateLimits.spendingLimit")
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
    property string authHelpText: root.tr("providers.help.openrouter")
    property bool hasLocalStats: true

    property real usageDaily: 0
    property real usageWeekly: 0
    property real usageMonthly: 0
    property real spendingLimit: -1
    property real limitRemaining: -1
    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "openrouter"

    property string apiKey: {
        const envKey = Quickshell.env("OPENROUTER_API_KEY") ?? "";
        return envKey || (providerSettings?.apiKey ?? "");
    }

    property int apiRefreshIntervalMin: 1

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


    ApiRefreshTimer {
        providerEnabled: root.providerEnabled && !root.useCodexbar && root.apiKey !== ""
        intervalMin: root.apiRefreshIntervalMin
        onTick: root.fetchKeyInfo()
    }

    onProviderEnabledChanged: {
        if (providerEnabled) {
            if (root.useCodexbar)
                codexbarFetcher.fetch();
            else if (apiKey !== "")
                fetchKeyInfo();
        }
    }

    onApiKeyChanged: {
        if (providerEnabled && !root.useCodexbar && apiKey !== "")
            fetchKeyInfo();
    }

    function fetchKeyInfo() {
        if (!root.apiKey)
            return;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://openrouter.ai/api/v1/key");
        xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey);

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                Logger.e("model-usage/openrouter", "Key info request failed (status " + xhr.status + ")");
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                const info = data.data ?? data;

                root.usageDaily = root.parseFinite(info.usage_daily, 0);
                root.usageWeekly = root.parseFinite(info.usage_weekly, 0);
                root.usageMonthly = root.parseFinite(info.usage_monthly, 0);
                root.spendingLimit = root.parseFinite(info.limit, -1);
                root.limitRemaining = root.parseFinite(info.limit_remaining, -1);
                root.rateLimitResetAt = root.utils.normalizeResetAt(info.limit_reset);

                if (root.spendingLimit > 0) {
                    root.rateLimitPercent = Math.min(1, Math.max(0, root.usageWeekly / root.spendingLimit));
                    root.rateLimitLabel = "Spending ($" + root.usageWeekly.toFixed(2) + " / $" + root.spendingLimit.toFixed(2) + ")";
                } else if (root.limitRemaining >= 0 && (root.usageWeekly + root.limitRemaining) > 0) {
                    const budget = root.usageWeekly + root.limitRemaining;
                    root.rateLimitPercent = Math.min(1, Math.max(0, root.usageWeekly / budget));
                    root.rateLimitLabel = "Budget ($" + root.usageWeekly.toFixed(2) + " / $" + budget.toFixed(2) + ")";
                } else {
                    root.rateLimitPercent = -1;
                    root.rateLimitLabel = "No spending limit";
                }

                root.tierLabel = info.is_free_tier ? "Free" : "Paid";
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/openrouter", "Failed to parse key info:", e);
            }
        };

        xhr.send();
        fetchActivity();
    }

    function parseFinite(value, fallback) {
        if (value === null || value === undefined)
            return fallback;
        const n = Number(value);
        return isFinite(n) ? n : fallback;
    }


    function fetchActivity() {
        if (!root.apiKey)
            return;

        const today = new Date();
        const days = [];
        for (let i = 6; i >= 0; i--) {
            const d = new Date(today);
            d.setDate(d.getDate() - i);
            const y = d.getFullYear();
            const m = String(d.getMonth() + 1).padStart(2, "0");
            const dd = String(d.getDate()).padStart(2, "0");
            days.push(y + "-" + m + "-" + dd);
        }

        let completed = 0;
        const results = {};

        for (let i = 0; i < days.length; i++) {
            const date = days[i];
            const xhr = new XMLHttpRequest();
            xhr.open("GET", "https://openrouter.ai/api/v1/activity?date=" + date);
            xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey);

            xhr.onreadystatechange = function () {
                if (xhr.readyState !== XMLHttpRequest.DONE)
                    return;

                if (xhr.status === 200) {
                    try {
                        const data = JSON.parse(xhr.responseText);
                        const entries = data.data ?? [];
                        let dayRequests = 0;
                        let dayTokens = 0;

                        for (const entry of entries) {
                            dayRequests += entry.requests ?? 0;
                            dayTokens += (entry.prompt_tokens ?? 0) + (entry.completion_tokens ?? 0);
                        }

                        results[date] = {
                            requests: dayRequests,
                            tokens: dayTokens,
                            entries: entries
                        };
                    } catch (e) {
                        results[date] = {
                            requests: 0,
                            tokens: 0,
                            entries: []
                        };
                    }
                } else {
                    results[date] = {
                        requests: 0,
                        tokens: 0,
                        entries: []
                    };
                }

                completed++;
                if (completed === days.length)
                    root.processActivityResults(days, results);
            };

            xhr.send();
        }
    }

    function processActivityResults(days, results) {
        const recentDays = [];
        let totalTokens = 0;
        const models = {};

        for (const date of days) {
            const r = results[date] ?? {
                requests: 0,
                tokens: 0,
                entries: []
            };
            recentDays.push({
                date: date,
                messageCount: r.requests
            });
            totalTokens += r.tokens;

            for (const entry of (r.entries ?? [])) {
                const model = entry.model ?? "unknown";
                if (!models[model]) {
                    models[model] = {
                        inputTokens: 0,
                        outputTokens: 0,
                        cacheReadInputTokens: 0,
                        cacheCreationInputTokens: 0
                    };
                }
                models[model].inputTokens += entry.prompt_tokens ?? 0;
                models[model].outputTokens += entry.completion_tokens ?? 0;
            }
        }

        root.recentDays = recentDays;
        root.modelUsage = models;

        const todayStr = days[days.length - 1];
        const todayData = results[todayStr] ?? {
            requests: 0,
            tokens: 0
        };
        root.todayPrompts = todayData.requests;
        root.todayTotalTokens = todayData.tokens;

        const todayByModel = {};
        for (const entry of (todayData.entries ?? [])) {
            const model = entry.model ?? "unknown";
            todayByModel[model] = (todayByModel[model] ?? 0) + (entry.prompt_tokens ?? 0) + (entry.completion_tokens ?? 0);
        }
        root.todayTokensByModel = todayByModel;
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
            fetchKeyInfo();
    }

}
