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

    property string providerId: "codex"
    property string providerName: root.tr("providers.names.codex")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/codex.svg"
    property bool providerEnabled: false
    property bool ready: false
    property int pendingRefreshRequests: 0
    readonly property bool refreshing: codexbarFetcher.running || sessionLister.running || root.sessionSearchInProgress || root.pendingRefreshRequests > 0

    property real rateLimitPercent: -1
    property string rateLimitLabel: root.tr("providers.rateLimits.weekly7d")
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
    property string authHelpText: root.tr("providers.help.codex")
    property string usageStatusText: ""
    property bool hasLocalStats: true

    property bool includeCacheTokens: true
    property string configModel: ""
    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "codex"
    property string usageMode: providerSettings?.usageMode ?? "api"
    property string accessToken: ""
    property string accountId: ""
    readonly property string apiEndpoint: "https://chatgpt.com/backend-api/wham/usage"

    property int refreshIntervalSec: 30

    property double _lastApiRefreshMs: 0
    readonly property int _apiRefreshMinIntervalMs: Math.max(5, root.refreshIntervalSec) * 1000

    property var utils: ProviderUtils {}
    readonly property var providerData: ProviderDataMapper {}

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
        id: historyFile
        path: root.resolvePath("~/.codex/history.jsonl")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseHistory(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                Logger.d("model-usage/codex", "history.jsonl not found — prompt counts unavailable");
        }
    }

    FileView {
        id: configFile
        path: root.resolvePath("~/.codex/config.toml")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseConfig(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                Logger.d("model-usage/codex", "config.toml not found");
        }
    }

    Process {
        id: sessionLister
        command: ["find", root.resolvePath("~/.codex/sessions"), "-type", "f", "-name", "*.jsonl"]
        running: false
        stdout: StdioCollector {
            id: sessionListerOutput
            onStreamFinished: {
                const output = text;
                if (output)
                    root.parseSessionList(output);
            }
        }
    }

    property var sessionPaths: []
    property int sessionPathIndex: -1
    property bool sessionSearchInProgress: false
    property string latestSessionPath: ""
    FileView {
        id: latestSessionFile
        path: root.latestSessionPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseSessionData(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                Logger.e("model-usage/codex", "Session file not found:", root.latestSessionPath);
                root.loadPreviousSessionFile();
            }
        }
    }

    FileView {
        id: authFile
        path: root.resolvePath("~/.codex/auth.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseAuth(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                Logger.e("model-usage/codex", "auth.json not found");
        }
    }

    Timer {
        interval: 60 * 1000
        running: root.providerEnabled && root.usageMode === "local"
        repeat: true
        onTriggered: root.scanSessions()
    }

    onProviderEnabledChanged: {
        if (providerEnabled) {
            if (root.useCodexbar) {
                codexbarFetcher.fetch();
            } else if (root.usageMode === "api") {
                root.fetchUsageFromApi();
            } else {
                root.scanSessions();
            }
        }
    }

    onUsageModeChanged: {
        if (root.providerEnabled) {
            if (root.useCodexbar) {
                codexbarFetcher.fetch();
            } else if (root.usageMode === "api") {
                root.fetchUsageFromApi();
            } else {
                root.scanSessions();
            }
        }
    }

    // --- Local file mode ---

    function parseHistory(content) {
        try {
            const now = new Date();
            const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000;
            const lines = content.split("\n");
            let prompts = 0;
            const sessions = {};

            for (let i = lines.length - 1; i >= 0; i--) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                try {
                    const entry = JSON.parse(line);
                    if ((entry.ts ?? 0) < startOfDay)
                        break;
                    prompts++;
                    if (entry.session_id)
                        sessions[entry.session_id] = true;
                } catch (e) {
                    continue;
                }
            }

            root.todayPrompts = prompts;
            root.todaySessions = Object.keys(sessions).length;
            root.ready = true;
        } catch (e) {
            Logger.e("model-usage/codex", "Failed to parse history.jsonl:", e);
        }
    }

    function parseConfig(content) {
        try {
            const match = content.match(/model\s*=\s*"([^"]+)"/);
            if (match)
                root.configModel = match[1];
        } catch (e) {
            Logger.e("model-usage/codex", "Failed to parse config.toml:", e);
        }
    }

    function parseAuth(content) {
        try {
            const data = JSON.parse(content);

            // Extract access token and account ID for API mode
            if (data.tokens) {
                root.accessToken = String(data.tokens.access_token ?? "");
                root.accountId = String(data.tokens.account_id ?? "");
            }

            // Tier label is only set from plan_type in API mode (parseApiResponse)
            // auth_mode is the auth method ("chatgpt"), not a plan type

            // In API mode, retry fetch once tokens become available
            if (root.usageMode === "api" && root.providerEnabled && root.accessToken)
                root.fetchUsageFromApi();
        } catch (e) {
            Logger.e("model-usage/codex", "Failed to parse auth.json:", e);
        }
    }

    function scanSessions() {
        if (!sessionLister.running)
            sessionLister.running = true;
    }

    function parseSessionList(output) {
        if (!output)
            return;
        const lines = output.trim().split("\n");
        const unique = {};
        for (let i = 0; i < lines.length; i++) {
            const file = lines[i].trim();
            if (!file.endsWith(".jsonl"))
                continue;
            unique[file] = true;
        }

        const files = Object.keys(unique).sort();
        if (files.length === 0) {
            root.sessionPaths = [];
            root.sessionPathIndex = -1;
            root.sessionSearchInProgress = false;
            return;
        }

        root.sessionPaths = files.slice(Math.max(0, files.length - 16));
        root.sessionPathIndex = root.sessionPaths.length - 1;
        root.sessionSearchInProgress = true;
        const newestPath = root.sessionPaths[root.sessionPathIndex];
        if (root.latestSessionPath === newestPath)
            latestSessionFile.reload();
        else
            root.latestSessionPath = newestPath;
    }

    function loadPreviousSessionFile() {
        if (!root.sessionSearchInProgress)
            return;
        root.sessionPathIndex = root.sessionPathIndex - 1;
        if (root.sessionPathIndex >= 0) {
            root.latestSessionPath = root.sessionPaths[root.sessionPathIndex];
        } else {
            root.sessionSearchInProgress = false;
        }
    }

    function parseSessionData(content) {
        try {
            const lines = content.split("\n");
            let lastTokenCount = null;

            for (let i = lines.length - 1; i >= 0; i--) {
                const line = lines[i].trim();
                if (!line)
                    continue;
                try {
                    const entry = JSON.parse(line);
                    let candidate = null;
                    if (entry.type === "event_msg" && entry.payload?.type === "token_count")
                        candidate = entry.payload;
                    else if (entry.type === "token_count")
                        candidate = entry;
                    else if (entry.type === "response_item" && entry.payload?.type === "event_msg" && entry.payload?.payload?.type === "token_count")
                        candidate = entry.payload.payload;

                    if (candidate) {
                        lastTokenCount = candidate;
                        break;
                    }
                } catch (e) {
                    continue;
                }
            }

            if (!lastTokenCount) {
                root.loadPreviousSessionFile();
                return;
            }

            const rl = lastTokenCount.rate_limits?.primary;
            if (rl) {
                root.rateLimitPercent = (rl.used_percent ?? 0) / 100;
                if (rl.window_minutes === 10080)
                    root.rateLimitLabel = root.tr("providers.rateLimits.weekly7d");
                else
                    root.rateLimitLabel = root.tr("providers.rateLimits.rollingWindow", { "hours": Math.round(rl.window_minutes / 60) });
                if (rl.resets_at) {
                    const resetDate = new Date(rl.resets_at * 1000);
                    root.rateLimitResetAt = resetDate.toISOString();
                }
            }

            const usage = lastTokenCount.info?.total_token_usage;
            if (usage) {
                const input = usage.input_tokens ?? 0;
                const output = usage.output_tokens ?? 0;
                const cached = usage.cached_input_tokens ?? 0;
                const reasoning = usage.reasoning_output_tokens ?? 0;
                root.todayTotalTokens = input + output + reasoning;
                if (root.includeCacheTokens)
                    root.todayTotalTokens += cached;

                const modelName = root.configModel || "codex";
                root.todayTokensByModel = {};
                root.todayTokensByModel[modelName] = root.todayTotalTokens;

                root.modelUsage = {};
                root.modelUsage[modelName] = {
                    inputTokens: input,
                    outputTokens: output + reasoning,
                    cacheReadInputTokens: cached,
                    cacheCreationInputTokens: 0
                };
            }

            root.sessionSearchInProgress = false;
        } catch (e) {
            Logger.e("model-usage/codex", "Failed to parse session data:", e);
            root.loadPreviousSessionFile();
        }
    }

    // --- API mode ---

    function unixToIso(unixTimestamp) {
        if (unixTimestamp === null || unixTimestamp === undefined)
            return "";
        const d = new Date(unixTimestamp * 1000);
        if (!isNaN(d.getTime()))
            return d.toISOString();
        return "";
    }

    function clearRateLimits() {
        root.rateLimitPercent = -1;
        root.rateLimitLabel = root.tr("providers.rateLimits.weekly7d");
        root.rateLimitResetAt = "";
        root.secondaryRateLimitPercent = -1;
        root.secondaryRateLimitLabel = "";
        root.secondaryRateLimitResetAt = "";
    }

    function parseApiResponse(data) {
        root.clearRateLimits();

        // Plan type -> tier label
        if (data.plan_type) {
            const pt = String(data.plan_type);
            root.tierLabel = pt.charAt(0).toUpperCase() + pt.slice(1);
        }

        // Primary rate limit (short window, e.g. 5h for Plus) → secondaryRateLimitPercent (5h slot)
        const primary = data.rate_limit?.primary_window;
        if (primary && typeof primary.used_percent === "number" && isFinite(primary.used_percent)) {
            root.secondaryRateLimitPercent = Math.min(1, Math.max(0, primary.used_percent / 100));
            const windowSec = primary.limit_window_seconds ?? 0;
            if (windowSec > 0) {
                if (windowSec >= 86400)
                    root.secondaryRateLimitLabel = Math.round(windowSec / 86400) + "-day window";
                else
                    root.secondaryRateLimitLabel = Math.round(windowSec / 3600) + "h window";
            }
            root.secondaryRateLimitResetAt = root.unixToIso(primary.reset_at);
        }

        // Secondary rate limit (long window, e.g. 7-day) → rateLimitPercent (7d slot)
        const secondary = data.rate_limit?.secondary_window;
        if (secondary && typeof secondary.used_percent === "number" && isFinite(secondary.used_percent)) {
            root.rateLimitPercent = Math.min(1, Math.max(0, secondary.used_percent / 100));
            const windowSec = secondary.limit_window_seconds ?? 0;
            if (windowSec > 0) {
                if (windowSec >= 86400)
                    root.rateLimitLabel = Math.round(windowSec / 86400) + "-day window";
                else
                    root.rateLimitLabel = Math.round(windowSec / 3600) + "h window";
            }
            root.rateLimitResetAt = root.unixToIso(secondary.reset_at);
        }

        // Limit reached status
        if (data.rate_limit?.limit_reached) {
            root.usageStatusText = root.tr("providers.status.rateLimitReached");
            root.authHelpText = "Wait for the rate limit window to reset.";
        } else {
            root.usageStatusText = "";
            root.authHelpText = "Run `codex` to re-authenticate if needed.";
        }
    }

    function fetchUsageFromApi() {
        if (!root.accessToken) {
            root.usageStatusText = root.tr("providers.status.noAuthToken");
            root.authHelpText = "Run `codex` to authenticate first.";
            root.ready = false;
            root.clearRateLimits();
            root._lastApiRefreshMs = 0;  // allow retry when auth.json loads
            return;
        }

        const now = Date.now();
        if (root._lastApiRefreshMs > 0 && (now - root._lastApiRefreshMs) < root._apiRefreshMinIntervalMs)
            return;

        root.pendingRefreshRequests += 1;
        const xhr = new XMLHttpRequest();
        xhr.open("GET", root.apiEndpoint);
        xhr.setRequestHeader("Authorization", "Bearer " + root.accessToken);
        if (root.accountId)
            xhr.setRequestHeader("ChatGPT-Account-Id", root.accountId);
        xhr.setRequestHeader("User-Agent", "NoctaliaModelUsage");
        xhr.setRequestHeader("Accept", "application/json");

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            root.pendingRefreshRequests = Math.max(0, root.pendingRefreshRequests - 1);
            root._lastApiRefreshMs = Date.now();

            if (xhr.status === 401 || xhr.status === 403) {
                root.usageStatusText = root.tr("providers.status.tokenExpired");
                root.authHelpText = "Run `codex` to re-authenticate.";
                root.ready = false;
                root.clearRateLimits();
                Logger.e("model-usage/codex", "API auth failed (status " + xhr.status + ")");
                return;
            }

            if (xhr.status < 200 || xhr.status >= 300) {
                root.usageStatusText = root.tr("providers.status.fetchUsageFailed", { "status": xhr.status });
                root.authHelpText = "Check your internet connection and try again.";
                root.ready = false;
                root.clearRateLimits();
                Logger.e("model-usage/codex", "API request failed (status " + xhr.status + ")");
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                root.parseApiResponse(data);
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/codex", "Failed to parse API response:", e);
                root.usageStatusText = root.tr("providers.status.parseUsageFailed");
            }
        };

        xhr.send();
    }

    // --- Shared ---


    function applyCodexbarData(result) {
        providerData.applyCodexbarData(root, result, utils);
    }

    function refresh(force) {
        if (root.useCodexbar) {
            codexbarFetcher.fetch();
            return;
        }

        if (root.usageMode === "api") {
            if (force === true) {
                authFile.reload();
                // Also read history for prompt counts (non-blocking)
                historyFile.reload();
                configFile.reload();
            }
            root.fetchUsageFromApi();
        } else if (force === true) {
            historyFile.reload();
            configFile.reload();
            authFile.reload();
            root.scanSessions();
        }
    }

}
