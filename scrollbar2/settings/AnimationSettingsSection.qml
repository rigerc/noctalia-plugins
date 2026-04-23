import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

SettingsSectionBox {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.section.animation.label") ?? ""
    description: rootSettings?.pluginApi?.tr("settings.section.animation.desc") ?? ""

    SettingsToggle {
        settingPath: "animation.enabled"
        rootSettings: root.rootSettings
        label: rootSettings?.pluginApi?.tr("settings.animation.enabled.label")
        description: rootSettings?.pluginApi?.tr("settings.animation.enabled.desc")
    }

    SettingsComboBox {
        settingPath: "animation.type"
        rootSettings: root.rootSettings
        modelSource: rootSettings?.animationTypeModel
        label: rootSettings?.pluginApi?.tr("settings.animation.type.label")
        description: rootSettings?.pluginApi?.tr("settings.animation.type.desc")
    }

    SettingsSlider {
        settingPath: "animation.speed"
        rootSettings: root.rootSettings
        from: 50; to: 1500; stepSize: 25
        unit: "ms"
        label: rootSettings?.pluginApi?.tr("settings.animation.speed.label")
        description: rootSettings?.pluginApi?.tr("settings.animation.speed.desc")
    }
}
