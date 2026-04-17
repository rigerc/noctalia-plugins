import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    readonly property bool windowFilteringSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        []
    ]) ?? true
    readonly property bool interactionSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        []
    ]) ?? true
    readonly property bool autoScrollSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        ["centerFocusedWindow"]
    ]) ?? true
    readonly property bool workspaceAnimationSectionVisible: rootSettings?.sectionHasVisibleSettings([
        [],
        ["workspaceAnimationEnabled"]
    ]) ?? true
    readonly property bool advancedSectionVisible: rootSettings?.sectionHasVisibleSettings([
        []
    ]) ?? true

    Layout.fillWidth: true
    spacing: Style.marginXL

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.windowFiltering.label")
        description: rootSettings?.pluginApi?.tr("settings.section.windowFiltering.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.onlySameOutput.label")
        description: rootSettings?.pluginApi?.tr("settings.onlySameOutput.desc")
        checked: rootSettings?.settingValue("filtering", "onlySameOutput") ?? true
        onToggled: checked => rootSettings?.setSetting("filtering", "onlySameOutput", checked)
        defaultValue: rootSettings?.defaultValue("filtering", "onlySameOutput") ?? true
    }

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.onlyActiveWorkspaces.label")
        description: rootSettings?.pluginApi?.tr("settings.onlyActiveWorkspaces.desc")
        checked: rootSettings?.settingValue("filtering", "onlyActiveWorkspaces") ?? true
        onToggled: checked => rootSettings?.setSetting("filtering", "onlyActiveWorkspaces", checked)
        defaultValue: rootSettings?.defaultValue("filtering", "onlyActiveWorkspaces") ?? true
    }

    NLabel {
        visible: !windowFilteringSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.interaction.label")
        description: rootSettings?.pluginApi?.tr("settings.section.interaction.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.enableReorder.label")
        description: rootSettings?.pluginApi?.tr("settings.enableReorder.desc")
        checked: rootSettings?.settingValue("interaction", "enableReorder") ?? true
        onToggled: checked => rootSettings?.setSetting("interaction", "enableReorder", checked)
        defaultValue: rootSettings?.defaultValue("interaction", "enableReorder") ?? true
    }

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.enableScrollWheel.label")
        description: rootSettings?.pluginApi?.tr("settings.enableScrollWheel.desc")
        checked: rootSettings?.settingValue("interaction", "enableScrollWheel") ?? true
        onToggled: checked => rootSettings?.setSetting("interaction", "enableScrollWheel", checked)
        defaultValue: rootSettings?.defaultValue("interaction", "enableScrollWheel") ?? true
    }

    NLabel {
        visible: !interactionSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.autoScroll.label")
        description: rootSettings?.pluginApi?.tr("settings.section.autoScroll.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.centerFocusedWindow.label")
        description: rootSettings?.pluginApi?.tr("settings.centerFocusedWindow.desc")
        checked: rootSettings?.settingValue("autoScroll", "centerFocusedWindow") ?? true
        onToggled: checked => rootSettings?.setSetting("autoScroll", "centerFocusedWindow", checked)
        defaultValue: rootSettings?.defaultValue("autoScroll", "centerFocusedWindow") ?? true
    }

    NValueSlider {
        visible: rootSettings?.isVisibleByConditions(["centerFocusedWindow"]) ?? true
        label: rootSettings?.pluginApi?.tr("settings.centerAnimationMs.label")
        description: rootSettings?.pluginApi?.tr("settings.centerAnimationMs.desc")
        from: 0
        to: 500
        stepSize: 10
        value: rootSettings?.settingValue("autoScroll", "centerAnimationMs") ?? 200
        text: Math.round(value) + " ms"
        defaultValue: rootSettings?.defaultValue("autoScroll", "centerAnimationMs") ?? 200
        showReset: true
        onMoved: sliderValue => rootSettings?.setSetting("autoScroll", "centerAnimationMs", Math.round(sliderValue))
    }

    NLabel {
        visible: !autoScrollSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.workspaceAnimation.label")
        description: rootSettings?.pluginApi?.tr("settings.section.workspaceAnimation.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceAnimationEnabled.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceAnimationEnabled.desc")
        checked: rootSettings?.settingValue("workspaceAnimation", "enabled") ?? false
        onToggled: checked => rootSettings?.setSetting("workspaceAnimation", "enabled", checked)
        defaultValue: rootSettings?.defaultValue("workspaceAnimation", "enabled") ?? false
    }

    NComboBox {
        visible: rootSettings?.isVisibleByConditions(["workspaceAnimationEnabled"]) ?? true
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.workspaceAnimationAxis.label")
        description: rootSettings?.pluginApi?.tr("settings.workspaceAnimationAxis.desc")
        model: rootSettings?.workspaceAnimationAxisModel
        currentKey: rootSettings?.settingValue("workspaceAnimation", "axis") ?? "horizontal"
        defaultValue: rootSettings?.defaultValue("workspaceAnimation", "axis") ?? "horizontal"
        onSelected: key => rootSettings?.setSetting("workspaceAnimation", "axis", key)
    }

    NLabel {
        visible: !workspaceAnimationSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.section.advanced.label")
        description: rootSettings?.pluginApi?.tr("settings.section.advanced.desc")
    }
    NDivider {}

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.debugLogging.label")
        description: rootSettings?.pluginApi?.tr("settings.debugLogging.desc")
        checked: rootSettings?.settingValue("advanced", "debugLogging") ?? false
        onToggled: checked => rootSettings?.setSetting("advanced", "debugLogging", checked)
        defaultValue: rootSettings?.defaultValue("advanced", "debugLogging") ?? false
    }

    NLabel {
        visible: !advancedSectionVisible
        description: rootSettings?.pluginApi?.tr("settings.emptySectionNote")
        descriptionColor: Color.mOnSurfaceVariant
    }
}
