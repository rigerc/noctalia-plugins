import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.behavior")
    description: rootSettings?.pluginApi?.tr("settings.pages.behavior")
    icon: "settings-2"
    navigationSections: [
        {
            "id": "filtering",
            "label": rootSettings?.pluginApi?.tr("settings.section.filtering.label"),
            "icon": "filter",
            "target": filteringSection.sectionTarget
        },
        {
            "id": "animation",
            "label": rootSettings?.pluginApi?.tr("settings.section.animation.label"),
            "icon": "transition-right",
            "target": animationSection.sectionTarget
        },
        {
            "id": "window-animation",
            "label": rootSettings?.pluginApi?.tr("settings.window.animation.sectionLabel"),
            "icon": "transition-right",
            "target": windowAnimationSection.sectionTarget
        },
        {
            "id": "mouse",
            "label": rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.label"),
            "icon": "mouse",
            "target": mouseSection.sectionTarget
        },
        {
            "id": "debug",
            "label": rootSettings?.pluginApi?.tr("settings.section.debug.label"),
            "icon": "bug",
            "target": debugSection.sectionTarget
        }
    ]

    FilteringSettingsSection {
        id: filteringSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    AnimationSettingsSection {
        id: animationSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    WindowAnimationSettingsSection {
        id: windowAnimationSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    MouseInteractionSettingsSection {
        id: mouseSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    DebugSettingsSection {
        id: debugSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
