import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Niri
import qs.Commons
import qs.Services.Compositor

Item {
    id: root

    property var pluginApi: null

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    function settingValue(groupKey, nestedKey, legacyKey, fallbackValue) {
        const configGroup = cfg ? cfg[groupKey] : undefined;
        const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
        if (nestedConfig !== undefined)
            return nestedConfig;

        const legacyConfig = cfg ? cfg[legacyKey] : undefined;
        if (legacyConfig !== undefined)
            return legacyConfig;

        const defaultsGroup = defaults ? defaults[groupKey] : undefined;
        const nestedDefault = defaultsGroup ? defaultsGroup[nestedKey] : undefined;
        if (nestedDefault !== undefined)
            return nestedDefault;

        const legacyDefault = defaults ? defaults[legacyKey] : undefined;
        if (legacyDefault !== undefined)
            return legacyDefault;

        return fallbackValue;
    }

    readonly property bool debugLogging: settingValue("advanced", "debugLogging", "debugLogging", false)
    readonly property bool supportsLiveReorder: CompositorService.isNiri || CompositorService.isHyprland

    property var allEntries: []
    property var liveEntriesByKey: ({})
    property string activeEntryKey: ""
    property int structureRevision: 0
    property int liveRevision: 0

    property bool pendingStructuralRefresh: false
    property string lastStructureSignature: ""
    property string lastTitleSignature: ""
    property var pendingLiveEntriesByKey: null

    function debugLog(message) {
        if (debugLogging)
            Logger.d("Scrollbar", message);
    }

    function getAppNameFromDesktopEntry(appId) {
        if (!appId)
            return "";

        try {
            if (typeof DesktopEntries !== "undefined" && DesktopEntries.heuristicLookup) {
                const heuristicEntry = DesktopEntries.heuristicLookup(appId);
                if (heuristicEntry?.name)
                    return heuristicEntry.name;
            }

            if (typeof DesktopEntries !== "undefined" && DesktopEntries.byId) {
                const directEntry = DesktopEntries.byId(appId);
                if (directEntry?.name)
                    return directEntry.name;
            }
        } catch (error) {
        }

        return appId;
    }

    function getWindowKey(window) {
        if (!window)
            return "";
        if (window.id !== undefined && window.id !== null)
            return "backend:" + String(window.id);
        if (window.address !== undefined && window.address !== null && String(window.address) !== "")
            return "address:" + String(window.address);
        if (window.pid !== undefined && window.pid !== null)
            return "pid:" + String(window.pid) + ":" + String(window.workspaceId ?? "") + ":" + String(window.appId ?? "");
        return "fallback:" + String(window.workspaceId ?? "") + ":" + String(window.output ?? "") + ":" + String(window.appId ?? "");
    }

    function getActiveWorkspaceIds() {
        try {
            return CompositorService.getActiveWorkspaces().map(function (workspace) {
                return workspace.id;
            });
        } catch (error) {
            return [];
        }
    }

    function collectWindows() {
        const windows = [];

        try {
            const total = CompositorService.windows?.count || 0;
            for (let i = 0; i < total; i++) {
                const window = CompositorService.windows.get(i);
                if (window)
                    windows.push(window);
            }
        } catch (error) {
        }

        return windows;
    }

    function buildStructuralEntries(windows) {
        return (windows || []).map(function (window) {
            return {
                "id": window.id,
                "entryKey": getWindowKey(window),
                "appId": window.appId || "",
                "fallbackTitle": window.title || getAppNameFromDesktopEntry(window.appId),
                "output": window.output || "",
                "workspaceId": window.workspaceId
            };
        });
    }

    function buildLiveEntries(entries, windows) {
        const windowsByKey = ({});
        const liveEntries = ({});

        (windows || []).forEach(function (window) {
            const key = getWindowKey(window);
            if (key)
                windowsByKey[key] = window;
        });

        (entries || []).forEach(function (entry) {
            const window = windowsByKey[entry.entryKey] || null;
            liveEntries[entry.entryKey] = {
                "id": window?.id ?? entry.id ?? "",
                "title": window?.title || entry.fallbackTitle || "",
                "isFocused": !!window?.isFocused
            };
        });

        return liveEntries;
    }

    function getStructureSignature(entries) {
        return (entries || []).map(function (entry) {
            return entry.entryKey;
        }).join("||");
    }

    function getTitleSignature(entries, liveEntries) {
        return (entries || []).map(function (entry) {
            const liveEntry = liveEntries ? liveEntries[entry.entryKey] : undefined;
            return entry.entryKey + "|" + (liveEntry?.title || "");
        }).join("||");
    }

    function getFocusedEntryKey(entries) {
        const source = entries || ({});
        for (const entryKey in source) {
            if (source[entryKey]?.isFocused)
                return entryKey;
        }
        return "";
    }

    function applyStructuralEntries(entries, reason) {
        allEntries = entries || [];
        lastStructureSignature = getStructureSignature(allEntries);
        structureRevision += 1;
        debugLog("applyStructuralEntries(" + (reason || "unknown") + "): windows=" + allEntries.length);
    }

    function applyLiveEntries(entries, reason) {
        liveEntriesByKey = entries || ({});
        activeEntryKey = getFocusedEntryKey(liveEntriesByKey);
        lastTitleSignature = getTitleSignature(allEntries, liveEntriesByKey);
        liveRevision += 1;
        debugLog("applyLiveEntries(" + (reason || "unknown") + "): focus=" + activeEntryKey + " windows=" + allEntries.length);
    }

    function flushPendingTitleUpdates(reason) {
        if (!pendingLiveEntriesByKey)
            return;

        const windows = collectWindows();
        const nextLiveEntries = buildLiveEntries(allEntries, windows);
        pendingLiveEntriesByKey = null;
        applyLiveEntries(nextLiveEntries, reason || "title-debounce");
    }

    function updateSnapshots(reason, forceStructural) {
        const windows = collectWindows();
        const nextEntries = buildStructuralEntries(windows);
        const nextStructureSignature = getStructureSignature(nextEntries);
        const structuralChanged = (forceStructural === true) || pendingStructuralRefresh || nextStructureSignature !== lastStructureSignature;

        pendingStructuralRefresh = false;

        if (structuralChanged)
            applyStructuralEntries(nextEntries, reason);

        const effectiveEntries = structuralChanged ? nextEntries : allEntries;
        const nextLiveEntries = buildLiveEntries(effectiveEntries, windows);
        const nextTitleSignature = getTitleSignature(effectiveEntries, nextLiveEntries);
        const nextFocusedEntryKey = getFocusedEntryKey(nextLiveEntries);
        const focusChanged = nextFocusedEntryKey !== activeEntryKey;
        const titleChanged = nextTitleSignature !== lastTitleSignature;

        if (structuralChanged || focusChanged || Object.keys(liveEntriesByKey).length === 0) {
            pendingLiveEntriesByKey = null;
            titleRefreshDebounce.stop();
            applyLiveEntries(nextLiveEntries, reason);
            return;
        }

        if (titleChanged) {
            pendingLiveEntriesByKey = nextLiveEntries;
            titleRefreshDebounce.restart();
        }
    }

    function scheduleStructuralRefresh(reason) {
        pendingStructuralRefresh = true;
        debugLog("scheduleStructuralRefresh(" + (reason || "unknown") + ")");
        structuralRefreshDebounce.restart();
    }

    function getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces) {
        const activeWorkspaceIds = onlyActiveWorkspaces ? getActiveWorkspaceIds() : [];
        return allEntries.filter(function (entry) {
            const outputMatch = (!onlySameOutput) || !screenName || entry.output === screenName;
            const workspaceMatch = (!onlyActiveWorkspaces) || activeWorkspaceIds.includes(entry.workspaceId);
            return outputMatch && workspaceMatch;
        });
    }

    function getWindowByEntry(entryKey) {
        const windows = collectWindows();
        for (let i = 0; i < windows.length; i++) {
            const window = windows[i];
            if (getWindowKey(window) === entryKey)
                return window;
        }
        return null;
    }

    function focusEntry(entryKey) {
        const window = getWindowByEntry(entryKey);
        if (!window)
            return;

        try {
            debugLog("focusEntry(" + entryKey + ")");
            CompositorService.focusWindow(window);
        } catch (error) {
            Logger.e("Scrollbar", "Failed to focus window: " + error);
        }
    }

    function closeEntry(entryKey) {
        const window = getWindowByEntry(entryKey);
        if (!window)
            return;

        try {
            debugLog("closeEntry(" + entryKey + ")");
            CompositorService.closeWindow(window);
        } catch (error) {
            Logger.e("Scrollbar", "Failed to close window: " + error);
        }
    }

    function getHyprlandAddressSelector(window) {
        if (!window || window.id === undefined || window.id === null)
            return "";
        const rawId = String(window.id).trim();
        if (rawId.length === 0)
            return "";
        return rawId.startsWith("0x") ? ("address:" + rawId) : ("address:0x" + rawId);
    }

    function focusWindowByBackend(window) {
        if (!window)
            return false;

        try {
            if (CompositorService.isNiri) {
                Niri.dispatch(["focus-window", "--id", String(window.id)]);
                return true;
            }

            if (CompositorService.isHyprland) {
                const selector = getHyprlandAddressSelector(window);
                if (!selector)
                    return false;
                Hyprland.dispatch("focuswindow " + selector);
                return true;
            }
        } catch (error) {
            Logger.e("Scrollbar", "Failed backend focus: " + error);
        }

        return false;
    }

    function reorderFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces, fromEntryKey, toEntryKey) {
        if (!supportsLiveReorder || !fromEntryKey || !toEntryKey || fromEntryKey === toEntryKey)
            return;

        const sourceWindow = getWindowByEntry(fromEntryKey);
        const targetWindow = getWindowByEntry(toEntryKey);
        if (!sourceWindow || !targetWindow)
            return;

        const filteredEntries = getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
        const previousFocused = CompositorService.getFocusedWindow ? CompositorService.getFocusedWindow() : null;
        if (!focusWindowByBackend(sourceWindow))
            return;

        debugLog("reorderFilteredEntries(" + fromEntryKey + " -> " + toEntryKey + ")");

        try {
            if (CompositorService.isNiri) {
                let targetIndex = 1;
                for (let i = 0; i < filteredEntries.length; i++) {
                    if (filteredEntries[i].entryKey === toEntryKey) {
                        targetIndex = i + 1;
                        break;
                    }
                }
                Niri.dispatch(["move-column-to-index", String(targetIndex)]);
            } else if (CompositorService.isHyprland) {
                const selector = getHyprlandAddressSelector(targetWindow);
                if (!selector)
                    return;
                Hyprland.dispatch("swapwindow " + selector);
            }
        } catch (error) {
            Logger.e("Scrollbar", "Failed live reorder: " + error);
        }

        if (previousFocused && previousFocused.id != sourceWindow.id) {
            Qt.callLater(function () {
                focusWindowByBackend(previousFocused);
            });
        }

        Qt.callLater(function () {
            updateSnapshots("reorder", true);
        });
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            updateSnapshots("init", true);
        });
    }

    Connections {
        target: CompositorService

        function onWindowListChanged() {
            scheduleStructuralRefresh("windowListChanged");
        }

        function onWorkspaceChanged() {
            scheduleStructuralRefresh("workspaceChanged");
        }

        function onActiveWindowChanged() {
            updateSnapshots("activeWindowChanged", pendingStructuralRefresh);
        }
    }

    Timer {
        id: structuralRefreshDebounce
        interval: 60
        repeat: false
        onTriggered: {
            updateSnapshots("structural-debounce", false);
        }
    }

    Timer {
        id: titleRefreshDebounce
        interval: 150
        repeat: false
        onTriggered: {
            flushPendingTitleUpdates("title-debounce");
        }
    }
}
