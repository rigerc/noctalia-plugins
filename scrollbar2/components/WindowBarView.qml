import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "../Utils.js" as Utils
import "windowbar"

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string hostMode: "bar"
    property bool visibleInCurrentMode: true

    property var currentSettings: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance ?? null

    property string hoveredEntryKey: ""
    property string hoveredPinnedAppId: ""
    property string selectedEntryKey: ""
    property string selectedAppId: ""
    property var contextMenuModel: []
    property string displayedWorkspaceText: ""
    property string outgoingWorkspaceText: ""
    property int displayedWorkspaceBadgeCount: 0
    property int outgoingWorkspaceBadgeCount: 0
    property real workspaceIndicatorTransitionProgress: 1
    property string displayedSpecialWorkspaceText: ""
    property string outgoingSpecialWorkspaceText: ""
    property var displayedSpecialWorkspaceIcons: []
    property var outgoingSpecialWorkspaceIcons: []
    property real specialWorkspaceOverlayTransitionProgress: 1
    property var invalidStyleRulePatterns: ({})
    property int dragSourceIndex: -1
    property int dragInsertIndex: -1
    property string dragSourceEntryKey: ""
    property bool dragDropHandled: false
    property var previousEntryKeys: []
    property bool entryLifecycleInitialized: false
    property var enteringEntryKeys: ({})
    property var closingEntries: []
    property var liveSegmentSnapshots: ({})
    property int closingEntryUidSeed: 0
    property var previousGlobalEntryKeys: []
    property var entries: []
    property var pinnedEntries: []

    Timer {
        id: dragCleanupTimer
        interval: 1
        repeat: false
        onTriggered: {
            if (!root.dragSessionActive || root.dragDropHandled)
                return;
            Logger.d("Scrollbar2", "Drag preview cleared: source=" + root.dragSourceEntryKey + " raw=" + root.dragInsertIndex + " reason=drag-end-timeout");
            root.clearDragState();
        }
    }

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
    readonly property bool hostVisible: visibleInCurrentMode && (hostMode !== "bar" || !isVerticalBar)
    readonly property var hyprlandMonitor: Hyprland.monitorFor(screen)

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
        return Utils.settingValue(currentSettings, defaults, groupKey, nestedKey, fallbackValue);
    }

    function objectSettingValue(groupKey, objectKey, nestedKey, fallbackValue) {
        return Utils.objectSettingValue(currentSettings, defaults, groupKey, objectKey, nestedKey, fallbackValue);
    }

    function nestedStateColor(groupKey, stateKey, fallbackValue) {
        const group = currentSettings?.[groupKey]?.colors;
        const value = group ? group[stateKey] : undefined;
        if (value && typeof value === "object" && !Array.isArray(value) && value.color !== undefined)
            return value.color;
        if (value !== undefined)
            return value;

        const defaultGroup = defaults?.[groupKey]?.colors;
        const defaultValue = defaultGroup ? defaultGroup[stateKey] : undefined;
        if (defaultValue && typeof defaultValue === "object" && !Array.isArray(defaultValue) && defaultValue.color !== undefined)
            return defaultValue.color;
        if (defaultValue !== undefined)
            return defaultValue;

        return fallbackValue;
    }

    function nestedWindowStateColor(groupKey, stateKey, fallbackValue) {
        const group = currentSettings?.window?.[groupKey];
        const value = group ? group[stateKey] : undefined;
        if (value && typeof value === "object" && !Array.isArray(value) && value.color !== undefined)
            return value.color;
        if (value !== undefined)
            return value;

        const defaultGroup = defaults?.window?.[groupKey];
        const defaultValue = defaultGroup ? defaultGroup[stateKey] : undefined;
        if (defaultValue && typeof defaultValue === "object" && !Array.isArray(defaultValue) && defaultValue.color !== undefined)
            return defaultValue.color;
        if (defaultValue !== undefined)
            return defaultValue;

        return fallbackValue;
    }

    function resolveColor(value, fallbackColor) {
        if (mainInstance?.resolveSettingColor)
            return mainInstance.resolveSettingColor(value, fallbackColor);
        return fallbackColor;
    }

    function normalizeOpacityValue(value, fallbackValue) {
        return Utils.normalizeOpacityValue(value, fallbackValue);
    }

    function colorWithOpacity(colorValue, opacityValue) {
        const sample = Qt.color(colorValue);
        const clampedOpacity = Math.max(0, Math.min(1, Number(opacityValue)));
        return Qt.rgba(sample.r, sample.g, sample.b, sample.a * clampedOpacity);
    }

    function nestedStateOpacity(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.[groupKey]?.colors?.[stateKey];
        if (value && typeof value === "object" && !Array.isArray(value) && value.opacity !== undefined)
            return normalizeOpacityValue(value.opacity, fallbackValue);

        const defaultValue = defaults?.[groupKey]?.colors?.[stateKey];
        if (defaultValue && typeof defaultValue === "object" && !Array.isArray(defaultValue) && defaultValue.opacity !== undefined)
            return normalizeOpacityValue(defaultValue.opacity, fallbackValue);

        return fallbackValue;
    }

    function nestedStateEnabled(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.[groupKey]?.colors?.[stateKey];
        if (value && typeof value === "object" && !Array.isArray(value) && value.enabled !== undefined)
            return value.enabled !== false;

        const defaultValue = defaults?.[groupKey]?.colors?.[stateKey];
        if (defaultValue && typeof defaultValue === "object" && !Array.isArray(defaultValue) && defaultValue.enabled !== undefined)
            return defaultValue.enabled !== false;

        return fallbackValue;
    }

    function normalizeStyleRuleColorState(settingValue, fallbackColor, fallbackOpacity) {
        const currentValue = (settingValue && typeof settingValue === "object" && !Array.isArray(settingValue)) ? settingValue : ({});
        return {
            "enabled": currentValue.enabled === true,
            "color": String(currentValue.color ?? fallbackColor),
            "opacity": normalizeOpacityValue(currentValue.opacity, fallbackOpacity)
        };
    }

    function normalizeStyleRule(rule) {
        const source = (rule && typeof rule === "object" && !Array.isArray(rule)) ? rule : ({});
        return {
            "enabled": source.enabled !== false,
            "matchField": normalizeStyleRuleMatchField(source.matchField),
            "pattern": String(source.pattern || ""),
            "customIcon": String(source.customIcon || ""),
            "colors": {
                "segment": {
                    "focused": normalizeStyleRuleColorState(source.colors?.segment?.focused, focusLineFocusedColorKey, focusLineFocusedOpacity),
                    "hover": normalizeStyleRuleColorState(source.colors?.segment?.hover, focusLineHoverColorKey, focusLineHoverOpacity),
                    "default": normalizeStyleRuleColorState(source.colors?.segment?.default, focusLineDefaultColorKey, focusLineDefaultOpacity)
                },
                "icon": {
                    "focused": normalizeStyleRuleColorState(source.colors?.icon?.focused, iconColorFocusedKey, iconColorFocusedOpacity),
                    "hover": normalizeStyleRuleColorState(source.colors?.icon?.hover, iconColorHoverKey, iconColorHoverOpacity),
                    "default": normalizeStyleRuleColorState(source.colors?.icon?.default, iconColorDefaultKey, iconColorDefaultOpacity)
                },
                "title": {
                    "focused": normalizeStyleRuleColorState(source.colors?.title?.focused, titleColorFocusedKey, titleColorFocusedOpacity),
                    "hover": normalizeStyleRuleColorState(source.colors?.title?.hover, titleColorHoverKey, titleColorHoverOpacity),
                    "default": normalizeStyleRuleColorState(source.colors?.title?.default, titleColorDefaultKey, titleColorDefaultOpacity)
                }
            },
            "blink": {
                "enabled": source.blink?.enabled === true,
                "color": normalizeStyleRuleColorState(source.blink?.color, "primary", 1),
                "interval": Math.max(200, Math.min(5000, Number(source.blink?.interval ?? 800)))
            },
            "badge": {
                "enabled": source.badge?.enabled === true,
                "color": normalizeStyleRuleColorState(source.badge?.color, "error", 1),
                "size": Math.max(2, Math.min(16, Number(source.badge?.size ?? 6))),
                "target": normalizeBadgeTarget(source.badge?.target),
                "position": normalizeBadgePosition(source.badge?.position)
            },
            "iconPrefix": {
                "enabled": source.iconPrefix?.enabled === true,
                "icon": String(source.iconPrefix?.icon || ""),
                "target": normalizePrefixTarget(source.iconPrefix?.target),
                "color": normalizeStyleRuleColorState(source.iconPrefix?.color, "on-surface-variant", 1)
            }
        };
    }

    function normalizeStyleRuleMatchField(matchField) {
        return Utils.normalizeStyleRuleMatchField(matchField);
    }

    function normalizeBadgeTarget(target) {
        return Utils.normalizeBadgeTarget(target);
    }

    function normalizeBadgePosition(position) {
        return Utils.normalizeBadgePosition(position);
    }

    function normalizePrefixTarget(target) {
        return Utils.normalizePrefixTarget(target);
    }

    function styleRuleAllowsEmptyPattern(matchField) {
        return Utils.styleRuleAllowsEmptyPattern(matchField);
    }

    function styleRuleItems() {
        const configuredRules = currentSettings?.customStyleRules;
        const source = Array.isArray(configuredRules) ? configuredRules : (Array.isArray(defaults?.customStyleRules) ? defaults.customStyleRules : []);
        return source.map(normalizeStyleRule);
    }

    function refreshEntriesCache() {
        if (!mainInstance) {
            entries = [];
            return;
        }
        const nextEntries = mainInstance.getFilteredEntryKeys(screenName, onlySameOutput, onlyActiveWorkspaces) || [];
        if (settingValue("debug", "logging", false) === true && !_sameStringList(entries, nextEntries)) {
            Logger.d("Scrollbar2", "WindowBarView entries updated: screen=" + screenName + " onlySameOutput=" + String(onlySameOutput) + " onlyActiveWorkspaces=" + String(onlyActiveWorkspaces) + " entries=[" + nextEntries.join(",") + "]");
        }
        entries = nextEntries;
    }

    function refreshPinnedEntriesCache() {
        if (!mainInstance) {
            pinnedEntries = [];
            return;
        }
        const source = mainInstance.getVisiblePinnedApps(screenName, onlySameOutput, onlyActiveWorkspaces) || [];
        pinnedEntries = source.filter(function (item) {
            return !(pinnedAppsHideWhenActive && item?.hasVisibleWindows);
        });
    }

    function entryKeyOf(entry) {
        if (typeof entry === "string")
            return String(entry);
        return String(entry?.entryKey || "");
    }

    function entryRecord(entry) {
        entryStateRev;
        const entryKey = entryKeyOf(entry);
        if (entryKey === "")
            return null;
        return mainInstance?.getEntryRecord(entryKey) || null;
    }

    function entryAppId(entry) {
        return String(entryRecord(entry)?.appId || "");
    }

    function entryCanonicalAppId(entry) {
        const record = entryRecord(entry);
        return String(record?.canonicalAppId || mainInstance?.resolveToDesktopEntryId(record?.appId || "") || record?.appId || "");
    }

    function entryHasSharedTitle(entry) {
        titleRev;
        const entryKey = entryKeyOf(entry);
        if (entryKey === "")
            return false;
        return mainInstance?.entryHasSharedTitle(entryKey) === true;
    }

    function ruleMatchSubject(entryKey, matchField) {
        const entry = entryRecord(entryKey);
        if (!entry)
            return "";
        const normalizedMatchField = normalizeStyleRuleMatchField(matchField);
        if (normalizedMatchField === "title")
            return currentTitle(entryKey);
        if (normalizedMatchField === "tag")
            return Array.isArray(entry?.tags) ? entry.tags.join(" ") : "";
        if (normalizedMatchField === "floating")
            return entry?.isFloating ? "floating" : "";
        if (normalizedMatchField === "urgent")
            return entry?.isUrgent ? "urgent" : "";
        if (normalizedMatchField === "grouped")
            return entry?.isGrouped ? "grouped" : "";
        if (normalizedMatchField === "sharedAppId")
            return entry?.sharesAppIdentity ? entryCanonicalAppId(entryKey) : "";
        if (normalizedMatchField === "sharedTitle")
            return entryHasSharedTitle(entryKey) ? currentTitle(entryKey) : "";
        return entryCanonicalAppId(entryKey);
    }

    function matchingStyleRule(entryKey) {
        if (!entryKey)
            return null;
        const rules = styleRuleItems();
        for (let index = 0; index < rules.length; index++) {
            const rule = rules[index];
            const matchField = normalizeStyleRuleMatchField(rule?.matchField);
            const pattern = String(rule?.pattern || "").trim();
            if (!rule?.enabled)
                continue;

            const subject = ruleMatchSubject(entryKey, rule.matchField);
            if (subject === "")
                continue;
            if (pattern === "") {
                if (styleRuleAllowsEmptyPattern(matchField))
                    return rule;
                continue;
            }

            try {
                if (new RegExp(pattern).test(subject))
                    return rule;
            } catch (error) {
                if (!invalidStyleRulePatterns[pattern]) {
                    const nextLogged = Object.assign({}, invalidStyleRulePatterns);
                    nextLogged[pattern] = true;
                    invalidStyleRulePatterns = nextLogged;
                    Logger.w("Scrollbar2", "Invalid custom style rule regex: " + pattern + " (" + error + ")");
                }
            }
        }
        return null;
    }

    function styleRuleStateValue(entryKey, groupKey, stateKey) {
        const matchingRule = matchingStyleRule(entryKey);
        if (!matchingRule)
            return null;
        return matchingRule.colors?.[groupKey]?.[stateKey] ?? null;
    }

    function resolvedSegmentStyle(entryKey) {
        const state = segmentState(entryKey);
        const overrideState = styleRuleStateValue(entryKey, "segment", state);
        if (overrideState?.enabled === true) {
            const overrideColor = resolveColor(overrideState.color, state === "focused" ? focusLineFocusedColor : (state === "hover" ? focusLineHoverColor : focusLineDefaultColor));
            return colorWithOpacity(overrideColor, focusLineOpacity * overrideState.opacity);
        }
        return null;
    }

    function customStyleRuleForEntry(entryKey) {
        return matchingStyleRule(entryKey);
    }

    function customRuleIconName(entryKey) {
        const matchingRule = customStyleRuleForEntry(entryKey);
        return String(matchingRule?.customIcon || "");
    }

    function resolvedLabelState(entryKey, kind) {
        const state = segmentState(entryKey);
        const fallbackKey = kind === "icon" ? (state === "focused" ? iconColorFocusedKey : (state === "hover" ? iconColorHoverKey : iconColorDefaultKey)) : (state === "focused" ? titleColorFocusedKey : (state === "hover" ? titleColorHoverKey : titleColorDefaultKey));
        const fallbackOpacity = kind === "icon" ? (state === "focused" ? iconColorFocusedOpacity : (state === "hover" ? iconColorHoverOpacity : iconColorDefaultOpacity)) : (state === "focused" ? titleColorFocusedOpacity : (state === "hover" ? titleColorHoverOpacity : titleColorDefaultOpacity));
        const fallbackColor = kind === "icon" ? (state === "focused" ? iconColorFocused : (state === "hover" ? iconColorHover : iconColorDefault)) : (state === "focused" ? titleColorFocused : (state === "hover" ? titleColorHover : titleColorDefault));
        const overrideState = styleRuleStateValue(entryKey, kind, state);
        const hasExplicitOverride = overrideState?.enabled === true;
        const effectiveKey = String(hasExplicitOverride ? overrideState.color : fallbackKey);
        const effectiveOpacity = hasExplicitOverride ? overrideState.opacity : fallbackOpacity;
        const effectiveColor = hasExplicitOverride ? resolveColor(effectiveKey, fallbackColor) : fallbackColor;
        return {
            "key": effectiveKey,
            "opacity": effectiveOpacity,
            "color": effectiveColor
        };
    }

    function nestedWindowStateOpacity(groupKey, stateKey, fallbackValue) {
        const value = currentSettings?.window?.[groupKey]?.[stateKey];
        if (value && typeof value === "object" && !Array.isArray(value) && value.opacity !== undefined)
            return normalizeOpacityValue(value.opacity, fallbackValue);

        const defaultValue = defaults?.window?.[groupKey]?.[stateKey];
        if (defaultValue && typeof defaultValue === "object" && !Array.isArray(defaultValue) && defaultValue.opacity !== undefined)
            return normalizeOpacityValue(defaultValue.opacity, fallbackValue);

        return fallbackValue;
    }

    readonly property bool onlySameOutput: settingValue("filtering", "onlySameOutput", true)
    readonly property bool onlyActiveWorkspaces: settingValue("filtering", "onlyActiveWorkspaces", true)
    readonly property string trackPosition: settingValue("track", "position", "bottom")
    readonly property string trackVerticalAlign: settingValue("track", "verticalAlign", "bottom")
    readonly property real trackThickness: Math.max(1, settingValue("track", "thickness", 6) * Style.uiScaleRatio)
    readonly property real trackBorderRadius: Math.max(0, settingValue("track", "borderRadius", 3) * Style.uiScaleRatio)
    readonly property bool trackShadowEnabled: settingValue("track", "shadowEnabled", true)
    readonly property real trackOpacity: normalizeOpacityValue(objectSettingValue("track", "fill", "opacity", settingValue("track", "opacity", 1)), 1)
    readonly property color trackColor: resolveColor(objectSettingValue("track", "fill", "color", settingValue("track", "color", "surface")), Color.mSurface)
    readonly property color separatorColor: resolveColor(settingValue("track", "separatorColor", "outline"), Color.mOutline)
    readonly property real trackWidthPercent: Math.max(5, Math.min(100, settingValue("track", "width", 90)))
    readonly property real segmentSpacing: Math.max(0, settingValue("track", "segmentSpacing", 4) * Style.uiScaleRatio)

    readonly property real focusLineThickness: Math.max(1, settingValue("focusLine", "thickness", 6) * Style.uiScaleRatio)
    readonly property real focusLineWidthPercent: Math.max(1, Math.min(100, settingValue("focusLine", "width", 100)))
    readonly property real focusLineRadius: Math.max(0, settingValue("focusLine", "borderRadius", 3) * Style.uiScaleRatio)
    readonly property string focusLineVerticalAlign: settingValue("focusLine", "verticalAlign", "bottom")
    readonly property real focusLineOpacity: normalizeOpacityValue(settingValue("focusLine", "opacity", 1), 1)
    readonly property string focusLineFocusedColorKey: nestedStateColor("focusLine", "focused", "primary")
    readonly property string focusLineHoverColorKey: nestedStateColor("focusLine", "hover", "hover")
    readonly property string focusLineDefaultColorKey: nestedStateColor("focusLine", "default", "surface-variant")
    readonly property real focusLineFocusedOpacity: nestedStateOpacity("focusLine", "focused", 1)
    readonly property real focusLineHoverOpacity: nestedStateOpacity("focusLine", "hover", 1)
    readonly property real focusLineDefaultOpacity: nestedStateOpacity("focusLine", "default", 1)
    readonly property bool focusLineFocusedEnabled: nestedStateEnabled("focusLine", "focused", true)
    readonly property bool focusLineHoverEnabled: nestedStateEnabled("focusLine", "hover", true)
    readonly property bool focusLineDefaultEnabled: nestedStateEnabled("focusLine", "default", true)
    readonly property color focusLineFocusedColor: resolveColor(focusLineFocusedColorKey, Color.mPrimary)
    readonly property color focusLineHoverColor: resolveColor(focusLineHoverColorKey, Color.mHover)
    readonly property color focusLineDefaultColor: resolveColor(focusLineDefaultColorKey, Color.mSurfaceVariant)

    readonly property string focusLineIndicatorColorKey: objectSettingValue("focusLine", "lineColor", "color", "primary")
    readonly property real focusLineIndicatorOpacity: normalizeOpacityValue(objectSettingValue("focusLine", "lineColor", "opacity", 1), 1)
    readonly property color focusLineIndicatorColor: resolveColor(focusLineIndicatorColorKey, Color.mPrimary)

    readonly property bool showIcon: settingValue("window", "showIcon", true)
    readonly property bool showTitle: settingValue("window", "showTitle", true)
    readonly property bool dragReorderEnabled: settingValue("window", "dragReorderEnabled", true)
    readonly property bool focusedOnly: settingValue("window", "focusedOnly", false)
    readonly property string focusedAlign: settingValue("window", "focusedAlign", "segment")
    readonly property real windowBorderRadius: Math.max(0, settingValue("window", "borderRadius", 6) * Style.uiScaleRatio)
    readonly property real windowMargin: Math.max(0, settingValue("window", "margin", 2) * Style.uiScaleRatio)
    readonly property real windowPaddingLeft: Math.max(0, settingValue("window", "paddingLeft", 7) * Style.uiScaleRatio)
    readonly property real windowPaddingRight: Math.max(0, settingValue("window", "paddingRight", 7) * Style.uiScaleRatio)
    readonly property real windowPaddingTop: Math.max(0, settingValue("window", "paddingTop", 0) * Style.uiScaleRatio)
    readonly property real windowPaddingBottom: Math.max(0, settingValue("window", "paddingBottom", 0) * Style.uiScaleRatio)
    readonly property string titleFontFamily: settingValue("window", "font", "JetBrains Mono")
    readonly property real titleFontSize: Math.max(1, settingValue("window", "fontSize", 11) * Style.uiScaleRatio)
    readonly property real iconScale: Math.max(0.5, settingValue("window", "iconScale", 1.0))
    readonly property real titleScale: Math.max(0.5, settingValue("window", "titleScale", 1.0))
    readonly property string iconAlign: settingValue("window", "iconAlign", "center")
    readonly property string titleAlign: settingValue("window", "titleAlign", "left")
    readonly property string titleWeightFocused: currentSettings?.window?.fontWeights?.focused ?? defaults?.window?.fontWeights?.focused ?? "semibold"
    readonly property string titleWeightHover: currentSettings?.window?.fontWeights?.hover ?? defaults?.window?.fontWeights?.hover ?? "medium"
    readonly property string titleWeightDefault: currentSettings?.window?.fontWeights?.default ?? defaults?.window?.fontWeights?.default ?? "medium"
    readonly property string iconColorFocusedKey: nestedWindowStateColor("iconColors", "focused", "on-surface")
    readonly property string iconColorHoverKey: nestedWindowStateColor("iconColors", "hover", "on-hover")
    readonly property string iconColorDefaultKey: nestedWindowStateColor("iconColors", "default", "on-surface-variant")
    readonly property real iconColorFocusedOpacity: nestedWindowStateOpacity("iconColors", "focused", 1)
    readonly property real iconColorHoverOpacity: nestedWindowStateOpacity("iconColors", "hover", 1)
    readonly property real iconColorDefaultOpacity: nestedWindowStateOpacity("iconColors", "default", 1)
    readonly property string titleColorFocusedKey: nestedWindowStateColor("titleColors", "focused", "on-surface")
    readonly property string titleColorHoverKey: nestedWindowStateColor("titleColors", "hover", "on-hover")
    readonly property string titleColorDefaultKey: nestedWindowStateColor("titleColors", "default", "on-surface-variant")
    readonly property real titleColorFocusedOpacity: nestedWindowStateOpacity("titleColors", "focused", 1)
    readonly property real titleColorHoverOpacity: nestedWindowStateOpacity("titleColors", "hover", 1)
    readonly property real titleColorDefaultOpacity: nestedWindowStateOpacity("titleColors", "default", 1)
    readonly property color iconColorFocused: resolveColor(iconColorFocusedKey, Color.mOnSurface)
    readonly property color iconColorHover: resolveColor(iconColorHoverKey, Color.mOnHover)
    readonly property color iconColorDefault: resolveColor(iconColorDefaultKey, Color.mOnSurfaceVariant)
    readonly property color titleColorFocused: resolveColor(titleColorFocusedKey, Color.mOnSurface)
    readonly property color titleColorHover: resolveColor(titleColorHoverKey, Color.mOnHover)
    readonly property color titleColorDefault: resolveColor(titleColorDefaultKey, Color.mOnSurfaceVariant)

    readonly property bool animationEnabled: settingValue("animation", "enabled", true)
    readonly property string animationType: settingValue("animation", "type", "spring")
    readonly property int animationSpeed: Math.max(0, Math.round(settingValue("animation", "speed", 420)))
    readonly property bool workspaceIndicatorEnabled: settingValue("workspaceIndicator", "enabled", false)
    readonly property string workspaceIndicatorLabelMode: settingValue("workspaceIndicator", "labelMode", "id")
    readonly property string workspaceIndicatorPresetText: String(settingValue("workspaceIndicator", "presetText", "") || "").trim()
    readonly property string workspaceIndicatorPosition: settingValue("workspaceIndicator", "position", "left")
    readonly property string workspaceIndicatorVerticalAlign: settingValue("workspaceIndicator", "verticalAlign", "center")
    readonly property real workspaceIndicatorPaddingX: Math.max(0, settingValue("workspaceIndicator", "paddingX", 10) * Style.uiScaleRatio)
    readonly property real workspaceIndicatorPaddingY: Math.max(0, settingValue("workspaceIndicator", "paddingY", 4) * Style.uiScaleRatio)
    readonly property real workspaceIndicatorMarginLeft: Math.max(0, settingValue("workspaceIndicator", "marginLeft", 8) * Style.uiScaleRatio)
    readonly property real workspaceIndicatorMarginRight: Math.max(0, settingValue("workspaceIndicator", "marginRight", 8) * Style.uiScaleRatio)
    readonly property real workspaceIndicatorBorderRadius: Math.max(0, settingValue("workspaceIndicator", "borderRadius", 999) * Style.uiScaleRatio)
    readonly property color workspaceIndicatorBackgroundColor: resolveColor(objectSettingValue("workspaceIndicator", "background", "color", "surface"), Color.mSurface)
    readonly property real workspaceIndicatorBackgroundOpacity: normalizeOpacityValue(objectSettingValue("workspaceIndicator", "background", "opacity", 0.72), 0.72)
    readonly property string workspaceIndicatorFontFamily: currentSettings?.workspaceIndicator?.font?.family ?? defaults?.workspaceIndicator?.font?.family ?? "JetBrains Mono"
    readonly property real workspaceIndicatorFontSize: Math.max(1, (currentSettings?.workspaceIndicator?.font?.size ?? defaults?.workspaceIndicator?.font?.size ?? 11) * Style.uiScaleRatio)
    readonly property string workspaceIndicatorFontWeightKey: currentSettings?.workspaceIndicator?.font?.weight ?? defaults?.workspaceIndicator?.font?.weight ?? "medium"
    readonly property string workspaceIndicatorTextColorKey: currentSettings?.workspaceIndicator?.font?.color?.color ?? defaults?.workspaceIndicator?.font?.color?.color ?? "on-surface"
    readonly property real workspaceIndicatorTextOpacity: normalizeOpacityValue(currentSettings?.workspaceIndicator?.font?.color?.opacity ?? defaults?.workspaceIndicator?.font?.color?.opacity ?? 1, 1)
    readonly property color workspaceIndicatorTextColor: resolveColor(workspaceIndicatorTextColorKey, Color.mOnSurface)
    readonly property bool workspaceIndicatorBadgeEnabled: currentSettings?.workspaceIndicator?.badge?.enabled ?? defaults?.workspaceIndicator?.badge?.enabled ?? false
    readonly property color workspaceIndicatorBadgeBackgroundColor: resolveColor(currentSettings?.workspaceIndicator?.badge?.background?.color ?? defaults?.workspaceIndicator?.badge?.background?.color ?? "primary", Color.mPrimary)
    readonly property real workspaceIndicatorBadgeBackgroundOpacity: normalizeOpacityValue(currentSettings?.workspaceIndicator?.badge?.background?.opacity ?? defaults?.workspaceIndicator?.badge?.background?.opacity ?? 1, 1)
    readonly property string workspaceIndicatorBadgeFontFamily: currentSettings?.workspaceIndicator?.badge?.font?.family ?? defaults?.workspaceIndicator?.badge?.font?.family ?? "JetBrains Mono"
    readonly property real workspaceIndicatorBadgeFontSize: Math.max(1, (currentSettings?.workspaceIndicator?.badge?.font?.size ?? defaults?.workspaceIndicator?.badge?.font?.size ?? 10) * Style.uiScaleRatio)
    readonly property string workspaceIndicatorBadgeFontWeightKey: currentSettings?.workspaceIndicator?.badge?.font?.weight ?? defaults?.workspaceIndicator?.badge?.font?.weight ?? "semibold"
    readonly property string workspaceIndicatorBadgeTextColorKey: currentSettings?.workspaceIndicator?.badge?.font?.color?.color ?? defaults?.workspaceIndicator?.badge?.font?.color?.color ?? "on-primary"
    readonly property real workspaceIndicatorBadgeTextOpacity: normalizeOpacityValue(currentSettings?.workspaceIndicator?.badge?.font?.color?.opacity ?? defaults?.workspaceIndicator?.badge?.font?.color?.opacity ?? 1, 1)
    readonly property color workspaceIndicatorBadgeTextColor: resolveColor(workspaceIndicatorBadgeTextColorKey, Color.mOnPrimary)
    readonly property bool workspaceIndicatorAnimationEnabled: currentSettings?.workspaceIndicator?.animation?.enabled ?? defaults?.workspaceIndicator?.animation?.enabled ?? true
    readonly property string workspaceIndicatorAnimationAxis: currentSettings?.workspaceIndicator?.animation?.axis ?? defaults?.workspaceIndicator?.animation?.axis ?? "horizontal"
    readonly property string workspaceIndicatorAnimationType: currentSettings?.workspaceIndicator?.animation?.type ?? defaults?.workspaceIndicator?.animation?.type ?? "smooth"
    readonly property int workspaceIndicatorAnimationSpeed: Math.max(0, Math.round(currentSettings?.workspaceIndicator?.animation?.speed ?? defaults?.workspaceIndicator?.animation?.speed ?? 220))
    readonly property bool specialWorkspaceOverlayEnabled: settingValue("specialWorkspaceOverlay", "enabled", false)
    readonly property string specialWorkspaceOverlayTextMode: settingValue("specialWorkspaceOverlay", "textMode", "stripped")
    readonly property string specialWorkspaceOverlayCustomLabel: String(settingValue("specialWorkspaceOverlay", "customLabel", "") || "").trim()
    readonly property bool specialWorkspaceOverlayShowWindowIcons: settingValue("specialWorkspaceOverlay", "showWindowIcons", false)
    readonly property real specialWorkspaceOverlayWidthPercent: Math.max(50, Math.min(100, settingValue("specialWorkspaceOverlay", "widthPercent", 100)))
    readonly property real specialWorkspaceOverlayHeightPercent: Math.max(50, Math.min(100, settingValue("specialWorkspaceOverlay", "heightPercent", 70)))
    readonly property color specialWorkspaceOverlayBackgroundColor: resolveColor(objectSettingValue("specialWorkspaceOverlay", "background", "color", "surface"), Color.mSurface)
    readonly property real specialWorkspaceOverlayBackgroundOpacity: normalizeOpacityValue(objectSettingValue("specialWorkspaceOverlay", "background", "opacity", 0.82), 0.82)
    readonly property string specialWorkspaceOverlayFontFamily: currentSettings?.specialWorkspaceOverlay?.font?.family ?? defaults?.specialWorkspaceOverlay?.font?.family ?? "JetBrains Mono"
    readonly property real specialWorkspaceOverlayFontSize: Math.max(1, (currentSettings?.specialWorkspaceOverlay?.font?.size ?? defaults?.specialWorkspaceOverlay?.font?.size ?? 11) * Style.uiScaleRatio)
    readonly property string specialWorkspaceOverlayFontWeightKey: currentSettings?.specialWorkspaceOverlay?.font?.weight ?? defaults?.specialWorkspaceOverlay?.font?.weight ?? "medium"
    readonly property string specialWorkspaceOverlayTextColorKey: currentSettings?.specialWorkspaceOverlay?.font?.color?.color ?? defaults?.specialWorkspaceOverlay?.font?.color?.color ?? "on-surface"
    readonly property real specialWorkspaceOverlayTextOpacity: normalizeOpacityValue(currentSettings?.specialWorkspaceOverlay?.font?.color?.opacity ?? defaults?.specialWorkspaceOverlay?.font?.color?.opacity ?? 1, 1)
    readonly property color specialWorkspaceOverlayTextColor: resolveColor(specialWorkspaceOverlayTextColorKey, Color.mOnSurface)
    readonly property bool specialWorkspaceOverlayAnimationEnabled: {
        const configured = currentSettings?.specialWorkspaceOverlay?.animation?.enabled;
        if (configured !== undefined && configured !== null)
            return configured !== false;
        const defaultValue = defaults?.specialWorkspaceOverlay?.animation?.enabled;
        if (defaultValue !== undefined && defaultValue !== null)
            return defaultValue !== false;
        return animationEnabled;
    }
    readonly property string specialWorkspaceOverlayAnimationAxis: {
        const configured = currentSettings?.specialWorkspaceOverlay?.animation?.axis;
        if (configured !== undefined && configured !== null && configured !== "")
            return String(configured);
        const defaultValue = defaults?.specialWorkspaceOverlay?.animation?.axis;
        if (defaultValue !== undefined && defaultValue !== null && defaultValue !== "")
            return String(defaultValue);
        return "vertical";
    }
    readonly property string specialWorkspaceOverlayAnimationType: {
        const configured = currentSettings?.specialWorkspaceOverlay?.animation?.type;
        if (configured !== undefined && configured !== null && configured !== "")
            return String(configured);
        const defaultValue = defaults?.specialWorkspaceOverlay?.animation?.type;
        if (defaultValue !== undefined && defaultValue !== null && defaultValue !== "")
            return String(defaultValue);
        return animationType;
    }
    readonly property int specialWorkspaceOverlayAnimationSpeed: {
        const configured = currentSettings?.specialWorkspaceOverlay?.animation?.speed;
        if (configured !== undefined && configured !== null && configured !== "" && !isNaN(Number(configured)))
            return Math.max(0, Math.round(Number(configured)));
        const defaultValue = defaults?.specialWorkspaceOverlay?.animation?.speed;
        if (defaultValue !== undefined && defaultValue !== null && defaultValue !== "" && !isNaN(Number(defaultValue)))
            return Math.max(0, Math.round(Number(defaultValue)));
        return animationSpeed;
    }
    readonly property real specialWorkspaceOverlayBorderRadius: {
        const configuredRadius = currentSettings?.specialWorkspaceOverlay?.borderRadius;
        if (configuredRadius !== undefined && configuredRadius !== null && configuredRadius !== "" && !isNaN(Number(configuredRadius)))
            return Math.max(0, Number(configuredRadius)) * Style.uiScaleRatio;

        const defaultRadius = defaults?.specialWorkspaceOverlay?.borderRadius;
        if (defaultRadius !== undefined && defaultRadius !== null && defaultRadius !== "" && !isNaN(Number(defaultRadius)))
            return Math.max(0, Number(defaultRadius)) * Style.uiScaleRatio;

        return trackBorderRadius;
    }
    readonly property bool trackEdgeFadeLeftEnabled: currentSettings?.track?.edgeFade?.leftEnabled ?? defaults?.track?.edgeFade?.leftEnabled ?? false
    readonly property bool trackEdgeFadeRightEnabled: currentSettings?.track?.edgeFade?.rightEnabled ?? defaults?.track?.edgeFade?.rightEnabled ?? false
    readonly property real trackEdgeFadeWidth: {
        const configuredWidth = Number(currentSettings?.track?.edgeFade?.width ?? defaults?.track?.edgeFade?.width ?? 24);
        return Math.max(0, (isNaN(configuredWidth) ? 24 : configuredWidth) * Style.uiScaleRatio);
    }
    readonly property string pinnedAppsPosition: settingValue("pinnedApps", "position", "left")
    readonly property string pinnedAppsIconColorKey: settingValue("pinnedApps", "iconColor", "on-surface")
    readonly property color pinnedAppsIconColor: resolveColor(pinnedAppsIconColorKey, Color.mOnSurface)
    readonly property real pinnedAppsMarginLeft: Math.max(0, settingValue("pinnedApps", "marginLeft", 8) * Style.uiScaleRatio)
    readonly property real pinnedAppsMarginRight: Math.max(0, settingValue("pinnedApps", "marginRight", 8) * Style.uiScaleRatio)
    readonly property bool pinnedAppsHideWhenActive: settingValue("pinnedApps", "hideWhenActive", false)
    readonly property string pinnedAppsActivateRunningBehavior: settingValue("pinnedApps", "activateRunningBehavior", "focusCycle")

    readonly property bool scrollWheelFocusEnabled: settingValue("mouseInteraction", "scrollWheelFocus", true)
    readonly property bool middleClickCloseEnabled: settingValue("mouseInteraction", "middleClickClose", true)
    readonly property bool workspaceScrollSwitchEnabled: settingValue("mouseInteraction", "workspaceScrollSwitch", false)
    readonly property bool windowAnimationEnabled: {
        const configured = currentSettings?.window?.animation?.enabled;
        if (configured !== undefined && configured !== null)
            return configured !== false;
        const defaultValue = defaults?.window?.animation?.enabled;
        if (defaultValue !== undefined && defaultValue !== null)
            return defaultValue !== false;
        return animationEnabled;
    }
    readonly property bool windowOpenAnimationEnabled: currentSettings?.window?.animation?.openEnabled ?? defaults?.window?.animation?.openEnabled ?? true
    readonly property bool windowCloseAnimationEnabled: currentSettings?.window?.animation?.closeEnabled ?? defaults?.window?.animation?.closeEnabled ?? true
    readonly property string windowAnimationType: {
        const configured = currentSettings?.window?.animation?.type;
        if (configured !== undefined && configured !== null && configured !== "")
            return String(configured);
        const defaultValue = defaults?.window?.animation?.type;
        if (defaultValue !== undefined && defaultValue !== null && defaultValue !== "")
            return String(defaultValue);
        return animationType;
    }
    readonly property int windowAnimationSpeed: {
        const configured = currentSettings?.window?.animation?.speed;
        if (configured !== undefined && configured !== null && configured !== "" && !isNaN(Number(configured)))
            return Math.max(0, Math.round(Number(configured)));
        const defaultValue = defaults?.window?.animation?.speed;
        if (defaultValue !== undefined && defaultValue !== null && defaultValue !== "" && !isNaN(Number(defaultValue)))
            return Math.max(0, Math.round(Number(defaultValue)));
        return animationSpeed;
    }
    readonly property bool windowOpenAnimationActive: windowAnimationEnabled && windowOpenAnimationEnabled && windowAnimationSpeed > 0
    readonly property bool windowCloseAnimationActive: windowAnimationEnabled && windowCloseAnimationEnabled && windowAnimationSpeed > 0

    readonly property int entryModelRev: mainInstance?.entryModelRevision ?? 0
    readonly property int entryStateRev: mainInstance?.entryStateRevision ?? 0
    readonly property int titleRev: mainInstance?.titleRevision ?? 0
    readonly property int liveRev: mainInstance?.liveRevision ?? 0
    readonly property int workspaceRev: mainInstance?.workspaceRevision ?? 0
    readonly property int activeSpecialRev: mainInstance?.activeSpecialRevision ?? 0
    readonly property int specialWorkspaceRevisionToken: workspaceRev + activeSpecialRev
    readonly property var activeWorkspace: mainInstance?.resolveWorkspaceForScreen(screenName) ?? null
    readonly property string activeWorkspaceIdText: {
        if (!activeWorkspace)
            return "";
        if (activeWorkspace.idx !== undefined && activeWorkspace.idx !== null && String(activeWorkspace.idx) !== "")
            return String(activeWorkspace.idx);
        if (activeWorkspace.id !== undefined && activeWorkspace.id !== null && String(activeWorkspace.id) !== "")
            return String(activeWorkspace.id);
        return "";
    }
    readonly property string activeWorkspaceNameText: String(activeWorkspace?.name || "").trim()
    readonly property var activeSpecialWorkspace: {
        const directMonitorRecord = hyprlandMonitor?.specialWorkspace;
        if (directMonitorRecord && (String(directMonitorRecord?.id ?? "").trim() !== "" || String(directMonitorRecord?.name ?? "").trim() !== "")) {
            return {
                "id": String(directMonitorRecord?.id ?? "").trim(),
                "name": String(directMonitorRecord?.name ?? "").trim()
            };
        }

        const resolvedMonitorName = String(hyprlandMonitor?.name || screenName).trim();
        return mainInstance?.resolveSpecialWorkspaceForScreen(resolvedMonitorName) ?? null;
    }
    readonly property string activeSpecialWorkspaceNameText: String(activeSpecialWorkspace?.name || "").trim()
    readonly property string activeSpecialWorkspaceStrippedName: {
        if (activeSpecialWorkspaceNameText.startsWith("special:"))
            return activeSpecialWorkspaceNameText.slice(8).trim();
        return activeSpecialWorkspaceNameText;
    }
    readonly property string specialWorkspaceOverlayLabelText: {
        switch (specialWorkspaceOverlayTextMode) {
        case "raw":
            return activeSpecialWorkspaceNameText;
        case "custom":
            return specialWorkspaceOverlayCustomLabel || activeSpecialWorkspaceStrippedName || activeSpecialWorkspaceNameText;
        default:
            return activeSpecialWorkspaceStrippedName || activeSpecialWorkspaceNameText;
        }
    }
    readonly property bool showSpecialWorkspaceOverlay: specialWorkspaceOverlayEnabled && hostVisible && specialWorkspaceOverlayLabelText !== ""

    readonly property string workspaceIndicatorValueText: {
        if (!activeWorkspace)
            return "";
        if (workspaceIndicatorLabelMode === "name")
            return activeWorkspaceNameText || activeWorkspaceIdText;
        return activeWorkspaceIdText || activeWorkspaceNameText;
    }
    readonly property string workspaceIndicatorText: {
        const parts = [];
        if (workspaceIndicatorPresetText)
            parts.push(workspaceIndicatorPresetText);
        if (workspaceIndicatorValueText)
            parts.push(workspaceIndicatorValueText);
        return parts.join(" ").trim();
    }
    readonly property int workspaceIndicatorBadgeCount: workspaceIndicatorBadgeEnabled && activeWorkspace ? (mainInstance?.countWindowsForWorkspace(screenName, activeWorkspace.id) ?? 0) : 0
    readonly property bool showWorkspaceIndicator: workspaceIndicatorEnabled && workspaceIndicatorText !== ""
    readonly property int segmentCount: entries.length
    readonly property int pinnedSegmentCount: pinnedEntries.length
    readonly property real availableWidth: Math.max(160 * Style.uiScaleRatio, Math.round((screen?.width || 1200) * trackWidthPercent / 100))
    readonly property real horizontalPadding: Math.max(2, Math.round(2 * Style.uiScaleRatio))
    readonly property real labelPaddingH: Math.max(6, Math.round(7 * Style.uiScaleRatio))
    readonly property real labelGap: Math.max(4, Math.round(5 * Style.uiScaleRatio))
    readonly property real computedIconSize: Math.max(12 * Style.uiScaleRatio, Math.round((titleFontSize + 5 * Style.uiScaleRatio) * iconScale))
    readonly property real computedLabelHeight: Math.max(computedIconSize, Math.round(titleFontSize * titleScale * 1.5))
    readonly property real computedContentHeight: {
        if (!showIcon && !showTitle)
            return Math.max(trackThickness, focusLineThickness);
        const windowContentHeight = computedLabelHeight + windowPaddingTop + windowPaddingBottom;
        return Math.max(trackThickness, focusLineThickness, windowContentHeight);
    }
    readonly property real availableContainerHeight: Math.max(1, hostMode === "bar" && root.height > 0 ? root.height : (hostMode === "bar" ? Style.getCapsuleHeightForScreen(screenName) : computedContentHeight))
    readonly property real visibleTrackThickness: Math.min(availableContainerHeight, trackThickness)
    readonly property real visibleFocusLineThickness: Math.min(availableContainerHeight, focusLineThickness)
    readonly property real segmentWidth: {
        if (segmentCount <= 0)
            return 0;
        const totalSpacing = Math.max(0, segmentCount - 1) * segmentSpacing;
        return Math.max(1, Math.floor((availableWidth - totalSpacing - horizontalPadding * 2) / segmentCount));
    }
    readonly property real actualTrackWidth: segmentCount > 0 ? (segmentWidth * segmentCount) + (Math.max(0, segmentCount - 1) * segmentSpacing) + horizontalPadding * 2 : 0
    readonly property real effectiveTrackWidth: (segmentCount > 0 || showSpecialWorkspaceOverlay) ? Math.max(actualTrackWidth, availableWidth) : actualTrackWidth
    readonly property real effectiveTrackEdgeFadeWidth: Math.min(Math.max(0, trackEdgeFadeWidth), Math.max(0, effectiveTrackWidth / 2))
    readonly property bool trackEdgeFadeActive: (trackEdgeFadeLeftEnabled || trackEdgeFadeRightEnabled) && effectiveTrackEdgeFadeWidth > 0 && effectiveTrackWidth > 0
    readonly property real specialWorkspaceOverlayWidth: Math.max(1, Math.round(effectiveTrackWidth * specialWorkspaceOverlayWidthPercent / 100))
    readonly property real specialWorkspaceOverlayHeight: Math.max(1, Math.round(availableContainerHeight * specialWorkspaceOverlayHeightPercent / 100))
    readonly property real specialWorkspaceOverlayContentPadding: Math.max(8, Math.round(10 * Style.uiScaleRatio))
    readonly property real specialWorkspaceOverlayIconSize: Math.max(14 * Style.uiScaleRatio, specialWorkspaceOverlayFontSize * 1.2)
    readonly property real specialWorkspaceOverlayIconGap: Math.max(8, Math.round(10 * Style.uiScaleRatio))
    readonly property real totalIndicatorWidth: showWorkspaceIndicator ? (workspaceIndicatorMarginLeft + workspaceContainer.width + workspaceIndicatorMarginRight) : 0
    readonly property real pinnedSlotSize: Math.max(Math.round(availableContainerHeight * 0.82), computedIconSize + horizontalPadding * 2)
    readonly property real pinnedAreaContentWidth: pinnedSegmentCount > 0 ? (pinnedSegmentCount * pinnedSlotSize) + (Math.max(0, pinnedSegmentCount - 1) * segmentSpacing) : 0
    readonly property real pinnedAreaWidth: pinnedSegmentCount > 0 ? (pinnedAppsMarginLeft + pinnedAreaContentWidth + pinnedAppsMarginRight) : 0
    readonly property real leftAccessoryWidth: (showWorkspaceIndicator && workspaceIndicatorPosition === "left" ? totalIndicatorWidth : 0) + (pinnedSegmentCount > 0 && pinnedAppsPosition === "left" ? pinnedAreaWidth : 0)
    readonly property real rightAccessoryWidth: (showWorkspaceIndicator && workspaceIndicatorPosition === "right" ? totalIndicatorWidth : 0) + (pinnedSegmentCount > 0 && pinnedAppsPosition === "right" ? pinnedAreaWidth : 0)
    readonly property int focusedIndex: {
        liveRev;
        if (!mainInstance?.activeEntryKey)
            return -1;
        for (let i = 0; i < entries.length; i++) {
            if (entries[i] === mainInstance.activeEntryKey)
                return i;
        }
        return -1;
    }
    readonly property bool dragSessionActive: dragSourceIndex >= 0 && dragSourceEntryKey !== ""
    readonly property int normalizedPreviewIndex: normalizedInsertIndex(dragInsertIndex)
    readonly property bool dragPreviewActive: dragSessionActive && dragInsertIndex >= 0 && normalizedPreviewIndex >= 0 && canPreviewInsertIndex(dragSourceEntryKey, dragInsertIndex)
    readonly property int previewFocusIndex: dragPreviewActive ? normalizedPreviewIndex : -1
    readonly property int effectiveFocusIndex: previewFocusIndex >= 0 ? previewFocusIndex : focusedIndex
    readonly property bool contextMenuOpen: contextMenu.visible

    implicitWidth: hostVisible && (segmentCount > 0 || showWorkspaceIndicator || pinnedSegmentCount > 0 || showSpecialWorkspaceOverlay) ? leftAccessoryWidth + effectiveTrackWidth + rightAccessoryWidth : 0
    implicitHeight: hostVisible && (segmentCount > 0 || showWorkspaceIndicator || pinnedSegmentCount > 0 || showSpecialWorkspaceOverlay) ? Math.max(availableContainerHeight, workspaceContainer.height, pinnedAppsContainer.height, specialWorkspaceOverlay.height) : 0
    visible: hostVisible && (segmentCount > 0 || showWorkspaceIndicator || pinnedSegmentCount > 0 || showSpecialWorkspaceOverlay)

    function workspaceIndicatorEasingType() {
        switch (workspaceIndicatorAnimationType) {
        case "linear":
            return Easing.Linear;
        case "ease":
            return Easing.InOutQuad;
        case "spring":
            return Easing.OutBack;
        default:
            return Easing.OutCubic;
        }
    }

    function workspaceIndicatorOvershoot() {
        return workspaceIndicatorAnimationType === "spring" ? 1.12 : 0;
    }

    function lifecycleEasingType(type) {
        switch (String(type || "")) {
        case "linear":
            return Easing.Linear;
        case "ease":
            return Easing.InOutQuad;
        case "spring":
            return Easing.OutBack;
        default:
            return Easing.OutCubic;
        }
    }

    function lifecycleOvershoot(type, springOvershoot) {
        return String(type || "") === "spring" ? springOvershoot : 0;
    }

    function specialWorkspaceOverlayEasingType() {
        return lifecycleEasingType(specialWorkspaceOverlayAnimationType);
    }

    function specialWorkspaceOverlayOvershoot() {
        return lifecycleOvershoot(specialWorkspaceOverlayAnimationType, 1.08);
    }

    function windowAnimationEasingType() {
        return lifecycleEasingType(windowAnimationType);
    }

    function windowAnimationOvershoot() {
        return lifecycleOvershoot(windowAnimationType, 1.1);
    }

    function workspaceIndicatorAlignedY() {
        return alignedY(workspaceIndicatorVerticalAlign, workspaceContainer.height);
    }

    function pinnedAppsAlignedY() {
        return Math.max(0, Math.round((root.implicitHeight - pinnedAppsContainer.height) / 2));
    }

    function updateWorkspaceIndicatorPresentation() {
        if (!showWorkspaceIndicator) {
            displayedWorkspaceText = "";
            outgoingWorkspaceText = "";
            displayedWorkspaceBadgeCount = 0;
            outgoingWorkspaceBadgeCount = 0;
            workspaceIndicatorTransitionProgress = 1;
            return;
        }

        const nextText = workspaceIndicatorText;
        const nextBadgeCount = workspaceIndicatorBadgeCount;
        if (displayedWorkspaceText === "") {
            displayedWorkspaceText = nextText;
            displayedWorkspaceBadgeCount = nextBadgeCount;
            outgoingWorkspaceText = "";
            outgoingWorkspaceBadgeCount = 0;
            workspaceIndicatorTransitionProgress = 1;
            return;
        }
        if (displayedWorkspaceText === nextText && displayedWorkspaceBadgeCount === nextBadgeCount)
            return;

        if (!workspaceIndicatorAnimationEnabled || workspaceIndicatorAnimationSpeed <= 0) {
            displayedWorkspaceText = nextText;
            displayedWorkspaceBadgeCount = nextBadgeCount;
            outgoingWorkspaceText = "";
            outgoingWorkspaceBadgeCount = 0;
            workspaceIndicatorTransitionProgress = 1;
            return;
        }

        outgoingWorkspaceText = displayedWorkspaceText;
        outgoingWorkspaceBadgeCount = displayedWorkspaceBadgeCount;
        displayedWorkspaceText = nextText;
        displayedWorkspaceBadgeCount = nextBadgeCount;
        workspaceIndicatorTransitionProgress = 0;
        workspaceIndicatorSwap.restart();
    }

    function updateSpecialWorkspaceOverlayPresentation() {
        const nextText = specialWorkspaceOverlayLabelText;
        const nextIcons = currentSpecialWorkspaceOverlayIcons();
        if (nextText === "") {
            displayedSpecialWorkspaceText = "";
            outgoingSpecialWorkspaceText = "";
            displayedSpecialWorkspaceIcons = [];
            outgoingSpecialWorkspaceIcons = [];
            specialWorkspaceOverlayTransitionProgress = 1;
            return;
        }

        if (displayedSpecialWorkspaceText === "") {
            displayedSpecialWorkspaceText = nextText;
            outgoingSpecialWorkspaceText = "";
            displayedSpecialWorkspaceIcons = nextIcons;
            outgoingSpecialWorkspaceIcons = [];
            specialWorkspaceOverlayTransitionProgress = 1;
            return;
        }

        if (displayedSpecialWorkspaceText === nextText && root._sameStringList(displayedSpecialWorkspaceIcons, nextIcons))
            return;

        if (!specialWorkspaceOverlayAnimationEnabled || specialWorkspaceOverlayAnimationSpeed <= 0) {
            displayedSpecialWorkspaceText = nextText;
            outgoingSpecialWorkspaceText = "";
            displayedSpecialWorkspaceIcons = nextIcons;
            outgoingSpecialWorkspaceIcons = [];
            specialWorkspaceOverlayTransitionProgress = 1;
            return;
        }

        outgoingSpecialWorkspaceText = displayedSpecialWorkspaceText;
        outgoingSpecialWorkspaceIcons = displayedSpecialWorkspaceIcons.slice();
        displayedSpecialWorkspaceText = nextText;
        displayedSpecialWorkspaceIcons = nextIcons;
        specialWorkspaceOverlayTransitionProgress = 0;
        specialWorkspaceOverlaySwap.restart();
    }

    function _sameStringList(a, b) {
        if (a === b)
            return true;
        if (!Array.isArray(a) || !Array.isArray(b))
            return false;
        if (a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (String(a[i] ?? "") !== String(b[i] ?? ""))
                return false;
        }
        return true;
    }

    function currentSpecialWorkspaceOverlayIcons() {
        if (!specialWorkspaceOverlayShowWindowIcons || !activeSpecialWorkspace)
            return [];
        const icons = mainInstance?.getWorkspaceWindowAppIds(screenName, activeSpecialWorkspace.id, activeSpecialWorkspace.name) || [];
        return Array.isArray(icons) ? icons.slice() : [];
    }

    function currentGlobalEntryKeys() {
        entryModelRev;
        const source = mainInstance?.entryOrder || [];
        return Array.isArray(source) ? source.slice() : [];
    }

    function specialWorkspaceOverlayTransitionOffset() {
        return Math.max(4, root.specialWorkspaceOverlayHeight * 0.14);
    }

    function updateLiveSegmentSnapshot(entryKey, snapshot) {
        if (!entryKey)
            return;
        const next = ({});
        for (const key in liveSegmentSnapshots)
            next[key] = liveSegmentSnapshots[key];
        next[entryKey] = snapshot;
        liveSegmentSnapshots = next;
    }

    function consumeEnteringEntry(entryKey) {
        if (!enteringEntryKeys?.[entryKey])
            return false;
        const next = ({});
        for (const key in enteringEntryKeys) {
            if (key !== entryKey)
                next[key] = enteringEntryKeys[key];
        }
        enteringEntryKeys = next;
        return true;
    }

    function pruneLiveSegmentSnapshots(activeKeys) {
        const keepKeys = ({});
        (activeKeys || []).forEach(function (entryKey) {
            keepKeys[entryKey] = true;
        });
        (closingEntries || []).forEach(function (entry) {
            if (entry?.entryKey)
                keepKeys[entry.entryKey] = true;
        });

        const next = ({});
        for (const key in liveSegmentSnapshots) {
            if (keepKeys[key])
                next[key] = liveSegmentSnapshots[key];
        }
        liveSegmentSnapshots = next;
    }

    function queueClosingEntry(entryKey) {
        if (!entryKey || !windowCloseAnimationActive)
            return;
        if ((closingEntries || []).some(function (entry) {
            return entry?.entryKey === entryKey;
        }))
            return;

        const snapshot = liveSegmentSnapshots?.[entryKey];
        if (!snapshot)
            return;

        const nextEntry = {
            "uid": ++closingEntryUidSeed,
            "entryKey": entryKey,
            "x": snapshot.x ?? 0,
            "y": snapshot.y ?? 0,
            "width": snapshot.width ?? 0,
            "height": snapshot.height ?? 0,
            "appId": snapshot.appId ?? "",
            "title": snapshot.title ?? "",
            "showLabel": snapshot.showLabel !== false,
            "backgroundColor": snapshot.backgroundColor ?? "transparent",
            "iconColor": snapshot.iconColor ?? Color.mOnSurface,
            "titleColor": snapshot.titleColor ?? Color.mOnSurface,
            "titleWeight": snapshot.titleWeight ?? Style.fontWeightMedium,
            "customIcon": snapshot.customIcon ?? ""
        };
        closingEntries = (closingEntries || []).concat([nextEntry]);
    }

    function removeClosingEntry(uid) {
        closingEntries = (closingEntries || []).filter(function (entry) {
            return entry?.uid !== uid;
        });
        pruneLiveSegmentSnapshots(previousEntryKeys);
    }

    function syncEntryLifecycle() {
        const activeKeys = (entries || []).map(function (entryKey) {
            return String(entryKey ?? "");
        }).filter(function (entryKey) {
            return entryKey !== "";
        });
        const globalKeys = currentGlobalEntryKeys();

        if (!entryLifecycleInitialized) {
            previousEntryKeys = activeKeys.slice();
            previousGlobalEntryKeys = globalKeys.slice();
            entryLifecycleInitialized = true;
            pruneLiveSegmentSnapshots(activeKeys);
            return;
        }

        const activeVisibleLookup = ({});
        activeKeys.forEach(function (entryKey) {
            activeVisibleLookup[entryKey] = true;
        });
        const previousGlobalLookup = ({});
        previousGlobalEntryKeys.forEach(function (entryKey) {
            previousGlobalLookup[entryKey] = true;
        });
        const activeGlobalLookup = ({});
        globalKeys.forEach(function (entryKey) {
            activeGlobalLookup[entryKey] = true;
        });

        const addedGlobalKeys = ({});
        globalKeys.forEach(function (entryKey) {
            if (!previousGlobalLookup[entryKey])
                addedGlobalKeys[entryKey] = true;
        });
        const removedGlobalKeys = ({});
        previousGlobalEntryKeys.forEach(function (entryKey) {
            if (!activeGlobalLookup[entryKey])
                removedGlobalKeys[entryKey] = true;
        });

        const nextEntering = ({});
        for (const key in enteringEntryKeys) {
            if (activeVisibleLookup[key])
                nextEntering[key] = enteringEntryKeys[key];
        }

        activeKeys.forEach(function (entryKey) {
            if (addedGlobalKeys[entryKey] && windowOpenAnimationActive)
                nextEntering[entryKey] = true;
        });
        enteringEntryKeys = nextEntering;

        previousEntryKeys.forEach(function (entryKey) {
            if (removedGlobalKeys[entryKey])
                queueClosingEntry(entryKey);
        });

        previousEntryKeys = activeKeys.slice();
        previousGlobalEntryKeys = globalKeys.slice();
        pruneLiveSegmentSnapshots(activeKeys);
    }

    onEntriesChanged: syncEntryLifecycle()
    onWorkspaceIndicatorTextChanged: updateWorkspaceIndicatorPresentation()
    onWorkspaceIndicatorBadgeCountChanged: updateWorkspaceIndicatorPresentation()
    onSpecialWorkspaceOverlayLabelTextChanged: updateSpecialWorkspaceOverlayPresentation()
    onSpecialWorkspaceRevisionTokenChanged: updateSpecialWorkspaceOverlayPresentation()
    onScreenNameChanged: {
        refreshEntriesCache();
        refreshPinnedEntriesCache();
    }
    onOnlySameOutputChanged: {
        refreshEntriesCache();
        refreshPinnedEntriesCache();
    }
    onOnlyActiveWorkspacesChanged: {
        refreshEntriesCache();
        refreshPinnedEntriesCache();
    }
    onPinnedAppsHideWhenActiveChanged: refreshPinnedEntriesCache()
    onMainInstanceChanged: {
        refreshEntriesCache();
        refreshPinnedEntriesCache();
    }
    onWindowCloseAnimationActiveChanged: {
        if (!windowCloseAnimationActive) {
            closingEntries = [];
            pruneLiveSegmentSnapshots(previousEntryKeys);
        }
    }
    Component.onCompleted: {
        refreshEntriesCache();
        refreshPinnedEntriesCache();
        syncEntryLifecycle();
        updateWorkspaceIndicatorPresentation();
        updateSpecialWorkspaceOverlayPresentation();
    }

    function segmentState(entryKey) {
        const isFocused = mainInstance?.activeEntryKey === entryKey;
        if (isFocused)
            return "focused";
        if (hoveredEntryKey === entryKey)
            return "hover";
        return "default";
    }

    function segmentBackgroundColor(entryKey) {
        const overrideColor = resolvedSegmentStyle(entryKey);
        if (overrideColor !== null)
            return overrideColor;

        const state = segmentState(entryKey);
        if (state === "focused")
            return focusLineFocusedEnabled ? colorWithOpacity(focusLineFocusedColor, focusLineOpacity * focusLineFocusedOpacity) : "transparent";
        if (state === "hover")
            return focusLineHoverEnabled ? colorWithOpacity(focusLineHoverColor, focusLineOpacity * focusLineHoverOpacity) : "transparent";
        return focusLineDefaultEnabled ? colorWithOpacity(focusLineDefaultColor, focusLineOpacity * focusLineDefaultOpacity) : "transparent";
    }

    function labelColor(entryKey, kind) {
        const resolved = resolvedLabelState(entryKey, kind);
        return colorWithOpacity(resolved.color, resolved.opacity);
    }

    function iconTintEnabled(entryKey) {
        return resolvedLabelState(entryKey, "icon").key !== "none";
    }

    function titleWeight(entryKey) {
        switch (segmentState(entryKey)) {
        case "focused":
            return fontWeightValue(titleWeightFocused, Style.fontWeightSemiBold);
        case "hover":
            return fontWeightValue(titleWeightHover, Style.fontWeightMedium);
        default:
            return fontWeightValue(titleWeightDefault, Style.fontWeightMedium);
        }
    }

    function labelVisible(entryKey) {
        if (!focusedOnly)
            return true;
        if (focusedAlign === "center")
            return false;
        return mainInstance?.activeEntryKey === entryKey;
    }

    function indicatorOffset(index) {
        if (index < 0)
            return 0;
        return horizontalPadding + index * (segmentWidth + segmentSpacing);
    }

    function insertionMarkerCenter(rawInsertIndex) {
        const numericIndex = Number(rawInsertIndex);
        if (segmentCount <= 0 || isNaN(numericIndex) || numericIndex < 0)
            return horizontalPadding;
        const clampedIndex = Math.max(0, Math.min(segmentCount, numericIndex));
        if (clampedIndex <= 0)
            return horizontalPadding;
        if (clampedIndex >= segmentCount)
            return horizontalPadding + (segmentCount * segmentWidth) + (Math.max(0, segmentCount - 1) * segmentSpacing);
        return horizontalPadding + (clampedIndex * segmentWidth) + ((clampedIndex - 0.5) * segmentSpacing);
    }

    function insertionZoneStart(rawInsertIndex) {
        const clampedIndex = Math.max(0, Math.min(segmentCount, Number(rawInsertIndex)));
        if (segmentCount <= 0)
            return 0;
        if (clampedIndex <= 0)
            return 0;
        return insertionMarkerCenter(clampedIndex - 1);
    }

    function insertionZoneWidth(rawInsertIndex) {
        const clampedIndex = Math.max(0, Math.min(segmentCount, Number(rawInsertIndex)));
        const rowWidth = Math.max(0, (segmentCount * segmentWidth) + (Math.max(0, segmentCount - 1) * segmentSpacing));
        const start = insertionZoneStart(clampedIndex);
        const end = clampedIndex >= segmentCount ? rowWidth : insertionMarkerCenter(clampedIndex);
        return Math.max(1, end - start);
    }

    function separatorOffset(index) {
        return horizontalPadding + (index + 1) * segmentWidth + index * segmentSpacing;
    }

    function alignedY(alignKey, itemThickness) {
        if (alignKey === "top")
            return 0;
        if (alignKey === "center")
            return Math.round((availableContainerHeight - itemThickness) / 2);
        return Math.max(0, availableContainerHeight - itemThickness);
    }

    function trackLineY() {
        return alignedY(trackVerticalAlign, visibleTrackThickness);
    }

    function trackCenterY() {
        return trackLineY() + visibleTrackThickness / 2;
    }

    function specialWorkspaceOverlayY() {
        return Math.max(0, Math.round((implicitHeight - specialWorkspaceOverlayHeight) / 2));
    }

    function indicatorY() {
        return alignedY(focusLineVerticalAlign, visibleFocusLineThickness);
    }

    function focusLineEasingType() {
        switch (animationType) {
        case "linear":
            return Easing.Linear;
        case "ease":
            return Easing.InOutQuad;
        case "smooth":
            return Easing.OutCubic;
        default:
            return Easing.OutBack;
        }
    }

    function focusLineOvershoot() {
        return animationType === "spring" ? 1.15 : 0;
    }

    function focusedEntry() {
        if (focusedIndex < 0 || focusedIndex >= entries.length)
            return null;
        return entryRecord(entries[focusedIndex]);
    }

    function focusedEntryKey() {
        if (focusedIndex < 0 || focusedIndex >= entries.length)
            return "";
        return String(entries[focusedIndex] || "");
    }

    function horizontalAlignment(alignKey) {
        switch (alignKey) {
        case "center":
            return Text.AlignHCenter;
        case "right":
            return Text.AlignRight;
        default:
            return Text.AlignLeft;
        }
    }

    function fontWeightValue(weightKey, fallbackValue) {
        switch (weightKey) {
        case "light":
            return Font.Light;
        case "normal":
            return Font.Normal;
        case "medium":
            return Style.fontWeightMedium;
        case "semibold":
            return Style.fontWeightSemiBold;
        case "bold":
            return Style.fontWeightBold;
        default:
            return fallbackValue;
        }
    }

    function iconAnchor(alignKey) {
        switch (alignKey) {
        case "left":
            return 0;
        case "right":
            return 1;
        default:
            return 0.5;
        }
    }

    function currentTitle(entry) {
        titleRev;
        const entryKey = entryKeyOf(entry);
        if (!entryKey)
            return "";
        return mainInstance?.getEntryTitle(entryKey) || "";
    }

    function clearDragState() {
        Logger.d("Scrollbar2", "Drag preview cleared: source=" + dragSourceEntryKey + " raw=" + dragInsertIndex + " reason=clear");
        dragCleanupTimer.stop();
        dragDropHandled = false;
        dragSourceIndex = -1;
        dragInsertIndex = -1;
        dragSourceEntryKey = "";
    }

    function entryIndexByKey(entryKey) {
        for (let i = 0; i < entries.length; i++) {
            if (entries[i] === entryKey)
                return i;
        }
        return -1;
    }

    function canDragEntry(entryKey) {
        if (!dragReorderEnabled || isVerticalBar || mainInstance?.reorderInFlight)
            return false;
        return mainInstance?.canReorderEntry(entryKey, screenName, onlySameOutput, onlyActiveWorkspaces) === true;
    }

    function canDropOnEntry(sourceEntryKey, targetEntryKey) {
        if (!sourceEntryKey || !targetEntryKey || sourceEntryKey === targetEntryKey)
            return false;

        const sourceEntry = entryRecord(sourceEntryKey);
        const targetEntry = entryRecord(targetEntryKey);
        if (!sourceEntry || !targetEntry)
            return false;
        if (sourceEntry?.isFloating || targetEntry?.isFloating)
            return false;
        if (String(sourceEntry?.workspaceId ?? "") !== String(targetEntry?.workspaceId ?? ""))
            return false;
        if (String(sourceEntry?.output || "").toLowerCase() !== String(targetEntry?.output || "").toLowerCase())
            return false;
        return canDragEntry(sourceEntryKey) && canDragEntry(targetEntryKey);
    }

    function normalizedInsertIndex(rawInsertIndex) {
        if (dragSourceIndex < 0 || segmentCount <= 0)
            return -1;
        const numericIndex = Number(rawInsertIndex);
        if (isNaN(numericIndex) || numericIndex < 0)
            return -1;
        const clampedIndex = Math.max(0, Math.min(segmentCount, numericIndex));
        if (isNaN(clampedIndex))
            return -1;
        const normalizedIndex = clampedIndex > dragSourceIndex ? clampedIndex - 1 : clampedIndex;
        return Math.max(0, Math.min(segmentCount - 1, normalizedIndex));
    }

    function canPreviewInsertIndex(sourceEntryKey, rawInsertIndex) {
        if (!sourceEntryKey || segmentCount < 2)
            return false;
        const sourceIndex = entryIndexByKey(sourceEntryKey);
        if (sourceIndex < 0)
            return false;

        const normalizedIndex = normalizedInsertIndex(rawInsertIndex);
        if (normalizedIndex < 0 || normalizedIndex === sourceIndex)
            return false;

        const remainingEntries = entries.filter(function (entryKey) {
            return entryKey !== sourceEntryKey;
        });
        const insertIndex = Math.max(0, Math.min(remainingEntries.length, normalizedIndex));
        const previousNeighbor = insertIndex > 0 ? String(remainingEntries[insertIndex - 1] || "") : "";
        const nextNeighbor = insertIndex < remainingEntries.length ? String(remainingEntries[insertIndex] || "") : "";

        if (!previousNeighbor && !nextNeighbor)
            return false;
        if (previousNeighbor && !canDropOnEntry(sourceEntryKey, previousNeighbor))
            return false;
        if (nextNeighbor && !canDropOnEntry(sourceEntryKey, nextNeighbor))
            return false;

        return mainInstance?.canReorderToIndex(sourceEntryKey, normalizedIndex, screenName, onlySameOutput, onlyActiveWorkspaces) === true;
    }

    function setDragInsertIndex(rawInsertIndex, sourceEntryKey, reason) {
        const numericIndex = Number(rawInsertIndex);
        const nextInsertIndex = (isNaN(numericIndex) || numericIndex < 0) ? -1 : Math.max(0, Math.min(segmentCount, numericIndex));
        const nextValue = canPreviewInsertIndex(sourceEntryKey, nextInsertIndex) ? nextInsertIndex : -1;
        if (dragInsertIndex === nextValue)
            return;
        dragInsertIndex = nextValue;
        Logger.d("Scrollbar2", "Drag preview slot: source=" + sourceEntryKey + " raw=" + nextInsertIndex + " normalized=" + normalizedInsertIndex(nextValue) + " reason=" + String(reason || ""));
    }

    function finalizeDragReorder(sourceEntryKey, reason) {
        const normalizedIndex = normalizedInsertIndex(dragInsertIndex);
        const canDrop = dragSessionActive && sourceEntryKey !== "" && normalizedIndex >= 0 && canPreviewInsertIndex(sourceEntryKey, dragInsertIndex);

        dragDropHandled = true;
        dragCleanupTimer.stop();
        Logger.d("Scrollbar2", "Drag finalize: source=" + sourceEntryKey + " raw=" + dragInsertIndex + " normalized=" + normalizedIndex + " canDrop=" + canDrop + " reason=" + String(reason || ""));
        Logger.d("Scrollbar2", "Drag preview cleared: source=" + sourceEntryKey + " raw=" + dragInsertIndex + " reason=" + String(reason || ""));
        clearDragState();

        if (!canDrop)
            return false;

        return mainInstance?.requestEntryReorderToIndex(sourceEntryKey, normalizedIndex, screenName, onlySameOutput, onlyActiveWorkspaces) ?? false;
    }

    function clearContextSelection() {
        selectedEntryKey = "";
        selectedAppId = "";
    }

    function pinnedSlotBackgroundColor(appId) {
        const isHovered = hoveredPinnedAppId === appId;
        if (isHovered)
            return colorWithOpacity(focusLineHoverColor, focusLineOpacity * focusLineHoverOpacity);
        return colorWithOpacity(focusLineDefaultColor, focusLineOpacity * focusLineDefaultOpacity);
    }

    function pinnedAppIconSource(item) {
        const customIcon = String(item?.customIcon || "");
        if (customIcon !== "")
            return customIcon.startsWith("file://") ? customIcon : "file://" + customIcon;
        return ThemeIcons.iconForAppId(item?.appId || "");
    }

    function activatePinnedApp(appId) {
        const canonicalAppId = mainInstance?.resolveToDesktopEntryId(appId) || appId;
        const visibleEntries = mainInstance?.getVisibleEntriesForApp(screenName, canonicalAppId, onlySameOutput, onlyActiveWorkspaces) || [];

        if (visibleEntries.length === 0) {
            mainInstance?.launchPinnedApp(canonicalAppId);
            return;
        }

        if (pinnedAppsActivateRunningBehavior === "startNew") {
            mainInstance?.launchPinnedApp(canonicalAppId);
            return;
        }

        mainInstance?.cycleFocusVisibleInstances(screenName, canonicalAppId, onlySameOutput, onlyActiveWorkspaces);
    }

    function openContextMenu(anchorItem, entry, pinnedApp) {
        const model = [];

        if (entry) {
            selectedEntryKey = entry.entryKey ?? "";
            selectedAppId = entry.appId ?? "";

            // Window actions section
            model.push({
                "label": pluginApi?.tr("menu.focus"),
                "action": "focus",
                "icon": "eye"
            });
            model.push({
                "label": pluginApi?.tr("menu.closeWindow"),
                "action": "close",
                "icon": "x"
            });

            // Separator
            model.push({
                "isSeparator": true
            });

            // Desktop actions (if any)
            const desktopActions = mainInstance?.desktopEntryActionsForApp(selectedAppId) || [];
            desktopActions.forEach(function (item) {
                model.push(item);
            });

            // Separator before app-specific actions
            if (selectedAppId || desktopActions.length > 0) {
                model.push({
                    "isSeparator": true
                });
            }

            // App-specific actions
            if (selectedAppId) {
                const appPinned = mainInstance?.isAppPinned(selectedAppId) ?? false;
                model.push({
                    "label": pluginApi?.tr(appPinned ? "menu.unpinFromBar" : "menu.pinToBar"),
                    "action": appPinned ? "unpin" : "pin",
                    "icon": appPinned ? "unpin" : "pin"
                });
            }

            // Style Rules - single option that handles both app and title
            const hasExistingStyleRule = (mainInstance?.findPrefilledStyleRuleIndex(selectedEntryKey, "appId") ?? -1) >= 0 || (mainInstance?.findPrefilledStyleRuleIndex(selectedEntryKey, "title") ?? -1) >= 0;

            model.push({
                "label": pluginApi?.tr(hasExistingStyleRule ? "menu.editCustomStyleRule" : "menu.addCustomStyleRule"),
                "action": "custom-style-rule",
                "icon": "brush"
            });

            // Separator before settings
            model.push({
                "isSeparator": true
            });
        } else if (pinnedApp) {
            clearContextSelection();
            selectedAppId = pinnedApp.appId ?? "";

            model.push({
                "label": pluginApi?.tr("menu.unpinFromBar"),
                "action": "unpin",
                "icon": "unpin"
            });

            model.push({
                "isSeparator": true
            });
        } else {
            clearContextSelection();
        }

        // Settings (always shown at bottom)
        model.push({
            "label": pluginApi?.tr("menu.settings"),
            "action": "settings",
            "icon": "settings"
        });

        contextMenuModel = model;
        PanelService.showContextMenu(contextMenu, root, root.screen, anchorItem ?? root);
    }

    NumberAnimation {
        id: workspaceIndicatorSwap
        target: root
        property: "workspaceIndicatorTransitionProgress"
        from: 0
        to: 1
        duration: root.workspaceIndicatorAnimationSpeed
        easing.type: root.workspaceIndicatorEasingType()
        easing.overshoot: root.workspaceIndicatorOvershoot()
        onStopped: {
            if (root.workspaceIndicatorTransitionProgress >= 1) {
                root.outgoingWorkspaceText = "";
                root.outgoingWorkspaceBadgeCount = 0;
            }
        }
    }

    NumberAnimation {
        id: specialWorkspaceOverlaySwap
        target: root
        property: "specialWorkspaceOverlayTransitionProgress"
        from: 0
        to: 1
        duration: root.specialWorkspaceOverlayAnimationSpeed
        easing.type: root.specialWorkspaceOverlayEasingType()
        easing.overshoot: root.specialWorkspaceOverlayOvershoot()
        onStopped: {
            if (root.specialWorkspaceOverlayTransitionProgress >= 1) {
                root.outgoingSpecialWorkspaceText = "";
                root.outgoingSpecialWorkspaceIcons = [];
            }
        }
    }

    WorkspaceIndicatorContainer {
        id: workspaceContainer
        view: root
    }

    PinnedAppsContainer {
        id: pinnedAppsContainer
        view: root
    }

    Row {
        id: segmentsRow
        parent: trackContentLayer
        x: horizontalPadding
        y: 0
        width: Math.max(0, root.actualTrackWidth - horizontalPadding * 2)
        height: root.availableContainerHeight
        spacing: segmentSpacing
        z: 1

        Repeater {
            model: root.entries

            delegate: Item {
                id: segmentItem

                required property var modelData
                required property int index

                readonly property string entryKey: String(modelData || "")
                readonly property string title: root.currentTitle(entryKey)
                readonly property bool showLabel: root.labelVisible(entryKey)
                readonly property bool reorderable: root.canDragEntry(entryKey)
                readonly property var styleRule: root.customStyleRuleForEntry(entryKey)

                width: root.segmentWidth
                height: parent ? parent.height : root.availableContainerHeight
                z: root.dragSourceIndex === index ? 1000 : 1
                objectName: "scrollbar2WindowSegment"

                Item {
                    id: draggableContent
                    width: parent.width
                    height: parent.height

                    readonly property bool isDragged: root.dragSourceIndex === index
                    property real shiftOffset: 0
                    property bool dragging: segmentMouseArea.drag.active
                    property real lifecycleOpacity: 1
                    property real lifecycleScale: 1

                    function syncSnapshot() {
                        root.updateLiveSegmentSnapshot(segmentItem.entryKey, {
                            "x": segmentItem.x + segmentsRow.x,
                            "y": segmentItem.y + segmentsRow.y,
                            "width": segmentItem.width,
                            "height": segmentItem.height,
                            "appId": root.entryAppId(segmentItem.entryKey),
                            "title": segmentItem.title,
                            "showLabel": segmentItem.showLabel,
                            "backgroundColor": root.segmentBackgroundColor(segmentItem.entryKey),
                            "iconColor": root.labelColor(segmentItem.entryKey, "icon"),
                            "titleColor": root.labelColor(segmentItem.entryKey, "title"),
                            "titleWeight": root.titleWeight(segmentItem.entryKey),
                            "customIcon": root.customRuleIconName(segmentItem.entryKey)
                        });
                    }

                    function startEnterAnimation() {
                        if (!root.consumeEnteringEntry(segmentItem.entryKey) || !root.windowOpenAnimationActive)
                            return;
                        lifecycleOpacity = 0;
                        lifecycleScale = 0.88;
                        enterAnimation.restart();
                    }

                    Binding on x {
                        when: !draggableContent.dragging
                        value: 0
                    }

                    Binding on y {
                        when: !draggableContent.dragging
                        value: 0
                    }

                    Binding on shiftOffset {
                        value: {
                            if (root.dragSourceIndex !== -1 && root.dragInsertIndex !== -1 && root.dragPreviewActive && !draggableContent.isDragged) {
                                if (root.dragSourceIndex < root.dragInsertIndex) {
                                    if (index > root.dragSourceIndex && index < root.dragInsertIndex)
                                        return -(segmentItem.width + root.segmentSpacing);
                                } else if (root.dragSourceIndex >= root.dragInsertIndex) {
                                    if (index >= root.dragInsertIndex && index < root.dragSourceIndex)
                                        return segmentItem.width + root.segmentSpacing;
                                }
                            }
                            return 0;
                        }
                    }

                    transform: Translate {
                        x: draggableContent.shiftOffset

                        Behavior on x {
                            NumberAnimation {
                                duration: Style.animationFast
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    onDraggingChanged: {
                        if (dragging) {
                            dragCleanupTimer.stop();
                            root.dragDropHandled = false;
                            root.dragSourceIndex = index;
                            root.dragInsertIndex = index;
                            root.dragSourceEntryKey = segmentItem.entryKey;
                            Logger.d("Scrollbar2", "Drag start: entry=" + segmentItem.entryKey + " index=" + index + " focused=" + root.focusedIndex);
                        } else if (root.dragSourceEntryKey === segmentItem.entryKey) {
                            Logger.d("Scrollbar2", "Drag end pending: source=" + segmentItem.entryKey + " raw=" + root.dragInsertIndex);
                            dragCleanupTimer.restart();
                        }
                    }

                    Drag.active: dragging && segmentItem.reorderable
                    Drag.source: segmentItem
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    Drag.keys: ["scrollbar2-window"]
                    z: dragging ? 1000 : 0
                    scale: dragging ? 1.03 : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: Style.animationFast
                        }
                    }

                    Item {
                        id: lifecycleWrapper
                        anchors.fill: parent
                        clip: true
                        opacity: draggableContent.lifecycleOpacity
                        scale: draggableContent.lifecycleScale
                        transformOrigin: Item.Center
                    }

                    ParallelAnimation {
                        id: enterAnimation

                        NumberAnimation {
                            target: draggableContent
                            property: "lifecycleOpacity"
                            from: 0
                            to: 1
                            duration: root.windowAnimationSpeed
                            easing.type: root.windowAnimationEasingType()
                            easing.overshoot: root.windowAnimationOvershoot()
                        }

                        NumberAnimation {
                            target: draggableContent
                            property: "lifecycleScale"
                            from: 0.88
                            to: 1
                            duration: root.windowAnimationSpeed
                            easing.type: root.windowAnimationEasingType()
                            easing.overshoot: root.windowAnimationOvershoot()
                        }
                    }

                    Timer {
                        id: enterAnimationDelay
                        interval: 0
                        repeat: false
                        onTriggered: {
                            draggableContent.syncSnapshot();
                            draggableContent.startEnterAnimation();
                        }
                    }

                    Rectangle {
                        parent: lifecycleWrapper
                        anchors.fill: parent
                        anchors.margins: root.windowMargin
                        radius: Math.min(Math.max(0, root.windowBorderRadius), Math.max(0, Math.min(width, height) / 2))
                        color: root.segmentBackgroundColor(segmentItem.entryKey)
                        z: 0

                        Behavior on color {
                            enabled: root.animationEnabled
                            ColorAnimation {
                                duration: root.animationSpeed
                            }
                        }
                    }

                    Rectangle {
                        id: blinkOverlay
                        parent: lifecycleWrapper

                        readonly property bool active: segmentItem.styleRule?.blink?.enabled ?? false
                        readonly property int blinkDuration: Math.max(200, segmentItem.styleRule?.blink?.interval ?? 800)
                        readonly property color blinkColor: {
                            if (!active)
                                return "transparent";
                            return root.colorWithOpacity(root.resolveColor(segmentItem.styleRule.blink.color?.color ?? "primary", Color.mPrimary), root.normalizeOpacityValue(segmentItem.styleRule.blink.color?.opacity ?? 1, 1));
                        }

                        anchors.fill: parent
                        anchors.margins: root.windowMargin
                        radius: Math.min(Math.max(0, root.windowBorderRadius), Math.max(0, Math.min(width, height) / 2))
                        color: blinkColor
                        visible: active
                        opacity: 0
                        z: 1

                        SequentialAnimation on opacity {
                            running: blinkOverlay.visible
                            loops: Animation.Infinite
                            alwaysRunToEnd: true
                            NumberAnimation {
                                from: 0
                                to: 1
                                duration: blinkOverlay.blinkDuration / 2
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 1
                                to: 0
                                duration: blinkOverlay.blinkDuration / 2
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    Rectangle {
                        parent: lifecycleWrapper
                        readonly property bool active: (segmentItem.styleRule?.badge?.enabled ?? false) && (segmentItem.styleRule?.badge?.target ?? "icon") === "segment"
                        readonly property string badgePos: segmentItem.styleRule?.badge?.position ?? "top-right"
                        readonly property real badgeDotSize: Math.max(2, (segmentItem.styleRule?.badge?.size ?? 6)) * Style.uiScaleRatio
                        readonly property color badgeDotColor: {
                            if (!active)
                                return "transparent";
                            return root.colorWithOpacity(root.resolveColor(segmentItem.styleRule.badge.color?.color ?? "error", Color.mError), root.normalizeOpacityValue(segmentItem.styleRule.badge.color?.opacity ?? 1, 1));
                        }

                        visible: active
                        width: badgeDotSize
                        height: badgeDotSize
                        radius: width / 2
                        color: badgeDotColor
                        z: 5
                        anchors.top: parent.top
                        anchors.topMargin: root.windowMargin
                        anchors.left: badgePos === "top-left" ? parent.left : undefined
                        anchors.leftMargin: badgePos === "top-left" ? root.windowMargin : 0
                        anchors.right: badgePos === "top-right" ? parent.right : undefined
                        anchors.rightMargin: badgePos === "top-right" ? root.windowMargin : 0
                    }

                    RowLayout {
                        parent: lifecycleWrapper
                        anchors.fill: parent
                        anchors.margins: root.windowMargin
                        anchors.leftMargin: root.windowMargin + root.windowPaddingLeft
                        anchors.rightMargin: root.windowMargin + root.windowPaddingRight
                        anchors.topMargin: root.windowMargin + root.windowPaddingTop
                        anchors.bottomMargin: root.windowMargin + root.windowPaddingBottom
                        spacing: root.labelGap
                        visible: root.showIcon || root.showTitle
                        layoutDirection: root.focusedOnly && root.focusedAlign === "right" && segmentItem.showLabel ? Qt.RightToLeft : Qt.LeftToRight
                        z: 10

                        NIcon {
                            readonly property bool active: (segmentItem.styleRule?.iconPrefix?.enabled ?? false) && (segmentItem.styleRule?.iconPrefix?.target ?? "icon") === "icon"
                            readonly property color prefixColor: {
                                if (!active)
                                    return Color.mOnSurfaceVariant;
                                return root.colorWithOpacity(root.resolveColor(segmentItem.styleRule.iconPrefix.color?.color ?? "on-surface-variant", Color.mOnSurfaceVariant), root.normalizeOpacityValue(segmentItem.styleRule.iconPrefix.color?.opacity ?? 1, 1));
                            }

                            visible: active && root.showIcon
                            icon: active ? String(segmentItem.styleRule.iconPrefix.icon || "") : ""
                            pointSize: root.computedIconSize * 0.6
                            color: prefixColor
                            Layout.preferredWidth: root.computedIconSize * 0.6
                            Layout.preferredHeight: root.computedIconSize * 0.6
                            Layout.alignment: Qt.AlignVCenter
                            opacity: segmentItem.showLabel ? 1 : 0

                            Behavior on opacity {
                                enabled: root.animationEnabled
                                NumberAnimation {
                                    duration: root.animationSpeed
                                }
                            }

                            Behavior on color {
                                enabled: root.animationEnabled
                                ColorAnimation {
                                    duration: root.animationSpeed
                                }
                            }
                        }

                        Item {
                            id: iconContainer
                            Layout.preferredWidth: root.showIcon ? (root.showTitle ? root.computedIconSize : Math.max(root.computedIconSize, segmentItem.width - (root.windowMargin * 2) - root.windowPaddingLeft - root.windowPaddingRight)) : 0
                            Layout.preferredHeight: root.showIcon ? root.computedIconSize : 0
                            Layout.alignment: Qt.AlignVCenter
                            visible: root.showIcon
                            opacity: segmentItem.showLabel ? 1 : 0

                            Behavior on opacity {
                                enabled: root.animationEnabled
                                NumberAnimation {
                                    duration: root.animationSpeed
                                }
                            }

                            IconImage {
                                id: appIcon
                                width: root.computedIconSize
                                height: root.computedIconSize
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.horizontalCenterOffset: Math.round((parent.width - width) * (root.iconAnchor(root.iconAlign) - 0.5))
                                source: ThemeIcons.iconForAppId(root.entryAppId(segmentItem.entryKey))
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready && customRuleIcon.visible === false

                                layer.enabled: visible && root.iconTintEnabled(segmentItem.entryKey)
                                layer.effect: ShaderEffect {
                                    property color targetColor: root.labelColor(segmentItem.entryKey, "icon")
                                    property real colorizeMode: 0.0

                                    fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                                }
                                opacity: {
                                    const state = root.segmentState(segmentItem.entryKey);
                                    if (state === "focused")
                                        return root.iconColorFocusedOpacity;
                                    if (state === "hover")
                                        return root.iconColorHoverOpacity;
                                    return root.iconColorDefaultOpacity;
                                }
                            }

                            NIcon {
                                id: customRuleIcon
                                width: root.computedIconSize
                                height: root.computedIconSize
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.horizontalCenterOffset: Math.round((parent.width - width) * (root.iconAnchor(root.iconAlign) - 0.5))
                                icon: root.customRuleIconName(segmentItem.entryKey)
                                pointSize: root.computedIconSize
                                visible: icon !== ""
                                color: root.labelColor(segmentItem.entryKey, "icon")

                                Behavior on color {
                                    enabled: root.animationEnabled
                                    ColorAnimation {
                                        duration: root.animationSpeed
                                    }
                                }
                            }

                            NText {
                                width: root.computedIconSize
                                horizontalAlignment: root.horizontalAlignment(root.iconAlign)
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.horizontalCenterOffset: Math.round((parent.width - width) * (root.iconAnchor(root.iconAlign) - 0.5))
                                visible: !appIcon.visible && !customRuleIcon.visible
                                text: segmentItem.title.length > 0 ? segmentItem.title.charAt(0).toUpperCase() : "?"
                                pointSize: Math.max(Style.fontSizeXS, root.titleFontSize * root.titleScale * 0.95)
                                font.weight: Style.fontWeightBold
                                color: root.labelColor(segmentItem.entryKey, "icon")

                                Behavior on color {
                                    enabled: root.animationEnabled
                                    ColorAnimation {
                                        duration: root.animationSpeed
                                    }
                                }
                            }

                            Rectangle {
                                readonly property bool active: (segmentItem.styleRule?.badge?.enabled ?? false) && (segmentItem.styleRule?.badge?.target ?? "icon") === "icon"
                                readonly property string badgePos: segmentItem.styleRule?.badge?.position ?? "top-right"
                                readonly property real badgeDotSize: Math.max(2, (segmentItem.styleRule?.badge?.size ?? 6)) * Style.uiScaleRatio
                                readonly property color badgeDotColor: {
                                    if (!active)
                                        return "transparent";
                                    return root.colorWithOpacity(root.resolveColor(segmentItem.styleRule.badge.color?.color ?? "error", Color.mError), root.normalizeOpacityValue(segmentItem.styleRule.badge.color?.opacity ?? 1, 1));
                                }

                                visible: active
                                width: badgeDotSize
                                height: badgeDotSize
                                radius: width / 2
                                color: badgeDotColor
                                z: 5
                                anchors.top: parent.top
                                anchors.left: badgePos === "top-left" ? parent.left : undefined
                                anchors.right: badgePos === "top-right" ? parent.right : undefined
                            }
                        }

                        NIcon {
                            readonly property bool active: (segmentItem.styleRule?.iconPrefix?.enabled ?? false) && (segmentItem.styleRule?.iconPrefix?.target ?? "icon") === "title"
                            readonly property color prefixColor: {
                                if (!active)
                                    return Color.mOnSurfaceVariant;
                                return root.colorWithOpacity(root.resolveColor(segmentItem.styleRule.iconPrefix.color?.color ?? "on-surface-variant", Color.mOnSurfaceVariant), root.normalizeOpacityValue(segmentItem.styleRule.iconPrefix.color?.opacity ?? 1, 1));
                            }

                            visible: active && root.showTitle
                            icon: active ? String(segmentItem.styleRule.iconPrefix.icon || "") : ""
                            pointSize: root.titleFontSize * root.titleScale * 0.85
                            color: prefixColor
                            Layout.preferredWidth: root.titleFontSize * root.titleScale * 0.85
                            Layout.preferredHeight: root.titleFontSize * root.titleScale * 0.85
                            Layout.alignment: Qt.AlignVCenter
                            opacity: segmentItem.showLabel ? 1 : 0

                            Behavior on opacity {
                                enabled: root.animationEnabled
                                NumberAnimation {
                                    duration: root.animationSpeed
                                }
                            }

                            Behavior on color {
                                enabled: root.animationEnabled
                                ColorAnimation {
                                    duration: root.animationSpeed
                                }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: titleText.implicitHeight
                            Layout.alignment: Qt.AlignVCenter
                            visible: root.showTitle

                            NText {
                                id: titleText
                                anchors.fill: parent
                                text: segmentItem.title
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                opacity: segmentItem.showLabel ? 1 : 0
                                color: root.labelColor(segmentItem.entryKey, "title")
                                horizontalAlignment: root.horizontalAlignment(root.titleAlign)
                                font.family: root.titleFontFamily || Qt.application.font.family
                                pointSize: root.titleFontSize * root.titleScale
                                font.weight: root.titleWeight(segmentItem.entryKey)

                                Behavior on color {
                                    enabled: root.animationEnabled
                                    ColorAnimation {
                                        duration: root.animationSpeed
                                    }
                                }

                                Behavior on opacity {
                                    enabled: root.animationEnabled
                                    NumberAnimation {
                                        duration: root.animationSpeed
                                    }
                                }
                            }

                            Rectangle {
                                readonly property bool active: (segmentItem.styleRule?.badge?.enabled ?? false) && (segmentItem.styleRule?.badge?.target ?? "icon") === "title"
                                readonly property string badgePos: segmentItem.styleRule?.badge?.position ?? "top-right"
                                readonly property real badgeDotSize: Math.max(2, (segmentItem.styleRule?.badge?.size ?? 6)) * Style.uiScaleRatio
                                readonly property color badgeDotColor: {
                                    if (!active)
                                        return "transparent";
                                    return root.colorWithOpacity(root.resolveColor(segmentItem.styleRule.badge.color?.color ?? "error", Color.mError), root.normalizeOpacityValue(segmentItem.styleRule.badge.color?.opacity ?? 1, 1));
                                }

                                visible: active
                                width: badgeDotSize
                                height: badgeDotSize
                                radius: width / 2
                                color: badgeDotColor
                                z: 5
                                anchors.top: parent.top
                                anchors.left: badgePos === "top-left" ? parent.left : undefined
                                anchors.right: badgePos === "top-right" ? parent.right : undefined
                            }
                        }
                    }

                    onXChanged: syncSnapshot()
                    onYChanged: syncSnapshot()
                    onLifecycleOpacityChanged: syncSnapshot()
                    onLifecycleScaleChanged: syncSnapshot()
                    Component.onCompleted: {
                        syncSnapshot();
                        enterAnimationDelay.start();
                    }
                }

                onXChanged: draggableContent.syncSnapshot()
                onYChanged: draggableContent.syncSnapshot()
                onWidthChanged: draggableContent.syncSnapshot()
                onHeightChanged: draggableContent.syncSnapshot()
                onTitleChanged: draggableContent.syncSnapshot()
                onShowLabelChanged: draggableContent.syncSnapshot()

                MouseArea {
                    id: segmentMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: segmentItem.reorderable ? (drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor) : Qt.PointingHandCursor
                    preventStealing: true
                    drag.target: segmentItem.reorderable ? draggableContent : undefined
                    drag.axis: Drag.XAxis

                    onEntered: {
                        root.hoveredEntryKey = segmentItem.entryKey;
                        if (segmentItem.title)
                            TooltipService.show(segmentItem, segmentItem.title, BarService.getTooltipDirection(root.screen?.name));
                    }

                    onExited: {
                        if (root.hoveredEntryKey === segmentItem.entryKey)
                            root.hoveredEntryKey = "";
                        TooltipService.hide();
                    }

                    onReleased: mouse => {
                        if (segmentItem.reorderable && root.dragSessionActive && root.dragSourceEntryKey === segmentItem.entryKey) {
                            Logger.d("Scrollbar2", "Drag release requesting drop: source=" + segmentItem.entryKey + " raw=" + root.dragInsertIndex);
                            root.finalizeDragReorder(segmentItem.entryKey, "release");
                            return;
                        }
                        if (mouse.button === Qt.MiddleButton && root.middleClickCloseEnabled) {
                            root.mainInstance?.closeEntry(segmentItem.entryKey);
                        } else if (mouse.button === Qt.RightButton) {
                            TooltipService.hide();
                            root.openContextMenu(segmentItem, root.entryRecord(segmentItem.entryKey));
                        } else if (mouse.button === Qt.LeftButton) {
                            root.mainInstance?.focusEntry(segmentItem.entryKey);
                        }
                    }
                }
            }
        }
    }

    DropArea {
        parent: trackContentLayer
        x: segmentsRow.x
        y: segmentsRow.y
        width: segmentsRow.width
        height: segmentsRow.height
        keys: ["scrollbar2-window"]
        enabled: root.dragReorderEnabled
        z: 2

        onEntered: drag => {
            if (!drag.source || drag.source.objectName !== "scrollbar2WindowSegment")
                return;
            root.dragInsertIndex = root.dragSourceIndex;
            Logger.d("Scrollbar2", "Drag overlay entered: source=" + (drag.source.entryKey ?? "") + " sourceIndex=" + root.dragSourceIndex);
        }

        onPositionChanged: drag => {
            if (!drag.source || drag.source.objectName !== "scrollbar2WindowSegment")
                return;
        }

        onExited: {
            if (!root.dragSessionActive)
                return;
            Logger.d("Scrollbar2", "Drag preview cleared: source=" + root.dragSourceEntryKey + " raw=" + root.dragInsertIndex + " reason=overlay-exit");
            root.clearDragState();
        }

        onDropped: drop => {
            const sourceEntryKey = drop.source?.entryKey ?? "";
            Logger.d("Scrollbar2", "Drag drop signal: source=" + sourceEntryKey + " raw=" + root.dragInsertIndex);
            root.finalizeDragReorder(sourceEntryKey, "drop");
        }
    }

    Item {
        parent: trackContentLayer
        x: segmentsRow.x
        y: segmentsRow.y
        width: segmentsRow.width
        height: segmentsRow.height
        z: 3
        visible: root.dragReorderEnabled && root.segmentCount > 1

        Repeater {
            model: root.segmentCount + 1

            delegate: DropArea {
                required property int index

                x: root.insertionZoneStart(index)
                y: 0
                width: root.insertionZoneWidth(index)
                height: parent ? parent.height : 0
                keys: ["scrollbar2-window"]
                enabled: root.dragReorderEnabled

                onEntered: drag => {
                    if (!drag.source || drag.source.objectName !== "scrollbar2WindowSegment")
                        return;
                    root.setDragInsertIndex(index, drag.source.entryKey ?? "", "slot-enter");
                }

                onPositionChanged: drag => {
                    if (!drag.source || drag.source.objectName !== "scrollbar2WindowSegment")
                        return;
                }
            }
        }
    }

    MouseArea {
        parent: trackContentLayer
        x: segmentsRow.x
        y: segmentsRow.y
        width: segmentsRow.width
        height: segmentsRow.height
        z: 1
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (!root.scrollWheelFocusEnabled || root.segmentCount === 0)
                return;

            const currentIndex = root.focusedIndex;
            let nextIndex;

            if (wheel.angleDelta.y > 0) {
                // Scroll up - focus previous
                nextIndex = currentIndex <= 0 ? root.segmentCount - 1 : currentIndex - 1;
            } else {
                // Scroll down - focus next
                nextIndex = (currentIndex + 1) % root.segmentCount;
            }

            if (nextIndex >= 0 && nextIndex < root.segmentCount) {
                root.mainInstance?.focusEntry(root.entries[nextIndex]);
                wheel.accepted = true;
            }
        }
    }

    Rectangle {
        id: dragInsertMarker
        parent: trackContentLayer
        visible: root.dragPreviewActive
        x: root.insertionMarkerCenter(root.dragInsertIndex) - (width / 2)
        y: Math.max(0, Math.round((root.availableContainerHeight - height) / 2))
        width: Math.max(2, Math.round(Math.max(root.visibleFocusLineThickness, 3 * Style.uiScaleRatio)))
        height: Math.max(root.visibleFocusLineThickness, Math.round(root.availableContainerHeight * 0.72))
        radius: width / 2
        color: root.colorWithOpacity(root.focusLineIndicatorColor, Math.max(root.focusLineOpacity, root.focusLineIndicatorOpacity))
        z: 24
        opacity: root.dragPreviewActive ? 1 : 0
        scale: root.dragPreviewActive ? 1 : 0.85

        Behavior on x {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.focusLineEasingType()
                easing.overshoot: root.focusLineOvershoot()
            }
        }

        Behavior on opacity {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
            }
        }

        Behavior on scale {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
            }
        }
    }

    Rectangle {
        id: trackLine
        x: root.leftAccessoryWidth
        y: trackLineY()
        width: root.effectiveTrackWidth
        height: visibleTrackThickness
        radius: Math.min(trackBorderRadius, height / 2)
        color: Qt.alpha(trackColor, trackOpacity)
        visible: root.segmentCount > 0 || root.showSpecialWorkspaceOverlay
        z: 10
    }

    Item {
        id: trackContentLayer
        x: root.leftAccessoryWidth
        y: 0
        width: root.effectiveTrackWidth
        height: root.availableContainerHeight
        z: 11
        visible: root.segmentCount > 0 || root.showSpecialWorkspaceOverlay

        readonly property real fadeStop: root.trackEdgeFadeActive ? Math.max(0, Math.min(0.5, root.effectiveTrackEdgeFadeWidth / Math.max(1, width))) : 0

        layer.enabled: root.trackEdgeFadeActive && width > 0 && height > 0
        layer.effect: MultiEffect {
            maskEnabled: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            maskSource: trackEdgeFadeMask
        }
    }

    SpecialWorkspaceOverlay {
        id: specialWorkspaceOverlay
        parent: trackContentLayer
        view: root
    }

    ClosingSegmentsLayer {
        id: closingSegmentsLayer
        parent: trackContentLayer
        view: root
    }

    TrackSeparators {
        id: trackSeparators
        parent: trackContentLayer
        view: root
        trackLine: trackLine
    }

    NDropShadow {
        anchors.fill: trackLine
        source: trackLine
        autoPaddingEnabled: true
        visible: trackShadowEnabled && trackLine.visible
        z: 9
    }

    FocusIndicator {
        id: focusIndicator
        parent: trackContentLayer
        view: root
    }

    Item {
        parent: trackContentLayer
        x: 0
        y: 0
        width: root.actualTrackWidth
        height: root.availableContainerHeight
        z: 10
        visible: root.focusedOnly && root.focusedAlign === "center" && root.focusedEntry() !== null

        RowLayout {
            anchors.centerIn: parent
            spacing: root.labelGap

            Item {
                Layout.preferredWidth: root.showIcon ? root.computedIconSize : 0
                Layout.preferredHeight: root.showIcon ? root.computedIconSize : 0
                visible: root.showIcon

                IconImage {
                    id: centeredIcon
                    anchors.fill: parent
                    source: ThemeIcons.iconForAppId(root.entryAppId(root.focusedEntryKey()))
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: visible && root.iconColorFocusedKey !== "none"
                    layer.effect: ShaderEffect {
                        property color targetColor: root.iconColorFocused
                        property real colorizeMode: 0.0

                        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                    opacity: root.iconColorFocusedOpacity
                }

                NText {
                    anchors.centerIn: parent
                    visible: !centeredIcon.visible
                    text: root.currentTitle(root.focusedEntryKey()).length > 0 ? root.currentTitle(root.focusedEntryKey()).charAt(0).toUpperCase() : "?"
                    pointSize: Math.max(Style.fontSizeXS, root.titleFontSize * root.titleScale * 0.95)
                    font.weight: Style.fontWeightBold
                    color: Qt.alpha(root.iconColorFocused, root.iconColorFocusedOpacity)
                }
            }

            NText {
                visible: root.showTitle
                text: root.currentTitle(root.focusedEntryKey())
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Qt.alpha(root.titleColorFocused, root.titleColorFocusedOpacity)
                font.family: root.titleFontFamily || Qt.application.font.family
                pointSize: root.titleFontSize * root.titleScale
                font.weight: root.fontWeightValue(root.titleWeightFocused, Style.fontWeightSemiBold)
            }
        }
    }

    Rectangle {
        id: trackEdgeFadeMask
        parent: trackContentLayer
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0.0
                color: root.trackEdgeFadeLeftEnabled ? "transparent" : "white"
            }
            GradientStop {
                position: trackContentLayer.fadeStop
                color: "white"
            }
            GradientStop {
                position: 1 - trackContentLayer.fadeStop
                color: "white"
            }
            GradientStop {
                position: 1.0
                color: root.trackEdgeFadeRightEnabled ? "transparent" : "white"
            }
        }
        layer.enabled: true
        layer.smooth: true
        opacity: 0
    }

    ScrollbarContextMenu {
        id: contextMenu
        model: root.contextMenuModel

        onTriggered: function (action, item) {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);

            if (action === "focus") {
                root.mainInstance?.focusEntry(root.selectedEntryKey);
            } else if (action === "close") {
                root.mainInstance?.closeEntry(root.selectedEntryKey);
            } else if (action === "pin") {
                root.mainInstance?.toggleAppPin(root.selectedAppId);
            } else if (action === "unpin") {
                root.mainInstance?.removePinnedApp(root.selectedAppId);
            } else if (action === "custom-style-rule") {
                // First, open settings to ensure Settings.qml is loaded
                BarService.openPluginSettings(root.screen, pluginApi.manifest);

                // Then trigger navigation (this will be caught by Settings.qml)
                // Prefer appId over title for the default rule
                const existingAppRuleIndex = root.mainInstance?.findPrefilledStyleRuleIndex(root.selectedEntryKey, "appId") ?? -1;
                const existingTitleRuleIndex = root.mainInstance?.findPrefilledStyleRuleIndex(root.selectedEntryKey, "title") ?? -1;

                // Use appId rule if it exists or if neither exists, otherwise use title rule
                const useAppId = existingAppRuleIndex >= 0 || (existingTitleRuleIndex < 0 && existingAppRuleIndex < 0);
                const matchField = useAppId ? "appId" : "title";

                const existingRuleIndex = useAppId ? existingAppRuleIndex : existingTitleRuleIndex;

                if (existingRuleIndex < 0) {
                    // No existing rule, create one
                    const rule = root.mainInstance?.buildPrefilledStyleRule(root.selectedEntryKey, matchField);
                    if (rule)
                        root.mainInstance?.appendStyleRule(rule, true);
                }

                // Request navigation to the rule
                root.mainInstance?.requestPrefilledStyleRuleEdit(root.selectedEntryKey, matchField);
            } else if (action === "settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            } else if (action.startsWith("desktop-action-") && item?.desktopAction) {
                if (item.desktopAction.command && item.desktopAction.command.length > 0) {
                    Quickshell.execDetached(item.desktopAction.command);
                } else if (item.desktopAction.execute) {
                    item.desktopAction.execute();
                }
            }

            root.clearContextSelection();
        }
    }

    Connections {
        target: mainInstance

        function onEntryModelRevisionChanged() {
            root.refreshEntriesCache();
            root.refreshPinnedEntriesCache();
            root.hoveredEntryKey = "";
            root.hoveredPinnedAppId = "";
        }

        function onEntryStateRevisionChanged() {
            root.refreshEntriesCache();
            root.refreshPinnedEntriesCache();
        }

        function onWorkspaceRevisionChanged() {
            root.refreshEntriesCache();
            root.refreshPinnedEntriesCache();
        }

        function onCurrentSettingsChanged() {
            root.refreshPinnedEntriesCache();
        }
    }

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.invalidStyleRulePatterns = ({});
        }
    }
}
