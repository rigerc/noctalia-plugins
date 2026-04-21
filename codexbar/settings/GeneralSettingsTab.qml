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
    icon: "sparkles"

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.general.barIcon.label")
        description: rootSettings?.pluginApi?.tr("settings.general.barIcon.desc")
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
            Layout.preferredWidth: Style.fontSizeXL * 2
            Layout.preferredHeight: Style.fontSizeXL * 2
            Layout.alignment: Qt.AlignVCenter
            icon: rootSettings?.editBarIcon ?? "sparkles"
            pointSize: Style.fontSizeXL * 1.6
            color: Color.resolveColorKey(rootSettings?.editBarIconColor ?? "on-surface")
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: rootSettings?.pluginApi?.tr("settings.general.barIcon.browse")
                    onClicked: barIconPicker.open()
                }
            }

            NText {
                Layout.fillWidth: true
                text: rootSettings?.editBarIcon ?? "sparkles"
                color: Color.mOnSurfaceVariant
                elide: Text.ElideRight
            }
        }
    }

    NIconPicker {
        id: barIconPicker
        initialIcon: rootSettings?.editBarIcon ?? "sparkles"
        onIconSelected: iconName => {
            if (rootSettings)
                rootSettings.editBarIcon = rootSettings.normalizeIconName(iconName);
        }
    }

    NColorChoice {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.general.barIconColor.label")
        currentKey: rootSettings?.editBarIconColor ?? "on-surface"
        onSelected: key => {
            if (rootSettings) rootSettings.editBarIconColor = key;
        }
    }

    NLabel {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.general.refreshInterval.label")
        description: rootSettings?.pluginApi?.tr("settings.general.refreshInterval.desc") + " (" + (rootSettings?.editRefreshInterval ?? 120) + "s)"
    }

    NSlider {
        Layout.fillWidth: true
        from: 30
        to: 600
        stepSize: 30
        value: rootSettings?.editRefreshInterval ?? 120
        onValueChanged: {
            if (rootSettings) rootSettings.editRefreshInterval = value;
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
            text: rootSettings?.pluginApi?.tr("settings.general.defaultProvider.label") || "Default Provider"
            pointSize: Style.fontSizeS
            color: Color.mOnSurface
        }

        NText {
            text: rootSettings?.pluginApi?.tr("settings.general.defaultProvider.desc") || "Provider shown in the bar widget"
            pointSize: Style.fontSizeXS
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
            currentKey: rootSettings?.editDefaultProvider ?? ""
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editDefaultProvider = key;
            }
        }
    }
}
