import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  readonly property int refreshIntervalMinutes: cfg.refreshIntervalMinutes ?? defaults.refreshIntervalMinutes ?? 30
  readonly property bool enableNotifications: cfg.enableNotifications ?? defaults.enableNotifications ?? false
  readonly property string terminalCommand: cfg.terminalCommand ?? defaults.terminalCommand ?? ""

  property bool mpmAvailable: false
  property string mpmPath: ""
  property string mpmVersion: ""
  property string mpmErrorMessage: ""

  property var availableManagers: []
  property var unavailableManagers: []
  property var managerResults: []
  property var activeManagerIds: []
  property int totalUpdateCount: 0
  property bool hasUpdates: totalUpdateCount > 0
  property bool isRefreshing: false
  property bool hasError: false
  property string errorMessage: ""
  property double lastCheckedAt: 0
  property double lastSuccessfulCheckedAt: 0

  property int previousSuccessfulUpdateCount: 0
  property bool hasCompletedInitialSuccessfulRefresh: false
  property bool hasShownMissingMpmToast: false
  property bool hasShownBrokenMpmToast: false

  property var managerInfoById: ({})
  property string pendingRefreshReason: ""
  property bool pendingAvailabilityToast: false

  readonly property bool hasLastSuccessfulData: lastSuccessfulCheckedAt > 0
  readonly property bool canRunUpgrade: mpmAvailable && activeManagerIds.length > 0 && terminalCommand.trim() !== ""

  readonly property int minuteMs: 60 * 1000

  Component.onCompleted: {
    Logger.i("MetaPackageManagerTray", "Plugin loaded");
    root.refresh(false, "startup");
  }

  Timer {
    id: refreshTimer
    interval: Math.max(1, root.refreshIntervalMinutes) * root.minuteMs
    running: true
    repeat: true
    onTriggered: root.refresh(false, "timer")
  }

  Process {
    id: availabilityProcess
    command: []
    stdout: StdioCollector { id: availabilityStdout }
    stderr: StdioCollector { id: availabilityStderr }

    onExited: function(exitCode, exitStatus) {
      root.handleAvailabilityResult(
        exitCode,
        String(availabilityStdout.text || ""),
        String(availabilityStderr.text || "")
      );
    }
  }

  Process {
    id: managersProcess
    command: []
    stdout: StdioCollector { id: managersStdout }
    stderr: StdioCollector { id: managersStderr }

    onExited: function(exitCode, exitStatus) {
      root.handleManagersResult(
        exitCode,
        String(managersStdout.text || ""),
        String(managersStderr.text || "")
      );
    }
  }

  Process {
    id: outdatedProcess
    command: []
    stdout: StdioCollector { id: outdatedStdout }
    stderr: StdioCollector { id: outdatedStderr }

    onExited: function(exitCode, exitStatus) {
      root.handleOutdatedResult(
        exitCode,
        String(outdatedStdout.text || ""),
        String(outdatedStderr.text || "")
      );
    }
  }

  IpcHandler {
    target: "plugin:meta-package-manager-tray"

    function refresh() {
      root.refresh(true, "ipc");
    }

    function upgrade() {
      root.upgrade();
    }

    function toggle() {
      if (!pluginApi) return;
      pluginApi.withCurrentScreen(screen => {
        pluginApi.togglePanel(screen);
      });
    }
  }

  function refresh(showAvailabilityToast, reason) {
    if (root.isRefreshing) {
      Logger.d("MetaPackageManagerTray", "Refresh skipped while another refresh is running");
      return;
    }

    root.pendingRefreshReason = reason || "manual";
    root.pendingAvailabilityToast = showAvailabilityToast === true;
    root.isRefreshing = true;
    root.hasError = false;
    root.errorMessage = "";

    availabilityProcess.command = [
      "sh",
      "-c",
      "mpm_path=$(command -v mpm 2>/dev/null) || exit 127; printf '%s\\n' \"$mpm_path\"; mpm --version"
    ];
    availabilityProcess.running = true;
  }

  function manualRefresh() {
    root.refresh(true, "manual");
  }

  function upgrade() {
    root.refreshTimer.restart();

    if (!root.mpmAvailable) {
      root.showAvailabilityWarning(true);
      return;
    }

    if (root.activeManagerIds.length === 0) {
      ToastService.showWarning(
        pluginApi?.tr("plugin.name"),
        pluginApi?.tr("toast.noActiveManagers"),
        "alert-triangle"
      );
      return;
    }

    if (root.terminalCommand.trim() === "") {
      ToastService.showWarning(
        pluginApi?.tr("plugin.name"),
        pluginApi?.tr("toast.terminalMissing"),
        "alert-triangle"
      );
      return;
    }

    var baseCommand = root.buildUpgradeCommand(root.activeManagerIds).join(" ");
    var refreshCommand = "qs -c noctalia-shell ipc call plugin:meta-package-manager-tray refresh";
    var fullCommand = baseCommand + " && " + refreshCommand;
    var terminalWrapped = root.wrapTerminalCommand(fullCommand);

    Logger.i("MetaPackageManagerTray", "Launching upgrade command");
    Quickshell.execDetached(["sh", "-c", terminalWrapped]);
  }

  function handleAvailabilityResult(exitCode, stdoutText, stderrText) {
    var lines = stdoutText.trim().split("\n").filter(function(line) {
      return line.trim() !== "";
    });
    var detectedPath = lines.length > 0 ? lines[0].trim() : "";
    var detectedVersion = lines.length > 1 ? lines.slice(1).join(" ").trim() : "";

    root.mpmPath = detectedPath;
    root.mpmVersion = exitCode === 0 ? detectedVersion : "";

    if (exitCode !== 0) {
      var isBroken = detectedPath !== "";
      root.mpmAvailable = false;
      root.mpmErrorMessage = isBroken
        ? pluginApi?.tr("status.mpmBroken")
        : pluginApi?.tr("status.mpmMissing");

      var detail = String(stderrText || "").trim();
      if (!detail && lines.length > 1) {
        detail = lines.slice(1).join("\n").trim();
      }
      if (detail !== "") {
        root.mpmErrorMessage += "\n" + detail;
      }

      root.hasError = true;
      root.errorMessage = root.mpmErrorMessage;
      root.lastCheckedAt = Date.now();
      root.isRefreshing = false;
      root.showAvailabilityWarning(root.pendingAvailabilityToast);
      return;
    }

    root.mpmAvailable = true;
    root.mpmErrorMessage = "";

    managersProcess.command = [
      "mpm",
      "--output-format", "json",
      "--no-color",
      "--verbosity", "ERROR",
      "managers"
    ];
    managersProcess.running = true;
  }

  function handleManagersResult(exitCode, stdoutText, stderrText) {
    if (exitCode !== 0) {
      root.setCommandFailure("managers", stderrText || stdoutText);
      return;
    }

    var parsed;
    try {
      parsed = JSON.parse(stdoutText || "{}");
    } catch (error) {
      root.setCommandFailure("managers-parse", String(error));
      return;
    }

    var allManagers = [];
    var infoById = {};
    var ids = Object.keys(parsed || {});
    ids.sort();

    for (var i = 0; i < ids.length; i++) {
      var id = ids[i];
      var raw = parsed[id] || {};
      var manager = {
        "id": id,
        "name": raw.name || id,
        "available": raw.available === true,
        "supported": raw.supported !== false,
        "executable": raw.executable === true,
        "fresh": raw.fresh === true,
        "enabled": root.isManagerEnabled(id),
        "active": root.isManagerEnabled(id) && raw.available === true,
        "cliPath": raw.cli_path || "",
        "version": raw.version || "",
        "errors": Array.isArray(raw.errors) ? raw.errors.slice() : []
      };
      allManagers.push(manager);
      infoById[id] = manager;
    }

    allManagers.sort(function(a, b) {
      if (a.available !== b.available) return a.available ? -1 : 1;
      return a.name.localeCompare(b.name);
    });

    root.managerInfoById = infoById;
    root.availableManagers = allManagers.filter(function(manager) {
      return manager.available;
    });
    root.unavailableManagers = allManagers.filter(function(manager) {
      return !manager.available;
    });
    root.activeManagerIds = root.availableManagers
      .filter(function(manager) { return manager.enabled; })
      .map(function(manager) { return manager.id; });

    if (root.activeManagerIds.length === 0) {
      root.managerResults = [];
      root.totalUpdateCount = 0;
      root.hasError = false;
      root.errorMessage = "";
      root.finalizeSuccessfulRefresh(0);
      return;
    }

    outdatedProcess.command = root.buildOutdatedCommand(root.activeManagerIds);
    outdatedProcess.running = true;
  }

  function handleOutdatedResult(exitCode, stdoutText, stderrText) {
    if (exitCode !== 0) {
      root.setCommandFailure("outdated", stderrText || stdoutText);
      return;
    }

    var parsed;
    try {
      parsed = JSON.parse(stdoutText || "{}");
    } catch (error) {
      root.setCommandFailure("outdated-parse", String(error));
      return;
    }

    var results = [];
    var totalCount = 0;
    var managerHadErrors = false;

    for (var i = 0; i < root.activeManagerIds.length; i++) {
      var managerId = root.activeManagerIds[i];
      var raw = parsed[managerId] || {};
      var managerInfo = root.managerInfoById[managerId] || ({
        "id": managerId,
        "name": managerId
      });
      var errors = Array.isArray(raw.errors) ? raw.errors.slice() : [];
      var rawPackages = Array.isArray(raw.packages) ? raw.packages.slice() : [];
      var packages = rawPackages.map(function(pkg) {
        return root.normalizePackage(pkg);
      });

      packages.sort(function(a, b) {
        return a.displayName.localeCompare(b.displayName);
      });

      totalCount += packages.length;
      managerHadErrors = managerHadErrors || errors.length > 0;

      results.push({
        "id": managerId,
        "name": raw.name || managerInfo.name || managerId,
        "packages": packages,
        "packageCount": packages.length,
        "errors": errors,
        "errorCount": errors.length
      });
    }

    results.sort(function(a, b) {
      if (a.packageCount !== b.packageCount) return b.packageCount - a.packageCount;
      if (a.errorCount !== b.errorCount) return b.errorCount - a.errorCount;
      return a.name.localeCompare(b.name);
    });

    root.managerResults = results;
    root.totalUpdateCount = totalCount;
    root.hasError = managerHadErrors;
    root.errorMessage = managerHadErrors ? pluginApi?.tr("status.partialErrors") : "";
    root.finalizeSuccessfulRefresh(totalCount);
  }

  function setCommandFailure(kind, detail) {
    var detailText = String(detail || "").trim();
    var translatedMessage = kind.indexOf("managers") === 0
      ? pluginApi?.tr("status.managersFailed")
      : pluginApi?.tr("status.outdatedFailed");

    if (kind.indexOf("parse") !== -1) {
      translatedMessage = pluginApi?.tr("status.invalidJson");
    }

    root.hasError = true;
    root.errorMessage = translatedMessage + (detailText !== "" ? "\n" + detailText : "");
    root.lastCheckedAt = Date.now();
    root.isRefreshing = false;
    Logger.w("MetaPackageManagerTray", root.errorMessage);
  }

  function finalizeSuccessfulRefresh(totalCount) {
    var now = Date.now();
    var shouldNotify = root.enableNotifications
      && root.hasCompletedInitialSuccessfulRefresh
      && totalCount > root.previousSuccessfulUpdateCount;

    root.lastCheckedAt = now;
    root.lastSuccessfulCheckedAt = now;
    root.previousSuccessfulUpdateCount = totalCount;
    root.hasCompletedInitialSuccessfulRefresh = true;
    root.isRefreshing = false;

    if (shouldNotify) {
      ToastService.showNotice(
        pluginApi?.tr("plugin.name"),
        pluginApi?.tr("toast.updatesAvailable", { "count": totalCount }),
        "package"
      );
    }
  }

  function showAvailabilityWarning(force) {
    if (root.mpmAvailable) return;

    var isBroken = root.mpmPath !== "";
    if (!force) {
      if (!isBroken && root.hasShownMissingMpmToast) return;
      if (isBroken && root.hasShownBrokenMpmToast) return;
    }

    if (isBroken) root.hasShownBrokenMpmToast = true;
    else root.hasShownMissingMpmToast = true;

    ToastService.showWarning(
      pluginApi?.tr("plugin.name"),
      isBroken ? pluginApi?.tr("toast.mpmBroken") : pluginApi?.tr("toast.mpmMissing"),
      "alert-triangle"
    );
  }

  function isManagerEnabled(id) {
    var enabledIds = cfg.enabledManagerIds ?? defaults.enabledManagerIds ?? [];
    return enabledIds.indexOf(id) !== -1;
  }

  function buildManagerSelectorFlags(ids) {
    return ids.map(function(id) {
      return "--" + id;
    });
  }

  function buildOutdatedCommand(ids) {
    return [
      "mpm",
      "--output-format", "json",
      "--no-color",
      "--no-stats",
      "--verbosity", "ERROR",
      "--timeout", "30"
    ].concat(root.buildManagerSelectorFlags(ids)).concat(["outdated"]);
  }

  function buildUpgradeCommand(ids) {
    return [
      "mpm",
      "--verbosity", "INFO",
      "--timeout", "0"
    ].concat(root.buildManagerSelectorFlags(ids)).concat(["upgrade", "--all"]);
  }

  function wrapTerminalCommand(commandText) {
    var template = root.terminalCommand.trim();
    if (template.indexOf("{}") !== -1) {
      return template.replace("{}", commandText);
    }
    return template + " " + root.shellQuote(commandText);
  }

  function shellQuote(text) {
    return "'" + String(text).replace(/'/g, "'\\''") + "'";
  }

  function normalizePackage(pkg) {
    var packageId = String(pkg?.id || "");
    var packageName = String(pkg?.name || "");
    return {
      "id": packageId,
      "displayName": packageName !== "" ? packageName : packageId,
      "installedVersion": String(pkg?.installed_version || ""),
      "latestVersion": String(pkg?.latest_version || "")
    };
  }

  function formatTimestamp(value) {
    if (!value || value <= 0) return pluginApi?.tr("common.never");
    return new Date(value).toLocaleString(Qt.locale().name);
  }
}
