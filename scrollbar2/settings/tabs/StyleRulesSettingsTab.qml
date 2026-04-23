import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../sections"

SettingsTabPage {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.navTabs.styleRules")
    description: rootSettings?.pluginApi?.tr("settings.pages.styleRules")
    icon: "filter-code"
    navigationSections: [
        {
            "id": "rules",
            "label": rootSettings?.pluginApi?.tr("settings.section.customStyleRules.label"),
            "icon": "filter-code",
            "target": styleRulesSection.rulesSectionTarget
        }
    ]

    CustomStyleRulesSettingsSection {
        id: styleRulesSection
        Layout.fillWidth: true
        rootSettings: root.rootSettings
    }
}
