import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

RowLayout {
    id: root

    property var pluginApi: null
    property string label: pluginApi?.tr("settings.colorPicker.label")
    property string description: pluginApi?.tr("settings.colorPicker.desc")
    property string currentValue: ""
    property var defaultValue: undefined

    readonly property bool isValueChanged: (defaultValue !== undefined) && !sameValue(currentValue, defaultValue)
    readonly property string indicatorTooltip: pluginApi?.tr("settings.colorPicker.defaultValue", {
        "value": describeValue(defaultValue)
    }) ?? ""
    readonly property int diameter: Math.round(Style.baseWidgetSize * 0.9 * Style.uiScaleRatio)
    readonly property bool customSelected: isCustomColor(currentValue)
    readonly property color customPreviewColor: resolveColor(customSelected ? currentValue : "surface-variant", Color.mSurfaceVariant)
    readonly property var colorOptions: [
        { "key": "none", "name": pluginApi?.tr("settings.colorOptions.none") },
        { "key": "primary", "name": pluginApi?.tr("settings.colorOptions.primary") },
        { "key": "on-primary", "name": pluginApi?.tr("settings.colorOptions.onPrimary") },
        { "key": "secondary", "name": pluginApi?.tr("settings.colorOptions.secondary") },
        { "key": "on-secondary", "name": pluginApi?.tr("settings.colorOptions.onSecondary") },
        { "key": "tertiary", "name": pluginApi?.tr("settings.colorOptions.tertiary") },
        { "key": "on-tertiary", "name": pluginApi?.tr("settings.colorOptions.onTertiary") },
        { "key": "error", "name": pluginApi?.tr("settings.colorOptions.error") },
        { "key": "on-error", "name": pluginApi?.tr("settings.colorOptions.onError") },
        { "key": "surface", "name": pluginApi?.tr("settings.colorOptions.surface") },
        { "key": "on-surface", "name": pluginApi?.tr("settings.colorOptions.onSurface") },
        { "key": "surface-variant", "name": pluginApi?.tr("settings.colorOptions.surfaceVariant") },
        { "key": "on-surface-variant", "name": pluginApi?.tr("settings.colorOptions.onSurfaceVariant") },
        { "key": "outline", "name": pluginApi?.tr("settings.colorOptions.outline") },
        { "key": "hover", "name": pluginApi?.tr("settings.colorOptions.hover") },
        { "key": "on-hover", "name": pluginApi?.tr("settings.colorOptions.onHover") }
    ]

    signal selected(string value)

    function sameValue(left, right) {
        if (left === undefined || right === undefined)
            return left === right;

        return String(left).toLowerCase() === String(right).toLowerCase();
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
        return typeof value === "string"
            && !isThemeColorKey(value)
            && /^#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(value);
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

        for (let i = 0; i < colorOptions.length; i++) {
            if (sameValue(colorOptions[i].key, value))
                return colorOptions[i].name;
        }

        return String(value);
    }

    function pickerSeedColor() {
        if (customSelected)
            return customPreviewColor;

        return resolveColor(currentValue, Color.mPrimary);
    }

    function openCustomPicker() {
        customPicker.selectedColor = pickerSeedColor();
        customPicker.open();
    }

    NColorPickerDialog {
        id: customPicker

        parent: Overlay.overlay
        modal: true
        onColorSelected: color => root.selected(Qt.rgba(color.r, color.g, color.b, 1).toString().toUpperCase())
    }

    NLabel {
        label: root.label
        description: root.description
        showIndicator: root.isValueChanged
        indicatorTooltip: root.indicatorTooltip
    }

    RowLayout {
        id: colourRow

        spacing: Style.marginS
        opacity: enabled ? 1.0 : 0.6
        Layout.minimumWidth: (root.diameter * (root.colorOptions.length + 1)) + (spacing * root.colorOptions.length)

        Repeater {
            model: root.colorOptions

            Rectangle {
                id: colorCircle

                required property var modelData

                readonly property bool isSelected: root.sameValue(root.currentValue, modelData.key)
                readonly property color swatchColor: root.resolveColor(modelData.key, Color.mOnSurface)

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: root.diameter
                implicitHeight: root.diameter
                radius: width * 0.5
                color: modelData.key === "none" ? Color.mSurfaceVariant : swatchColor
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
                    color: root.contrastColor(colorCircle.swatchColor)
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
                    onClicked: root.selected(colorCircle.modelData.key)
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

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: root.diameter
            implicitHeight: root.diameter
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
                onEntered: TooltipService.show(parent, root.customSelected
                    ? `${root.pluginApi?.tr("settings.colorOptions.custom")} (${String(root.currentValue).toUpperCase()})`
                    : root.pluginApi?.tr("settings.colorOptions.custom"))
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
}
