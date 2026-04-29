import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../components"
import "../../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias indicatorSectionTarget: indicatorCard.sectionTarget
    property alias badgeSectionTarget: badgeCard.sectionTarget
    property alias animationSectionTarget: animationCard.sectionTarget
    readonly property bool workspaceIndicatorSettingsActive: root.rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
    readonly property bool workspaceIndicatorBadgeSettingsActive: workspaceIndicatorSettingsActive
        && (root.rootSettings?.isVisibleByConditions(["workspaceIndicatorBadgeEnabled"]) ?? false)
    readonly property bool workspaceIndicatorAnimationSettingsActive: workspaceIndicatorSettingsActive
        && (root.rootSettings?.isVisibleByConditions(["workspaceIndicatorAnimationEnabled"]) ?? true)

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: indicatorCard
        sectionKey: "workspaceIndicator"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.enabled.desc")
                checked: root.rootSettings?.settingValue("workspaceIndicator", "enabled") ?? false
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "enabled") ?? false
                onToggled: checked => root.rootSettings?.setSetting("workspaceIndicator", "enabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.labelMode.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.labelMode.desc")
                model: root.rootSettings?.workspaceIndicatorLabelModeModel
                currentKey: root.rootSettings?.settingValue("workspaceIndicator", "labelMode") ?? "id"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "labelMode") ?? "id"
                onSelected: key => root.rootSettings?.setSetting("workspaceIndicator", "labelMode", key)
            }

            NTextInput {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.presetText.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.presetText.desc")
                text: root.rootSettings?.settingValue("workspaceIndicator", "presetText") ?? ""
                onTextChanged: root.rootSettings?.setSetting("workspaceIndicator", "presetText", text)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.position.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.position.desc")
                model: root.rootSettings?.workspaceIndicatorPositionModel
                currentKey: root.rootSettings?.settingValue("workspaceIndicator", "position") ?? "left"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "position") ?? "left"
                onSelected: key => root.rootSettings?.setSetting("workspaceIndicator", "position", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.verticalAlign.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.verticalAlign.desc")
                model: root.rootSettings?.focusVerticalModel
                currentKey: root.rootSettings?.settingValue("workspaceIndicator", "verticalAlign") ?? "center"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "verticalAlign") ?? "center"
                onSelected: key => root.rootSettings?.setSetting("workspaceIndicator", "verticalAlign", key)
            }

            NValueSlider {
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingX.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingX.desc")
                from: 0
                to: 32
                stepSize: 1
                value: root.rootSettings?.settingValue("workspaceIndicator", "paddingX") ?? 10
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "paddingX") ?? 10
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("workspaceIndicator", "paddingX", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingY.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingY.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.rootSettings?.settingValue("workspaceIndicator", "paddingY") ?? 4
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "paddingY") ?? 4
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("workspaceIndicator", "paddingY", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginLeft.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginLeft.desc")
                from: 0
                to: 48
                stepSize: 1
                value: root.rootSettings?.settingValue("workspaceIndicator", "marginLeft") ?? 8
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "marginLeft") ?? 8
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("workspaceIndicator", "marginLeft", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginRight.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginRight.desc")
                from: 0
                to: 48
                stepSize: 1
                value: root.rootSettings?.settingValue("workspaceIndicator", "marginRight") ?? 8
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "marginRight") ?? 8
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("workspaceIndicator", "marginRight", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.borderRadius.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.borderRadius.desc")
                from: 0
                to: 999
                stepSize: 1
                value: root.rootSettings?.settingValue("workspaceIndicator", "borderRadius") ?? 999
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("workspaceIndicator", "borderRadius") ?? 999
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("workspaceIndicator", "borderRadius", Math.round(sliderValue))
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.background.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.background.desc")
                currentColor: root.rootSettings?.objectSettingValue("workspaceIndicator", "background", "color") ?? "surface"
                defaultColor: root.rootSettings?.defaultObjectValue("workspaceIndicator", "background", "color") ?? "surface"
                currentOpacity: root.rootSettings?.objectSettingValue("workspaceIndicator", "background", "opacity") ?? 0.72
                defaultOpacity: root.rootSettings?.defaultObjectValue("workspaceIndicator", "background", "opacity") ?? 0.72
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setObjectSetting("workspaceIndicator", "background", "color", value)
                onOpacitySelected: value => root.rootSettings?.setObjectSetting("workspaceIndicator", "background", "opacity", value)
            }

            NSearchableComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.family.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.family.desc")
                model: FontService.availableFonts
                currentKey: root.rootSettings?.nestedSettingValue("workspaceIndicator", "font", "family") ?? ""
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "font", "family") ?? ""
                onSelected: key => root.rootSettings?.setNestedSetting("workspaceIndicator", "font", "family", key)
            }

            NValueSlider {
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.size.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.size.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.rootSettings?.nestedSettingValue("workspaceIndicator", "font", "size") ?? 11
                text: value === 0 ? root.rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "font", "size") ?? 11
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setNestedSetting("workspaceIndicator", "font", "size", Math.round(sliderValue))
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.weight.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.weight.desc")
                model: root.rootSettings?.fontWeightModel
                currentKey: root.rootSettings?.nestedSettingValue("workspaceIndicator", "font", "weight") ?? "medium"
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "font", "weight") ?? "medium"
                onSelected: key => root.rootSettings?.setNestedSetting("workspaceIndicator", "font", "weight", key)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.color.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.color.desc")
                currentColor: root.rootSettings?.stateSettingValue("workspaceIndicator", "font", "color", "color") ?? "on-surface"
                defaultColor: root.rootSettings?.defaultStateValue("workspaceIndicator", "font", "color", "color") ?? "on-surface"
                currentOpacity: root.rootSettings?.stateSettingValue("workspaceIndicator", "font", "color", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("workspaceIndicator", "font", "color", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("workspaceIndicator", "font", "color", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("workspaceIndicator", "font", "color", "opacity", value)
            }
        
        }
    }

    SettingsSectionCard {
        id: badgeCard
        sectionKey: "workspaceIndicator"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.sectionLabel")
        description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.sectionDesc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.enabled.desc")
                checked: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "enabled") ?? false
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "enabled") ?? false
                onToggled: checked => root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorBadgeSettingsActive
                opacity: root.workspaceIndicatorBadgeSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.background.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.background.desc")
                currentColor: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.color ?? "primary"
                defaultColor: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "background")?.color ?? "primary"
                currentOpacity: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.opacity ?? 1
                defaultOpacity: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "background")?.opacity ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "background", { "color": value, "opacity": root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.opacity ?? 1 })
                onOpacitySelected: value => root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "background", { "color": root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.color ?? "primary", "opacity": value })
            }

            NSearchableComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorBadgeSettingsActive
                opacity: root.workspaceIndicatorBadgeSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.family.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.family.desc")
                model: FontService.availableFonts
                currentKey: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.family ?? ""
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.family ?? ""
                onSelected: key => {
                    const current = root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": key,
                        "size": current.size ?? 10,
                        "weight": current.weight ?? "semibold",
                        "color": current.color ?? { "color": "on-primary", "opacity": 1 }
                    });
                }
            }

            NValueSlider {
                enabled: root.workspaceIndicatorBadgeSettingsActive
                opacity: root.workspaceIndicatorBadgeSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.size.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.size.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.size ?? 10
                text: value === 0 ? root.rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.size ?? 10
                showReset: true
                onMoved: sliderValue => {
                    const current = root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": Math.round(sliderValue),
                        "weight": current.weight ?? "semibold",
                        "color": current.color ?? { "color": "on-primary", "opacity": 1 }
                    });
                }
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorBadgeSettingsActive
                opacity: root.workspaceIndicatorBadgeSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.weight.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.weight.desc")
                model: root.rootSettings?.fontWeightModel
                currentKey: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.weight ?? "semibold"
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.weight ?? "semibold"
                onSelected: key => {
                    const current = root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": current.size ?? 10,
                        "weight": key,
                        "color": current.color ?? { "color": "on-primary", "opacity": 1 }
                    });
                }
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorBadgeSettingsActive
                opacity: root.workspaceIndicatorBadgeSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.color.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.color.desc")
                currentColor: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.color?.color ?? "on-primary"
                defaultColor: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.color?.color ?? "on-primary"
                currentOpacity: root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.color?.opacity ?? 1
                defaultOpacity: root.rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.color?.opacity ?? 1
                showOpacityControl: true
                onColorSelected: value => {
                    const current = root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": current.size ?? 10,
                        "weight": current.weight ?? "semibold",
                        "color": { "color": value, "opacity": current.color?.opacity ?? 1 }
                    });
                }
                onOpacitySelected: value => {
                    const current = root.rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    root.rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": current.size ?? 10,
                        "weight": current.weight ?? "semibold",
                        "color": { "color": current.color?.color ?? "on-primary", "opacity": value }
                    });
                }
            }
        
        }
    }

    SettingsSectionCard {
        id: animationCard
        sectionKey: "workspaceIndicator"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.sectionLabel")
        description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.sectionDesc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorSettingsActive
                opacity: root.workspaceIndicatorSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.enabled.desc")
                checked: root.rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "enabled") ?? true
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "enabled") ?? true
                onToggled: checked => root.rootSettings?.setNestedSetting("workspaceIndicator", "animation", "enabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorAnimationSettingsActive
                opacity: root.workspaceIndicatorAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.type.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.type.desc")
                model: root.rootSettings?.animationTypeModel
                currentKey: root.rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "type") ?? "smooth"
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "type") ?? "smooth"
                onSelected: key => root.rootSettings?.setNestedSetting("workspaceIndicator", "animation", "type", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.workspaceIndicatorAnimationSettingsActive
                opacity: root.workspaceIndicatorAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.axis.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.axis.desc")
                model: root.rootSettings?.axisModel
                currentKey: root.rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "axis") ?? "horizontal"
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "axis") ?? "horizontal"
                onSelected: key => root.rootSettings?.setNestedSetting("workspaceIndicator", "animation", "axis", key)
            }

            NValueSlider {
                enabled: root.workspaceIndicatorAnimationSettingsActive
                opacity: root.workspaceIndicatorAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.speed.label")
                description: root.rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: root.rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "speed") ?? 220
                text: Math.round(value) + " ms"
                defaultValue: root.rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "speed") ?? 220
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setNestedSetting("workspaceIndicator", "animation", "speed", Math.round(sliderValue))
            }
        
        }
    }
}
