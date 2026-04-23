import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property string label: pluginApi?.tr("settings.colorPicker.label")
    property string description: pluginApi?.tr("settings.colorPicker.desc")
    property string currentColor: ""
    property var defaultColor: undefined
    property real currentOpacity: 1
    property var defaultOpacity: undefined
    property bool showOpacityControl: false
    property bool opacityExpandedControlled: false
    property bool opacityExpanded: false
    property real opacityFrom: 0
    property real opacityTo: 1
    property real opacityStepSize: 0.01

    readonly property bool colorChanged: (defaultColor !== undefined) && !sameValue(currentColor, defaultColor)
    readonly property bool opacityChanged: showOpacityControl && defaultOpacity !== undefined && !sameNumber(currentOpacity, defaultOpacity)
    readonly property bool isValueChanged: colorChanged || opacityChanged
    readonly property string indicatorTooltip: defaultSummary()
    readonly property int diameter: Math.round(Style.baseWidgetSize * 0.9 * Style.uiScaleRatio)
    readonly property bool customSelected: isCustomColor(currentColor)
    readonly property color customPreviewColor: resolveColor(customSelected ? currentColor : "surface", Color.mSurface)
    property bool _localOpacityExpanded: opacityExpanded
    readonly property bool effectiveOpacityExpanded: opacityExpandedControlled ? opacityExpanded : _localOpacityExpanded
    readonly property var preferredColorOptions: [
        {
            "key": "none",
            "name": pluginApi?.tr("settings.colorOptions.none")
        },
        {
            "key": "primary",
            "name": pluginApi?.tr("settings.colorOptions.primary")
        },
        {
            "key": "secondary",
            "name": pluginApi?.tr("settings.colorOptions.secondary")
        },
        {
            "key": "tertiary",
            "name": pluginApi?.tr("settings.colorOptions.tertiary")
        },
        {
            "key": "surface",
            "name": pluginApi?.tr("settings.colorOptions.surface")
        },
        {
            "key": "error",
            "name": pluginApi?.tr("settings.colorOptions.error")
        }
    ]
    readonly property var legacyColorOptions: [
        {
            "key": "on-primary",
            "name": pluginApi?.tr("settings.colorOptions.onPrimary")
        },
        {
            "key": "on-secondary",
            "name": pluginApi?.tr("settings.colorOptions.onSecondary")
        },
        {
            "key": "on-tertiary",
            "name": pluginApi?.tr("settings.colorOptions.onTertiary")
        },
        {
            "key": "on-error",
            "name": pluginApi?.tr("settings.colorOptions.onError")
        },
        {
            "key": "on-surface",
            "name": pluginApi?.tr("settings.colorOptions.onSurface")
        },
        {
            "key": "surface-variant",
            "name": pluginApi?.tr("settings.colorOptions.surfaceVariant")
        },
        {
            "key": "on-surface-variant",
            "name": pluginApi?.tr("settings.colorOptions.onSurfaceVariant")
        },
        {
            "key": "outline",
            "name": pluginApi?.tr("settings.colorOptions.outline")
        },
        {
            "key": "hover",
            "name": pluginApi?.tr("settings.colorOptions.hover")
        },
        {
            "key": "on-hover",
            "name": pluginApi?.tr("settings.colorOptions.onHover")
        }
    ]
    readonly property var visibleColorOptions: buildVisibleColorOptions()

    signal colorSelected(string value)
    signal opacitySelected(real value)
    signal opacityExpandedToggled(bool expanded)

    Layout.fillWidth: true
    spacing: Style.marginM

    function sameValue(left, right) {
        if (left === undefined || right === undefined)
            return left === right;

        return String(left).toLowerCase() === String(right).toLowerCase();
    }

    function sameNumber(left, right) {
        if (left === undefined || right === undefined)
            return left === right;

        return Math.abs(Number(left) - Number(right)) < 0.0001;
    }

    function isThemeColorKey(value) {
        switch (value) {
        case "none":
        case "primary":
        case "on-primary":
        case "secondary":
        case "on-secondary":
        case "tertiary":
        case "on-tertiary":
        case "error":
        case "on-error":
        case "surface":
        case "on-surface":
        case "surface-variant":
        case "on-surface-variant":
        case "outline":
        case "hover":
        case "on-hover":
            return true;
        default:
            return false;
        }
    }

    function isCustomColor(value) {
        return typeof value === "string" && !isThemeColorKey(value) && /^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value);
    }

    function resolveThemeColor(key) {
        switch (key) {
        case "none":
            return "transparent";
        case "primary":
            return Color.mPrimary;
        case "on-primary":
            return Color.mOnPrimary;
        case "secondary":
            return Color.mSecondary;
        case "on-secondary":
            return Color.mOnSecondary;
        case "tertiary":
            return Color.mTertiary;
        case "on-tertiary":
            return Color.mOnTertiary;
        case "error":
            return Color.mError;
        case "on-error":
            return Color.mOnError;
        case "surface":
            return Color.mSurface;
        case "on-surface":
            return Color.mOnSurface;
        case "surface-variant":
            return Color.mSurfaceVariant;
        case "on-surface-variant":
            return Color.mOnSurfaceVariant;
        case "outline":
            return Color.mOutline;
        case "hover":
            return Color.mHover;
        case "on-hover":
            return Color.mOnHover;
        default:
            return undefined;
        }
    }

    function resolveColor(value, fallbackColor) {
        const themeColor = resolveThemeColor(value);
        if (themeColor !== undefined)
            return themeColor;
        if (isCustomColor(value))
            return value;
        return fallbackColor;
    }

    function contrastColor(baseColor) {
        const sample = Qt.color(baseColor);
        const luminance = (sample.r * 0.299) + (sample.g * 0.587) + (sample.b * 0.114);
        return luminance > 0.6 ? "#111111" : "#F5F5F5";
    }

    function describeValue(value) {
        if (value === undefined)
            return "";
        if (isCustomColor(value))
            return String(value).toUpperCase();

        for (let i = 0; i < preferredColorOptions.length; i++) {
            if (sameValue(preferredColorOptions[i].key, value))
                return preferredColorOptions[i].name;
        }

        for (let j = 0; j < legacyColorOptions.length; j++) {
            if (sameValue(legacyColorOptions[j].key, value))
                return legacyColorOptions[j].name;
        }

        return String(value);
    }

    function describeOpacity(value) {
        if (value === undefined)
            return "";
        return Math.round(Number(value) * 100) + "%";
    }

    function defaultSummary() {
        if (!isValueChanged)
            return "";

        const parts = [];
        if (defaultColor !== undefined) {
            parts.push(pluginApi?.tr("settings.colorPicker.defaultColor", {
                "value": describeValue(defaultColor)
            }) ?? "");
        }
        if (showOpacityControl && defaultOpacity !== undefined) {
            parts.push(pluginApi?.tr("settings.colorPicker.defaultOpacity", {
                "value": describeOpacity(defaultOpacity)
            }) ?? "");
        }
        let summary = "";
        for (let i = 0; i < parts.length; i++) {
            if (!parts[i])
                continue;
            if (summary !== "")
                summary += " | ";
            summary += parts[i];
        }
        return summary;
    }

    function buildVisibleColorOptions() {
        const options = preferredColorOptions.slice();

        function maybeAppendLegacy(value, suffixKey) {
            if (value === undefined || isCustomColor(value))
                return;
            for (let index = 0; index < options.length; index++) {
                if (sameValue(options[index].key, value))
                    return;
            }
            let legacy = null;
            for (let legacyIndex = 0; legacyIndex < legacyColorOptions.length; legacyIndex++) {
                if (sameValue(legacyColorOptions[legacyIndex].key, value)) {
                    legacy = legacyColorOptions[legacyIndex];
                    break;
                }
            }
            if (!legacy)
                return;
            options.push({
                "key": legacy.key,
                "name": pluginApi?.tr(suffixKey, {
                    "value": legacy.name
                }) ?? legacy.name
            });
        }

        maybeAppendLegacy(currentColor, "settings.colorPicker.legacyCurrent");
        maybeAppendLegacy(defaultColor, "settings.colorPicker.legacyDefault");
        return options;
    }

    function pickerSeedColor() {
        if (customSelected)
            return customPreviewColor;

        return resolveColor(currentColor, Color.mPrimary);
    }

    function openCustomPicker() {
        customPicker.selectedColor = pickerSeedColor();
        customPicker.open();
    }

    NColorPickerDialog {
        id: customPicker

        parent: Overlay.overlay
        modal: true
        onColorSelected: color => root.colorSelected(Qt.rgba(color.r, color.g, color.b, 1).toString().toUpperCase())
    }

    NLabel {
        Layout.fillWidth: true
        label: root.label
        description: root.description
        showIndicator: root.isValueChanged
        indicatorTooltip: root.indicatorTooltip
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Flow {
            Layout.fillWidth: true
            spacing: Style.marginS

            Repeater {
                model: root.visibleColorOptions

                Rectangle {
                    id: colorCircle

                    required property var modelData

                    readonly property bool isSelected: root.sameValue(root.currentColor, modelData.key)
                    readonly property color swatchColor: root.resolveColor(modelData.key, Color.mOnSurface)
                    readonly property bool isTransparentOption: colorCircle.modelData.key === "none"

                    width: root.diameter
                    height: root.diameter
                    radius: width * 0.5
                    color: isTransparentOption ? "transparent" : swatchColor
                    border.color: circleMouseArea.containsMouse || isSelected ? Color.mOnSurface : Color.mOutline
                    border.width: Style.borderM

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width - (Style.marginM * 2)
                        height: Style.borderM
                        radius: height / 2
                        rotation: -45
                        color: Color.mError
                        visible: colorCircle.modelData.key === "none"
                    }

                    NIcon {
                        anchors.centerIn: parent
                        icon: "check"
                        pointSize: Math.max(Style.fontSizeXS, colorCircle.width * 0.4)
                        color: colorCircle.isTransparentOption ? Color.mOnSurface : root.contrastColor(colorCircle.swatchColor)
                        font.weight: Style.fontWeightBold
                        visible: colorCircle.isSelected
                    }

                    MouseArea {
                        id: circleMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: TooltipService.show(parent, colorCircle.modelData.name)
                        onExited: TooltipService.hide()
                        onClicked: root.colorSelected(colorCircle.modelData.key)
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Style.animationFast
                        }
                    }
                }
            }

            Rectangle {
                id: customCircle

                width: root.diameter
                height: root.diameter
                radius: width * 0.5
                color: root.customPreviewColor
                border.color: customMouseArea.containsMouse || root.customSelected ? Color.mOnSurface : Color.mOutline
                border.width: Style.borderM

                NIcon {
                    anchors.centerIn: parent
                    icon: root.customSelected ? "check" : "color-picker"
                    pointSize: Math.max(Style.fontSizeXS, customCircle.width * 0.4)
                    color: root.customSelected ? root.contrastColor(root.customPreviewColor) : Color.mOnSurface
                    font.weight: Style.fontWeightBold
                }

                MouseArea {
                    id: customMouseArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: TooltipService.show(parent, root.customSelected ? `${root.pluginApi?.tr("settings.colorOptions.custom")} (${String(root.currentColor).toUpperCase()})` : root.pluginApi?.tr("settings.colorOptions.custom"))
                    onExited: TooltipService.hide()
                    onClicked: root.openCustomPicker()
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: Style.animationFast
                    }
                }
            }
        }

        ColumnLayout {
            id: opacityCollapsible

            visible: root.showOpacityControl
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 200 * Style.uiScaleRatio
            spacing: 0

            property bool expanded: root.effectiveOpacityExpanded
            property bool _userInteracted: false

            Rectangle {
                id: opacityHeader

                Layout.fillWidth: true
                Layout.preferredHeight: opacityHeaderContent.implicitHeight + Style.marginS * 2
                color: Color.mSurfaceVariant
                radius: Style.iRadiusM
                border.color: Color.mOutline
                border.width: Style.borderS

                Rectangle {
                    anchors.fill: parent
                    color: Color.mOnSurface
                    opacity: opacityCollapsible.expanded ? 0.06 : 0
                    radius: parent.radius

                    Behavior on opacity {
                        enabled: opacityCollapsible._userInteracted
                        NumberAnimation {
                            duration: Style.animationNormal
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: opacityHeaderArea

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        opacityCollapsible._userInteracted = true;
                        const nextExpanded = !opacityCollapsible.expanded;
                        if (root.opacityExpandedControlled)
                            root.opacityExpandedToggled(nextExpanded);
                        else
                            root._localOpacityExpanded = nextExpanded;
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: Color.mOnSurface
                        opacity: opacityHeaderArea.containsMouse ? 0.06 : 0
                        radius: opacityHeader.radius

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Style.animationFast
                            }
                        }
                    }
                }

                RowLayout {
                    id: opacityHeaderContent

                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginS

                    NIcon {
                        icon: "chevron-right"
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurfaceVariant
                        Layout.alignment: Qt.AlignVCenter

                        rotation: opacityCollapsible.expanded ? 90 : 0
                        Behavior on rotation {
                            enabled: opacityCollapsible._userInteracted
                            NumberAnimation {
                                duration: Style.animationNormal
                                easing.type: Easing.OutCubic
                            }
                        }
                    }

                    NText {
                        text: root.pluginApi?.tr("settings.colorPicker.opacity.label")
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            Rectangle {
                id: opacityContent

                Layout.fillWidth: true
                Layout.topMargin: Style.marginXS
                visible: opacityCollapsible.expanded
                color: "transparent"
                radius: Style.iRadiusM

                Layout.preferredHeight: opacityCollapsible.expanded ? opacityContentLayout.implicitHeight : 0

                Behavior on Layout.preferredHeight {
                    enabled: opacityCollapsible._userInteracted
                    NumberAnimation {
                        duration: Style.animationNormal
                        easing.type: Easing.OutCubic
                    }
                }

                ColumnLayout {
                    id: opacityContentLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Style.marginS

                    NValueSlider {
                        Layout.fillWidth: true
                        label: root.pluginApi?.tr("settings.colorPicker.opacity.valueLabel")
                        description: root.pluginApi?.tr("settings.colorPicker.opacity.valueDesc")
                        from: root.opacityFrom
                        to: root.opacityTo
                        stepSize: root.opacityStepSize
                        value: Math.max(root.opacityFrom, Math.min(root.opacityTo, root.currentOpacity))
                        text: root.describeOpacity(value)
                        defaultValue: root.defaultOpacity !== undefined ? Math.max(root.opacityFrom, Math.min(root.opacityTo, root.defaultOpacity)) : undefined
                        showReset: root.defaultOpacity !== undefined
                        onMoved: sliderValue => root.opacitySelected(Math.round(sliderValue * 100) / 100)
                    }
                }

                opacity: opacityCollapsible.expanded ? 1.0 : 0.0
                Behavior on opacity {
                    enabled: opacityCollapsible._userInteracted
                    NumberAnimation {
                        duration: Style.animationNormal
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
