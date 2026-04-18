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
            "key": "fade",
            "name": pluginApi?.tr("options.animationFade")
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

    function normalizeSettingsSnapshot(settings) {
        const next = deepCopy(settings || ({}));
        if (!next.display)
            next.display = ({});
        next.display.spaceMode = "reserve";
        if (next.track && next.track.height !== undefined)
            delete next.track.height;
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

    function defaultValue(groupKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function defaultNestedValue(groupKey, nestedGroupKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        const nestedGroup = group ? group[nestedGroupKey] : undefined;
        return nestedGroup ? nestedGroup[nestedKey] : undefined;
    }

    function setSetting(groupKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        next[groupKey][nestedKey] = value;
        editSettings = next;
    }

    function setNestedSetting(groupKey, nestedGroupKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        if (!next[groupKey][nestedGroupKey])
            next[groupKey][nestedGroupKey] = ({});
        next[groupKey][nestedGroupKey][nestedKey] = value;
        editSettings = next;
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

    function refreshEditSettings() {
        defaultSettings = normalizeSettingsSnapshot(deepCopy(defaults));
        editSettings = createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults);
    }

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshEditSettings();
        }
    }

    Component.onCompleted: refreshEditSettings()

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

    function saveSettings() {
        if (!pluginApi)
            return;

        pluginApi.pluginSettings = normalizeSettingsSnapshot(editSettings);
        pluginApi.saveSettings();
    }
}
