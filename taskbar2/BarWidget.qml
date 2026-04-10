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
    readonly property real focusTransitionBaseThickness: 6
    readonly property real focusTransitionScale: Math.max(0.5, cfg.focusTransitionScale ?? defaults.focusTransitionScale ?? 1.0)
    readonly property string focusTransitionLeadColorKey: cfg.focusTransitionLeadColor ?? defaults.focusTransitionLeadColor ?? "primary"
    readonly property string focusTransitionGlowColorKey: cfg.focusTransitionGlowColor ?? defaults.focusTransitionGlowColor ?? "primary"
    readonly property real focusTransitionBlur: Math.max(0, cfg.focusTransitionBlur ?? defaults.focusTransitionBlur ?? 6)
    readonly property int focusTransitionTransparency: Math.max(0, Math.min(90, cfg.focusTransitionTransparency ?? defaults.focusTransitionTransparency ?? 15))
    readonly property real focusTransitionIntensityRatio: focusTransitionIntensity / 100
    readonly property real focusTransitionOpacityRatio: 1 - (focusTransitionTransparency / 100)
    readonly property string focusTransitionEffectColorKey: cfg.focusTransitionEffectColor ?? defaults.focusTransitionEffectColor ?? "tertiary"
    readonly property string focusTransitionVerticalPosition: cfg.focusTransitionVerticalPosition ?? defaults.focusTransitionVerticalPosition ?? "bottom"
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

    function resolveFocusTransitionColor(colorKeyValue, fallbackColor) {
        if (!colorKeyValue || colorKeyValue === "none")
            return fallbackColor;
        return Color.resolveColorKey(colorKeyValue);
    }

    function mixTransitionColors(mixRatio, effectRatio) {
        const baseColor = resolveFocusTransitionColor(focusTransitionLeadColorKey, Color.mPrimary);
        const glowColor = resolveFocusTransitionColor(focusTransitionGlowColorKey, Color.mPrimary);
        const effColor = resolveFocusTransitionColor(focusTransitionEffectColorKey, Color.mTertiary);
        const ratio = Math.max(0, Math.min(1, mixRatio));
        const eRatio = Math.max(0, Math.min(1, effectRatio || 0));
        const r1 = baseColor.r + (glowColor.r - baseColor.r) * ratio;
        const g1 = baseColor.g + (glowColor.g - baseColor.g) * ratio;
        const b1 = baseColor.b + (glowColor.b - baseColor.b) * ratio;
        return Qt.rgba(
            r1 + (effColor.r - r1) * eRatio,
            g1 + (effColor.g - g1) * eRatio,
            b1 + (effColor.b - b1) * eRatio,
            1
        );
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

    function getFocusedWorkspaceIdForEntry(entryKey) {
        const liveEntry = getLiveEntry(entryKey);
        if (!liveEntry)
            return -1;

        const windows = liveEntry.windows || [];
        for (let i = 0; i < windows.length; i++) {
            const window = windows[i];
            if (window && window.isFocused)
                return window.workspaceId ?? -1;
        }

        const primaryWindow = liveEntry.primaryWindow;
        if (primaryWindow)
            return primaryWindow.workspaceId ?? -1;

        return -1;
    }

    function scheduleFocusTransition(startEntryKey, endEntryKey) {
        focusTransitionOverlay.cancelTransition();
        if (!focusTransitionEnabled || !startEntryKey || !endEntryKey)
            return;

        const startRect = getEntryIndicatorRect(startEntryKey);
        const endRect = getEntryIndicatorRect(endEntryKey);
        if (!startRect || !endRect)
            return;

        focusTransitionOverlay.scheduleTransition(startRect, endRect);
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

        if (previousFocusedEntryKey && nextFocusedEntryKey) {
            const previousWorkspaceId = getFocusedWorkspaceIdForEntry(previousFocusedEntryKey);
            const nextWorkspaceId = getFocusedWorkspaceIdForEntry(nextFocusedEntryKey);

            if (previousWorkspaceId === -1 || nextWorkspaceId === -1 || previousWorkspaceId !== nextWorkspaceId) {
                focusTransitionOverlay.cancelTransition();
                return;
            }

            scheduleFocusTransition(previousFocusedEntryKey, nextFocusedEntryKey);
        } else {
            focusTransitionOverlay.cancelTransition();
        }
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
    onFocusTransitionEnabledChanged: if (!focusTransitionEnabled) focusTransitionOverlay.cancelTransition()
    onFocusTransitionStyleChanged: focusTransitionOverlay.cancelTransition()
    onFocusTransitionIntensityChanged: focusTransitionOverlay.cancelTransition()
    onFocusTransitionVerticalPositionChanged: {
        for (let i = 0; i < entryRepeater.count; i++) {
            const item = entryRepeater.itemAt(i);
            if (item && item.syncIndicatorRect)
                item.syncIndicatorRect();
        }
    }

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
                id: entryRepeater
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
                    readonly property color focusAccentColor: root.mixTransitionColors(0.18)
                    readonly property color focusSecondaryColor: root.mixTransitionColors(0.9)
                    readonly property real focusVisualStrength: isFocused ? 1.0 : (isHovered ? 0.4 : 0.0)
                    readonly property real focusWashOpacity: isFocused ? 0.22 : (isHovered ? 0.1 : 0.0)
                    readonly property real iconGlowOpacity: isFocused ? 0.32 : (isHovered ? 0.12 : 0.0)
                    readonly property real iconFocusScale: isFocused ? 1.18 : (isHovered ? Math.max(root.hoverIconScaleMultiplier, 1.05) : 1.0)
                    readonly property real iconFocusLift: isFocused ? -1 : 0
                    readonly property real titleFocusOpacity: isFocused ? 1.0 : (isHovered ? 0.94 : 0.84)
                    readonly property real titleFocusOffset: isFocused ? -2 : (isHovered ? -1 : 0)
                    readonly property real badgeFocusScale: isFocused ? 1.08 : 1.0
                    readonly property real indicatorOpacity: isFocused ? 1.0 : (isHovered ? 0.72 : 0.0)
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
                        const markerLength = Math.min(availableMainSpace, Math.max(6, Math.round(root.itemSize * 0.25 * root.focusTransitionScale)));
                        const markerThickness = Math.min(Math.max(2, availableCrossSpace), Math.round(6 * root.focusTransitionScale));
                        let markerY;
                        if (root.focusTransitionVerticalPosition === "top")
                            markerY = Math.round(itemPoint.y + 2);
                        else if (root.focusTransitionVerticalPosition === "middle")
                            markerY = Math.round(itemPoint.y + (taskbarItem.height - markerThickness) / 2);
                        else
                            markerY = Math.round(itemPoint.y + taskbarItem.height - markerThickness - 2);
                        const rect = root.isVerticalBar ? {
                            "x": Math.round(itemPoint.x + taskbarItem.width - markerThickness - 2),
                            "y": Math.round(iconPoint.y + (iconContainer.height - markerLength) / 2),
                            "width": markerThickness,
                            "height": markerLength
                        } : {
                            "x": Math.round(iconPoint.x + (iconContainer.width - markerLength) / 2),
                            "y": markerY,
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

                    Component.onCompleted: {
                        syncIndicatorRect();
                        iconForegroundProxy.syncPosition();
                    }
                    Component.onDestruction: root.clearEntryIndicatorRect(modelData.entryKey)
                    onXChanged: {
                        syncIndicatorRect();
                        iconForegroundProxy.syncPosition();
                    }
                    onYChanged: {
                        syncIndicatorRect();
                        iconForegroundProxy.syncPosition();
                    }
                    onWidthChanged: {
                        syncIndicatorRect();
                        iconForegroundProxy.syncPosition();
                    }
                    onHeightChanged: {
                        syncIndicatorRect();
                        iconForegroundProxy.syncPosition();
                    }

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
                            iconForegroundProxy.syncPosition();
                        }

                        Drag.active: dragging
                        Drag.source: taskbarItem
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.keys: ["taskbar-app"]
                        z: dragging ? 1000 : 0
                        scale: (dragging ? 1.05 : 1.0) * (taskbarItem.isHovered ? taskbarItem.hoverItemScale : 1.0)
                        onXChanged: iconForegroundProxy.syncPosition()
                        onYChanged: iconForegroundProxy.syncPosition()
                        onWidthChanged: iconForegroundProxy.syncPosition()
                        onHeightChanged: iconForegroundProxy.syncPosition()
                        onScaleChanged: iconForegroundProxy.syncPosition()
                        onShiftOffsetChanged: iconForegroundProxy.syncPosition()

                        Behavior on scale {
                            NumberAnimation {
                                duration: Style.animationFast
                            }
                        }

                        Rectangle {
                            id: capsuleBackground
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

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Math.max(1, Style.borderS)
                                radius: Math.max(0, capsuleBackground.radius - Style.borderS)
                                color: "transparent"
                                opacity: taskbarItem.focusWashOpacity
                                gradient: Gradient {
                                    orientation: root.isVerticalBar ? Gradient.Vertical : Gradient.Horizontal
                                    GradientStop {
                                        position: 0.0
                                        color: Qt.rgba(taskbarItem.focusAccentColor.r, taskbarItem.focusAccentColor.g, taskbarItem.focusAccentColor.b, 0.95)
                                    }
                                    GradientStop {
                                        position: 0.55
                                        color: Qt.rgba(taskbarItem.focusSecondaryColor.r, taskbarItem.focusSecondaryColor.g, taskbarItem.focusSecondaryColor.b, 0.55)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(taskbarItem.focusAccentColor.r, taskbarItem.focusAccentColor.g, taskbarItem.focusAccentColor.b, 0.18)
                                    }
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Style.animationNormal
                                        easing.type: Easing.OutCubic
                                    }
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
                                    onXChanged: {
                                        taskbarItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }
                                    onYChanged: {
                                        taskbarItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }
                                    onWidthChanged: {
                                        taskbarItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }
                                    onHeightChanged: {
                                        taskbarItem.syncIndicatorRect();
                                        iconForegroundProxy.syncPosition();
                                    }

                                    Item {
                                        anchors.fill: parent
                                    }

                                    Rectangle {
                                        visible: !taskbarItem.shouldShowTitle && !taskbarItem.showGroupedIndicator
                                        anchors.bottom: parent.bottom
                                        anchors.bottomMargin: -2
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: Style.toOdd(root.itemSize * (0.22 + taskbarItem.focusVisualStrength * 0.18))
                                        height: 4
                                        color: taskbarItem.isFocused ? taskbarItem.focusAccentColor : taskbarItem.focusSecondaryColor
                                        opacity: taskbarItem.indicatorOpacity
                                        radius: Math.min(Style.radiusXXS, width / 2)

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: Style.animationNormal
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Style.animationFast
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Behavior on opacity {
                                            NumberAnimation {
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
                                            scale: taskbarItem.badgeFocusScale
                                            radius: height / 2
                                            color: taskbarItem.focusedWindowIndex >= 0 ? taskbarItem.focusAccentColor : Qt.alpha(taskbarItem.focusSecondaryColor, 0.28)
                                            border.color: taskbarItem.focusedWindowIndex >= 0 ? Qt.alpha(Color.mSurface, 0.92) : Qt.alpha(taskbarItem.focusSecondaryColor, 0.58)
                                            border.width: Style.borderS

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutBack
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Behavior on border.color {
                                                ColorAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            NText {
                                                id: numberLabel
                                                anchors.centerIn: parent
                                                text: taskbarItem.groupedIndicatorText
                                                family: Settings.data.ui.fontFixed
                                                pointSize: Math.max(Style.fontSizeXS, Math.min(root.barFontSize * 0.8, Style.fontSizeS))
                                                applyUiScale: false
                                                font.weight: Style.fontWeightBold
                                                color: taskbarItem.focusedWindowIndex >= 0 ? Color.mOnPrimary : taskbarItem.itemTextColor

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Style.animationFast
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
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
                                                    scale: actualIndex === taskbarItem.focusedWindowIndex ? 1.35 : 1.0
                                                    radius: width / 2
                                                    x: root.isVerticalBar ? 0 : index * (parent.dotSize + parent.dotSpacing)
                                                    y: root.isVerticalBar ? index * (parent.dotSize + parent.dotSpacing) : 0
                                                    color: actualIndex === taskbarItem.focusedWindowIndex ? taskbarItem.focusAccentColor : taskbarItem.focusSecondaryColor
                                                    opacity: actualIndex === taskbarItem.focusedWindowIndex ? 1.0 : 0.56

                                                    Behavior on scale {
                                                        NumberAnimation {
                                                            duration: Style.animationFast
                                                            easing.type: Easing.OutBack
                                                        }
                                                    }

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: Style.animationFast
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }

                                                    Behavior on opacity {
                                                        NumberAnimation {
                                                            duration: Style.animationFast
                                                            easing.type: Easing.OutCubic
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        id: iconForegroundProxy
                                        parent: taskbarForegroundLayer
                                        z: 1
                                        visible: taskbarForegroundLayer.visible && taskbarItem.visible && !taskbarItem.isSeparator
                                        enabled: false
                                        property rect mappedRect: Qt.rect(0, 0, 0, 0)

                                        function syncPosition() {
                                            if (!taskbarForegroundLayer || !iconContainer) {
                                                mappedRect = Qt.rect(0, 0, 0, 0);
                                                return;
                                            }

                                            const topLeft = iconContainer.mapToItem(taskbarForegroundLayer, 0, 0);
                                            const bottomRight = iconContainer.mapToItem(taskbarForegroundLayer, iconContainer.width, iconContainer.height);
                                            const left = Math.min(topLeft.x, bottomRight.x);
                                            const top = Math.min(topLeft.y, bottomRight.y);
                                            const right = Math.max(topLeft.x, bottomRight.x);
                                            const bottom = Math.max(topLeft.y, bottomRight.y);
                                            mappedRect = Qt.rect(
                                                Math.round(left),
                                                Math.round(top),
                                                Math.max(0, Math.round(right - left)),
                                                Math.max(0, Math.round(bottom - top))
                                            );
                                        }

                                        x: mappedRect.x
                                        y: mappedRect.y
                                        width: mappedRect.width
                                        height: mappedRect.height

                                        Item {
                                            anchors.fill: parent
                                            y: taskbarItem.iconFocusLift
                                            scale: taskbarItem.iconFocusScale
                                            opacity: 0.78 + taskbarItem.focusVisualStrength * 0.22
                                            transformOrigin: Item.Center

                                            Behavior on y {
                                                NumberAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: Style.animationNormal
                                                    easing.type: Easing.OutQuad
                                                }
                                            }

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Style.animationFast
                                                    easing.type: Easing.OutCubic
                                                }
                                            }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Math.round(parent.width * 0.9)
                                                height: Math.round(parent.height * 0.9)
                                                radius: Math.max(width, height) / 2
                                                color: Qt.rgba(taskbarItem.focusSecondaryColor.r, taskbarItem.focusSecondaryColor.g, taskbarItem.focusSecondaryColor.b, 1)
                                                opacity: taskbarItem.iconGlowOpacity
                                                scale: 0.86 + taskbarItem.focusVisualStrength * 0.28

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: Style.animationNormal
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }

                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: Style.animationNormal
                                                        easing.type: Easing.OutCubic
                                                    }
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
                                    }
                                }

                                NText {
                                    visible: taskbarItem.shouldShowTitle
                                    Layout.preferredWidth: root.titleWidth
                                    Layout.preferredHeight: root.itemSize
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    Layout.fillWidth: false
                                    Layout.leftMargin: taskbarItem.titleFocusOffset
                                    text: taskbarItem.title
                                    family: root.titleFontFamilyValue()
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    pointSize: taskbarItem.titlePointSize
                                    color: taskbarItem.itemTextColor
                                    opacity: taskbarItem.titleFocusOpacity
                                    font.weight: root.titleFontWeightValue()

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.OutCubic
                                        }
                                    }

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Style.animationFast
                                            easing.type: Easing.OutCubic
                                        }
                                    }
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

        FocusTransitionOverlay {
            id: focusTransitionOverlay
            anchors.fill: parent
            z: 20
            isVerticalBar: root.isVerticalBar
            transitionEnabled: root.focusTransitionEnabled
            delayMs: root.focusTransitionDelayMs
            durationMs: root.focusTransitionDurationMs
            styleKey: root.focusTransitionStyle
            intensityRatio: root.focusTransitionIntensityRatio
            thickness: root.focusTransitionBaseThickness * root.focusTransitionScale
            leadColorKey: root.focusTransitionLeadColorKey
            glowColorKey: root.focusTransitionGlowColorKey
            effectColorKey: root.focusTransitionEffectColorKey
            verticalPosition: root.focusTransitionVerticalPosition
            blurRadius: root.focusTransitionBlur * root.focusTransitionScale
            opacityRatio: root.focusTransitionOpacityRatio
        }

        Item {
            id: taskbarForegroundLayer
            anchors.fill: parent
            z: 30
        }
    }
}
