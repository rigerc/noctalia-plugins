import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "."

HybridColorChoice {
    id: root

    property var rootSettings: null
    property string settingPath: ""
    property bool colorOnly: false
    property string separateOpacityPath: ""
    property var visibilityConditions: []
    property var disabledConditions: []

    readonly property bool _isDisabled: rootSettings ? rootSettings.isDisabledByConditions(disabledConditions) : false
    readonly property bool _hasSeparateOpacity: separateOpacityPath !== ""

    enabled: !_isDisabled
    visible: rootSettings ? rootSettings.isVisibleByConditions(visibilityConditions) : true
    Layout.fillWidth: true

    currentColor: {
        if (!rootSettings) return "";
        if (colorOnly) return rootSettings.getPath(settingPath) ?? "";
        return rootSettings.getPath(settingPath + ".color") ?? "";
    }

    defaultColor: {
        if (!rootSettings) return undefined;
        if (colorOnly || _hasSeparateOpacity) return rootSettings.getDefault(settingPath);
        return rootSettings.getDefault(settingPath + ".color");
    }

    currentOpacity: {
        if (!rootSettings) return 1;
        if (colorOnly) return 1;
        if (_hasSeparateOpacity) return rootSettings.getPath(separateOpacityPath) ?? 1;
        return rootSettings.getPath(settingPath + ".opacity") ?? 1;
    }

    defaultOpacity: {
        if (!rootSettings || colorOnly) return undefined;
        if (_hasSeparateOpacity) return rootSettings.getDefault(separateOpacityPath);
        return rootSettings.getDefault(settingPath + ".opacity");
    }

    showOpacityControl: !colorOnly

    onColorSelected: value => {
        if (!rootSettings) return;
        if (colorOnly || _hasSeparateOpacity) {
            rootSettings.setPath(settingPath, value);
        } else {
            rootSettings.setPath(settingPath + ".color", value);
        }
    }

    onOpacitySelected: value => {
        if (!rootSettings || colorOnly) return;
        if (_hasSeparateOpacity) {
            rootSettings.setPath(separateOpacityPath, value);
        } else {
            rootSettings.setPath(settingPath + ".opacity", value);
        }
    }
}
