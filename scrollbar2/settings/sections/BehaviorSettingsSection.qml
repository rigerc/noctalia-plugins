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
    readonly property bool globalAnimationSettingsActive: rootSettings?.settingValue("animation", "enabled") ?? true
    readonly property bool windowAnimationSettingsActive: rootSettings?.isVisibleByConditions(["windowAnimationEnabled"]) ?? true
    readonly property bool workspaceScrollSettingsActive: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: filteringCard
        sectionKey: "filtering"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.section.filtering.label")
        description: rootSettings?.pluginApi?.tr("settings.section.filtering.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.filtering.sameOutput.label")
                description: rootSettings?.pluginApi?.tr("settings.filtering.sameOutput.desc")
                checked: rootSettings?.settingValue("filtering", "onlySameOutput") ?? true
                onToggled: checked => rootSettings?.setSetting("filtering", "onlySameOutput", checked)
                defaultValue: rootSettings?.defaultValue("filtering", "onlySameOutput") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.filtering.activeWorkspaces.label")
                description: rootSettings?.pluginApi?.tr("settings.filtering.activeWorkspaces.desc")
                checked: rootSettings?.settingValue("filtering", "onlyActiveWorkspaces") ?? true
                onToggled: checked => rootSettings?.setSetting("filtering", "onlyActiveWorkspaces", checked)
                defaultValue: rootSettings?.defaultValue("filtering", "onlyActiveWorkspaces") ?? true
            }
        }
    }

    SettingsSectionCard {
        id: animationCard
        sectionKey: "animation"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.section.animation.label")
        description: rootSettings?.pluginApi?.tr("settings.section.animation.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.animation.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.animation.enabled.desc")
                checked: rootSettings?.settingValue("animation", "enabled") ?? true
                onToggled: checked => rootSettings?.setSetting("animation", "enabled", checked)
                defaultValue: rootSettings?.defaultValue("animation", "enabled") ?? true
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.globalAnimationSettingsActive
                opacity: root.globalAnimationSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.animation.type.label")
                description: rootSettings?.pluginApi?.tr("settings.animation.type.desc")
                model: rootSettings?.animationTypeModel
                currentKey: rootSettings?.settingValue("animation", "type") ?? "spring"
                defaultValue: rootSettings?.defaultValue("animation", "type") ?? "spring"
                onSelected: key => rootSettings?.setSetting("animation", "type", key)
            }

            NValueSlider {
                enabled: root.globalAnimationSettingsActive
                opacity: root.globalAnimationSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.animation.speed.label")
                description: rootSettings?.pluginApi?.tr("settings.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: rootSettings?.settingValue("animation", "speed") ?? 420
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultValue("animation", "speed") ?? 420
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("animation", "speed", Math.round(sliderValue))
            }
        }
    }

    SettingsSectionCard {
        id: windowAnimationCard
        sectionKey: "window"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.window.animation.sectionLabel")
        description: rootSettings?.pluginApi?.tr("settings.window.animation.sectionDesc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.window.animation.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.window.animation.enabled.desc")
                checked: rootSettings?.nestedSettingValue("window", "animation", "enabled")
                    ?? rootSettings?.settingValue("animation", "enabled")
                    ?? true
                defaultValue: rootSettings?.defaultNestedValue("window", "animation", "enabled")
                onToggled: checked => rootSettings?.setNestedSetting("window", "animation", "enabled", checked)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.animation.openEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.window.animation.openEnabled.desc")
                checked: rootSettings?.nestedSettingValue("window", "animation", "openEnabled") ?? true
                defaultValue: rootSettings?.defaultNestedValue("window", "animation", "openEnabled") ?? true
                onToggled: checked => rootSettings?.setNestedSetting("window", "animation", "openEnabled", checked)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.animation.closeEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.window.animation.closeEnabled.desc")
                checked: rootSettings?.nestedSettingValue("window", "animation", "closeEnabled") ?? true
                defaultValue: rootSettings?.defaultNestedValue("window", "animation", "closeEnabled") ?? true
                onToggled: checked => rootSettings?.setNestedSetting("window", "animation", "closeEnabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.animation.type.label")
                description: rootSettings?.pluginApi?.tr("settings.window.animation.type.desc")
                model: rootSettings?.animationTypeModel
                currentKey: rootSettings?.nestedSettingValue("window", "animation", "type")
                    ?? rootSettings?.settingValue("animation", "type")
                    ?? "spring"
                defaultValue: rootSettings?.defaultNestedValue("window", "animation", "type")
                onSelected: key => rootSettings?.setNestedSetting("window", "animation", "type", key)
            }

            NValueSlider {
                enabled: root.windowAnimationSettingsActive
                opacity: root.windowAnimationSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.window.animation.speed.label")
                description: rootSettings?.pluginApi?.tr("settings.window.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: rootSettings?.nestedSettingValue("window", "animation", "speed")
                    ?? rootSettings?.settingValue("animation", "speed")
                    ?? 420
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultNestedValue("window", "animation", "speed")
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("window", "animation", "speed", Math.round(sliderValue))
            }
        }
    }

    SettingsSectionCard {
        id: mouseInteractionCard
        sectionKey: "mouseInteraction"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.label")
        description: rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.mouseInteraction.scrollWheelFocus.label")
                description: rootSettings?.pluginApi?.tr("settings.mouseInteraction.scrollWheelFocus.desc")
                checked: rootSettings?.settingValue("mouseInteraction", "scrollWheelFocus") ?? true
                onToggled: checked => rootSettings?.setSetting("mouseInteraction", "scrollWheelFocus", checked)
                defaultValue: rootSettings?.defaultValue("mouseInteraction", "scrollWheelFocus") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.mouseInteraction.middleClickClose.label")
                description: rootSettings?.pluginApi?.tr("settings.mouseInteraction.middleClickClose.desc")
                checked: rootSettings?.settingValue("mouseInteraction", "middleClickClose") ?? true
                onToggled: checked => rootSettings?.setSetting("mouseInteraction", "middleClickClose", checked)
                defaultValue: rootSettings?.defaultValue("mouseInteraction", "middleClickClose") ?? true
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.workspaceScrollSettingsActive
                opacity: root.workspaceScrollSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.mouseInteraction.workspaceScrollSwitch.label")
                description: rootSettings?.pluginApi?.tr("settings.mouseInteraction.workspaceScrollSwitch.desc")
                checked: rootSettings?.settingValue("mouseInteraction", "workspaceScrollSwitch") ?? false
                onToggled: checked => rootSettings?.setSetting("mouseInteraction", "workspaceScrollSwitch", checked)
                defaultValue: rootSettings?.defaultValue("mouseInteraction", "workspaceScrollSwitch") ?? false
            }
        }
    }

    SettingsSectionCard {
        id: debugCard
        sectionKey: "debug"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.section.debug.label")
        description: rootSettings?.pluginApi?.tr("settings.section.debug.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.debug.logging.label")
                description: rootSettings?.pluginApi?.tr("settings.debug.logging.desc")
                checked: rootSettings?.settingValue("debug", "logging") ?? false
                onToggled: checked => rootSettings?.setSetting("debug", "logging", checked)
                defaultValue: rootSettings?.defaultValue("debug", "logging") ?? false
            }
        }
    }
}
