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
    navigationSections: [
        {
            "id": "display",
            "label": rootSettings?.pluginApi?.tr("settings.section.display.label"),
            "icon": "device-desktop",
            "target": displaySection.displaySectionTarget
        },
        {
            "id": "track",
            "label": rootSettings?.pluginApi?.tr("settings.section.track.label"),
            "icon": "line",
            "target": displaySection.trackSectionTarget
        },
        {
            "id": "filtering",
            "label": rootSettings?.pluginApi?.tr("settings.section.filtering.label"),
            "icon": "filter",
            "target": behaviorSection.filteringSectionTarget
        },
        {
            "id": "animation",
            "label": rootSettings?.pluginApi?.tr("settings.section.animation.label"),
            "icon": "transition-right",
            "target": behaviorSection.animationSectionTarget
        },
        {
            "id": "debug",
            "label": rootSettings?.pluginApi?.tr("settings.section.debug.label"),
            "icon": "bug",
            "target": behaviorSection.debugSectionTarget
        }
    ]

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.pageGroups.layoutCore.label")
        description: rootSettings?.pluginApi?.tr("settings.pageGroups.layoutCore.desc")
        icon: "device-desktop"
        iconColor: Color.mOnSurfaceVariant
    }

    DisplaySettingsSection {
        id: displaySection
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
        id: behaviorSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
