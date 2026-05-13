// qmllint disable unused-imports
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
// qmllint enable unused-imports
import "../components"

Item {
    id: root
    visible: false

    property var pluginApi: null

    function tr(key, vars) {
        return root.pluginApi?.tr(key, vars);
    }

    property string providerId: "copilot"
    property string providerName: root.tr("providers.names.copilot")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/copilot.svg"
    property bool providerEnabled: false
    property bool ready: false
    property int pendingRefreshRequests: 0
    readonly property bool refreshing: codexbarFetcher.running || tokenProcess.running || root.pendingRefreshRequests > 0

    property real rateLimitPercent: -1
    property string rateLimitLabel: root.tr("providers.rateLimits.premium")
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: root.tr("providers.rateLimits.chat")
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
    property string authHelpText: root.tr("providers.help.copilot")
    property bool hasLocalStats: false
    property string usageStatusText: ""

    property string ghToken: ""
    property double lastRefreshAtMs: 0
    property int refreshIntervalSec: 30
    readonly property int refreshMinIntervalMs: Math.max(5, root.refreshIntervalSec) * 1000
    property int tokenProcessTimeoutMs: 30000
    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "copilot"

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


    Process {
        id: tokenProcess
        command: ["gh", "auth", "token"]
        running: false
        stdout: StdioCollector {
            id: tokenOutput
            onStreamFinished: {
                const token = text.trim();
                if (token) {
                    root.ghToken = token;
                    root.fetchUsage();
                } else {
                    Logger.e("model-usage/copilot", "gh auth token returned empty");
                    root.usageStatusText = root.tr("providers.status.noToken");
                    root.ready = false;
                    root.clearRateLimits();
                }
            }
        }
        // qmllint disable signal-handler-parameters
        onExited: (code) => {
            tokenTimeoutTimer.stop();
            if (code !== 0) {
                Logger.e("model-usage/copilot", "gh auth token failed (exit " + code + ")");
                root.usageStatusText = root.tr("providers.status.notAuthenticated");
                root.ready = false;
                root.clearRateLimits();
            }
        }
    }

    Timer {
        id: tokenTimeoutTimer
        interval: root.tokenProcessTimeoutMs
        repeat: false
        onTriggered: {
            if (!tokenProcess.running)
                return;
            tokenProcess.running = false;
            Logger.e("model-usage/copilot", "gh auth token timed out");
            root.usageStatusText = root.tr("providers.status.notAuthenticated");
            root.ready = false;
            root.clearRateLimits();
        }
    }

    onProviderEnabledChanged: {
        if (providerEnabled) {
            if (root.useCodexbar)
                codexbarFetcher.fetch();
            else
                refreshToken();
        }
    }

    function refreshToken() {
        if (root.useCodexbar || tokenProcess.running)
            return;
        tokenProcess.running = true;
        tokenTimeoutTimer.restart();
    }

    function fetchUsage() {
        if (!root.ghToken)
            return;

        root.pendingRefreshRequests += 1;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://api.github.com/copilot_internal/user");
        xhr.setRequestHeader("Authorization", "token " + root.ghToken);
        xhr.setRequestHeader("Accept", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.pendingRefreshRequests = Math.max(0, root.pendingRefreshRequests - 1);

            if (xhr.status === 401 || xhr.status === 403) {
                root.usageStatusText = root.tr("providers.status.tokenInvalid");
                root.ready = false;
                root.ghToken = "";
                root.tierLabel = "";
                root.clearRateLimits();
                Logger.e("model-usage/copilot", "Auth failed (status " + xhr.status + ")");
                return;
            }

            if (xhr.status < 200 || xhr.status >= 300) {
                Logger.e("model-usage/copilot", "Usage request failed (status " + xhr.status + ")");
                root.ready = false;
                root.clearRateLimits();
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                root.parseUsageData(data);
                root.usageStatusText = "";
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/copilot", "Failed to parse usage response:", e);
            }
        };

        xhr.send();
    }

    function parseUsageData(data) {
        root.clearRateLimits();
        root.tierLabel = data.copilot_plan ? formatPlan(data.copilot_plan) : "";

        const resetDate = data.quota_reset_date ?? "";

        // Paid tier: quota_snapshots
        const snapshots = data.quota_snapshots;
        if (snapshots) {
            const premium = snapshots.premium_interactions;
            if (premium && typeof premium.percent_remaining === "number") {
                const usedPct = Math.min(100, Math.max(0, 100 - premium.percent_remaining));
                root.rateLimitPercent = usedPct / 100;
                root.rateLimitLabel = "Premium (" + Math.round(usedPct) + "%)";
                root.rateLimitResetAt = root.utils.normalizeResetAt(resetDate);
            }

            const chat = snapshots.chat;
            if (chat && typeof chat.percent_remaining === "number") {
                const chatUsed = Math.min(100, Math.max(0, 100 - chat.percent_remaining));
                root.secondaryRateLimitPercent = chatUsed / 100;
                root.secondaryRateLimitLabel = "Chat (" + Math.round(chatUsed) + "%)";
                root.secondaryRateLimitResetAt = root.utils.normalizeResetAt(resetDate);
            }
        }

        // Free tier: limited_user_quotas
        if (data.limited_user_quotas && data.monthly_quotas) {
            const lq = data.limited_user_quotas;
            const mq = data.monthly_quotas;
            const freeReset = data.limited_user_reset_date ?? "";

            if (typeof lq.chat === "number" && typeof mq.chat === "number" && mq.chat > 0) {
                const used = mq.chat - lq.chat;
                const usedPct = Math.min(100, Math.max(0, Math.round((used / mq.chat) * 100)));
                root.rateLimitPercent = usedPct / 100;
                root.rateLimitLabel = "Chat (" + used + "/" + mq.chat + ")";
                root.rateLimitResetAt = root.utils.normalizeResetAt(freeReset);
            }

            if (typeof lq.completions === "number" && typeof mq.completions === "number" && mq.completions > 0) {
                const used = mq.completions - lq.completions;
                const usedPct = Math.min(100, Math.max(0, Math.round((used / mq.completions) * 100)));
                root.secondaryRateLimitPercent = usedPct / 100;
                root.secondaryRateLimitLabel = "Completions (" + used + "/" + mq.completions + ")";
                root.secondaryRateLimitResetAt = root.utils.normalizeResetAt(freeReset);
            }
        }
    }

    function formatPlan(plan) {
        if (!plan)
            return "";
        const p = String(plan);
        return p.charAt(0).toUpperCase() + p.slice(1);
    }

    function clearRateLimits() {
        root.rateLimitPercent = -1;
        root.rateLimitLabel = "Premium";
        root.rateLimitResetAt = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "Chat";
        root.secondaryRateLimitResetAt = "";
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

    function refresh(force) {
        if (root.useCodexbar) {
            codexbarFetcher.fetch();
            return;
        }

        const now = Date.now();
        if (force !== true && root.lastRefreshAtMs > 0 && (now - root.lastRefreshAtMs) < root.refreshMinIntervalMs)
            return;
        root.lastRefreshAtMs = now;
        refreshToken();
    }

}
