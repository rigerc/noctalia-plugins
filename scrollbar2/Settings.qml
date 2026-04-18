import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property var editSettings: deepCopy(pluginApi?.pluginSettings || defaults || ({}))
    property real preferredWidth: 760 * Style.uiScaleRatio
    property string valueDisplayBackgroundColor: "none"
    property string valueDisplayGradientColor: "none"
    property string valueTrackColor: "#16161f"
    property string valueTrackBorderColor: "#2a2a42"
    property string valueFocusLineFocusedColor: "#00e5ff"
    property string valueFocusLineHoverColor: "#1a2a36"
    property string valueFocusLineDefaultColor: "#12121e"
    property string valueWindowFont: "JetBrains Mono"
    property string valueWindowIconFocusedColor: "#ffffff"
    property string valueWindowIconHoverColor: "#9090b8"
    property string valueWindowIconDefaultColor: "#404060"
    property string valueWindowTitleFocusedColor: "#ffffff"
    property string valueWindowTitleHoverColor: "#9090b8"
    property string valueWindowTitleDefaultColor: "#404060"

    readonly property var displayModeModel: [
        { "key": "floatingPanel", "name": pluginApi?.tr("options.displayModeFloatingPanel") },
        { "key": "bar", "name": pluginApi?.tr("options.displayModeBar") }
    ]
    readonly property var spaceModeModel: [
        { "key": "overlay", "name": pluginApi?.tr("options.spaceModeOverlay") },
        { "key": "reserve", "name": pluginApi?.tr("options.spaceModeReserve") }
    ]
    readonly property var trackPositionModel: [
        { "key": "top", "name": pluginApi?.tr("options.trackPositionTop") },
        { "key": "bottom", "name": pluginApi?.tr("options.trackPositionBottom") }
    ]
    readonly property var focusAlignModel: [
        { "key": "segment", "name": pluginApi?.tr("options.focusAlignSegment") },
        { "key": "center", "name": pluginApi?.tr("options.focusAlignCenter") },
        { "key": "left", "name": pluginApi?.tr("options.focusAlignLeft") },
        { "key": "right", "name": pluginApi?.tr("options.focusAlignRight") }
    ]
    readonly property var focusVerticalModel: [
        { "key": "top", "name": pluginApi?.tr("options.verticalAlignTop") },
        { "key": "center", "name": pluginApi?.tr("options.verticalAlignCenter") },
        { "key": "bottom", "name": pluginApi?.tr("options.verticalAlignBottom") }
    ]
    readonly property var animationTypeModel: [
        { "key": "spring", "name": pluginApi?.tr("options.animationSpring") },
        { "key": "ease", "name": pluginApi?.tr("options.animationEase") },
        { "key": "linear", "name": pluginApi?.tr("options.animationLinear") },
        { "key": "fade", "name": pluginApi?.tr("options.animationFade") }
    ]
    readonly property var gradientDirectionModel: [
        { "key": "vertical", "name": pluginApi?.tr("options.gradientVertical") },
        { "key": "horizontal", "name": pluginApi?.tr("options.gradientHorizontal") }
    ]

    spacing: Style.marginL
    implicitWidth: preferredWidth

    function deepCopy(value) {
        try {
            return JSON.parse(JSON.stringify(value || ({})));
        } catch (error) {
            return ({});
        }
    }

    function valueFor(groupKey, nestedKey, fallbackValue) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        if (group && group[nestedKey] !== undefined)
            return group[nestedKey];
        const defaultGroup = defaults ? defaults[groupKey] : undefined;
        if (defaultGroup && defaultGroup[nestedKey] !== undefined)
            return defaultGroup[nestedKey];
        return fallbackValue;
    }

    function nestedValue(groupKey, nestedGroupKey, nestedKey, fallbackValue) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        const nestedGroup = group ? group[nestedGroupKey] : undefined;
        if (nestedGroup && nestedGroup[nestedKey] !== undefined)
            return nestedGroup[nestedKey];
        const defaultGroup = defaults ? defaults[groupKey] : undefined;
        const defaultNestedGroup = defaultGroup ? defaultGroup[nestedGroupKey] : undefined;
        if (defaultNestedGroup && defaultNestedGroup[nestedKey] !== undefined)
            return defaultNestedGroup[nestedKey];
        return fallbackValue;
    }

    function setSetting(groupKey, nestedKey, value) {
        const nextSettings = deepCopy(editSettings);
        if (!nextSettings[groupKey])
            nextSettings[groupKey] = {};
        nextSettings[groupKey][nestedKey] = value;
        editSettings = nextSettings;
    }

    function setNestedSetting(groupKey, nestedGroupKey, nestedKey, value) {
        const nextSettings = deepCopy(editSettings);
        if (!nextSettings[groupKey])
            nextSettings[groupKey] = {};
        if (!nextSettings[groupKey][nestedGroupKey])
            nextSettings[groupKey][nestedGroupKey] = {};
        nextSettings[groupKey][nestedGroupKey][nestedKey] = value;
        editSettings = nextSettings;
    }

    function resetFromPlugin() {
        editSettings = deepCopy(pluginApi?.pluginSettings || defaults || ({}));
        valueDisplayBackgroundColor = String(valueFor("display", "backgroundColor", "none"));
        valueDisplayGradientColor = String(valueFor("display", "gradientColor", "none"));
        valueTrackColor = String(valueFor("track", "color", "#16161f"));
        valueTrackBorderColor = String(valueFor("track", "borderColor", "#2a2a42"));
        valueFocusLineFocusedColor = String(nestedValue("focusLine", "colors", "focused", "#00e5ff"));
        valueFocusLineHoverColor = String(nestedValue("focusLine", "colors", "hover", "#1a2a36"));
        valueFocusLineDefaultColor = String(nestedValue("focusLine", "colors", "default", "#12121e"));
        valueWindowFont = String(valueFor("window", "font", "JetBrains Mono"));
        valueWindowIconFocusedColor = String(nestedValue("window", "iconColors", "focused", "#ffffff"));
        valueWindowIconHoverColor = String(nestedValue("window", "iconColors", "hover", "#9090b8"));
        valueWindowIconDefaultColor = String(nestedValue("window", "iconColors", "default", "#404060"));
        valueWindowTitleFocusedColor = String(nestedValue("window", "titleColors", "focused", "#ffffff"));
        valueWindowTitleHoverColor = String(nestedValue("window", "titleColors", "hover", "#9090b8"));
        valueWindowTitleDefaultColor = String(nestedValue("window", "titleColors", "default", "#404060"));
    }

    function syncTextInput(input, value) {
        if (!input)
            return;
        const nextValue = String(value);
        if (input.text !== nextValue)
            input.text = nextValue;
    }

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.resetFromPlugin();
        }
    }

    Component.onCompleted: resetFromPlugin()

    NText {
        text: pluginApi?.tr("settings.summary")
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    NDivider {
        Layout.fillWidth: true
    }

    NText {
        text: pluginApi?.tr("settings.sections.display")
        font.weight: Style.fontWeightBold
        Layout.fillWidth: true
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.display.mode.label")
        description: pluginApi?.tr("settings.display.mode.desc")
        model: displayModeModel
        currentKey: valueFor("display", "mode", "floatingPanel")
        onSelected: key => root.setSetting("display", "mode", key)
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.display.spaceMode.label")
        description: pluginApi?.tr("settings.display.spaceMode.desc")
        model: spaceModeModel
        currentKey: valueFor("display", "spaceMode", "overlay")
        onSelected: key => root.setSetting("display", "spaceMode", key)
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.scale.label")
        description: pluginApi?.tr("settings.display.scale.desc")
        from: 0.5
        to: 2.0
        stepSize: 0.05
        value: valueFor("display", "scale", 1.0)
        text: value.toFixed(2) + "x"
        onMoved: value => root.setSetting("display", "scale", Number(value.toFixed(2)))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.margin.label")
        description: pluginApi?.tr("settings.display.margin.desc")
        from: 0
        to: 48
        stepSize: 1
        value: valueFor("display", "margin", 0)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("display", "margin", Math.round(value))
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.offsetH.label")
        description: pluginApi?.tr("settings.display.offsetH.desc")
        from: -200
        to: 200
        stepSize: 1
        value: valueFor("display", "offsetH", 0)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("display", "offsetH", Math.round(value))
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.offsetV.label")
        description: pluginApi?.tr("settings.display.offsetV.desc")
        from: -200
        to: 200
        stepSize: 1
        value: valueFor("display", "offsetV", 0)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("display", "offsetV", Math.round(value))
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.radiusScale.label")
        description: pluginApi?.tr("settings.display.radiusScale.desc")
        from: 0
        to: 3
        stepSize: 0.05
        value: valueFor("display", "radiusScale", 1.0)
        text: value.toFixed(2) + "x"
        onMoved: value => root.setSetting("display", "radiusScale", Number(value.toFixed(2)))
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NTextInput {
        id: displayBackgroundColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.display.backgroundColor.label")
        description: pluginApi?.tr("settings.display.backgroundColor.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(displayBackgroundColorInput, root.valueDisplayBackgroundColor)
        onTextChanged: {
            root.valueDisplayBackgroundColor = text;
            root.setSetting("display", "backgroundColor", text);
        }
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.backgroundOpacity.label")
        description: pluginApi?.tr("settings.display.backgroundOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: valueFor("display", "backgroundOpacity", 0)
        text: Math.round(value) + "%"
        onMoved: value => root.setSetting("display", "backgroundOpacity", Math.round(value))
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NToggle {
        label: pluginApi?.tr("settings.display.gradientEnabled.label")
        description: pluginApi?.tr("settings.display.gradientEnabled.desc")
        checked: valueFor("display", "gradientEnabled", false)
        onToggled: checked => root.setSetting("display", "gradientEnabled", checked)
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel"
    }

    NTextInput {
        id: displayGradientColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.display.gradientColor.label")
        description: pluginApi?.tr("settings.display.gradientColor.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(displayGradientColorInput, root.valueDisplayGradientColor)
        onTextChanged: {
            root.valueDisplayGradientColor = text;
            root.setSetting("display", "gradientColor", text);
        }
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel" && valueFor("display", "gradientEnabled", false)
    }

    NValueSlider {
        label: pluginApi?.tr("settings.display.gradientOpacity.label")
        description: pluginApi?.tr("settings.display.gradientOpacity.desc")
        from: 0
        to: 100
        stepSize: 1
        value: valueFor("display", "gradientOpacity", 0)
        text: Math.round(value) + "%"
        onMoved: value => root.setSetting("display", "gradientOpacity", Math.round(value))
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel" && valueFor("display", "gradientEnabled", false)
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.display.gradientDirection.label")
        description: pluginApi?.tr("settings.display.gradientDirection.desc")
        model: gradientDirectionModel
        currentKey: valueFor("display", "gradientDirection", "vertical")
        onSelected: key => root.setSetting("display", "gradientDirection", key)
        visible: valueFor("display", "mode", "floatingPanel") === "floatingPanel" && valueFor("display", "gradientEnabled", false)
    }

    NToggle {
        label: pluginApi?.tr("settings.filtering.sameOutput.label")
        description: pluginApi?.tr("settings.filtering.sameOutput.desc")
        checked: valueFor("filtering", "onlySameOutput", true)
        onToggled: checked => root.setSetting("filtering", "onlySameOutput", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.filtering.activeWorkspaces.label")
        description: pluginApi?.tr("settings.filtering.activeWorkspaces.desc")
        checked: valueFor("filtering", "onlyActiveWorkspaces", true)
        onToggled: checked => root.setSetting("filtering", "onlyActiveWorkspaces", checked)
    }

    NDivider {
        Layout.fillWidth: true
    }

    NText {
        text: pluginApi?.tr("settings.sections.track")
        font.weight: Style.fontWeightBold
        Layout.fillWidth: true
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.track.position.label")
        description: pluginApi?.tr("settings.track.position.desc")
        model: trackPositionModel
        currentKey: valueFor("track", "position", "bottom")
        onSelected: key => root.setSetting("track", "position", key)
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.width.label")
        description: pluginApi?.tr("settings.track.width.desc")
        from: 5
        to: 100
        stepSize: 1
        value: valueFor("track", "width", 90)
        text: Math.round(value) + "%"
        onMoved: value => root.setSetting("track", "width", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.height.label")
        description: pluginApi?.tr("settings.track.height.desc")
        from: 0
        to: 60
        stepSize: 1
        value: valueFor("track", "height", 0)
        text: Math.round(value) > 0 ? (Math.round(value) + "px") : pluginApi?.tr("settings.auto")
        onMoved: value => root.setSetting("track", "height", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.thickness.label")
        description: pluginApi?.tr("settings.track.thickness.desc")
        from: 1
        to: 40
        stepSize: 1
        value: valueFor("track", "thickness", 6)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("track", "thickness", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.segmentSpacing.label")
        description: pluginApi?.tr("settings.track.segmentSpacing.desc")
        from: 0
        to: 20
        stepSize: 1
        value: valueFor("track", "segmentSpacing", 4)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("track", "segmentSpacing", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.borderRadius.label")
        description: pluginApi?.tr("settings.track.borderRadius.desc")
        from: 0
        to: 24
        stepSize: 1
        value: valueFor("track", "borderRadius", 3)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("track", "borderRadius", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.opacity.label")
        description: pluginApi?.tr("settings.track.opacity.desc")
        from: 0
        to: 1
        stepSize: 0.01
        value: valueFor("track", "opacity", 1)
        text: Math.round(value * 100) + "%"
        onMoved: value => root.setSetting("track", "opacity", Number(value.toFixed(2)))
    }

    NTextInput {
        id: trackColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.track.color.label")
        description: pluginApi?.tr("settings.track.color.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(trackColorInput, root.valueTrackColor)
        onTextChanged: {
            root.valueTrackColor = text;
            root.setSetting("track", "color", text);
        }
    }

    NTextInput {
        id: trackBorderColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.track.borderColor.label")
        description: pluginApi?.tr("settings.track.borderColor.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(trackBorderColorInput, root.valueTrackBorderColor)
        onTextChanged: {
            root.valueTrackBorderColor = text;
            root.setSetting("track", "borderColor", text);
        }
    }

    NValueSlider {
        label: pluginApi?.tr("settings.track.borderWidth.label")
        description: pluginApi?.tr("settings.track.borderWidth.desc")
        from: 0
        to: 8
        stepSize: 1
        value: valueFor("track", "borderWidth", 1)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("track", "borderWidth", Math.round(value))
    }

    NToggle {
        label: pluginApi?.tr("settings.track.shadowEnabled.label")
        description: pluginApi?.tr("settings.track.shadowEnabled.desc")
        checked: valueFor("track", "shadowEnabled", true)
        onToggled: checked => root.setSetting("track", "shadowEnabled", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.track.borders.top.label")
        description: pluginApi?.tr("settings.track.borders.top.desc")
        checked: nestedValue("track", "borders", "top", false)
        onToggled: checked => root.setNestedSetting("track", "borders", "top", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.track.borders.right.label")
        description: pluginApi?.tr("settings.track.borders.right.desc")
        checked: nestedValue("track", "borders", "right", false)
        onToggled: checked => root.setNestedSetting("track", "borders", "right", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.track.borders.bottom.label")
        description: pluginApi?.tr("settings.track.borders.bottom.desc")
        checked: nestedValue("track", "borders", "bottom", false)
        onToggled: checked => root.setNestedSetting("track", "borders", "bottom", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.track.borders.left.label")
        description: pluginApi?.tr("settings.track.borders.left.desc")
        checked: nestedValue("track", "borders", "left", false)
        onToggled: checked => root.setNestedSetting("track", "borders", "left", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.track.borders.segment.label")
        description: pluginApi?.tr("settings.track.borders.segment.desc")
        checked: nestedValue("track", "borders", "segment", false)
        onToggled: checked => root.setNestedSetting("track", "borders", "segment", checked)
    }

    NDivider {
        Layout.fillWidth: true
    }

    NText {
        text: pluginApi?.tr("settings.sections.focusLine")
        font.weight: Style.fontWeightBold
        Layout.fillWidth: true
    }

    NValueSlider {
        label: pluginApi?.tr("settings.focusLine.thickness.label")
        description: pluginApi?.tr("settings.focusLine.thickness.desc")
        from: 1
        to: 40
        stepSize: 1
        value: valueFor("focusLine", "thickness", 6)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("focusLine", "thickness", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.focusLine.borderRadius.label")
        description: pluginApi?.tr("settings.focusLine.borderRadius.desc")
        from: 0
        to: 24
        stepSize: 1
        value: valueFor("focusLine", "borderRadius", 3)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("focusLine", "borderRadius", Math.round(value))
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.focusLine.verticalAlign.label")
        description: pluginApi?.tr("settings.focusLine.verticalAlign.desc")
        model: focusVerticalModel
        currentKey: valueFor("focusLine", "verticalAlign", "bottom")
        onSelected: key => root.setSetting("focusLine", "verticalAlign", key)
    }

    NValueSlider {
        label: pluginApi?.tr("settings.focusLine.opacity.label")
        description: pluginApi?.tr("settings.focusLine.opacity.desc")
        from: 0
        to: 1
        stepSize: 0.01
        value: valueFor("focusLine", "opacity", 1)
        text: Math.round(value * 100) + "%"
        onMoved: value => root.setSetting("focusLine", "opacity", Number(value.toFixed(2)))
    }

    NToggle {
        label: pluginApi?.tr("settings.focusLine.shadowEnabled.label")
        description: pluginApi?.tr("settings.focusLine.shadowEnabled.desc")
        checked: valueFor("focusLine", "shadowEnabled", true)
        onToggled: checked => root.setSetting("focusLine", "shadowEnabled", checked)
    }

    NTextInput {
        id: focusLineFocusedColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.focusLine.colors.focused.label")
        description: pluginApi?.tr("settings.focusLine.colors.focused.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(focusLineFocusedColorInput, root.valueFocusLineFocusedColor)
        onTextChanged: {
            root.valueFocusLineFocusedColor = text;
            root.setNestedSetting("focusLine", "colors", "focused", text);
        }
    }

    NTextInput {
        id: focusLineHoverColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.focusLine.colors.hover.label")
        description: pluginApi?.tr("settings.focusLine.colors.hover.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(focusLineHoverColorInput, root.valueFocusLineHoverColor)
        onTextChanged: {
            root.valueFocusLineHoverColor = text;
            root.setNestedSetting("focusLine", "colors", "hover", text);
        }
    }

    NTextInput {
        id: focusLineDefaultColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.focusLine.colors.default.label")
        description: pluginApi?.tr("settings.focusLine.colors.default.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(focusLineDefaultColorInput, root.valueFocusLineDefaultColor)
        onTextChanged: {
            root.valueFocusLineDefaultColor = text;
            root.setNestedSetting("focusLine", "colors", "default", text);
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NText {
        text: pluginApi?.tr("settings.sections.window")
        font.weight: Style.fontWeightBold
        Layout.fillWidth: true
    }

    NToggle {
        label: pluginApi?.tr("settings.window.showIcon.label")
        description: pluginApi?.tr("settings.window.showIcon.desc")
        checked: valueFor("window", "showIcon", true)
        onToggled: checked => root.setSetting("window", "showIcon", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.window.showTitle.label")
        description: pluginApi?.tr("settings.window.showTitle.desc")
        checked: valueFor("window", "showTitle", true)
        onToggled: checked => root.setSetting("window", "showTitle", checked)
    }

    NToggle {
        label: pluginApi?.tr("settings.window.focusedOnly.label")
        description: pluginApi?.tr("settings.window.focusedOnly.desc")
        checked: valueFor("window", "focusedOnly", false)
        onToggled: checked => root.setSetting("window", "focusedOnly", checked)
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.focusedAlign.label")
        description: pluginApi?.tr("settings.window.focusedAlign.desc")
        model: focusAlignModel
        currentKey: valueFor("window", "focusedAlign", "segment")
        onSelected: key => root.setSetting("window", "focusedAlign", key)
        visible: valueFor("window", "focusedOnly", false)
    }

    NTextInput {
        id: windowFontInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.font.label")
        description: pluginApi?.tr("settings.window.font.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowFontInput, root.valueWindowFont)
        onTextChanged: {
            root.valueWindowFont = text;
            root.setSetting("window", "font", text);
        }
    }

    NValueSlider {
        label: pluginApi?.tr("settings.window.fontSize.label")
        description: pluginApi?.tr("settings.window.fontSize.desc")
        from: 8
        to: 24
        stepSize: 1
        value: valueFor("window", "fontSize", 11)
        text: Math.round(value) + "px"
        onMoved: value => root.setSetting("window", "fontSize", Math.round(value))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.window.iconScale.label")
        description: pluginApi?.tr("settings.window.iconScale.desc")
        from: 0.5
        to: 2.0
        stepSize: 0.05
        value: valueFor("window", "iconScale", 1.0)
        text: value.toFixed(2) + "x"
        onMoved: value => root.setSetting("window", "iconScale", Number(value.toFixed(2)))
    }

    NValueSlider {
        label: pluginApi?.tr("settings.window.titleScale.label")
        description: pluginApi?.tr("settings.window.titleScale.desc")
        from: 0.5
        to: 2.0
        stepSize: 0.05
        value: valueFor("window", "titleScale", 1.0)
        text: value.toFixed(2) + "x"
        onMoved: value => root.setSetting("window", "titleScale", Number(value.toFixed(2)))
    }

    NTextInput {
        id: windowIconFocusedColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.iconColors.focused.label")
        description: pluginApi?.tr("settings.window.iconColors.focused.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowIconFocusedColorInput, root.valueWindowIconFocusedColor)
        onTextChanged: {
            root.valueWindowIconFocusedColor = text;
            root.setNestedSetting("window", "iconColors", "focused", text);
        }
    }

    NTextInput {
        id: windowIconHoverColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.iconColors.hover.label")
        description: pluginApi?.tr("settings.window.iconColors.hover.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowIconHoverColorInput, root.valueWindowIconHoverColor)
        onTextChanged: {
            root.valueWindowIconHoverColor = text;
            root.setNestedSetting("window", "iconColors", "hover", text);
        }
    }

    NTextInput {
        id: windowIconDefaultColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.iconColors.default.label")
        description: pluginApi?.tr("settings.window.iconColors.default.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowIconDefaultColorInput, root.valueWindowIconDefaultColor)
        onTextChanged: {
            root.valueWindowIconDefaultColor = text;
            root.setNestedSetting("window", "iconColors", "default", text);
        }
    }

    NTextInput {
        id: windowTitleFocusedColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.titleColors.focused.label")
        description: pluginApi?.tr("settings.window.titleColors.focused.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowTitleFocusedColorInput, root.valueWindowTitleFocusedColor)
        onTextChanged: {
            root.valueWindowTitleFocusedColor = text;
            root.setNestedSetting("window", "titleColors", "focused", text);
        }
    }

    NTextInput {
        id: windowTitleHoverColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.titleColors.hover.label")
        description: pluginApi?.tr("settings.window.titleColors.hover.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowTitleHoverColorInput, root.valueWindowTitleHoverColor)
        onTextChanged: {
            root.valueWindowTitleHoverColor = text;
            root.setNestedSetting("window", "titleColors", "hover", text);
        }
    }

    NTextInput {
        id: windowTitleDefaultColorInput
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.window.titleColors.default.label")
        description: pluginApi?.tr("settings.window.titleColors.default.desc")
        text: ""
        Component.onCompleted: root.syncTextInput(windowTitleDefaultColorInput, root.valueWindowTitleDefaultColor)
        onTextChanged: {
            root.valueWindowTitleDefaultColor = text;
            root.setNestedSetting("window", "titleColors", "default", text);
        }
    }

    Connections {
        target: root

        function onValueDisplayBackgroundColorChanged() { root.syncTextInput(displayBackgroundColorInput, root.valueDisplayBackgroundColor); }
        function onValueDisplayGradientColorChanged() { root.syncTextInput(displayGradientColorInput, root.valueDisplayGradientColor); }
        function onValueTrackColorChanged() { root.syncTextInput(trackColorInput, root.valueTrackColor); }
        function onValueTrackBorderColorChanged() { root.syncTextInput(trackBorderColorInput, root.valueTrackBorderColor); }
        function onValueFocusLineFocusedColorChanged() { root.syncTextInput(focusLineFocusedColorInput, root.valueFocusLineFocusedColor); }
        function onValueFocusLineHoverColorChanged() { root.syncTextInput(focusLineHoverColorInput, root.valueFocusLineHoverColor); }
        function onValueFocusLineDefaultColorChanged() { root.syncTextInput(focusLineDefaultColorInput, root.valueFocusLineDefaultColor); }
        function onValueWindowFontChanged() { root.syncTextInput(windowFontInput, root.valueWindowFont); }
        function onValueWindowIconFocusedColorChanged() { root.syncTextInput(windowIconFocusedColorInput, root.valueWindowIconFocusedColor); }
        function onValueWindowIconHoverColorChanged() { root.syncTextInput(windowIconHoverColorInput, root.valueWindowIconHoverColor); }
        function onValueWindowIconDefaultColorChanged() { root.syncTextInput(windowIconDefaultColorInput, root.valueWindowIconDefaultColor); }
        function onValueWindowTitleFocusedColorChanged() { root.syncTextInput(windowTitleFocusedColorInput, root.valueWindowTitleFocusedColor); }
        function onValueWindowTitleHoverColorChanged() { root.syncTextInput(windowTitleHoverColorInput, root.valueWindowTitleHoverColor); }
        function onValueWindowTitleDefaultColorChanged() { root.syncTextInput(windowTitleDefaultColorInput, root.valueWindowTitleDefaultColor); }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NText {
        text: pluginApi?.tr("settings.sections.animation")
        font.weight: Style.fontWeightBold
        Layout.fillWidth: true
    }

    NToggle {
        label: pluginApi?.tr("settings.animation.enabled.label")
        description: pluginApi?.tr("settings.animation.enabled.desc")
        checked: valueFor("animation", "enabled", true)
        onToggled: checked => root.setSetting("animation", "enabled", checked)
    }

    NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.animation.type.label")
        description: pluginApi?.tr("settings.animation.type.desc")
        model: animationTypeModel
        currentKey: valueFor("animation", "type", "spring")
        onSelected: key => root.setSetting("animation", "type", key)
    }

    NValueSlider {
        label: pluginApi?.tr("settings.animation.speed.label")
        description: pluginApi?.tr("settings.animation.speed.desc")
        from: 50
        to: 1500
        stepSize: 25
        value: valueFor("animation", "speed", 420)
        text: Math.round(value) + "ms"
        onMoved: value => root.setSetting("animation", "speed", Math.round(value))
    }

    function saveSettings() {
        if (!pluginApi)
            return;

        pluginApi.pluginSettings = deepCopy(editSettings);
        pluginApi.saveSettings();
    }
}
