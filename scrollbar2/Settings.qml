import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "./settings"
import "Migrations.js" as Migrations

ColumnLayout {
    id: root

    property var pluginApi: null
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property var defaultSettings: normalizeSettingsSnapshot(deepCopy(defaults))
    property var editSettings: createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults)
    property real preferredWidth: 920 * Style.uiScaleRatio
    property int selectedTab: 0
    property string _activePresetId: pluginApi?.pluginSettings?._activePresetId || ""
    property int styleRulesRevision: 0
    property var expandedStyleRuleOpacityPanels: ({})
    readonly property var mainInstance: pluginApi?.mainInstance ?? null
    readonly property var tabModel: [
        {
            "label": pluginApi?.tr("settings.navTabs.layout"),
            "icon": "layout-grid"
        },
        {
            "label": pluginApi?.tr("settings.navTabs.appearance"),
            "icon": "palette"
        },
        {
            "label": pluginApi?.tr("settings.navTabs.pinnedApps"),
            "icon": "apps"
        },
        {
            "label": pluginApi?.tr("settings.navTabs.styleRules"),
            "icon": "filter-code"
        },
        {
            "label": pluginApi?.tr("settings.navTabs.presets"),
            "icon": "template"
        }
    ]
    readonly property var styleRuleMatchFieldModel: [
        {
            "key": "appId",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.appId")
        },
        {
            "key": "title",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.title")
        },
        {
            "key": "tag",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.tag")
        },
        {
            "key": "floating",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.floating")
        },
        {
            "key": "urgent",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.urgent")
        },
        {
            "key": "grouped",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.grouped")
        },
        {
            "key": "sharedAppId",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.sharedAppId")
        },
        {
            "key": "sharedTitle",
            "name": pluginApi?.tr("settings.customStyleRules.matchField.sharedTitle")
        }
    ]
    readonly property var styleRuleBadgeTargetModel: [
        {
            "key": "icon",
            "name": pluginApi?.tr("settings.customStyleRules.badge.target.icon")
        },
        {
            "key": "title",
            "name": pluginApi?.tr("settings.customStyleRules.badge.target.title")
        },
        {
            "key": "segment",
            "name": pluginApi?.tr("settings.customStyleRules.badge.target.segment")
        }
    ]
    readonly property var styleRuleBadgePositionModel: [
        {
            "key": "top-left",
            "name": pluginApi?.tr("settings.customStyleRules.badge.position.topLeft")
        },
        {
            "key": "top-right",
            "name": pluginApi?.tr("settings.customStyleRules.badge.position.topRight")
        }
    ]
    readonly property var styleRulePrefixTargetModel: [
        {
            "key": "icon",
            "name": pluginApi?.tr("settings.customStyleRules.iconPrefix.target.icon")
        },
        {
            "key": "title",
            "name": pluginApi?.tr("settings.customStyleRules.iconPrefix.target.title")
        }
    ]
    readonly property var displayModeModel: [
        {
            "key": "floatingPanel",
            "name": pluginApi?.tr("options.displayModeFloatingPanel")
        },
        {
            "key": "bar",
            "name": pluginApi?.tr("options.displayModeBar")
        }
    ]
    readonly property var autoHideRevealModeModel: [
        {
            "key": "edgeSliver",
            "name": pluginApi?.tr("options.autoHideRevealModeEdgeSliver")
        },
        {
            "key": "hoverZone",
            "name": pluginApi?.tr("options.autoHideRevealModeHoverZone")
        }
    ]
    readonly property var autoHideEffectModel: [
        {
            "key": "slideFade",
            "name": pluginApi?.tr("options.autoHideEffectSlideFade")
        },
        {
            "key": "slide",
            "name": pluginApi?.tr("options.autoHideEffectSlide")
        },
        {
            "key": "fade",
            "name": pluginApi?.tr("options.autoHideEffectFade")
        },
        {
            "key": "instant",
            "name": pluginApi?.tr("options.autoHideEffectInstant")
        }
    ]
    readonly property var autoHideSlideDirectionModel: [
        {
            "key": "auto",
            "name": pluginApi?.tr("options.autoHideSlideDirectionAuto")
        },
        {
            "key": "up",
            "name": pluginApi?.tr("options.autoHideSlideDirectionUp")
        },
        {
            "key": "down",
            "name": pluginApi?.tr("options.autoHideSlideDirectionDown")
        },
        {
            "key": "left",
            "name": pluginApi?.tr("options.autoHideSlideDirectionLeft")
        },
        {
            "key": "right",
            "name": pluginApi?.tr("options.autoHideSlideDirectionRight")
        }
    ]
    readonly property var trackPositionModel: [
        {
            "key": "top",
            "name": pluginApi?.tr("options.trackPositionTop")
        },
        {
            "key": "bottom",
            "name": pluginApi?.tr("options.trackPositionBottom")
        }
    ]
    readonly property var focusAlignModel: [
        {
            "key": "segment",
            "name": pluginApi?.tr("options.focusAlignSegment")
        },
        {
            "key": "center",
            "name": pluginApi?.tr("options.focusAlignCenter")
        },
        {
            "key": "left",
            "name": pluginApi?.tr("options.focusAlignLeft")
        },
        {
            "key": "right",
            "name": pluginApi?.tr("options.focusAlignRight")
        }
    ]
    readonly property var focusVerticalModel: [
        {
            "key": "top",
            "name": pluginApi?.tr("options.verticalAlignTop")
        },
        {
            "key": "center",
            "name": pluginApi?.tr("options.verticalAlignCenter")
        },
        {
            "key": "bottom",
            "name": pluginApi?.tr("options.verticalAlignBottom")
        }
    ]
    readonly property var horizontalAlignModel: [
        {
            "key": "left",
            "name": pluginApi?.tr("options.horizontalAlignLeft")
        },
        {
            "key": "center",
            "name": pluginApi?.tr("options.horizontalAlignCenter")
        },
        {
            "key": "right",
            "name": pluginApi?.tr("options.horizontalAlignRight")
        }
    ]
    readonly property var fontWeightModel: [
        {
            "key": "light",
            "name": pluginApi?.tr("options.fontWeightLight")
        },
        {
            "key": "normal",
            "name": pluginApi?.tr("options.fontWeightNormal")
        },
        {
            "key": "medium",
            "name": pluginApi?.tr("options.fontWeightMedium")
        },
        {
            "key": "semibold",
            "name": pluginApi?.tr("options.fontWeightSemibold")
        },
        {
            "key": "bold",
            "name": pluginApi?.tr("options.fontWeightBold")
        }
    ]
    readonly property var animationTypeModel: [
        {
            "key": "spring",
            "name": pluginApi?.tr("options.animationSpring")
        },
        {
            "key": "ease",
            "name": pluginApi?.tr("options.animationEase")
        },
        {
            "key": "linear",
            "name": pluginApi?.tr("options.animationLinear")
        },
        {
            "key": "smooth",
            "name": pluginApi?.tr("options.animationSmooth")
        }
    ]
    readonly property var workspaceIndicatorLabelModeModel: [
        {
            "key": "id",
            "name": pluginApi?.tr("options.workspaceIndicatorId")
        },
        {
            "key": "name",
            "name": pluginApi?.tr("options.workspaceIndicatorName")
        }
    ]
    readonly property var workspaceIndicatorPositionModel: [
        {
            "key": "left",
            "name": pluginApi?.tr("options.workspaceIndicatorLeft")
        },
        {
            "key": "right",
            "name": pluginApi?.tr("options.workspaceIndicatorRight")
        }
    ]
    readonly property var specialWorkspaceOverlayTextModeModel: [
        {
            "key": "stripped",
            "name": pluginApi?.tr("options.specialWorkspaceOverlayStripped")
        },
        {
            "key": "raw",
            "name": pluginApi?.tr("options.specialWorkspaceOverlayRaw")
        },
        {
            "key": "custom",
            "name": pluginApi?.tr("options.specialWorkspaceOverlayCustom")
        }
    ]
    readonly property var pinnedAppsPositionModel: [
        {
            "key": "left",
            "name": pluginApi?.tr("options.pinnedAppsLeft")
        },
        {
            "key": "right",
            "name": pluginApi?.tr("options.pinnedAppsRight")
        }
    ]
    readonly property var pinnedAppsActivateBehaviorModel: [
        {
            "key": "focusCycle",
            "name": pluginApi?.tr("options.pinnedAppsFocusCycle")
        },
        {
            "key": "startNew",
            "name": pluginApi?.tr("options.pinnedAppsStartNew")
        }
    ]
    readonly property var axisModel: [
        {
            "key": "horizontal",
            "name": pluginApi?.tr("options.axisHorizontal")
        },
        {
            "key": "vertical",
            "name": pluginApi?.tr("options.axisVertical")
        }
    ]
    readonly property var gradientDirectionModel: [
        {
            "key": "vertical",
            "name": pluginApi?.tr("options.gradientVertical")
        },
        {
            "key": "horizontal",
            "name": pluginApi?.tr("options.gradientHorizontal")
        }
    ]
    spacing: Style.marginM
    implicitWidth: preferredWidth

    function deepCopy(value) {
        try {
            return JSON.parse(JSON.stringify(value || ({})));
        } catch (error) {
            return ({});
        }
    }

    function createSettingsSnapshot(primary, secondary) {
        const base = deepCopy(secondary || ({}));
        const overrides = deepCopy(primary || ({}));
        delete base._presets;
        delete base._activePresetId;
        delete overrides._presets;
        delete overrides._activePresetId;

        function merge(target, source) {
            for (const key in source) {
                const value = source[key];
                if (value && typeof value === "object" && !Array.isArray(value)) {
                    if (!target[key] || typeof target[key] !== "object" || Array.isArray(target[key]))
                        target[key] = {};
                    merge(target[key], value);
                } else {
                    target[key] = value;
                }
            }
            return target;
        }

        return normalizeSettingsSnapshot(merge(base, overrides));
    }

    function presetSettingsSnapshot(settings) {
        const next = normalizeSettingsSnapshot(deepCopy(settings || ({})));
        delete next.customStyleRules;
        return next;
    }

    function clampOpacity(value, fallbackValue) {
        const numericValue = Number(value);
        if (isNaN(numericValue))
            return fallbackValue;
        return Math.max(0, Math.min(1, numericValue));
    }

    function normalizeOpacityValue(value, fallbackValue) {
        const numericValue = Number(value);
        if (isNaN(numericValue))
            return fallbackValue;
        if (numericValue > 1)
            return clampOpacity(numericValue / 100, fallbackValue);
        return clampOpacity(numericValue, fallbackValue);
    }

    function normalizeColorSetting(settingValue, fallbackColor, fallbackOpacity) {
        const normalized = ({});
        const currentValue = (settingValue && typeof settingValue === "object" && !Array.isArray(settingValue)) ? settingValue : ({});
        normalized.color = currentValue.color ?? fallbackColor;
        normalized.opacity = normalizeOpacityValue(currentValue.opacity, fallbackOpacity);
        return normalized;
    }

    function normalizeColorStateMap(settingValue, fallbackMap, fallbackOpacity, defaultEnabled) {
        const normalized = ({});
        const currentValue = (settingValue && typeof settingValue === "object" && !Array.isArray(settingValue)) ? settingValue : ({});
        const opacityValue = fallbackOpacity === undefined ? 1 : fallbackOpacity;
        const enabledByDefault = defaultEnabled !== false;

        for (const key in fallbackMap) {
            const currentState = currentValue[key];
            normalized[key] = normalizeColorSetting(
                currentState,
                fallbackMap[key],
                opacityValue
            );
            normalized[key].enabled = currentState?.enabled === undefined ? enabledByDefault : currentState.enabled === true;
        }

        return normalized;
    }

    function normalizeCustomStyleRule(rule) {
        const source = (rule && typeof rule === "object" && !Array.isArray(rule)) ? rule : ({});
        return {
            "enabled": source.enabled !== false,
            "matchField": normalizeStyleRuleMatchField(source.matchField),
            "pattern": String(source.pattern || ""),
            "customIcon": String(source.customIcon || ""),
            "colors": {
                "segment": normalizeColorStateMap(
                    source.colors?.segment,
                    {
                        "focused": "primary",
                        "hover": "hover",
                        "default": "surface-variant"
                    },
                    undefined,
                    false
                ),
                "icon": normalizeColorStateMap(
                    source.colors?.icon,
                    {
                        "focused": "on-surface",
                        "hover": "on-hover",
                        "default": "on-surface-variant"
                    },
                    undefined,
                    false
                ),
                "title": normalizeColorStateMap(
                    source.colors?.title,
                    {
                        "focused": "on-surface",
                        "hover": "on-hover",
                        "default": "on-surface-variant"
                    },
                    undefined,
                    false
                )
            },
            "blink": {
                "enabled": source.blink?.enabled === true,
                "color": normalizeColorSetting(source.blink?.color, "primary", 1),
                "interval": Math.max(200, Math.min(5000, Number(source.blink?.interval ?? 800)))
            },
            "badge": {
                "enabled": source.badge?.enabled === true,
                "color": normalizeColorSetting(source.badge?.color, "error", 1),
                "size": Math.max(2, Math.min(16, Number(source.badge?.size ?? 6))),
                "target": normalizeBadgeTarget(source.badge?.target),
                "position": normalizeBadgePosition(source.badge?.position)
            },
            "iconPrefix": {
                "enabled": source.iconPrefix?.enabled === true,
                "icon": String(source.iconPrefix?.icon || ""),
                "target": normalizePrefixTarget(source.iconPrefix?.target),
                "color": normalizeColorSetting(source.iconPrefix?.color, "on-surface-variant", 1)
            }
        };
    }

    function normalizeOptionalAnimationOverrideValue(value, normalizer) {
        if (value === undefined || value === null || value === "")
            return null;
        return normalizer(value);
    }

    function normalizeSettingsSnapshot(settings) {
        const migrated = Migrations.migrateSettings(settings || ({}));
        const next = deepCopy(migrated.settings);
        if (!next.display)
            next.display = ({});
        if (!next.track)
            next.track = ({});
        if (!next.focusLine)
            next.focusLine = ({});
        next.display.spaceMode = "reserve";

        next.display.background = normalizeColorSetting(
            next.display.background,
            "none",
            0
        );
        next.display.gradient = normalizeColorSetting(
            next.display.gradient,
            "none",
            0
        );
        next.display.autoHide = next.display.autoHide && typeof next.display.autoHide === "object" && !Array.isArray(next.display.autoHide) ? next.display.autoHide : ({});
        next.display.autoHide.enabled = next.display.autoHide.enabled === true;
        if (["edgeSliver", "hoverZone"].indexOf(String(next.display.autoHide.revealMode || "")) < 0)
            next.display.autoHide.revealMode = "edgeSliver";
        next.display.autoHide.delayMs = Math.max(0, Math.min(5000, Math.round(Number(next.display.autoHide.delayMs ?? 1000))));
        next.display.autoHide.durationMs = Math.max(0, Math.min(1500, Math.round(Number(next.display.autoHide.durationMs ?? 200))));
        if (["slideFade", "slide", "fade", "instant"].indexOf(String(next.display.autoHide.effect || "")) < 0)
            next.display.autoHide.effect = "slideFade";
        next.display.autoHide.dynamicMargin = next.display.autoHide.dynamicMargin === true;
        if (["auto", "up", "down", "left", "right"].indexOf(String(next.display.autoHide.slideDirection || "")) < 0)
            next.display.autoHide.slideDirection = "auto";
        next.display.autoHide.edgeSliverSize = Math.max(2, Math.min(48, Math.round(Number(next.display.autoHide.edgeSliverSize ?? 8))));
        next.display.autoHide.edgeSliverWidth = Math.max(10, Math.min(100, Math.round(Number(next.display.autoHide.edgeSliverWidth ?? 100))));
        next.display.autoHide.edgeSliverMargin = Math.max(0, Math.min(64, Math.round(Number(next.display.autoHide.edgeSliverMargin ?? 0))));
        next.display.autoHide.edgeSliverRadius = Math.max(0, Math.min(64, Math.round(Number(next.display.autoHide.edgeSliverRadius ?? 0))));
        if (next.display.autoHide.edgeSliverColor === undefined || next.display.autoHide.edgeSliverColor === null || next.display.autoHide.edgeSliverColor === "")
            next.display.autoHide.edgeSliverColor = "none";
        next.display.autoHide.edgeSliverOpacity = normalizeOpacityValue(next.display.autoHide.edgeSliverOpacity, 1);
        next.track.fill = normalizeColorSetting(
            next.track.fill,
            "surface",
            1
        );
        next.track.edgeFade = next.track.edgeFade && typeof next.track.edgeFade === "object" && !Array.isArray(next.track.edgeFade) ? next.track.edgeFade : ({});
        next.track.edgeFade.leftEnabled = next.track.edgeFade.leftEnabled === true;
        next.track.edgeFade.rightEnabled = next.track.edgeFade.rightEnabled === true;
        next.track.edgeFade.width = isNaN(Number(next.track.edgeFade.width)) ? 24 : Math.max(0, Math.min(120, Math.round(Number(next.track.edgeFade.width))));
        next.focusLine.colors = normalizeColorStateMap(
            next.focusLine.colors,
            {
                "focused": "primary",
                "hover": "hover",
                "default": "surface-variant"
            }
        );
        next.focusLine.width = Math.max(1, Math.min(100, Number(next.focusLine.width ?? 100)));
        next.focusLine.lineColor = normalizeColorSetting(
            next.focusLine.lineColor,
            "primary",
            1
        );
        next.window = next.window && typeof next.window === "object" && !Array.isArray(next.window) ? next.window : ({});
        next.window.dragReorderEnabled = next.window.dragReorderEnabled !== false;
        next.window.iconColors = normalizeColorStateMap(
            next.window.iconColors,
            {
                "focused": "on-surface",
                "hover": "on-hover",
                "default": "on-surface-variant"
            }
        );
        next.window.titleColors = normalizeColorStateMap(
            next.window.titleColors,
            {
                "focused": "on-surface",
                "hover": "on-hover",
                "default": "on-surface-variant"
            }
        );
        next.focusLine.opacity = normalizeOpacityValue(next.focusLine.opacity, 1);
        next.animation = next.animation && typeof next.animation === "object" && !Array.isArray(next.animation) ? next.animation : ({});
        if (["spring", "ease", "linear", "smooth"].indexOf(next.animation.type) < 0)
            next.animation.type = "spring";
        next.animation.speed = Math.max(50, Math.min(1500, Math.round(Number(next.animation.speed ?? 420))));
        next.workspaceIndicator = next.workspaceIndicator && typeof next.workspaceIndicator === "object" && !Array.isArray(next.workspaceIndicator) ? next.workspaceIndicator : ({});
        if (["id", "name"].indexOf(next.workspaceIndicator.labelMode) < 0)
            next.workspaceIndicator.labelMode = "id";
        if (["left", "right"].indexOf(next.workspaceIndicator.position) < 0)
            next.workspaceIndicator.position = "left";
        if (["top", "center", "bottom"].indexOf(next.workspaceIndicator.verticalAlign) < 0)
            next.workspaceIndicator.verticalAlign = "center";
        next.workspaceIndicator.background = normalizeColorSetting(next.workspaceIndicator.background, "surface", 0.72);
        next.workspaceIndicator.font = next.workspaceIndicator.font && typeof next.workspaceIndicator.font === "object" && !Array.isArray(next.workspaceIndicator.font) ? next.workspaceIndicator.font : ({});
        next.workspaceIndicator.font.color = normalizeColorSetting(next.workspaceIndicator.font.color, "on-surface", 1);
        next.workspaceIndicator.badge = next.workspaceIndicator.badge && typeof next.workspaceIndicator.badge === "object" && !Array.isArray(next.workspaceIndicator.badge) ? next.workspaceIndicator.badge : ({});
        next.workspaceIndicator.badge.background = normalizeColorSetting(next.workspaceIndicator.badge.background, "primary", 1);
        next.workspaceIndicator.badge.font = next.workspaceIndicator.badge.font && typeof next.workspaceIndicator.badge.font === "object" && !Array.isArray(next.workspaceIndicator.badge.font) ? next.workspaceIndicator.badge.font : ({});
        next.workspaceIndicator.badge.font.color = normalizeColorSetting(next.workspaceIndicator.badge.font.color, "on-primary", 1);
        next.workspaceIndicator.animation = next.workspaceIndicator.animation && typeof next.workspaceIndicator.animation === "object" && !Array.isArray(next.workspaceIndicator.animation) ? next.workspaceIndicator.animation : ({});
        if (["horizontal", "vertical"].indexOf(next.workspaceIndicator.animation.axis) < 0)
            next.workspaceIndicator.animation.axis = "horizontal";
        if (["spring", "ease", "linear", "smooth"].indexOf(next.workspaceIndicator.animation.type) < 0)
            next.workspaceIndicator.animation.type = "smooth";
        next.workspaceIndicator.animation.speed = Math.max(50, Math.min(1500, Math.round(Number(next.workspaceIndicator.animation.speed ?? 220))));
        next.specialWorkspaceOverlay = next.specialWorkspaceOverlay && typeof next.specialWorkspaceOverlay === "object" && !Array.isArray(next.specialWorkspaceOverlay) ? next.specialWorkspaceOverlay : ({});
        if (["stripped", "raw", "custom"].indexOf(next.specialWorkspaceOverlay.textMode) < 0)
            next.specialWorkspaceOverlay.textMode = "stripped";
        next.specialWorkspaceOverlay.showWindowIcons = next.specialWorkspaceOverlay.showWindowIcons === true;
        next.specialWorkspaceOverlay.widthPercent = Math.max(50, Math.min(100, Number(next.specialWorkspaceOverlay.widthPercent ?? 100)));
        next.specialWorkspaceOverlay.heightPercent = Math.max(50, Math.min(100, Number(next.specialWorkspaceOverlay.heightPercent ?? 70)));
        if (next.specialWorkspaceOverlay.borderRadius !== undefined && next.specialWorkspaceOverlay.borderRadius !== null && next.specialWorkspaceOverlay.borderRadius !== "" && !isNaN(Number(next.specialWorkspaceOverlay.borderRadius)))
            next.specialWorkspaceOverlay.borderRadius = Math.max(0, Math.min(24, Math.round(Number(next.specialWorkspaceOverlay.borderRadius))));
        else
            next.specialWorkspaceOverlay.borderRadius = null;
        next.specialWorkspaceOverlay.background = normalizeColorSetting(next.specialWorkspaceOverlay.background, "surface", 0.82);
        next.specialWorkspaceOverlay.font = next.specialWorkspaceOverlay.font && typeof next.specialWorkspaceOverlay.font === "object" && !Array.isArray(next.specialWorkspaceOverlay.font) ? next.specialWorkspaceOverlay.font : ({});
        next.specialWorkspaceOverlay.font.color = normalizeColorSetting(next.specialWorkspaceOverlay.font.color, "on-surface", 1);
        next.specialWorkspaceOverlay.animation = next.specialWorkspaceOverlay.animation && typeof next.specialWorkspaceOverlay.animation === "object" && !Array.isArray(next.specialWorkspaceOverlay.animation) ? next.specialWorkspaceOverlay.animation : ({});
        next.specialWorkspaceOverlay.animation.enabled = normalizeOptionalAnimationOverrideValue(next.specialWorkspaceOverlay.animation.enabled, function (value) {
            return value !== false;
        });
        next.specialWorkspaceOverlay.animation.axis = normalizeOptionalAnimationOverrideValue(next.specialWorkspaceOverlay.animation.axis, function (value) {
            return ["horizontal", "vertical"].indexOf(String(value)) >= 0 ? String(value) : "vertical";
        });
        next.specialWorkspaceOverlay.animation.type = normalizeOptionalAnimationOverrideValue(next.specialWorkspaceOverlay.animation.type, function (value) {
            return ["spring", "ease", "linear", "smooth"].indexOf(String(value)) >= 0 ? String(value) : "spring";
        });
        next.specialWorkspaceOverlay.animation.speed = normalizeOptionalAnimationOverrideValue(next.specialWorkspaceOverlay.animation.speed, function (value) {
            const numericValue = Number(value);
            return Math.max(50, Math.min(1500, Math.round(isNaN(numericValue) ? 420 : numericValue)));
        });
        next.window.animation = next.window.animation && typeof next.window.animation === "object" && !Array.isArray(next.window.animation) ? next.window.animation : ({});
        next.window.animation.enabled = normalizeOptionalAnimationOverrideValue(next.window.animation.enabled, function (value) {
            return value !== false;
        });
        next.window.animation.openEnabled = next.window.animation.openEnabled !== false;
        next.window.animation.closeEnabled = next.window.animation.closeEnabled !== false;
        next.window.animation.type = normalizeOptionalAnimationOverrideValue(next.window.animation.type, function (value) {
            return ["spring", "ease", "linear", "smooth"].indexOf(String(value)) >= 0 ? String(value) : "spring";
        });
        next.window.animation.speed = normalizeOptionalAnimationOverrideValue(next.window.animation.speed, function (value) {
            const numericValue = Number(value);
            return Math.max(50, Math.min(1500, Math.round(isNaN(numericValue) ? 420 : numericValue)));
        });
        next.pinnedApps = next.pinnedApps && typeof next.pinnedApps === "object" && !Array.isArray(next.pinnedApps) ? next.pinnedApps : ({});
        if (["left", "right"].indexOf(next.pinnedApps.position) < 0)
            next.pinnedApps.position = "left";
        if (["focusCycle", "startNew"].indexOf(next.pinnedApps.activateRunningBehavior) < 0)
            next.pinnedApps.activateRunningBehavior = "focusCycle";
        if (next.pinnedApps.iconColor === undefined || next.pinnedApps.iconColor === null || next.pinnedApps.iconColor === "")
            next.pinnedApps.iconColor = "on-surface";
        next.pinnedApps.items = Array.isArray(next.pinnedApps.items) ? next.pinnedApps.items.map(function (item) {
            return {
                "appId": String(item?.appId || ""),
                "customIcon": String(item?.customIcon || "")
            };
        }).filter(function (item) {
            return item.appId !== "";
        }) : [];
        next.customStyleRules = Array.isArray(next.customStyleRules) ? next.customStyleRules.map(normalizeCustomStyleRule) : [];

        return next;
    }

    function normalizeStyleRuleMatchField(matchField) {
        switch (String(matchField || "")) {
        case "title":
        case "tag":
        case "floating":
        case "urgent":
        case "grouped":
        case "sharedAppId":
        case "sharedTitle":
            return String(matchField);
        default:
            return "appId";
        }
    }

    function normalizeBadgeTarget(target) {
        switch (String(target || "")) {
        case "title":
        case "segment":
            return String(target);
        default:
            return "icon";
        }
    }

    function normalizeBadgePosition(position) {
        switch (String(position || "")) {
        case "top-left":
            return "top-left";
        default:
            return "top-right";
        }
    }

    function normalizePrefixTarget(target) {
        switch (String(target || "")) {
        case "title":
            return "title";
        default:
            return "icon";
        }
    }

    function suggestedPatternForMatchField(matchField) {
        switch (normalizeStyleRuleMatchField(matchField)) {
        case "title":
            return "YouTube";
        case "tag":
            return "code";
        case "floating":
        case "urgent":
        case "grouped":
        case "sharedAppId":
        case "sharedTitle":
            return ".+";
        default:
            return "^firefox$";
        }
    }

    function styleRulePatternPlaceholder(matchField) {
        return suggestedPatternForMatchField(matchField);
    }

    function styleRuleAllowsEmptyPattern(matchField) {
        switch (normalizeStyleRuleMatchField(matchField)) {
        case "tag":
        case "floating":
        case "urgent":
        case "grouped":
        case "sharedAppId":
        case "sharedTitle":
            return true;
        default:
            return false;
        }
    }

    function settingValue(groupKey, nestedKey) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function nestedSettingValue(groupKey, nestedGroupKey, nestedKey) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        const nestedGroup = group ? group[nestedGroupKey] : undefined;
        return nestedGroup ? nestedGroup[nestedKey] : undefined;
    }

    function objectSettingValue(groupKey, objectKey, nestedKey) {
        return nestedSettingValue(groupKey, objectKey, nestedKey);
    }

    function stateSettingValue(groupKey, objectKey, stateKey, nestedKey) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        const objectGroup = group ? group[objectKey] : undefined;
        const stateGroup = objectGroup ? objectGroup[stateKey] : undefined;
        return stateGroup ? stateGroup[nestedKey] : undefined;
    }

    function defaultValue(groupKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function defaultNestedValue(groupKey, nestedGroupKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        const nestedGroup = group ? group[nestedGroupKey] : undefined;
        return nestedGroup ? nestedGroup[nestedKey] : undefined;
    }

    function defaultObjectValue(groupKey, objectKey, nestedKey) {
        return defaultNestedValue(groupKey, objectKey, nestedKey);
    }

    function defaultStateValue(groupKey, objectKey, stateKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        const objectGroup = group ? group[objectKey] : undefined;
        const stateGroup = objectGroup ? objectGroup[stateKey] : undefined;
        return stateGroup ? stateGroup[nestedKey] : undefined;
    }

    function setSetting(groupKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        next[groupKey][nestedKey] = value;
        editSettings = next;
        _activePresetId = "";
    }

    function setNestedSetting(groupKey, nestedGroupKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        if (!next[groupKey][nestedGroupKey])
            next[groupKey][nestedGroupKey] = ({});
        next[groupKey][nestedGroupKey][nestedKey] = value;
        editSettings = next;
        _activePresetId = "";
    }

    function setObjectSetting(groupKey, objectKey, nestedKey, value) {
        setNestedSetting(groupKey, objectKey, nestedKey, value);
    }

    function setStateSetting(groupKey, objectKey, stateKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        if (!next[groupKey][objectKey])
            next[groupKey][objectKey] = ({});
        if (!next[groupKey][objectKey][stateKey])
            next[groupKey][objectKey][stateKey] = ({});
        next[groupKey][objectKey][stateKey][nestedKey] = value;
        editSettings = next;
        _activePresetId = "";
    }

    function conditionValue(key) {
        switch (key) {
        case "floatingPanelMode":
            return (settingValue("display", "mode") ?? "floatingPanel") === "floatingPanel";
        case "autoHideEnabled":
            return nestedSettingValue("display", "autoHide", "enabled") ?? false;
        case "autoHideSlideEffect": {
            const effect = nestedSettingValue("display", "autoHide", "effect") ?? "slideFade";
            return effect === "slideFade" || effect === "slide";
        }
        case "autoHideAnimatedEffect":
            return (nestedSettingValue("display", "autoHide", "effect") ?? "slideFade") !== "instant";
        case "autoHideEdgeSliverMode":
            return (nestedSettingValue("display", "autoHide", "revealMode") ?? "edgeSliver") === "edgeSliver";
        case "displayGradientEnabled":
            return settingValue("display", "gradientEnabled") ?? false;
        case "workspaceIndicatorEnabled":
            return settingValue("workspaceIndicator", "enabled") ?? false;
        case "workspaceIndicatorBadgeEnabled":
            return nestedSettingValue("workspaceIndicator", "badge", "enabled") ?? false;
        case "workspaceIndicatorAnimationEnabled":
            return nestedSettingValue("workspaceIndicator", "animation", "enabled") ?? true;
        case "specialWorkspaceOverlayEnabled":
            return settingValue("specialWorkspaceOverlay", "enabled") ?? false;
        case "specialWorkspaceOverlayCustomMode":
            return (settingValue("specialWorkspaceOverlay", "textMode") ?? "stripped") === "custom";
        case "specialWorkspaceOverlayAnimationEnabled": {
            const override = nestedSettingValue("specialWorkspaceOverlay", "animation", "enabled");
            if (override !== undefined && override !== null)
                return override !== false;
            return settingValue("animation", "enabled") ?? true;
        }
        case "windowAnimationEnabled": {
            const override = nestedSettingValue("window", "animation", "enabled");
            if (override !== undefined && override !== null)
                return override !== false;
            return settingValue("animation", "enabled") ?? true;
        }
        case "pinnedAppsEnabled":
            return pinnedAppItems().length > 0;
        case "showIcons":
            return settingValue("window", "showIcon") ?? true;
        case "showTitle":
            return settingValue("window", "showTitle") ?? true;
        case "focusedOnly":
            return settingValue("window", "focusedOnly") ?? false;
        default:
            return true;
        }
    }

    function isVisibleByConditions(conditions) {
        if (!conditions || conditions.length === 0)
            return true;

        for (let i = 0; i < conditions.length; i++) {
            if (!conditionValue(conditions[i]))
                return false;
        }

        return true;
    }

    function applyPreset(settingsObj, presetId) {
        const nextSettings = createSettingsSnapshot(settingsObj, defaults);
        nextSettings.customStyleRules = styleRuleItems().map(normalizeCustomStyleRule);
        editSettings = nextSettings;
        styleRulesRevision += 1;
        _activePresetId = presetId || "";
    }

    function refreshEditSettings() {
        defaultSettings = normalizeSettingsSnapshot(deepCopy(defaults));
        editSettings = createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults);
        styleRulesRevision += 1;
        _activePresetId = pluginApi?.pluginSettings?._activePresetId || "";
    }

    function pinnedAppItems() {
        return Array.isArray(editSettings?.pinnedApps?.items) ? editSettings.pinnedApps.items : [];
    }

    function defaultPinnedAppItems() {
        return Array.isArray(defaultSettings?.pinnedApps?.items) ? defaultSettings.pinnedApps.items : [];
    }

    function setPinnedAppItems(items) {
        const next = deepCopy(editSettings);
        if (!next.pinnedApps || typeof next.pinnedApps !== "object" || Array.isArray(next.pinnedApps))
            next.pinnedApps = ({});
        next.pinnedApps.items = Array.isArray(items) ? items : [];
        editSettings = next;
        _activePresetId = "";
    }

    function setPinnedAppCustomIcon(appId, customIcon) {
        const nextItems = pinnedAppItems().map(function (item) {
            if (item?.appId !== appId)
                return item;
            return {
                "appId": appId,
                "customIcon": String(customIcon || "")
            };
        });
        setPinnedAppItems(nextItems);
    }

    function removePinnedApp(appId) {
        setPinnedAppItems(pinnedAppItems().filter(function (item) {
            return item?.appId !== appId;
        }));
    }

    function styleRuleItems() {
        const rules = editSettings?.customStyleRules;
        return Array.isArray(rules) ? rules.slice() : [];
    }

    function styleRuleColorStatePanelKey(index, colorGroup, stateKey) {
        return [String(index), String(colorGroup), String(stateKey)].join(":");
    }

    function isStyleRuleColorStatePanelExpanded(index, colorGroup, stateKey) {
        return expandedStyleRuleOpacityPanels?.[styleRuleColorStatePanelKey(index, colorGroup, stateKey)] === true;
    }

    function setStyleRuleColorStatePanelExpanded(index, colorGroup, stateKey, expanded) {
        const key = styleRuleColorStatePanelKey(index, colorGroup, stateKey);
        const next = Object.assign({}, expandedStyleRuleOpacityPanels);
        if (expanded)
            next[key] = true;
        else
            delete next[key];
        expandedStyleRuleOpacityPanels = next;
    }

    function defaultStyleRuleItems() {
        return Array.isArray(defaultSettings?.customStyleRules) ? defaultSettings.customStyleRules : [];
    }

    function currentGlobalStyleRuleColors() {
        return {
            "segment": normalizeColorStateMap(
                editSettings?.focusLine?.colors,
                {
                    "focused": "primary",
                    "hover": "hover",
                    "default": "surface-variant"
                },
                undefined,
                false
            ),
            "icon": normalizeColorStateMap(
                editSettings?.window?.iconColors,
                {
                    "focused": "on-surface",
                    "hover": "on-hover",
                    "default": "on-surface-variant"
                },
                undefined,
                false
            ),
            "title": normalizeColorStateMap(
                editSettings?.window?.titleColors,
                {
                    "focused": "on-surface",
                    "hover": "on-hover",
                    "default": "on-surface-variant"
                },
                undefined,
                false
            )
        };
    }

    function createEmptyStyleRule() {
        return normalizeCustomStyleRule({
            "enabled": true,
            "matchField": "appId",
            "pattern": "",
            "colors": currentGlobalStyleRuleColors()
        });
    }

    function setStyleRuleItems(items) {
        const next = deepCopy(editSettings);
        next.customStyleRules = Array.isArray(items) ? items.map(normalizeCustomStyleRule) : [];
        editSettings = next;
        styleRulesRevision += 1;
        _activePresetId = "";
    }

    function addStyleRule() {
        const nextItems = styleRuleItems().slice();
        nextItems.push(createEmptyStyleRule());
        setStyleRuleItems(nextItems);
    }

    function updateStyleRule(index, patch) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = styleRuleItems().slice();
        nextItems[index] = normalizeCustomStyleRule(Object.assign({}, nextItems[index] || ({}), patch || ({})));
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleColorState(index, colorGroup, stateKey, nestedKey, value) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        if (!nextItems[index].colors)
            nextItems[index].colors = ({});
        if (!nextItems[index].colors[colorGroup])
            nextItems[index].colors[colorGroup] = ({});
        if (!nextItems[index].colors[colorGroup][stateKey])
            nextItems[index].colors[colorGroup][stateKey] = ({});
        nextItems[index].colors[colorGroup][stateKey][nestedKey] = value;
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleBlink(index, patch) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        const currentBlink = nextItems[index]?.blink || ({});
        nextItems[index].blink = Object.assign({}, currentBlink, patch || ({}));
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleBlinkColor(index, nestedKey, value) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        if (!nextItems[index].blink)
            nextItems[index].blink = ({});
        if (!nextItems[index].blink.color)
            nextItems[index].blink.color = ({});
        nextItems[index].blink.color[nestedKey] = value;
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleBadge(index, patch) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        const currentBadge = nextItems[index]?.badge || ({});
        nextItems[index].badge = Object.assign({}, currentBadge, patch || ({}));
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleBadgeColor(index, nestedKey, value) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        if (!nextItems[index].badge)
            nextItems[index].badge = ({});
        if (!nextItems[index].badge.color)
            nextItems[index].badge.color = ({});
        nextItems[index].badge.color[nestedKey] = value;
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleIconPrefix(index, patch) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        const currentPrefix = nextItems[index]?.iconPrefix || ({});
        nextItems[index].iconPrefix = Object.assign({}, currentPrefix, patch || ({}));
        setStyleRuleItems(nextItems);
    }

    function updateStyleRuleIconPrefixColor(index, nestedKey, value) {
        if (index < 0 || index >= styleRuleItems().length)
            return;

        const nextItems = deepCopy(styleRuleItems());
        if (!nextItems[index].iconPrefix)
            nextItems[index].iconPrefix = ({});
        if (!nextItems[index].iconPrefix.color)
            nextItems[index].iconPrefix.color = ({});
        nextItems[index].iconPrefix.color[nestedKey] = value;
        setStyleRuleItems(nextItems);
    }

    function moveStyleRule(index, direction) {
        const nextIndex = index + direction;
        const nextItems = styleRuleItems().slice();
        if (index < 0 || index >= nextItems.length || nextIndex < 0 || nextIndex >= nextItems.length)
            return;

        const swapped = nextItems[index];
        nextItems[index] = nextItems[nextIndex];
        nextItems[nextIndex] = swapped;
        setStyleRuleItems(nextItems);
    }

    function removeStyleRule(index) {
        setStyleRuleItems(styleRuleItems().filter(function (_item, itemIndex) {
            return itemIndex !== index;
        }));
    }

    function isValidRegex(pattern) {
        const text = String(pattern || "").trim();
        if (text === "")
            return true;

        try {
            new RegExp(text);
            return true;
        } catch (error) {
            return false;
        }
    }

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshEditSettings();
        }
    }

    Connections {
        target: mainInstance

        function onRequestedStyleRuleRevisionChanged() {
            root.selectedTab = 3;
        }
    }

    Component.onCompleted: {
        refreshEditSettings();
        // Handle navigation that was triggered before this instance was loaded
        if (mainInstance?.requestedStyleRuleNavigationPending ?? false) {
            root.selectedTab = 3;
            mainInstance.requestedStyleRuleNavigationPending = false;
        }
    }

    NTabBar {
        currentIndex: selectedTab
        Layout.fillWidth: true
        distributeEvenly: true

        Repeater {
            model: root.tabModel

            delegate: NTabButton {
                required property int index
                required property var modelData

                text: modelData.label
                icon: modelData.icon
                tabIndex: index
                checked: root.selectedTab === index
                onClicked: root.selectedTab = index
            }
        }
    }

    NTabView {
        currentIndex: selectedTab
        Layout.fillWidth: true

        LayoutSettingsTab {
            rootSettings: root
        }

        AppearanceSettingsTab {
            rootSettings: root
        }

        PinnedAppsSettingsTab {
            rootSettings: root
        }

        StyleRulesSettingsTab {
            rootSettings: root
        }

        PresetsSettingsTab {
            rootSettings: root
        }
    }

    function saveSettings() {
        if (!pluginApi)
            return;

        const normalized = normalizeSettingsSnapshot(editSettings);
        normalized.customStyleRules = normalized.customStyleRules.filter(function (rule) {
            return root.styleRuleAllowsEmptyPattern(rule?.matchField) || String(rule?.pattern || "").trim() !== "";
        });
        normalized._presets = deepCopy(pluginApi.pluginSettings._presets || []);
        normalized._activePresetId = _activePresetId;
        pluginApi.pluginSettings = normalized;
        pluginApi.saveSettings();
    }
}
