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
    property string activeEntryKey: ""
    property int structureRevision: 0
    property int liveRevision: 0
    property int titleRevision: 0

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
        try {
            const total = CompositorService.windows?.count || 0;
            for (let i = 0; i < total; i++) {
                const window = CompositorService.windows.get(i);
                if (window)
                    windows.push(window);
            }
        } catch (error) {}
        return windows;
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

    function buildEntries(windows) {
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

        function onWindowListChanged() {
            root.updateSnapshots("windowListChanged");
        }

        function onActiveWindowChanged() {
            root.updateSnapshots("activeWindowChanged");
        }
    }

    Connections {
        target: typeof DesktopEntries !== "undefined" ? DesktopEntries.applications : null

        function onValuesChanged() {
            root.updateSnapshots("desktopEntriesChanged");
        }
    }

    Component.onCompleted: updateSnapshots("startup")

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
