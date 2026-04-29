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
    property alias specialWorkspaceSectionTarget: specialWorkspaceCard.sectionTarget
    property alias animationSectionTarget: animationCard.sectionTarget
    readonly property bool specialWorkspaceSettingsActive: root.rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
    readonly property bool specialWorkspaceCustomSettingsActive: root.rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled", "specialWorkspaceOverlayCustomMode"]) ?? false
    readonly property bool specialWorkspaceAnimationSettingsActive: specialWorkspaceSettingsActive
        && (root.rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayAnimationEnabled"]) ?? true)

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: specialWorkspaceCard
        sectionKey: "specialWorkspaceOverlay"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.section.specialWorkspaceOverlay.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.specialWorkspaceOverlay.desc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.enabled.desc")
                checked: root.rootSettings?.settingValue("specialWorkspaceOverlay", "enabled") ?? false
                defaultValue: root.rootSettings?.defaultValue("specialWorkspaceOverlay", "enabled") ?? false
                onToggled: checked => root.rootSettings?.setSetting("specialWorkspaceOverlay", "enabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.textMode.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.textMode.desc")
                model: root.rootSettings?.specialWorkspaceOverlayTextModeModel
                currentKey: root.rootSettings?.settingValue("specialWorkspaceOverlay", "textMode") ?? "stripped"
                defaultValue: root.rootSettings?.defaultValue("specialWorkspaceOverlay", "textMode") ?? "stripped"
                onSelected: key => root.rootSettings?.setSetting("specialWorkspaceOverlay", "textMode", key)
            }

            NTextInput {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceCustomSettingsActive
                opacity: root.specialWorkspaceCustomSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.customLabel.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.customLabel.desc")
                text: root.rootSettings?.settingValue("specialWorkspaceOverlay", "customLabel") ?? ""
                onEditingFinished: root.rootSettings?.setSetting("specialWorkspaceOverlay", "customLabel", text)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.showWindowIcons.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.showWindowIcons.desc")
                checked: root.rootSettings?.settingValue("specialWorkspaceOverlay", "showWindowIcons") ?? false
                defaultValue: root.rootSettings?.defaultValue("specialWorkspaceOverlay", "showWindowIcons") ?? false
                onToggled: checked => root.rootSettings?.setSetting("specialWorkspaceOverlay", "showWindowIcons", checked)
            }

            NValueSlider {
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.widthPercent.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.widthPercent.desc")
                from: 50
                to: 100
                stepSize: 1
                value: root.rootSettings?.settingValue("specialWorkspaceOverlay", "widthPercent") ?? 100
                text: Math.round(value) + "%"
                defaultValue: root.rootSettings?.defaultValue("specialWorkspaceOverlay", "widthPercent") ?? 100
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("specialWorkspaceOverlay", "widthPercent", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.heightPercent.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.heightPercent.desc")
                from: 50
                to: 100
                stepSize: 1
                value: root.rootSettings?.settingValue("specialWorkspaceOverlay", "heightPercent") ?? 70
                text: Math.round(value) + "%"
                defaultValue: root.rootSettings?.defaultValue("specialWorkspaceOverlay", "heightPercent") ?? 70
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("specialWorkspaceOverlay", "heightPercent", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.borderRadius.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: root.rootSettings?.settingValue("specialWorkspaceOverlay", "borderRadius") ?? 3
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("specialWorkspaceOverlay", "borderRadius") ?? 3
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("specialWorkspaceOverlay", "borderRadius", Math.round(sliderValue))
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.background.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.background.desc")
                currentColor: root.rootSettings?.objectSettingValue("specialWorkspaceOverlay", "background", "color") ?? "surface"
                defaultColor: root.rootSettings?.defaultObjectValue("specialWorkspaceOverlay", "background", "color") ?? "surface"
                currentOpacity: root.rootSettings?.objectSettingValue("specialWorkspaceOverlay", "background", "opacity") ?? 0.82
                defaultOpacity: root.rootSettings?.defaultObjectValue("specialWorkspaceOverlay", "background", "opacity") ?? 0.82
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setObjectSetting("specialWorkspaceOverlay", "background", "color", value)
                onOpacitySelected: value => root.rootSettings?.setObjectSetting("specialWorkspaceOverlay", "background", "opacity", value)
            }

            NSearchableComboBox {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.family.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.family.desc")
                model: FontService.availableFonts
                currentKey: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "font", "family") ?? ""
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "font", "family") ?? ""
                onSelected: key => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "font", "family", key)
            }

            NValueSlider {
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.size.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.size.desc")
                from: 1
                to: 24
                stepSize: 1
                value: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "font", "size") ?? 11
                text: Math.round(value) + " pt"
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "font", "size") ?? 11
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "font", "size", Math.round(sliderValue))
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.weight.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.weight.desc")
                model: root.rootSettings?.fontWeightModel
                currentKey: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "font", "weight") ?? "medium"
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "font", "weight") ?? "medium"
                onSelected: key => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "font", "weight", key)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.color.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.color.desc")
                currentColor: root.rootSettings?.stateSettingValue("specialWorkspaceOverlay", "font", "color", "color") ?? "on-surface"
                defaultColor: root.rootSettings?.defaultStateValue("specialWorkspaceOverlay", "font", "color", "color") ?? "on-surface"
                currentOpacity: root.rootSettings?.stateSettingValue("specialWorkspaceOverlay", "font", "color", "opacity") ?? 1
                defaultOpacity: root.rootSettings?.defaultStateValue("specialWorkspaceOverlay", "font", "color", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => root.rootSettings?.setStateSetting("specialWorkspaceOverlay", "font", "color", "color", value)
                onOpacitySelected: value => root.rootSettings?.setStateSetting("specialWorkspaceOverlay", "font", "color", "opacity", value)
            }
        
        }
    }

    SettingsSectionCard {
        id: animationCard
        sectionKey: "specialWorkspaceOverlay"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.sectionLabel")
        description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.sectionDesc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceSettingsActive
                opacity: root.specialWorkspaceSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.enabled.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.enabled.desc")
                checked: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "enabled")
                    ?? root.rootSettings?.settingValue("animation", "enabled")
                    ?? true
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "enabled")
                onToggled: checked => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "enabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceAnimationSettingsActive
                opacity: root.specialWorkspaceAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.type.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.type.desc")
                model: root.rootSettings?.animationTypeModel
                currentKey: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "type")
                    ?? root.rootSettings?.settingValue("animation", "type")
                    ?? "spring"
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "type")
                onSelected: key => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "type", key)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.specialWorkspaceAnimationSettingsActive
                opacity: root.specialWorkspaceAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.axis.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.axis.desc")
                model: root.rootSettings?.axisModel
                currentKey: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "axis") ?? "vertical"
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "axis")
                onSelected: key => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "axis", key)
            }

            NValueSlider {
                enabled: root.specialWorkspaceAnimationSettingsActive
                opacity: root.specialWorkspaceAnimationSettingsActive ? 1.0 : 0.45
                label: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.speed.label")
                description: root.rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: root.rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "speed")
                    ?? root.rootSettings?.settingValue("animation", "speed")
                    ?? 420
                text: Math.round(value) + " ms"
                defaultValue: root.rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "speed")
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "speed", Math.round(sliderValue))
            }
        
        }
    }
}
