import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias displaySectionTarget: displayContent

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: displayContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: displayContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.display.label")
                description: rootSettings?.pluginApi?.tr("settings.section.display.desc")
            }

            SettingsComboBox {
                settingPath: "display.mode"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.displayModeModel
                label: rootSettings?.pluginApi?.tr("settings.display.mode.label")
                description: rootSettings?.pluginApi?.tr("settings.display.mode.desc")
            }

            SettingsComboBox {
                settingPath: "track.position"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.trackPositionModel
                label: rootSettings?.pluginApi?.tr("settings.track.position.label")
                description: rootSettings?.pluginApi?.tr("settings.track.position.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsSlider {
                settingPath: "display.scale"
                rootSettings: root.rootSettings
                from: 0.5; to: 2.0; stepSize: 0.05
                unit: "%"
                label: rootSettings?.pluginApi?.tr("settings.display.scale.label")
                description: rootSettings?.pluginApi?.tr("settings.display.scale.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsSlider {
                settingPath: "display.margin"
                rootSettings: root.rootSettings
                from: 0; to: 48; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.display.margin.label")
                description: rootSettings?.pluginApi?.tr("settings.display.margin.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsSlider {
                settingPath: "display.offsetH"
                rootSettings: root.rootSettings
                from: -200; to: 200; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.display.offsetH.label")
                description: rootSettings?.pluginApi?.tr("settings.display.offsetH.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsSlider {
                settingPath: "display.offsetV"
                rootSettings: root.rootSettings
                from: -200; to: 200; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.display.offsetV.label")
                description: rootSettings?.pluginApi?.tr("settings.display.offsetV.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsSlider {
                settingPath: "display.radiusScale"
                rootSettings: root.rootSettings
                from: 0; to: 3; stepSize: 0.05
                unit: "%"
                label: rootSettings?.pluginApi?.tr("settings.display.radiusScale.label")
                description: rootSettings?.pluginApi?.tr("settings.display.radiusScale.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsColorField {
                pluginApi: rootSettings?.pluginApi
                rootSettings: root.rootSettings
                settingPath: "display.background"
                label: rootSettings?.pluginApi?.tr("settings.display.backgroundColor.label")
                description: rootSettings?.pluginApi?.tr("settings.display.backgroundColor.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsToggle {
                settingPath: "display.gradientEnabled"
                rootSettings: root.rootSettings
                label: rootSettings?.pluginApi?.tr("settings.display.gradientEnabled.label")
                description: rootSettings?.pluginApi?.tr("settings.display.gradientEnabled.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsColorField {
                pluginApi: rootSettings?.pluginApi
                rootSettings: root.rootSettings
                settingPath: "display.gradient"
                label: rootSettings?.pluginApi?.tr("settings.display.gradientColor.label")
                description: rootSettings?.pluginApi?.tr("settings.display.gradientColor.desc")
                visibilityConditions: ["floatingPanelMode", "displayGradientEnabled"]
            }

            SettingsComboBox {
                settingPath: "display.gradientDirection"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.gradientDirectionModel
                label: rootSettings?.pluginApi?.tr("settings.display.gradientDirection.label")
                description: rootSettings?.pluginApi?.tr("settings.display.gradientDirection.desc")
                visibilityConditions: ["floatingPanelMode", "displayGradientEnabled"]
            }

            NHeader {
                visible: rootSettings?.isVisibleByConditions(["floatingPanelMode"]) ?? true
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.sectionLabel")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.sectionDesc")
            }

            SettingsToggle {
                settingPath: "display.autoHide.enabled"
                rootSettings: root.rootSettings
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.enabled.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.enabled.desc")
                visibilityConditions: ["floatingPanelMode"]
            }

            SettingsComboBox {
                settingPath: "display.autoHide.revealMode"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.autoHideRevealModeModel
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.revealMode.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.revealMode.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled"]
            }

            SettingsSlider {
                settingPath: "display.autoHide.delayMs"
                rootSettings: root.rootSettings
                from: 0; to: 5000; stepSize: 50
                unit: "ms"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.delayMs.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.delayMs.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled"]
            }

            SettingsSlider {
                settingPath: "display.autoHide.durationMs"
                rootSettings: root.rootSettings
                from: 0; to: 1500; stepSize: 25
                unit: "ms"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.durationMs.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.durationMs.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideAnimatedEffect"]
            }

            SettingsComboBox {
                settingPath: "display.autoHide.effect"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.autoHideEffectModel
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.effect.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.effect.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled"]
            }

            SettingsToggle {
                settingPath: "display.autoHide.dynamicMargin"
                rootSettings: root.rootSettings
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.dynamicMargin.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.dynamicMargin.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled"]
            }

            SettingsComboBox {
                settingPath: "display.autoHide.slideDirection"
                rootSettings: root.rootSettings
                modelSource: rootSettings?.autoHideSlideDirectionModel
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.slideDirection.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.slideDirection.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideSlideEffect"]
            }

            SettingsSlider {
                settingPath: "display.autoHide.edgeSliverSize"
                rootSettings: root.rootSettings
                from: 2; to: 48; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverSize.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverSize.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideEdgeSliverMode"]
            }

            SettingsSlider {
                settingPath: "display.autoHide.edgeSliverWidth"
                rootSettings: root.rootSettings
                from: 10; to: 100; stepSize: 1
                unit: "%"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverWidth.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverWidth.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideEdgeSliverMode"]
            }

            SettingsSlider {
                settingPath: "display.autoHide.edgeSliverMargin"
                rootSettings: root.rootSettings
                from: 0; to: 64; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverMargin.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverMargin.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideEdgeSliverMode"]
            }

            SettingsSlider {
                settingPath: "display.autoHide.edgeSliverRadius"
                rootSettings: root.rootSettings
                from: 0; to: 64; stepSize: 1
                unit: "px"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverRadius.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverRadius.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideEdgeSliverMode"]
            }

            SettingsColorField {
                pluginApi: rootSettings?.pluginApi
                rootSettings: root.rootSettings
                settingPath: "display.autoHide.edgeSliverColor"
                separateOpacityPath: "display.autoHide.edgeSliverOpacity"
                label: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverColor.label")
                description: rootSettings?.pluginApi?.tr("settings.display.autoHide.edgeSliverColor.desc")
                visibilityConditions: ["floatingPanelMode", "autoHideEnabled", "autoHideEdgeSliverMode"]
            }
        }
    }
}
