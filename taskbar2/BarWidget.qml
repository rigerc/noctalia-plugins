import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services.Compositor
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import "FocusTransitionStyle.js" as FocusTransitionStyle

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen

    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
    readonly property real barHeight: Style.getBarHeightForScreen(screenName)
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    property bool hasWindow: false
    readonly property string hideMode: cfg.hideMode ?? defaults.hideMode ?? "hidden"
    readonly property bool onlySameOutput: cfg.onlySameOutput ?? defaults.onlySameOutput ?? true
    readonly property bool onlyActiveWorkspaces: cfg.onlyActiveWorkspaces ?? defaults.onlyActiveWorkspaces ?? true
    readonly property bool showTitle: isVerticalBar ? false : (cfg.showTitle ?? defaults.showTitle ?? false)
    readonly property bool smartWidth: cfg.smartWidth ?? defaults.smartWidth ?? true
    readonly property int maxTaskbarWidthPercent: cfg.maxTaskbarWidth ?? defaults.maxTaskbarWidth ?? 40
    readonly property bool colorizeIcons: cfg.colorizeIcons ?? defaults.colorizeIcons ?? false
    readonly property real iconScale: cfg.iconScale ?? defaults.iconScale ?? 0.8
    readonly property real hoverIconScaleMultiplier: cfg.hoverIconScaleMultiplier ?? defaults.hoverIconScaleMultiplier ?? 1.0
    readonly property real hoverItemScalePercent: cfg.hoverItemScalePercent ?? defaults.hoverItemScalePercent ?? 0
    readonly property int itemGapUnits: cfg.itemGapUnits ?? defaults.itemGapUnits ?? 2
    readonly property int itemGap: Math.max(0, Math.round(itemGapUnits * Style.uiScaleRatio))
    readonly property string titleFontFamily: cfg.titleFontFamily ?? defaults.titleFontFamily ?? ""
    readonly property real titleFontScale: cfg.titleFontScale ?? defaults.titleFontScale ?? 1.0
    readonly property string titleFontWeight: cfg.titleFontWeight ?? defaults.titleFontWeight ?? "medium"
    readonly property var itemColors: cfg.itemColors ?? defaults.itemColors ?? ({})
    readonly property bool showPinnedApps: cfg.showPinnedApps ?? defaults.showPinnedApps ?? true
    readonly property bool groupApps: cfg.groupApps ?? defaults.groupApps ?? false
    readonly property string groupClickAction: cfg.groupClickAction ?? defaults.groupClickAction ?? "cycle"
    readonly property string groupContextMenuMode: cfg.groupContextMenuMode ?? defaults.groupContextMenuMode ?? "extended"
    readonly property string groupIndicatorStyle: cfg.groupIndicatorStyle ?? defaults.groupIndicatorStyle ?? "number"
    readonly property bool groupByWorkspaceIndex: cfg.groupByWorkspaceIndex ?? defaults.groupByWorkspaceIndex ?? false
    readonly property bool showWorkspaceSeparators: cfg.showWorkspaceSeparators ?? defaults.showWorkspaceSeparators ?? true
    readonly property bool workspaceSeparatorShowLabel: cfg.workspaceSeparatorShowLabel ?? defaults.workspaceSeparatorShowLabel ?? true
    readonly property bool workspaceSeparatorShowDivider: cfg.workspaceSeparatorShowDivider ?? defaults.workspaceSeparatorShowDivider ?? true
    readonly property string workspaceSeparatorPrefix: cfg.workspaceSeparatorPrefix ?? defaults.workspaceSeparatorPrefix ?? ""
    readonly property string workspaceSeparatorSuffix: cfg.workspaceSeparatorSuffix ?? defaults.workspaceSeparatorSuffix ?? ""
    readonly property string workspaceSeparatorDividerMode: cfg.workspaceSeparatorDividerMode ?? defaults.workspaceSeparatorDividerMode ?? "line"
    readonly property string workspaceSeparatorDividerChar: cfg.workspaceSeparatorDividerChar ?? defaults.workspaceSeparatorDividerChar ?? "|"
    readonly property string workspaceSeparatorDividerIcon: cfg.workspaceSeparatorDividerIcon ?? defaults.workspaceSeparatorDividerIcon ?? "minus"
    readonly property bool workspaceSeparatorShowForFirst: cfg.workspaceSeparatorShowForFirst ?? defaults.workspaceSeparatorShowForFirst ?? false
    readonly property bool focusTransitionEnabled: cfg.focusTransitionEnabled ?? defaults.focusTransitionEnabled ?? true
    readonly property int focusTransitionDelayMs: Math.max(0, cfg.focusTransitionDelayMs ?? defaults.focusTransitionDelayMs ?? 120)
    readonly property int focusTransitionDurationMs: Math.max(0, cfg.focusTransitionDurationMs ?? defaults.focusTransitionDurationMs ?? 220)
    readonly property string focusTransitionStyle: cfg.focusTransitionStyle ?? defaults.focusTransitionStyle ?? "soft-comet"
    readonly property int focusTransitionIntensity: Math.max(0, Math.min(100, cfg.focusTransitionIntensity ?? defaults.focusTransitionIntensity ?? 60))
    readonly property real focusTransitionThickness: Math.max(2, cfg.focusTransitionThickness ?? defaults.focusTransitionThickness ?? 6)
    readonly property real focusTransitionMarkerScale: Math.max(0.5, cfg.focusTransitionMarkerScale ?? defaults.focusTransitionMarkerScale ?? 1.4)
    readonly property string focusTransitionColorKey: cfg.focusTransitionColor ?? defaults.focusTransitionColor ?? "primary"
    readonly property string focusTransitionGlowColorKey: cfg.focusTransitionGlowColor ?? defaults.focusTransitionGlowColor ?? "primary"
    readonly property real focusTransitionBlur: Math.max(0, cfg.focusTransitionBlur ?? defaults.focusTransitionBlur ?? 6)
    readonly property int focusTransitionTransparency: Math.max(0, Math.min(90, cfg.focusTransitionTransparency ?? defaults.focusTransitionTransparency ?? 15))
    readonly property real focusTransitionIntensityRatio: focusTransitionIntensity / 100
    readonly property real focusTransitionOpacityRatio: 1 - (focusTransitionTransparency / 100)
    readonly property bool workspaceGroupingActive: groupByWorkspaceIndex && !onlyActiveWorkspaces
    readonly property int itemSize: Style.toOdd(capsuleHeight * Math.max(0.1, iconScale))
    readonly property int appEntryCount: getAppEntries(combinedModel).length

    readonly property real maxTaskbarWidth: {
        if (!screen || isVerticalBar || !smartWidth || maxTaskbarWidthPercent <= 0)
            return 0;
        var barFloating = Settings.data.bar.barType === "floating";
        var barMarginH = barFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        var availableWidth = screen.width - (barMarginH * 2);
        return Math.round(availableWidth * (maxTaskbarWidthPercent / 100));
    }

    readonly property int titleWidth: {
        var calculatedWidth = cfg.titleWidth ?? defaults.titleWidth ?? 120;

        if (smartWidth && appEntryCount > 0) {
            if (maxTaskbarWidth > 0) {
                var entriesCount = appEntryCount;
                var maxWidthPerEntry = (maxTaskbarWidth / entriesCount) - itemSize - Style.marginS - Style.margin2M;
                calculatedWidth = Math.min(calculatedWidth, maxWidthPerEntry);
            }

            calculatedWidth = Math.max(Math.round(calculatedWidth), 20);
        }

        return calculatedWidth;
    }

    property var hoveredEntryKey: ""
    property var combinedModel: []
    property var sessionAppOrder: []
    property var groupCycleIndices: ({})
    property var liveEntriesByKey: ({})
    property var stableWindowKeyEntries: []
    property int stableWindowKeyCounter: 0

    property int wheelAccumulatedDelta: 0
    property bool wheelCooldown: false
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1

    property string selectedAppId: ""
    property string selectedEntryKey: ""
    property string selectedMenuMode: ""
    property bool pendingModelRefresh: false
    property bool pendingForceStructuralRefresh: false
    property int modelUpdateTrigger: 0
    property int liveDataRevision: 0
    property var entryIndicatorRectsByKey: ({})
    property bool focusTrackingInitialized: false
    property string lastFocusedEntryKey: ""
    property string currentFocusedEntryKey: ""
    property string pendingFocusTransitionStartKey: ""
    property string pendingFocusTransitionEndKey: ""
    property bool focusTravelActive: false
    property real focusTravelAxisPosition: 0
    property real focusTravelCrossPosition: 0
    property real focusTravelLength: 0
    property real focusTravelThickness: 0
    property real focusTravelStartCenterAxis: 0
    property real focusTravelOpacity: 0
    property real focusTravelTrailStrength: 0
    property real focusTravelGlowStrength: 0
    property real focusTravelBloomOpacity: 0
    property real focusTravelBloomScale: 1
    property real focusTravelDirectionSign: 1
    property string focusTravelLeadShape: "pill"
    property string focusTravelTrailShape: "none"
    property int focusTravelTrailingPieces: 0
    property real focusTravelTrailingGap: 0
    property real focusTravelTrailingMainRatio: 0.7
    property real focusTravelTrailingCrossRatio: 0.7
    property real focusTravelTrailingOpacityFalloff: 0.2
    property real focusTravelTrailingScaleFalloff: 0.14
    property real focusTravelRibbonStrength: 0
    property real focusTravelHaloStrength: 0
    property var focusTravelStartRect: null
    property var focusTravelEndRect: null
    readonly property real focusTravelMarkerCenterAxis: focusTravelAxisPosition + (focusTravelLength / 2)
    readonly property real focusTravelTrailStartAxis: Math.min(focusTravelStartCenterAxis, focusTravelMarkerCenterAxis)
    readonly property real focusTravelTrailExtent: Math.max(0, Math.abs(focusTravelMarkerCenterAxis - focusTravelStartCenterAxis))

    function titleFontFamilyValue() {
        return titleFontFamily && titleFontFamily.length > 0 ? titleFontFamily : Settings.data.ui.fontDefault;
    }

    function titleFontWeightValue() {
        switch (titleFontWeight) {
        case "regular":
            return Style.fontWeightRegular;
        case "semibold":
            return Style.fontWeightSemiBold;
        case "bold":
            return Style.fontWeightBold;
        default:
            return Style.fontWeightMedium;
        }
    }

    function fallbackItemStateColor(stateKey, colorRole) {
        if (colorRole === "border")
            return "transparent";

        if (colorRole === "text")
            return (stateKey === "hovered" || stateKey === "focused") ? Color.mOnHover : Color.mOnSurface;

        return (stateKey === "hovered" || stateKey === "focused") ? Color.mHover : Style.capsuleColor;
    }

    function resolveItemStateColor(stateKey, colorRole) {
        const stateColors = itemColors?.[stateKey];
        const colorKey = stateColors ? stateColors[colorRole] : "none";
        if (!colorKey || colorKey === "none")
            return fallbackItemStateColor(stateKey, colorRole);
        if (colorRole === "text")
            return Color.resolveColorKey(colorKey);
        return Color.resolveColorKeyOptional(colorKey);
    }

    function resolveFocusTransitionColor(colorKey, fallbackColor) {
        if (!colorKey || colorKey === "none")
            return fallbackColor;
        return Color.resolveColorKey(colorKey);
    }

    function normalizeAppId(appId) {
        if (!appId || typeof appId !== "string")
            return "";
        let id = appId.toLowerCase().trim();
        if (id.endsWith(".desktop"))
            id = id.substring(0, id.length - 8);
        return id;
    }

    function getWindowHandle(window) {
        if (!window)
            return null;
        if (window.handle)
            return window.handle;
        if (window.toplevel)
            return window.toplevel;
        return null;
    }

    function getStableWindowKey(window) {
        if (!window)
            return "";

        const handle = getWindowHandle(window);
        if (handle) {
            for (let i = 0; i < stableWindowKeyEntries.length; i++) {
                const entry = stableWindowKeyEntries[i];
                if (entry && entry.handle === handle)
                    return entry.key;
            }

            stableWindowKeyCounter += 1;
            const key = "window:" + stableWindowKeyCounter;
            stableWindowKeyEntries = stableWindowKeyEntries.concat([{
                "handle": handle,
                "key": key
            }]);
            return key;
        }

        if (window.id !== undefined && window.id !== null)
            return "backend:" + String(window.id);

        return "fallback:" + normalizeAppId(window.appId) + ":" + String(window.workspaceId ?? "") + ":" + String(window.output ?? "");
    }

    function pruneStableWindowKeys(activeWindows) {
        if (!stableWindowKeyEntries || stableWindowKeyEntries.length === 0)
            return;

        const activeHandles = [];
        (activeWindows || []).forEach(window => {
            const handle = getWindowHandle(window);
            if (handle)
                activeHandles.push(handle);
        });

        if (activeHandles.length === 0)
            return;

        const nextEntries = stableWindowKeyEntries.filter(entry => {
            return activeHandles.some(handle => handle === entry.handle);
        });

        if (nextEntries.length !== stableWindowKeyEntries.length)
            stableWindowKeyEntries = nextEntries;
    }

    function getAppKey(appData) {
        if (!appData)
            return null;
        if (appData.type === "separator")
            return null;

        if (appData.orderKey !== undefined)
            return appData.orderKey;

        if (groupApps)
            return appData.appId;

        if (appData.type === "pinned" || appData.type === "pinned-running")
            return appData.appId;

        if (appData.windowStableKey)
            return appData.windowStableKey;

        if (appData.window)
            return appData.window;

        return appData.appId;
    }

    function getEntryKey(appData) {
        if (!appData)
            return "";
        if (appData.type === "separator")
            return "";

        if (groupApps)
            return "app:" + appData.appId;

        if (appData.windowStableKey)
            return appData.windowStableKey;

        if (appData.window)
            return getStableWindowKey(appData.window);

        return "pinned:" + appData.appId;
    }

    function isAppEntry(entry) {
        return !!entry && entry.type !== "separator";
    }

    function getAppEntries(entries) {
        const sourceEntries = entries || [];
        return sourceEntries.filter(entry => isAppEntry(entry));
    }

    function getWorkspaceInfo(workspaceId) {
        const fallbackIndex = (typeof workspaceId === "number" && !isNaN(workspaceId)) ? workspaceId : 0;
        const workspaces = CompositorService.workspaces;

        if (workspaces && workspaces.count !== undefined && workspaces.get) {
            for (let i = 0; i < workspaces.count; i++) {
                const workspace = workspaces.get(i);
                if (workspace && workspace.id === workspaceId) {
                    return {
                        "id": workspace.id,
                        "index": workspace.idx !== undefined ? workspace.idx : fallbackIndex,
                        "name": workspace.name || ""
                    };
                }
            }
        }

        return {
            "id": workspaceId,
            "index": fallbackIndex,
            "name": ""
        };
    }

    function getWorkspaceLabel(workspaceIndex) {
        return (workspaceSeparatorPrefix || "") + workspaceIndex + (workspaceSeparatorSuffix || "");
    }

    function sortApps(apps) {
        // Sort by compositor spatial order: workspace ID, then X position, then Y position
        return apps.slice().sort((a, b) => {
            // Pinned apps without windows go to the end
            const aHasWindow = a.window !== null && a.window !== undefined;
            const bHasWindow = b.window !== null && b.window !== undefined;
            if (aHasWindow !== bHasWindow) {
                return aHasWindow ? -1 : 1;
            }

            // If neither has a window, sort by appId
            if (!aHasWindow && !bHasWindow) {
                return (a.appId || "").localeCompare(b.appId || "");
            }

            // Both have windows - sort by compositor spatial order
            // 1. Sort by workspace ID
            const aWs = a.workspaceId ?? -1;
            const bWs = b.workspaceId ?? -1;
            if (aWs !== bWs) {
                return aWs - bWs;
            }

            // 2. Sort by X position (left to right)
            const aX = (a.window && typeof a.window.x === "number") ? a.window.x : 0;
            const bX = (b.window && typeof b.window.x === "number") ? b.window.x : 0;
            if (aX !== bX) {
                return aX - bX;
            }

            // 3. Sort by Y position (top to bottom)
            const aY = (a.window && typeof a.window.y === "number") ? a.window.y : 0;
            const bY = (b.window && typeof b.window.y === "number") ? b.window.y : 0;
            if (aY !== bY) {
                return aY - bY;
            }

            // Fallback to appId for stable sort
            return (a.appId || "").localeCompare(b.appId || "");
        });
    }

    function reorderApps(fromIndex, toIndex) {
        Logger.d("Taskbar2", "Reordering apps from " + fromIndex + " to " + toIndex);
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || fromIndex >= combinedModel.length || toIndex >= combinedModel.length)
            return;

        const fromItem = combinedModel[fromIndex];
        const toItem = combinedModel[toIndex];
        if (!isAppEntry(fromItem) || !isAppEntry(toItem))
            return;
        if (workspaceGroupingActive && fromItem.workspaceId !== toItem.workspaceId)
            return;

        const orderedKeys = getAppEntries(combinedModel).map(getAppKey).filter(key => key !== null);
        const sourceKey = getAppKey(fromItem);
        const targetKey = getAppKey(toItem);
        const sourceIndex = orderedKeys.indexOf(sourceKey);
        const targetIndex = orderedKeys.indexOf(targetKey);

        if (sourceIndex === -1 || targetIndex === -1)
            return;

        const movedKey = orderedKeys.splice(sourceIndex, 1)[0];
        orderedKeys.splice(targetIndex, 0, movedKey);

        sessionAppOrder = orderedKeys;
        updateCombinedModel(true);
        savePinnedOrder();
    }

    function savePinnedOrder() {
        const currentPinned = Settings.data.dock.pinnedApps || [];
        const newPinned = [];
        const seen = new Set();

        getAppEntries(combinedModel).forEach(app => {
            if (app.appId && !seen.has(app.appId)) {
                const isPinned = currentPinned.some(p => normalizeAppId(p) === normalizeAppId(app.appId));
                if (isPinned) {
                    newPinned.push(app.appId);
                    seen.add(app.appId);
                }
            }
        });

        currentPinned.forEach(p => {
            if (!seen.has(p)) {
                newPinned.push(p);
                seen.add(p);
            }
        });

        if (JSON.stringify(currentPinned) !== JSON.stringify(newPinned)) {
            Settings.data.dock.pinnedApps = newPinned;
        }
    }

    function isAppIdPinned(appId, pinnedApps) {
        if (!appId || !pinnedApps || pinnedApps.length === 0)
            return false;
        const normalizedId = normalizeAppId(appId);
        if (pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId))
            return true;
        const resolved = resolveToDesktopEntryId(appId);
        if (resolved !== appId) {
            const normalizedResolved = normalizeAppId(resolved);
            return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedResolved);
        }
        return false;
    }

    property var _desktopEntryIdCache: ({})

    function resolveToDesktopEntryId(appId) {
        if (!appId)
            return appId;
        if (_desktopEntryIdCache.hasOwnProperty(appId))
            return _desktopEntryIdCache[appId];
        try {
            if (typeof DesktopEntries !== "undefined" && DesktopEntries.heuristicLookup) {
                const entry = DesktopEntries.heuristicLookup(appId);
                if (entry && entry.id) {
                    _desktopEntryIdCache[appId] = entry.id;
                    return entry.id;
                }
            }
        } catch (e) {}
        _desktopEntryIdCache[appId] = appId;
        return appId;
    }

    function getAppNameFromDesktopEntry(appId) {
        if (!appId)
            return appId;

        try {
            if (typeof DesktopEntries !== "undefined" && DesktopEntries.heuristicLookup) {
                const entry = DesktopEntries.heuristicLookup(appId);
                if (entry && entry.name) {
                    return entry.name;
                }
            }

            if (typeof DesktopEntries !== "undefined" && DesktopEntries.byId) {
                const entry = DesktopEntries.byId(appId);
                if (entry && entry.name) {
                    return entry.name;
                }
            }
        } catch (e) {}

        return appId;
    }

    function getDesktopEntryId(appId) {
        if (!appId)
            return appId;

        if (typeof DesktopEntries !== "undefined" && DesktopEntries.heuristicLookup) {
            try {
                const entry = DesktopEntries.heuristicLookup(appId);
                if (entry && entry.id) {
                    return entry.id;
                }
            } catch (e) {}
        }

        if (typeof DesktopEntries !== "undefined" && DesktopEntries.byId) {
            try {
                const entry = DesktopEntries.byId(appId);
                if (entry && entry.id) {
                    return entry.id;
                }
            } catch (e) {}
        }

        return appId;
    }

    function isAppPinned(appId) {
        if (!appId)
            return false;
        const pinnedApps = Settings.data.dock.pinnedApps || [];
        const normalizedId = normalizeAppId(appId);
        if (pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedId))
            return true;
        const resolved = resolveToDesktopEntryId(appId);
        if (resolved !== appId) {
            const normalizedResolved = normalizeAppId(resolved);
            return pinnedApps.some(pinnedId => normalizeAppId(pinnedId) === normalizedResolved);
        }
        return false;
    }

    function toggleAppPin(appId) {
        if (!appId)
            return;

        const desktopEntryId = getDesktopEntryId(appId);
        const normalizedId = normalizeAppId(desktopEntryId);
        let pinnedApps = (Settings.data.dock.pinnedApps || []).slice();
        const existingIndex = pinnedApps.findIndex(pinnedId => normalizeAppId(pinnedId) === normalizedId);
        const isPinned = existingIndex >= 0;

        if (isPinned) {
            pinnedApps.splice(existingIndex, 1);
        } else {
            pinnedApps.push(desktopEntryId);
        }

        Settings.data.dock.pinnedApps = pinnedApps;
    }

    function getPrimaryWindow(windows) {
        if (!windows || windows.length === 0)
            return null;
        for (let i = 0; i < windows.length; i++) {
            if (windows[i] && windows[i].isFocused)
                return windows[i];
        }
        return windows[0];
    }

    function collectVisibleWindows() {
        const windows = [];
        try {
            const total = CompositorService.windows.count || 0;
            for (let i = 0; i < total; i++) {
                const window = CompositorService.windows.get(i);
                if (window)
                    windows.push(window);
            }
        } catch (e) {}
        return windows;
    }

    function getActiveWorkspaceIds() {
        const activeWorkspaces = CompositorService.getActiveWorkspaces ? CompositorService.getActiveWorkspaces() : [];
        return activeWorkspaces.map(ws => ws.id);
    }

    function windowPasses(window, activeIds) {
        if (!window)
            return false;
        const passOutput = (!root.onlySameOutput) || (window.output === root.screen?.name);
        const passWorkspace = (!root.onlyActiveWorkspaces) || activeIds.includes(window.workspaceId);
        return passOutput && passWorkspace;
    }

    function buildGroupedModel(apps) {
        if (!groupApps) {
            return apps.map(app => {
                return {
                    "entryKey": getEntryKey(app),
                    "appId": app.appId,
                    "type": app.type,
                    "fallbackTitle": app.title || getAppNameFromDesktopEntry(app.appId),
                    "isPinned": app.type === "pinned" || app.type === "pinned-running",
                    "orderKey": getAppKey(app),
                    "windowStableKey": app.windowStableKey || "",
                    "workspaceId": app.workspaceId ?? -1,
                    "workspaceIndex": app.workspaceIndex ?? -1
                };
            });
        }

        const grouped = [];
        const groupedById = new Map();

        apps.forEach(app => {
            const appId = app.appId;
            const windows = app.window ? [app.window] : [];
            const existing = groupedById.get(appId);

            if (existing) {
                windows.forEach(window => {
                    const stableKey = getStableWindowKey(window);
                    if (window && stableKey && existing.windowStableKeys.indexOf(stableKey) === -1) {
                        existing.windowStableKeys.push(stableKey);
                    }
                });
                if (app.type === "pinned" || app.type === "pinned-running") {
                    existing.isPinned = true;
                }
            } else {
                const wsId = app.workspaceId ?? -1;
                const entry = {
                    "entryKey": workspaceGroupingActive ? ("app:" + appId + ":ws" + wsId) : ("app:" + appId),
                    "appId": appId,
                    "type": app.type,
                    "fallbackTitle": app.title || getAppNameFromDesktopEntry(appId),
                    "windowStableKeys": windows.map(window => getStableWindowKey(window)).filter(windowKey => windowKey !== ""),
                    "isPinned": app.type === "pinned" || app.type === "pinned-running",
                    "orderKey": appId,
                    "workspaceId": app.workspaceId ?? -1,
                    "workspaceIndex": app.workspaceIndex ?? -1
                };
                grouped.push(entry);
                groupedById.set(appId, entry);
            }
        });

        grouped.forEach(entry => {
            if (entry.windowStableKeys.length > 0 && entry.isPinned) {
                entry.type = "pinned-running";
            } else if (entry.windowStableKeys.length > 0) {
                entry.type = "running";
            } else {
                entry.type = "pinned";
            }
        });

        return grouped;
    }

    function buildWorkspaceGroupedModel(apps) {
        const groupedByWorkspace = new Map();
        const workspaceOrder = [];
        const unassignedEntries = [];

        apps.forEach(app => {
            if (app.workspaceId === undefined || app.workspaceId === null || app.workspaceId === "" || app.workspaceId === -1) {
                unassignedEntries.push(app);
                return;
            }

            const key = String(app.workspaceId);
            if (!groupedByWorkspace.has(key)) {
                groupedByWorkspace.set(key, {
                    "workspaceId": app.workspaceId,
                    "workspaceIndex": app.workspaceIndex ?? app.workspaceId,
                    "entries": []
                });
                workspaceOrder.push(key);
            }
            groupedByWorkspace.get(key).entries.push(app);
        });

        workspaceOrder.sort((a, b) => {
            const groupA = groupedByWorkspace.get(a);
            const groupB = groupedByWorkspace.get(b);
            const indexA = groupA ? groupA.workspaceIndex : 0;
            const indexB = groupB ? groupB.workspaceIndex : 0;
            if (indexA !== indexB)
                return indexA - indexB;
            return String(a).localeCompare(String(b));
        });

        const renderEntries = [];

        workspaceOrder.forEach((key, index) => {
            const workspaceGroup = groupedByWorkspace.get(key);
            if (!workspaceGroup || workspaceGroup.entries.length === 0)
                return;

            if (showWorkspaceSeparators && (index > 0 || workspaceSeparatorShowForFirst)) {
                renderEntries.push({
                    "type": "separator",
                    "workspaceId": workspaceGroup.workspaceId,
                    "workspaceIndex": workspaceGroup.workspaceIndex
                });
            }

            buildGroupedModel(workspaceGroup.entries).forEach(entry => renderEntries.push(entry));
        });

        if (unassignedEntries.length > 0) {
            buildGroupedModel(unassignedEntries).forEach(entry => renderEntries.push(entry));
        }

        return renderEntries;
    }

    function buildLiveEntries(structuralEntries, windowsById, windowsByStableKey) {
        const liveEntries = {};

        structuralEntries.forEach(entry => {
            if (!isAppEntry(entry) || !entry.entryKey)
                return;

            const windowIds = [];
            const windows = [];

            if (groupApps) {
                if (entry.windowStableKeys) {
                    entry.windowStableKeys.forEach(windowKey => {
                        const liveWindow = windowsByStableKey[windowKey];
                        if (liveWindow) {
                            windowIds.push(String(liveWindow.id));
                            windows.push(liveWindow);
                        }
                    });
                }
            } else if (entry.windowStableKey) {
                const liveWindow = windowsByStableKey[entry.windowStableKey];
                if (liveWindow) {
                    windowIds.push(String(liveWindow.id));
                    windows.push(liveWindow);
                }
            }

            const primaryWindow = getPrimaryWindow(windows);
            let focusedWindowIndex = -1;
            for (let i = 0; i < windows.length; i++) {
                if (windows[i] && windows[i].isFocused) {
                    focusedWindowIndex = i;
                    break;
                }
            }

            liveEntries[entry.entryKey] = {
                "windows": windows,
                "windowIds": windowIds,
                "primaryWindow": primaryWindow,
                "title": (primaryWindow && primaryWindow.title) ? primaryWindow.title : entry.fallbackTitle,
                "isFocused": focusedWindowIndex >= 0,
                "focusedWindowIndex": focusedWindowIndex,
                "groupedCount": windows.length
            };
        });

        return liveEntries;
    }

    function getStructuralSignature(entry) {
        if (!isAppEntry(entry)) {
            return ["separator", entry.workspaceId, entry.workspaceIndex, entry.label || ""].join("|");
        }
        const ids = entry.windowStableKeys ? entry.windowStableKeys.join(",") : (entry.windowStableKey || "");
        return [entry.entryKey, entry.appId, entry.type, entry.isPinned ? "1" : "0", ids].join("|");
    }

    function hasStructuralChange(nextEntries) {
        if (combinedModel.length !== nextEntries.length)
            return true;

        for (let i = 0; i < nextEntries.length; i++) {
            if (getStructuralSignature(combinedModel[i]) !== getStructuralSignature(nextEntries[i]))
                return true;
        }

        return false;
    }

    function applySnapshot(nextEntries, forceStructural) {
        const structuralChanged = forceStructural || hasStructuralChange(nextEntries);

        if (structuralChanged) {
            combinedModel = nextEntries;
            reconcileSessionOrder();
            reconcileGroupCycleIndices();
            modelUpdateTrigger++;
        }

        const windowsById = {};
        const windowsByStableKey = {};
        const windows = collectVisibleWindows();
        for (let i = 0; i < windows.length; i++) {
            const window = windows[i];
            windowsById[String(window.id)] = window;
            const stableKey = getStableWindowKey(window);
            if (stableKey)
                windowsByStableKey[stableKey] = window;
        }
        pruneStableWindowKeys(windows);

        liveEntriesByKey = buildLiveEntries(combinedModel, windowsById, windowsByStableKey);
        liveDataRevision++;
        updateFocusedEntryTracking(getFocusedEntryKey(liveEntriesByKey));
        updateHasWindow();
    }

    function reconcileSessionOrder() {
        if (!sessionAppOrder || sessionAppOrder.length === 0) {
            sessionAppOrder = getAppEntries(combinedModel).map(getAppKey);
            return;
        }

        const appEntries = getAppEntries(combinedModel);
        const currentKeys = new Set(appEntries.map(getAppKey));
        const existingKeys = new Set();
        const newOrder = [];

        sessionAppOrder.forEach(key => {
            if (currentKeys.has(key)) {
                newOrder.push(key);
                existingKeys.add(key);
            }
        });

        appEntries.forEach(app => {
            const key = getAppKey(app);
            if (!existingKeys.has(key)) {
                newOrder.push(key);
                existingKeys.add(key);
            }
        });

        if (JSON.stringify(newOrder) !== JSON.stringify(sessionAppOrder)) {
            sessionAppOrder = newOrder;
        }
    }

    function reconcileGroupCycleIndices() {
        const cycleState = groupCycleIndices || {};
        const nextCycleState = {};
        getAppEntries(combinedModel).forEach(app => {
            if (app && app.appId && cycleState[app.appId] !== undefined) {
                nextCycleState[app.appId] = cycleState[app.appId];
            }
        });
        groupCycleIndices = nextCycleState;
    }

    function buildStructuralEntries() {
        const pinnedApps = Settings.data.dock.pinnedApps || [];
        const combined = [];
        const processedWindows = new Set();
        const processedPinnedAppIds = new Set();
        const runningWindows = collectVisibleWindows();
        const activeIds = getActiveWorkspaceIds();

        function pushEntry(entryType, window, appId, title) {
            const canonicalId = isAppIdPinned(appId, pinnedApps) ? (pinnedApps.find(p => normalizeAppId(p) === normalizeAppId(appId)) || appId) : appId;
            const workspaceInfo = window ? getWorkspaceInfo(window.workspaceId) : null;

            if (window) {
                if (processedWindows.has(window))
                    return;
                if (!windowPasses(window, activeIds))
                    return;
                combined.push({
                    "type": entryType,
                    "window": window,
                    "windowStableKey": getStableWindowKey(window),
                    "appId": canonicalId,
                    "title": title || window.title || getAppNameFromDesktopEntry(appId),
                    "workspaceId": workspaceInfo ? workspaceInfo.id : -1,
                    "workspaceIndex": workspaceInfo ? workspaceInfo.index : -1
                });
                processedWindows.add(window);
            } else {
                if (processedPinnedAppIds.has(canonicalId))
                    return;
                combined.push({
                    "id": canonicalId,
                    "type": entryType,
                    "window": null,
                    "appId": canonicalId,
                    "title": title || getAppNameFromDesktopEntry(canonicalId),
                    "workspaceId": -1,
                    "workspaceIndex": -1
                });
                processedPinnedAppIds.add(canonicalId);
            }
        }

        function pushRunning(firstPass) {
            runningWindows.forEach(window => {
                if (!window)
                    return;
                const isPinned = isAppIdPinned(window.appId, pinnedApps);
                if (!firstPass && isPinned && processedWindows.has(window))
                    return;
                pushEntry((firstPass && isPinned) ? "pinned-running" : "running", window, window.appId, window.title);
            });
        }

        function pushPinned() {
            pinnedApps.forEach(pinnedAppId => {
                const normalizedPinnedId = normalizeAppId(pinnedAppId);
                const matchingWindows = runningWindows.filter(window => {
                    if (!window || !windowPasses(window, activeIds))
                        return false;
                    if (normalizeAppId(window.appId) === normalizedPinnedId)
                        return true;
                    const resolved = resolveToDesktopEntryId(window.appId);
                    return resolved !== window.appId && normalizeAppId(resolved) === normalizedPinnedId;
                });

                if (matchingWindows.length > 0) {
                    matchingWindows.forEach(window => {
                        pushEntry("pinned-running", window, pinnedAppId, window.title);
                    });
                } else if (showPinnedApps) {
                    pushEntry("pinned", null, pinnedAppId, getAppNameFromDesktopEntry(pinnedAppId));
                }
            });
        }

        pushRunning(true);
        pushPinned();

        const orderedEntries = sortApps(combined);
        if (workspaceGroupingActive)
            return buildWorkspaceGroupedModel(orderedEntries);
        return buildGroupedModel(orderedEntries);
    }

    function updateCombinedModel(forceStructural) {
        applySnapshot(buildStructuralEntries(), forceStructural === true);
    }

    function refreshLiveData() {
        applySnapshot(buildStructuralEntries(), false);
    }

    function isInteractionActive() {
        return hoveredEntryKey !== "" || dragSourceIndex !== -1 || contextMenu.visible;
    }

    function flushPendingModelRefresh() {
        if (!pendingModelRefresh || isInteractionActive())
            return;

        const forceStructural = pendingForceStructuralRefresh;
        pendingModelRefresh = false;
        pendingForceStructuralRefresh = false;
        updateCombinedModel(forceStructural);
    }

    function scheduleModelRefresh(forceStructural) {
        pendingForceStructuralRefresh = pendingForceStructuralRefresh || (forceStructural === true);
        pendingModelRefresh = true;

        if (isInteractionActive()) {
            refreshLiveData();
            return;
        }

        modelRefreshDebounce.restart();
    }

    function updateHasWindow() {
        hasWindow = combinedModel.length > 0;
    }

    function getLiveEntry(entryKey) {
        return liveEntriesByKey[entryKey] || null;
    }

    function getFocusedEntryKey(liveEntries) {
        const entries = liveEntries || ({});
        for (var entryKey in entries) {
            if (entries[entryKey] && entries[entryKey].isFocused)
                return entryKey;
        }
        return "";
    }

    function updateEntryIndicatorRect(entryKey, rect) {
        if (!entryKey)
            return;
        const nextRects = Object.assign({}, entryIndicatorRectsByKey);
        nextRects[entryKey] = rect;
        entryIndicatorRectsByKey = nextRects;
    }

    function clearEntryIndicatorRect(entryKey) {
        if (!entryKey || !entryIndicatorRectsByKey[entryKey])
            return;
        const nextRects = Object.assign({}, entryIndicatorRectsByKey);
        delete nextRects[entryKey];
        entryIndicatorRectsByKey = nextRects;
    }

    function getEntryIndicatorRect(entryKey) {
        if (!entryKey)
            return null;
        return entryIndicatorRectsByKey[entryKey] || null;
    }

    function resolveEasingType(name) {
        switch (name) {
        case "inCubic":
            return Easing.InCubic;
        case "outCubic":
            return Easing.OutCubic;
        case "inOutCubic":
            return Easing.InOutCubic;
        case "outBack":
            return Easing.OutBack;
        default:
            return Easing.Linear;
        }
    }

    function configureAxisAnimation(firstTo, firstDuration, firstEasing, secondTo, secondDuration, secondEasing) {
        focusTravelAxisStep1.to = firstTo;
        focusTravelAxisStep1.duration = Math.max(0, Math.round(firstDuration));
        focusTravelAxisStep1.easing.type = resolveEasingType(firstEasing);
        focusTravelAxisStep2.to = secondTo;
        focusTravelAxisStep2.duration = Math.max(0, Math.round(secondDuration));
        focusTravelAxisStep2.easing.type = resolveEasingType(secondEasing);
        focusTravelAxisSequence.restart();
    }

    function configureLengthAnimation(firstTo, firstDuration, firstEasing, secondTo, secondDuration, secondEasing) {
        focusTravelLengthStep1.to = firstTo;
        focusTravelLengthStep1.duration = Math.max(0, Math.round(firstDuration));
        focusTravelLengthStep1.easing.type = resolveEasingType(firstEasing);
        focusTravelLengthStep2.to = secondTo;
        focusTravelLengthStep2.duration = Math.max(0, Math.round(secondDuration));
        focusTravelLengthStep2.easing.type = resolveEasingType(secondEasing);
        focusTravelLengthSequence.restart();
    }

    function configureOpacityAnimation(startOpacity, fadeInTo, fadeInDuration, holdDuration, fadeOutTo, fadeOutDuration) {
        focusTravelOpacity = startOpacity;
        focusTravelOpacityStep1.to = fadeInTo;
        focusTravelOpacityStep1.duration = Math.max(0, Math.round(fadeInDuration));
        focusTravelOpacityPause.duration = Math.max(0, Math.round(holdDuration));
        focusTravelOpacityStep2.to = fadeOutTo;
        focusTravelOpacityStep2.duration = Math.max(0, Math.round(fadeOutDuration));
        focusTravelOpacitySequence.restart();
    }

    function configureBloomAnimation(delayDuration, riseTo, riseDuration, fallDuration, scaleTo) {
        focusTravelBloomOpacity = 0;
        focusTravelBloomScale = 1;
        focusTravelBloomPause.duration = Math.max(0, Math.round(delayDuration));
        focusTravelBloomOpacityRise.to = riseTo;
        focusTravelBloomOpacityRise.duration = Math.max(0, Math.round(riseDuration));
        focusTravelBloomOpacityFall.to = 0;
        focusTravelBloomOpacityFall.duration = Math.max(0, Math.round(fallDuration));
        focusTravelBloomScaleRise.to = scaleTo;
        focusTravelBloomScaleRise.duration = Math.max(0, Math.round(riseDuration));
        focusTravelBloomScaleFall.to = 1;
        focusTravelBloomScaleFall.duration = Math.max(0, Math.round(fallDuration));
        focusTravelBloomOpacitySequence.restart();
        focusTravelBloomScaleSequence.restart();
    }

    function setFocusTransitionPieces(shape, count, gap, mainRatio, crossRatio, opacityFalloff, scaleFalloff) {
        focusTravelTrailShape = shape;
        focusTravelTrailingPieces = count;
        focusTravelTrailingGap = gap;
        focusTravelTrailingMainRatio = mainRatio;
        focusTravelTrailingCrossRatio = crossRatio;
        focusTravelTrailingOpacityFalloff = opacityFalloff;
        focusTravelTrailingScaleFalloff = scaleFalloff;
    }

    function cancelFocusTransition() {
        focusTravelActive = false;
        focusTravelOpacity = 0;
        focusTravelTrailStrength = 0;
        focusTravelGlowStrength = 0;
        focusTravelBloomOpacity = 0;
        focusTravelBloomScale = 1;
        focusTravelDirectionSign = 1;
        focusTravelLeadShape = "pill";
        focusTravelTrailShape = "none";
        focusTravelTrailingPieces = 0;
        focusTravelTrailingGap = 0;
        focusTravelTrailingMainRatio = 0.7;
        focusTravelTrailingCrossRatio = 0.7;
        focusTravelTrailingOpacityFalloff = 0.2;
        focusTravelTrailingScaleFalloff = 0.14;
        focusTravelRibbonStrength = 0;
        focusTravelHaloStrength = 0;
        focusTravelStartRect = null;
        focusTravelEndRect = null;
        focusTransitionDelayTimer.stop();
        focusTravelAxisSequence.stop();
        focusTravelLengthSequence.stop();
        focusTravelOpacitySequence.stop();
        focusTravelBloomOpacitySequence.stop();
        focusTravelBloomScaleSequence.stop();
        pendingFocusTransitionStartKey = "";
        pendingFocusTransitionEndKey = "";
    }

    function beginFocusTransition(startRect, endRect) {
        if (!startRect || !endRect)
            return;

        const startAxis = isVerticalBar ? startRect.y : startRect.x;
        const endAxis = isVerticalBar ? endRect.y : endRect.x;
        const startLength = isVerticalBar ? startRect.height : startRect.width;
        const endLength = isVerticalBar ? endRect.height : endRect.width;
        const duration = Math.max(1, focusTransitionDurationMs);
        const direction = endAxis >= startAxis ? 1 : -1;
        const spec = FocusTransitionStyle.buildSpec({
            "style": focusTransitionStyle,
            "startAxis": startAxis,
            "endAxis": endAxis,
            "startLength": startLength,
            "endLength": endLength,
            "duration": duration,
            "direction": direction,
            "intensityRatio": focusTransitionIntensityRatio,
            "uiScaleRatio": Style.uiScaleRatio
        });

        focusTravelStartRect = startRect;
        focusTravelEndRect = endRect;
        focusTravelLength = spec.useStartLength ? startLength : endLength;
        focusTravelThickness = isVerticalBar ? endRect.width : endRect.height;
        focusTravelAxisPosition = startAxis;
        focusTravelCrossPosition = isVerticalBar ? endRect.x : endRect.y;
        focusTravelStartCenterAxis = startAxis + focusTravelLength / 2;
        focusTravelTrailStrength = spec.trailStrength;
        focusTravelGlowStrength = spec.glowStrength;
        focusTravelBloomOpacity = 0;
        focusTravelBloomScale = 1;
        focusTravelDirectionSign = direction;
        focusTravelLeadShape = spec.leadShape;
        focusTravelRibbonStrength = spec.ribbonStrength;
        focusTravelHaloStrength = spec.haloStrength;
        setFocusTransitionPieces(spec.trailShape, spec.trailingPieces, spec.trailingGap, spec.trailingMainRatio, spec.trailingCrossRatio, spec.trailingOpacityFalloff, spec.trailingScaleFalloff);
        focusTravelActive = true;

        configureAxisAnimation(spec.axis.firstTo, spec.axis.firstDuration, spec.axis.firstEasing, spec.axis.secondTo, spec.axis.secondDuration, spec.axis.secondEasing);
        configureLengthAnimation(spec.length.firstTo, spec.length.firstDuration, spec.length.firstEasing, spec.length.secondTo, spec.length.secondDuration, spec.length.secondEasing);
        configureOpacityAnimation(spec.opacity.startOpacity, spec.opacity.fadeInTo, spec.opacity.fadeInDuration, spec.opacity.holdDuration, spec.opacity.fadeOutTo, spec.opacity.fadeOutDuration);

        if (spec.bloom) {
            configureBloomAnimation(spec.bloom.delayDuration, spec.bloom.riseTo, spec.bloom.riseDuration, spec.bloom.fallDuration, spec.bloom.scaleTo);
        } else {
            focusTravelBloomOpacitySequence.stop();
            focusTravelBloomScaleSequence.stop();
            focusTravelBloomOpacity = 0;
            focusTravelBloomScale = 1;
        }
    }

    function scheduleFocusTransition(startEntryKey, endEntryKey) {
        cancelFocusTransition();
        if (!focusTransitionEnabled || !startEntryKey || !endEntryKey)
            return;

        pendingFocusTransitionStartKey = startEntryKey;
        pendingFocusTransitionEndKey = endEntryKey;
        focusTransitionDelayTimer.interval = focusTransitionDelayMs;
        focusTransitionDelayTimer.restart();
    }

    function updateFocusedEntryTracking(nextFocusedEntryKey) {
        const previousFocusedEntryKey = currentFocusedEntryKey;

        if (!focusTrackingInitialized) {
            currentFocusedEntryKey = nextFocusedEntryKey;
            lastFocusedEntryKey = nextFocusedEntryKey;
            focusTrackingInitialized = true;
            return;
        }

        if (previousFocusedEntryKey === nextFocusedEntryKey)
            return;

        lastFocusedEntryKey = previousFocusedEntryKey;
        currentFocusedEntryKey = nextFocusedEntryKey;

        if (previousFocusedEntryKey && nextFocusedEntryKey)
            scheduleFocusTransition(previousFocusedEntryKey, nextFocusedEntryKey);
        else
            cancelFocusTransition();
    }

    function getEntryForAppId(appId) {
        const appEntries = getAppEntries(combinedModel);
        for (let i = 0; i < appEntries.length; i++) {
            const item = appEntries[i];
            if (item && normalizeAppId(item.appId) === normalizeAppId(appId))
                return item;
        }
        return null;
    }

    function getLiveWindowsForEntryKey(entryKey) {
        const liveEntry = getLiveEntry(entryKey);
        if (!liveEntry || !liveEntry.windows)
            return [];
        return liveEntry.windows;
    }

    function getValidWindowsForAppId(appId) {
        const entry = getEntryForAppId(appId);
        if (!entry)
            return [];
        return getLiveWindowsForEntryKey(entry.entryKey);
    }

    function getWindowById(windowId) {
        if (!windowId)
            return null;
        const appEntries = getAppEntries(combinedModel);
        for (let i = 0; i < appEntries.length; i++) {
            const windows = getLiveWindowsForEntryKey(appEntries[i].entryKey);
            for (let j = 0; j < windows.length; j++) {
                if (windows[j] && windows[j].id == windowId)
                    return windows[j];
            }
        }
        return null;
    }

    function getPrimaryWindowForAppId(appId) {
        return getPrimaryWindow(getValidWindowsForAppId(appId));
    }

    function getPrimaryWindowForEntryKey(entryKey) {
        return getPrimaryWindow(getLiveWindowsForEntryKey(entryKey));
    }

    function focusWindow(window) {
        if (!window)
            return;
        try {
            CompositorService.focusWindow(window);
        } catch (error) {
            Logger.e("Taskbar2", "Failed to focus window: " + error);
        }
    }

    function closeWindow(window) {
        if (!window)
            return;
        try {
            CompositorService.closeWindow(window);
        } catch (error) {
            Logger.e("Taskbar2", "Failed to close window: " + error);
        }
    }

    function closeAllWindows(appId) {
        const windows = getValidWindowsForAppId(appId);
        windows.forEach(window => closeWindow(window));
    }

    function buildContextMenuModel(menuModeOverride) {
        const appId = selectedAppId;
        const windows = getLiveWindowsForEntryKey(selectedEntryKey);
        const primaryWindow = getPrimaryWindow(windows);
        const isRunning = windows.length > 0;
        const isPinned = isAppPinned(appId);
        const grouped = groupApps && windows.length > 1;
        const rawMode = menuModeOverride || groupContextMenuMode || "extended";
        const menuMode = grouped ? ((rawMode === "list" || rawMode === "extended") ? rawMode : "extended") : "single";
        const items = [];

        if (!grouped || menuMode === "single") {
            if (isRunning) {
                items.push({
                    "label": I18n.tr("common.focus"),
                    "action": "focus",
                    "icon": "eye"
                });
            }

            items.push({
                "label": !isPinned ? I18n.tr("common.pin") : I18n.tr("common.unpin"),
                "action": "pin",
                "icon": !isPinned ? "pin" : "unpin"
            });

            if (isRunning) {
                items.push({
                    "label": I18n.tr("common.close"),
                    "action": "close",
                    "icon": "x"
                });
            }
        } else {
            windows.forEach((window, index) => {
                const windowTitle = (window.title && window.title.trim() !== "") ? window.title : (appId || ("Window " + (index + 1)));
                items.push({
                    "label": windowTitle,
                    "action": "focus-window",
                    "icon": window.isFocused ? "circle-filled" : "square-rounded",
                    "windowId": window.id
                });
            });

            if (menuMode === "extended") {
                items.push({
                    "action": "_separator",
                    "enabled": false
                });
                items.push({
                    "label": I18n.tr("common.focus"),
                    "action": "focus",
                    "icon": "eye"
                });
                items.push({
                    "label": !isPinned ? I18n.tr("common.pin") : I18n.tr("common.unpin"),
                    "action": "pin",
                    "icon": !isPinned ? "pin" : "unpin"
                });
                items.push({
                    "label": pluginApi?.tr("menu.closeAll"),
                    "action": "close-all",
                    "icon": "x"
                });
            }
        }

        if ((!grouped || menuMode === "extended") && typeof DesktopEntries !== "undefined" && DesktopEntries.byId && appId) {
            const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId);
            if (entry != null && entry.actions) {
                entry.actions.forEach(action => {
                    items.push({
                        "label": action.name,
                        "action": "desktop-action",
                        "icon": "chevron-right",
                        "desktopAction": action
                    });
                });
            }
        }

        items.push({
            "label": pluginApi?.tr("menu.settings"),
            "action": "widget-settings",
            "icon": "settings"
        });

        return items;
    }

    function launchPinnedApp(appId) {
        if (!appId)
            return;

        try {
            const app = DesktopEntries.byId(appId);
            if (!app)
                return;

            if (Settings.data.appLauncher.customLaunchPrefixEnabled && Settings.data.appLauncher.customLaunchPrefix) {
                const prefix = Settings.data.appLauncher.customLaunchPrefix.split(" ");

                if (app.runInTerminal) {
                    const terminal = Settings.data.appLauncher.terminalCommand.split(" ");
                    const command = prefix.concat(terminal.concat(app.command));
                    Quickshell.execDetached(command);
                } else {
                    const command = prefix.concat(app.command);
                    Quickshell.execDetached(command);
                }
            } else {
                if (app.runInTerminal) {
                    Logger.d("Taskbar2", "Executing terminal app manually: " + app.name);
                    const terminal = Settings.data.appLauncher.terminalCommand.split(" ");
                    const command = terminal.concat(app.command);
                    CompositorService.spawn(command);
                } else if (app.command && app.command.length > 0) {
                    CompositorService.spawn(app.command);
                } else if (app.execute) {
                    app.execute();
                } else {
                    Logger.w("Taskbar2", "Could not launch: " + app.name + ". No valid launch method.");
                }
            }
        } catch (e) {
            Logger.e("Taskbar2", "Failed to launch app: " + e);
        }
    }

    function openTaskbarContextMenu(item, menuModeOverride) {
        selectedAppId = item && item.modelData ? item.modelData.appId : "";
        selectedEntryKey = item && item.modelData ? item.modelData.entryKey : "";
        selectedMenuMode = menuModeOverride || "";
        contextMenu.model = buildContextMenuModel(selectedMenuMode);
        PanelService.showContextMenu(contextMenu, root, screen, item);
    }

    NPopupContextMenu {
        id: contextMenu

        onVisibleChanged: {
            if (!visible)
                root.flushPendingModelRefresh();
        }

        onTriggered: function(action, item) {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);

            const primaryWindow = root.getPrimaryWindowForEntryKey(root.selectedEntryKey);

            if (action === "focus") {
                root.focusWindow(primaryWindow);
            } else if (action === "focus-window" && item && item.windowId !== undefined) {
                root.focusWindow(root.getWindowById(item.windowId));
            } else if (action === "pin" && root.selectedAppId) {
                root.toggleAppPin(root.selectedAppId);
            } else if (action === "close") {
                root.closeWindow(primaryWindow);
            } else if (action === "close-all" && root.selectedAppId) {
                root.closeAllWindows(root.selectedAppId);
            } else if (action === "widget-settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            } else if (action === "desktop-action" && item && item.desktopAction) {
                if (item.desktopAction.command && item.desktopAction.command.length > 0) {
                    Quickshell.execDetached(item.desktopAction.command);
                } else if (item.desktopAction.execute) {
                    item.desktopAction.execute();
                }
            }

            root.selectedAppId = "";
            root.selectedEntryKey = "";
            root.selectedMenuMode = "";
        }
    }

    Connections {
        target: CompositorService
        function onActiveWindowChanged() {
            refreshLiveData();
        }
        function onWindowListChanged() {
            scheduleModelRefresh(false);
        }
        function onWorkspaceChanged() {
            scheduleModelRefresh(true);
        }
    }

    Connections {
        target: Settings.data.dock
        function onPinnedAppsChanged() {
            scheduleModelRefresh(true);
        }
    }

    onOnlySameOutputChanged: scheduleModelRefresh(true)
    onOnlyActiveWorkspacesChanged: scheduleModelRefresh(true)
    onShowPinnedAppsChanged: scheduleModelRefresh(true)
    onGroupAppsChanged: scheduleModelRefresh(true)
    onGroupByWorkspaceIndexChanged: scheduleModelRefresh(true)
    onShowWorkspaceSeparatorsChanged: scheduleModelRefresh(true)
    onHoveredEntryKeyChanged: flushPendingModelRefresh()
    onDragSourceIndexChanged: flushPendingModelRefresh()
    onFocusTransitionEnabledChanged: if (!focusTransitionEnabled) cancelFocusTransition()
    onFocusTransitionStyleChanged: cancelFocusTransition()
    onFocusTransitionIntensityChanged: cancelFocusTransition()

    Component.onCompleted: updateCombinedModel(true)
    onScreenChanged: scheduleModelRefresh(true)

    Timer {
        id: wheelDebounce
        interval: 150
        repeat: false
        onTriggered: {
            root.wheelCooldown = false;
            root.wheelAccumulatedDelta = 0;
        }
    }

    Timer {
        id: modelRefreshDebounce
        interval: 60
        repeat: false
        onTriggered: {
            if (!root.pendingModelRefresh)
                return;

            const forceStructural = root.pendingForceStructuralRefresh;
            root.pendingModelRefresh = false;
            root.pendingForceStructuralRefresh = false;
            root.updateCombinedModel(forceStructural);
        }
    }

    Timer {
        id: focusTransitionDelayTimer
        interval: root.focusTransitionDelayMs
        repeat: false
        onTriggered: {
            const startRect = root.getEntryIndicatorRect(root.pendingFocusTransitionStartKey);
            const endRect = root.getEntryIndicatorRect(root.pendingFocusTransitionEndKey);
            root.pendingFocusTransitionStartKey = "";
            root.pendingFocusTransitionEndKey = "";

            if (!startRect || !endRect)
                return;

            root.beginFocusTransition(startRect, endRect);
        }
    }

    SequentialAnimation {
        id: focusTravelAxisSequence
        running: false

        NumberAnimation {
            id: focusTravelAxisStep1
            target: root
            property: "focusTravelAxisPosition"
        }

        NumberAnimation {
            id: focusTravelAxisStep2
            target: root
            property: "focusTravelAxisPosition"
        }
    }

    SequentialAnimation {
        id: focusTravelLengthSequence
        running: false

        NumberAnimation {
            id: focusTravelLengthStep1
            target: root
            property: "focusTravelLength"
        }

        NumberAnimation {
            id: focusTravelLengthStep2
            target: root
            property: "focusTravelLength"
        }
    }

    SequentialAnimation {
        id: focusTravelOpacitySequence
        running: false
        onStopped: root.focusTravelActive = false

        NumberAnimation {
            id: focusTravelOpacityStep1
            target: root
            property: "focusTravelOpacity"
            easing.type: Easing.OutCubic
        }

        PauseAnimation {
            id: focusTravelOpacityPause
        }

        NumberAnimation {
            id: focusTravelOpacityStep2
            target: root
            property: "focusTravelOpacity"
            easing.type: Easing.InCubic
        }
    }

    SequentialAnimation {
        id: focusTravelBloomOpacitySequence
        running: false

        PauseAnimation {
            id: focusTravelBloomPause
        }

        NumberAnimation {
            id: focusTravelBloomOpacityRise
            target: root
            property: "focusTravelBloomOpacity"
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: focusTravelBloomOpacityFall
            target: root
            property: "focusTravelBloomOpacity"
            easing.type: Easing.InCubic
        }
    }

    SequentialAnimation {
        id: focusTravelBloomScaleSequence
        running: false

        PauseAnimation {
            duration: focusTravelBloomPause.duration
        }

        NumberAnimation {
            id: focusTravelBloomScaleRise
            target: root
            property: "focusTravelBloomScale"
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: focusTravelBloomScaleFall
            target: root
            property: "focusTravelBloomScale"
            easing.type: Easing.InCubic
        }
    }

    WheelHandler {
        id: wheelHandler
        target: root
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (event) {
            const appEntries = root.getAppEntries(root.combinedModel);
            if (root.wheelCooldown || appEntries.length === 0)
                return;
            var dy = event.angleDelta.y;
            var dx = event.angleDelta.x;
            var useDy = Math.abs(dy) >= Math.abs(dx);
            var delta = useDy ? dy : dx;
            root.wheelAccumulatedDelta += delta;
            var step = 120;
            if (Math.abs(root.wheelAccumulatedDelta) >= step) {
                var direction = root.wheelAccumulatedDelta > 0 ? -1 : 1;
                var currentIndex = -1;
                for (var i = 0; i < appEntries.length; i++) {
                    const liveEntry = root.getLiveEntry(appEntries[i].entryKey);
                    if (liveEntry && liveEntry.isFocused) {
                        currentIndex = i;
                        break;
                    }
                }
                if (currentIndex < 0) {
                    for (var j = 0; j < appEntries.length; j++) {
                        const liveEntry = root.getLiveEntry(appEntries[j].entryKey);
                        if (liveEntry && liveEntry.primaryWindow) {
                            currentIndex = j;
                            break;
                        }
                    }
                }
                if (currentIndex >= 0) {
                    var nextIndex = (currentIndex + direction + appEntries.length) % appEntries.length;
                    var nextItem = appEntries[nextIndex];
                    if (nextItem) {
                        root.focusWindow(root.getPrimaryWindowForEntryKey(nextItem.entryKey));
                    }
                }
                root.wheelCooldown = true;
                wheelDebounce.restart();
                root.wheelAccumulatedDelta = 0;
                event.accepted = true;
            }
        }
    }

    visible: hideMode !== "hidden" || hasWindow
    opacity: ((hideMode !== "hidden" && hideMode !== "transparent") || hasWindow) ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    readonly property real contentWidth: {
        if (!visible)
            return 0;
        if (isVerticalBar)
            return barHeight;

        var calculatedWidth = showTitle ? taskbarLayout.implicitWidth : taskbarLayout.implicitWidth + Style.margin2M;
        if (smartWidth && maxTaskbarWidth > 0) {
            return Math.min(calculatedWidth, maxTaskbarWidth);
        }
        return Math.round(calculatedWidth);
    }
    readonly property real contentHeight: visible ? (isVerticalBar ? Math.round(taskbarLayout.implicitHeight + Style.margin2S) : capsuleHeight) : 0

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        width: root.contentWidth
        height: root.contentHeight
        anchors.centerIn: parent
        radius: Style.radiusM
        color: Style.capsuleColor
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        GridLayout {
            id: taskbarLayout

            x: isVerticalBar ? Style.pixelAlignCenter(parent.width, width) : (root.showTitle ? Style.pixelAlignCenter(parent.width, width) : Style.marginM)
            y: Style.pixelAlignCenter(parent.height, height)

            rows: isVerticalBar ? -1 : 1
            columns: isVerticalBar ? 1 : -1

            Repeater {
                model: root.combinedModel
                delegate: Item {
                    id: taskbarItem
                    required property var modelData
                    required property int index

                    readonly property int liveRevision: root.liveDataRevision
                    readonly property var liveEntry: {
                        const _ = liveRevision;
                        return root.getLiveEntry(modelData.entryKey);
                    }
                    readonly property var windows: liveEntry && liveEntry.windows ? liveEntry.windows : []
                    readonly property bool isRunning: windows.length > 0
                    readonly property bool isPinned: modelData.type === "pinned" || modelData.type === "pinned-running"
                    readonly property bool isFocused: liveEntry ? liveEntry.isFocused : false
                    readonly property bool isHovered: root.hoveredEntryKey === modelData.entryKey
                    readonly property bool isInactive: isPinned && !isRunning
                    readonly property bool shouldShowTitle: root.showTitle && modelData.type !== "pinned"
                    readonly property real itemSpacing: Style.marginS
                    readonly property real contentPaddingHorizontal: shouldShowTitle ? Style.marginM : Style.marginS
                    readonly property real entryContentWidth: root.itemSize + (shouldShowTitle ? (itemSpacing + root.titleWidth) : 0)
                    readonly property real visualWidth: root.isVerticalBar ? root.barHeight : Math.round(entryContentWidth + contentPaddingHorizontal * 2)
                    readonly property string title: (liveEntry && liveEntry.title) ? liveEntry.title : (modelData.fallbackTitle || modelData.appId || "Unknown application")
                    readonly property string effectiveItemState: isFocused ? "focused" : (isHovered ? "hovered" : (isInactive ? "inactive" : "default"))
                    readonly property color itemBackgroundColor: root.resolveItemStateColor(effectiveItemState, "background")
                    readonly property color itemBorderColor: root.resolveItemStateColor(effectiveItemState, "border")
                    readonly property real itemBorderWidth: itemBorderColor.a > 0 ? Style.borderS : 0
                    readonly property color itemTextColor: root.resolveItemStateColor(effectiveItemState, "text")
                    readonly property int groupedCount: liveEntry ? liveEntry.groupedCount : windows.length
                    readonly property int focusedWindowIndex: liveEntry ? liveEntry.focusedWindowIndex : -1
                    readonly property string groupedIndicatorText: focusedWindowIndex >= 0 ? ((focusedWindowIndex + 1) + "/" + groupedCount) : groupedCount.toString()
                    readonly property bool showGroupedIndicator: root.groupApps && groupedCount > 1 && isRunning
                    readonly property real titlePointSize: Math.max(Style.fontSizeXS, root.barFontSize * root.titleFontScale)
                    readonly property real hoverItemScale: 1 + (root.hoverItemScalePercent / 100.0)
                    readonly property bool isSeparator: modelData.type === "separator"
                    readonly property string separatorLabel: root.getWorkspaceLabel(modelData.workspaceIndex ?? 0)
                    readonly property real separatorLabelWidth: root.workspaceSeparatorShowLabel ? Math.max(0, Math.round(separatorLabel.length * root.barFontSize * 0.62)) : 0
                    readonly property real separatorLineLength: Math.max(Math.round(root.itemSize * 0.9), Style.marginL * 2)
                    readonly property real separatorVisualWidth: root.isVerticalBar ? root.barHeight : Math.round(Style.marginM * 2 + separatorLabelWidth + ((root.workspaceSeparatorShowLabel && root.workspaceSeparatorShowDivider && separatorLabelWidth > 0) ? Style.marginS : 0) + (root.workspaceSeparatorShowDivider ? separatorLineLength : 0))
                    readonly property real separatorVisualHeight: root.isVerticalBar ? Math.round(Style.marginM * 2 + separatorLabelWidth + ((root.workspaceSeparatorShowLabel && root.workspaceSeparatorShowDivider && separatorLabelWidth > 0) ? Style.marginS : 0) + (root.workspaceSeparatorShowDivider ? separatorLineLength : 0)) : root.barHeight

                    function syncIndicatorRect() {
                        if (isSeparator)
                            return;
                        if (!visualCapsule || !iconContainer)
                            return;

                        const iconPoint = iconContainer.mapToItem(visualCapsule, 0, 0);
                        const itemPoint = taskbarItem.mapToItem(visualCapsule, 0, 0);
                        const availableMainSpace = root.isVerticalBar ? iconContainer.height : iconContainer.width;
                        const availableCrossSpace = (root.isVerticalBar ? taskbarItem.width - 4 : taskbarItem.height - 4) * 1.5;
                        const markerLength = Math.min(availableMainSpace, Math.max(6, Math.round(root.itemSize * 0.25 * root.focusTransitionMarkerScale)));
                        const markerThickness = Math.min(Math.max(2, availableCrossSpace), Math.round(root.focusTransitionThickness));
                        const rect = root.isVerticalBar ? {
                            "x": Math.round(itemPoint.x + taskbarItem.width - markerThickness - 2),
                            "y": Math.round(iconPoint.y + (iconContainer.height - markerLength) / 2),
                            "width": markerThickness,
                            "height": markerLength
                        } : {
                            "x": Math.round(iconPoint.x + (iconContainer.width - markerLength) / 2),
                            "y": Math.round(itemPoint.y + taskbarItem.height - markerThickness - 2),
                            "width": markerLength,
                            "height": markerThickness
                        };

                        root.updateEntryIndicatorRect(modelData.entryKey, rect);
                    }

                    Layout.preferredWidth: isSeparator ? (root.isVerticalBar ? root.barHeight : separatorVisualWidth) : (root.isVerticalBar ? root.barHeight : visualWidth)
                    Layout.preferredHeight: isSeparator ? (root.isVerticalBar ? separatorVisualHeight : root.barHeight) : (root.isVerticalBar ? root.capsuleHeight : root.barHeight)
                    Layout.alignment: Qt.AlignCenter

                    z: (root.dragSourceIndex === index) ? 1000 : 1
                    property int modelIndex: index
                    objectName: isSeparator ? "taskbarSeparatorItem" : "taskbarAppItem"

                    Component.onCompleted: syncIndicatorRect()
                    Component.onDestruction: root.clearEntryIndicatorRect(modelData.entryKey)
                    onXChanged: syncIndicatorRect()
                    onYChanged: syncIndicatorRect()
                    onWidthChanged: syncIndicatorRect()
                    onHeightChanged: syncIndicatorRect()

                    DropArea {
                        visible: !taskbarItem.isSeparator
                        anchors.fill: parent
                        keys: ["taskbar-app"]
                        onEntered: function (drag) {
                            if (drag.source && drag.source.objectName === "taskbarAppItem") {
                                root.dragTargetIndex = taskbarItem.modelIndex;
                            }
                        }
                        onExited: function () {
                            if (root.dragTargetIndex === taskbarItem.modelIndex) {
                                root.dragTargetIndex = -1;
                            }
                        }
                        onDropped: function (drop) {
                            root.dragSourceIndex = -1;
                            root.dragTargetIndex = -1;
                            if (drop.source && drop.source.objectName === "taskbarAppItem" && drop.source !== taskbarItem) {
                                root.reorderApps(drop.source.modelIndex, taskbarItem.modelIndex);
                            }
                        }
                    }

                    Loader {
                        anchors.fill: parent
                        active: taskbarItem.isSeparator
                        sourceComponent: workspaceSeparatorComponent
                    }

                    Component {
                        id: workspaceSeparatorComponent

                        Item {
                            anchors.fill: parent

                            Item {
                                anchors.centerIn: parent
                                width: root.isVerticalBar ? root.barHeight : taskbarItem.separatorVisualWidth
                                height: root.isVerticalBar ? taskbarItem.separatorVisualHeight : root.barHeight

                                RowLayout {
                                    visible: !root.isVerticalBar
                                    anchors.centerIn: parent
                                    spacing: Style.marginS

                                    NText {
                                        visible: root.workspaceSeparatorShowLabel && taskbarItem.separatorLabel.length > 0
                                        text: taskbarItem.separatorLabel
                                        pointSize: Math.max(Style.fontSizeXS, root.barFontSize * 0.9)
                                        color: Color.mOnSurfaceVariant
                                        font.weight: Style.fontWeightSemiBold
                                    }

                                    Loader {
                                        visible: root.workspaceSeparatorShowDivider
                                        Layout.preferredWidth: root.workspaceSeparatorDividerMode === "line" ? taskbarItem.separatorLineLength : (root.workspaceSeparatorDividerMode === "icon" ? taskbarItem.separatorLineLength : taskbarItem.separatorLineLength)
                                        Layout.preferredHeight: Math.max(1, Style.borderS)
                                        sourceComponent: root.workspaceSeparatorDividerMode === "line" ? lineDividerComponent : (root.workspaceSeparatorDividerMode === "character" ? charDividerComponent : iconDividerComponent)
                                    }
                                }

                                ColumnLayout {
                                    visible: root.isVerticalBar
                                    anchors.centerIn: parent
                                    spacing: Style.marginS

                                    NText {
                                        visible: root.workspaceSeparatorShowLabel && taskbarItem.separatorLabel.length > 0
                                        text: taskbarItem.separatorLabel
                                        pointSize: Math.max(Style.fontSizeXS, root.barFontSize * 0.9)
                                        color: Color.mOnSurfaceVariant
                                        font.weight: Style.fontWeightSemiBold
                                        rotation: -90
                                    }

                                    Loader {
                                        visible: root.workspaceSeparatorShowDivider
                                        Layout.preferredWidth: Math.max(1, Style.borderS)
                                        Layout.preferredHeight: root.workspaceSeparatorDividerMode === "line" ? taskbarItem.separatorLineLength : taskbarItem.separatorLineLength
                                        sourceComponent: root.workspaceSeparatorDividerMode === "line" ? lineDividerComponentVertical : (root.workspaceSeparatorDividerMode === "character" ? charDividerComponentVertical : iconDividerComponentVertical)
                                    }
                                }
                            }

                            Component {
                                id: lineDividerComponent
                                Rectangle {
                                    Layout.preferredWidth: taskbarItem.separatorLineLength
                                    Layout.preferredHeight: Math.max(1, Style.borderS)
                                    radius: height / 2
                                    color: Qt.alpha(Color.mOutline, 0.7)
                                }
                            }

                            Component {
                                id: lineDividerComponentVertical
                                Rectangle {
                                    Layout.preferredWidth: Math.max(1, Style.borderS)
                                    Layout.preferredHeight: taskbarItem.separatorLineLength
                                    radius: width / 2
                                    color: Qt.alpha(Color.mOutline, 0.7)
                                }
                            }

                            Component {
                                id: charDividerComponent
                                NText {
                                    text: root.workspaceSeparatorDividerChar || "|"
                                    pointSize: Math.max(Style.fontSizeXS, root.barFontSize * 0.9)
                                    color: Color.mOnSurfaceVariant
                                    font.weight: Style.fontWeightSemiBold
                                }
                            }

                            Component {
                                id: charDividerComponentVertical
                                NText {
                                    text: root.workspaceSeparatorDividerChar || "|"
                                    pointSize: Math.max(Style.fontSizeXS, root.barFontSize * 0.9)
                                    color: Color.mOnSurfaceVariant
                                    font.weight: Style.fontWeightSemiBold
                                    rotation: -90
                                }
                            }

                            Component {
                                id: iconDividerComponent
                                NIcon {
                                    icon: root.workspaceSeparatorDividerIcon || "minus"
                                    pointSize: Math.max(Style.fontSizeXS, root.barFontSize)
                                    color: Color.mOnSurfaceVariant
                                }
                            }

                            Component {
                                id: iconDividerComponentVertical
                                NIcon {
                                    icon: root.workspaceSeparatorDividerIcon || "minus"
                                    pointSize: Math.max(Style.fontSizeXS, root.barFontSize)
                                    color: Color.mOnSurfaceVariant
                                    rotation: -90
                                }
                            }
                        }
                    }

                    Item {
                        id: draggableContent
                        visible: !taskbarItem.isSeparator
                        width: parent.width
                        height: parent.height
                        anchors.centerIn: dragging ? undefined : parent

                        readonly property bool isDragged: root.dragSourceIndex === index
                        property real shiftOffset: 0
                        property bool dragging: taskbarMouseArea.drag.active

                        Binding on shiftOffset {
                            value: {
                                if (root.dragSourceIndex !== -1 && root.dragTargetIndex !== -1 && !draggableContent.isDragged) {
                                    if (root.dragSourceIndex < root.dragTargetIndex) {
                                        if (index > root.dragSourceIndex && index <= root.dragTargetIndex) {
                                            return -1 * (root.isVerticalBar ? draggableContent.height : draggableContent.width);
                                        }
                                    } else if (root.dragSourceIndex > root.dragTargetIndex) {
                                        if (index >= root.dragTargetIndex && index < root.dragSourceIndex) {
                                            return root.isVerticalBar ? draggableContent.height : draggableContent.width;
                                        }
                                    }
                                }
                                return 0;
                            }
                        }

                        transform: Translate {
                            x: !root.isVerticalBar ? draggableContent.shiftOffset : 0
                            y: root.isVerticalBar ? draggableContent.shiftOffset : 0

                            Behavior on x {
                                NumberAnimation {
                                    duration: Style.animationFast
                                    easing.type: Easing.OutQuad
                                }
                            }
                            Behavior on y {
                                NumberAnimation {
                                    duration: Style.animationFast
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        onDraggingChanged: {
                            if (dragging) {
                                root.dragSourceIndex = index;
                            } else if (root.dragSourceIndex === index) {
                                Qt.callLater(() => {
                                    if (!taskbarMouseArea.drag.active && root.dragSourceIndex === index) {
                                        root.dragSourceIndex = -1;
                                        root.dragTargetIndex = -1;
                                    }
                                });
                            }
                        }

                        Drag.active: dragging
                        Drag.source: taskbarItem
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.keys: ["taskbar-app"]
                        z: dragging ? 1000 : 0
                        scale: (dragging ? 1.05 : 1.0) * (taskbarItem.isHovered ? taskbarItem.hoverItemScale : 1.0)

                        Behavior on scale {
                            NumberAnimation {
                                duration: Style.animationFast
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: root.isVerticalBar ? root.capsuleHeight : taskbarItem.visualWidth
                            height: root.capsuleHeight
                            color: taskbarItem.itemBackgroundColor
                            radius: Style.radiusM
                            border.color: taskbarItem.itemBorderColor
                            border.width: taskbarItem.itemBorderWidth

                            Behavior on color {
                                ColorAnimation {
                                    duration: Style.animationFast
                                    easing.type: Easing.InOutQuad
                                }
                            }

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Style.animationFast
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }

                        Item {
                            anchors.centerIn: parent
                            width: taskbarItem.entryContentWidth
                            height: root.itemSize

                            RowLayout {
                                anchors.fill: parent
                                spacing: taskbarItem.itemSpacing

                                Item {
                                    id: iconContainer
                                    Layout.preferredWidth: root.itemSize
                                    Layout.preferredHeight: root.itemSize
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    onXChanged: taskbarItem.syncIndicatorRect()
                                    onYChanged: taskbarItem.syncIndicatorRect()
                                    onWidthChanged: taskbarItem.syncIndicatorRect()
                                    onHeightChanged: taskbarItem.syncIndicatorRect()

                                    Item {
                                        anchors.fill: parent
                                        scale: taskbarItem.isHovered ? root.hoverIconScaleMultiplier : 1.0
                                        transformOrigin: Item.Center

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration: Style.animationFast
                                                easing.type: Easing.OutQuad
                                            }
                                        }

                                        IconImage {
                                            anchors.fill: parent
                                            source: ThemeIcons.iconForAppId(taskbarItem.modelData.appId)
                                            smooth: true
                                            asynchronous: true
                                            layer.enabled: root.colorizeIcons
                                            layer.effect: ShaderEffect {
                                                property color targetColor: Settings.data.colorSchemes.darkMode ? Color.mOnSurface : Color.mSurfaceVariant
                                                property real colorizeMode: 0.0

                                                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: !taskbarItem.shouldShowTitle && !taskbarItem.showGroupedIndicator
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: Style.toOdd(root.itemSize * 0.25)
                                        height: 4
                                        color: taskbarItem.isFocused ? Color.mPrimary : (taskbarItem.isHovered ? Color.mHover : "transparent")
                                        radius: Math.min(Style.radiusXXS, width / 2)

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Style.animationFast
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Loader {
                                        active: taskbarItem.showGroupedIndicator && root.groupIndicatorStyle === "number"
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.topMargin: Math.round(-root.itemSize * 0.08)
                                        anchors.rightMargin: Math.round(-root.itemSize * 0.08)
                                        z: 2
                                        sourceComponent: groupNumberIndicatorComponent
                                    }

                                    Loader {
                                        active: taskbarItem.showGroupedIndicator && root.groupIndicatorStyle === "dots"
                                        anchors.bottom: parent.bottom
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottomMargin: -2
                                        z: 1
                                        sourceComponent: groupDotsIndicatorComponent
                                    }

                                    Component {
                                        id: groupNumberIndicatorComponent

                                        Rectangle {
                                            readonly property real badgeHeight: Math.max(12, Math.round(root.itemSize * 0.48))
                                            readonly property real horizontalPadding: Math.max(3, Math.round(root.itemSize * 0.10))

                                            width: Math.max(badgeHeight, Math.round(numberLabel.implicitWidth + horizontalPadding * 2))
                                            height: badgeHeight
                                            radius: height / 2
                                            color: taskbarItem.focusedWindowIndex >= 0 ? Color.mPrimary : Qt.alpha(Color.mSurface, 0.96)
                                            border.color: taskbarItem.focusedWindowIndex >= 0 ? Color.mSurface : Qt.alpha(Color.mOutline, 0.8)
                                            border.width: Style.borderS

                                            NText {
                                                id: numberLabel
                                                anchors.centerIn: parent
                                                text: taskbarItem.groupedIndicatorText
                                                family: Settings.data.ui.fontFixed
                                                pointSize: Math.max(Style.fontSizeXS, Math.min(root.barFontSize * 0.8, Style.fontSizeS))
                                                applyUiScale: false
                                                font.weight: Style.fontWeightBold
                                                color: taskbarItem.focusedWindowIndex >= 0 ? Color.mOnPrimary : Color.mOnSurface
                                            }
                                        }
                                    }

                                    Component {
                                        id: groupDotsIndicatorComponent

                                        Item {
                                            readonly property int maxVisibleDots: 5
                                            readonly property int totalCount: Math.max(0, taskbarItem.groupedCount)
                                            readonly property int focusedIndex: taskbarItem.focusedWindowIndex >= 0 ? taskbarItem.focusedWindowIndex : 0
                                            readonly property int visibleCount: Math.min(totalCount, maxVisibleDots)
                                            readonly property int dotSize: Math.max(2, Math.round(root.itemSize * 0.1))
                                            readonly property int dotSpacing: Math.max(1, Math.round(dotSize * 0.7))
                                            readonly property int windowStart: {
                                                if (totalCount <= maxVisibleDots)
                                                    return 0;
                                                const centeredStart = focusedIndex - Math.floor(maxVisibleDots / 2);
                                                const maxStart = totalCount - maxVisibleDots;
                                                return Math.max(0, Math.min(maxStart, centeredStart));
                                            }

                                            width: root.isVerticalBar ? dotSize : (visibleCount * dotSize + Math.max(0, visibleCount - 1) * dotSpacing)
                                            height: root.isVerticalBar ? (visibleCount * dotSize + Math.max(0, visibleCount - 1) * dotSpacing) : dotSize

                                            Repeater {
                                                model: parent.visibleCount
                                                delegate: Rectangle {
                                                    required property int index
                                                    readonly property int actualIndex: parent.windowStart + index
                                                    width: parent.dotSize
                                                    height: parent.dotSize
                                                    radius: width / 2
                                                    x: root.isVerticalBar ? 0 : index * (parent.dotSize + parent.dotSpacing)
                                                    y: root.isVerticalBar ? index * (parent.dotSize + parent.dotSpacing) : 0
                                                    color: actualIndex === taskbarItem.focusedWindowIndex ? Color.mPrimary : Color.mOnSurfaceVariant
                                                    opacity: 0.95
                                                }
                                            }
                                        }
                                    }
                                }

                                NText {
                                    visible: taskbarItem.shouldShowTitle
                                    Layout.preferredWidth: root.titleWidth
                                    Layout.preferredHeight: root.itemSize
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    Layout.fillWidth: false
                                    text: taskbarItem.title
                                    family: root.titleFontFamilyValue()
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    pointSize: taskbarItem.titlePointSize
                                    color: taskbarItem.itemTextColor
                                    opacity: Style.opacityFull
                                    font.weight: root.titleFontWeightValue()
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: taskbarMouseArea
                        objectName: "taskbarMouseArea"
                        visible: !taskbarItem.isSeparator
                        enabled: !taskbarItem.isSeparator
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        drag.target: draggableContent
                        drag.axis: root.isVerticalBar ? Drag.YAxis : Drag.XAxis
                        preventStealing: true

                        onReleased: {
                            if (draggableContent.Drag.active) {
                                draggableContent.Drag.drop();
                            }
                        }

                        onClicked: mouse => {
                            if (!modelData)
                                return;

                            const runningWindows = taskbarItem.windows;
                            const primaryWindow = root.getPrimaryWindowForEntryKey(modelData.entryKey);

                            if (mouse.button === Qt.LeftButton) {
                                if (runningWindows.length === 0) {
                                    root.launchPinnedApp(modelData.appId);
                                } else if (!root.groupApps || runningWindows.length <= 1) {
                                    root.focusWindow(primaryWindow);
                                } else if (root.groupClickAction === "list") {
                                    TooltipService.hideImmediately();
                                    root.openTaskbarContextMenu(taskbarItem, "list");
                                } else {
                                    const appKey = modelData.appId || "";
                                    const state = root.groupCycleIndices || {};
                                    const nextIndex = (state[appKey] || 0) % runningWindows.length;
                                    const nextWindow = runningWindows[nextIndex];
                                    root.focusWindow(nextWindow);
                                    state[appKey] = (nextIndex + 1) % runningWindows.length;
                                    root.groupCycleIndices = Object.assign({}, state);
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                TooltipService.hide();
                                root.openTaskbarContextMenu(taskbarItem, "");
                            }
                        }

                        onEntered: {
                            root.hoveredEntryKey = taskbarItem.modelData.entryKey;
                            TooltipService.show(taskbarItem, taskbarItem.title, BarService.getTooltipDirection(root.screen?.name));
                        }

                        onExited: {
                            root.hoveredEntryKey = "";
                            TooltipService.hide();
                        }
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            visible: root.focusTravelActive && root.focusTravelOpacity > 0
            z: 20

            Rectangle {
                visible: root.focusTravelRibbonStrength > 0 && root.focusTravelTrailExtent > 0
                x: root.isVerticalBar ? (root.focusTravelCrossPosition + root.focusTravelThickness * 0.18) : root.focusTravelTrailStartAxis
                y: root.isVerticalBar ? root.focusTravelTrailStartAxis : (root.focusTravelCrossPosition + root.focusTravelThickness * 0.18)
                width: root.isVerticalBar ? Math.max(2, root.focusTravelThickness * 0.64) : root.focusTravelTrailExtent
                height: root.isVerticalBar ? root.focusTravelTrailExtent : Math.max(2, root.focusTravelThickness * 0.64)
                radius: Math.max(width, height) / 2
                color: Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionGlowColorKey, Color.mPrimary), root.focusTravelRibbonStrength * root.focusTravelOpacity * root.focusTransitionOpacityRatio)
            }

            Rectangle {
                visible: root.focusTravelTrailExtent > 1 && root.focusTravelTrailStrength > 0
                x: root.isVerticalBar ? (root.focusTravelCrossPosition - 2 - root.focusTransitionBlur * 0.5) : (root.focusTravelTrailStartAxis - root.focusTransitionBlur * 0.5)
                y: root.isVerticalBar ? (root.focusTravelTrailStartAxis - root.focusTransitionBlur * 0.5) : (root.focusTravelCrossPosition - 2 - root.focusTransitionBlur * 0.5)
                width: root.isVerticalBar ? (root.focusTravelThickness + 4 + root.focusTransitionBlur) : (root.focusTravelTrailExtent + root.focusTransitionBlur)
                height: root.isVerticalBar ? (root.focusTravelTrailExtent + root.focusTransitionBlur) : (root.focusTravelThickness + 4 + root.focusTransitionBlur)
                radius: Math.max(width, height) / 2
                color: Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionGlowColorKey, Color.mPrimary), root.focusTravelTrailStrength * root.focusTravelOpacity * root.focusTransitionOpacityRatio)
            }

            Rectangle {
                visible: root.focusTravelGlowStrength > 0
                x: root.isVerticalBar ? (root.focusTravelCrossPosition - 4 - (root.focusTravelBloomScale - 1) * 2 - root.focusTransitionBlur) : (root.focusTravelAxisPosition - 4 - (root.focusTravelBloomScale - 1) * 4 - root.focusTransitionBlur)
                y: root.isVerticalBar ? (root.focusTravelAxisPosition - 4 - (root.focusTravelBloomScale - 1) * 4 - root.focusTransitionBlur) : (root.focusTravelCrossPosition - 4 - (root.focusTravelBloomScale - 1) * 2 - root.focusTransitionBlur)
                width: root.isVerticalBar ? (root.focusTravelThickness + 8 + (root.focusTravelBloomScale - 1) * 4 + root.focusTransitionBlur * 2) : (root.focusTravelLength + 8 + (root.focusTravelBloomScale - 1) * 8 + root.focusTransitionBlur * 2)
                height: root.isVerticalBar ? (root.focusTravelLength + 8 + (root.focusTravelBloomScale - 1) * 8 + root.focusTransitionBlur * 2) : (root.focusTravelThickness + 8 + (root.focusTravelBloomScale - 1) * 4 + root.focusTransitionBlur * 2)
                radius: Math.max(width, height) / 2
                color: Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionGlowColorKey, Color.mPrimary), root.focusTravelGlowStrength * root.focusTravelOpacity * root.focusTransitionOpacityRatio)
            }

            Rectangle {
                visible: root.focusTravelHaloStrength > 0
                x: root.isVerticalBar ? (root.focusTravelCrossPosition - 3 - root.focusTransitionBlur * 0.25) : (root.focusTravelAxisPosition - 3 - root.focusTransitionBlur * 0.25)
                y: root.isVerticalBar ? (root.focusTravelAxisPosition - 3 - root.focusTransitionBlur * 0.25) : (root.focusTravelCrossPosition - 3 - root.focusTransitionBlur * 0.25)
                width: root.isVerticalBar ? (root.focusTravelThickness + 6 + root.focusTransitionBlur * 0.5) : (root.focusTravelLength + 6 + root.focusTransitionBlur * 0.5)
                height: root.isVerticalBar ? (root.focusTravelLength + 6 + root.focusTransitionBlur * 0.5) : (root.focusTravelThickness + 6 + root.focusTransitionBlur * 0.5)
                radius: Math.max(width, height) / 2
                color: "transparent"
                border.width: Math.max(1, Style.borderS)
                border.color: Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionGlowColorKey, Color.mPrimary), root.focusTravelHaloStrength * root.focusTravelOpacity * root.focusTransitionOpacityRatio)
            }

            Repeater {
                model: 4

                delegate: Rectangle {
                    required property int index
                    readonly property bool enabledPiece: root.focusTravelTrailingPieces > index && root.focusTravelTrailShape !== "none"
                    readonly property real lag: root.focusTravelTrailingGap * (index + 1)
                    readonly property real centerAxis: root.focusTravelMarkerCenterAxis - root.focusTravelDirectionSign * lag
                    readonly property real scaleFactor: Math.max(0.18, 1 - index * root.focusTravelTrailingScaleFalloff)
                    readonly property real baseMain: root.focusTravelLength * root.focusTravelTrailingMainRatio
                    readonly property real baseCross: root.focusTravelThickness * root.focusTravelTrailingCrossRatio
                    readonly property real pieceMain: {
                        if (root.focusTravelTrailShape === "dot")
                            return Math.max(3, Math.min(baseMain, baseCross) * scaleFactor);
                        return Math.max(3, baseMain * scaleFactor);
                    }
                    readonly property real pieceCross: {
                        if (root.focusTravelTrailShape === "dot")
                            return pieceMain;
                        return Math.max(3, baseCross * scaleFactor);
                    }
                    readonly property real pieceOpacity: Math.max(0, root.focusTravelOpacity * root.focusTransitionOpacityRatio * (1 - index * root.focusTravelTrailingOpacityFalloff))
                    readonly property real pieceX: root.isVerticalBar ? (root.focusTravelCrossPosition + (root.focusTravelThickness - pieceCross) / 2) : (centerAxis - pieceMain / 2)
                    readonly property real pieceY: root.isVerticalBar ? (centerAxis - pieceMain / 2) : (root.focusTravelCrossPosition + (root.focusTravelThickness - pieceCross) / 2)
                    readonly property real pieceWidth: root.isVerticalBar ? pieceCross : pieceMain
                    readonly property real pieceHeight: root.isVerticalBar ? pieceMain : pieceCross
                    readonly property color pieceColor: root.resolveFocusTransitionColor(root.focusTransitionGlowColorKey, Color.mPrimary)

                    visible: enabledPiece
                    x: pieceX
                    y: pieceY
                    width: pieceWidth
                    height: pieceHeight
                    radius: {
                        switch (root.focusTravelTrailShape) {
                        case "shard":
                            return Math.min(Style.radiusXXS, Math.min(width, height) / 3);
                        case "dot":
                            return width / 2;
                        default:
                            return Math.max(width, height) / 2;
                        }
                    }
                    color: Qt.alpha(pieceColor, pieceOpacity)
                    border.width: root.focusTravelTrailShape === "echo" ? Math.max(1, Style.borderS) : 0
                    border.color: root.focusTravelTrailShape === "echo" ? Qt.alpha(pieceColor, pieceOpacity * 0.9) : "transparent"
                }
            }

            Rectangle {
                x: root.isVerticalBar ? root.focusTravelCrossPosition : root.focusTravelAxisPosition
                y: root.isVerticalBar ? root.focusTravelAxisPosition : root.focusTravelCrossPosition
                width: root.isVerticalBar ? root.focusTravelThickness : root.focusTravelLength
                height: root.isVerticalBar ? root.focusTravelLength : root.focusTravelThickness
                radius: root.focusTravelLeadShape === "rect" ? Math.min(Style.radiusXS, Math.min(width, height) / 3) : Math.max(width, height) / 2
                border.width: root.focusTravelLeadShape === "rect" ? Math.max(1, Style.borderS) : 0
                border.color: root.focusTravelLeadShape === "rect" ? Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionColorKey, Color.mPrimary), 0.65 * root.focusTravelOpacity * root.focusTransitionOpacityRatio) : "transparent"
                color: Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionColorKey, Color.mPrimary), root.focusTravelOpacity * root.focusTransitionOpacityRatio)
            }

            Rectangle {
                readonly property var bloomRect: root.focusTravelEndRect || ({
                    "x": 0,
                    "y": 0,
                    "width": 0,
                    "height": 0
                })
                visible: root.focusTravelBloomOpacity > 0 && root.focusTravelEndRect
                x: root.isVerticalBar ? (bloomRect.x - (root.focusTravelBloomScale - 1) * 3 - root.focusTransitionBlur) : (bloomRect.x - (root.focusTravelBloomScale - 1) * 6 - root.focusTransitionBlur)
                y: root.isVerticalBar ? (bloomRect.y - (root.focusTravelBloomScale - 1) * 6 - root.focusTransitionBlur) : (bloomRect.y - (root.focusTravelBloomScale - 1) * 3 - root.focusTransitionBlur)
                width: root.isVerticalBar ? (bloomRect.width + (root.focusTravelBloomScale - 1) * 6 + root.focusTransitionBlur * 2) : (bloomRect.width + (root.focusTravelBloomScale - 1) * 12 + root.focusTransitionBlur * 2)
                height: root.isVerticalBar ? (bloomRect.height + (root.focusTravelBloomScale - 1) * 12 + root.focusTransitionBlur * 2) : (bloomRect.height + (root.focusTravelBloomScale - 1) * 6 + root.focusTransitionBlur * 2)
                radius: Math.max(width, height) / 2
                color: Qt.alpha(root.resolveFocusTransitionColor(root.focusTransitionGlowColorKey, Color.mPrimary), root.focusTravelBloomOpacity * root.focusTransitionOpacityRatio)
            }
        }
    }
}
