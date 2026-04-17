import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null

    Layout.fillWidth: true
    spacing: Style.marginL

    ListModel {
        id: customPresetModel
    }

    function rebuildCustomPresetModel() {
        customPresetModel.clear();
        const presets = rootSettings?.customPresets || [];
        for (let i = 0; i < presets.length; i++) {
            customPresetModel.append({
                "key": presets[i].name,
                "name": presets[i].name
            });
        }
    }

    Connections {
        target: rootSettings

        function onCustomPresetsChanged() {
            root.rebuildCustomPresetModel();
        }
    }

    Component.onCompleted: rebuildCustomPresetModel()

    NHeader {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.presets.tab.label")
        description: rootSettings?.pluginApi?.tr("settings.presets.tab.desc")
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: summaryContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: summaryContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginS

            NLabel {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.presets.status.label")
                description: rootSettings?.presetStatusSummary
            }

            NLabel {
                visible: (rootSettings?.selectedPresetDescription ?? "") !== ""
                Layout.fillWidth: true
                description: rootSettings?.selectedPresetDescription
                descriptionColor: Color.mOnSurfaceVariant
            }
        }
    }

    NComboBox {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.presets.builtIn.label")
        description: rootSettings?.pluginApi?.tr("settings.presets.builtIn.desc")
        model: rootSettings?.builtInPresetModel
        currentKey: rootSettings?.selectedBuiltinPresetKey ?? ""
        defaultValue: ""
        onSelected: key => rootSettings?.applyBuiltInPreset(key)
    }

    NSearchableComboBox {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.presets.custom.label")
        description: rootSettings?.pluginApi?.tr("settings.presets.custom.loadDesc")
        model: customPresetModel
        currentKey: rootSettings?.selectedCustomPresetName ?? ""
        placeholder: rootSettings?.pluginApi?.tr("settings.presets.custom.placeholder")
        defaultValue: ""
        onSelected: key => rootSettings?.loadCustomPreset(key)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
            text: rootSettings?.pluginApi?.tr("settings.presets.actions.clear")
            icon: "x"
            outlined: true
            enabled: (rootSettings?.selectedBuiltinPresetKey ?? "") !== ""
                || (rootSettings?.selectedCustomPresetName ?? "") !== ""
                || (rootSettings?.presetSelectionClearedByEdit ?? false)
            onClicked: rootSettings?.clearPresetSelection(false)
        }

        Item {
            Layout.fillWidth: true
        }
    }

    NCollapsible {
        Layout.fillWidth: true
        label: rootSettings?.pluginApi?.tr("settings.presets.custom.manage.label")
        description: rootSettings?.pluginApi?.tr("settings.presets.custom.manage.desc")
        expanded: (rootSettings?.trimmedCustomPresetName ?? "") !== "" || (rootSettings?.selectedCustomPresetName ?? "") !== ""
        contentSpacing: Style.marginM

        NTextInput {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.presets.custom.name.label")
            description: rootSettings?.pluginApi?.tr("settings.presets.custom.name.desc")
            placeholderText: rootSettings?.pluginApi?.tr("settings.presets.custom.name.placeholder")
            text: rootSettings?.customPresetNameInput ?? ""
            onTextChanged: rootSettings.customPresetNameInput = text
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.presets.custom.actions.save")
                icon: "plus"
                enabled: rootSettings?.canSaveCustomPreset ?? false
                onClicked: rootSettings?.saveNewCustomPreset()
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.presets.custom.actions.overwrite")
                icon: "reload"
                enabled: rootSettings?.canOverwriteCustomPreset ?? false
                onClicked: rootSettings?.overwriteCustomPreset()
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.presets.custom.actions.delete")
                icon: "trash"
                outlined: true
                enabled: rootSettings?.canDeleteCustomPreset ?? false
                onClicked: rootSettings?.deleteSelectedCustomPreset()
            }
        }

        NLabel {
            visible: (rootSettings?.trimmedCustomPresetName ?? "") === ""
            Layout.fillWidth: true
            description: rootSettings?.pluginApi?.tr("settings.presets.custom.validation.empty")
            descriptionColor: Color.mOnSurfaceVariant
        }

        NLabel {
            visible: (rootSettings?.trimmedCustomPresetName ?? "") !== "" && (rootSettings?.matchingCustomPresetIndex ?? -1) !== -1
            Layout.fillWidth: true
            description: rootSettings?.pluginApi?.tr("settings.presets.custom.validation.duplicate")
            descriptionColor: Color.mPrimary
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: transferContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: transferContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NLabel {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.presets.custom.transfer.label")
                description: rootSettings?.pluginApi?.tr("settings.presets.custom.transfer.desc")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: rootSettings?.pluginApi?.tr("settings.presets.custom.actions.import")
                    icon: "folder-open"
                    outlined: true
                    onClicked: rootSettings?.openImportPresetPicker()
                }

                NButton {
                    text: rootSettings?.pluginApi?.tr("settings.presets.custom.actions.export")
                    icon: "folder"
                    outlined: true
                    enabled: (rootSettings?.customPresets?.length ?? 0) > 0
                    onClicked: rootSettings?.openExportPresetPicker()
                }
            }

            NLabel {
                visible: (rootSettings?.presetTransferMessage ?? "") !== ""
                Layout.fillWidth: true
                description: rootSettings?.presetTransferMessage
                descriptionColor: Color.mOnSurfaceVariant
            }
        }
    }
}
