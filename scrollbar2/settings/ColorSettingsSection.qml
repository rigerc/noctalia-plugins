import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias trackColorsSectionTarget: trackColorsContent
    property alias focusColorsSectionTarget: focusColorsContent
    property alias windowColorsSectionTarget: windowColorsContent

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: trackColorsContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: trackColorsContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.trackColors.label")
                description: rootSettings?.pluginApi?.tr("settings.section.trackColors.desc")
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.color.label")
                description: rootSettings?.pluginApi?.tr("settings.track.color.desc")
                currentColor: rootSettings?.objectSettingValue("track", "fill", "color") ?? "surface"
                defaultColor: rootSettings?.defaultObjectValue("track", "fill", "color") ?? "surface"
                currentOpacity: rootSettings?.objectSettingValue("track", "fill", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultObjectValue("track", "fill", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setObjectSetting("track", "fill", "color", value)
                onOpacitySelected: value => rootSettings?.setObjectSetting("track", "fill", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.separatorColor.label")
                description: rootSettings?.pluginApi?.tr("settings.track.separatorColor.desc")
                currentColor: rootSettings?.settingValue("track", "separatorColor") ?? "outline"
                defaultColor: rootSettings?.defaultValue("track", "separatorColor") ?? "outline"
                onColorSelected: value => rootSettings?.setSetting("track", "separatorColor", value)
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.edgeFade.leftEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.track.edgeFade.leftEnabled.desc")
                checked: rootSettings?.nestedSettingValue("track", "edgeFade", "leftEnabled") ?? false
                defaultValue: rootSettings?.defaultNestedValue("track", "edgeFade", "leftEnabled") ?? false
                onToggled: checked => rootSettings?.setNestedSetting("track", "edgeFade", "leftEnabled", checked)
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.edgeFade.rightEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.track.edgeFade.rightEnabled.desc")
                checked: rootSettings?.nestedSettingValue("track", "edgeFade", "rightEnabled") ?? false
                defaultValue: rootSettings?.defaultNestedValue("track", "edgeFade", "rightEnabled") ?? false
                onToggled: checked => rootSettings?.setNestedSetting("track", "edgeFade", "rightEnabled", checked)
            }

            NValueSlider {
                visible: (rootSettings?.nestedSettingValue("track", "edgeFade", "leftEnabled") ?? false)
                    || (rootSettings?.nestedSettingValue("track", "edgeFade", "rightEnabled") ?? false)
                label: rootSettings?.pluginApi?.tr("settings.track.edgeFade.width.label")
                description: rootSettings?.pluginApi?.tr("settings.track.edgeFade.width.desc")
                from: 0
                to: 120
                stepSize: 1
                value: rootSettings?.nestedSettingValue("track", "edgeFade", "width") ?? 24
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultNestedValue("track", "edgeFade", "width") ?? 24
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("track", "edgeFade", "width", Math.round(sliderValue))
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: focusColorsContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: focusColorsContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.focusColors.label")
                description: rootSettings?.pluginApi?.tr("settings.section.focusColors.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.enabled.desc")
                checked: rootSettings?.stateSettingValue("focusLine", "colors", "focused", "enabled") ?? true
                defaultValue: rootSettings?.defaultStateValue("focusLine", "colors", "focused", "enabled") ?? true
                onToggled: checked => rootSettings?.setStateSetting("focusLine", "colors", "focused", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: rootSettings?.stateSettingValue("focusLine", "colors", "focused", "enabled") ?? true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.desc")
                currentColor: rootSettings?.stateSettingValue("focusLine", "colors", "focused", "color") ?? "primary"
                defaultColor: rootSettings?.defaultStateValue("focusLine", "colors", "focused", "color") ?? "primary"
                currentOpacity: rootSettings?.stateSettingValue("focusLine", "colors", "focused", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("focusLine", "colors", "focused", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("focusLine", "colors", "focused", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("focusLine", "colors", "focused", "opacity", value)
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.enabled.desc")
                checked: rootSettings?.stateSettingValue("focusLine", "colors", "hover", "enabled") ?? true
                defaultValue: rootSettings?.defaultStateValue("focusLine", "colors", "hover", "enabled") ?? true
                onToggled: checked => rootSettings?.setStateSetting("focusLine", "colors", "hover", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: rootSettings?.stateSettingValue("focusLine", "colors", "hover", "enabled") ?? true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.desc")
                currentColor: rootSettings?.stateSettingValue("focusLine", "colors", "hover", "color") ?? "hover"
                defaultColor: rootSettings?.defaultStateValue("focusLine", "colors", "hover", "color") ?? "hover"
                currentOpacity: rootSettings?.stateSettingValue("focusLine", "colors", "hover", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("focusLine", "colors", "hover", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("focusLine", "colors", "hover", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("focusLine", "colors", "hover", "opacity", value)
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.enabled.desc")
                checked: rootSettings?.stateSettingValue("focusLine", "colors", "default", "enabled") ?? true
                defaultValue: rootSettings?.defaultStateValue("focusLine", "colors", "default", "enabled") ?? true
                onToggled: checked => rootSettings?.setStateSetting("focusLine", "colors", "default", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: rootSettings?.stateSettingValue("focusLine", "colors", "default", "enabled") ?? true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.desc")
                currentColor: rootSettings?.stateSettingValue("focusLine", "colors", "default", "color") ?? "surface-variant"
                defaultColor: rootSettings?.defaultStateValue("focusLine", "colors", "default", "color") ?? "surface-variant"
                currentOpacity: rootSettings?.stateSettingValue("focusLine", "colors", "default", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("focusLine", "colors", "default", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("focusLine", "colors", "default", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("focusLine", "colors", "default", "opacity", value)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: windowColorsContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: windowColorsContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.windowColors.label")
                description: rootSettings?.pluginApi?.tr("settings.section.windowColors.desc")
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.focused.desc")
                currentColor: rootSettings?.stateSettingValue("window", "iconColors", "focused", "color") ?? "on-surface"
                defaultColor: rootSettings?.defaultStateValue("window", "iconColors", "focused", "color") ?? "on-surface"
                currentOpacity: rootSettings?.stateSettingValue("window", "iconColors", "focused", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("window", "iconColors", "focused", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("window", "iconColors", "focused", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("window", "iconColors", "focused", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.desc")
                currentColor: rootSettings?.stateSettingValue("window", "iconColors", "hover", "color") ?? "on-hover"
                defaultColor: rootSettings?.defaultStateValue("window", "iconColors", "hover", "color") ?? "on-hover"
                currentOpacity: rootSettings?.stateSettingValue("window", "iconColors", "hover", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("window", "iconColors", "hover", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("window", "iconColors", "hover", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("window", "iconColors", "hover", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.desc")
                currentColor: rootSettings?.stateSettingValue("window", "iconColors", "default", "color") ?? "on-surface-variant"
                defaultColor: rootSettings?.defaultStateValue("window", "iconColors", "default", "color") ?? "on-surface-variant"
                currentOpacity: rootSettings?.stateSettingValue("window", "iconColors", "default", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("window", "iconColors", "default", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("window", "iconColors", "default", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("window", "iconColors", "default", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.desc")
                currentColor: rootSettings?.stateSettingValue("window", "titleColors", "focused", "color") ?? "on-surface"
                defaultColor: rootSettings?.defaultStateValue("window", "titleColors", "focused", "color") ?? "on-surface"
                currentOpacity: rootSettings?.stateSettingValue("window", "titleColors", "focused", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("window", "titleColors", "focused", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("window", "titleColors", "focused", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("window", "titleColors", "focused", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.desc")
                currentColor: rootSettings?.stateSettingValue("window", "titleColors", "hover", "color") ?? "on-hover"
                defaultColor: rootSettings?.defaultStateValue("window", "titleColors", "hover", "color") ?? "on-hover"
                currentOpacity: rootSettings?.stateSettingValue("window", "titleColors", "hover", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("window", "titleColors", "hover", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("window", "titleColors", "hover", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("window", "titleColors", "hover", "opacity", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.desc")
                currentColor: rootSettings?.stateSettingValue("window", "titleColors", "default", "color") ?? "on-surface-variant"
                defaultColor: rootSettings?.defaultStateValue("window", "titleColors", "default", "color") ?? "on-surface-variant"
                currentOpacity: rootSettings?.stateSettingValue("window", "titleColors", "default", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("window", "titleColors", "default", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("window", "titleColors", "default", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("window", "titleColors", "default", "opacity", value)
            }
        }
    }
}
