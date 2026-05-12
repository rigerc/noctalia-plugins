import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../components"

Item {
    id: root
    visible: false

    property var pluginApi: null

    function tr(key, vars) {
        return root.pluginApi?.tr(key, vars);
    }

    property string providerId: "claude"
    property string providerName: root.tr("providers.names.claude")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/claude.svg"
    property bool providerEnabled: false
    property bool ready: false
    property string usageStatusText: ""

    property real rateLimitPercent: -1
    property string rateLimitLabel: root.tr("providers.rateLimits.weekly7d")
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: root.tr("providers.rateLimits.session5h")
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
    property string authHelpText: root.tr("providers.help.claude")
    property bool hasLocalStats: true

    property string oauthAccessToken: ""
    property double oauthExpiresAtMs: 0
    property string authMode: "none"
    property string subscriptionType: ""
    property string rateLimitTier: ""
    property bool hasAuthoritativeRateLimit: false

    property double lastProbeAtMs: 0
    property int probeMinIntervalMs: 5 * 60 * 1000

    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "claude"
    property bool includeCacheTokens: true

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


    function resolvePath(p) {
        if (p && p.startsWith("~"))
            return (Quickshell.env("HOME") ?? "/home") + p.substring(1);
        return p;
    }

    FileView {
        id: claudeJsonFile
        path: root.resolvePath("~/.claude.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseClaudeJson(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                Logger.d("model-usage/claude", "~/.claude.json not found — local stats unavailable");
        }
    }

    FileView {
        id: historyFile
        path: root.resolvePath("~/.claude/history.jsonl")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseHistory(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                Logger.d("model-usage/claude", "history.jsonl not found — prompt counts unavailable");
        }
    }

    Timer {
        id: waitingForAuthTimer
        interval: 2000
        repeat: false
        onTriggered: {
            if (!root.ready)
                root.usageStatusText = root.tr("providers.status.waitingAuth");
        }
    }

    FileView {
        id: credentialsFile
        path: root.resolvePath(root.providerSettings?.credentialsPath ?? "~/.claude/.credentials.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseCredentials(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                if (!root.ready)
                    waitingForAuthTimer.restart();
            }
        }
    }

    Timer {
        interval: 5 * 60 * 1000
        running: root.providerEnabled && !root.useCodexbar && root.oauthAccessToken !== ""
        repeat: true
        onTriggered: root.probeRateLimits()
    }

    function parseClaudeJson(content) {
        try {
            const data = JSON.parse(content);
            const projects = data.projects ?? {};

            const todayByModel = {};
            const allModelUsage = {};
            let todayTokens = 0;

            for (const projectPath in projects) {
                const proj = projects[projectPath];
                const modelUsage = proj.lastModelUsage ?? {};

                for (const model in modelUsage) {
                    const m = modelUsage[model];
                    let tokens = (m.inputTokens ?? 0) + (m.outputTokens ?? 0);
                    if (root.includeCacheTokens)
                        tokens += (m.cacheReadInputTokens ?? 0) + (m.cacheCreationInputTokens ?? 0);

                    todayTokens += tokens;
                    todayByModel[model] = (todayByModel[model] ?? 0) + tokens;

                    if (!allModelUsage[model]) {
                        allModelUsage[model] = {
                            inputTokens: 0,
                            outputTokens: 0,
                            cacheReadInputTokens: 0,
                            cacheCreationInputTokens: 0
                        };
                    }
                    allModelUsage[model].inputTokens += m.inputTokens ?? 0;
                    allModelUsage[model].outputTokens += m.outputTokens ?? 0;
                    allModelUsage[model].cacheReadInputTokens += m.cacheReadInputTokens ?? 0;
                    allModelUsage[model].cacheCreationInputTokens += m.cacheCreationInputTokens ?? 0;
                }
            }

            root.todayTokensByModel = todayByModel;
            root.todayTotalTokens = todayTokens;
            root.modelUsage = allModelUsage;
            root.ready = true;

            if (root.authMode === "none" && !root.tierLabel) {
                root.tierLabel = root.tr("providers.tiers.thirdPartyApi");
            }
            if (root.usageStatusText === root.tr("providers.status.waitingAuth"))
                root.clearUsageStatus();
        } catch (e) {
            Logger.e("model-usage/claude", "Failed to parse ~/.claude.json:", e);
        }
    }

    function parseHistory(content) {
        try {
            const now = new Date();
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
            const lines = content.split("\n");
            let todayPrompts = 0;
            let totalPrompts = 0;
            const todaySessions = {};
            const allSessions = {};

            for (let i = lines.length - 1; i >= 0; i--) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                try {
                    const entry = JSON.parse(line);
                    totalPrompts++;
                    if (entry.sessionId)
                        allSessions[entry.sessionId] = true;
                    if ((entry.timestamp ?? 0) >= startOfDay) {
                        todayPrompts++;
                        if (entry.sessionId)
                            todaySessions[entry.sessionId] = true;
                    }
                } catch (e) {
                    continue;
                }
            }

            root.todayPrompts = todayPrompts;
            root.todaySessions = Object.keys(todaySessions).length;
            root.totalPrompts = totalPrompts;
            root.totalSessions = Object.keys(allSessions).length;
        } catch (e) {
            Logger.e("model-usage/claude", "Failed to parse history.jsonl:", e);
        }
    }

    function parseCredentials(content) {
        if (!root.providerEnabled || root.useCodexbar) return;
        try {
            const data = JSON.parse(content);
            const oauth = data.claudeAiOauth ?? {};
            const fileAccessToken = oauth.accessToken ?? "";
            const fileExpiresAtMs = root.normalizeExpiresAtMs(oauth.expiresAt);
            const fileHasOAuth = fileAccessToken !== "";

            const tokenChanged = (root.oauthAccessToken !== fileAccessToken || root.oauthExpiresAtMs !== fileExpiresAtMs);
            root.oauthAccessToken = fileAccessToken;
            root.oauthExpiresAtMs = fileExpiresAtMs;
            if (tokenChanged)
                root.clearAuthoritativeRateLimits();

            root.authMode = fileHasOAuth ? "oauth" : "none";

            root.subscriptionType = oauth.subscriptionType ?? "";
            root.rateLimitTier = oauth.rateLimitTier ?? "";
            root.tierLabel = formatTier();

            if (root.oauthAccessToken && !root.oauthTokenExpired()) {
                root.clearUsageStatus();
                root.probeRateLimits();
            } else if (!root.oauthAccessToken) {
                root.clearAuthoritativeRateLimits();
                if (root.ready) {
                    root.clearUsageStatus();
                    if (!root.tierLabel)
                        root.tierLabel = root.tr("providers.tiers.thirdPartyApi");
                } else {
                    root.usageStatusText = root.tr("providers.status.waitingAuth");
                }
            } else {
                root.usageStatusText = root.tr("providers.status.tokenExpired");
                root.clearAuthoritativeRateLimits();
            }
        } catch (e) {
            Logger.e("model-usage/claude", "Failed to parse credentials.json:", e);
            root.clearAuthoritativeRateLimits();
            if (!root.ready)
                root.usageStatusText = root.tr("providers.status.waitingAuth");
        }
    }

    function formatTier() {
        if (!root.rateLimitTier)
            return root.subscriptionType || "";
        const match = root.rateLimitTier.match(/max_(\d+x)/i);
        if (match)
            return "Max " + match[1];
        if (root.subscriptionType)
            return root.subscriptionType.charAt(0).toUpperCase() + root.subscriptionType.slice(1);
        return "";
    }

    function normalizeExpiresAtMs(value) {
        const n = Number(value ?? 0);
        return (isFinite(n) && n > 0) ? n : 0;
    }

    function oauthTokenExpired() {
        if (!root.oauthAccessToken)
            return true;
        if (!root.oauthExpiresAtMs || !(root.oauthExpiresAtMs > 0))
            return false;
        return root.oauthExpiresAtMs <= Date.now();
    }

    function clearAuthoritativeRateLimits() {
        root.hasAuthoritativeRateLimit = false;
        root.rateLimitPercent = -1;
        root.rateLimitLabel = root.tr("providers.rateLimits.weekly7d");
        root.rateLimitResetAt = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "Session (5-hour)";
        root.secondaryRateLimitResetAt = "";
    }

    function clearUsageStatus() {
        root.usageStatusText = "";
    }

    function parseNumber(value) {
        if (value === null || value === undefined)
            return NaN;
        return parseFloat(String(value).trim().replace("%", ""));
    }

    function normalizeUtilization(value) {
        const n = parseNumber(value);
        if (!(n >= 0))
            return -1;
        if (n > 1)
            return Math.min(1, n / 100);
        return Math.min(1, n);
    }


    function oauthUsageBucket(payload, key) {
        const bucket = payload?.[key];
        if (bucket && typeof bucket === "object")
            return bucket;
        return null;
    }

    function applyAuthoritativeRateLimits(weekly, weeklyReset, session, sessionReset, sourceLabel) {
        const weeklyNorm = root.normalizeUtilization(weekly);
        const sessionNorm = root.normalizeUtilization(session);
        if (weeklyNorm < 0 && sessionNorm < 0)
            return false;

        root.hasAuthoritativeRateLimit = true;
        root.rateLimitPercent = -1;
        root.rateLimitLabel = root.tr("providers.rateLimits.weekly7d");
        root.rateLimitResetAt = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "Session (5-hour)";
        root.secondaryRateLimitResetAt = "";

        if (weeklyNorm >= 0)
            root.rateLimitPercent = weeklyNorm;
        if (sessionNorm >= 0)
            root.secondaryRateLimitPercent = sessionNorm;
        if (weeklyReset !== null && weeklyReset !== undefined)
            root.rateLimitResetAt = root.utils.normalizeResetAt(weeklyReset);
        if (sessionReset !== null && sessionReset !== undefined)
            root.secondaryRateLimitResetAt = root.utils.normalizeResetAt(sessionReset);

        if (root.rateLimitPercent < 0 && sessionNorm >= 0) {
            root.rateLimitPercent = sessionNorm;
            root.rateLimitLabel = root.secondaryRateLimitLabel;
            root.rateLimitResetAt = root.secondaryRateLimitResetAt;
        }

        if (sourceLabel)
            root.rateLimitLabel = root.rateLimitLabel + " (" + sourceLabel + ")";
        return true;
    }

    function probeOAuthUsage() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://api.anthropic.com/api/oauth/usage");
        xhr.setRequestHeader("Authorization", "Bearer " + root.oauthAccessToken);
        xhr.setRequestHeader("anthropic-beta", "oauth-2025-04-20");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    const payload = JSON.parse(xhr.responseText ?? "{}");
                    const weeklyBucket = root.oauthUsageBucket(payload, "seven_day_oauth_apps") || root.oauthUsageBucket(payload, "seven_day");
                    const sessionBucket = root.oauthUsageBucket(payload, "five_hour");

                    if (root.applyAuthoritativeRateLimits(weeklyBucket?.utilization, weeklyBucket?.resets_at, sessionBucket?.utilization, sessionBucket?.resets_at, "")) {
                        root.ready = true;
                        root.clearUsageStatus();
                        return;
                    }
                } catch (e) {
                    Logger.e("model-usage/claude", "Failed to parse oauth usage response:", e);
                }
            }

            if (xhr.status === 401 || xhr.status === 403) {
                root.usageStatusText = root.tr("providers.status.tokenExpired");
                root.clearAuthoritativeRateLimits();
                return;
            }

            const body = xhr.responseText ? String(xhr.responseText).slice(0, 220) : "";
            Logger.e("model-usage/claude", "OAuth usage probe failed (status " + xhr.status + ")" + (body ? " body=" + body : ""));
            root.clearAuthoritativeRateLimits();
        };
        xhr.send();
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

        claudeJsonFile.reload();
        historyFile.reload();
        credentialsFile.reload();
    }


    function probeRateLimits() {
        if (!root.providerEnabled || root.useCodexbar) return;
        if (!root.oauthAccessToken || root.authMode !== "oauth") {
            root.clearAuthoritativeRateLimits();
            return;
        }

        if (root.oauthTokenExpired()) {
            root.usageStatusText = root.tr("providers.status.tokenExpired");
            root.clearAuthoritativeRateLimits();
            return;
        }

        const nowMs = Date.now();
        if (root.lastProbeAtMs > 0 && (nowMs - root.lastProbeAtMs) < root.probeMinIntervalMs)
            return;
        root.lastProbeAtMs = nowMs;

        root.probeOAuthUsage();
    }
}
