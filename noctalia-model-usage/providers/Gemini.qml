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

    property string providerId: "gemini"
    property string providerName: root.tr("providers.names.gemini")
    property string providerIcon: "ai"
    property string providerIconAsset: "assets/geminicli.svg"
    property bool providerEnabled: false
    property bool ready: false

    property real rateLimitPercent: -1
    property string rateLimitLabel: root.tr("providers.rateLimits.proModels")
    property string rateLimitResetAt: ""
    property real secondaryRateLimitPercent: -1
    property string secondaryRateLimitLabel: root.tr("providers.rateLimits.flashModels")
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
    property string authHelpText: root.tr("providers.help.gemini")
    property string usageStatusText: ""
    property bool hasLocalStats: false

    property var providerSettings: ({})
    property bool useCodexbar: root.providerSettings?.useCodexbar ?? false
    readonly property string codexbarProviderName: "gemini"
    property var utils: ProviderUtils {}
    property int apiRefreshIntervalMin: 1

    property string _accessToken: ""
    property string _refreshToken: ""
    property string _clientId: ""
    property string _clientSecret: ""
    property double _expiryDate: 0
    property string _projectId: ""
    property bool _credsLoaded: false

    function resolvePath(p) {
        if (p && p.startsWith("~"))
            return (Quickshell.env("HOME") ?? "/home") + p.substring(1);
        return p;
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
        id: credsFile
        path: root.resolvePath("~/.gemini/oauth_creds.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root._accessToken = data.access_token ?? "";
                root._refreshToken = data.refresh_token ?? "";
                root._clientId = data.client_id ?? "";
                root._clientSecret = data.client_secret ?? "";
                root._expiryDate = Number(data.expiry_date ?? 0);
                root._credsLoaded = true;
                root.usageStatusText = "";
                if (root.providerEnabled && !root.useCodexbar)
                    root.fetchAll();
            } catch (e) {
                Logger.d("model-usage/gemini", "Failed to parse oauth_creds.json: " + e);
                root.usageStatusText = root.tr("providers.status.couldNotReadGeminiCreds", { "help": root.authHelpText });
            }
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.usageStatusText = root.tr("providers.status.notAuthenticatedHelp", { "help": root.authHelpText });
            } else {
                Logger.d("model-usage/gemini", "Creds file load failed: " + error);
            }
        }
    }

    ApiRefreshTimer {
        providerEnabled: root.providerEnabled && !root.useCodexbar && root._credsLoaded
        intervalMin: root.apiRefreshIntervalMin
        onTick: root.fetchAll()
    }

    onProviderEnabledChanged: {
        if (providerEnabled) {
            if (root.useCodexbar)
                codexbarFetcher.fetch();
            else if (_credsLoaded)
                fetchAll();
        }
    }

    function fetchAll() {
        if (!root._credsLoaded)
            return;
        if (Date.now() >= root._expiryDate && root._refreshToken && root._clientId && root._clientSecret) {
            root.refreshToken();
        } else {
            root.fetchQuota();
            root.fetchPlan();
        }
    }

    function refreshToken() {
        const xhr = new XMLHttpRequest();
        xhr.open("POST", "https://oauth2.googleapis.com/token");
        xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const data = JSON.parse(xhr.responseText);
                    root._accessToken = data.access_token ?? root._accessToken;
                    if (data.expires_in)
                        root._expiryDate = Date.now() + Number(data.expires_in) * 1000;
                    root.fetchQuota();
                    root.fetchPlan();
                } catch (e) {
                    Logger.e("model-usage/gemini", "Failed to parse token refresh response: " + e);
                }
            } else {
                Logger.e("model-usage/gemini", "Token refresh failed (status " + xhr.status + ")");
                root.usageStatusText = root.tr("providers.status.tokenRefreshFailed", { "help": root.authHelpText });
            }
        };

        const body = "client_id=" + encodeURIComponent(root._clientId)
            + "&client_secret=" + encodeURIComponent(root._clientSecret)
            + "&refresh_token=" + encodeURIComponent(root._refreshToken)
            + "&grant_type=refresh_token";
        xhr.send(body);
    }

    function fetchQuota() {
        if (!root._accessToken)
            return;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuota");
        xhr.setRequestHeader("Authorization", "Bearer " + root._accessToken);
        xhr.setRequestHeader("Content-Type", "application/json");
        if (root._projectId)
            xhr.setRequestHeader("x-goog-user-project", root._projectId);

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                Logger.e("model-usage/gemini", "retrieveUserQuota failed (status " + xhr.status + ")");
                if (xhr.status === 401 || xhr.status === 403)
                    root.usageStatusText = root.tr("providers.status.authenticationFailed", { "help": root.authHelpText });
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                root.parseQuotaBuckets(data.quotaBuckets ?? data.quotas ?? []);
                root.usageStatusText = "";
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/gemini", "Failed to parse quota response: " + e);
            }
        };

        xhr.send("{}");
    }

    function fetchPlan() {
        if (!root._accessToken)
            return;

        const xhr = new XMLHttpRequest();
        xhr.open("POST", "https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist");
        xhr.setRequestHeader("Authorization", "Bearer " + root._accessToken);
        xhr.setRequestHeader("Content-Type", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                Logger.d("model-usage/gemini", "loadCodeAssist failed (status " + xhr.status + ")");
                return;
            }
            try {
                const data = JSON.parse(xhr.responseText);
                root.parsePlan(data);
            } catch (e) {
                Logger.e("model-usage/gemini", "Failed to parse plan response: " + e);
            }
        };

        xhr.send("{}");
    }

    function modelTier(modelId) {
        const id = String(modelId ?? "").toLowerCase();
        if (id.includes("flash-lite") || id.includes("flashlite"))
            return "flashlite";
        if (id.includes("flash"))
            return "flash";
        if (id.includes("pro") || id.includes("ultra") || id.includes("exp"))
            return "pro";
        return "other";
    }

    function parseQuotaBuckets(buckets) {
        let proWorst = -1;
        let proResetAt = "";
        let flashWorst = -1;
        let flashResetAt = "";

        for (const bucket of buckets) {
            const remaining = Number(bucket.remainingFraction ?? 1);
            const used = 1.0 - remaining;
            const tier = root.modelTier(bucket.modelId ?? "");
            const resetIso = bucket.resetTime ? new Date(Number(bucket.resetTime)).toISOString() : "";

            if (tier === "pro") {
                if (used > proWorst) {
                    proWorst = used;
                    proResetAt = resetIso;
                }
            } else if (tier === "flash") {
                if (used > flashWorst) {
                    flashWorst = used;
                    flashResetAt = resetIso;
                }
            }
        }

        root.rateLimitPercent = proWorst >= 0 ? proWorst : -1;
        root.rateLimitLabel = "Pro models";
        root.rateLimitResetAt = proResetAt;

        root.secondaryRateLimitPercent = flashWorst >= 0 ? flashWorst : -1;
        root.secondaryRateLimitLabel = "Flash models";
        root.secondaryRateLimitResetAt = flashResetAt;
    }

    function parsePlan(data) {
        const tier = String(data.currentTier ?? data.planAssignment?.tier ?? "").toLowerCase();
        const claims = data.userTierClaims ?? data.claims ?? [];
        const hasHd = Array.isArray(claims) && claims.some(c => String(c).toLowerCase().includes("hd"));

        if (tier.includes("standard"))
            root.tierLabel = root.tr("providers.tiers.paid");
        else if (tier.includes("legacy"))
            root.tierLabel = root.tr("providers.tiers.legacy");
        else if (tier.includes("free") && hasHd)
            root.tierLabel = root.tr("providers.tiers.workspace");
        else if (tier.includes("free"))
            root.tierLabel = root.tr("providers.tiers.free");
        else
            root.tierLabel = tier || "";
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

        if (root._credsLoaded)
            fetchAll();
    }
}
