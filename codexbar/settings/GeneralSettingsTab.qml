import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: tab

    property var rootSettings: null
    readonly property var mainInstance: rootSettings?.pluginApi?.mainInstance

    title: rootSettings?.pluginApi?.tr("settings.tabs.general") || "General"
    description: rootSettings?.pluginApi?.tr("settings.general.description") || "Configure bar widget appearance and refresh behavior"
    icon: "mdi:sparkles"

    NTextInput {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.general.barIcon.label")
        description: rootSettings?.pluginApi?.tr("settings.general.barIcon.desc")
        text: rootSettings?.editBarIcon ?? "mdi:sparkles"
        onTextChanged: {
            if (rootSettings) rootSettings.editBarIcon = text;
        }
    }

    NColorChoice {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.general.barIconColor.label")
        value: rootSettings?.editBarIconColor ?? "on-surface"
        onValueChanged: {
            if (rootSettings) rootSettings.editBarIconColor = value;
        }
    }

    NSlider {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.general.refreshInterval.label")
        description: rootSettings?.pluginApi?.tr("settings.general.refreshInterval.desc")
        from: 30
        to: 600
        stepSize: 30
        value: rootSettings?.editRefreshInterval ?? 120
        suffix: "s"
        onMoved: {
            if (rootSettings) rootSettings.editRefreshInterval = value;
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
            text: rootSettings?.pluginApi?.tr("settings.general.defaultProvider.label") || "Default Provider"
            font.pixelSize: Style.fontSizeS
            color: Color.mOnSurface
        }

        NText {
            text: rootSettings?.pluginApi?.tr("settings.general.defaultProvider.desc") || "Provider shown in the bar widget"
            font.pixelSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
        }

        NComboBox {
            Layout.fillWidth: true
            model: {
                var items = [{"key": "", "name": "Auto (first available)"}];
                var providers = mainInstance?.providerData || [];
                for (var i = 0; i < providers.length; i++) {
                    var pid = String(providers[i].provider || "");
                    var displayName = mainInstance?.providerDisplayName(pid) || pid;
                    items.push({"key": pid, "name": displayName});
                }
                return items;
            }
            textRole: "name"
            valueRole: "key"
            currentValue: rootSettings?.editDefaultProvider ?? ""
            onCurrentValueChanged: {
                if (rootSettings) rootSettings.editDefaultProvider = currentValue;
            }
        }
    }
}
