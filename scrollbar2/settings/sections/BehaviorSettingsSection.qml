import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias filteringSectionTarget: filteringCard.sectionTarget
    property alias animationSectionTarget: animationCard.sectionTarget
    property alias windowAnimationSectionTarget: windowAnimationCard.sectionTarget
    property alias mouseInteractionSectionTarget: mouseInteractionCard.sectionTarget
    property alias debugSectionTarget: debugCard.sectionTarget
    readonly property bool globalAnimationSettingsActive: root.rootSettings?.settingValue("animation", "enabled") ?? true
    readonly property bool windowAnimationSettingsActive: root.rootSettings?.isVisibleByConditions(["windowAnimationEnabled"]) ?? true
    readonly property bool workspaceScrollSettingsActive: root.rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: filteringCard
        sectionKey: "filtering"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.filtering.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.filtering.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.filtering.sameOutput.label")
                description: root.rootSettings?.pluginApi?.tr("settings.filtering.sameOutput.desc")
                checked: root.rootSettings?.settingValue("filtering", "onlySameOutput") ?? true
                onToggled: checked => root.rootSettings?.setSetting("filtering", "onlySameOutput", checked)
                defaultValue: root.rootSettings?.defaultValue("filtering", "onlySameOutput") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.filtering.activeWorkspaces.label")
                description: root.rootSettings?.pluginApi?.tr("settings.filtering.activeWorkspaces.desc")
                checked: root.rootSettings?.settingValue("filtering", "onlyActiveWorkspaces") ?? true
                onToggled: checked => root.rootSettings?.setSetting("filtering", "onlyActiveWorkspaces", checked)
                defaultValue: root.rootSettings?.defaultValue("filtering", "onlyActiveWorkspaces") ?? true
            }
        }
    }

    SettingsSectionCard {
        id: animationCard
        sectionKey: "animation"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.animation.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.animation.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.animation.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.animation.enabled.desc")
                checked: root.rootSettings?.settingValue("animation", "enabled") ?? true
                onToggled: checked => root.rootSettings?.setSetting("animation", "enabled", checked)
                defaultValue: root.rootSettings?.defaultValue("animation", "enabled") ?? true
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.globalAnimationSettingsActive
                opacity: root.globalAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.animation.type.label")
                description: root.rootSettings?.pluginApi?.tr("settings.animation.type.desc")
                model: root.rootSettings?.animationTypeModel
                currentKey: root.rootSettings?.settingValue("animation", "type") ?? "spring"
                defaultValue: root.rootSettings?.defaultValue("animation", "type") ?? "spring"
                onSelected: key => root.rootSettings?.setSetting("animation", "type", key)
            }

            NValueSlider {
                enabled: root.globalAnimationSettingsActive
                opacity: root.globalAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.animation.speed.label")
                description: root.rootSettings?.pluginApi?.tr("settings.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: root.rootSettings?.settingValue("animation", "speed") ?? 420
                text: Math.round(value) + " ms"
                defaultValue: root.rootSettings?.defaultValue("animation", "speed") ?? 420
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("animation", "speed", Math.round(sliderValue))
            }
        }
    }

    SettingsSectionCard {
        id: windowAnimationCard
        sectionKey: "window"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.window.animation.sectionLabel")
        description: root.rootSettings?.pluginApi?.tr("settings.window.animation.sectionDesc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.window.animation.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.animation.enabled.desc")
                checked: root.rootSettings?.nestedSettingValue("window", "animation", "enabled")
                    ?? root.rootSettings?.settingValue("animation", "enabled")
                    ?? true
                defaultValue: root.rootSettings?.defaultNestedValue("window", "animation", "enabled")
                onToggled: checked => root.rootSettings?.setNestedSetting("window", "animation", "enabled", checked)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.animation.openEnabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.animation.openEnabled.desc")
                checked: root.rootSettings?.nestedSettingValue("window", "animation", "openEnabled") ?? true
                defaultValue: root.rootSettings?.defaultNestedValue("window", "animation", "openEnabled") ?? true
                onToggled: checked => root.rootSettings?.setNestedSetting("window", "animation", "openEnabled", checked)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.animation.closeEnabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.animation.closeEnabled.desc")
                checked: root.rootSettings?.nestedSettingValue("window", "animation", "closeEnabled") ?? true
                defaultValue: root.rootSettings?.defaultNestedValue("window", "animation", "closeEnabled") ?? true
                onToggled: checked => root.rootSettings?.setNestedSetting("window", "animation", "closeEnabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.animation.type.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.animation.type.desc")
                model: root.rootSettings?.animationTypeModel
                currentKey: root.rootSettings?.nestedSettingValue("window", "animation", "type")
                    ?? root.rootSettings?.settingValue("animation", "type")
                    ?? "spring"
                defaultValue: root.rootSettings?.defaultNestedValue("window", "animation", "type")
                onSelected: key => root.rootSettings?.setNestedSetting("window", "animation", "type", key)
            }

            NValueSlider {
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.window.animation.speed.label")
                description: root.rootSettings?.pluginApi?.tr("settings.window.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: root.rootSettings?.nestedSettingValue("window", "animation", "speed")
                    ?? root.rootSettings?.settingValue("animation", "speed")
                    ?? 420
                text: Math.round(value) + " ms"
                defaultValue: root.rootSettings?.defaultNestedValue("window", "animation", "speed")
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setNestedSetting("window", "animation", "speed", Math.round(sliderValue))
            }
        }
    }

    SettingsSectionCard {
        id: mouseInteractionCard
        sectionKey: "mouseInteraction"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.mouseInteraction.scrollWheelFocus.label")
                description: root.rootSettings?.pluginApi?.tr("settings.mouseInteraction.scrollWheelFocus.desc")
                checked: root.rootSettings?.settingValue("mouseInteraction", "scrollWheelFocus") ?? true
                onToggled: checked => root.rootSettings?.setSetting("mouseInteraction", "scrollWheelFocus", checked)
                defaultValue: root.rootSettings?.defaultValue("mouseInteraction", "scrollWheelFocus") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.mouseInteraction.middleClickClose.label")
                description: root.rootSettings?.pluginApi?.tr("settings.mouseInteraction.middleClickClose.desc")
                checked: root.rootSettings?.settingValue("mouseInteraction", "middleClickClose") ?? true
                onToggled: checked => root.rootSettings?.setSetting("mouseInteraction", "middleClickClose", checked)
                defaultValue: root.rootSettings?.defaultValue("mouseInteraction", "middleClickClose") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.workspaceScrollSettingsActive
                opacity: root.workspaceScrollSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.mouseInteraction.workspaceScrollSwitch.label")
                description: root.rootSettings?.pluginApi?.tr("settings.mouseInteraction.workspaceScrollSwitch.desc")
                checked: root.rootSettings?.settingValue("mouseInteraction", "workspaceScrollSwitch") ?? false
                onToggled: checked => root.rootSettings?.setSetting("mouseInteraction", "workspaceScrollSwitch", checked)
                defaultValue: root.rootSettings?.defaultValue("mouseInteraction", "workspaceScrollSwitch") ?? false
            }
        }
    }

    SettingsSectionCard {
        id: debugCard
        sectionKey: "debug"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.debug.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.debug.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.debug.logging.label")
                description: root.rootSettings?.pluginApi?.tr("settings.debug.logging.desc")
                checked: root.rootSettings?.settingValue("debug", "logging") ?? false
                onToggled: checked => root.rootSettings?.setSetting("debug", "logging", checked)
                defaultValue: root.rootSettings?.defaultValue("debug", "logging") ?? false
            }
        }
    }
}
