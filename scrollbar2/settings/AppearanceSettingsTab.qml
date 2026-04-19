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
    navigationSections: [
        {
            "id": "window",
            "label": rootSettings?.pluginApi?.tr("settings.section.window.label"),
            "icon": "typography",
            "target": windowSection.windowSectionTarget
        },
        {
            "id": "focus-line",
            "label": rootSettings?.pluginApi?.tr("settings.section.focusLine.label"),
            "icon": "line",
            "target": windowSection.focusLineSectionTarget
        },
        {
            "id": "colors",
            "label": rootSettings?.pluginApi?.tr("settings.section.trackColors.label"),
            "icon": "paint",
            "target": colorSection.trackColorsSectionTarget
        },
        {
            "id": "workspace-indicator",
            "label": rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.label"),
            "icon": "apps",
            "target": workspaceIndicatorSection.indicatorSectionTarget
        },
        {
            "id": "special-workspace",
            "label": rootSettings?.pluginApi?.tr("settings.section.specialWorkspaceOverlay.label"),
            "icon": "stack-2",
            "target": specialWorkspaceSection.specialWorkspaceSectionTarget
        }
    ]

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.labels.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.labels.desc")
        icon: "device-desktop"
        iconColor: Color.mOnSurfaceVariant
    }

    WindowSettingsSection {
        id: windowSection
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
        id: colorSection
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
        id: workspaceIndicatorSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    SpecialWorkspaceOverlaySettingsSection {
        id: specialWorkspaceSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
