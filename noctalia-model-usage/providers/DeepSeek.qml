import QtQuick
import Quickshell

Item {
    id: root
    visible: false

    property string providerId: "deepseek"
    property string providerName: "DeepSeek"
    property string providerIcon: "ai"
    property bool enabled: false
    property bool ready: false

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
    property string authHelpText: "Check your DeepSeek API key at platform.deepseek.com."
    property bool hasLocalStats: false
    property string usageStatusText: ""

    property var providerSettings: ({})
    property string apiKey: {
        const envKey = Quickshell.env("DEEPSEEK_API_KEY") ?? "";
        return envKey || (providerSettings?.apiKey ?? "");
    }

    property bool isAvailable: false
    property real totalBalance: 0
    property real grantedBalance: 0
    property real toppedUpBalance: 0
    property string currency: ""

    Timer {
        interval: 5 * 60 * 1000
        running: root.enabled && root.apiKey !== ""
        repeat: true
        onTriggered: root.fetchBalance()
    }

    onEnabledChanged: {
        if (enabled && apiKey !== "")
            fetchBalance();
    }

    onApiKeyChanged: {
        root.ready = false;
        root.tierLabel = "";
        root.usageStatusText = "";
        if (enabled && apiKey !== "")
            fetchBalance();
    }

    function fetchBalance() {
        if (!root.apiKey)
            return;

        const xhr = new XMLHttpRequest();
        xhr.open("GET", "https://api.deepseek.com/user/balance");
        xhr.setRequestHeader("Authorization", "Bearer " + root.apiKey);
        xhr.setRequestHeader("Accept", "application/json");

        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;

            if (xhr.status === 401 || xhr.status === 403) {
                root.usageStatusText = "Invalid API key";
                root.ready = false;
                root.tierLabel = "";
                Logger.e("model-usage/deepseek", "Auth failed (status " + xhr.status + ")");
                return;
            }

            if (xhr.status < 200 || xhr.status >= 300) {
                const body = xhr.responseText ? String(xhr.responseText).slice(0, 200) : "";
                Logger.e("model-usage/deepseek", "Balance request failed (status " + xhr.status + ")" + (body ? " body=" + body : ""));
                return;
            }

            try {
                const data = JSON.parse(xhr.responseText);
                root.parseBalanceData(data);
                root.usageStatusText = "";
                root.ready = true;
            } catch (e) {
                Logger.e("model-usage/deepseek", "Failed to parse balance response:", e);
            }
        };

        xhr.send();
    }

    function parseBalanceData(data) {
        root.isAvailable = data.is_available ?? false;
        const balanceInfos = data.balance_infos ?? [];

        if (balanceInfos.length > 0) {
            const info = balanceInfos[0];
            root.currency = info.currency ?? "";
            root.totalBalance = parseFloat(info.total_balance ?? "0");
            root.grantedBalance = parseFloat(info.granted_balance ?? "0");
            root.toppedUpBalance = parseFloat(info.topped_up_balance ?? "0");

            if (root.totalBalance > 0) {
                root.tierLabel = root.totalBalance.toFixed(2) + " " + root.currency;
            } else {
                root.tierLabel = root.grantedBalance.toFixed(2) + " " + root.currency + " (granted)";
            }
        } else {
            root.tierLabel = root.isAvailable ? "Available" : "No balance info";
        }
    }

    function refresh() {
        if (root.apiKey !== "")
            fetchBalance();
    }

    function formatResetTime(isoTimestamp) {
        if (!isoTimestamp)
            return "";
        const reset = new Date(isoTimestamp);
        const now = new Date();
        const diffMs = reset.getTime() - now.getTime();
        if (diffMs <= 0)
            return "now";
        const hours = Math.floor(diffMs / 3600000);
        const mins = Math.floor((diffMs % 3600000) / 60000);
        if (hours > 24)
            return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
        if (hours > 0)
            return hours + "h " + mins + "m";
        return mins + "m";
    }
}
