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

    function settingValue(groupKey, nestedKey, legacyKey, fallbackValue) {
        const configGroup = currentSettings ? currentSettings[groupKey] : undefined;
        const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
        if (nestedConfig !== undefined)
            return nestedConfig;

        const legacyConfig = currentSettings ? currentSettings[legacyKey] : undefined;
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
        return typeof value === "string"
            && /^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value);
    }

    function resolveSettingColor(value, fallbackColor) {
        const themeColor = resolveThemeColor(value);
        if (themeColor !== undefined)
            return themeColor;
        if (isHexColorString(value))
            return value;
        return fallbackColor;
    }

    readonly property bool debugLogging: settingValue("advanced", "debugLogging", "debugLogging", false)
    readonly property bool supportsLiveReorder: CompositorService.isNiri || CompositorService.isHyprland
    readonly property string renderMode: settingValue("window", "renderMode", "renderMode", "bar")
    readonly property string windowSpaceMode: settingValue("window", "spaceMode", "windowSpaceMode", "overlay")

    readonly property real windowOffsetH: settingValue("window", "offsetH", "windowOffsetH", 0)
    readonly property real windowOffsetV: settingValue("window", "offsetV", "windowOffsetV", 0)
    readonly property real windowScale: Math.max(0.5, settingValue("window", "scale", "windowScale", 1.0))
    readonly property string windowBackgroundColorKey: settingValue("window", "backgroundColor", "windowBackgroundColor", "none")
    readonly property real windowBackgroundOpacity: Math.max(0, Math.min(100, settingValue("window", "backgroundOpacity", "windowBackgroundOpacity", 0)))
    readonly property real windowMargin: Math.max(0, Math.round(settingValue("window", "margin", "windowMargin", 0) * Style.uiScaleRatio))
    readonly property real windowHeight: Math.max(0, Math.round(settingValue("window", "height", "windowHeight", 0) * Style.uiScaleRatio))
    readonly property real windowRadiusScale: Math.max(0, settingValue("window", "radiusScale", "windowRadiusScale", 1.0))
    readonly property bool windowGradientEnabled: settingValue("window", "gradientEnabled", "windowGradientEnabled", false)
    readonly property string windowGradientColorKey: settingValue("window", "gradientColor", "windowGradientColor", "none")
    readonly property real windowGradientOpacity: Math.max(0, Math.min(100, settingValue("window", "gradientOpacity", "windowGradientOpacity", 0)))
    readonly property string windowGradientDirection: settingValue("window", "gradientDirection", "windowGradientDirection", "vertical")

    readonly property bool windowBackgroundEnabled: windowBackgroundColorKey !== "none" && windowBackgroundOpacity > 0
    readonly property color windowBackgroundBaseColor: resolveSettingColor(windowBackgroundColorKey, "transparent")
    readonly property color windowBackgroundResolvedColor: windowBackgroundEnabled ? Qt.alpha(windowBackgroundBaseColor, windowBackgroundOpacity / 100) : "transparent"
    readonly property bool windowGradientActive: windowGradientEnabled && windowGradientColorKey !== "none" && windowGradientOpacity > 0
    readonly property color windowGradientBaseColor: resolveSettingColor(windowGradientColorKey, "transparent")
    readonly property color windowGradientResolvedColor: windowGradientActive ? Qt.alpha(windowGradientBaseColor, windowGradientOpacity / 100) : "transparent"
    readonly property real effectiveWindowRadius: Style.radiusL * windowRadiusScale

    property var allEntries: []
    property var liveEntriesByKey: ({})
    property var titleEntriesByKey: ({})
    property string activeEntryKey: ""
    property var compositorWorkspaces: []
    property int structureRevision: 0
    property int liveRevision: 0
    property int workspaceRevision: 0

    property bool pendingStructuralRefresh: false
    property string lastStructureSignature: ""
    property string lastStateSignature: ""
    property string lastTitleSignature: ""
    property string lastWorkspaceSignature: ""
    property var pendingTitleEntriesByKey: null

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

    function collectWorkspaces() {
        const workspaces = [];

        try {
            const total = CompositorService.workspaces?.count || 0;
            for (let i = 0; i < total; i++) {
                const workspace = CompositorService.workspaces.get(i);
                if (workspace)
                    workspaces.push(workspace);
            }
        } catch (error) {
        }

        return workspaces;
    }

    function workspaceOutputMatches(workspace, screenName) {
        if (!workspace)
            return false;
        if (CompositorService.globalWorkspaces)
            return true;
        if (!screenName)
            return true;
        return String(workspace.output || "").toLowerCase() === String(screenName).toLowerCase();
    }

    function cloneWorkspaceData(workspace) {
        return {
            "id": workspace?.id,
            "idx": workspace?.idx,
            "name": workspace?.name || "",
            "output": workspace?.output || "",
            "isFocused": workspace?.isFocused === true,
            "isActive": workspace?.isActive === true
        };
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

    function buildStateEntries(entries, windows) {
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
        const titleEntries = ({});

        (windows || []).forEach(function (window) {
            const key = getWindowKey(window);
            if (key)
                windowsByKey[key] = window;
        });

        (entries || []).forEach(function (entry) {
            const window = windowsByKey[entry.entryKey] || null;
            titleEntries[entry.entryKey] = window?.title || entry.fallbackTitle || "";
        });

        return titleEntries;
    }

    function getStructureSignature(entries) {
        return (entries || []).map(function (entry) {
            return entry.entryKey;
        }).join("||");
    }

    function getStateSignature(entries, stateEntries) {
        return (entries || []).map(function (entry) {
            const stateEntry = stateEntries ? stateEntries[entry.entryKey] : undefined;
            return entry.entryKey + "|" + String(stateEntry?.id ?? "") + "|" + String(stateEntry?.isFocused === true);
        }).join("||");
    }

    function getTitleSignature(entries, titleEntries) {
        return (entries || []).map(function (entry) {
            return entry.entryKey + "|" + String(titleEntries ? titleEntries[entry.entryKey] || "" : "");
        }).join("||");
    }

    function getWorkspaceSignature(workspaces) {
        return (workspaces || []).map(function (workspace) {
            return String(workspace.id ?? "") + "|" + String(workspace.idx ?? "") + "|" + String(workspace.name ?? "") + "|" + String(workspace.output ?? "") + "|" + String(workspace.isFocused === true) + "|" + String(workspace.isActive === true);
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

    function applyStateEntries(entries, reason) {
        liveEntriesByKey = entries || ({});
        activeEntryKey = getFocusedEntryKey(liveEntriesByKey);
        lastStateSignature = getStateSignature(allEntries, liveEntriesByKey);
        liveRevision += 1;
        debugLog("applyStateEntries(" + (reason || "unknown") + "): focus=" + activeEntryKey + " windows=" + allEntries.length);
    }

    function applyTitleEntries(entries, reason) {
        titleEntriesByKey = entries || ({});
        lastTitleSignature = getTitleSignature(allEntries, titleEntriesByKey);
        debugLog("applyTitleEntries(" + (reason || "unknown") + "): windows=" + allEntries.length);
    }

    function refreshWorkspaceSnapshot(reason) {
        const nextWorkspaces = collectWorkspaces().map(cloneWorkspaceData);
        const nextWorkspaceSignature = getWorkspaceSignature(nextWorkspaces);

        if (nextWorkspaceSignature === lastWorkspaceSignature)
            return;

        compositorWorkspaces = nextWorkspaces;
        lastWorkspaceSignature = nextWorkspaceSignature;
        workspaceRevision += 1;
        debugLog("refreshWorkspaceSnapshot(" + (reason || "unknown") + "): workspaces=" + compositorWorkspaces.length);
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

    function flushPendingTitleUpdates(reason) {
        if (!pendingTitleEntriesByKey)
            return;

        const nextTitleEntries = pendingTitleEntriesByKey;
        pendingTitleEntriesByKey = null;
        applyTitleEntries(nextTitleEntries, reason || "title-debounce");
    }

    function applySnapshots(reason, forceStructural, windows, nextEntries) {
        const nextStructureSignature = getStructureSignature(nextEntries);
        const structuralChanged = (forceStructural === true) || pendingStructuralRefresh || nextStructureSignature !== lastStructureSignature;

        pendingStructuralRefresh = false;

        if (structuralChanged)
            applyStructuralEntries(nextEntries, reason);

        const effectiveEntries = structuralChanged ? nextEntries : allEntries;
        const nextStateEntries = buildStateEntries(effectiveEntries, windows);
        const nextTitleEntries = buildTitleEntries(effectiveEntries, windows);
        const nextStateSignature = getStateSignature(effectiveEntries, nextStateEntries);
        const nextTitleSignature = getTitleSignature(effectiveEntries, nextTitleEntries);
        const stateChanged = structuralChanged || nextStateSignature !== lastStateSignature || Object.keys(liveEntriesByKey).length === 0;
        const titleChanged = nextTitleSignature !== lastTitleSignature;

        if (stateChanged) {
            applyStateEntries(nextStateEntries, reason);

            if (structuralChanged || Object.keys(titleEntriesByKey).length === 0) {
                pendingTitleEntriesByKey = null;
                titleRefreshDebounce.stop();
                applyTitleEntries(nextTitleEntries, reason);
                return;
            }

            if (titleChanged) {
                pendingTitleEntriesByKey = nextTitleEntries;
                titleRefreshDebounce.restart();
            } else {
                pendingTitleEntriesByKey = null;
                titleRefreshDebounce.stop();
            }
            return;
        }

        if (titleChanged) {
            pendingTitleEntriesByKey = nextTitleEntries;
            titleRefreshDebounce.restart();
        } else {
            pendingTitleEntriesByKey = null;
            titleRefreshDebounce.stop();
        }
    }

    function updateSnapshots(reason, forceStructural) {
        refreshWorkspaceSnapshot(reason);

        const windows = collectWindows();
        const nextEntries = buildStructuralEntries(windows);
        applySnapshots(reason, forceStructural, windows, nextEntries);
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
            refreshWorkspaceSnapshot("init");
            updateSnapshots("init", true);
        });
    }

    Connections {
        target: CompositorService

        function onWindowListChanged() {
            updateSnapshots("windowListChanged", false);
        }

        function onWorkspaceChanged() {
            updateSnapshots("workspaceChanged", false);
        }

        function onActiveWindowChanged() {
            updateSnapshots("activeWindowChanged", false);
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

    Timer {
        id: windowOrderPollTimer
        interval: 500
        repeat: true
        running: allEntries.length > 0
        onTriggered: {
            var windows = collectWindows();
            var nextEntries = buildStructuralEntries(windows);
            var nextSignature = getStructureSignature(nextEntries);
            if (nextSignature !== lastStructureSignature) {
                debugLog("windowOrderPoll: order changed");
                refreshWorkspaceSnapshot("windowOrderPoll");
                applySnapshots("windowOrderPoll", false, windows, nextEntries);
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: Loader {
            id: screenWindowLoader

            required property ShellScreen modelData

            active: root.renderMode === "window"

            sourceComponent: PanelWindow {
                id: windowHost

                screen: screenWindowLoader.modelData
                focusable: false
                color: "transparent"

                readonly property string edge: Settings.getBarPositionForScreen(screen?.name)
                readonly property bool isVerticalEdge: edge === "left" || edge === "right"
                readonly property bool isTopOrLeft: edge === "top" || edge === "left"
                readonly property real contentBaseWidth: Math.ceil(windowView.implicitWidth * root.windowScale) + root.windowMargin * 2
                readonly property real contentBaseHeight: Math.ceil(windowView.implicitHeight * root.windowScale) + root.windowMargin * 2
                readonly property real effectiveOffsetH: Math.round(root.windowOffsetH * Style.uiScaleRatio)
                readonly property real effectiveOffsetV: Math.round(root.windowOffsetV * Style.uiScaleRatio)

                anchors.top: isVerticalEdge || edge === "top"
                anchors.bottom: isVerticalEdge || edge === "bottom"
                anchors.left: !isVerticalEdge || edge === "left"
                anchors.right: !isVerticalEdge || edge === "right"

                implicitWidth: isVerticalEdge ? contentBaseWidth + Math.abs(effectiveOffsetH) : Math.round(screen?.width || contentBaseWidth)
                implicitHeight: isVerticalEdge ? Math.round(screen?.height || contentBaseHeight) : contentBaseHeight + Math.abs(effectiveOffsetV)

                WlrLayershell.namespace: "scrollbar-window-" + (screen?.name || "unknown")
                WlrLayershell.layer: root.windowSpaceMode === "reserve" ? WlrLayer.Top : WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.exclusionMode: root.windowSpaceMode === "reserve" ? ExclusionMode.Auto : ExclusionMode.Ignore

                visible: windowContent.width > 0 && windowContent.height > 0
                mask: Region {
                    item: windowContent
                }

                Item {
                    id: windowContent
                    width: contentBaseWidth
                    height: contentBaseHeight
                    x: isVerticalEdge
                        ? (isTopOrLeft ? Math.max(0, effectiveOffsetH) : Math.max(0, -effectiveOffsetH))
                        : Style.pixelAlignCenter(parent.width, width) + effectiveOffsetH
                    y: isVerticalEdge
                        ? Style.pixelAlignCenter(parent.height, height) + effectiveOffsetV
                        : (isTopOrLeft ? Math.max(0, effectiveOffsetV) : Math.max(0, -effectiveOffsetV))

                    Rectangle {
                        id: windowBackgroundRect
                        anchors.fill: parent
                        radius: root.effectiveWindowRadius
                        color: root.windowBackgroundResolvedColor
                        visible: root.windowBackgroundEnabled || root.windowGradientActive

                        Rectangle {
                            anchors.fill: parent
                            radius: root.effectiveWindowRadius
                            visible: root.windowGradientActive
                            color: "transparent"

                            gradient: Gradient {
                                orientation: root.windowGradientDirection === "horizontal" ? Gradient.Horizontal : Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: "transparent"
                                }
                                GradientStop {
                                    position: 1.0
                                    color: root.windowGradientResolvedColor
                                }
                            }
                        }
                    }

                    Item {
                        id: windowScaledContent
                        anchors.fill: parent
                        anchors.margins: root.windowMargin

                        ScrollbarView {
                            id: windowView
                            anchors.centerIn: parent
                            width: implicitWidth
                            height: implicitHeight
                            pluginApi: root.pluginApi
                            screen: windowHost.screen
                            hostMode: "window"
                            fillHostThickness: false
                            hostThickness: root.windowHeight > 0 ? root.windowHeight : Style.getCapsuleHeightForScreen(windowHost.screen?.name)
                            visibleInCurrentMode: root.renderMode === "window"

                            transform: Scale {
                                origin.x: windowView.width / 2
                                origin.y: windowView.height / 2
                                xScale: root.windowScale
                                yScale: root.windowScale
                            }
                        }
                    }
                }
            }
        }
    }
}
