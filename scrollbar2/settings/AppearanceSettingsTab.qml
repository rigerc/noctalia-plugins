import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.appearance")
    description: rootSettings?.pluginApi?.tr("settings.pages.appearance")
    icon: "palette"

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.labels.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.labels.desc")
        icon: "device-desktop"
        iconColor: Color.mOnSurfaceVariant
    }

    WindowSettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.colors.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.colors.desc")
        icon: "paint"
        iconColor: Color.mOnSurfaceVariant
    }

    ColorSettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.workspaces.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.workspaces.desc")
        icon: "layers-union"
        iconColor: Color.mOnSurfaceVariant
    }

    WorkspaceIndicatorSettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    SpecialWorkspaceOverlaySettingsSection {
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
