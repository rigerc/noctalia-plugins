import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.layout")
    description: rootSettings?.pluginApi?.tr("settings.pages.layout")
    icon: "layout-grid"

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.layoutCore.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.layoutCore.desc")
        icon: "device-desktop"
        iconColor: Color.mOnSurfaceVariant
    }

    DisplaySettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.motion.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.motion.desc")
        icon: "transition-right"
        iconColor: Color.mOnSurfaceVariant
    }

    BehaviorSettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
