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
    property bool _cliMissingNotified: false
    property bool _lastFetchHadJson: false

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property int refreshInterval: root.normalizeRefreshInterval(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)
    readonly property var barTextFields: root.normalizeBarTextFields(cfg.barTextFields ?? defaults.barTextFields ?? ["primary"])
    readonly property bool shouldFetchStatus: barTextFields.indexOf("status") >= 0
    readonly property bool notifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    readonly property bool notifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    readonly property int lowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

    function normalizeBarTextFields(fields) {
        var allowed = ["primary", "secondary", "status"];
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

    function isCliErrorPayload(providerData) {
        return String(providerData?.provider || "") === "cli" && !!providerData?.error;
    }

    function refresh() {
        if (root.isRefreshing)
            return;

        root.isRefreshing = true;
        root.lastError = "";
        fetchProcess.running = true;
    }

    function _looksLikeMissingCli(exitCode, stderrText) {
        var text = String(stderrText || "");
        return exitCode === 127
            || text.indexOf("not found") >= 0
            || text.indexOf("No such file") >= 0
            || text.indexOf("ENOENT") >= 0;
    }

    function _tryParseJsonValue(text) {
        try {
            return {
                "ok": true,
                "value": JSON.parse(text)
            };
        } catch (error) {
            return {
                "ok": false,
                "error": error
            };
        }
    }

    function _extractLikelyJsonFragment(text) {
        var source = String(text || "");
        var firstBrace = source.indexOf("{");
        var firstBracket = source.indexOf("[");
        var start = -1;

        if (firstBrace >= 0 && firstBracket >= 0)
            start = Math.min(firstBrace, firstBracket);
        else if (firstBrace >= 0)
            start = firstBrace;
        else if (firstBracket >= 0)
            start = firstBracket;

        if (start < 0)
            return "";

        var lastBrace = source.lastIndexOf("}");
        var lastBracket = source.lastIndexOf("]");
        var end = -1;
        if (lastBrace >= 0 && lastBracket >= 0)
            end = Math.max(lastBrace, lastBracket);
        else if (lastBrace >= 0)
            end = lastBrace;
        else if (lastBracket >= 0)
            end = lastBracket;

        if (end < start)
            return "";
        return source.slice(start, end + 1);
    }

    function parseCodexbarOutput(rawText) {
        var trimmed = String(rawText || "").trim();
        if (trimmed === "")
            return {
                "ok": false,
                "error": "empty output"
            };

        var parsedFull = root._tryParseJsonValue(trimmed);
        if (parsedFull.ok) {
            return {
                "ok": true,
                "value": parsedFull.value
            };
        }

        var lines = trimmed.split(/\r?\n/);
        var values = [];
        for (var index = 0; index < lines.length; index++) {
            var line = String(lines[index] || "").trim();
            if (line === "")
                continue;

            var parsedLine = root._tryParseJsonValue(line);
            if (parsedLine.ok) {
                values.push(parsedLine.value);
                continue;
            }

            var fragment = root._extractLikelyJsonFragment(line);
            if (fragment === "")
                continue;

            var parsedFrag = root._tryParseJsonValue(fragment);
            if (parsedFrag.ok)
                values.push(parsedFrag.value);
        }

        if (values.length === 0) {
            return {
                "ok": false,
                "error": parsedFull.error ? String(parsedFull.error) : "parse error"
            };
        }

        if (values.length === 1) {
            return {
                "ok": true,
                "value": values[0]
            };
        }

        var merged = [];
        for (var v = 0; v < values.length; v++) {
            var value = values[v];
            if (Array.isArray(value))
                merged = merged.concat(value);
            else
                merged.push(value);
        }

        return {
            "ok": true,
            "value": merged
        };
    }

    Process {
        id: fetchProcess

        property var _command: {
            var script = "codexbar_path=$(command -v codexbar 2>/dev/null) || exit 127; exec \"$codexbar_path\" --format json";
            if (root.shouldFetchStatus)
                script += " --status";
            return ["sh", "-c", script];
        }
        command: _command

        stdout: StdioCollector {
            id: fetchStdout
            onStreamFinished: {
                var rawOutput = String(this.text || "");
                var output = rawOutput.trim();
                if (!output) {
                    root.isRefreshing = false;
                    root._lastFetchHadJson = false;
                    return;
                }

                var parsed = root.parseCodexbarOutput(rawOutput);
                if (!parsed.ok) {
                    root._lastFetchHadJson = false;
                    Logger.e("CodexBar", "Failed to parse JSON: " + parsed.error);
                    root.lastError = pluginApi?.tr("errors.cliParseFailed") || "Failed to parse JSON output";
                } else {
                    root._lastFetchHadJson = true;
                    var data = parsed.value;
                    var providers = Array.isArray(data) ? data : [data];
                    root._handleProviderData(providers);
                }
                root.isRefreshing = false;
            }
        }

        stderr: StdioCollector {
            id: fetchStderr
            onStreamFinished: {
                var err = this.text.trim();
                if (err) {
                    Logger.w("CodexBar", "stderr: " + err);
                    if (!root.lastError)
                        root.lastError = err;
                }
            }
        }

        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0) {
                var stderrText = String(fetchStderr?.text || "").trim();
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
                } else if (root._lastFetchHadJson) {
                    // codexbar may exit non-zero when providers contain errors, but still emit valid JSON.
                    // Prefer rendering provider-level errors in the UI over showing a generic exit code.
                } else if (!root.lastError) {
                    root.lastError = "Exit code " + exitCode;
                }
                Logger.w("CodexBar", "codexbar exited with code " + exitCode);
            } else {
                root._cliMissingNotified = false;
            }
            root.isRefreshing = false;
        }
    }

    function _handleProviderData(providers) {
        var newResets = ({});
        var newUsedPercents = ({});
        var filteredProviders = [];
        var now = Date.now();
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (root.isCliErrorPayload(p)) {
                var cliMessage = String(p.error?.message || "").trim();
                if (cliMessage !== "")
                    root.lastError = cliMessage;
                continue;
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

    property var _lowNotified: ({})

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

    onShouldFetchStatusChanged: {
        if (!root.isRefreshing && Array.isArray(root.providerData) && root.providerData.length > 0)
            root.refresh();
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
