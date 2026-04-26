import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property var providerData: []
    property string lastError: ""
    property bool isRefreshing: false
    property string lastUpdated: ""
    property var previousResets: ({})
    property var previousUsedPercents: ({})
    property var _lowNotified: ({})
    property bool _cliMissingNotified: false
    property string rawJsonBuffer: ""
    property string rawStderrBuffer: ""
    property int _fetchRequestId: 0
    property int _timedOutRequestId: -1
    property int countdownTick: 0

    function formatResetsCountdown(resetsAt) {
        if (!resetsAt)
            return "";
        var _ = root.countdownTick;
        var d = new Date(resetsAt);
        var diff = (d.getTime() - Date.now()) / 1000;
        if (diff <= 0)
            return pluginApi?.tr("panel.resetsNow") || "Now";
        var h = Math.floor(diff / 3600);
        var m = Math.floor((diff % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property int refreshInterval: root.normalizeRefreshInterval(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)
    readonly property var barTextFields: root.normalizeBarTextFields(cfg.barTextFields ?? defaults.barTextFields ?? ["primary"])
    readonly property bool notifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    readonly property bool notifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    readonly property int lowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

    function normalizeBarTextFields(fields) {
        var allowed = ["primary", "secondary", "tertiary", "status"];
        var normalized = [];
        var source = Array.isArray(fields) ? fields : [fields];

        for (var index = 0; index < source.length; index++) {
            var fieldKey = String(source[index] || "").trim();
            if (allowed.indexOf(fieldKey) < 0 || normalized.indexOf(fieldKey) >= 0)
                continue;
            normalized.push(fieldKey);
        }

        if (normalized.length === 0)
            normalized.push("primary");
        return normalized;
    }

    function normalizeRefreshInterval(intervalValue) {
        var allowed = [60, 120, 300, 600, 900, 1800, 3600, 7200, 21600, 43200, 86400];
        var numeric = Number(intervalValue);
        if (!isFinite(numeric))
            numeric = 120;

        var best = allowed[0];
        var smallestDiff = Math.abs(best - numeric);
        for (var index = 1; index < allowed.length; index++) {
            var candidate = allowed[index];
            var diff = Math.abs(candidate - numeric);
            if (diff < smallestDiff) {
                best = candidate;
                smallestDiff = diff;
            }
        }
        return best;
    }

    function providerIcon(providerId) {
        switch (String(providerId || "")) {
        case "codex":
            return "cpu";
        case "claude":
            return "sparkles";
        case "kilo":
            return "bolt";
        case "gemini":
            return "stars";
        case "copilot":
            return "cpu";
        default:
            return "cpu";
        }
    }

    function providerDisplayName(providerId) {
        switch (String(providerId || "")) {
        case "codex":
            return "Codex";
        case "claude":
            return "Claude";
        case "kilo":
            return "Kilo";
        case "gemini":
            return "Gemini";
        case "copilot":
            return "Copilot";
        default:
            return String(providerId || "Unknown");
        }
    }

    function durationLabel(windowMinutes) {
        var m = Number(windowMinutes || 0);
        if (!isFinite(m) || m <= 0)
            return "";
        if (m % 1440 === 0)
            return (m / 1440) + "d";
        if (m % 60 === 0)
            return (m / 60) + "h";
        return m + "m";
    }

    function isCliErrorPayload(entry) {
        return String(entry?.provider || "") === "cli" && !!entry?.error;
    }

    function _extractFirstJSONArray(text) {
        var trimmed = String(text || "").trim();
        if (!trimmed || trimmed.charAt(0) !== "[")
            return null;
        var depth = 0;
        var inStr = false;
        var esc = false;
        for (var i = 0; i < trimmed.length; i++) {
            var c = trimmed.charAt(i);
            if (esc) {
                esc = false;
                continue;
            }
            if (c === "\\" && inStr) {
                esc = true;
                continue;
            }
            if (c === "\"") {
                inStr = !inStr;
                continue;
            }
            if (inStr)
                continue;
            if (c === "[")
                depth++;
            else if (c === "]") {
                depth--;
                if (depth === 0)
                    return trimmed.substring(0, i + 1);
            }
        }
        return null;
    }

    function refresh() {
        if (root.isRefreshing)
            return;

        root.isRefreshing = true;
        root.lastError = "";
        root.rawJsonBuffer = "";
        root.rawStderrBuffer = "";
        root._fetchRequestId += 1;
        root._timedOutRequestId = -1;
        fetchProcess.running = true;
        fetchTimeout.restart();
    }

    function _looksLikeMissingCli(exitCode, stderrText) {
        var text = String(stderrText || "");
        return exitCode === 127
            || text.indexOf("not found") >= 0
            || text.indexOf("No such file") >= 0
            || text.indexOf("ENOENT") >= 0;
    }

    function normalizeProvidersPayload(providers) {
        var newResets = ({});
        var newUsedPercents = ({});
        var filteredProviders = [];
        var now = Date.now();

        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (!p || typeof p !== "object" || !p.provider) {
                if (p && p.error)
                    root.lastError = String(p.error.message || p.error || "").trim();
                continue;
            }

            if (root.isCliErrorPayload(p)) {
                var cliMessage = String(p.error?.message || "").trim();
                if (cliMessage !== "")
                    root.lastError = cliMessage;
                continue;
            }

            p._windowLabels = ({});
            var roles = ["primary", "secondary", "tertiary"];
            for (var r = 0; r < roles.length; r++) {
                var role = roles[r];
                var win = p.usage ? p.usage[role] : null;
                if (win) {
                    var label = root.durationLabel(win.windowMinutes);
                    if (!label && win.resetDescription)
                        label = String(win.resetDescription).trim();
                    p._windowLabels[role] = label || (role.charAt(0).toUpperCase() + role.slice(1));
                }
            }

            var providerId = String(p.provider || "");
            var primaryResetsAt = p.usage?.primary?.resetsAt || "";
            var primaryUsed = p.usage?.primary?.usedPercent ?? -1;
            var primaryLeft = 100 - primaryUsed;

            filteredProviders.push(p);

            if (primaryResetsAt) {
                var prevReset = root.previousResets[providerId];
                var prevUsed = root.previousUsedPercents[providerId];
                if (prevReset && prevReset !== primaryResetsAt && root.notifyOnReset) {
                    var prevTime = Date.parse(prevReset);
                    var nextTime = Date.parse(primaryResetsAt);
                    var hasTimes = isFinite(prevTime) && isFinite(nextTime);

                    var prevWasDue = hasTimes && prevTime <= now + 5 * 60 * 1000;
                    var nextAdvanced = hasTimes && nextTime > prevTime;
                    var usageDropped = typeof prevUsed === "number"
                        && primaryUsed >= 0
                        && primaryUsed <= 100
                        && primaryUsed <= prevUsed - 10;

                    if ((prevWasDue && nextAdvanced) || (usageDropped && nextAdvanced && (nextTime - prevTime) >= 30 * 60 * 1000)) {
                        ToastService.showNotice(
                            pluginApi?.tr("notifications.resetTitle"),
                            pluginApi?.tr("notifications.resetBody").replace("{provider}", root.providerDisplayName(providerId)),
                            "sparkles"
                        );
                    }
                }
                newResets[providerId] = primaryResetsAt;
            }

            if (primaryUsed >= 0 && primaryUsed <= 100)
                newUsedPercents[providerId] = primaryUsed;

            if (primaryLeft >= 0 && primaryLeft <= root.lowUsageThreshold && root.notifyOnLowUsage) {
                var notifKey = providerId + "_low_" + (new Date(primaryResetsAt || Date.now())).toDateString();
                if (!root._lowNotified || !root._lowNotified[notifKey]) {
                    if (!root._lowNotified)
                        root._lowNotified = ({});
                    root._lowNotified[notifKey] = true;
                    ToastService.showNotice(
                        pluginApi?.tr("notifications.lowTitle"),
                        pluginApi?.tr("notifications.lowBody").replace("{provider}", root.providerDisplayName(providerId)).replace("{percent}", String(Math.round(primaryLeft))),
                        "bell"
                    );
                }
            }
        }

        root.previousResets = newResets;
        root.previousUsedPercents = newUsedPercents;
        root.providerData = filteredProviders;
        root.lastUpdated = new Date().toISOString();
    }

    Process {
        id: fetchProcess

        property var _command: {
            var script = "codexbar_path=$(command -v codexbar 2>/dev/null) || exit 127; exec \"$codexbar_path\" --format json --status";
            return ["sh", "-c", script];
        }
        command: _command

        stdout: StdioCollector {
            id: fetchStdout
            onStreamFinished: {
                root.rawJsonBuffer = String(this.text || "");
            }
        }

        stderr: StdioCollector {
            id: fetchStderr
            onStreamFinished: {
                var err = String(this.text || "").trim();
                if (err) {
                    Logger.w("CodexBar", "stderr: " + err);
                    root.rawStderrBuffer = err;
                }
            }
        }

        onExited: function (exitCode, exitStatus) {
            var exitedRequestId = root._fetchRequestId;
            fetchTimeout.stop();
            root.isRefreshing = false;

            if (root._timedOutRequestId === exitedRequestId) {
                root._timedOutRequestId = -1;
                root.rawJsonBuffer = "";
                root.rawStderrBuffer = "";
                return;
            }

            var jsonParsed = false;

            if (root.rawJsonBuffer.length > 0) {
                var firstJson = root._extractFirstJSONArray(root.rawJsonBuffer);
                if (firstJson) {
                    try {
                        var payload = JSON.parse(firstJson);
                        var list = Array.isArray(payload) ? payload : [payload];
                        root.normalizeProvidersPayload(list);
                        jsonParsed = true;

                        var remaining = root.rawJsonBuffer.substring(firstJson.length).trim();
                        if (remaining.length > 0 && !root.lastError) {
                            var secondJson = root._extractFirstJSONArray(remaining);
                            if (secondJson) {
                                try {
                                    var cliPayload = JSON.parse(secondJson);
                                    var cliList = Array.isArray(cliPayload) ? cliPayload : [cliPayload];
                                    for (var ci = 0; ci < cliList.length; ci++) {
                                        if (cliList[ci].provider === "cli" && cliList[ci].error) {
                                            root.lastError = String(cliList[ci].error.message || "").trim();
                                            break;
                                        }
                                    }
                                } catch (_cliParseErr) {}
                            }
                        }
                    } catch (parseError) {
                        Logger.e("CodexBar", "JSON parse error: " + parseError);
                    }
                }
            }

            if (!jsonParsed) {
                if (exitCode !== 0) {
                    var stderrText = root.rawStderrBuffer;
                    if (root._looksLikeMissingCli(exitCode, stderrText)) {
                        root.lastError = pluginApi?.tr("errors.cliMissing");
                        if (!root._cliMissingNotified) {
                            root._cliMissingNotified = true;
                            ToastService.showNotice(
                                pluginApi?.tr("errors.cliMissingTitle"),
                                pluginApi?.tr("errors.cliMissingBody"),
                                "external-link"
                            );
                        }
                    } else if (!root.lastError) {
                        root.lastError = stderrText.length > 0 ? stderrText : "Exit code " + exitCode;
                    }
                    Logger.w("CodexBar", "codexbar exited with code " + exitCode);
                } else if (!root.lastError) {
                    root.lastError = root.rawStderrBuffer.length > 0
                        ? root.rawStderrBuffer
                        : pluginApi?.tr("errors.cliParseFailed") || "Failed to parse CodexBar output.";
                }
            } else {
                root._cliMissingNotified = false;
            }

            root.rawJsonBuffer = "";
            root.rawStderrBuffer = "";
        }
    }

    Timer {
        id: fetchTimeout
        interval: 20000
        repeat: false
        onTriggered: {
            if (fetchProcess.running) {
                root._timedOutRequestId = root._fetchRequestId;
                fetchProcess.running = false;
                root.isRefreshing = false;
                root.lastError = "codexbar timed out while fetching usage data.";
                Logger.w("CodexBar", "Fetch timed out after " + interval + "ms");
            }
        }
    }

    Timer {
        id: updateTimer

        interval: root.refreshInterval * 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: root.refresh()
        onIntervalChanged: {
            if (running) {
                running = false;
                running = true;
            }
        }
    }

    Timer {
        id: countdownTickTimer
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.countdownTick += 1
    }

    IpcHandler {
        target: "plugin:codexbar"

        function refresh() {
            root.refresh();
        }
    }

    Component.onCompleted: {
        Logger.i("CodexBar", "Plugin loaded, refresh interval: " + root.refreshInterval + "s");
    }
}
