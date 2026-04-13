import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Niri
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Services.Compositor
import qs.Services.System
import qs.Services.UI
import qs.Widgets
import "./components"
import "./common/TaskbarModel.js" as TaskbarModel

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
    readonly property string iconColorKey: cfg.iconColor ?? defaults.iconColor ?? "primary"
    readonly property int iconColorOpacity: cfg.iconColorOpacity ?? defaults.iconColorOpacity ?? 100
    readonly property real iconScale: cfg.iconScale ?? defaults.iconScale ?? 0.8
    readonly property real hoverIconScaleMultiplier: cfg.hoverIconScaleMultiplier ?? defaults.hoverIconScaleMultiplier ?? 1.0
    readonly property real hoverItemScalePercent: cfg.hoverItemScalePercent ?? defaults.hoverItemScalePercent ?? 0
    readonly property int itemGapUnits: cfg.itemGapUnits ?? defaults.itemGapUnits ?? 2
    readonly property int itemGap: Math.max(0, Math.round(itemGapUnits * Style.uiScaleRatio))
    readonly property string titleFontFamily: cfg.titleFontFamily ?? defaults.titleFontFamily ?? ""
    readonly property real titleFontScale: cfg.titleFontScale ?? defaults.titleFontScale ?? 1.0
    readonly property string titleFontWeight: cfg.titleFontWeight ?? defaults.titleFontWeight ?? "medium"
    readonly property bool itemStateFadeEnabled: cfg.itemStateFadeEnabled ?? defaults.itemStateFadeEnabled ?? true
    readonly property real itemStateFadeMinOpacity: Math.max(0, Math.min(100, cfg.itemStateFadeMinOpacity ?? defaults.itemStateFadeMinOpacity ?? 88)) / 100
    readonly property int itemStateFadeOutDurationMs: Math.max(0, cfg.itemStateFadeOutDurationMs ?? defaults.itemStateFadeOutDurationMs ?? 55)
    readonly property int itemStateFadeInDurationMs: Math.max(0, cfg.itemStateFadeInDurationMs ?? defaults.itemStateFadeInDurationMs ?? 90)
    readonly property int itemPositionAnimationDurationMs: Math.max(0, cfg.itemPositionAnimationDurationMs ?? defaults.itemPositionAnimationDurationMs ?? Style.animationFast)
    readonly property int itemScaleAnimationDurationMs: Math.max(0, cfg.itemScaleAnimationDurationMs ?? defaults.itemScaleAnimationDurationMs ?? Style.animationNormal)
    readonly property int itemOpacityAnimationDurationMs: Math.max(0, cfg.itemOpacityAnimationDurationMs ?? defaults.itemOpacityAnimationDurationMs ?? Style.animationFast)
    readonly property int itemColorAnimationDurationMs: Math.max(0, cfg.itemColorAnimationDurationMs ?? defaults.itemColorAnimationDurationMs ?? Style.animationFast)
    readonly property var itemColors: cfg.itemColors ?? defaults.itemColors ?? ({})
    readonly property bool showPinnedApps: cfg.showPinnedApps ?? defaults.showPinnedApps ?? true
    readonly property bool groupApps: cfg.groupApps ?? defaults.groupApps ?? false
    readonly property string groupClickAction: cfg.groupClickAction ?? defaults.groupClickAction ?? "cycle"
    readonly property string groupContextMenuMode: cfg.groupContextMenuMode ?? defaults.groupContextMenuMode ?? "extended"
    readonly property string groupIndicatorStyle: cfg.groupIndicatorStyle ?? defaults.groupIndicatorStyle ?? "number"
    readonly property var ignoredWorkspaceIds: cfg.ignoredWorkspaceIds ?? defaults.ignoredWorkspaceIds ?? []
    readonly property var ignoredWorkspaceNames: cfg.ignoredWorkspaceNames ?? defaults.ignoredWorkspaceNames ?? []
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
    readonly property bool supportsLiveReorder: CompositorService.isNiri || CompositorService.isHyprland

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
    property var groupCycleIndices: ({})
    property var liveEntriesByKey: ({})
    property var stableWindowKeyEntries: []
    property int stableWindowKeyCounter: 0

    property int wheelAccumulatedDelta: 0
    property bool wheelCooldown: false
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property int pendingDragCommitSourceIndex: -1

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

    ItemStateColors {
        id: itemStateColors
    }

    function modelContext() {
        return {
            "CompositorService": CompositorService,
            "Settings": Settings,
            "screen": screen,
            "onlySameOutput": onlySameOutput,
            "onlyActiveWorkspaces": onlyActiveWorkspaces,
            "groupApps": groupApps,
            "workspaceGroupingActive": workspaceGroupingActive,
            "showWorkspaceSeparators": showWorkspaceSeparators,
            "workspaceSeparatorShowForFirst": workspaceSeparatorShowForFirst,
            "workspaceSeparatorPrefix": workspaceSeparatorPrefix,
            "workspaceSeparatorSuffix": workspaceSeparatorSuffix,
            "ignoredWorkspaceIds": ignoredWorkspaceIds,
            "ignoredWorkspaceNames": ignoredWorkspaceNames,
            "showPinnedApps": showPinnedApps,
            "stableWindowKeyEntries": stableWindowKeyEntries,
            "stableWindowKeyCounter": stableWindowKeyCounter,
            "getAppNameFromDesktopEntry": getAppNameFromDesktopEntry,
            "resolveToDesktopEntryId": resolveToDesktopEntryId,
            "isAppIdPinned": isAppIdPinned,
            "getPrimaryWindow": getPrimaryWindow
        };
    }

    function syncModelContext(context) {
        stableWindowKeyEntries = context.stableWindowKeyEntries;
        stableWindowKeyCounter = context.stableWindowKeyCounter;
    }

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

    function resolvedIconTintColor() {
        const baseColor = (!iconColorKey || iconColorKey === "none") ? Color.mPrimary : Color.resolveColorKey(iconColorKey);
        const alpha = Math.max(0, Math.min(100, iconColorOpacity)) / 100;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, alpha);
    }

    function resolveItemStateColor(stateKey, colorRole) {
        return itemStateColors.resolveItemStateColor(itemColors, stateKey, colorRole);
    }

    function resolveItemStateColorWithOpacity(stateKey, colorRole) {
        return itemStateColors.resolveItemStateColorWithOpacity(itemColors, stateKey, colorRole);
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
        return Qt.rgba(r1 + (effColor.r - r1) * eRatio, g1 + (effColor.g - g1) * eRatio, b1 + (effColor.b - b1) * eRatio, 1);
    }

    function normalizeAppId(appId) {
        return TaskbarModel.normalizeAppId(appId);
    }

    function getWindowHandle(window) {
        return TaskbarModel.getWindowHandle(window);
    }

    function getStableWindowKey(window) {
        const context = modelContext();
        const key = TaskbarModel.getStableWindowKey(context, window);
        syncModelContext(context);
        return key;
    }

    function pruneStableWindowKeys(activeWindows) {
        const context = modelContext();
        TaskbarModel.pruneStableWindowKeys(context, activeWindows);
        syncModelContext(context);
    }

    function getAppKey(appData) {
        return TaskbarModel.getAppKey(modelContext(), appData);
    }

    function getEntryKey(appData) {
        const context = modelContext();
        const key = TaskbarModel.getEntryKey(context, appData);
        syncModelContext(context);
        return key;
    }

    function isAppEntry(entry) {
        return TaskbarModel.isAppEntry(entry);
    }

    function getAppEntries(entries) {
        return TaskbarModel.getAppEntries(entries);
    }

    function getWorkspaceInfo(workspaceId) {
        return TaskbarModel.getWorkspaceInfo(modelContext(), workspaceId);
    }

    function getWorkspaceLabel(workspaceIndex) {
        return TaskbarModel.getWorkspaceLabel(modelContext(), workspaceIndex);
    }

    function isWorkspaceIgnored(workspaceId) {
        return TaskbarModel.isWorkspaceIgnored(modelContext(), workspaceId);
    }

    function getWorkspaceReference(workspaceId) {
        return TaskbarModel.getWorkspaceReference(modelContext(), workspaceId);
    }

    function reorderApps(fromIndex, toIndex) {
        Logger.d("Taskbar2", "Reordering apps from " + fromIndex + " to " + toIndex);
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || fromIndex >= combinedModel.length || toIndex >= combinedModel.length)
            return;

        const fromItem = combinedModel[fromIndex];
        const toItem = combinedModel[toIndex];
        if (!isAppEntry(fromItem))
            return;

        if (isAppEntry(toItem) && fromItem.type === "pinned" && toItem.type === "pinned") {
            reorderPinnedApps(fromItem.appId, toItem.appId);
            return;
        }

        if (!supportsLiveReorder)
            return;

        moveLiveEntry(fromItem, toItem);
    }

    function updateDragTargetForItem(sourceIndex, dragItem) {
        if (!dragItem || sourceIndex < 0 || sourceIndex >= combinedModel.length) {
            dragTargetIndex = -1;
            return;
        }

        const dragCenter = dragItem.mapToItem(visualCapsule, dragItem.width / 2, dragItem.height / 2);
        const dragAxis = isVerticalBar ? dragCenter.y : dragCenter.x;
        let nextTargetIndex = -1;
        let closestDistance = Number.POSITIVE_INFINITY;

        for (let i = 0; i < entryRepeater.count; i++) {
            if (i === sourceIndex)
                continue;

            const candidateItem = entryRepeater.itemAt(i);
            if (!candidateItem || !candidateItem.visible || !candidateItem.reorderDropEnabled)
                continue;

            const candidateCenter = candidateItem.mapToItem(visualCapsule, candidateItem.width / 2, candidateItem.height / 2);
            const candidateAxis = isVerticalBar ? candidateCenter.y : candidateCenter.x;
            const distance = Math.abs(candidateAxis - dragAxis);
            if (distance < closestDistance) {
                closestDistance = distance;
                nextTargetIndex = i;
            }
        }

        dragTargetIndex = nextTargetIndex;
    }

    function completeDragReorder(fromIndex, toIndex) {
        pendingDragCommitSourceIndex = -1;
        dragSourceIndex = -1;
        dragTargetIndex = -1;

        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 || fromIndex >= combinedModel.length || toIndex >= combinedModel.length)
            return;

        const targetItem = combinedModel[toIndex];
        if (!targetItem)
            return;

        if (targetItem.type === "workspace-target") {
            const fromItem = combinedModel[fromIndex];
            if (fromItem && supportsLiveReorder)
                moveLiveEntry(fromItem, targetItem);
            return;
        }

        reorderApps(fromIndex, toIndex);
    }

    function queueDragCommit(fromIndex, toIndex) {
        if (fromIndex < 0)
            return;

        pendingDragCommitSourceIndex = fromIndex;
        Qt.callLater(function () {
            if (pendingDragCommitSourceIndex !== fromIndex)
                return;
            completeDragReorder(fromIndex, toIndex);
        });
    }

    function reorderPinnedApps(sourceAppId, targetAppId) {
        const currentPinned = (Settings.data.dock.pinnedApps || []).slice();
        const sourceIndex = currentPinned.findIndex(appId => normalizeAppId(appId) === normalizeAppId(sourceAppId));
        const targetIndex = currentPinned.findIndex(appId => normalizeAppId(appId) === normalizeAppId(targetAppId));
        if (sourceIndex === -1 || targetIndex === -1 || sourceIndex === targetIndex)
            return;

        const moved = currentPinned.splice(sourceIndex, 1)[0];
        currentPinned.splice(targetIndex, 0, moved);
        Settings.data.dock.pinnedApps = currentPinned;
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
        return TaskbarModel.collectVisibleWindows(modelContext());
    }

    function getActiveWorkspaceIds() {
        return TaskbarModel.getActiveWorkspaceIds(modelContext());
    }

    function windowPasses(window, activeIds) {
        return TaskbarModel.windowPasses(modelContext(), window, activeIds);
    }

    function buildGroupedModel(apps) {
        const context = modelContext();
        const grouped = TaskbarModel.buildGroupedModel(context, apps);
        syncModelContext(context);
        return grouped;
    }

    function buildWorkspaceGroupedModel(apps) {
        const context = modelContext();
        const grouped = TaskbarModel.buildWorkspaceGroupedModel(context, apps);
        syncModelContext(context);
        return grouped;
    }

    function buildLiveEntries(structuralEntries, windowsById, windowsByStableKey) {
        return TaskbarModel.buildLiveEntries(modelContext(), structuralEntries, windowsById, windowsByStableKey);
    }

    function getStructuralSignature(entry) {
        return TaskbarModel.getStructuralSignature(modelContext(), entry);
    }

    function hasStructuralChange(nextEntries) {
        return TaskbarModel.hasStructuralChange(modelContext(), combinedModel, nextEntries);
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
        return;
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
        const context = modelContext();
        const entries = TaskbarModel.buildStructuralEntries(context);
        syncModelContext(context);
        return entries;
    }

    function updateCombinedModel(forceStructural) {
        applySnapshot(buildStructuralEntries(), forceStructural === true);
    }

    function refreshLiveData() {
        applySnapshot(buildStructuralEntries(), false);
    }

    function refreshAllIndicatorRects() {
        for (let i = 0; i < entryRepeater.count; i++) {
            const item = entryRepeater.itemAt(i);
            if (item && item.syncIndicatorRect)
                item.syncIndicatorRect();
        }
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
        return TaskbarModel.getFocusedEntryKey(liveEntries);
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

    function getAnchorWindowForEntry(entry) {
        if (!entry)
            return null;
        const liveEntry = getLiveEntry(entry.entryKey);
        if (!liveEntry)
            return null;
        return liveEntry.anchorWindow || liveEntry.primaryWindow || null;
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
                Hyprland.dispatch("focuswindow " + getHyprlandAddressSelector(window));
                return true;
            }
        } catch (error) {
            Logger.e("Taskbar2", "Failed backend focus: " + error);
        }
        return false;
    }

    function getHyprlandAddressSelector(window) {
        if (!window || window.id === undefined || window.id === null)
            return "";
        const rawId = String(window.id).trim();
        if (rawId.length === 0)
            return "";
        return rawId.startsWith("0x") ? ("address:" + rawId) : ("address:0x" + rawId);
    }

    function moveWindowToWorkspace(window, workspaceId) {
        if (!window || workspaceId === undefined || workspaceId === null || workspaceId === -1 || isWorkspaceIgnored(workspaceId))
            return;

        const previousFocused = CompositorService.getFocusedWindow ? CompositorService.getFocusedWindow() : null;
        const workspaceRef = getWorkspaceReference(workspaceId);

        try {
            if (CompositorService.isNiri) {
                Niri.dispatch(["move-window-to-workspace", "--window-id", String(window.id), "--focus", "false", workspaceRef]);
            } else if (CompositorService.isHyprland) {
                const selector = getHyprlandAddressSelector(window);
                if (!selector)
                    return;
                Hyprland.dispatch("movetoworkspacesilent " + workspaceRef + "," + selector);
            }
        } catch (error) {
            Logger.e("Taskbar2", "Failed workspace move: " + error);
        }

        if (previousFocused && previousFocused.id != window.id)
            Qt.callLater(function () {
                root.focusWindowByBackend(previousFocused);
            });
    }

    function moveLiveEntry(fromItem, toItem) {
        const sourceWindow = getAnchorWindowForEntry(fromItem);
        if (!sourceWindow)
            return;

        const targetWorkspaceId = toItem ? (toItem.workspaceId ?? -1) : -1;
        const targetWindow = toItem && isAppEntry(toItem) ? getAnchorWindowForEntry(toItem) : null;

        if (targetWorkspaceId !== -1 && sourceWindow.workspaceId !== targetWorkspaceId) {
            moveWindowToWorkspace(sourceWindow, toItem.workspaceId);
            return;
        }

        const previousFocused = CompositorService.getFocusedWindow ? CompositorService.getFocusedWindow() : null;
        if (!focusWindowByBackend(sourceWindow))
            return;

        try {
            if (CompositorService.isNiri) {
                const sameWorkspaceEntries = getAppEntries(combinedModel).filter(entry => (entry.workspaceId ?? -1) === (fromItem.workspaceId ?? -1));
                let targetIndex = 1;
                for (let i = 0; i < sameWorkspaceEntries.length; i++) {
                    if (sameWorkspaceEntries[i].entryKey === toItem.entryKey) {
                        targetIndex = i + 1;
                        break;
                    }
                }
                Niri.dispatch(["move-column-to-index", String(targetIndex)]);
            } else if (CompositorService.isHyprland && targetWindow) {
                const selector = getHyprlandAddressSelector(targetWindow);
                if (!selector)
                    return;
                Hyprland.dispatch("swapwindow " + selector);
            }
        } catch (error) {
            Logger.e("Taskbar2", "Failed live reorder: " + error);
        }

        if (previousFocused && previousFocused.id != sourceWindow.id)
            Qt.callLater(function () {
                root.focusWindowByBackend(previousFocused);
            });
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
        contextMenu.openForItem(item, menuModeOverride);
    }

    TaskbarContextMenu {
        id: contextMenu
        barRoot: root
        onRequestFlushPendingModelRefresh: root.flushPendingModelRefresh()
    }

    Connections {
        target: CompositorService
        function onActiveWindowChanged() {
            if (groupApps)
                scheduleModelRefresh(true);
            else
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
    onIgnoredWorkspaceIdsChanged: scheduleModelRefresh(true)
    onIgnoredWorkspaceNamesChanged: scheduleModelRefresh(true)
    onGroupByWorkspaceIndexChanged: scheduleModelRefresh(true)
    onShowWorkspaceSeparatorsChanged: scheduleModelRefresh(true)
    onHoveredEntryKeyChanged: flushPendingModelRefresh()
    onDragSourceIndexChanged: flushPendingModelRefresh()
    onFocusTransitionEnabledChanged: if (!focusTransitionEnabled)
        focusTransitionOverlay.cancelTransition()
    onFocusTransitionStyleChanged: focusTransitionOverlay.cancelTransition()
    onFocusTransitionIntensityChanged: focusTransitionOverlay.cancelTransition()
    Component.onCompleted: {
        updateCombinedModel(true);
    }
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
            columnSpacing: root.itemGap
            rowSpacing: root.itemGap

            rows: isVerticalBar ? -1 : 1
            columns: isVerticalBar ? 1 : -1

            Repeater {
                id: entryRepeater
                model: root.combinedModel
                delegate: TaskbarEntryDelegate {
                    barWidgetRoot: root
                    stateColors: itemStateColors
                    capsuleItem: visualCapsule
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
    }
}
