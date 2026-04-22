import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: tab

    property var rootSettings: null
    readonly property var mainInstance: rootSettings?.pluginApi?.mainInstance
    readonly property var availableBarTextFieldOptions: {
        var items = [];
        var selected = rootSettings?.editBarTextFields || [];
        var options = rootSettings?.barTextFieldOptions || [];

        for (var index = 0; index < options.length; index++) {
            var option = options[index];
            if (selected.indexOf(option.key) >= 0)
                continue;
            items.push(option);
        }
        return items;
    }

    component SettingsCard: NBox {
        id: card

        property string title: ""
        property string description: ""
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NLabel {
                visible: card.title !== "" || card.description !== ""
                Layout.fillWidth: true
                label: card.title
                description: card.description
                labelSize: Style.fontSizeL
            }
        }
    }

    title: rootSettings?.pluginApi?.tr("settings.tabs.general")
    description: rootSettings?.pluginApi?.tr("settings.general.description")
    icon: "sparkles"

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.appearance.title")
        description: rootSettings?.pluginApi?.tr("settings.general.appearance.description")

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginL

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
                spacing: Style.marginM

                NButton {
                    text: rootSettings?.pluginApi?.tr("settings.general.barIcon.browse")
                    onClicked: barIconPicker.open()
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
                if (rootSettings)
                    rootSettings.editBarIconColor = key;
            }
        }
    }

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.textFields.title")
        description: rootSettings?.pluginApi?.tr("settings.general.textFields.description")

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginL

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.general.textFields.add")
                model: tab.availableBarTextFieldOptions
                currentKey: rootSettings?.editBarTextFieldToAdd ?? "primary"
                enabled: tab.availableBarTextFieldOptions.length > 0
                onSelected: key => {
                    if (rootSettings)
                        rootSettings.editBarTextFieldToAdd = key;
                }
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.general.textFields.addButton")
                icon: "plus"
                enabled: tab.availableBarTextFieldOptions.length > 0
                onClicked: {
                    if (rootSettings)
                        rootSettings.addBarTextField(rootSettings.editBarTextFieldToAdd);
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            Repeater {
                model: rootSettings?.editBarTextFields || []

                delegate: NBox {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: fieldRow.implicitHeight + Style.marginM * 2

                    RowLayout {
                        id: fieldRow
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM

                        NText {
                            Layout.fillWidth: true
                            text: {
                                var options = rootSettings?.barTextFieldOptions || [];
                                for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
                                    if (options[optionIndex].key === modelData)
                                        return options[optionIndex].name;
                                }
                                return String(modelData || "");
                            }
                            pointSize: Style.fontSizeM
                            color: Color.mOnSurface
                        }

                        NButton {
                            icon: "arrow-up"
                            outlined: true
                            enabled: index > 0
                            onClicked: {
                                if (rootSettings)
                                    rootSettings.moveBarTextField(index, -1);
                            }
                        }

                        NButton {
                            icon: "arrow-down"
                            outlined: true
                            enabled: index < (rootSettings?.editBarTextFields?.length ?? 0) - 1
                            onClicked: {
                                if (rootSettings)
                                    rootSettings.moveBarTextField(index, 1);
                            }
                        }

                        NButton {
                            icon: "trash"
                            outlined: true
                            enabled: (rootSettings?.editBarTextFields?.length ?? 0) > 1
                            onClicked: {
                                if (rootSettings)
                                    rootSettings.removeBarTextField(index);
                            }
                        }
                    }
                }
            }
        }

        NTextInput {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.textFields.separator.label")
            description: rootSettings?.pluginApi?.tr("settings.general.textFields.separator.desc")
            text: rootSettings?.editBarTextSeparator ?? ""
            onTextChanged: {
                if (rootSettings)
                    rootSettings.editBarTextSeparator = text;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.textFields.separatorSpacing.label")
            description: rootSettings?.pluginApi?.tr("settings.general.textFields.separatorSpacing.desc")
            from: 0
            to: 4
            stepSize: 1
            value: rootSettings?.editBarTextSeparatorSpacing ?? 1
            suffix: "sp"
            onValueChanged: {
                if (rootSettings)
                    rootSettings.editBarTextSeparatorSpacing = value;
            }
        }
    }

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.textStyle.title")
        description: rootSettings?.pluginApi?.tr("settings.general.textStyle.description")

        NColorChoice {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.text.color.label")
            currentKey: rootSettings?.editBarTextColor ?? "on-surface"
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editBarTextColor = key;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.text.opacity.label")
            description: rootSettings?.pluginApi?.tr("settings.general.text.opacity.desc")
            from: 0
            to: 100
            stepSize: 5
            value: rootSettings?.editBarTextOpacityPercent ?? 100
            suffix: "%"
            onValueChanged: {
                if (rootSettings)
                    rootSettings.editBarTextOpacityPercent = value;
            }
        }
    }

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.behavior.title")
        description: rootSettings?.pluginApi?.tr("settings.general.behavior.description")

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.behavior.showOnHover.label")
            description: rootSettings?.pluginApi?.tr("settings.general.behavior.showOnHover.desc")
            checked: rootSettings?.editBarTextShowOnHover ?? false
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editBarTextShowOnHover = checked;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.behavior.expandOnChange.label")
            description: rootSettings?.pluginApi?.tr("settings.general.behavior.expandOnChange.desc")
            checked: rootSettings?.editBarTextExpandOnChange ?? false
            enabled: rootSettings?.editBarTextShowOnHover ?? false
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editBarTextExpandOnChange = checked;
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.refreshInterval.label")
            model: rootSettings?.refreshIntervalOptions || []
            currentKey: String(rootSettings?.editRefreshInterval ?? 120)
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editRefreshInterval = Number(key);
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginXS

            NText {
                text: rootSettings?.pluginApi?.tr("settings.general.defaultProvider.label")
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
            }

            NText {
                text: rootSettings?.pluginApi?.tr("settings.general.defaultProvider.desc")
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
            }

            NComboBox {
                Layout.fillWidth: true
                model: {
                    var items = [{
                        "key": "",
                        "name": rootSettings?.pluginApi?.tr("settings.general.defaultProvider.auto")
                    }];
                    var providers = mainInstance?.providerData || [];
                    for (var index = 0; index < providers.length; index++) {
                        var providerId = String(providers[index].provider || "");
                        var displayName = mainInstance?.providerDisplayName(providerId) || providerId;
                        items.push({
                            "key": providerId,
                            "name": displayName
                        });
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
}
