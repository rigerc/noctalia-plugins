import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

NValueSlider {
    id: root

    property var rootSettings: null
    property string settingPath: ""
    property string unit: "px"
    property var visibilityConditions: []
    property var disabledConditions: []
    property bool showAutoAtZero: false

    readonly property bool _isDisabled: rootSettings ? rootSettings.isDisabledByConditions(disabledConditions) : false
    readonly property string _autoText: rootSettings?.pluginApi?.tr("common.auto") ?? "Auto"

    Layout.fillWidth: true
    enabled: !_isDisabled
    opacity: _isDisabled ? 0.4 : 1.0
    visible: rootSettings ? rootSettings.isVisibleByConditions(visibilityConditions) : true
    showReset: true

    value: {
        const v = rootSettings ? rootSettings.getPath(settingPath) : 0;
        return v !== undefined ? v : 0;
    }

    text: {
        if (showAutoAtZero && value <= 0)
            return _autoText;
        if (unit === "%" || unit === "ms" || unit === "pt" || unit === "px")
            return Math.round(value) + " " + unit;
        return Math.round(value) + " " + unit;
    }

    defaultValue: rootSettings ? rootSettings.getDefault(settingPath) : undefined

    onMoved: sliderValue => {
        if (!rootSettings) return;
        if (stepSize < 1)
            rootSettings.setPath(settingPath, Math.round(sliderValue * 100) / 100);
        else
            rootSettings.setPath(settingPath, Math.round(sliderValue));
    }
}
