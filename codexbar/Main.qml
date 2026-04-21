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

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property int refreshInterval: Math.max(30, Math.min(600, Number(cfg.refreshInterval ?? defaults.refreshInterval ?? 120)))
    readonly property bool notifyOnReset: cfg.notifyOnReset ?? defaults.notifyOnReset ?? true
    readonly property bool notifyOnLowUsage: cfg.notifyOnLowUsage ?? defaults.notifyOnLowUsage ?? true
    readonly property int lowUsageThreshold: Math.max(5, Math.min(50, Number(cfg.lowUsageThreshold ?? defaults.lowUsageThreshold ?? 20)))

    function providerIcon(providerId) {
        switch (String(providerId || "")) {
        case "codex":
            return "mdi:robot-outline";
        case "claude":
            return "mdi:sparkles";
        case "kilo":
            return "mdi:lightning-bolt";
        case "gemini":
            return "mdi:star-four-points";
        case "copilot":
            return "mdi:github";
        default:
            return "mdi:robot";
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

    Process {
        id: fetchProcess

        property var _command: ["codexbar", "--format", "json"]
        command: _command

        stdout: StdioCollector {
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
            onStreamFinished: {
                var err = this.text.trim();
                if (err)
                    Logger.w("CodexBar", "stderr: " + err);
            }
        }

        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.lastError = "Exit code " + exitCode;
                Logger.w("CodexBar", "codexbar exited with code " + exitCode);
            }
            root.isRefreshing = false;
        }
    }

    function _handleProviderData(providers) {
        var newResets = ({});
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            var providerId = String(p.provider || "");
            var primaryResetsAt = p.usage?.primary?.resetsAt || "";
            var primaryUsed = p.usage?.primary?.usedPercent ?? -1;
            var primaryLeft = 100 - primaryUsed;

            if (primaryResetsAt) {
                var prevReset = root.previousResets[providerId];
                if (prevReset && prevReset !== primaryResetsAt && root.notifyOnReset) {
                    ToastService.showNotice(
                        pluginApi?.tr("notifications.resetTitle"),
                        pluginApi?.tr("notifications.resetBody").replace("{provider}", root.providerDisplayName(providerId)),
                        "mdi:sparkles"
                    );
                }
                newResets[providerId] = primaryResetsAt;
            }

            if (primaryLeft >= 0 && primaryLeft <= root.lowUsageThreshold && root.notifyOnLowUsage) {
                var notifKey = providerId + "_low_" + (new Date(primaryResetsAt || Date.now())).toDateString();
                if (!root._lowNotified || !root._lowNotified[notifKey]) {
                    if (!root._lowNotified)
                        root._lowNotified = ({});
                    root._lowNotified[notifKey] = true;
                    ToastService.showNotice(
                        pluginApi?.tr("notifications.lowTitle"),
                        pluginApi?.tr("notifications.lowBody").replace("{provider}", root.providerDisplayName(providerId)).replace("{percent}", String(Math.round(primaryLeft))),
                        "mdi:bell-outline"
                    );
                }
            }
        }

        root.previousResets = newResets;
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
