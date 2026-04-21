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

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property int refreshInterval: Math.max(30, Math.min(600, Number(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)))
    readonly property bool notifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    readonly property bool notifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    readonly property int lowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

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

    Process {
        id: fetchProcess

        property var _command: ["sh", "-c", "codexbar_path=$(command -v codexbar 2>/dev/null) || exit 127; exec \"$codexbar_path\" --format json"]
        command: _command

        stdout: StdioCollector {
            id: fetchStdout
            onStreamFinished: {
                var output = this.text.trim();
                if (!output) {
                    root.isRefreshing = false;
                    return;
                }

                try {
                    var data = JSON.parse(output);
                    var providers = Array.isArray(data) ? data : [data];
                    root._handleProviderData(providers);
                } catch (e) {
                    Logger.e("CodexBar", "Failed to parse JSON: " + e.message);
                    root.lastError = e.message;
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
        var now = Date.now();
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            var providerId = String(p.provider || "");
            var primaryResetsAt = p.usage?.primary?.resetsAt || "";
            var primaryUsed = p.usage?.primary?.usedPercent ?? -1;
            var primaryLeft = 100 - primaryUsed;

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
        root.providerData = providers;
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
