import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

SettingsSectionBox {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.section.debug.label") ?? ""
    description: rootSettings?.pluginApi?.tr("settings.section.debug.desc") ?? ""

    SettingsToggle {
        settingPath: "debug.logging"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.debug.logging.label")
        description: rootSettings?.pluginApi?.tr("settings.debug.logging.desc")
    }
}
