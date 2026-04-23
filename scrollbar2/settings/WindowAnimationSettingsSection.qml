import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

SettingsSectionBox {
    id: root

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.window.animation.sectionLabel") ?? ""
    description: rootSettings?.pluginApi?.tr("settings.window.animation.sectionDesc") ?? ""

    readonly property bool _animEnabled: {
        const override = rootSettings ? rootSettings.getPath("window.animation.enabled") : undefined;
        if (override !== undefined && override !== null) return override !== false;
        return rootSettings ? (rootSettings.getPath("animation.enabled") ?? true) : true;
    }

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.window.animation.enabled.label")
        description: rootSettings?.pluginApi?.tr("settings.window.animation.enabled.desc")
        checked: rootSettings ? (rootSettings.getPath("window.animation.enabled") ?? rootSettings.getPath("animation.enabled") ?? true) : true
        defaultValue: rootSettings ? rootSettings.getDefault("window.animation.enabled") : undefined
        onToggled: checked => {
            if (rootSettings) rootSettings.setPath("window.animation.enabled", checked);
        }
    }

    NToggle {
        visible: root._animEnabled
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.window.animation.openEnabled.label")
        description: rootSettings?.pluginApi?.tr("settings.window.animation.openEnabled.desc")
        checked: rootSettings ? (rootSettings.getPath("window.animation.openEnabled") ?? true) : true
        defaultValue: rootSettings ? rootSettings.getDefault("window.animation.openEnabled") ?? true : true
        onToggled: checked => {
            if (rootSettings) rootSettings.setPath("window.animation.openEnabled", checked);
        }
    }

    NToggle {
        visible: root._animEnabled
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.window.animation.closeEnabled.label")
        description: rootSettings?.pluginApi?.tr("settings.window.animation.closeEnabled.desc")
        checked: rootSettings ? (rootSettings.getPath("window.animation.closeEnabled") ?? true) : true
        defaultValue: rootSettings ? rootSettings.getDefault("window.animation.closeEnabled") ?? true : true
        onToggled: checked => {
            if (rootSettings) rootSettings.setPath("window.animation.closeEnabled", checked);
        }
    }

    NComboBox {
        visible: root._animEnabled
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.window.animation.type.label")
        description: rootSettings?.pluginApi?.tr("settings.window.animation.type.desc")
        model: rootSettings?.animationTypeModel
        currentKey: rootSettings ? (rootSettings.getPath("window.animation.type") ?? rootSettings.getPath("animation.type") ?? "spring") : "spring"
        defaultValue: rootSettings ? rootSettings.getDefault("window.animation.type") : undefined
        onSelected: key => {
            if (rootSettings) rootSettings.setPath("window.animation.type", key);
        }
    }

    NValueSlider {
        visible: root._animEnabled
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.window.animation.speed.label")
        description: rootSettings?.pluginApi?.tr("settings.window.animation.speed.desc")
        from: 50; to: 1500; stepSize: 25
        value: rootSettings ? (rootSettings.getPath("window.animation.speed") ?? rootSettings.getPath("animation.speed") ?? 420) : 420
        text: Math.round(value) + " ms"
        defaultValue: rootSettings ? rootSettings.getDefault("window.animation.speed") : undefined
        showReset: true
        onMoved: sliderValue => {
            if (rootSettings) rootSettings.setPath("window.animation.speed", Math.round(sliderValue));
        }
    }
}
