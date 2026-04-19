import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets

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
        const numericValue = Number(value);
        if (isNaN(numericValue))
            return fallbackValue;
        if (numericValue > 1)
            return Math.max(0, Math.min(1, numericValue / 100));
        return Math.max(0, Math.min(1, numericValue));
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
            "enabled": currentValue.enabled !== false,
            "color": String(currentValue.color ?? fallbackColor),
            "opacity": normalizeOpacityValue(currentValue.opacity, fallbackOpacity)
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
            }
        };
    }

    function styleRuleItems() {
        const configuredRules = currentSettings?.customStyleRules;
        const source = Array.isArray(configuredRules) ? configuredRules : (Array.isArray(defaults?.customStyleRules) ? defaults.customStyleRules : []);
        return source.map(normalizeStyleRule);
    }

    function ruleMatchSubject(entry, matchField) {
        if (!entry)
            return "";
        if (matchField === "title")
            return currentTitle(entry);
        return String(mainInstance?.resolveToDesktopEntryId(entry?.appId || "") || entry?.appId || "");
    }

    function matchingStyleRule(entry) {
        const rules = styleRuleItems();
        for (let index = 0; index < rules.length; index++) {
            const rule = rules[index];
            const pattern = String(rule?.pattern || "").trim();
            if (!rule?.enabled || pattern === "")
                continue;

            const subject = ruleMatchSubject(entry, rule.matchField);
            if (subject === "")
                continue;

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
        const entry = entries.find(function (candidate) {
            return candidate?.entryKey === entryKey;
        }) || null;
        const matchingRule = matchingStyleRule(entry);
        if (!matchingRule)
            return null;
        return matchingRule.colors?.[groupKey]?.[stateKey] ?? null;
    }

    function resolvedSegmentStyle(entryKey) {
        const state = segmentState(entryKey);
        const overrideState = styleRuleStateValue(entryKey, "segment", state);
        if (overrideState) {
            if (overrideState.enabled === false)
                return "transparent";
            const overrideColor = resolveColor(overrideState.color, state === "focused" ? focusLineFocusedColor : (state === "hover" ? focusLineHoverColor : focusLineDefaultColor));
            return colorWithOpacity(overrideColor, focusLineOpacity * overrideState.opacity);
        }
        return null;
    }

    function customStyleRuleForEntry(entryKey) {
        const entry = entries.find(function (candidate) {
            return candidate?.entryKey === entryKey;
        }) || null;
        return matchingStyleRule(entry);
    }

    function customRuleIconName(entryKey) {
        const matchingRule = customStyleRuleForEntry(entryKey);
        return String(matchingRule?.customIcon || "");
    }

    function resolvedLabelState(entryKey, kind) {
        const state = segmentState(entryKey);
        const fallbackKey = kind === "icon"
            ? (state === "focused" ? iconColorFocusedKey : (state === "hover" ? iconColorHoverKey : iconColorDefaultKey))
            : (state === "focused" ? titleColorFocusedKey : (state === "hover" ? titleColorHoverKey : titleColorDefaultKey));
        const fallbackOpacity = kind === "icon"
            ? (state === "focused" ? iconColorFocusedOpacity : (state === "hover" ? iconColorHoverOpacity : iconColorDefaultOpacity))
            : (state === "focused" ? titleColorFocusedOpacity : (state === "hover" ? titleColorHoverOpacity : titleColorDefaultOpacity));
        const fallbackColor = kind === "icon"
            ? (state === "focused" ? iconColorFocused : (state === "hover" ? iconColorHover : iconColorDefault))
            : (state === "focused" ? titleColorFocused : (state === "hover" ? titleColorHover : titleColorDefault));
        const overrideState = styleRuleStateValue(entryKey, kind, state);
        const effectiveKey = String(overrideState?.color ?? fallbackKey);
        const effectiveOpacity = overrideState ? overrideState.opacity : fallbackOpacity;
        const effectiveColor = overrideState ? resolveColor(effectiveKey, fallbackColor) : fallbackColor;
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
    readonly property bool focusedOnly: settingValue("window", "focusedOnly", false)
    readonly property string focusedAlign: settingValue("window", "focusedAlign", "segment")
    readonly property real windowBorderRadius: Math.max(0, settingValue("window", "borderRadius", 6) * Style.uiScaleRatio)
    readonly property real windowMargin: Math.max(0, settingValue("window", "margin", 2) * Style.uiScaleRatio)
    readonly property real windowPaddingLeft: Math.max(0, settingValue("window", "paddingLeft", 7) * Style.uiScaleRatio)
    readonly property real windowPaddingRight: Math.max(0, settingValue("window", "paddingRight", 7) * Style.uiScaleRatio)
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
    readonly property string pinnedAppsPosition: settingValue("pinnedApps", "position", "left")
    readonly property string pinnedAppsIconColorKey: settingValue("pinnedApps", "iconColor", "on-surface")
    readonly property color pinnedAppsIconColor: resolveColor(pinnedAppsIconColorKey, Color.mOnSurface)
    readonly property real pinnedAppsMarginLeft: Math.max(0, settingValue("pinnedApps", "marginLeft", 8) * Style.uiScaleRatio)
    readonly property real pinnedAppsMarginRight: Math.max(0, settingValue("pinnedApps", "marginRight", 8) * Style.uiScaleRatio)
    readonly property bool pinnedAppsHideWhenActive: settingValue("pinnedApps", "hideWhenActive", false)
    readonly property string pinnedAppsActivateRunningBehavior: settingValue("pinnedApps", "activateRunningBehavior", "focusCycle")

    readonly property int revisionToken: (mainInstance?.structureRevision ?? 0) + (mainInstance?.liveRevision ?? 0) + (mainInstance?.titleRevision ?? 0) + (mainInstance?.workspaceRevision ?? 0) + (mainInstance?.activeSpecialRevision ?? 0)
    readonly property var entries: {
        revisionToken;
        if (!mainInstance)
            return [];
        return mainInstance.getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces) || [];
    }
    readonly property var pinnedEntries: {
        revisionToken;
        if (!mainInstance)
            return [];
        const source = mainInstance.getVisiblePinnedApps(screenName, onlySameOutput, onlyActiveWorkspaces) || [];
        return source.filter(function (item) {
            return !(pinnedAppsHideWhenActive && item?.hasVisibleWindows);
        });
    }
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
        const windowContentHeight = computedLabelHeight + horizontalPadding * 2;
        return Math.max(trackThickness, focusLineThickness, windowContentHeight);
    }
    readonly property real availableContainerHeight: Math.max(1, root.height > 0 ? root.height : (hostMode === "bar" ? Style.getCapsuleHeightForScreen(screenName) : computedContentHeight))
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
        if (!mainInstance?.activeEntryKey)
            return -1;
        for (let i = 0; i < entries.length; i++) {
            if (entries[i]?.entryKey === mainInstance.activeEntryKey)
                return i;
        }
        return -1;
    }

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

    function specialWorkspaceOverlayEasingType() {
        switch (animationType) {
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

    function specialWorkspaceOverlayOvershoot() {
        return animationType === "spring" ? 1.08 : 0;
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

        if (displayedSpecialWorkspaceText === nextText && JSON.stringify(displayedSpecialWorkspaceIcons) === JSON.stringify(nextIcons))
            return;

        if (!animationEnabled || animationSpeed <= 0) {
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

    function currentSpecialWorkspaceOverlayIcons() {
        if (!specialWorkspaceOverlayShowWindowIcons || !activeSpecialWorkspace)
            return [];
        const icons = mainInstance?.getWorkspaceWindowAppIds(screenName, activeSpecialWorkspace.id, activeSpecialWorkspace.name) || [];
        return Array.isArray(icons) ? icons.slice() : [];
    }

    onWorkspaceIndicatorTextChanged: updateWorkspaceIndicatorPresentation()
    onWorkspaceIndicatorBadgeCountChanged: updateWorkspaceIndicatorPresentation()
    onSpecialWorkspaceOverlayLabelTextChanged: updateSpecialWorkspaceOverlayPresentation()
    onRevisionTokenChanged: updateSpecialWorkspaceOverlayPresentation()
    Component.onCompleted: {
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
        return entries[focusedIndex];
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
        if (!entry)
            return "";
        if (mainInstance?.titleEntriesByKey && mainInstance.titleEntriesByKey[entry.entryKey] !== undefined)
            return mainInstance.titleEntriesByKey[entry.entryKey];
        return entry.fallbackTitle || "";
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
            const desktopActions = mainInstance?.desktopEntryActionsForApp(selectedAppId) || [];
            desktopActions.forEach(function (item) {
                model.push(item);
            });
            if (selectedAppId) {
                const appPinned = mainInstance?.isAppPinned(selectedAppId) ?? false;
                const hasExistingAppStyleRule = (mainInstance?.findPrefilledStyleRuleIndex(selectedEntryKey, "appId") ?? -1) >= 0;
                model.push({
                    "label": pluginApi?.tr(appPinned ? "menu.unpinFromBar" : "menu.pinToBar"),
                    "action": appPinned ? "unpin" : "pin",
                    "icon": appPinned ? "unpin" : "pin"
                });
                model.push({
                    "label": pluginApi?.tr(hasExistingAppStyleRule ? "menu.editStyleRuleForApp" : "menu.addStyleRuleForApp"),
                    "action": "style-rule-app",
                    "icon": "brush"
                });
            }
            const hasExistingTitleStyleRule = (mainInstance?.findPrefilledStyleRuleIndex(selectedEntryKey, "title") ?? -1) >= 0;
            model.push({
                "label": pluginApi?.tr(hasExistingTitleStyleRule ? "menu.editStyleRuleForTitle" : "menu.addStyleRuleForTitle"),
                "action": "style-rule-title",
                "icon": "typography"
            });
        } else if (pinnedApp) {
            clearContextSelection();
            selectedAppId = pinnedApp.appId ?? "";
            model.push({
                "label": pluginApi?.tr("menu.unpinFromBar"),
                "action": "unpin",
                "icon": "unpin"
            });
        } else {
            clearContextSelection();
        }

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
        duration: root.animationSpeed
        easing.type: root.specialWorkspaceOverlayEasingType()
        easing.overshoot: root.specialWorkspaceOverlayOvershoot()
        onStopped: {
            if (root.specialWorkspaceOverlayTransitionProgress >= 1) {
                root.outgoingSpecialWorkspaceText = "";
                root.outgoingSpecialWorkspaceIcons = [];
            }
        }
    }

    Item {
        id: workspaceContainer
        visible: root.showWorkspaceIndicator
        x: {
            if (root.workspaceIndicatorPosition === "left")
                return (root.pinnedSegmentCount > 0 && root.pinnedAppsPosition === "left" ? root.pinnedAreaWidth : 0) + root.workspaceIndicatorMarginLeft;
            return root.leftAccessoryWidth + root.actualTrackWidth + root.workspaceIndicatorMarginLeft;
        }
        y: root.workspaceIndicatorAlignedY()
        width: workspaceBackground.width
        height: workspaceBackground.height
        z: 30

        Rectangle {
            id: workspaceBackground
            width: Math.max(incomingIndicator.implicitWidth, outgoingIndicator.implicitWidth) + root.workspaceIndicatorPaddingX * 2
            height: Math.max(incomingIndicator.implicitHeight, outgoingIndicator.implicitHeight) + root.workspaceIndicatorPaddingY * 2
            radius: Math.min(root.workspaceIndicatorBorderRadius, Math.min(width, height) / 2)
            color: Qt.alpha(root.workspaceIndicatorBackgroundColor, root.workspaceIndicatorBackgroundOpacity)

            Item {
                anchors.fill: parent
                clip: true

                RowLayout {
                    id: outgoingIndicator
                    anchors.centerIn: parent
                    spacing: Math.max(4, Math.round(4 * Style.uiScaleRatio))
                    visible: root.outgoingWorkspaceText !== "" && root.workspaceIndicatorTransitionProgress < 1
                    opacity: 1 - root.workspaceIndicatorTransitionProgress
                    x: root.workspaceIndicatorAnimationAxis === "horizontal" ? Math.round((-root.workspaceIndicatorPaddingX * 1.5) * root.workspaceIndicatorTransitionProgress) : 0
                    y: root.workspaceIndicatorAnimationAxis === "vertical" ? Math.round((-root.workspaceIndicatorPaddingY * 2) * root.workspaceIndicatorTransitionProgress) : 0

                    NText {
                        text: root.outgoingWorkspaceText
                        color: Qt.alpha(root.workspaceIndicatorTextColor, root.workspaceIndicatorTextOpacity)
                        font.family: root.workspaceIndicatorFontFamily || Qt.application.font.family
                        font.weight: root.fontWeightValue(root.workspaceIndicatorFontWeightKey, Style.fontWeightMedium)
                        pointSize: root.workspaceIndicatorFontSize
                    }

                    Rectangle {
                        visible: root.workspaceIndicatorBadgeEnabled
                        radius: Math.min(height / 2, Math.round(999 * Style.uiScaleRatio))
                        color: Qt.alpha(root.workspaceIndicatorBadgeBackgroundColor, root.workspaceIndicatorBadgeBackgroundOpacity)
                        implicitWidth: badgeOutgoingText.implicitWidth + root.workspaceIndicatorPaddingX
                        implicitHeight: badgeOutgoingText.implicitHeight + root.workspaceIndicatorPaddingY

                        NText {
                            id: badgeOutgoingText
                            anchors.centerIn: parent
                            text: String(root.outgoingWorkspaceBadgeCount)
                            color: Qt.alpha(root.workspaceIndicatorBadgeTextColor, root.workspaceIndicatorBadgeTextOpacity)
                            font.family: root.workspaceIndicatorBadgeFontFamily || Qt.application.font.family
                            font.weight: root.fontWeightValue(root.workspaceIndicatorBadgeFontWeightKey, Style.fontWeightSemiBold)
                            pointSize: root.workspaceIndicatorBadgeFontSize
                        }
                    }
                }

                RowLayout {
                    id: incomingIndicator
                    anchors.centerIn: parent
                    spacing: Math.max(4, Math.round(4 * Style.uiScaleRatio))
                    opacity: root.workspaceIndicatorAnimationEnabled ? root.workspaceIndicatorTransitionProgress : 1
                    x: root.workspaceIndicatorAnimationAxis === "horizontal" ? Math.round((1 - root.workspaceIndicatorTransitionProgress) * root.workspaceIndicatorPaddingX * 1.5) : 0
                    y: root.workspaceIndicatorAnimationAxis === "vertical" ? Math.round((1 - root.workspaceIndicatorTransitionProgress) * root.workspaceIndicatorPaddingY * 2) : 0

                    NText {
                        text: root.displayedWorkspaceText
                        color: Qt.alpha(root.workspaceIndicatorTextColor, root.workspaceIndicatorTextOpacity)
                        font.family: root.workspaceIndicatorFontFamily || Qt.application.font.family
                        font.weight: root.fontWeightValue(root.workspaceIndicatorFontWeightKey, Style.fontWeightMedium)
                        pointSize: root.workspaceIndicatorFontSize
                    }

                    Rectangle {
                        visible: root.workspaceIndicatorBadgeEnabled
                        radius: Math.min(height / 2, Math.round(999 * Style.uiScaleRatio))
                        color: Qt.alpha(root.workspaceIndicatorBadgeBackgroundColor, root.workspaceIndicatorBadgeBackgroundOpacity)
                        implicitWidth: badgeIncomingText.implicitWidth + root.workspaceIndicatorPaddingX
                        implicitHeight: badgeIncomingText.implicitHeight + root.workspaceIndicatorPaddingY

                        NText {
                            id: badgeIncomingText
                            anchors.centerIn: parent
                            text: String(root.displayedWorkspaceBadgeCount)
                            color: Qt.alpha(root.workspaceIndicatorBadgeTextColor, root.workspaceIndicatorBadgeTextOpacity)
                            font.family: root.workspaceIndicatorBadgeFontFamily || Qt.application.font.family
                            font.weight: root.fontWeightValue(root.workspaceIndicatorBadgeFontWeightKey, Style.fontWeightSemiBold)
                            pointSize: root.workspaceIndicatorBadgeFontSize
                        }
                    }
                }
            }
        }
    }

    Item {
        id: pinnedAppsContainer
        visible: root.pinnedSegmentCount > 0
        x: {
            if (root.pinnedAppsPosition === "left")
                return root.pinnedAppsMarginLeft;
            return root.leftAccessoryWidth + root.actualTrackWidth + (root.showWorkspaceIndicator && root.workspaceIndicatorPosition === "right" ? root.totalIndicatorWidth : 0) + root.pinnedAppsMarginLeft;
        }
        y: root.pinnedAppsAlignedY()
        width: root.pinnedAreaContentWidth
        height: root.pinnedSegmentCount > 0 ? root.pinnedSlotSize : 0
        z: 25

        Row {
            anchors.fill: parent
            spacing: root.segmentSpacing

            Repeater {
                model: root.pinnedEntries

                delegate: Item {
                    id: pinnedItem

                    required property var modelData

                    readonly property string appId: modelData?.appId ?? ""
                    readonly property string title: modelData?.name ?? appId

                    width: root.pinnedSlotSize
                    height: root.pinnedSlotSize

                    Rectangle {
                        anchors.fill: parent
                        radius: Math.min(root.windowBorderRadius, Math.min(width, height) / 2)
                        color: root.pinnedSlotBackgroundColor(pinnedItem.appId)

                        Behavior on color {
                            enabled: root.animationEnabled
                            ColorAnimation {
                                duration: root.animationSpeed
                            }
                        }
                    }

                    IconImage {
                        id: pinnedCustomIcon
                        anchors.centerIn: parent
                        width: root.computedIconSize
                        height: root.computedIconSize
                        source: root.pinnedAppIconSource(pinnedItem.modelData)
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: visible && root.pinnedAppsIconColorKey !== "none"
                        layer.effect: ShaderEffect {
                            property color targetColor: root.pinnedAppsIconColor
                            property real colorizeMode: 0.0

                            fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                        }
                    }

                    NText {
                        anchors.centerIn: parent
                        visible: !pinnedCustomIcon.visible
                        text: pinnedItem.title.length > 0 ? pinnedItem.title.charAt(0).toUpperCase() : "?"
                        pointSize: Math.max(Style.fontSizeXS, root.titleFontSize * root.titleScale * 0.95)
                        font.weight: Style.fontWeightBold
                        color: root.pinnedAppsIconColorKey === "none" ? Color.mOnSurface : root.pinnedAppsIconColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        onEntered: {
                            root.hoveredPinnedAppId = pinnedItem.appId;
                            if (pinnedItem.title)
                                TooltipService.show(pinnedItem, pinnedItem.title, BarService.getTooltipDirection(root.screen?.name));
                        }

                        onExited: {
                            if (root.hoveredPinnedAppId === pinnedItem.appId)
                                root.hoveredPinnedAppId = "";
                            TooltipService.hide();
                        }

                        onReleased: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                TooltipService.hide();
                                root.openContextMenu(pinnedItem, null, pinnedItem.modelData);
                            } else if (mouse.button === Qt.LeftButton) {
                                root.activatePinnedApp(pinnedItem.appId);
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        id: segmentsRow
        x: root.leftAccessoryWidth + horizontalPadding
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

                readonly property string entryKey: modelData.entryKey ?? ""
                readonly property string title: root.currentTitle(modelData)
                readonly property bool showLabel: root.labelVisible(entryKey)

                width: root.segmentWidth
                height: parent ? parent.height : root.availableContainerHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.windowMargin
                    radius: Math.min(Math.max(0, root.windowBorderRadius), Math.max(0, Math.min(width, height) / 2))
                    color: root.segmentBackgroundColor(segmentItem.entryKey)

                    Behavior on color {
                        enabled: root.animationEnabled
                        ColorAnimation {
                            duration: root.animationSpeed
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.windowMargin
                    anchors.leftMargin: root.windowMargin + root.windowPaddingLeft
                    anchors.rightMargin: root.windowMargin + root.windowPaddingRight
                    spacing: root.labelGap
                    visible: root.showIcon || root.showTitle
                    layoutDirection: root.focusedOnly && root.focusedAlign === "right" && segmentItem.showLabel ? Qt.RightToLeft : Qt.LeftToRight

                    Item {
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
                            source: ThemeIcons.iconForAppId(segmentItem.modelData.appId)
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
                    }

                    NText {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.showTitle
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
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

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
                        if (mouse.button === Qt.MiddleButton) {
                            root.mainInstance?.closeEntry(segmentItem.entryKey);
                        } else if (mouse.button === Qt.RightButton) {
                            TooltipService.hide();
                            root.openContextMenu(segmentItem, segmentItem.modelData);
                        } else if (mouse.button === Qt.LeftButton) {
                            root.mainInstance?.focusEntry(segmentItem.entryKey);
                        }
                    }
                }
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

    Rectangle {
        id: specialWorkspaceOverlay
        visible: root.showSpecialWorkspaceOverlay
        x: root.leftAccessoryWidth + Math.round((root.effectiveTrackWidth - width) / 2)
        y: root.specialWorkspaceOverlayY()
        width: root.specialWorkspaceOverlayWidth
        height: root.specialWorkspaceOverlayHeight
        radius: Math.min(root.trackBorderRadius, Math.min(width, height) / 2)
        color: Qt.alpha(root.specialWorkspaceOverlayBackgroundColor, root.specialWorkspaceOverlayBackgroundOpacity)
        z: 22
        opacity: root.showSpecialWorkspaceOverlay ? 1 : 0
        scale: root.showSpecialWorkspaceOverlay ? 1 : 0.92

        Behavior on opacity {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.specialWorkspaceOverlayEasingType()
                easing.overshoot: root.specialWorkspaceOverlayOvershoot()
            }
        }

        Behavior on scale {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.specialWorkspaceOverlayEasingType()
                easing.overshoot: root.specialWorkspaceOverlayOvershoot()
            }
        }

        Item {
            anchors.fill: parent
            clip: true

            Row {
                anchors.centerIn: parent
                spacing: (root.outgoingSpecialWorkspaceText !== "" && root.outgoingSpecialWorkspaceIcons.length > 0) ? root.specialWorkspaceOverlayIconGap : 0
                visible: root.outgoingSpecialWorkspaceText !== "" && root.specialWorkspaceOverlayTransitionProgress < 1
                opacity: 1 - root.specialWorkspaceOverlayTransitionProgress
                y: Math.round(-Math.max(4, root.specialWorkspaceOverlayHeight * 0.14) * root.specialWorkspaceOverlayTransitionProgress)

                NText {
                    readonly property real iconsWidth: root.outgoingSpecialWorkspaceIcons.length > 0
                        ? (root.outgoingSpecialWorkspaceIcons.length * root.specialWorkspaceOverlayIconSize) + ((root.outgoingSpecialWorkspaceIcons.length - 1) * root.specialWorkspaceOverlayIconGap)
                        : 0
                    readonly property real maxTextWidth: Math.max(0, specialWorkspaceOverlay.width - (root.specialWorkspaceOverlayContentPadding * 2) - iconsWidth - (root.outgoingSpecialWorkspaceIcons.length > 0 ? root.specialWorkspaceOverlayIconGap : 0))
                    width: Math.min(implicitWidth, maxTextWidth)
                    text: root.outgoingSpecialWorkspaceText
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: Qt.alpha(root.specialWorkspaceOverlayTextColor, root.specialWorkspaceOverlayTextOpacity)
                    font.family: root.specialWorkspaceOverlayFontFamily || Qt.application.font.family
                    font.weight: root.fontWeightValue(root.specialWorkspaceOverlayFontWeightKey, Style.fontWeightMedium)
                    pointSize: root.specialWorkspaceOverlayFontSize
                }

                Repeater {
                    model: root.outgoingSpecialWorkspaceIcons

                    delegate: IconImage {
                        required property var modelData

                        width: root.specialWorkspaceOverlayIconSize
                        height: width
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        source: ThemeIcons.iconForAppId(String(modelData || ""))
                        smooth: true
                        asynchronous: true
                    }
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: (root.displayedSpecialWorkspaceText !== "" && root.displayedSpecialWorkspaceIcons.length > 0) ? root.specialWorkspaceOverlayIconGap : 0
                opacity: root.animationEnabled ? root.specialWorkspaceOverlayTransitionProgress : 1
                y: root.animationEnabled ? Math.round((1 - root.specialWorkspaceOverlayTransitionProgress) * Math.max(4, root.specialWorkspaceOverlayHeight * 0.14)) : 0

                NText {
                    readonly property real iconsWidth: root.displayedSpecialWorkspaceIcons.length > 0
                        ? (root.displayedSpecialWorkspaceIcons.length * root.specialWorkspaceOverlayIconSize) + ((root.displayedSpecialWorkspaceIcons.length - 1) * root.specialWorkspaceOverlayIconGap)
                        : 0
                    readonly property real maxTextWidth: Math.max(0, specialWorkspaceOverlay.width - (root.specialWorkspaceOverlayContentPadding * 2) - iconsWidth - (root.displayedSpecialWorkspaceIcons.length > 0 ? root.specialWorkspaceOverlayIconGap : 0))
                    width: Math.min(implicitWidth, maxTextWidth)
                    text: root.displayedSpecialWorkspaceText
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: Qt.alpha(root.specialWorkspaceOverlayTextColor, root.specialWorkspaceOverlayTextOpacity)
                    font.family: root.specialWorkspaceOverlayFontFamily || Qt.application.font.family
                    font.weight: root.fontWeightValue(root.specialWorkspaceOverlayFontWeightKey, Style.fontWeightMedium)
                    pointSize: root.specialWorkspaceOverlayFontSize
                }

                Repeater {
                    model: root.displayedSpecialWorkspaceIcons

                    delegate: IconImage {
                        required property var modelData

                        width: root.specialWorkspaceOverlayIconSize
                        height: width
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        source: ThemeIcons.iconForAppId(String(modelData || ""))
                        smooth: true
                        asynchronous: true
                    }
                }
            }
        }
    }

    Item {
        id: trackSeparators
        x: root.leftAccessoryWidth
        y: trackLine.y
        width: root.effectiveTrackWidth
        height: trackLine.height
        visible: root.segmentCount > 1 && root.segmentSpacing > 0 && trackLine.visible
        z: 11

        Repeater {
            model: Math.max(0, root.segmentCount - 1)

            delegate: Rectangle {
                required property int index

                x: root.separatorOffset(index)
                y: 0
                width: root.segmentSpacing
                height: trackSeparators.height
                color: Qt.alpha(root.separatorColor, root.trackOpacity)
            }
        }
    }

    NDropShadow {
        anchors.fill: trackLine
        source: trackLine
        autoPaddingEnabled: true
        visible: trackShadowEnabled && trackLine.visible
        z: 9
    }

    Item {
        id: focusIndicator
        visible: focusedIndex >= 0 && availableContainerHeight > 0
        x: root.leftAccessoryWidth + indicatorOffset(focusedIndex)
        y: 0
        width: segmentWidth
        height: availableContainerHeight
        z: 20

        Behavior on x {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.focusLineEasingType()
                easing.overshoot: root.focusLineOvershoot()
            }
        }

        Behavior on width {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.focusLineEasingType()
                easing.overshoot: root.focusLineOvershoot()
            }
        }

        Rectangle {
            id: focusLineFill
            x: 0
            y: root.indicatorY()
            width: parent.width
            height: root.visibleFocusLineThickness
            radius: root.focusLineRadius
            color: Qt.alpha(root.focusLineIndicatorColor, root.focusLineOpacity * root.focusLineIndicatorOpacity)
        }
    }

    Item {
        x: root.leftAccessoryWidth
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
                    source: ThemeIcons.iconForAppId(root.focusedEntry()?.appId ?? "")
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
                    text: root.currentTitle(root.focusedEntry()).length > 0 ? root.currentTitle(root.focusedEntry()).charAt(0).toUpperCase() : "?"
                    pointSize: Math.max(Style.fontSizeXS, root.titleFontSize * root.titleScale * 0.95)
                    font.weight: Style.fontWeightBold
                    color: Qt.alpha(root.iconColorFocused, root.iconColorFocusedOpacity)
                }
            }

            NText {
                visible: root.showTitle
                text: root.currentTitle(root.focusedEntry())
                elide: Text.ElideRight
                maximumLineCount: 1
                color: Qt.alpha(root.titleColorFocused, root.titleColorFocusedOpacity)
                font.family: root.titleFontFamily || Qt.application.font.family
                pointSize: root.titleFontSize * root.titleScale
                font.weight: root.fontWeightValue(root.titleWeightFocused, Style.fontWeightSemiBold)
            }
        }
    }

    NPopupContextMenu {
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
            } else if (action === "style-rule-app") {
                const existingAppRuleIndex = root.mainInstance?.findPrefilledStyleRuleIndex(root.selectedEntryKey, "appId") ?? -1;
                if (existingAppRuleIndex < 0) {
                    const appRule = root.mainInstance?.buildPrefilledStyleRule(root.selectedEntryKey, "appId");
                    if (appRule)
                        root.mainInstance?.appendStyleRule(appRule, true);
                }
                root.mainInstance?.requestPrefilledStyleRuleEdit(root.selectedEntryKey, "appId");
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            } else if (action === "style-rule-title") {
                const existingTitleRuleIndex = root.mainInstance?.findPrefilledStyleRuleIndex(root.selectedEntryKey, "title") ?? -1;
                if (existingTitleRuleIndex < 0) {
                    const titleRule = root.mainInstance?.buildPrefilledStyleRule(root.selectedEntryKey, "title");
                    if (titleRule)
                        root.mainInstance?.appendStyleRule(titleRule, true);
                }
                root.mainInstance?.requestPrefilledStyleRuleEdit(root.selectedEntryKey, "title");
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
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

        function onStructureRevisionChanged() {
            root.hoveredEntryKey = "";
            root.hoveredPinnedAppId = "";
        }
    }

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.invalidStyleRulePatterns = ({});
        }
    }
}
