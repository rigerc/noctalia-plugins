import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias filteringSectionTarget: filteringContent
    property alias animationSectionTarget: animationContent
    property alias mouseInteractionSectionTarget: mouseInteractionContent

    Layout.fillWidth: true
    spacing: Style.marginL

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: filteringContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: filteringContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.filtering.label")
                description: rootSettings?.pluginApi?.tr("settings.section.filtering.desc")
            }

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

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: animationContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: animationContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.animation.label")
                description: rootSettings?.pluginApi?.tr("settings.section.animation.desc")
            }

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
                label: rootSettings?.pluginApi?.tr("settings.animation.type.label")
                description: rootSettings?.pluginApi?.tr("settings.animation.type.desc")
                model: rootSettings?.animationTypeModel
                currentKey: rootSettings?.settingValue("animation", "type") ?? "spring"
                defaultValue: rootSettings?.defaultValue("animation", "type") ?? "spring"
                onSelected: key => rootSettings?.setSetting("animation", "type", key)
            }

            NValueSlider {
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

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: mouseInteractionContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: mouseInteractionContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.label")
                description: rootSettings?.pluginApi?.tr("settings.section.mouseInteraction.desc")
            }

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
        }
    }
}
