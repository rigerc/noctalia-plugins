import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./settings"

ColumnLayout {
    id: root

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property real preferredWidth: 720 * Style.uiScaleRatio

    readonly property var fontWeightModel: ListModel {
        ListElement {
            key: "default"
            name: QT_TR_NOOP("Default")
        }
        ListElement {
            key: "light"
            name: QT_TR_NOOP("Light")
        }
        ListElement {
            key: "normal"
            name: QT_TR_NOOP("Normal")
        }
        ListElement {
            key: "medium"
            name: QT_TR_NOOP("Medium")
        }
        ListElement {
            key: "semibold"
            name: QT_TR_NOOP("Semibold")
        }
        ListElement {
            key: "bold"
            name: QT_TR_NOOP("Bold")
        }
    }
    readonly property var edgeCueModeModel: ListModel {
        ListElement {
            key: "fade"
            name: QT_TR_NOOP("Fade")
        }
        ListElement {
            key: "border"
            name: QT_TR_NOOP("Border")
        }
        ListElement {
            key: "off"
            name: QT_TR_NOOP("Off")
        }
    }
    readonly property var defaultSettings: createSettingsSnapshot(defaults, ({}))
    property var editSettings: createSettingsSnapshot(cfg, defaults)

    spacing: Style.marginM
    implicitWidth: preferredWidth

    function deepCopy(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function readSetting(primary, secondary, groupKey, nestedKey, legacyKey, fallbackValue) {
        const primaryGroup = primary ? primary[groupKey] : undefined;
        const nestedPrimary = primaryGroup ? primaryGroup[nestedKey] : undefined;
        if (nestedPrimary !== undefined)
            return nestedPrimary;

        const legacyPrimary = primary ? primary[legacyKey] : undefined;
        if (legacyPrimary !== undefined)
            return legacyPrimary;

        const secondaryGroup = secondary ? secondary[groupKey] : undefined;
        const nestedSecondary = secondaryGroup ? secondaryGroup[nestedKey] : undefined;
        if (nestedSecondary !== undefined)
            return nestedSecondary;

        const legacySecondary = secondary ? secondary[legacyKey] : undefined;
        if (legacySecondary !== undefined)
            return legacySecondary;

        return fallbackValue;
    }

    function createSettingsSnapshot(primary, secondary) {
        return {
            "filtering": {
                "onlySameOutput": readSetting(primary, secondary, "filtering", "onlySameOutput", "onlySameOutput", true),
                "onlyActiveWorkspaces": readSetting(primary, secondary, "filtering", "onlyActiveWorkspaces", "onlyActiveWorkspaces", true)
            },
            "interaction": {
                "enableReorder": readSetting(primary, secondary, "interaction", "enableReorder", "enableReorder", true),
                "enableScrollWheel": readSetting(primary, secondary, "interaction", "enableScrollWheel", "enableScrollWheel", true)
            },
            "autoScroll": {
                "centerFocusedWindow": readSetting(primary, secondary, "autoScroll", "centerFocusedWindow", "centerFocusedWindow", true),
                "centerAnimationMs": readSetting(primary, secondary, "autoScroll", "centerAnimationMs", "centerAnimationMs", 200)
            },
            "advanced": {
                "debugLogging": readSetting(primary, secondary, "advanced", "debugLogging", "debugLogging", false)
            },
            "layout": {
                "maxWidgetWidth": readSetting(primary, secondary, "layout", "maxWidgetWidth", "maxWidgetWidth", 40),
                "slotWidth": readSetting(primary, secondary, "layout", "slotWidth", "slotWidth", 112),
                "slotSpacingUnits": readSetting(primary, secondary, "layout", "slotSpacingUnits", "slotSpacingUnits", 1),
                "radiusScale": readSetting(primary, secondary, "layout", "radiusScale", "radiusScale", 1.0),
                "slotCapsuleScale": readSetting(primary, secondary, "layout", "slotCapsuleScale", "slotCapsuleScale", 1.0),
                "clipToBarBounds": readSetting(primary, secondary, "layout", "clipToBarBounds", "clipToBarBounds", true)
            },
            "icons": {
                "showIcons": readSetting(primary, secondary, "icons", "showIcons", "showIcons", true),
                "iconScale": readSetting(primary, secondary, "icons", "iconScale", "iconScale", 0.8),
                "iconTintColor": readSetting(primary, secondary, "icons", "iconTintColor", "iconTintColor", "none"),
                "iconTintOpacity": readSetting(primary, secondary, "icons", "iconTintOpacity", "iconTintOpacity", 100)
            },
            "title": {
                "showTitle": readSetting(primary, secondary, "title", "showTitle", "showTitle", true),
                "titleFontFamily": readSetting(primary, secondary, "title", "titleFontFamily", "titleFontFamily", ""),
                "titleFontSize": readSetting(primary, secondary, "title", "titleFontSize", "titleFontSize", 0),
                "titleFontWeight": readSetting(primary, secondary, "title", "titleFontWeight", "titleFontWeight", "default")
            },
            "edgeFade": {
                "mode": (() => {
                    const configuredMode = readSetting(primary, secondary, "edgeFade", "mode", "edgeFadeMode", undefined);
                    if (configuredMode !== undefined)
                        return configuredMode;

                    const legacySize = readSetting(primary, secondary, "edgeFade", "size", "edgeFadeSize", undefined);
                    if (legacySize !== undefined)
                        return legacySize > 0 ? "fade" : "off";

                    return "fade";
                })(),
                "fadeSize": (() => {
                    const configuredFadeSize = readSetting(primary, secondary, "edgeFade", "fadeSize", "edgeFadeFadeSize", undefined);
                    if (configuredFadeSize !== undefined)
                        return configuredFadeSize;
                    return readSetting(primary, secondary, "edgeFade", "size", "edgeFadeSize", 18);
                })(),
                "fadeOpacity": readSetting(primary, secondary, "edgeFade", "fadeOpacity", "edgeFadeOpacity", 100),
                "borderColor": readSetting(primary, secondary, "edgeFade", "borderColor", "edgeFadeBorderColor", "outline"),
                "borderOpacity": readSetting(primary, secondary, "edgeFade", "borderOpacity", "edgeFadeBorderOpacity", 70),
                "borderThickness": readSetting(primary, secondary, "edgeFade", "borderThickness", "edgeFadeBorderThickness", 1)
            },
            "background": {
                "color": readSetting(primary, secondary, "background", "color", "backgroundColor", "none"),
                "opacity": readSetting(primary, secondary, "background", "opacity", "backgroundOpacity", 0)
            },
            "focused": {
                "showFill": readSetting(primary, secondary, "focused", "showFill", "showFocusedFill", true),
                "fillColor": readSetting(primary, secondary, "focused", "fillColor", "focusedFillColor", "primary"),
                "fillOpacity": readSetting(primary, secondary, "focused", "fillOpacity", "focusedFillOpacity", 92),
                "showBorder": readSetting(primary, secondary, "focused", "showBorder", "showFocusedBorder", true),
                "borderColor": readSetting(primary, secondary, "focused", "borderColor", "focusedBorderColor", "primary"),
                "borderOpacity": readSetting(primary, secondary, "focused", "borderOpacity", "focusedBorderOpacity", 100),
                "textColor": readSetting(primary, secondary, "focused", "textColor", "focusedTextColor", "on-primary")
            },
            "unfocused": {
                "showFill": readSetting(primary, secondary, "unfocused", "showFill", "showUnfocusedFill", true),
                "fillColor": readSetting(primary, secondary, "unfocused", "fillColor", "unfocusedFillColor", "surface-variant"),
                "fillOpacity": readSetting(primary, secondary, "unfocused", "fillOpacity", "unfocusedFillOpacity", 8),
                "showBorder": readSetting(primary, secondary, "unfocused", "showBorder", "showUnfocusedBorder", true),
                "borderColor": readSetting(primary, secondary, "unfocused", "borderColor", "unfocusedBorderColor", "outline"),
                "borderOpacity": readSetting(primary, secondary, "unfocused", "borderOpacity", "unfocusedBorderOpacity", 45),
                "textColor": readSetting(primary, secondary, "unfocused", "textColor", "unfocusedTextColor", "on-surface"),
                "inactiveOpacity": readSetting(primary, secondary, "unfocused", "inactiveOpacity", "inactiveOpacity", 45)
            },
            "hover": {
                "fillColor": readSetting(primary, secondary, "hover", "fillColor", "hoverFillColor", "hover"),
                "fillOpacity": readSetting(primary, secondary, "hover", "fillOpacity", "hoverFillOpacity", 55),
                "showBorder": readSetting(primary, secondary, "hover", "showBorder", "showHoverBorder", true),
                "borderColor": readSetting(primary, secondary, "hover", "borderColor", "hoverBorderColor", "outline"),
                "borderOpacity": readSetting(primary, secondary, "hover", "borderOpacity", "hoverBorderOpacity", 100),
                "textColor": readSetting(primary, secondary, "hover", "textColor", "hoverTextColor", "on-hover"),
                "scalePercent": readSetting(primary, secondary, "hover", "scalePercent", "hoverScalePercent", 2.5),
                "transitionDurationMs": readSetting(primary, secondary, "hover", "transitionDurationMs", "hoverTransitionDurationMs", 120)
            },
            "indicators": {
                "showTrackLine": readSetting(primary, secondary, "indicators", "showTrackLine", "showTrackLine", true),
                "trackOpacity": readSetting(primary, secondary, "indicators", "trackOpacity", "trackOpacity", 35),
                "trackThumbColor": readSetting(primary, secondary, "indicators", "trackThumbColor", "trackThumbColor", "primary"),
                "showFocusLine": readSetting(primary, secondary, "indicators", "showFocusLine", "showFocusLine", true),
                "focusLineColor": readSetting(primary, secondary, "indicators", "focusLineColor", "focusLineColor", "secondary"),
                "focusLineOpacity": readSetting(primary, secondary, "indicators", "focusLineOpacity", "focusLineOpacity", 96),
                "focusLineThickness": readSetting(primary, secondary, "indicators", "focusLineThickness", "focusLineThickness", 2),
                "focusLineAnimationMs": readSetting(primary, secondary, "indicators", "focusLineAnimationMs", "focusLineAnimationMs", 120)
            }
        };
    }

    function settingValue(groupKey, nestedKey) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function defaultValue(groupKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function setSetting(groupKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        next[groupKey][nestedKey] = value;
        editSettings = next;
    }

    function saveSettings() {
        if (!pluginApi)
            return;

        pluginApi.pluginSettings = deepCopy(editSettings);
        pluginApi.saveSettings();
    }

    NTabBar {
        id: tabBar
        Layout.fillWidth: true
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            text: pluginApi?.tr("settings.tabs.layout")
            tabIndex: 0
            checked: tabView.currentIndex === 0
            onClicked: tabView.currentIndex = 0
        }
        NTabButton {
            text: pluginApi?.tr("settings.tabs.colors")
            tabIndex: 1
            checked: tabView.currentIndex === 1
            onClicked: tabView.currentIndex = 1
        }
        NTabButton {
            text: pluginApi?.tr("settings.tabs.behavior")
            tabIndex: 2
            checked: tabView.currentIndex === 2
            onClicked: tabView.currentIndex = 2
        }
    }

    NTabView {
        id: tabView
        Layout.fillWidth: true

        LayoutSettingsTab {
            rootSettings: root
        }

        ColorsSettingsTab {
            rootSettings: root
        }

        BehaviorSettingsTab {
            rootSettings: root
        }
    }
}
