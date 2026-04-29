import QtQuick.Layouts
import qs.Widgets

SettingsTabPage {
    id: tab

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.tabs.notifications") || "Notifications"
    description: rootSettings?.pluginApi?.tr("settings.notifications.description") || "Configure when to show notifications"
    icon: "bell"

    NToggle {
        Layout.fillWidth: true
        label: tab.rootSettings?.pluginApi?.tr("settings.notifications.notifyOnReset.label")
        description: tab.rootSettings?.pluginApi?.tr("settings.notifications.notifyOnReset.desc")
        checked: tab.rootSettings?.editNotifyOnReset ?? true
        onToggled: checked => {
            if (tab.rootSettings)
                tab.rootSettings.editNotifyOnReset = checked;
        }
    }

    NToggle {
        Layout.fillWidth: true
        label: tab.rootSettings?.pluginApi?.tr("settings.notifications.notifyOnLowUsage.label")
        description: tab.rootSettings?.pluginApi?.tr("settings.notifications.notifyOnLowUsage.desc")
        checked: tab.rootSettings?.editNotifyOnLowUsage ?? true
        onToggled: checked => {
            if (tab.rootSettings)
                tab.rootSettings.editNotifyOnLowUsage = checked;
        }
    }

    NSpinBox {
        Layout.fillWidth: true
        label: tab.rootSettings?.pluginApi?.tr("settings.notifications.lowUsageThreshold.label")
        description: tab.rootSettings?.pluginApi?.tr("settings.notifications.lowUsageThreshold.desc")
        from: 5
        to: 50
        stepSize: 5
        value: tab.rootSettings?.editLowUsageThreshold ?? 20
        suffix: "%"
        onValueChanged: {
            if (tab.rootSettings) tab.rootSettings.editLowUsageThreshold = value;
        }
    }
}
