import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "."

ColumnLayout {
    id: root

    property var rootSettings: null
    property string settingPath: ""
    property string keyPrefix: ""
    property bool showAutoForZero: false
    property var visibilityConditions: []
    property var disabledConditions: []

    readonly property bool _isDisabled: rootSettings ? rootSettings.isDisabledByConditions(disabledConditions) : false

    function _tr(suffix) {
        return rootSettings?.pluginApi?.tr(keyPrefix + suffix) ?? "";
    }

    visible: rootSettings ? rootSettings.isVisibleByConditions(visibilityConditions) : true
    enabled: !_isDisabled
    opacity: _isDisabled ? 0.4 : 1.0
    spacing: Style.marginS

    NSearchableComboBox {
        Layout.fillWidth: true
        label: root._tr(".family.label")
        description: root._tr(".family.desc")
        model: FontService.availableFonts
        currentKey: root.rootSettings ? (root.rootSettings.getPath(settingPath + ".family") ?? "") : ""
        defaultValue: root.rootSettings ? (root.rootSettings.getDefault(settingPath + ".family") ?? "") : ""
        onSelected: key => {
            if (root.rootSettings) root.rootSettings.setPath(settingPath + ".family", key);
        }
    }

    SettingsSlider {
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".size"
        from: 0; to: 24; stepSize: 1
        unit: "pt"
        showAutoAtZero: root.showAutoForZero
        label: root._tr(".size.label")
        description: root._tr(".size.desc")
    }

    SettingsComboBox {
        rootSettings: root.rootSettings
        settingPath: root.settingPath + ".weight"
        modelSource: root.rootSettings?.fontWeightModel
        label: root._tr(".weight.label")
        description: root._tr(".weight.desc")
    }

    SettingsColorField {
        rootSettings: root.rootSettings
        pluginApi: root.rootSettings?.pluginApi
        settingPath: root.settingPath + ".color"
        label: root._tr(".color.label")
        description: root._tr(".color.desc")
    }
}
