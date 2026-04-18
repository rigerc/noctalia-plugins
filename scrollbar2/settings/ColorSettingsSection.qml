import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null

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

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.desc")
                currentColor: rootSettings?.nestedSettingValue("focusLine", "colors", "focused") ?? "primary"
                defaultColor: rootSettings?.defaultNestedValue("focusLine", "colors", "focused") ?? "primary"
                onColorSelected: value => rootSettings?.setNestedSetting("focusLine", "colors", "focused", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.desc")
                currentColor: rootSettings?.nestedSettingValue("focusLine", "colors", "hover") ?? "hover"
                defaultColor: rootSettings?.defaultNestedValue("focusLine", "colors", "hover") ?? "hover"
                onColorSelected: value => rootSettings?.setNestedSetting("focusLine", "colors", "hover", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.desc")
                currentColor: rootSettings?.nestedSettingValue("focusLine", "colors", "default") ?? "surface-variant"
                defaultColor: rootSettings?.defaultNestedValue("focusLine", "colors", "default") ?? "surface-variant"
                onColorSelected: value => rootSettings?.setNestedSetting("focusLine", "colors", "default", value)
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
                currentColor: rootSettings?.nestedSettingValue("window", "iconColors", "focused") ?? "on-surface"
                defaultColor: rootSettings?.defaultNestedValue("window", "iconColors", "focused") ?? "on-surface"
                onColorSelected: value => rootSettings?.setNestedSetting("window", "iconColors", "focused", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.desc")
                currentColor: rootSettings?.nestedSettingValue("window", "iconColors", "hover") ?? "on-hover"
                defaultColor: rootSettings?.defaultNestedValue("window", "iconColors", "hover") ?? "on-hover"
                onColorSelected: value => rootSettings?.setNestedSetting("window", "iconColors", "hover", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.desc")
                currentColor: rootSettings?.nestedSettingValue("window", "iconColors", "default") ?? "on-surface-variant"
                defaultColor: rootSettings?.defaultNestedValue("window", "iconColors", "default") ?? "on-surface-variant"
                onColorSelected: value => rootSettings?.setNestedSetting("window", "iconColors", "default", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.desc")
                currentColor: rootSettings?.nestedSettingValue("window", "titleColors", "focused") ?? "on-surface"
                defaultColor: rootSettings?.defaultNestedValue("window", "titleColors", "focused") ?? "on-surface"
                onColorSelected: value => rootSettings?.setNestedSetting("window", "titleColors", "focused", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.desc")
                currentColor: rootSettings?.nestedSettingValue("window", "titleColors", "hover") ?? "on-hover"
                defaultColor: rootSettings?.defaultNestedValue("window", "titleColors", "hover") ?? "on-hover"
                onColorSelected: value => rootSettings?.setNestedSetting("window", "titleColors", "hover", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.desc")
                currentColor: rootSettings?.nestedSettingValue("window", "titleColors", "default") ?? "on-surface-variant"
                defaultColor: rootSettings?.defaultNestedValue("window", "titleColors", "default") ?? "on-surface-variant"
                onColorSelected: value => rootSettings?.setNestedSetting("window", "titleColors", "default", value)
            }
        }
    }
}
