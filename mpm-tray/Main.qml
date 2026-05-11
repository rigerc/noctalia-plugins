import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root

    property var pluginApi: null

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property int refreshIntervalMinutes: cfg.refreshIntervalMinutes ?? defaults.refreshIntervalMinutes ?? 30
    readonly property var disabledManagers: cfg.disabledManagers ?? defaults.disabledManagers ?? []
    readonly property string presyncCmd: cfg.presyncCmd ?? defaults.presyncCmd ?? "(checkupdates; paru -Qua) 2>/dev/null; exit 0"
    readonly property bool refreshOnStartup: cfg.refreshOnStartup ?? defaults.refreshOnStartup ?? true

    // Shared state — accessible from BarWidget/Panel/Settings via pluginApi.mainInstance
    property bool mpmAvailable: false
    property string mpmPath: ""
    property string mpmVersion: ""

    property var allManagers: []
    property var availableManagers: []
    property var unavailableManagers: []
    property var activeManagerIds: []
    property bool managersLoaded: false

    property var managerResults: []
    property int totalUpdateCount: 0
    property bool isRefreshing: false
    property bool hasError: false
    property string errorMessage: ""
    property double lastCheckedAt: 0

    Component.onCompleted: {
        if (root.refreshOnStartup)
            root.refresh("startup");
    }

    Timer {
        id: refreshTimer
        interval: Math.max(1, root.refreshIntervalMinutes) * 60000
        running: true
        repeat: true
        onTriggered: root.refresh("timer")
    }

    // Abort the whole chain if it takes longer than 2 minutes
    Timer {
        id: refreshTimeout
        interval: 120000
        repeat: false
        onTriggered: {
            availabilityProcess.running = false;
            managersProcess.running = false;
            presyncProcess.running = false;
            outdatedProcess.running = false;
            root.hasError = true;
            root.errorMessage = "Refresh timed out";
            root.isRefreshing = false;
            Logger.w("MpmTray", "Refresh timed out after 120s");
        }
    }

    // ── Process 1: check mpm availability ────────────────────────────────────

    Process {
        id: availabilityProcess

        stdout: StdioCollector { id: avStdout }
        stderr: StdioCollector { id: avStderr }

        // qmllint disable signal-handler-parameters
        onExited: function (exitCode) {
            var out = String(avStdout.text || "").trim();
            if (exitCode === 127 || exitCode !== 0) {
                refreshTimeout.stop();
                root.mpmAvailable = false;
                root.errorMessage = exitCode === 127 ? "mpm not found in PATH" : ("mpm exited " + exitCode + ": " + String(avStderr.text || "").trim());
                root.isRefreshing = false;
                Logger.w("MpmTray", "mpm not available:", root.errorMessage);
                return;
            }
            var lines = out.split("\n");
            root.mpmPath = String(lines[0] || "").trim();
            root.mpmVersion = String(lines[1] || "").trim().replace(/^mpm[, ]+version[, ]+/i, "").replace(/^v/, "");
            root.mpmAvailable = true;
            Logger.i("MpmTray", "mpm found at", root.mpmPath, "version", root.mpmVersion);
            managersProcess.command = ["mpm", "--table-format", "json", "--no-color", "managers"];
            managersProcess.running = true;
        }
        // qmllint enable signal-handler-parameters
    }

    // ── Process 2: list managers ──────────────────────────────────────────────

    Process {
        id: managersProcess

        stdout: StdioCollector { id: mgStdout }
        stderr: StdioCollector { id: mgStderr }

        // qmllint disable signal-handler-parameters
        onExited: function (exitCode) {
            if (exitCode !== 0) {
                refreshTimeout.stop();
                root.hasError = true;
                root.errorMessage = String(mgStderr.text || "").trim() || ("mpm managers exited " + exitCode);
                root.isRefreshing = false;
                Logger.e("MpmTray", "managers failed:", root.errorMessage);
                return;
            }

            var jsonText = root.extractJson(String(mgStdout.text || ""));
            if (!jsonText) {
                refreshTimeout.stop();
                root.hasError = true;
                root.errorMessage = "mpm managers returned no JSON";
                root.isRefreshing = false;
                Logger.e("MpmTray", root.errorMessage);
                return;
            }

            try {
                var data = JSON.parse(jsonText);
                var keys = Object.keys(data);
                var all = [], avail = [], unavail = [];
                for (var i = 0; i < keys.length; i++) {
                    var id = keys[i];
                    var m = data[id];
                    var entry = { "id": id, "name": String(m.name || id) };
                    var isAvail = m.available === true || m.executable === true;
                    entry["available"] = isAvail;
                    all.push(entry);
                    if (isAvail)
                        avail.push(entry);
                    else
                        unavail.push(entry);
                }
                root.allManagers = all;
                root.availableManagers = avail;
                root.unavailableManagers = unavail;
                root.managersLoaded = true;

                var active = [];
                for (var j = 0; j < avail.length; j++) {
                    if (root.disabledManagers.indexOf(avail[j].id) === -1)
                        active.push(avail[j].id);
                }
                root.activeManagerIds = active;

                if (active.length === 0) {
                    refreshTimeout.stop();
                    root.managerResults = [];
                    root.totalUpdateCount = 0;
                    root.hasError = false;
                    root.isRefreshing = false;
                    root.lastCheckedAt = Date.now();
                    Logger.i("MpmTray", "No active managers, skipping outdated");
                    return;
                }

                root.runPresyncOrOutdated();
            } catch (e) {
                refreshTimeout.stop();
                root.hasError = true;
                root.errorMessage = "JSON parse error (managers): " + e;
                root.isRefreshing = false;
                Logger.e("MpmTray", root.errorMessage);
            }
        }
        // qmllint enable signal-handler-parameters
    }

    // ── Process 3: presync (optional, configurable) ───────────────────────────

    Process {
        id: presyncProcess

        stderr: StdioCollector { id: presyncStderr }

        // qmllint disable signal-handler-parameters
        onExited: function (exitCode) {
            if (exitCode !== 0)
                Logger.d("MpmTray", "presync finished with code", exitCode, "(non-fatal)");
            else
                Logger.i("MpmTray", "presync completed");

            outdatedProcess.command = ["mpm", "--table-format", "json", "--no-color", "outdated"];
            outdatedProcess.running = true;
        }
        // qmllint enable signal-handler-parameters
    }

    // ── Process 4: list outdated packages ────────────────────────────────────

    Process {
        id: outdatedProcess

        stdout: StdioCollector { id: outStdout }
        stderr: StdioCollector { id: outStderr }

        // qmllint disable signal-handler-parameters
        onExited: function (exitCode) {
            refreshTimeout.stop();

            if (exitCode !== 0) {
                root.hasError = true;
                root.errorMessage = String(outStderr.text || "").trim() || ("mpm outdated exited " + exitCode);
                root.isRefreshing = false;
                Logger.e("MpmTray", "outdated failed:", root.errorMessage);
                return;
            }

            var jsonText = root.extractJson(String(outStdout.text || ""));
            if (!jsonText) {
                root.managerResults = [];
                root.totalUpdateCount = 0;
                root.hasError = false;
                root.isRefreshing = false;
                root.lastCheckedAt = Date.now();
                Logger.i("MpmTray", "No outdated packages found (no JSON output)");
                return;
            }

            try {
                var data = JSON.parse(jsonText);
                var keys = Object.keys(data);
                var results = [];
                var total = 0;

                for (var i = 0; i < keys.length; i++) {
                    var managerId = keys[i];
                    if (root.disabledManagers.indexOf(managerId) !== -1)
                        continue;
                    var m = data[managerId];
                    var packages = Array.isArray(m.packages) ? m.packages : [];
                    var errors = Array.isArray(m.errors) ? m.errors : [];
                    var normalizedPkgs = packages.map(pkg => root.normalizePackage(pkg));
                    total += normalizedPkgs.length;
                    results.push({
                        "id": managerId,
                        "name": String(m.name || managerId),
                        "packages": normalizedPkgs,
                        "packageCount": normalizedPkgs.length,
                        "errors": errors,
                        "errorCount": errors.length
                    });
                }

                root.managerResults = results;
                root.totalUpdateCount = total;
                root.hasError = false;
                root.isRefreshing = false;
                root.lastCheckedAt = Date.now();
                Logger.i("MpmTray", "Found", total, "updates across", results.length, "managers");
            } catch (e) {
                root.hasError = true;
                root.errorMessage = "JSON parse error (outdated): " + e;
                root.isRefreshing = false;
                Logger.e("MpmTray", root.errorMessage);
            }
        }
        // qmllint enable signal-handler-parameters
    }

    // ── IPC ───────────────────────────────────────────────────────────────────

    IpcHandler {
        target: "plugin:mpm-tray"

        function refresh(): void {
            root.refresh("ipc");
        }

        function toggle(): void {
            if (!root.pluginApi)
                return;
            root.pluginApi.withCurrentScreen(s => {
                root.pluginApi.togglePanel(s);
            });
        }
    }

    // ── Public functions ──────────────────────────────────────────────────────

    function refresh(reason) {
        if (root.isRefreshing)
            return;
        Logger.d("MpmTray", "Refresh triggered by:", reason);
        root.isRefreshing = true;
        root.hasError = false;
        root.errorMessage = "";
        refreshTimeout.restart();

        var needsManagers = !root.managersLoaded || reason === "startup" || reason === "settings";
        if (needsManagers) {
            availabilityProcess.command = ["sh", "-c",
                "p=$(command -v mpm 2>/dev/null) || exit 127; printf '%s\\n' \"$p\"; mpm --version 2>&1 | head -1"];
            availabilityProcess.running = true;
        } else {
            root.runPresyncOrOutdated();
        }
    }

    function runPresyncOrOutdated() {
        var cmd = String(root.presyncCmd || "").trim();
        if (cmd !== "") {
            presyncProcess.command = ["sh", "-c", cmd];
            presyncProcess.running = true;
            Logger.i("MpmTray", "Running presync");
        } else {
            outdatedProcess.command = ["mpm", "--table-format", "json", "--no-color", "outdated"];
            outdatedProcess.running = true;
            Logger.i("MpmTray", "Skipping presync (empty command)");
        }
    }

    function extractJson(text) {
        var start = text.indexOf("{");
        if (start < 0)
            return "";
        var depth = 0;
        for (var i = start; i < text.length; i++) {
            if (text[i] === "{")
                depth++;
            else if (text[i] === "}")
                depth--;
            if (depth === 0)
                return text.substring(start, i + 1);
        }
        return "";
    }

    function normalizePackage(pkg) {
        return {
            "id": String(pkg.id || ""),
            "displayName": String(pkg.name || pkg.id || ""),
            "installedVersion": String(pkg.installed_version || ""),
            "latestVersion": String(pkg.latest_version || "")
        };
    }

    function isManagerEnabled(id) {
        return root.disabledManagers.indexOf(id) === -1;
    }

    function formatTimestamp(value) {
        if (!value || value === 0)
            return pluginApi?.tr("common.never") ?? "Never";
        return new Date(value).toLocaleTimeString();
    }
}
