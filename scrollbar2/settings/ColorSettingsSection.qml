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
                currentValue: rootSettings?.settingValue("track", "color") ?? "surface"
                defaultValue: rootSettings?.defaultValue("track", "color") ?? "surface"
                onSelected: value => rootSettings?.setSetting("track", "color", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.track.separatorColor.label")
                description: rootSettings?.pluginApi?.tr("settings.track.separatorColor.desc")
                currentValue: rootSettings?.settingValue("track", "separatorColor") ?? "outline"
                defaultValue: rootSettings?.defaultValue("track", "separatorColor") ?? "outline"
                onSelected: value => rootSettings?.setSetting("track", "separatorColor", value)
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
                currentValue: rootSettings?.nestedSettingValue("focusLine", "colors", "focused") ?? "primary"
                defaultValue: rootSettings?.defaultNestedValue("focusLine", "colors", "focused") ?? "primary"
                onSelected: value => rootSettings?.setNestedSetting("focusLine", "colors", "focused", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.desc")
                currentValue: rootSettings?.nestedSettingValue("focusLine", "colors", "hover") ?? "hover"
                defaultValue: rootSettings?.defaultNestedValue("focusLine", "colors", "hover") ?? "hover"
                onSelected: value => rootSettings?.setNestedSetting("focusLine", "colors", "hover", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.desc")
                currentValue: rootSettings?.nestedSettingValue("focusLine", "colors", "default") ?? "surface-variant"
                defaultValue: rootSettings?.defaultNestedValue("focusLine", "colors", "default") ?? "surface-variant"
                onSelected: value => rootSettings?.setNestedSetting("focusLine", "colors", "default", value)
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
                currentValue: rootSettings?.nestedSettingValue("window", "iconColors", "focused") ?? "on-surface"
                defaultValue: rootSettings?.defaultNestedValue("window", "iconColors", "focused") ?? "on-surface"
                onSelected: value => rootSettings?.setNestedSetting("window", "iconColors", "focused", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.desc")
                currentValue: rootSettings?.nestedSettingValue("window", "iconColors", "hover") ?? "on-hover"
                defaultValue: rootSettings?.defaultNestedValue("window", "iconColors", "hover") ?? "on-hover"
                onSelected: value => rootSettings?.setNestedSetting("window", "iconColors", "hover", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showIcons"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.desc")
                currentValue: rootSettings?.nestedSettingValue("window", "iconColors", "default") ?? "on-surface-variant"
                defaultValue: rootSettings?.defaultNestedValue("window", "iconColors", "default") ?? "on-surface-variant"
                onSelected: value => rootSettings?.setNestedSetting("window", "iconColors", "default", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.desc")
                currentValue: rootSettings?.nestedSettingValue("window", "titleColors", "focused") ?? "on-surface"
                defaultValue: rootSettings?.defaultNestedValue("window", "titleColors", "focused") ?? "on-surface"
                onSelected: value => rootSettings?.setNestedSetting("window", "titleColors", "focused", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.desc")
                currentValue: rootSettings?.nestedSettingValue("window", "titleColors", "hover") ?? "on-hover"
                defaultValue: rootSettings?.defaultNestedValue("window", "titleColors", "hover") ?? "on-hover"
                onSelected: value => rootSettings?.setNestedSetting("window", "titleColors", "hover", value)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["showTitle"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.label")
                description: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.desc")
                currentValue: rootSettings?.nestedSettingValue("window", "titleColors", "default") ?? "on-surface-variant"
                defaultValue: rootSettings?.defaultNestedValue("window", "titleColors", "default") ?? "on-surface-variant"
                onSelected: value => rootSettings?.setNestedSetting("window", "titleColors", "default", value)
            }
        }
    }
}
