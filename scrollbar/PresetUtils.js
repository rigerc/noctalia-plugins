.pragma library

function deepCopy(value) {
    return JSON.parse(JSON.stringify(value));
}

function isPlainObject(value) {
    return value !== null && typeof value === "object" && !Array.isArray(value);
}

function applyDeepOverride(target, overrides) {
    if (!isPlainObject(overrides))
        return;

    for (const key in overrides) {
        const nextValue = overrides[key];
        if (isPlainObject(nextValue)) {
            if (!isPlainObject(target[key]))
                target[key] = ({});
            applyDeepOverride(target[key], nextValue);
        } else {
            target[key] = deepCopy(nextValue);
        }
    }
}

function mergeDeep(base, overrides) {
    const result = deepCopy(base);
    applyDeepOverride(result, overrides);
    return result;
}

function readSetting(primary, secondary, groupKey, nestedKey, legacyKey, fallbackValue) {
    const primaryGroup = primary ? primary[groupKey] : undefined;
    const nestedPrimary = primaryGroup ? primaryGroup[nestedKey] : undefined;
    if (nestedPrimary !== undefined)
        return nestedPrimary;

    const legacyPrimary = primary ? primary[legacyKey] : undefined;
    if (legacyPrimary !== undefined)
        return legacyPrimary;

    const secondaryGroup = secondary ? secondary[groupKey] : undefined;
    const nestedSecondary = secondaryGroup ? secondaryGroup[nestedKey] : undefined;
    if (nestedSecondary !== undefined)
        return nestedSecondary;

    const legacySecondary = secondary ? secondary[legacyKey] : undefined;
    if (legacySecondary !== undefined)
        return legacySecondary;

    return fallbackValue;
}

function createSettingsSnapshot(primary, secondary) {
    return {
        "filtering": {
            "onlySameOutput": readSetting(primary, secondary, "filtering", "onlySameOutput", "onlySameOutput", true),
            "onlyActiveWorkspaces": readSetting(primary, secondary, "filtering", "onlyActiveWorkspaces", "onlyActiveWorkspaces", true)
        },
        "interaction": {
            "enableReorder": readSetting(primary, secondary, "interaction", "enableReorder", "enableReorder", true),
            "enableScrollWheel": readSetting(primary, secondary, "interaction", "enableScrollWheel", "enableScrollWheel", true)
        },
        "autoScroll": {
            "centerFocusedWindow": readSetting(primary, secondary, "autoScroll", "centerFocusedWindow", "centerFocusedWindow", true),
            "centerAnimationMs": readSetting(primary, secondary, "autoScroll", "centerAnimationMs", "centerAnimationMs", 200)
        },
        "window": {
            "renderMode": readSetting(primary, secondary, "window", "renderMode", "renderMode", "bar"),
            "spaceMode": readSetting(primary, secondary, "window", "spaceMode", "windowSpaceMode", "overlay"),
            "offsetH": readSetting(primary, secondary, "window", "offsetH", "windowOffsetH", 0),
            "offsetV": readSetting(primary, secondary, "window", "offsetV", "windowOffsetV", 0),
            "scale": readSetting(primary, secondary, "window", "scale", "windowScale", 1.0),
            "backgroundColor": readSetting(primary, secondary, "window", "backgroundColor", "windowBackgroundColor", "none"),
            "backgroundOpacity": readSetting(primary, secondary, "window", "backgroundOpacity", "windowBackgroundOpacity", 0),
            "margin": readSetting(primary, secondary, "window", "margin", "windowMargin", 0),
            "height": readSetting(primary, secondary, "window", "height", "windowHeight", 0),
            "radiusScale": readSetting(primary, secondary, "window", "radiusScale", "windowRadiusScale", 1.0),
            "gradientEnabled": readSetting(primary, secondary, "window", "gradientEnabled", "windowGradientEnabled", false),
            "gradientColor": readSetting(primary, secondary, "window", "gradientColor", "windowGradientColor", "none"),
            "gradientOpacity": readSetting(primary, secondary, "window", "gradientOpacity", "windowGradientOpacity", 0),
            "gradientDirection": readSetting(primary, secondary, "window", "gradientDirection", "windowGradientDirection", "vertical")
        },
        "advanced": {
            "debugLogging": readSetting(primary, secondary, "advanced", "debugLogging", "debugLogging", false)
        },
        "layout": {
            "widgetSizeMode": readSetting(primary, secondary, "layout", "widgetSizeMode", "widgetSizeMode", "dynamic"),
            "fixedWidgetSize": readSetting(primary, secondary, "layout", "fixedWidgetSize", "fixedWidgetSize", 360),
            "maxWidgetWidth": readSetting(primary, secondary, "layout", "maxWidgetWidth", "maxWidgetWidth", 40),
            "showSlots": readSetting(primary, secondary, "layout", "showSlots", "showSlots", true),
            "slotWidth": readSetting(primary, secondary, "layout", "slotWidth", "slotWidth", 112),
            "slotSpacingUnits": readSetting(primary, secondary, "layout", "slotSpacingUnits", "slotSpacingUnits", 1),
            "radiusScale": readSetting(primary, secondary, "layout", "radiusScale", "radiusScale", 1.0),
            "slotCapsuleScale": readSetting(primary, secondary, "layout", "slotCapsuleScale", "slotCapsuleScale", 1.0)
        },
        "icons": {
            "showIcons": readSetting(primary, secondary, "icons", "showIcons", "showIcons", true),
            "iconScale": readSetting(primary, secondary, "icons", "iconScale", "iconScale", 0.8),
            "iconTintColor": readSetting(primary, secondary, "icons", "iconTintColor", "iconTintColor", "none"),
            "iconTintOpacity": readSetting(primary, secondary, "icons", "iconTintOpacity", "iconTintOpacity", 100)
        },
        "title": {
            "showTitle": readSetting(primary, secondary, "title", "showTitle", "showTitle", true),
            "titleFontFamily": readSetting(primary, secondary, "title", "titleFontFamily", "titleFontFamily", ""),
            "titleFontSize": readSetting(primary, secondary, "title", "titleFontSize", "titleFontSize", 0),
            "titleFontWeight": readSetting(primary, secondary, "title", "titleFontWeight", "titleFontWeight", "default")
        },
        "focusedTitle": {
            "enabled": readSetting(primary, secondary, "focusedTitle", "enabled", "focusedTitleEnabled", false),
            "textColor": readSetting(primary, secondary, "focusedTitle", "textColor", "focusedTitleTextColor", "on-surface"),
            "opacity": readSetting(primary, secondary, "focusedTitle", "opacity", "focusedTitleOpacity", 100),
            "backgroundColor": readSetting(primary, secondary, "focusedTitle", "backgroundColor", "focusedTitleBackgroundColor", "none"),
            "backgroundOpacity": readSetting(primary, secondary, "focusedTitle", "backgroundOpacity", "focusedTitleBackgroundOpacity", 0),
            "offsetV": readSetting(primary, secondary, "focusedTitle", "offsetV", "focusedTitleOffsetV", 0)
        },
        "workspaceIndicator": {
            "enabled": readSetting(primary, secondary, "workspaceIndicator", "enabled", "workspaceIndicatorEnabled", false),
            "labelMode": readSetting(primary, secondary, "workspaceIndicator", "labelMode", "workspaceIndicatorLabelMode", "id"),
            "position": readSetting(primary, secondary, "workspaceIndicator", "position", "workspaceIndicatorPosition", "before"),
            "spacing": readSetting(primary, secondary, "workspaceIndicator", "spacing", "workspaceIndicatorSpacing", 8),
            "padding": readSetting(primary, secondary, "workspaceIndicator", "padding", "workspaceIndicatorPadding", 0),
            "fontFamily": readSetting(primary, secondary, "workspaceIndicator", "fontFamily", "workspaceIndicatorFontFamily", ""),
            "fontSize": readSetting(primary, secondary, "workspaceIndicator", "fontSize", "workspaceIndicatorFontSize", 0),
            "textColor": readSetting(primary, secondary, "workspaceIndicator", "textColor", "workspaceIndicatorTextColor", "primary"),
            "opacity": readSetting(primary, secondary, "workspaceIndicator", "opacity", "workspaceIndicatorOpacity", 100)
        },
        "edgeFade": {
            "enabled": (function () {
                const configuredEnabled = readSetting(primary, secondary, "edgeFade", "enabled", "edgeFadeEnabled", undefined);
                if (configuredEnabled !== undefined)
                    return configuredEnabled;

                const configuredMode = readSetting(primary, secondary, "edgeFade", "mode", "edgeFadeMode", undefined);
                if (configuredMode !== undefined)
                    return configuredMode !== "off";

                const legacySize = readSetting(primary, secondary, "edgeFade", "size", "edgeFadeSize", undefined);
                if (legacySize !== undefined)
                    return legacySize > 0;

                return true;
            })(),
            "fadeSize": (function () {
                const configuredFadeSize = readSetting(primary, secondary, "edgeFade", "fadeSize", "edgeFadeFadeSize", undefined);
                if (configuredFadeSize !== undefined)
                    return configuredFadeSize;
                return readSetting(primary, secondary, "edgeFade", "size", "edgeFadeSize", 48);
            })(),
            "fadeOpacity": readSetting(primary, secondary, "edgeFade", "fadeOpacity", "edgeFadeOpacity", 100)
        },
        "background": {
            "color": readSetting(primary, secondary, "background", "color", "backgroundColor", "none"),
            "opacity": readSetting(primary, secondary, "background", "opacity", "backgroundOpacity", 0)
        },
        "focused": {
            "showFill": readSetting(primary, secondary, "focused", "showFill", "showFocusedFill", true),
            "fillColor": readSetting(primary, secondary, "focused", "fillColor", "focusedFillColor", "primary"),
            "fillOpacity": readSetting(primary, secondary, "focused", "fillOpacity", "focusedFillOpacity", 92),
            "showBorder": readSetting(primary, secondary, "focused", "showBorder", "showFocusedBorder", true),
            "borderColor": readSetting(primary, secondary, "focused", "borderColor", "focusedBorderColor", "primary"),
            "borderOpacity": readSetting(primary, secondary, "focused", "borderOpacity", "focusedBorderOpacity", 100),
            "textColor": readSetting(primary, secondary, "focused", "textColor", "focusedTextColor", "on-primary")
        },
        "unfocused": {
            "showFill": readSetting(primary, secondary, "unfocused", "showFill", "showUnfocusedFill", true),
            "fillColor": readSetting(primary, secondary, "unfocused", "fillColor", "unfocusedFillColor", "surface-variant"),
            "fillOpacity": readSetting(primary, secondary, "unfocused", "fillOpacity", "unfocusedFillOpacity", 8),
            "showBorder": readSetting(primary, secondary, "unfocused", "showBorder", "showUnfocusedBorder", true),
            "borderColor": readSetting(primary, secondary, "unfocused", "borderColor", "unfocusedBorderColor", "outline"),
            "borderOpacity": readSetting(primary, secondary, "unfocused", "borderOpacity", "unfocusedBorderOpacity", 45),
            "textColor": readSetting(primary, secondary, "unfocused", "textColor", "unfocusedTextColor", "on-surface"),
            "inactiveOpacity": readSetting(primary, secondary, "unfocused", "inactiveOpacity", "inactiveOpacity", 45)
        },
        "hover": {
            "fillColor": readSetting(primary, secondary, "hover", "fillColor", "hoverFillColor", "hover"),
            "fillOpacity": readSetting(primary, secondary, "hover", "fillOpacity", "hoverFillOpacity", 55),
            "showBorder": readSetting(primary, secondary, "hover", "showBorder", "showHoverBorder", true),
            "borderColor": readSetting(primary, secondary, "hover", "borderColor", "hoverBorderColor", "outline"),
            "borderOpacity": readSetting(primary, secondary, "hover", "borderOpacity", "hoverBorderOpacity", 100),
            "textColor": readSetting(primary, secondary, "hover", "textColor", "hoverTextColor", "on-hover"),
            "scalePercent": readSetting(primary, secondary, "hover", "scalePercent", "hoverScalePercent", 2.5),
            "transitionDurationMs": readSetting(primary, secondary, "hover", "transitionDurationMs", "hoverTransitionDurationMs", 120)
        },
        "indicators": {
            "showTrackLine": readSetting(primary, secondary, "indicators", "showTrackLine", "showTrackLine", true),
            "trackOpacity": readSetting(primary, secondary, "indicators", "trackOpacity", "trackOpacity", 35),
            "trackLinePosition": readSetting(primary, secondary, "indicators", "trackLinePosition", "trackLinePosition", "end"),
            "trackLineThickness": readSetting(primary, secondary, "indicators", "trackLineThickness", "trackLineThickness", 2),
            "trackThumbColor": readSetting(primary, secondary, "indicators", "trackThumbColor", "trackThumbColor", "primary"),
            "showFocusLine": readSetting(primary, secondary, "indicators", "showFocusLine", "showFocusLine", true),
            "focusLineColor": readSetting(primary, secondary, "indicators", "focusLineColor", "focusLineColor", "secondary"),
            "focusLineOpacity": readSetting(primary, secondary, "indicators", "focusLineOpacity", "focusLineOpacity", 96),
            "focusLineThickness": readSetting(primary, secondary, "indicators", "focusLineThickness", "focusLineThickness", 2),
            "focusLineAnimationMs": readSetting(primary, secondary, "indicators", "focusLineAnimationMs", "focusLineAnimationMs", 120)
        },
        "workspaceAnimation": {
            "enabled": readSetting(primary, secondary, "workspaceAnimation", "enabled", "workspaceAnimationEnabled", false),
            "axis": readSetting(primary, secondary, "workspaceAnimation", "axis", "workspaceAnimationAxis", "horizontal")
        }
    };
}

function normalizePresetName(name) {
    return (name ?? "").trim();
}

function findCustomPresetIndex(name, presets) {
    const normalizedName = normalizePresetName(name).toLowerCase();
    if (normalizedName === "")
        return -1;

    const list = presets || [];
    for (let i = 0; i < list.length; i++) {
        if ((list[i]?.name ?? "").toLowerCase() === normalizedName)
            return i;
    }

    return -1;
}

function createCustomPresetList(primary, secondary) {
    const primaryPresets = primary?.presets?.custom;
    const secondaryPresets = secondary?.presets?.custom;
    const source = Array.isArray(primaryPresets) ? primaryPresets : (Array.isArray(secondaryPresets) ? secondaryPresets : []);
    const normalized = [];

    for (let i = 0; i < source.length; i++) {
        const entry = source[i];
        const name = normalizePresetName(entry?.name ?? "");
        if (name === "" || findCustomPresetIndex(name, normalized) !== -1)
            continue;

        normalized.push({
            "name": name,
            "settings": createSettingsSnapshot(entry?.settings || ({}), secondary)
        });
    }

    return normalized;
}

function createCustomPresetListFromData(data, defaults) {
    if (Array.isArray(data))
        return createCustomPresetList({
            "presets": {
                "custom": data
            }
        }, defaults || ({}));

    if (Array.isArray(data?.customPresets))
        return createCustomPresetList({
            "presets": {
                "custom": data.customPresets
            }
        }, defaults || ({}));

    if (Array.isArray(data?.presets?.custom))
        return createCustomPresetList(data, defaults || ({}));

    if (Array.isArray(data?.presets))
        return createCustomPresetList({
            "presets": {
                "custom": data.presets
            }
        }, defaults || ({}));

    return [];
}

function builtInPresetKeys() {
    return [
        "standard",
        "focusTrack",
        "iconStrip",
        "titleTrack",
        "trackOnly",
        "denseStrip",
        "floatingPanel",
        "edgePill"
    ];
}

function builtInStyleOverrides(key) {
    switch (key) {
    case "standard":
        return {
            "background": {
                "color": "none",
                "opacity": 0
            },
            "edgeFade": {
                "enabled": true,
                "fadeSize": 48,
                "fadeOpacity": 100
            },
            "focused": {
                "showFill": true,
                "fillColor": "primary",
                "fillOpacity": 92,
                "showBorder": true,
                "borderColor": "primary",
                "borderOpacity": 100,
                "textColor": "on-primary"
            },
            "unfocused": {
                "showFill": true,
                "fillColor": "surface-variant",
                "fillOpacity": 8,
                "showBorder": true,
                "borderColor": "outline",
                "borderOpacity": 45,
                "textColor": "on-surface",
                "inactiveOpacity": 45
            },
            "hover": {
                "fillColor": "hover",
                "fillOpacity": 55,
                "showBorder": true,
                "borderColor": "outline",
                "borderOpacity": 100,
                "textColor": "on-hover",
                "scalePercent": 2.5,
                "transitionDurationMs": 120
            },
            "indicators": {
                "showTrackLine": false,
                "trackOpacity": 35,
                "trackLinePosition": "end",
                "trackLineThickness": 2,
                "trackThumbColor": "primary",
                "showFocusLine": false,
                "focusLineColor": "secondary",
                "focusLineOpacity": 96,
                "focusLineThickness": 2,
                "focusLineAnimationMs": 120
            }
        };
    case "focusTrack":
        return {
            "background": {
                "color": "surface",
                "opacity": 12
            },
            "edgeFade": {
                "enabled": true,
                "fadeSize": 52,
                "fadeOpacity": 88
            },
            "focused": {
                "showFill": true,
                "fillColor": "primary",
                "fillOpacity": 78,
                "showBorder": true,
                "borderColor": "secondary",
                "borderOpacity": 100,
                "textColor": "on-primary"
            },
            "unfocused": {
                "showFill": true,
                "fillColor": "surface-variant",
                "fillOpacity": 10,
                "showBorder": true,
                "borderColor": "outline",
                "borderOpacity": 30,
                "textColor": "on-surface",
                "inactiveOpacity": 52
            },
            "hover": {
                "fillColor": "secondary",
                "fillOpacity": 35,
                "showBorder": true,
                "borderColor": "secondary",
                "borderOpacity": 85,
                "textColor": "on-secondary",
                "scalePercent": 2.5,
                "transitionDurationMs": 150
            },
            "indicators": {
                "showTrackLine": true,
                "trackOpacity": 42,
                "trackLinePosition": "end",
                "trackLineThickness": 2,
                "trackThumbColor": "primary",
                "showFocusLine": true,
                "focusLineColor": "secondary",
                "focusLineOpacity": 100,
                "focusLineThickness": 3,
                "focusLineAnimationMs": 160
            }
        };
    case "iconStrip":
        return {
            "background": {
                "color": "none",
                "opacity": 0
            },
            "edgeFade": {
                "enabled": true,
                "fadeSize": 40,
                "fadeOpacity": 92
            },
            "focused": {
                "showFill": true,
                "fillColor": "secondary",
                "fillOpacity": 72,
                "showBorder": false,
                "borderColor": "secondary",
                "borderOpacity": 0,
                "textColor": "on-secondary"
            },
            "unfocused": {
                "showFill": true,
                "fillColor": "surface-variant",
                "fillOpacity": 12,
                "showBorder": false,
                "borderColor": "outline",
                "borderOpacity": 0,
                "textColor": "on-surface",
                "inactiveOpacity": 56
            },
            "hover": {
                "fillColor": "hover",
                "fillOpacity": 28,
                "showBorder": false,
                "borderColor": "outline",
                "borderOpacity": 0,
                "textColor": "on-hover",
                "scalePercent": 3,
                "transitionDurationMs": 120
            },
            "indicators": {
                "showTrackLine": false,
                "trackOpacity": 30,
                "trackLinePosition": "center",
                "trackLineThickness": 2,
                "trackThumbColor": "secondary",
                "showFocusLine": false,
                "focusLineColor": "secondary",
                "focusLineOpacity": 100,
                "focusLineThickness": 2,
                "focusLineAnimationMs": 120
            }
        };
    case "titleTrack":
        return {
            "background": {
                "color": "surface",
                "opacity": 22
            },
            "edgeFade": {
                "enabled": false,
                "fadeSize": 32,
                "fadeOpacity": 0
            },
            "focusedTitle": {
                "enabled": true,
                "textColor": "on-surface",
                "opacity": 100,
                "backgroundColor": "none",
                "backgroundOpacity": 0,
                "offsetV": 0
            },
            "hover": {
                "fillColor": "hover",
                "fillOpacity": 0,
                "showBorder": false,
                "borderColor": "outline",
                "borderOpacity": 0,
                "textColor": "on-surface",
                "scalePercent": 0,
                "transitionDurationMs": 120
            },
            "indicators": {
                "showTrackLine": true,
                "trackOpacity": 55,
                "trackLinePosition": "center",
                "trackLineThickness": 2,
                "trackThumbColor": "primary",
                "showFocusLine": true,
                "focusLineColor": "secondary",
                "focusLineOpacity": 100,
                "focusLineThickness": 3,
                "focusLineAnimationMs": 180
            }
        };
    case "trackOnly":
        return {
            "background": {
                "color": "surface-variant",
                "opacity": 18
            },
            "edgeFade": {
                "enabled": false,
                "fadeSize": 24,
                "fadeOpacity": 0
            },
            "focusedTitle": {
                "enabled": false,
                "textColor": "on-surface",
                "opacity": 0,
                "backgroundColor": "none",
                "backgroundOpacity": 0,
                "offsetV": 0
            },
            "indicators": {
                "showTrackLine": true,
                "trackOpacity": 60,
                "trackLinePosition": "center",
                "trackLineThickness": 3,
                "trackThumbColor": "primary",
                "showFocusLine": true,
                "focusLineColor": "tertiary",
                "focusLineOpacity": 100,
                "focusLineThickness": 4,
                "focusLineAnimationMs": 180
            }
        };
    case "denseStrip":
        return {
            "background": {
                "color": "none",
                "opacity": 0
            },
            "edgeFade": {
                "enabled": true,
                "fadeSize": 36,
                "fadeOpacity": 96
            },
            "focused": {
                "showFill": true,
                "fillColor": "primary",
                "fillOpacity": 70,
                "showBorder": false,
                "borderColor": "primary",
                "borderOpacity": 0,
                "textColor": "on-primary"
            },
            "unfocused": {
                "showFill": true,
                "fillColor": "surface-variant",
                "fillOpacity": 14,
                "showBorder": false,
                "borderColor": "outline",
                "borderOpacity": 0,
                "textColor": "on-surface",
                "inactiveOpacity": 62
            },
            "hover": {
                "fillColor": "secondary",
                "fillOpacity": 24,
                "showBorder": false,
                "borderColor": "secondary",
                "borderOpacity": 0,
                "textColor": "on-secondary",
                "scalePercent": 2,
                "transitionDurationMs": 90
            },
            "indicators": {
                "showTrackLine": false,
                "trackOpacity": 30,
                "trackLinePosition": "end",
                "trackLineThickness": 2,
                "trackThumbColor": "primary",
                "showFocusLine": false,
                "focusLineColor": "secondary",
                "focusLineOpacity": 100,
                "focusLineThickness": 2,
                "focusLineAnimationMs": 100
            }
        };
    case "floatingPanel":
        return {
            "background": {
                "color": "surface",
                "opacity": 0
            },
            "edgeFade": {
                "enabled": true,
                "fadeSize": 28,
                "fadeOpacity": 70
            },
            "focused": {
                "showFill": true,
                "fillColor": "primary",
                "fillOpacity": 65,
                "showBorder": true,
                "borderColor": "primary",
                "borderOpacity": 72,
                "textColor": "on-primary"
            },
            "unfocused": {
                "showFill": true,
                "fillColor": "surface-variant",
                "fillOpacity": 18,
                "showBorder": true,
                "borderColor": "outline",
                "borderOpacity": 28,
                "textColor": "on-surface",
                "inactiveOpacity": 58
            },
            "hover": {
                "fillColor": "secondary",
                "fillOpacity": 22,
                "showBorder": true,
                "borderColor": "secondary",
                "borderOpacity": 60,
                "textColor": "on-secondary",
                "scalePercent": 1.5,
                "transitionDurationMs": 140
            },
            "indicators": {
                "showTrackLine": true,
                "trackOpacity": 26,
                "trackLinePosition": "end",
                "trackLineThickness": 2,
                "trackThumbColor": "primary",
                "showFocusLine": true,
                "focusLineColor": "secondary",
                "focusLineOpacity": 84,
                "focusLineThickness": 2,
                "focusLineAnimationMs": 140
            }
        };
    case "edgePill":
        return {
            "background": {
                "color": "surface",
                "opacity": 0
            },
            "edgeFade": {
                "enabled": false,
                "fadeSize": 24,
                "fadeOpacity": 0
            },
            "focusedTitle": {
                "enabled": false,
                "textColor": "on-surface",
                "opacity": 0,
                "backgroundColor": "none",
                "backgroundOpacity": 0,
                "offsetV": 0
            },
            "indicators": {
                "showTrackLine": true,
                "trackOpacity": 48,
                "trackLinePosition": "center",
                "trackLineThickness": 4,
                "trackThumbColor": "primary",
                "showFocusLine": true,
                "focusLineColor": "on-primary",
                "focusLineOpacity": 100,
                "focusLineThickness": 4,
                "focusLineAnimationMs": 160
            }
        };
    default:
        return ({});
    }
}

function builtInPresetSnapshot(key, defaultSettings) {
    const style = builtInStyleOverrides(key);

    switch (key) {
    case "standard":
        return mergeDeep(defaultSettings, style);
    case "focusTrack":
        return mergeDeep(defaultSettings, style);
    case "iconStrip":
        return mergeDeep(defaultSettings, mergeDeep(style, {
            "indicators": {
            },
            "title": {
                "showTitle": false
            }
        }));
    case "titleTrack":
        return mergeDeep(defaultSettings, mergeDeep(style, {
            "layout": {
                "showSlots": false
            },
            "focusedTitle": {
            },
            "indicators": {
            }
        }));
    case "trackOnly":
        return mergeDeep(defaultSettings, mergeDeep(style, {
            "layout": {
                "showSlots": false
            },
            "focusedTitle": {
            },
            "indicators": {
            }
        }));
    case "denseStrip":
        return mergeDeep(defaultSettings, mergeDeep(style, {
            "layout": {
                "widgetSizeMode": "dynamic",
                "maxWidgetWidth": 60,
                "showSlots": true,
                "slotWidth": 84,
                "slotSpacingUnits": 0,
                "slotCapsuleScale": 0.72,
                "radiusScale": 0.85
            },
            "icons": {
                "showIcons": true,
                "iconScale": 0.65
            },
            "title": {
                "showTitle": false
            },
            "indicators": {
            }
        }));
    case "floatingPanel":
        return mergeDeep(defaultSettings, mergeDeep(style, {
            "window": {
                "renderMode": "window",
                "spaceMode": "overlay",
                "backgroundColor": "surface",
                "backgroundOpacity": 75,
                "gradientEnabled": true,
                "gradientColor": "primary",
                "gradientOpacity": 15,
                "radiusScale": 0.6,
                "margin": 8,
                "scale": 0.95
            }
        }));
    case "edgePill":
        return mergeDeep(defaultSettings, mergeDeep(style, {
            "window": {
                "renderMode": "window",
                "spaceMode": "overlay",
                "backgroundColor": "surface",
                "backgroundOpacity": 100,
                "radiusScale": 1.0,
                "margin": 4
            },
            "layout": {
                "showSlots": false
            },
            "indicators": {
            }
        }));
    default:
        return deepCopy(defaultSettings);
    }
}

function createComparableSnapshot(settings, defaults) {
    return createSettingsSnapshot(settings || ({}), defaults || ({}));
}

function createPluginSettingsSnapshot(settings, defaults) {
    const normalized = createComparableSnapshot(settings, defaults);
    normalized.presets = {
        "custom": deepCopy(createCustomPresetList(settings || ({}), defaults || ({})))
    };
    return normalized;
}

function equalSnapshots(left, right) {
    return JSON.stringify(left || null) === JSON.stringify(right || null);
}

function createPresetCatalog(settings, defaults) {
    const defaultSettings = createComparableSnapshot(defaults || ({}), ({}));
    const catalog = [];
    const builtIns = builtInPresetKeys();

    for (let i = 0; i < builtIns.length; i++) {
        const key = builtIns[i];
        catalog.push({
            "id": "builtin:" + key,
            "type": "builtin",
            "key": key,
            "name": key,
            "settings": builtInPresetSnapshot(key, defaultSettings)
        });
    }

    const customPresets = createCustomPresetList(settings || ({}), defaults || ({}));
    for (let i = 0; i < customPresets.length; i++) {
        catalog.push({
            "id": "custom:" + customPresets[i].name,
            "type": "custom",
            "name": customPresets[i].name,
            "settings": deepCopy(customPresets[i].settings)
        });
    }

    return catalog;
}

function findMatchingPresetId(settings, defaults) {
    const current = createComparableSnapshot(settings || ({}), defaults || ({}));
    const catalog = createPresetCatalog(settings || ({}), defaults || ({}));

    for (let i = 0; i < catalog.length; i++) {
        if (equalSnapshots(current, catalog[i].settings))
            return catalog[i].id;
    }

    return "";
}

function findPresetById(id, settings, defaults) {
    const catalog = createPresetCatalog(settings || ({}), defaults || ({}));
    for (let i = 0; i < catalog.length; i++) {
        if (catalog[i].id === id)
            return catalog[i];
    }
    return null;
}
