import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "."

ColumnLayout {
    id: root

    property var rootSettings: null
    property string settingPath: ""
    property string keyPrefix: ""
    property bool showAxis: false
    property bool showOpenClose: false
    property string fallbackPath: ""
    property int defaultSpeed: 420
    property var visibilityConditions: []
    property var disabledConditions: []

    readonly property bool _isDisabled: rootSettings ? rootSettings.isDisabledByConditions(disabledConditions) : false
    readonly property bool _animEnabled: {
        const override = rootSettings ? rootSettings.getPath(settingPath + ".enabled") : undefined;
        if (override !== undefined && override !== null) return override !== false;
        if (fallbackPath) {
            const fallback = rootSettings ? rootSettings.getPath(fallbackPath + ".enabled") : undefined;
            return fallback !== false;
        }
        return true;
    }

    function _tr(suffix) {
        return rootSettings?.pluginApi?.tr(keyPrefix + suffix) ?? "";
    }

    visible: rootSettings ? rootSettings.isVisibleByConditions(visibilityConditions) : true
    enabled: !_isDisabled
    opacity: _isDisabled ? 0.4 : 1.0
    spacing: Style.marginS

    SettingsToggle {
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".enabled"
        label: root._tr(".enabled.label")
        description: root._tr(".enabled.desc")
    }

    SettingsToggle {
        visible: root.showOpenClose
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".openEnabled"
        label: root._tr(".openEnabled.label")
        description: root._tr(".openEnabled.desc")
        visibilityConditions: root._animEnabled ? [] : ["__never__"]
    }

    SettingsToggle {
        visible: root.showOpenClose
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".closeEnabled"
        label: root._tr(".closeEnabled.label")
        description: root._tr(".closeEnabled.desc")
        visibilityConditions: root._animEnabled ? [] : ["__never__"]
    }

    SettingsComboBox {
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".type"
        modelSource: root.rootSettings?.animationTypeModel
        label: root._tr(".type.label")
        description: root._tr(".type.desc")
        visibilityConditions: root._animEnabled ? [] : ["__never__"]
    }

    SettingsComboBox {
        visible: root.showAxis
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".axis"
        modelSource: root.rootSettings?.axisModel
        label: root._tr(".axis.label")
        description: root._tr(".axis.desc")
        visibilityConditions: root._animEnabled ? [] : ["__never__"]
    }

    SettingsSlider {
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".speed"
        from: 50; to: 1500; stepSize: 25
        unit: "ms"
        defaultValue: root.defaultSpeed
        label: root._tr(".speed.label")
        description: root._tr(".speed.desc")
        visibilityConditions: root._animEnabled ? [] : ["__never__"]
    }
}
