import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "."

ColumnLayout {
    id: root

    property var rootSettings: null
    property string settingPath: ""
    property bool showEnabledToggles: true
    property var defaultColors: ({
        "focused": "primary",
        "hover": "hover",
        "default": "surface-variant"
    })
    property real defaultOpacity: 1
    property bool defaultEnabled: true
    property var visibilityConditions: []
    property var disabledConditions: []

    property bool styleRuleMode: false
    property var ruleData: null
    property int ruleIndex: -1
    property string styleRuleColorGroup: ""

    readonly property var _states: ["focused", "hover", "default"]
    readonly property bool _isDisabled: rootSettings ? rootSettings.isDisabledByConditions(disabledConditions) : false

    visible: rootSettings ? rootSettings.isVisibleByConditions(visibilityConditions) : true
    enabled: !_isDisabled
    opacity: _isDisabled ? 0.4 : 1.0
    spacing: Style.marginS

    function _getLabelKey(stateKey) {
        if (styleRuleMode)
            return "settings.customStyleRules." + styleRuleColorGroup + "Colors." + stateKey;
        if (settingPath.indexOf("focusLine") === 0)
            return "settings.focusLine.colors." + stateKey;
        if (settingPath.indexOf("window.iconColors") === 0)
            return "settings.window.iconColors." + stateKey;
        if (settingPath.indexOf("window.titleColors") === 0)
            return "settings.window.titleColors." + stateKey;
        return "";
    }

    Repeater {
        model: root._states

        delegate: ColumnLayout {
            id: stateBlock

            required property string modelData
            required property int index

            readonly property string stateKey: modelData

            readonly property var _ruleState: root.ruleData?.colors?.[root.styleRuleColorGroup]?.[stateKey]
            readonly property bool _ruleEnabled: _ruleState ? _ruleState.enabled === true : false
            readonly property string _ruleColor: _ruleState ? (_ruleState.color ?? (root.defaultColors[stateKey] || "surface-variant")) : (root.defaultColors[stateKey] || "surface-variant")
            readonly property real _ruleOpacity: _ruleState ? (_ruleState.opacity ?? root.defaultOpacity) : root.defaultOpacity

            readonly property string _colorPath: root.settingPath + "." + stateKey
            readonly property bool _normalEnabled: root.rootSettings ? (root.rootSettings.getPath(_colorPath + ".enabled") ?? root.defaultEnabled) : root.defaultEnabled
            readonly property string _normalColor: root.rootSettings ? (root.rootSettings.getPath(_colorPath + ".color") ?? (root.defaultColors[stateKey] || "surface-variant")) : (root.defaultColors[stateKey] || "surface-variant")
            readonly property real _normalOpacity: root.rootSettings ? (root.rootSettings.getPath(_colorPath + ".opacity") ?? root.defaultOpacity) : root.defaultOpacity

            readonly property bool stateEnabled: root.styleRuleMode ? _ruleEnabled : _normalEnabled
            readonly property string stateColor: root.styleRuleMode ? _ruleColor : _normalColor
            readonly property real stateOpacity: root.styleRuleMode ? _ruleOpacity : _normalOpacity
            readonly property var stateDefaultColor: {
                if (root.styleRuleMode)
                    return root.defaultColors[stateKey] || "surface-variant";
                return root.rootSettings ? root.rootSettings.getDefault(_colorPath + ".color") : undefined;
            }
            readonly property var stateDefaultOpacity: {
                if (root.styleRuleMode)
                    return root.defaultOpacity;
                return root.rootSettings ? root.rootSettings.getDefault(_colorPath + ".opacity") : undefined;
            }

            spacing: Style.marginS

            NToggle {
                visible: root.showEnabledToggles
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr(root._getLabelKey(stateKey) + ".enabled.label") ?? ""
                description: root.rootSettings?.pluginApi?.tr(root._getLabelKey(stateKey) + ".enabled.desc") ?? ""
                checked: stateBlock.stateEnabled
                defaultValue: root.defaultEnabled
                onToggled: checked => {
                    if (root.styleRuleMode) {
                        if (root.rootSettings)
                            root.rootSettings.updateStyleRuleColorState(root.ruleIndex, root.styleRuleColorGroup, stateKey, "enabled", checked);
                    } else {
                        if (root.rootSettings)
                            root.rootSettings.setPath(root.settingPath + "." + stateKey + ".enabled", checked);
                    }
                }
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: stateBlock.stateEnabled
                opacity: stateBlock.stateEnabled ? 1.0 : 0.4

                label: root.rootSettings?.pluginApi?.tr(root._getLabelKey(stateKey) + ".label") ?? ""
                description: root.rootSettings?.pluginApi?.tr(root._getLabelKey(stateKey) + ".desc") ?? ""
                currentColor: stateBlock.stateColor
                defaultColor: stateBlock.stateDefaultColor
                currentOpacity: stateBlock.stateOpacity
                defaultOpacity: stateBlock.stateDefaultOpacity
                showOpacityControl: true

                opacityExpandedControlled: root.styleRuleMode
                opacityExpanded: root.styleRuleMode ? (root.rootSettings?.isStyleRuleColorStatePanelExpanded(root.ruleIndex, root.styleRuleColorGroup, stateKey) ?? false) : false
                onOpacityExpandedToggled: expanded => {
                    if (root.styleRuleMode && root.rootSettings)
                        root.rootSettings.setStyleRuleColorStatePanelExpanded(root.ruleIndex, root.styleRuleColorGroup, stateKey, expanded);
                }

                onColorSelected: value => {
                    if (root.styleRuleMode) {
                        if (root.rootSettings)
                            root.rootSettings.updateStyleRuleColorState(root.ruleIndex, root.styleRuleColorGroup, stateKey, "color", value);
                    } else {
                        if (root.rootSettings)
                            root.rootSettings.setPath(root.settingPath + "." + stateKey + ".color", value);
                    }
                }
                onOpacitySelected: value => {
                    if (root.styleRuleMode) {
                        if (root.rootSettings)
                            root.rootSettings.updateStyleRuleColorState(root.ruleIndex, root.styleRuleColorGroup, stateKey, "opacity", value);
                    } else {
                        if (root.rootSettings)
                            root.rootSettings.setPath(root.settingPath + "." + stateKey + ".opacity", value);
                    }
                }
            }
        }
    }
}
