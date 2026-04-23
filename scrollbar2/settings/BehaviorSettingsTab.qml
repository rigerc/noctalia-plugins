import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.behavior")
    description: rootSettings?.pluginApi?.tr("settings.pages.behavior")
    icon: "adjustments"
    navigationSections: [
        {
            "id": "filtering",
            "label": rootSettings?.pluginApi?.tr("settings.section.filtering.label"),
            "icon": "filter",
            "target": behaviorSection.filteringSectionTarget
        },
        {
            "id": "mouse",
            "label": rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.label"),
            "icon": "mouse",
            "target": behaviorSection.mouseInteractionSectionTarget
        },
        {
            "id": "animation",
            "label": rootSettings?.pluginApi?.tr("settings.section.animation.label"),
            "icon": "transition-right",
            "target": behaviorSection.animationSectionTarget
        },
        {
            "id": "window-animation",
            "label": rootSettings?.pluginApi?.tr("settings.window.animation.sectionLabel"),
            "icon": "arrows-shuffle",
            "target": behaviorSection.windowAnimationSectionTarget
        },
        {
            "id": "auto-hide",
            "label": rootSettings?.pluginApi?.tr("settings.display.autoHide.sectionLabel"),
            "icon": "eye-off",
            "target": autoHideSection.autoHideSectionTarget
        },
        {
            "id": "debug",
            "label": rootSettings?.pluginApi?.tr("settings.section.debug.label"),
            "icon": "bug",
            "target": behaviorSection.debugSectionTarget
        }
    ]

    BehaviorSettingsSection {
        id: behaviorSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }

    AutoHideSettingsSection {
        id: autoHideSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
