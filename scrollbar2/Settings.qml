import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "./settings"

ColumnLayout {
    id: root

    property var pluginApi: null
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property var defaultSettings: normalizeSettingsSnapshot(deepCopy(defaults))
    property var editSettings: createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults)
    property real preferredWidth: 760 * Style.uiScaleRatio
    property int selectedTab: 0
    property string _activePresetId: pluginApi?.pluginSettings?._activePresetId || ""

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

    function normalizeColorSetting(settingValue, legacyColorValue, legacyOpacityValue, fallbackColor, fallbackOpacity) {
        const normalized = ({});
        const currentValue = (settingValue && typeof settingValue === "object" && !Array.isArray(settingValue)) ? settingValue : ({});
        normalized.color = currentValue.color ?? legacyColorValue ?? fallbackColor;
        normalized.opacity = normalizeOpacityValue(currentValue.opacity ?? legacyOpacityValue, fallbackOpacity);
        return normalized;
    }

    function normalizeColorStateMap(settingValue, fallbackMap, fallbackOpacity) {
        const normalized = ({});
        const currentValue = (settingValue && typeof settingValue === "object" && !Array.isArray(settingValue)) ? settingValue : ({});
        const opacityValue = fallbackOpacity === undefined ? 1 : fallbackOpacity;

        for (const key in fallbackMap) {
            const currentState = currentValue[key];
            normalized[key] = normalizeColorSetting(
                currentState,
                currentState,
                undefined,
                fallbackMap[key],
                opacityValue
            );
        }

        return normalized;
    }

    function normalizeSettingsSnapshot(settings) {
        const next = deepCopy(settings || ({}));
        if (!next.display)
            next.display = ({});
        if (!next.track)
            next.track = ({});
        if (!next.focusLine)
            next.focusLine = ({});
        next.display.spaceMode = "reserve";
        if (next.track && next.track.height !== undefined)
            delete next.track.height;
        if (next.animation && next.animation.type !== undefined)
            delete next.animation.type;

        next.display.background = normalizeColorSetting(
            next.display.background,
            next.display.backgroundColor,
            next.display.backgroundOpacity,
            "none",
            0
        );
        next.display.gradient = normalizeColorSetting(
            next.display.gradient,
            next.display.gradientColor,
            next.display.gradientOpacity,
            "none",
            0
        );
        next.track.fill = normalizeColorSetting(
            next.track.fill,
            next.track.color,
            next.track.opacity,
            "surface",
            1
        );
        next.focusLine.colors = normalizeColorStateMap(
            next.focusLine.colors,
            {
                "focused": "primary",
                "hover": "hover",
                "default": "surface-variant"
            }
        );
        next.window = next.window && typeof next.window === "object" && !Array.isArray(next.window) ? next.window : ({});
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

        delete next.display.backgroundColor;
        delete next.display.backgroundOpacity;
        delete next.display.gradientColor;
        delete next.display.gradientOpacity;
        delete next.track.color;
        delete next.track.opacity;
        return next;
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
        case "displayGradientEnabled":
            return settingValue("display", "gradientEnabled") ?? false;
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
        editSettings = createSettingsSnapshot(settingsObj, defaults);
        _activePresetId = presetId || "";
    }

    function refreshEditSettings() {
        defaultSettings = normalizeSettingsSnapshot(deepCopy(defaults));
        editSettings = createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults);
        _activePresetId = pluginApi?.pluginSettings?._activePresetId || "";
    }

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshEditSettings();
        }
    }

    Component.onCompleted: refreshEditSettings()

    NTabBar {
        currentIndex: selectedTab
        Layout.fillWidth: true

        NTabButton {
            text: pluginApi?.tr("settings.tabs.settings") ?? "Settings"
            tabIndex: 0
            checked: selectedTab === 0
            onClicked: selectedTab = 0
        }

        NTabButton {
            text: pluginApi?.tr("settings.tabs.presets") ?? "Presets"
            tabIndex: 1
            checked: selectedTab === 1
            onClicked: selectedTab = 1
        }
    }

    NTabView {
        currentIndex: selectedTab
        Layout.fillWidth: true

        ColumnLayout {
            spacing: Style.marginM

            NText {
                text: pluginApi?.tr("settings.summary")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            DisplaySettingsSection {
                Layout.fillWidth: true
                rootSettings: root
            }

            WindowSettingsSection {
                Layout.fillWidth: true
                rootSettings: root
            }

            ColorSettingsSection {
                Layout.fillWidth: true
                rootSettings: root
            }

            BehaviorSettingsSection {
                Layout.fillWidth: true
                rootSettings: root
            }
        }

        PresetsSection {
            rootSettings: root
        }
    }

    function saveSettings() {
        if (!pluginApi)
            return;

        const normalized = normalizeSettingsSnapshot(editSettings);
        normalized._presets = deepCopy(pluginApi.pluginSettings._presets || []);
        normalized._activePresetId = _activePresetId;
        pluginApi.pluginSettings = normalized;
        pluginApi.saveSettings();
    }
}
