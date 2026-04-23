import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

SettingsSectionBox {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.section.filtering.label") ?? ""
    description: rootSettings?.pluginApi?.tr("settings.section.filtering.desc") ?? ""

    SettingsToggle {
        settingPath: "filtering.onlySameOutput"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.filtering.sameOutput.label")
        description: rootSettings?.pluginApi?.tr("settings.filtering.sameOutput.desc")
    }

    SettingsToggle {
        settingPath: "filtering.onlyActiveWorkspaces"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.filtering.activeWorkspaces.label")
        description: rootSettings?.pluginApi?.tr("settings.filtering.activeWorkspaces.desc")
    }
}
