import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

SettingsSectionBox {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.label") ?? ""
    description: rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.desc") ?? ""

    SettingsToggle {
        settingPath: "mouseInteraction.scrollWheelFocus"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.mouseInteraction.scrollWheelFocus.label")
        description: rootSettings?.pluginApi?.tr("settings.mouseInteraction.scrollWheelFocus.desc")
    }

    SettingsToggle {
        settingPath: "mouseInteraction.middleClickClose"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.mouseInteraction.middleClickClose.label")
        description: rootSettings?.pluginApi?.tr("settings.mouseInteraction.middleClickClose.desc")
    }

    SettingsToggle {
        settingPath: "mouseInteraction.workspaceScrollSwitch"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.mouseInteraction.workspaceScrollSwitch.label")
        description: rootSettings?.pluginApi?.tr("settings.mouseInteraction.workspaceScrollSwitch.desc")
    }
}
