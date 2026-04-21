import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: tab

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.tabs.notifications") || "Notifications"
    description: rootSettings?.pluginApi?.tr("settings.notifications.description") || "Configure when to show notifications"
    icon: "bell"

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.notifications.notifyOnReset.label")
        description: rootSettings?.pluginApi?.tr("settings.notifications.notifyOnReset.desc")
        checked: rootSettings?.editNotifyOnReset ?? true
        onCheckedChanged: {
            if (rootSettings) rootSettings.editNotifyOnReset = checked;
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.notifications.notifyOnLowUsage.label")
        description: rootSettings?.pluginApi?.tr("settings.notifications.notifyOnLowUsage.desc")
        checked: rootSettings?.editNotifyOnLowUsage ?? true
        onCheckedChanged: {
            if (rootSettings) rootSettings.editNotifyOnLowUsage = checked;
        }
    }

    NSpinBox {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.notifications.lowUsageThreshold.label")
        description: rootSettings?.pluginApi?.tr("settings.notifications.lowUsageThreshold.desc")
        from: 5
        to: 50
        stepSize: 5
        value: rootSettings?.editLowUsageThreshold ?? 20
        suffix: "%"
        onValueChanged: {
            if (rootSettings) rootSettings.editLowUsageThreshold = value;
        }
    }
}
