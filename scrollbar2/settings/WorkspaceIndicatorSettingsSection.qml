import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: indicatorContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: indicatorContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.label")
                description: rootSettings?.pluginApi?.tr("settings.section.workspaceIndicator.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.enabled.desc")
                checked: rootSettings?.settingValue("workspaceIndicator", "enabled") ?? false
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "enabled") ?? false
                onToggled: checked => rootSettings?.setSetting("workspaceIndicator", "enabled", checked)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.labelMode.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.labelMode.desc")
                model: rootSettings?.workspaceIndicatorLabelModeModel
                currentKey: rootSettings?.settingValue("workspaceIndicator", "labelMode") ?? "id"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "labelMode") ?? "id"
                onSelected: key => rootSettings?.setSetting("workspaceIndicator", "labelMode", key)
            }

            NTextInput {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.presetText.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.presetText.desc")
                text: rootSettings?.settingValue("workspaceIndicator", "presetText") ?? ""
                onTextChanged: rootSettings?.setSetting("workspaceIndicator", "presetText", text)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.position.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.position.desc")
                model: rootSettings?.workspaceIndicatorPositionModel
                currentKey: rootSettings?.settingValue("workspaceIndicator", "position") ?? "left"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "position") ?? "left"
                onSelected: key => rootSettings?.setSetting("workspaceIndicator", "position", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.verticalAlign.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.verticalAlign.desc")
                model: rootSettings?.focusVerticalModel
                currentKey: rootSettings?.settingValue("workspaceIndicator", "verticalAlign") ?? "center"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "verticalAlign") ?? "center"
                onSelected: key => rootSettings?.setSetting("workspaceIndicator", "verticalAlign", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingX.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingX.desc")
                from: 0
                to: 32
                stepSize: 1
                value: rootSettings?.settingValue("workspaceIndicator", "paddingX") ?? 10
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "paddingX") ?? 10
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "paddingX", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingY.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.paddingY.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.settingValue("workspaceIndicator", "paddingY") ?? 4
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "paddingY") ?? 4
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "paddingY", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginLeft.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginLeft.desc")
                from: 0
                to: 48
                stepSize: 1
                value: rootSettings?.settingValue("workspaceIndicator", "marginLeft") ?? 8
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "marginLeft") ?? 8
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "marginLeft", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginRight.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.marginRight.desc")
                from: 0
                to: 48
                stepSize: 1
                value: rootSettings?.settingValue("workspaceIndicator", "marginRight") ?? 8
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "marginRight") ?? 8
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "marginRight", Math.round(sliderValue))
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.borderRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.borderRadius.desc")
                from: 0
                to: 999
                stepSize: 1
                value: rootSettings?.settingValue("workspaceIndicator", "borderRadius") ?? 999
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("workspaceIndicator", "borderRadius") ?? 999
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("workspaceIndicator", "borderRadius", Math.round(sliderValue))
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.background.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.background.desc")
                currentColor: rootSettings?.objectSettingValue("workspaceIndicator", "background", "color") ?? "surface"
                defaultColor: rootSettings?.defaultObjectValue("workspaceIndicator", "background", "color") ?? "surface"
                currentOpacity: rootSettings?.objectSettingValue("workspaceIndicator", "background", "opacity") ?? 0.72
                defaultOpacity: rootSettings?.defaultObjectValue("workspaceIndicator", "background", "opacity") ?? 0.72
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setObjectSetting("workspaceIndicator", "background", "color", value)
                onOpacitySelected: value => rootSettings?.setObjectSetting("workspaceIndicator", "background", "opacity", value)
            }

            NSearchableComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.family.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.family.desc")
                model: FontService.availableFonts
                currentKey: rootSettings?.nestedSettingValue("workspaceIndicator", "font", "family") ?? ""
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "font", "family") ?? ""
                onSelected: key => rootSettings?.setNestedSetting("workspaceIndicator", "font", "family", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.size.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.size.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.nestedSettingValue("workspaceIndicator", "font", "size") ?? 11
                text: value === 0 ? rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "font", "size") ?? 11
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("workspaceIndicator", "font", "size", Math.round(sliderValue))
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.weight.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.weight.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("workspaceIndicator", "font", "weight") ?? "medium"
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "font", "weight") ?? "medium"
                onSelected: key => rootSettings?.setNestedSetting("workspaceIndicator", "font", "weight", key)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.color.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.font.color.desc")
                currentColor: rootSettings?.stateSettingValue("workspaceIndicator", "font", "color", "color") ?? "on-surface"
                defaultColor: rootSettings?.defaultStateValue("workspaceIndicator", "font", "color", "color") ?? "on-surface"
                currentOpacity: rootSettings?.stateSettingValue("workspaceIndicator", "font", "color", "opacity") ?? 1
                defaultOpacity: rootSettings?.defaultStateValue("workspaceIndicator", "font", "color", "opacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setStateSetting("workspaceIndicator", "font", "color", "color", value)
                onOpacitySelected: value => rootSettings?.setStateSetting("workspaceIndicator", "font", "color", "opacity", value)
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: badgeContent.implicitHeight + Style.marginL * 2
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false

        ColumnLayout {
            id: badgeContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.sectionLabel")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.sectionDesc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.enabled.desc")
                checked: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "enabled") ?? false
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "enabled") ?? false
                onToggled: checked => rootSettings?.setNestedSetting("workspaceIndicator", "badge", "enabled", checked)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorBadgeEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.background.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.background.desc")
                currentColor: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.color ?? "primary"
                defaultColor: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "background")?.color ?? "primary"
                currentOpacity: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.opacity ?? 1
                defaultOpacity: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "background")?.opacity ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setNestedSetting("workspaceIndicator", "badge", "background", { "color": value, "opacity": rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.opacity ?? 1 })
                onOpacitySelected: value => rootSettings?.setNestedSetting("workspaceIndicator", "badge", "background", { "color": rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "background")?.color ?? "primary", "opacity": value })
            }

            NSearchableComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorBadgeEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.family.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.family.desc")
                model: FontService.availableFonts
                currentKey: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.family ?? ""
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.family ?? ""
                onSelected: key => {
                    const current = rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": key,
                        "size": current.size ?? 10,
                        "weight": current.weight ?? "semibold",
                        "color": current.color ?? { "color": "on-primary", "opacity": 1 }
                    });
                }
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorBadgeEnabled"]) ?? false
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.size.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.size.desc")
                from: 0
                to: 24
                stepSize: 1
                value: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.size ?? 10
                text: value === 0 ? rootSettings?.pluginApi?.tr("common.auto") : (Math.round(value) + " pt")
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.size ?? 10
                showReset: true
                onMoved: sliderValue => {
                    const current = rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": Math.round(sliderValue),
                        "weight": current.weight ?? "semibold",
                        "color": current.color ?? { "color": "on-primary", "opacity": 1 }
                    });
                }
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorBadgeEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.weight.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.weight.desc")
                model: rootSettings?.fontWeightModel
                currentKey: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.weight ?? "semibold"
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.weight ?? "semibold"
                onSelected: key => {
                    const current = rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": current.size ?? 10,
                        "weight": key,
                        "color": current.color ?? { "color": "on-primary", "opacity": 1 }
                    });
                }
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorBadgeEnabled"]) ?? false
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.color.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.badge.font.color.desc")
                currentColor: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.color?.color ?? "on-primary"
                defaultColor: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.color?.color ?? "on-primary"
                currentOpacity: rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font")?.color?.opacity ?? 1
                defaultOpacity: rootSettings?.defaultNestedValue("workspaceIndicator", "badge", "font")?.color?.opacity ?? 1
                showOpacityControl: true
                onColorSelected: value => {
                    const current = rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": current.size ?? 10,
                        "weight": current.weight ?? "semibold",
                        "color": { "color": value, "opacity": current.color?.opacity ?? 1 }
                    });
                }
                onOpacitySelected: value => {
                    const current = rootSettings?.nestedSettingValue("workspaceIndicator", "badge", "font") || ({});
                    rootSettings?.setNestedSetting("workspaceIndicator", "badge", "font", {
                        "family": current.family ?? "JetBrains Mono",
                        "size": current.size ?? 10,
                        "weight": current.weight ?? "semibold",
                        "color": { "color": current.color?.color ?? "on-primary", "opacity": value }
                    });
                }
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: animationContent.implicitHeight + Style.marginL * 2
        visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorEnabled"]) ?? false

        ColumnLayout {
            id: animationContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.sectionLabel")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.sectionDesc")
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.enabled.desc")
                checked: rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "enabled") ?? true
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "enabled") ?? true
                onToggled: checked => rootSettings?.setNestedSetting("workspaceIndicator", "animation", "enabled", checked)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorAnimationEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.type.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.type.desc")
                model: rootSettings?.animationTypeModel
                currentKey: rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "type") ?? "smooth"
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "type") ?? "smooth"
                onSelected: key => rootSettings?.setNestedSetting("workspaceIndicator", "animation", "type", key)
            }

            NComboBox {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorAnimationEnabled"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.axis.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.axis.desc")
                model: rootSettings?.axisModel
                currentKey: rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "axis") ?? "horizontal"
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "axis") ?? "horizontal"
                onSelected: key => rootSettings?.setNestedSetting("workspaceIndicator", "animation", "axis", key)
            }

            NValueSlider {
                visible: rootSettings?.isVisibleByConditions(["workspaceIndicatorAnimationEnabled"]) ?? true
                label: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.speed.label")
                description: rootSettings?.pluginApi?.tr("settings.workspaceIndicator.animation.speed.desc")
                from: 50
                to: 1500
                stepSize: 25
                value: rootSettings?.nestedSettingValue("workspaceIndicator", "animation", "speed") ?? 220
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultNestedValue("workspaceIndicator", "animation", "speed") ?? 220
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("workspaceIndicator", "animation", "speed", Math.round(sliderValue))
            }
        }
    }
}
