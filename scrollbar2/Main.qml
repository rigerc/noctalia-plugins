import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Niri
import Quickshell.Wayland
import qs.Commons
import qs.Services.Compositor
import "./components"

Item {
    id: root

    property var pluginApi: null
    property var currentSettings: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    property var allEntries: []
    property var liveEntriesByKey: ({})
    property var titleEntriesByKey: ({})
    property var compositorWorkspaces: []
    property string activeEntryKey: ""
    property int structureRevision: 0
    property int liveRevision: 0
    property int titleRevision: 0
    property int workspaceRevision: 0
    property int activeSpecialRevision: 0
    property var cycleStateByApp: ({})
    property var _desktopEntryIdCache: ({})
    property var activeSpecialByMonitor: ({})
    property string requestedStyleRuleMatchField: ""
    property string requestedStyleRulePattern: ""
    property int requestedStyleRuleRevision: 0
    property bool reorderInFlight: false
    property var hyprlandReorderState: null

    Timer {
        id: reorderReleaseTimer
        interval: 260
        repeat: false
        onTriggered: {
            root.refreshBackendState();
            root.reorderInFlight = false;
        }
    }

    Timer {
        id: hyprlandReorderTimer
        interval: 24
        repeat: false
        onTriggered: {
            root.advanceHyprlandReorder();
        }
    }

    function refreshSettingsSnapshot() {
        currentSettings = pluginApi?.pluginSettings || ({});
    }

    onPluginApiChanged: refreshSettingsSnapshot()

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshSettingsSnapshot();
        }
    }

    function settingValue(groupKey, nestedKey, fallbackValue) {
        const configGroup = currentSettings ? currentSettings[groupKey] : undefined;
        const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
        if (nestedConfig !== undefined)
            return nestedConfig;

        const defaultsGroup = defaults ? defaults[groupKey] : undefined;
        const nestedDefault = defaultsGroup ? defaultsGroup[nestedKey] : undefined;
        if (nestedDefault !== undefined)
            return nestedDefault;

        return fallbackValue;
    }

    function objectSettingValue(groupKey, objectKey, nestedKey, fallbackValue) {
        const configValue = currentSettings?.[groupKey]?.[objectKey]?.[nestedKey];
        if (configValue !== undefined)
            return configValue;

        const defaultValue = defaults?.[groupKey]?.[objectKey]?.[nestedKey];
        if (defaultValue !== undefined)
            return defaultValue;

        return fallbackValue;
    }

    function normalizeOpacityValue(value) {
        const numericValue = Number(value);
        if (isNaN(numericValue))
            return 0;
        if (numericValue > 1)
            return Math.max(0, Math.min(1, numericValue / 100));
        return Math.max(0, Math.min(1, numericValue));
    }

    function resolveThemeColor(key) {
        switch (key) {
        case "none":
            return "transparent";
        case "primary":
            return Color.mPrimary;
        case "on-primary":
            return Color.mOnPrimary;
        case "secondary":
            return Color.mSecondary;
        case "on-secondary":
            return Color.mOnSecondary;
        case "tertiary":
            return Color.mTertiary;
        case "on-tertiary":
            return Color.mOnTertiary;
        case "error":
            return Color.mError;
        case "on-error":
            return Color.mOnError;
        case "surface":
            return Color.mSurface;
        case "on-surface":
            return Color.mOnSurface;
        case "surface-variant":
            return Color.mSurfaceVariant;
        case "on-surface-variant":
            return Color.mOnSurfaceVariant;
        case "outline":
            return Color.mOutline;
        case "hover":
            return Color.mHover;
        case "on-hover":
            return Color.mOnHover;
        default:
            return undefined;
        }
    }

    function isHexColorString(value) {
        return typeof value === "string" && /^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value);
    }

    function resolveSettingColor(value, fallbackColor) {
        const themeColor = resolveThemeColor(value);
        if (themeColor !== undefined)
            return themeColor;
        if (isHexColorString(value))
            return value;
        return fallbackColor;
    }

    function deepCopy(value) {
        try {
            return JSON.parse(JSON.stringify(value || ({})));
        } catch (error) {
            return ({});
        }
    }

    function specialWorkspaceRecord(workspaceId, workspaceName) {
        const trimmedId = String(workspaceId ?? "").trim();
        const trimmedName = String(workspaceName ?? "").trim();
        if (trimmedId === "" && trimmedName === "")
            return null;

        return {
            "id": trimmedId,
            "name": trimmedName
        };
    }

    function updateActiveSpecialForMonitor(monitorName, workspaceId, workspaceName) {
        const normalizedMonitorName = String(monitorName || "").trim();
        if (normalizedMonitorName === "")
            return;

        const nextState = Object.assign({}, activeSpecialByMonitor);
        const nextRecord = specialWorkspaceRecord(workspaceId, workspaceName);
        const previousRecord = nextState[normalizedMonitorName] || null;

        if (!nextRecord) {
            if (!previousRecord)
                return;
            delete nextState[normalizedMonitorName];
        } else if (previousRecord && previousRecord.id === nextRecord.id && previousRecord.name === nextRecord.name) {
            return;
        } else {
            nextState[normalizedMonitorName] = nextRecord;
        }

        activeSpecialByMonitor = nextState;
        activeSpecialRevision += 1;
    }

    function refreshActiveSpecialSnapshot() {
        if (!CompositorService.isHyprland) {
            if (Object.keys(activeSpecialByMonitor).length === 0)
                return;
            activeSpecialByMonitor = ({});
            activeSpecialRevision += 1;
            return;
        }

        try {
            const monitors = Hyprland.monitors.values;
            const nextState = ({});
            for (let i = 0; i < monitors.length; i++) {
                const monitor = monitors[i];
                const monitorName = String(monitor?.name || "").trim();
                const record = specialWorkspaceRecord(monitor?.specialWorkspace?.id, monitor?.specialWorkspace?.name);
                if (monitorName !== "" && record)
                    nextState[monitorName] = record;
            }

            if (JSON.stringify(nextState) === JSON.stringify(activeSpecialByMonitor))
                return;

            activeSpecialByMonitor = nextState;
            activeSpecialRevision += 1;
        } catch (error) {
            Logger.w("Scrollbar2", "Failed to read active special workspaces: " + error);
        }
    }

    readonly property string displayMode: settingValue("display", "mode", "floatingPanel")
    readonly property real displayOffsetH: settingValue("display", "offsetH", 0)
    readonly property real displayOffsetV: settingValue("display", "offsetV", 0)
    readonly property real displayScale: Math.max(0.5, settingValue("display", "scale", 1.0))
    readonly property real displayMargin: Math.max(0, Math.round(settingValue("display", "margin", 0) * Style.uiScaleRatio))
    readonly property real displayRadiusScale: Math.max(0, settingValue("display", "radiusScale", 1.0))
    readonly property string displayBackgroundColorKey: objectSettingValue("display", "background", "color", settingValue("display", "backgroundColor", "none"))
    readonly property real displayBackgroundOpacity: normalizeOpacityValue(objectSettingValue("display", "background", "opacity", settingValue("display", "backgroundOpacity", 0)))
    readonly property bool displayGradientEnabled: settingValue("display", "gradientEnabled", false)
    readonly property string displayGradientColorKey: objectSettingValue("display", "gradient", "color", settingValue("display", "gradientColor", "none"))
    readonly property real displayGradientOpacity: normalizeOpacityValue(objectSettingValue("display", "gradient", "opacity", settingValue("display", "gradientOpacity", 0)))
    readonly property string displayGradientDirection: settingValue("display", "gradientDirection", "vertical")
    readonly property string trackPosition: settingValue("track", "position", "bottom")
    readonly property real effectiveDisplayRadius: Style.radiusL * displayRadiusScale
    readonly property bool displayBackgroundEnabled: displayBackgroundColorKey !== "none" && displayBackgroundOpacity > 0
    readonly property color displayBackgroundBaseColor: resolveSettingColor(displayBackgroundColorKey, "transparent")
    readonly property color displayBackgroundResolvedColor: displayBackgroundEnabled ? Qt.alpha(displayBackgroundBaseColor, displayBackgroundOpacity) : "transparent"
    readonly property bool displayGradientActive: displayGradientEnabled && displayGradientColorKey !== "none" && displayGradientOpacity > 0
    readonly property color displayGradientBaseColor: resolveSettingColor(displayGradientColorKey, "transparent")
    readonly property color displayGradientResolvedColor: displayGradientActive ? Qt.alpha(displayGradientBaseColor, displayGradientOpacity) : "transparent"

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
        } catch (error) {}

        return appId;
    }

    function normalizeAppId(appId) {
        if (!appId || typeof appId !== "string")
            return "";
        return appId.toLowerCase().trim();
    }

    function normalizedWorkspaceToken(value) {
        if (value === undefined || value === null)
            return "";
        return String(value).trim();
    }

    function sameWorkspace(a, b) {
        return normalizedWorkspaceToken(a?.workspaceId) !== "" && normalizedWorkspaceToken(a?.workspaceId) === normalizedWorkspaceToken(b?.workspaceId);
    }

    function sameOutput(a, b) {
        return normalizeAppId(a?.output || "") === normalizeAppId(b?.output || "");
    }

    function extractNiriLayoutValue(layoutValue, firstKey, secondKey) {
        if (layoutValue === undefined || layoutValue === null)
            return undefined;
        if (Array.isArray(layoutValue)) {
            const index = firstKey === "column" ? 0 : 1;
            const numericArrayValue = Number(layoutValue[index]);
            return isNaN(numericArrayValue) ? undefined : numericArrayValue;
        }

        if (typeof layoutValue === "object") {
            const directValue = Number(layoutValue[firstKey]);
            if (!isNaN(directValue))
                return directValue;
            const fallbackValue = Number(layoutValue[secondKey]);
            if (!isNaN(fallbackValue))
                return fallbackValue;
        }

        return undefined;
    }

    function extractNiriLayoutPosition(window) {
        const rawLayout = window?.layout?.posInScrollingLayout
            ?? window?.layout?.pos_in_scrolling_layout
            ?? window?.posInScrollingLayout
            ?? window?.pos_in_scrolling_layout
            ?? null;
        if (!rawLayout)
            return null;

        const column = extractNiriLayoutValue(rawLayout, "column", "x");
        const tile = extractNiriLayoutValue(rawLayout, "tile", "y");
        if (column === undefined && tile === undefined)
            return null;

        return {
            "column": column,
            "tile": tile
        };
    }

    function backendMetadataByWindowId() {
        const metadata = ({});

        if (CompositorService.isHyprland) {
            try {
                const toplevels = Hyprland.toplevels?.values || [];
                for (let i = 0; i < toplevels.length; i++) {
                    const toplevel = toplevels[i];
                    const address = String(toplevel?.address || "").trim();
                    if (address === "")
                        continue;
                    metadata[address] = {
                        "isFloating": toplevel?.lastIpcObject?.floating === true
                    };
                }
            } catch (error) {}
        } else if (CompositorService.isNiri) {
            try {
                const windows = Niri.windows?.values || [];
                for (let i = 0; i < windows.length; i++) {
                    const window = windows[i];
                    const windowId = String(window?.id || "").trim();
                    if (windowId === "")
                        continue;
                    const layoutPosition = extractNiriLayoutPosition(window);
                    metadata[windowId] = {
                        "isFloating": window?.isFloating === true,
                        "niriColumnIndex": layoutPosition?.column,
                        "niriTileIndex": layoutPosition?.tile
                    };
                }
            } catch (error) {}
        }

        return metadata;
    }

    function getDesktopEntry(appId) {
        if (!appId || typeof DesktopEntries === "undefined")
            return null;

        try {
            if (DesktopEntries.heuristicLookup) {
                const heuristicEntry = DesktopEntries.heuristicLookup(appId);
                if (heuristicEntry)
                    return heuristicEntry;
            }
        } catch (error) {}

        try {
            if (DesktopEntries.byId) {
                const directEntry = DesktopEntries.byId(appId);
                if (directEntry)
                    return directEntry;
            }
        } catch (error) {}

        return null;
    }

    function resolveToDesktopEntryId(appId) {
        if (!appId)
            return "";
        if (_desktopEntryIdCache.hasOwnProperty(appId))
            return _desktopEntryIdCache[appId];

        const desktopEntryId = getDesktopEntry(appId)?.id || appId;
        _desktopEntryIdCache[appId] = desktopEntryId;
        return desktopEntryId;
    }

    function pinnedAppItems() {
        const configuredItems = currentSettings?.pinnedApps?.items;
        if (Array.isArray(configuredItems))
            return configuredItems;
        const defaultItems = defaults?.pinnedApps?.items;
        return Array.isArray(defaultItems) ? defaultItems : [];
    }

    function getPinnedAppRecord(appId) {
        const canonicalId = resolveToDesktopEntryId(appId);
        if (!canonicalId)
            return null;

        const items = pinnedAppItems();
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            if (resolveToDesktopEntryId(item?.appId || "") === canonicalId)
                return item;
        }
        return null;
    }

    function isAppPinned(appId) {
        return !!getPinnedAppRecord(appId);
    }

    function updatePluginSettings(mutator) {
        if (!pluginApi)
            return;

        const nextSettings = deepCopy(pluginApi.pluginSettings || ({}));
        mutator(nextSettings);
        pluginApi.pluginSettings = nextSettings;
        pluginApi.saveSettings();
        refreshSettingsSnapshot();
    }

    function normalizeStyleRuleColorState(source, fallbackColor, fallbackOpacity) {
        const currentValue = (source && typeof source === "object" && !Array.isArray(source)) ? source : ({});
        return {
            "color": String(currentValue.color ?? fallbackColor),
            "opacity": normalizeOpacityValue(currentValue.opacity ?? fallbackOpacity)
        };
    }

    function normalizeStyleRule(rule) {
        const source = (rule && typeof rule === "object" && !Array.isArray(rule)) ? rule : ({});
        return {
            "enabled": source.enabled !== false,
            "matchField": source.matchField === "title" ? "title" : "appId",
            "pattern": String(source.pattern || ""),
            "customIcon": String(source.customIcon || ""),
            "colors": {
                "segment": {
                    "focused": normalizeStyleRuleColorState(source.colors?.segment?.focused, nestedStateColorValue("focusLine", "focused", "primary"), nestedStateOpacityValue("focusLine", "focused", 1)),
                    "hover": normalizeStyleRuleColorState(source.colors?.segment?.hover, nestedStateColorValue("focusLine", "hover", "hover"), nestedStateOpacityValue("focusLine", "hover", 1)),
                    "default": normalizeStyleRuleColorState(source.colors?.segment?.default, nestedStateColorValue("focusLine", "default", "surface-variant"), nestedStateOpacityValue("focusLine", "default", 1))
                },
                "icon": {
                    "focused": normalizeStyleRuleColorState(source.colors?.icon?.focused, objectWindowSettingValue("iconColors", "focused", "on-surface"), nestedWindowStateOpacityValue("iconColors", "focused", 1)),
                    "hover": normalizeStyleRuleColorState(source.colors?.icon?.hover, objectWindowSettingValue("iconColors", "hover", "on-hover"), nestedWindowStateOpacityValue("iconColors", "hover", 1)),
                    "default": normalizeStyleRuleColorState(source.colors?.icon?.default, objectWindowSettingValue("iconColors", "default", "on-surface-variant"), nestedWindowStateOpacityValue("iconColors", "default", 1))
                },
                "title": {
                    "focused": normalizeStyleRuleColorState(source.colors?.title?.focused, objectWindowSettingValue("titleColors", "focused", "on-surface"), nestedWindowStateOpacityValue("titleColors", "focused", 1)),
                    "hover": normalizeStyleRuleColorState(source.colors?.title?.hover, objectWindowSettingValue("titleColors", "hover", "on-hover"), nestedWindowStateOpacityValue("titleColors", "hover", 1)),
                    "default": normalizeStyleRuleColorState(source.colors?.title?.default, objectWindowSettingValue("titleColors", "default", "on-surface-variant"), nestedWindowStateOpacityValue("titleColors", "default", 1))
                }
            }
        };
    }

    function nestedStateColorValue(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.[groupKey]?.colors?.[stateKey]?.color;
        if (value !== undefined)
            return value;

        const defaultValue = defaults?.[groupKey]?.colors?.[stateKey]?.color;
        if (defaultValue !== undefined)
            return defaultValue;

        return fallbackValue;
    }

    function objectWindowSettingValue(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.window?.[groupKey]?.[stateKey]?.color;
        if (value !== undefined)
            return value;

        const defaultValue = defaults?.window?.[groupKey]?.[stateKey]?.color;
        if (defaultValue !== undefined)
            return defaultValue;

        return fallbackValue;
    }

    function nestedStateOpacityValue(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.[groupKey]?.colors?.[stateKey]?.opacity;
        if (value !== undefined)
            return normalizeOpacityValue(value);

        const defaultValue = defaults?.[groupKey]?.colors?.[stateKey]?.opacity;
        if (defaultValue !== undefined)
            return normalizeOpacityValue(defaultValue);

        return fallbackValue;
    }

    function nestedWindowStateOpacityValue(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.window?.[groupKey]?.[stateKey]?.opacity;
        if (value !== undefined)
            return normalizeOpacityValue(value);

        const defaultValue = defaults?.window?.[groupKey]?.[stateKey]?.opacity;
        if (defaultValue !== undefined)
            return normalizeOpacityValue(defaultValue);

        return fallbackValue;
    }

    function escapeRegexLiteral(text) {
        return String(text || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    }

    function appendStyleRule(rule, insertAtFront) {
        updatePluginSettings(function (nextSettings) {
            const currentRules = Array.isArray(nextSettings.customStyleRules) ? nextSettings.customStyleRules.slice() : [];
            const normalizedRule = normalizeStyleRule(rule);
            if (insertAtFront)
                currentRules.unshift(normalizedRule);
            else
                currentRules.push(normalizedRule);
            nextSettings.customStyleRules = currentRules;
        });
    }

    function styleRuleItems() {
        const configuredRules = currentSettings?.customStyleRules;
        return Array.isArray(configuredRules) ? configuredRules.map(normalizeStyleRule) : [];
    }

    function findStyleRuleIndex(matchField, pattern) {
        const normalizedMatchField = matchField === "title" ? "title" : "appId";
        const normalizedPattern = String(pattern || "").trim();
        if (normalizedPattern === "")
            return -1;

        const rules = styleRuleItems();
        for (let index = 0; index < rules.length; index++) {
            const rule = rules[index];
            if ((rule?.matchField ?? "appId") !== normalizedMatchField)
                continue;
            if (String(rule?.pattern || "").trim() !== normalizedPattern)
                continue;
            return index;
        }
        return -1;
    }

    function buildPrefilledStyleRule(entryKey, matchField) {
        const window = getWindowByEntry(entryKey);
        const resolvedMatchField = matchField === "title" ? "title" : "appId";
        const rawValue = resolvedMatchField === "title"
            ? String(titleEntriesByKey?.[entryKey] ?? window?.title ?? "")
            : String(resolveToDesktopEntryId(window?.appId || "") || window?.appId || "");
        if (String(rawValue).trim() === "")
            return null;

        return normalizeStyleRule({
            "enabled": true,
            "matchField": resolvedMatchField,
            "pattern": "^" + escapeRegexLiteral(rawValue) + "$"
        });
    }

    function findPrefilledStyleRuleIndex(entryKey, matchField) {
        const rule = buildPrefilledStyleRule(entryKey, matchField);
        if (!rule)
            return -1;
        return findStyleRuleIndex(rule.matchField, rule.pattern);
    }

    function requestStyleRuleEdit(matchField, pattern) {
        requestedStyleRuleMatchField = matchField === "title" ? "title" : "appId";
        requestedStyleRulePattern = String(pattern || "").trim();
        requestedStyleRuleRevision += 1;
    }

    function requestPrefilledStyleRuleEdit(entryKey, matchField) {
        const rule = buildPrefilledStyleRule(entryKey, matchField);
        if (!rule)
            return false;
        requestStyleRuleEdit(rule.matchField, rule.pattern);
        return true;
    }

    function toggleAppPin(appId) {
        const canonicalId = resolveToDesktopEntryId(appId);
        if (!canonicalId)
            return;

        updatePluginSettings(function (nextSettings) {
            if (!nextSettings.pinnedApps || typeof nextSettings.pinnedApps !== "object" || Array.isArray(nextSettings.pinnedApps))
                nextSettings.pinnedApps = ({});
            const currentItems = Array.isArray(nextSettings.pinnedApps.items) ? nextSettings.pinnedApps.items : [];
            const existingIndex = currentItems.findIndex(function (item) {
                return resolveToDesktopEntryId(item?.appId || "") === canonicalId;
            });

            if (existingIndex >= 0) {
                currentItems.splice(existingIndex, 1);
                delete cycleStateByApp[canonicalId];
            } else {
                currentItems.push({
                    "appId": canonicalId,
                    "customIcon": ""
                });
            }

            nextSettings.pinnedApps.items = currentItems;
        });
    }

    function setPinnedAppCustomIcon(appId, customIcon) {
        const canonicalId = resolveToDesktopEntryId(appId);
        if (!canonicalId)
            return;

        updatePluginSettings(function (nextSettings) {
            if (!nextSettings.pinnedApps || typeof nextSettings.pinnedApps !== "object" || Array.isArray(nextSettings.pinnedApps))
                nextSettings.pinnedApps = ({});
            const currentItems = Array.isArray(nextSettings.pinnedApps.items) ? nextSettings.pinnedApps.items : [];
            const existingIndex = currentItems.findIndex(function (item) {
                return resolveToDesktopEntryId(item?.appId || "") === canonicalId;
            });
            if (existingIndex < 0)
                return;

            currentItems[existingIndex] = {
                "appId": canonicalId,
                "customIcon": String(customIcon || "")
            };
            nextSettings.pinnedApps.items = currentItems;
        });
    }

    function removePinnedApp(appId) {
        if (isAppPinned(appId))
            toggleAppPin(appId);
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

    function collectWindows() {
        const windows = [];
        const backendMetadata = backendMetadataByWindowId();
        try {
            const total = CompositorService.windows?.count || 0;
            for (let i = 0; i < total; i++) {
                const window = CompositorService.windows.get(i);
                if (!window)
                    continue;
                const id = String(window?.id || "").trim();
                const extra = id !== "" ? (backendMetadata[id] || ({})) : ({});
                windows.push(Object.assign({}, window, extra));
            }
        } catch (error) {}
        return windows;
    }

    function collectWorkspaces() {
        const workspaces = [];
        try {
            const total = CompositorService.workspaces?.count || 0;
            for (let i = 0; i < total; i++) {
                const workspace = CompositorService.workspaces.get(i);
                if (workspace)
                    workspaces.push(workspace);
            }
        } catch (error) {}
        return workspaces;
    }

    function cloneWorkspaceData(workspace) {
        return {
            "id": workspace?.id,
            "idx": workspace?.idx,
            "name": workspace?.name || "",
            "output": workspace?.output || "",
            "isFocused": workspace?.isFocused === true,
            "isActive": workspace?.isActive === true,
            "isUrgent": workspace?.isUrgent === true,
            "isOccupied": workspace?.isOccupied === true
        };
    }

    function workspaceOutputMatches(workspace, screenName) {
        if (!workspace)
            return false;
        if (CompositorService.globalWorkspaces)
            return true;
        if (!screenName)
            return true;
        return String(workspace.output || "").toLowerCase() === String(screenName || "").toLowerCase();
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

    function refreshWorkspaceSnapshot() {
        compositorWorkspaces = collectWorkspaces().map(cloneWorkspaceData);
        workspaceRevision += 1;
    }

    function workspaceToken(workspace) {
        if (!workspace)
            return "";
        if (workspace.id !== undefined && workspace.id !== null && String(workspace.id) !== "")
            return String(workspace.id);
        if (workspace.idx !== undefined && workspace.idx !== null && String(workspace.idx) !== "")
            return String(workspace.idx);
        if (workspace.name)
            return String(workspace.name);
        return "";
    }

    function resolveWorkspaceForScreen(screenName) {
        const normalizedScreenName = String(screenName || "").toLowerCase();
        const matchingWorkspaces = compositorWorkspaces.filter(function (workspace) {
            return workspaceOutputMatches(workspace, normalizedScreenName);
        });

        for (let i = 0; i < matchingWorkspaces.length; i++) {
            if (matchingWorkspaces[i].isFocused)
                return matchingWorkspaces[i];
        }
        for (let i = 0; i < matchingWorkspaces.length; i++) {
            if (matchingWorkspaces[i].isActive)
                return matchingWorkspaces[i];
        }
        for (let i = 0; i < compositorWorkspaces.length; i++) {
            if (compositorWorkspaces[i].isFocused)
                return compositorWorkspaces[i];
        }
        for (let i = 0; i < compositorWorkspaces.length; i++) {
            if (compositorWorkspaces[i].isActive)
                return compositorWorkspaces[i];
        }
        if (matchingWorkspaces.length > 0)
            return matchingWorkspaces[0];
        if (compositorWorkspaces.length > 0)
            return compositorWorkspaces[0];
        return null;
    }

    function resolveSpecialWorkspaceForScreen(screenName) {
        const normalizedScreenName = String(screenName || "").trim().toLowerCase();
        for (const monitorName in activeSpecialByMonitor) {
            if (String(monitorName || "").trim().toLowerCase() === normalizedScreenName)
                return activeSpecialByMonitor[monitorName];
        }
        return null;
    }

    function countWindowsForWorkspace(screenName, workspaceId) {
        if (workspaceId === undefined || workspaceId === null || workspaceId === "")
            return 0;

        const normalizedScreenName = String(screenName || "").toLowerCase();
        let count = 0;
        const windows = collectWindows();
        for (let i = 0; i < windows.length; i++) {
            const window = windows[i];
            if (!window || window.workspaceId !== workspaceId)
                continue;
            if (!workspaceOutputMatches({
                "output": window.output || ""
            }, normalizedScreenName))
                continue;
            count += 1;
        }
        return count;
    }

    function getWorkspaceWindowAppIds(screenName, workspaceId, workspaceName) {
        const normalizedScreenName = String(screenName || "").toLowerCase();
        const normalizedWorkspaceId = String(workspaceId ?? "").trim();
        const normalizedWorkspaceName = String(workspaceName ?? "").trim();
        const windows = collectWindows();
        const appIds = [];

        for (let i = 0; i < windows.length; i++) {
            const window = windows[i];
            if (!window)
                continue;

            const windowWorkspaceId = String(window.workspaceId ?? "").trim();
            const windowWorkspaceName = String(window.workspaceName ?? "").trim();
            const matchesWorkspace = (normalizedWorkspaceId !== "" && windowWorkspaceId === normalizedWorkspaceId)
                || (normalizedWorkspaceName !== "" && windowWorkspaceName === normalizedWorkspaceName);
            if (!matchesWorkspace)
                continue;

            if (!workspaceOutputMatches({
                "output": window.output || ""
            }, normalizedScreenName))
                continue;

            appIds.push(String(window.appId || ""));
        }

        return appIds;
    }

    function buildEntries(windows) {
        return (windows || []).map(function (window) {
            return {
                "id": window.id,
                "entryKey": getWindowKey(window),
                "appId": window.appId || "",
                "fallbackTitle": window.title || getAppNameFromDesktopEntry(window.appId),
                "output": window.output || "",
                "workspaceId": window.workspaceId,
                "x": window?.x,
                "y": window?.y,
                "isFloating": window?.isFloating === true,
                "niriColumnIndex": window?.niriColumnIndex,
                "niriTileIndex": window?.niriTileIndex
            };
        });
    }

    function buildLiveEntries(entries, windows) {
        const windowsByKey = ({});
        const stateEntries = ({});

        (windows || []).forEach(function (window) {
            const key = getWindowKey(window);
            if (key)
                windowsByKey[key] = window;
        });

        (entries || []).forEach(function (entry) {
            const window = windowsByKey[entry.entryKey] || null;
            stateEntries[entry.entryKey] = {
                "id": window?.id ?? entry.id ?? "",
                "isFocused": !!window?.isFocused
            };
        });

        return stateEntries;
    }

    function buildTitleEntries(entries, windows) {
        const windowsByKey = ({});
        const titles = ({});

        (windows || []).forEach(function (window) {
            const key = getWindowKey(window);
            if (key)
                windowsByKey[key] = window;
        });

        (entries || []).forEach(function (entry) {
            const window = windowsByKey[entry.entryKey] || null;
            titles[entry.entryKey] = window?.title || entry.fallbackTitle || "";
        });

        return titles;
    }

    function getFocusedEntryKey(entries) {
        const source = entries || ({});
        for (const entryKey in source) {
            if (source[entryKey]?.isFocused)
                return entryKey;
        }
        return "";
    }

    function updateSnapshots(reason) {
        refreshWorkspaceSnapshot();
        const windows = collectWindows();
        const nextEntries = buildEntries(windows);
        const nextLiveEntries = buildLiveEntries(nextEntries, windows);
        const nextTitles = buildTitleEntries(nextEntries, windows);

        allEntries = nextEntries;
        liveEntriesByKey = nextLiveEntries;
        titleEntriesByKey = nextTitles;
        activeEntryKey = getFocusedEntryKey(nextLiveEntries);
        structureRevision += 1;
        liveRevision += 1;
        titleRevision += 1;
    }

    function getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces) {
        const activeWorkspaceIds = onlyActiveWorkspaces ? getActiveWorkspaceIds() : [];
        return allEntries.filter(function (entry) {
            const outputMatch = (!onlySameOutput) || !screenName || entry.output === screenName;
            const workspaceMatch = (!onlyActiveWorkspaces) || activeWorkspaceIds.includes(entry.workspaceId);
            return outputMatch && workspaceMatch;
        });
    }

    function reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces) {
        return getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces).filter(function (entry) {
            return entry?.isFloating !== true;
        });
    }

    function indexOfEntry(entries, entryKey) {
        for (let i = 0; i < entries.length; i++) {
            if (entries[i]?.entryKey === entryKey)
                return i;
        }
        return -1;
    }

    function canReorderEntry(entryKey, screenName, onlySameOutput, onlyActiveWorkspaces) {
        if (reorderInFlight)
            return false;

        const visibleEntries = reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
        const sourceIndex = indexOfEntry(visibleEntries, entryKey);
        if (sourceIndex < 0)
            return false;

        const sourceEntry = visibleEntries[sourceIndex];
        return sourceEntry?.isFloating !== true;
    }

    function canReorderToIndex(sourceEntryKey, targetIndex, screenName, onlySameOutput, onlyActiveWorkspaces) {
        if (reorderInFlight)
            return false;

        const visibleEntries = reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
        const sourceIndex = indexOfEntry(visibleEntries, sourceEntryKey);
        if (sourceIndex < 0)
            return false;

        const sourceEntry = visibleEntries[sourceIndex];
        if (!sourceEntry || sourceEntry.isFloating)
            return false;

        const clampedTargetIndex = Math.max(0, Math.min(visibleEntries.length - 1, Number(targetIndex)));
        if (isNaN(clampedTargetIndex) || clampedTargetIndex === sourceIndex)
            return false;

        const remainingEntries = visibleEntries.filter(function (entry) {
            return entry?.entryKey !== sourceEntryKey;
        });
        const insertIndex = Math.max(0, Math.min(remainingEntries.length, clampedTargetIndex));
        const previousNeighbor = insertIndex > 0 ? remainingEntries[insertIndex - 1] : null;
        const nextNeighbor = insertIndex < remainingEntries.length ? remainingEntries[insertIndex] : null;

        if (!previousNeighbor && !nextNeighbor)
            return false;
        if (previousNeighbor && (!sameWorkspace(sourceEntry, previousNeighbor) || !sameOutput(sourceEntry, previousNeighbor)))
            return false;
        if (nextNeighbor && (!sameWorkspace(sourceEntry, nextNeighbor) || !sameOutput(sourceEntry, nextNeighbor)))
            return false;

        return true;
    }

    function refreshBackendState() {
        try {
            if (CompositorService.isHyprland) {
                Hyprland.refreshToplevels();
                Hyprland.refreshWorkspaces();
            } else if (CompositorService.isNiri) {
                Niri.refreshWindows();
                Niri.refreshWorkspaces();
            }
        } catch (error) {}
        updateSnapshots("refreshBackendState");
    }

    function dispatchHyprland(request) {
        try {
            Hyprland.dispatch(request);
            return true;
        } catch (error) {
            Logger.e("Scrollbar2", "Hyprland reorder dispatch failed: " + error);
            return false;
        }
    }

    function focusHyprlandEntry(entryId) {
        const normalizedId = String(entryId || "").trim();
        if (normalizedId === "")
            return false;
        return dispatchHyprland("focuswindow address:0x" + normalizedId);
    }

    function dispatchNiri(args) {
        try {
            Niri.dispatch(args);
            return true;
        } catch (error) {
            Logger.e("Scrollbar2", "Niri reorder dispatch failed: " + error);
            return false;
        }
    }

    function completeHyprlandReorder(state, reordered, reason) {
        hyprlandReorderTimer.stop();
        hyprlandReorderState = null;
        refreshBackendState();
        reorderReleaseTimer.restart();

        const finalEntries = reorderableEntries(state.screenName, state.onlySameOutput, state.onlyActiveWorkspaces);
        const finalIndex = indexOfEntry(finalEntries, state.sourceEntryKey);
        Logger.d("Scrollbar2", "Reorder result: source=" + state.sourceEntryKey + " finalIndex=" + finalIndex + " requestedIndex=" + state.targetIndex + " reordered=" + reordered + " reason=" + String(reason || "") + " visible=[" + finalEntries.map(function (entry) {
            return entry?.entryKey || "";
        }).join(",") + "]");
        if (!reordered)
            Logger.w("Scrollbar2", "Drag reorder did not complete for " + state.sourceEntryKey + " -> index " + state.targetIndex + " (" + String(reason || "unknown") + ")");
    }

    function startHyprlandReorder(sourceEntryKey, targetIndex, screenName, onlySameOutput, onlyActiveWorkspaces) {
        hyprlandReorderState = {
            "sourceEntryKey": sourceEntryKey,
            "targetIndex": targetIndex,
            "screenName": screenName,
            "onlySameOutput": onlySameOutput,
            "onlyActiveWorkspaces": onlyActiveWorkspaces,
            "phase": "focus",
            "stepCount": 0,
            "expectedIndex": -1,
            "swapWithEntryKey": ""
        };
        refreshBackendState();
        hyprlandReorderTimer.restart();
        return true;
    }

    function advanceHyprlandReorder() {
        const state = hyprlandReorderState;
        if (!state) {
            reorderInFlight = false;
            return;
        }

        const maxSteps = 96;
        if (state.stepCount >= maxSteps) {
            completeHyprlandReorder(state, false, "step-limit");
            return;
        }

        if (state.phase === "await-focus" || state.phase === "await-swap")
            refreshBackendState();

        const visibleEntries = reorderableEntries(state.screenName, state.onlySameOutput, state.onlyActiveWorkspaces);
        const sourceCurrentIndex = indexOfEntry(visibleEntries, state.sourceEntryKey);
        if (sourceCurrentIndex < 0) {
            completeHyprlandReorder(state, false, "source-missing");
            return;
        }
        if (sourceCurrentIndex === state.targetIndex) {
            completeHyprlandReorder(state, true, "complete");
            return;
        }

        const sourceEntry = visibleEntries[sourceCurrentIndex];
        const comparisonEntry = visibleEntries[sourceCurrentIndex < state.targetIndex ? sourceCurrentIndex + 1 : sourceCurrentIndex - 1];
        if (!comparisonEntry) {
            completeHyprlandReorder(state, false, "comparison-missing");
            return;
        }
        if (!sameWorkspace(sourceEntry, comparisonEntry) || !sameOutput(sourceEntry, comparisonEntry)) {
            completeHyprlandReorder(state, false, "scope-mismatch");
            return;
        }
        if (!sourceEntry?.id || !comparisonEntry?.id) {
            completeHyprlandReorder(state, false, "backend-id-missing");
            return;
        }

        if (state.phase === "focus") {
            Logger.d("Scrollbar2", "Hyprland reorder focus request: source=" + state.sourceEntryKey + " currentIndex=" + sourceCurrentIndex + " targetIndex=" + state.targetIndex + " active=" + activeEntryKey);
            if (!focusHyprlandEntry(sourceEntry.id)) {
                completeHyprlandReorder(state, false, "focus-dispatch-failed");
                return;
            }
            state.phase = "await-focus";
            state.stepCount += 1;
            hyprlandReorderTimer.restart();
            return;
        }

        if (state.phase === "await-focus") {
            Logger.d("Scrollbar2", "Hyprland focus check: requested=" + state.sourceEntryKey + " active=" + activeEntryKey);
            if (activeEntryKey !== state.sourceEntryKey) {
                state.phase = "focus";
                hyprlandReorderTimer.restart();
                return;
            }
            state.phase = "swap";
            hyprlandReorderTimer.restart();
            return;
        }

        if (state.phase === "swap") {
            Logger.d("Scrollbar2", "Hyprland reorder step: source=" + state.sourceEntryKey + " currentIndex=" + sourceCurrentIndex + " targetIndex=" + state.targetIndex + " swapWith=" + comparisonEntry.entryKey);
            if (!dispatchHyprland("swapwindow address:0x" + String(comparisonEntry.id))) {
                completeHyprlandReorder(state, false, "swap-dispatch-failed");
                return;
            }
            state.expectedIndex = sourceCurrentIndex < state.targetIndex ? sourceCurrentIndex + 1 : sourceCurrentIndex - 1;
            state.swapWithEntryKey = comparisonEntry.entryKey;
            state.phase = "await-swap";
            state.stepCount += 1;
            hyprlandReorderTimer.restart();
            return;
        }

        if (state.phase === "await-swap") {
            const refreshedEntries = reorderableEntries(state.screenName, state.onlySameOutput, state.onlyActiveWorkspaces);
            const refreshedIndex = indexOfEntry(refreshedEntries, state.sourceEntryKey);
            Logger.d("Scrollbar2", "Hyprland swap check: source=" + state.sourceEntryKey + " currentIndex=" + refreshedIndex + " expectedIndex=" + state.expectedIndex + " targetIndex=" + state.targetIndex + " swapWith=" + state.swapWithEntryKey);
            if (refreshedIndex < 0) {
                completeHyprlandReorder(state, false, "source-missing-after-swap");
                return;
            }
            if (refreshedIndex === state.targetIndex) {
                completeHyprlandReorder(state, true, "complete");
                return;
            }
            if (refreshedIndex === state.expectedIndex) {
                state.phase = "focus";
                hyprlandReorderTimer.restart();
                return;
            }
            state.phase = "focus";
            hyprlandReorderTimer.restart();
            return;
        }

        completeHyprlandReorder(state, false, "invalid-phase");
    }

    function niriMoveAction(sourceEntry, targetEntry) {
        const sourceColumn = Number(sourceEntry?.niriColumnIndex);
        const targetColumn = Number(targetEntry?.niriColumnIndex);
        const sourceTile = Number(sourceEntry?.niriTileIndex);
        const targetTile = Number(targetEntry?.niriTileIndex);
        const sourceHasColumn = !isNaN(sourceColumn);
        const targetHasColumn = !isNaN(targetColumn);
        const sourceHasTile = !isNaN(sourceTile);
        const targetHasTile = !isNaN(targetTile);

        if (sourceHasColumn && targetHasColumn && sourceColumn !== targetColumn)
            return sourceColumn < targetColumn ? "move-window-right" : "move-window-left";
        if (sourceHasTile && targetHasTile && sourceTile !== targetTile)
            return sourceTile < targetTile ? "move-window-down" : "move-window-up";
        if (sourceEntry?.niriColumnIndex !== undefined || targetEntry?.niriColumnIndex !== undefined) {
            if (sourceColumn < targetColumn)
                return "move-window-right";
            if (sourceColumn > targetColumn)
                return "move-window-left";
        }
        return niriDirectionFallback(sourceEntry, targetEntry);
    }

    function niriDirectionFallback(sourceEntry, targetEntry) {
        const sourceX = Number(sourceEntry?.x);
        const targetX = Number(targetEntry?.x);
        const sourceY = Number(sourceEntry?.y);
        const targetY = Number(targetEntry?.y);

        if (!isNaN(sourceX) && !isNaN(targetX) && sourceX !== targetX)
            return sourceX < targetX ? "move-window-right" : "move-window-left";
        if (!isNaN(sourceY) && !isNaN(targetY) && sourceY !== targetY)
            return sourceY < targetY ? "move-window-down" : "move-window-up";
        return "";
    }

    function performNiriReorder(sourceEntryKey, targetIndex, screenName, onlySameOutput, onlyActiveWorkspaces) {
        const maxSteps = 48;
        for (let step = 0; step < maxSteps; step++) {
            const visibleEntries = reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
            const currentIndex = indexOfEntry(visibleEntries, sourceEntryKey);
            if (currentIndex < 0)
                return false;
            if (currentIndex === targetIndex)
                return true;

            const sourceEntry = visibleEntries[currentIndex];
            const comparisonEntry = visibleEntries[currentIndex < targetIndex ? currentIndex + 1 : currentIndex - 1];
            if (!comparisonEntry)
                return currentIndex === targetIndex;

            focusEntry(sourceEntryKey);
            const action = niriMoveAction(sourceEntry, comparisonEntry);
            if (action === "" || !dispatchNiri([action]))
                return false;
            refreshBackendState();
        }

        return false;
    }

    function requestEntryReorderToIndex(sourceEntryKey, targetIndex, screenName, onlySameOutput, onlyActiveWorkspaces) {
        if (!canReorderToIndex(sourceEntryKey, targetIndex, screenName, onlySameOutput, onlyActiveWorkspaces))
            return false;

        const visibleEntries = reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
        const sourceIndex = indexOfEntry(visibleEntries, sourceEntryKey);
        const clampedTargetIndex = Math.max(0, Math.min(visibleEntries.length - 1, Number(targetIndex)));
        const sourceEntry = visibleEntries[sourceIndex];
        Logger.d("Scrollbar2", "Reorder request: source=" + sourceEntryKey + " sourceIndex=" + sourceIndex + " targetIndex=" + clampedTargetIndex + " visible=[" + visibleEntries.map(function (entry) {
            return entry?.entryKey || "";
        }).join(",") + "]");

        reorderInFlight = true;
        if (CompositorService.isHyprland) {
            return startHyprlandReorder(sourceEntryKey, clampedTargetIndex, screenName, onlySameOutput, onlyActiveWorkspaces);
        } else if (CompositorService.isNiri) {
            const reordered = performNiriReorder(sourceEntryKey, clampedTargetIndex, screenName, onlySameOutput, onlyActiveWorkspaces);
            refreshBackendState();
            reorderReleaseTimer.restart();
            const finalEntries = reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
            const finalIndex = indexOfEntry(finalEntries, sourceEntryKey);
            Logger.d("Scrollbar2", "Reorder result: source=" + sourceEntryKey + " finalIndex=" + finalIndex + " requestedIndex=" + clampedTargetIndex + " reordered=" + reordered + " visible=[" + finalEntries.map(function (entry) {
                return entry?.entryKey || "";
            }).join(",") + "]");
            if (!reordered)
                Logger.w("Scrollbar2", "Drag reorder did not complete for " + sourceEntryKey + " -> index " + clampedTargetIndex);
            return reordered;
        } else {
            Logger.w("Scrollbar2", "Drag reorder is not supported on this compositor backend");
            reorderInFlight = false;
            return false;
        }
    }

    function requestEntryReorder(sourceEntryKey, targetEntryKey, screenName, onlySameOutput, onlyActiveWorkspaces) {
        const visibleEntries = reorderableEntries(screenName, onlySameOutput, onlyActiveWorkspaces);
        const sourceIndex = indexOfEntry(visibleEntries, sourceEntryKey);
        const targetIndex = indexOfEntry(visibleEntries, targetEntryKey);
        if (sourceIndex < 0 || targetIndex < 0)
            return false;
        return requestEntryReorderToIndex(sourceEntryKey, targetIndex, screenName, onlySameOutput, onlyActiveWorkspaces);
    }

    function getVisibleEntriesForApp(screenName, appId, onlySameOutput, onlyActiveWorkspaces) {
        const canonicalId = resolveToDesktopEntryId(appId);
        if (!canonicalId)
            return [];

        return getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces).filter(function (entry) {
            return resolveToDesktopEntryId(entry?.appId || "") === canonicalId;
        });
    }

    function getVisiblePinnedApps(screenName, onlySameOutput, onlyActiveWorkspaces) {
        return pinnedAppItems().filter(function (item) {
            const canonicalId = resolveToDesktopEntryId(item?.appId || "");
            if (!canonicalId)
                return false;

            return true;
        }).map(function (item) {
            const canonicalId = resolveToDesktopEntryId(item?.appId || "");
            const visibleEntries = getVisibleEntriesForApp(screenName, canonicalId, onlySameOutput, onlyActiveWorkspaces);
            return {
                "appId": canonicalId,
                "customIcon": String(item?.customIcon || ""),
                "name": getAppNameFromDesktopEntry(canonicalId),
                "visibleWindowCount": visibleEntries.length,
                "hasVisibleWindows": visibleEntries.length > 0
            };
        });
    }

    function getWindowByEntry(entryKey) {
        const windows = collectWindows();
        return windows.find(function (candidate) {
            return getWindowKey(candidate) === entryKey;
        }) || null;
    }

    function focusEntry(entryKey) {
        const window = getWindowByEntry(entryKey);
        if (!window)
            return;

        try {
            CompositorService.focusWindow(window);
        } catch (error) {
            Logger.e("Scrollbar2", "Failed to focus window: " + error);
        }
    }

    function closeEntry(entryKey) {
        const window = getWindowByEntry(entryKey);
        if (!window)
            return;

        try {
            CompositorService.closeWindow(window);
        } catch (error) {
            Logger.e("Scrollbar2", "Failed to close window: " + error);
        }
    }

    function cycleFocusVisibleInstances(screenName, appId, onlySameOutput, onlyActiveWorkspaces) {
        const canonicalId = resolveToDesktopEntryId(appId);
        const visibleEntries = getVisibleEntriesForApp(screenName, canonicalId, onlySameOutput, onlyActiveWorkspaces);
        if (visibleEntries.length === 0)
            return false;

        let nextIndex = 0;
        for (let i = 0; i < visibleEntries.length; i++) {
            if (visibleEntries[i]?.entryKey === activeEntryKey) {
                nextIndex = (i + 1) % visibleEntries.length;
                cycleStateByApp[canonicalId] = nextIndex;
                focusEntry(visibleEntries[nextIndex].entryKey);
                return true;
            }
        }

        nextIndex = cycleStateByApp[canonicalId] ?? 0;
        nextIndex = ((nextIndex % visibleEntries.length) + visibleEntries.length) % visibleEntries.length;
        cycleStateByApp[canonicalId] = (nextIndex + 1) % visibleEntries.length;
        focusEntry(visibleEntries[nextIndex].entryKey);
        return true;
    }

    function launchPinnedApp(appId) {
        const canonicalId = resolveToDesktopEntryId(appId);
        if (!canonicalId)
            return false;

        try {
            const app = getDesktopEntry(canonicalId);
            if (!app)
                return false;

            if (Settings.data.appLauncher.customLaunchPrefixEnabled && Settings.data.appLauncher.customLaunchPrefix) {
                const prefix = Settings.data.appLauncher.customLaunchPrefix.split(" ");
                if (app.runInTerminal) {
                    const terminal = Settings.data.appLauncher.terminalCommand.split(" ");
                    Quickshell.execDetached(prefix.concat(terminal.concat(app.command)));
                } else {
                    Quickshell.execDetached(prefix.concat(app.command));
                }
            } else if (app.runInTerminal) {
                const terminal = Settings.data.appLauncher.terminalCommand.split(" ");
                CompositorService.spawn(terminal.concat(app.command));
            } else if (app.command && app.command.length > 0) {
                CompositorService.spawn(app.command);
            } else if (app.execute) {
                app.execute();
            } else {
                Logger.w("Scrollbar2", "No launch method found for " + canonicalId);
                return false;
            }
        } catch (error) {
            Logger.e("Scrollbar2", "Failed to launch pinned app: " + error);
            return false;
        }

        return true;
    }

    function desktopEntryActionsForApp(appId) {
        if (!appId)
            return [];

        try {
            if (typeof DesktopEntries === "undefined")
                return [];

            const entry = DesktopEntries.heuristicLookup ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId?.(appId);
            if (!entry || !entry.actions || entry.actions.length === 0)
                return [];

            return entry.actions.map(function (desktopAction, index) {
                return {
                    "label": desktopAction.name,
                    "action": "desktop-action-" + index,
                    "icon": "chevron-right",
                    "desktopAction": desktopAction
                };
            });
        } catch (error) {
            Logger.e("Scrollbar2", "Failed to read desktop actions: " + error);
            return [];
        }
    }

    Connections {
        target: CompositorService

        function onWorkspacesChanged() {
            root.refreshWorkspaceSnapshot();
        }

        function onWindowListChanged() {
            root.updateSnapshots("windowListChanged");
        }

        function onActiveWindowChanged() {
            root.updateSnapshots("activeWindowChanged");
        }
    }

    Connections {
        target: CompositorService.isHyprland ? Hyprland : null

        function onRawEvent(event) {
            if (event.name !== "activespecialv2")
                return;

            const values = event.parse(3);
            root.updateActiveSpecialForMonitor(values[2], values[0], values[1]);
        }
    }

    Connections {
        target: typeof DesktopEntries !== "undefined" ? DesktopEntries.applications : null

        function onValuesChanged() {
            root._desktopEntryIdCache = ({});
            root.updateSnapshots("desktopEntriesChanged");
        }
    }

    Component.onCompleted: {
        updateSnapshots("startup");
        refreshActiveSpecialSnapshot();
    }

    Variants {
        model: Quickshell.screens

        delegate: Loader {
            id: screenWindowLoader

            required property ShellScreen modelData

            active: root.displayMode === "floatingPanel"

            sourceComponent: PanelWindow {
                id: windowHost

                screen: screenWindowLoader.modelData
                focusable: false
                color: "transparent"

                readonly property bool anchorTop: root.trackPosition !== "bottom"
                readonly property real effectiveOffsetH: Math.round(root.displayOffsetH * Style.uiScaleRatio)
                readonly property real effectiveOffsetV: Math.round(root.displayOffsetV * Style.uiScaleRatio)
                readonly property real contentBaseWidth: Math.ceil(windowView.implicitWidth * root.displayScale) + root.displayMargin * 2
                readonly property real contentBaseHeight: Math.ceil(windowView.implicitHeight * root.displayScale) + root.displayMargin * 2

                anchors.top: anchorTop
                anchors.bottom: !anchorTop
                anchors.left: true
                anchors.right: true

                implicitWidth: Math.round(screen?.width || contentBaseWidth)
                implicitHeight: contentBaseHeight + Math.abs(effectiveOffsetV)

                WlrLayershell.namespace: "scrollbar2-window-" + (screen?.name || "unknown")
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.exclusionMode: ExclusionMode.Auto

                visible: windowContent.width > 0 && windowContent.height > 0
                mask: Region {
                    item: windowContent
                }

                Item {
                    id: windowContent
                    width: contentBaseWidth
                    height: contentBaseHeight
                    x: Style.pixelAlignCenter(parent.width, width) + effectiveOffsetH
                    y: anchorTop ? Math.max(0, effectiveOffsetV) : Math.max(0, -effectiveOffsetV)

                    Rectangle {
                        anchors.fill: parent
                        radius: root.effectiveDisplayRadius
                        color: root.displayBackgroundResolvedColor
                        visible: root.displayBackgroundEnabled || root.displayGradientActive

                        Rectangle {
                            anchors.fill: parent
                            radius: root.effectiveDisplayRadius
                            visible: root.displayGradientActive
                            color: "transparent"

                            gradient: Gradient {
                                orientation: root.displayGradientDirection === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: root.displayGradientResolvedColor
                                }
                            }
                        }
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: root.displayMargin

                        WindowBarView {
                            id: windowView
                            anchors.centerIn: parent
                            width: implicitWidth
                            height: implicitHeight
                            pluginApi: root.pluginApi
                            screen: windowHost.screen
                            hostMode: "floatingPanel"
                            visibleInCurrentMode: root.displayMode === "floatingPanel"

                            transform: Scale {
                                origin.x: windowView.width / 2
                                origin.y: windowView.height / 2
                                xScale: root.displayScale
                                yScale: root.displayScale
                            }
                        }
                    }
                }
            }
        }
    }
}
