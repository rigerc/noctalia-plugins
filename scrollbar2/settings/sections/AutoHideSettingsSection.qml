import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"
import "../../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias autoHideSectionTarget: autoHideCard.sectionTarget
    readonly property bool floatingPanelSettingsActive: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
    readonly property bool autoHideSettingsActive: rootSettings?.isVisibleByConditions(["floatingPanelMode", "autoHideEnabled"]) ?? false
    readonly property bool autoHideAnimatedSettingsActive: rootSettings?.isVisibleByConditions(["floatingPanelMode", "autoHideEnabled", "autoHideAnimatedEffect"]) ?? false
    readonly property bool autoHideSlideSettingsActive: rootSettings?.isVisibleByConditions(["floatingPanelMode", "autoHideEnabled", "autoHideSlideEffect"]) ?? false
    readonly property bool autoHideEdgeSliverSettingsActive: rootSettings?.isVisibleByConditions(["floatingPanelMode", "autoHideEnabled", "autoHideEdgeSliverMode"]) ?? false

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: autoHideCard
        sectionKey: "display"
        rootSettings: root.rootSettings

        title: rootSettings?.pluginApi?.tr("settings.display.autoHide.sectionLabel")
        description: rootSettings?.pluginApi?.tr("settings.display.autoHide.sectionDesc")

        SettingsSubCard {
            NToggle {
                Layout.fillWidth: true
                enabled: root.floatingPanelSettingsActive
                opacity: root.floatingPanelSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.enabled.desc")
                checked: rootSettings?.nestedSettingValue("display", "autoHide", "enabled") ?? false
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "enabled") ?? false
                onToggled: checked => rootSettings?.setNestedSetting("display", "autoHide", "enabled", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.autoHideSettingsActive
                opacity: root.autoHideSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.revealMode.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.revealMode.desc")
                model: rootSettings?.autoHideRevealModeModel
                currentKey: rootSettings?.nestedSettingValue("display", "autoHide", "revealMode") ?? "edgeSliver"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "revealMode") ?? "edgeSliver"
                onSelected: key => rootSettings?.setNestedSetting("display", "autoHide", "revealMode", key)
            }
        }

        SettingsSubCard {
            NValueSlider {
                enabled: root.autoHideSettingsActive
                opacity: root.autoHideSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.delayMs.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.delayMs.desc")
                from: 0
                to: 5000
                stepSize: 50
                value: rootSettings?.nestedSettingValue("display", "autoHide", "delayMs") ?? 1000
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "delayMs") ?? 1000
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("display", "autoHide", "delayMs", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.autoHideAnimatedSettingsActive
                opacity: root.autoHideAnimatedSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.durationMs.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.durationMs.desc")
                from: 0
                to: 1500
                stepSize: 25
                value: rootSettings?.nestedSettingValue("display", "autoHide", "durationMs") ?? 200
                text: Math.round(value) + " ms"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "durationMs") ?? 200
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("display", "autoHide", "durationMs", Math.round(sliderValue))
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.autoHideSettingsActive
                opacity: root.autoHideSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.effect.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.effect.desc")
                model: rootSettings?.autoHideEffectModel
                currentKey: rootSettings?.nestedSettingValue("display", "autoHide", "effect") ?? "slideFade"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "effect") ?? "slideFade"
                onSelected: key => rootSettings?.setNestedSetting("display", "autoHide", "effect", key)
            }

            NToggle {
                Layout.fillWidth: true
                enabled: root.autoHideSettingsActive
                opacity: root.autoHideSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.dynamicMargin.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.dynamicMargin.desc")
                checked: rootSettings?.nestedSettingValue("display", "autoHide", "dynamicMargin") ?? false
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "dynamicMargin") ?? false
                onToggled: checked => rootSettings?.setNestedSetting("display", "autoHide", "dynamicMargin", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                enabled: root.autoHideSlideSettingsActive
                opacity: root.autoHideSlideSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.slideDirection.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.slideDirection.desc")
                model: rootSettings?.autoHideSlideDirectionModel
                currentKey: rootSettings?.nestedSettingValue("display", "autoHide", "slideDirection") ?? "auto"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "slideDirection") ?? "auto"
                onSelected: key => rootSettings?.setNestedSetting("display", "autoHide", "slideDirection", key)
            }
        }

        SettingsSubCard {
            NValueSlider {
                enabled: root.autoHideEdgeSliverSettingsActive
                opacity: root.autoHideEdgeSliverSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverSize.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverSize.desc")
                from: 2
                to: 48
                stepSize: 1
                value: rootSettings?.nestedSettingValue("display", "autoHide", "edgeSliverSize") ?? 8
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "edgeSliverSize") ?? 8
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("display", "autoHide", "edgeSliverSize", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.autoHideEdgeSliverSettingsActive
                opacity: root.autoHideEdgeSliverSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverWidth.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverWidth.desc")
                from: 10
                to: 100
                stepSize: 1
                value: rootSettings?.nestedSettingValue("display", "autoHide", "edgeSliverWidth") ?? 100
                text: Math.round(value) + "%"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "edgeSliverWidth") ?? 100
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("display", "autoHide", "edgeSliverWidth", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.autoHideEdgeSliverSettingsActive
                opacity: root.autoHideEdgeSliverSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverMargin.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverMargin.desc")
                from: 0
                to: 64
                stepSize: 1
                value: rootSettings?.nestedSettingValue("display", "autoHide", "edgeSliverMargin") ?? 0
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "edgeSliverMargin") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("display", "autoHide", "edgeSliverMargin", Math.round(sliderValue))
            }

            NValueSlider {
                enabled: root.autoHideEdgeSliverSettingsActive
                opacity: root.autoHideEdgeSliverSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverRadius.desc")
                from: 0
                to: 64
                stepSize: 1
                value: rootSettings?.nestedSettingValue("display", "autoHide", "edgeSliverRadius") ?? 0
                text: value <= 0 ? rootSettings?.pluginApi?.tr("common.auto") : Math.round(value) + " px"
                defaultValue: rootSettings?.defaultNestedValue("display", "autoHide", "edgeSliverRadius") ?? 0
                showReset: true
                onMoved: sliderValue => rootSettings?.setNestedSetting("display", "autoHide", "edgeSliverRadius", Math.round(sliderValue))
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                enabled: root.autoHideEdgeSliverSettingsActive
                opacity: root.autoHideEdgeSliverSettingsActive ? 1.0 : 0.45
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverColor.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverColor.desc")
                currentColor: rootSettings?.nestedSettingValue("display", "autoHide", "edgeSliverColor") ?? "none"
                defaultColor: rootSettings?.defaultNestedValue("display", "autoHide", "edgeSliverColor") ?? "none"
                currentOpacity: rootSettings?.nestedSettingValue("display", "autoHide", "edgeSliverOpacity") ?? 1
                defaultOpacity: rootSettings?.defaultNestedValue("display", "autoHide", "edgeSliverOpacity") ?? 1
                showOpacityControl: true
                onColorSelected: value => rootSettings?.setNestedSetting("display", "autoHide", "edgeSliverColor", value)
                onOpacitySelected: value => rootSettings?.setNestedSetting("display", "autoHide", "edgeSliverOpacity", value)
            }
        }
    }
}
