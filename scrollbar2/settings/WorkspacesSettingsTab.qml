import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.workspaces")
    description: rootSettings?.pluginApi?.tr("settings.pages.workspaces")
    icon: "layers-union"
    navigationSections: [
        {
            "id": "workspace-indicator",
            "label": rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.label"),
            "icon": "apps",
            "target": workspaceIndicatorSection.indicatorSectionTarget
        },
        {
            "id": "workspace-indicator-animation",
            "label": rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.sectionLabel"),
            "icon": "line",
            "target": workspaceIndicatorSection.animationSectionTarget
        },
        {
            "id": "special-workspace",
            "label": rootSettings?.pluginApi?.tr("settings.section.specialWorkspaceOverlay.label"),
            "icon": "stack-2",
            "target": specialWorkspaceSection.specialWorkspaceSectionTarget
        },
        {
            "id": "special-workspace-animation",
            "label": rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.sectionLabel"),
            "icon": "line",
            "target": specialWorkspaceSection.animationSectionTarget
        }
    ]

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
