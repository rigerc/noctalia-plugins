import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias specialWorkspaceSectionTarget: content
    property alias animationSectionTarget: animationContent

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: content.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.specialWorkspaceOverlay.label")
                description: rootSettings?.pluginApi?.tr("settings.section.specialWorkspaceOverlay.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.enabled.desc")
                checked: rootSettings?.settingValue("specialWorkspaceOverlay", "enabled") ?? false
                defaultValue: rootSettings?.defaultValue("specialWorkspaceOverlay", "enabled") ?? false
                onToggled: checked => rootSettings?.setSetting("specialWorkspaceOverlay", "enabled", checked)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.textMode.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.textMode.desc")
                model: rootSettings?.specialWorkspaceOverlayTextModeModel
                currentKey: rootSettings?.settingValue("specialWorkspaceOverlay", "textMode") ?? "stripped"
                defaultValue: rootSettings?.defaultValue("specialWorkspaceOverlay", "textMode") ?? "stripped"
                onSelected: key => rootSettings?.setSetting("specialWorkspaceOverlay", "textMode", key)
            }

            NTextInput {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled", "specialWorkspaceOverlayCustomMode"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.customLabel.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.customLabel.desc")
                text: rootSettings?.settingValue("specialWorkspaceOverlay", "customLabel") ?? ""
                onTextChanged: rootSettings?.setSetting("specialWorkspaceOverlay", "customLabel", text)
            }

            NToggle {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.showWindowIcons.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.showWindowIcons.desc")
                checked: rootSettings?.settingValue("specialWorkspaceOverlay", "showWindowIcons") ?? false
                defaultValue: rootSettings?.defaultValue("specialWorkspaceOverlay", "showWindowIcons") ?? false
                onToggled: checked => rootSettings?.setSetting("specialWorkspaceOverlay", "showWindowIcons", checked)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.widthPercent.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.widthPercent.desc")
                from: 50
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("specialWorkspaceOverlay", "widthPercent") ?? 100
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("specialWorkspaceOverlay", "widthPercent") ?? 100
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("specialWorkspaceOverlay", "widthPercent", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.heightPercent.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.heightPercent.desc")
                from: 50
                to: 100
                stepSize: 1
                value: rootSettings?.settingValue("specialWorkspaceOverlay", "heightPercent") ?? 70
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultValue("specialWorkspaceOverlay", "heightPercent") ?? 70
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("specialWorkspaceOverlay", "heightPercent", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.borderRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.borderRadius.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("specialWorkspaceOverlay", "borderRadius") ?? 3
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("specialWorkspaceOverlay", "borderRadius") ?? 3
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("specialWorkspaceOverlay", "borderRadius", Math.round(sliderValue))
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.background.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.background.desc")
                currentColor: rootSettings?.objectSettingValue("specialWorkspaceOverlay", "background", "color") ?? "surface"
                defaultColor: rootSettings?.defaultObjectValue("specialWorkspaceOverlay", "background", "color") ?? "surface"
                currentOpacity: rootSettings?.objectSettingValue("specialWorkspaceOverlay", "background", "opacity") ?? 0.82
                defaultOpacity: rootSettings?.defaultObjectValue("specialWorkspaceOverlay", "background", "opacity") ?? 0.82
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setObjectSetting("specialWorkspaceOverlay", "background", "color", value)
                onOpacitySelected: value => rootSettings?.setObjectSetting("specialWorkspaceOverlay", "background", "opacity", value)
            }

            NSearchableComboBox {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.family.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.family.desc")
                model: FontService.availableFonts
                currentKey: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "font", "family") ?? ""
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "font", "family") ?? ""
                onSelected: key => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "font", "family", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.size.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.size.desc")
                from: 1
                to: 24
                stepSize: 1
                value: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "font", "size") ?? 11
                text: Math.round(value) + " pt"
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "font", "size") ?? 11
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "font", "size", Math.round(sliderValue))
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.weight.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.weight.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "font", "weight") ?? "medium"
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "font", "weight") ?? "medium"
                onSelected: key => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "font", "weight", key)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.color.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.font.color.desc")
                currentColor: rootSettings?.stateSettingValue("specialWorkspaceOverlay", "font", "color", "color") ?? "on-surface"
                defaultColor: rootSettings?.defaultStateValue("specialWorkspaceOverlay", "font", "color", "color") ?? "on-surface"
                currentOpacity: rootSettings?.stateSettingValue("specialWorkspaceOverlay", "font", "color", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("specialWorkspaceOverlay", "font", "color", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("specialWorkspaceOverlay", "font", "color", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("specialWorkspaceOverlay", "font", "color", "opacity", value)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: animationContent.implicitHeight + Style.marginL * 2
        visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayEnabled"]) ?? false

        ColumnLayout {
            id: animationContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.sectionLabel")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.sectionDesc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.enabled.desc")
                checked: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "enabled")
                    ?? rootSettings?.settingValue("animation", "enabled")
                    ?? true
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "enabled")
                onToggled: checked => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "enabled", checked)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayAnimationEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.type.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.type.desc")
                model: rootSettings?.animationTypeModel
                currentKey: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "type")
                    ?? rootSettings?.settingValue("animation", "type")
                    ?? "spring"
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "type")
                onSelected: key => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "type", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayAnimationEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.axis.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.axis.desc")
                model: rootSettings?.axisModel
                currentKey: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "axis") ?? "vertical"
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "axis")
                onSelected: key => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "axis", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["specialWorkspaceOverlayAnimationEnabled"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.speed.label")
                description: rootSettings?.pluginApi?.tr("settings.specialWorkspaceOverlay.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: rootSettings?.nestedSettingValue("specialWorkspaceOverlay", "animation", "speed")
                    ?? rootSettings?.settingValue("animation", "speed")
                    ?? 420
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultNestedValue("specialWorkspaceOverlay", "animation", "speed")
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("specialWorkspaceOverlay", "animation", "speed", Math.round(sliderValue))
            }
        }
    }
}
