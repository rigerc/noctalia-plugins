import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

NToggle {
    id: root

    property var rootSettings: null
    property string settingPath: ""
    property var visibilityConditions: []
    property var disabledConditions: []

    readonly property bool _isDisabled: rootSettings ? rootSettings.isDisabledByConditions(disabledConditions) : false

    Layout.fillWidth: true
    enabled: !_isDisabled
    opacity: _isDisabled ? 0.4 : 1.0
    visible: rootSettings ? rootSettings.isVisibleByConditions(visibilityConditions) : true

    checked: rootSettings ? (rootSettings.getPath(settingPath) ?? false) : false
    defaultValue: rootSettings ? rootSettings.getDefault(settingPath) : false

    onToggled: checked => {
        if (rootSettings) rootSettings.setPath(settingPath, checked);
    }
}
