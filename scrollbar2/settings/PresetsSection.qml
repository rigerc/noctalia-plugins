import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var rootSettings: null
    property var pluginApi: rootSettings?.pluginApi ?? null
    property var builtInPresets: []
    property var customPresets: []

    spacing: Style.marginL

    Component.onCompleted: {
        builtInPresets = _buildBuiltinPresets();
        _refreshCustomPresets();
    }

    Connections {
        target: rootSettings?.pluginApi ?? null

        function onPluginSettingsChanged() {
            _refreshCustomPresets();
        }
    }

    function _refreshCustomPresets() {
        var presets = rootSettings?.pluginApi?.pluginSettings?._presets || [];
        if (!Array.isArray(presets))
            presets = [];
        customPresets = rootSettings.deepCopy(presets);
    }

    function _deepMerge(base, overrides) {
        var result = rootSettings.deepCopy(base);
        function merge(target, source) {
            for (var key in source) {
                if (source[key] && typeof source[key] === "object" && !Array.isArray(source[key])) {
                    if (!target[key] || typeof target[key] !== "object" || Array.isArray(target[key]))
                        target[key] = ({});
                    merge(target[key], source[key]);
                } else {
                    target[key] = source[key];
                }
            }
        }
        merge(result, overrides);
        return result;
    }

    function _buildBuiltinPresets() {
        var d = rootSettings ? rootSettings.deepCopy(rootSettings.defaultSettings) : ({});
        return [
            {
                id: "builtin:default",
                name: pluginApi?.tr("settings.presets.builtinPresets.default.name") ?? "Default",
                description: pluginApi?.tr("settings.presets.builtinPresets.default.desc") ?? "",
                builtIn: true,
                settings: d
            },
            {
                id: "builtin:minimal",
                name: pluginApi?.tr("settings.presets.builtinPresets.minimal.name") ?? "Minimal",
                description: pluginApi?.tr("settings.presets.builtinPresets.minimal.desc") ?? "",
                builtIn: true,
                settings: _deepMerge(d, {
                    track: {
                        thickness: 2,
                        shadowEnabled: false,
                        segmentSpacing: 2
                    },
                    focusLine: {
                        thickness: 2,
                        shadowEnabled: false
                    },
                    window: {
                        showIcon: false,
                        showTitle: false
                    },
                    animation: {
                        enabled: false
                    }
                })
            },
            {
                id: "builtin:bordered",
                name: pluginApi?.tr("settings.presets.builtinPresets.bordered.name") ?? "Bordered",
                description: pluginApi?.tr("settings.presets.builtinPresets.bordered.desc") ?? "",
                builtIn: true,
                settings: _deepMerge(d, {
                    track: {
                        thickness: 8,
                        borderRadius: 0,
                        shadowEnabled: false,
                        separatorColor: "outline"
                    },
                    focusLine: {
                        thickness: 8,
                        borderRadius: 0,
                        shadowEnabled: false
                    },
                    window: {
                        borderRadius: 0,
                        margin: 1
                    },
                    animation: {
                        enabled: false
                    }
                })
            },
            {
                id: "builtin:floating",
                name: pluginApi?.tr("settings.presets.builtinPresets.floating.name") ?? "Floating",
                description: pluginApi?.tr("settings.presets.builtinPresets.floating.desc") ?? "",
                builtIn: true,
                settings: _deepMerge(d, {
                    display: {
                        mode: "floatingPanel",
                        background: {
                            color: "tertiary",
                            opacity: 1
                        },
                        gradientEnabled: true,
                        gradient: {
                            color: "error",
                            opacity: 0.3
                        },
                        scale: 1.0,
                        margin: 6,
                        radiusScale: 1.2
                    },
                    window: {
                        focusedAlign: "center"
                    }
                })
            },
            {
                id: "builtin:compact",
                name: pluginApi?.tr("settings.presets.builtinPresets.compact.name") ?? "Compact",
                description: pluginApi?.tr("settings.presets.builtinPresets.compact.desc") ?? "",
                builtIn: true,
                settings: _deepMerge(d, {
                    track: {
                        thickness: 3,
                        segmentSpacing: 1,
                        borderRadius: 1
                    },
                    focusLine: {
                        thickness: 3,
                        borderRadius: 1
                    },
                    window: {
                        focusedOnly: true,
                        fontSize: 9,
                        borderRadius: 2,
                        margin: 1,
                        paddingLeft: 4,
                        paddingRight: 4
                    },
                    animation: {
                        speed: 250
                    }
                })
            }
        ];
    }

    function _generateId() {
        return Date.now().toString(36) + "-" + Math.random().toString(36).substring(2, 8);
    }

    function _presetById(id) {
        var i;
        for (i = 0; i < builtInPresets.length; i++) {
            if (builtInPresets[i].id === id)
                return builtInPresets[i];
        }
        for (i = 0; i < customPresets.length; i++) {
            if (customPresets[i].id === id)
                return customPresets[i];
        }
        return null;
    }

    function _findPresetByName(name, excludeId) {
        var i;
        for (i = 0; i < builtInPresets.length; i++) {
            if (builtInPresets[i].name === name)
                return builtInPresets[i];
        }
        for (i = 0; i < customPresets.length; i++) {
            if (customPresets[i].name === name && customPresets[i].id !== excludeId)
                return customPresets[i];
        }
        return null;
    }

    function _applyPreset(presetId) {
        var preset = _presetById(presetId);
        if (!preset)
            return;
        rootSettings.applyPreset(preset.settings, presetId);
    }

    function _savePreset(name, description) {
        if (!name || name.trim() === "")
            return;
        name = name.trim().substring(0, 32);
        description = (description || "").trim().substring(0, 120);
        if (_findPresetByName(name))
            return;
        var now = Date.now();
        var preset = {
            id: _generateId(),
            name: name,
            description: description,
            createdAt: now,
            updatedAt: now,
            settings: rootSettings.normalizeSettingsSnapshot(rootSettings.deepCopy(rootSettings.editSettings)),
            version: 1
        };
        var presets = rootSettings.deepCopy(customPresets);
        presets.push(preset);
        var api = pluginApi;
        if (!api)
            return;
        api.pluginSettings._presets = presets;
        api.saveSettings();
    }

    function _deletePreset(id) {
        var presets = rootSettings.deepCopy(customPresets).filter(function (p) {
            return p.id !== id;
        });
        var api = pluginApi;
        if (!api)
            return;
        api.pluginSettings._presets = presets;
        if (rootSettings._activePresetId === id)
            rootSettings._activePresetId = "";
        api.saveSettings();
    }

    function _deleteAllPresets() {
        var api = pluginApi;
        if (!api)
            return;
        api.pluginSettings._presets = [];
        rootSettings._activePresetId = "";
        api.saveSettings();
    }

    function _renamePreset(id, newName) {
        if (!newName || newName.trim() === "")
            return;
        newName = newName.trim().substring(0, 32);
        if (_findPresetByName(newName, id))
            return;
        var presets = rootSettings.deepCopy(customPresets);
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].id === id) {
                presets[i].name = newName;
                presets[i].updatedAt = Date.now();
                break;
            }
        }
        var api = pluginApi;
        if (!api)
            return;
        api.pluginSettings._presets = presets;
        api.saveSettings();
    }

    function _duplicatePreset(id) {
        var preset = _presetById(id);
        if (!preset)
            return;
        var copyName = preset.name;
        var suffix = 1;
        while (_findPresetByName(copyName)) {
            suffix++;
            copyName = preset.name + " " + suffix;
        }
        var now = Date.now();
        var newPreset = {
            id: _generateId(),
            name: copyName,
            description: preset.description || "",
            createdAt: now,
            updatedAt: now,
            settings: rootSettings.deepCopy(preset.settings),
            version: 1
        };
        var presets = rootSettings.deepCopy(customPresets);
        presets.push(newPreset);
        var api = pluginApi;
        if (!api)
            return;
        api.pluginSettings._presets = presets;
        api.saveSettings();
    }

    function _updatePreset(id) {
        var presets = rootSettings.deepCopy(customPresets);
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].id === id) {
                presets[i].settings = rootSettings.normalizeSettingsSnapshot(rootSettings.deepCopy(rootSettings.editSettings));
                presets[i].updatedAt = Date.now();
                break;
            }
        }
        var api = pluginApi;
        if (!api)
            return;
        api.pluginSettings._presets = presets;
        api.saveSettings();
    }

    NHeader {
        label: pluginApi?.tr("settings.presets.section.label") ?? "Presets"
        description: pluginApi?.tr("settings.presets.section.desc") ?? ""
        Layout.fillWidth: true
    }

    NLabel {
        label: pluginApi?.tr("settings.presets.builtin.label") ?? "Built-in Presets"
        description: pluginApi?.tr("settings.presets.builtin.desc") ?? ""
        Layout.fillWidth: true
    }

    Flow {
        Layout.fillWidth: true
        spacing: Style.marginM

        Repeater {
            model: root.builtInPresets

            delegate: PresetCard {
                presetId: modelData.id
                presetName: modelData.name
                presetDescription: modelData.description
                isBuiltIn: true
                isActive: rootSettings?._activePresetId === modelData.id
                pluginApi: root.pluginApi
                onClicked: root._applyPreset(modelData.id)
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NLabel {
            label: pluginApi?.tr("settings.presets.custom.label") ?? "Custom Presets"
            description: pluginApi?.tr("settings.presets.custom.desc") ?? ""
            Layout.fillWidth: true
        }

        NButton {
            text: pluginApi?.tr("settings.presets.actions.save") ?? "Save Current as Preset"
            icon: "device-floppy"
            fontSize: Style.fontSizeS
            onClicked: saveDialog.open()
        }

        NButton {
            visible: root.customPresets.length > 0
            text: pluginApi?.tr("settings.presets.actions.deleteAll") ?? "Delete All"
            icon: "trash"
            fontSize: Style.fontSizeS
            outlined: true
            backgroundColor: Color.mError
            onClicked: deleteAllDialog.open()
        }
    }

    Flow {
        visible: root.customPresets.length > 0
        Layout.fillWidth: true
        spacing: Style.marginM

        Repeater {
            model: root.customPresets

            delegate: PresetCard {
                presetId: modelData.id
                presetName: modelData.name
                presetDescription: modelData.description || ""
                isBuiltIn: false
                isActive: rootSettings?._activePresetId === modelData.id
                pluginApi: root.pluginApi
                onClicked: root._applyPreset(modelData.id)
                onRenameRequested: {
                    renameDialog._targetId = modelData.id;
                    renameDialog._targetName = modelData.name;
                    renameField.text = modelData.name;
                    renameDialog.open();
                }
                onUpdateRequested: {
                    updateDialog._targetId = modelData.id;
                    updateDialog._targetName = modelData.name;
                    updateDialog.open();
                }
                onDuplicateRequested: root._duplicatePreset(modelData.id)
                onDeleteRequested: {
                    deleteDialog._targetId = modelData.id;
                    deleteDialog._targetName = modelData.name;
                    deleteDialog.open();
                }
            }
        }
    }

    NBox {
        visible: root.customPresets.length === 0
        Layout.fillWidth: true
        Layout.preferredHeight: emptyContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: emptyContent
            anchors.fill: parent
            anchors.margins: Style.marginL

            NText {
                text: pluginApi?.tr("settings.presets.empty.label") ?? "No custom presets yet"
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
            }

            NText {
                text: pluginApi?.tr("settings.presets.empty.desc") ?? "Save your current settings to create a preset."
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    Popup {
        id: saveDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 380 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property string _error: ""

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: saveDialog.width - saveDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.save.title") ?? "Save Preset"
                description: root.pluginApi?.tr("settings.presets.dialog.save.desc") ?? ""
            }

            NTextInput {
                id: saveNameField
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presets.dialog.save.nameLabel") ?? "Preset Name"
                description: root.pluginApi?.tr("settings.presets.dialog.save.nameDesc") ?? ""
                placeholderText: root.pluginApi?.tr("settings.presets.dialog.save.namePlaceholder") ?? "My Preset"
                onTextChanged: saveDialog._error = ""
            }

            NTextInput {
                id: saveDescField
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presets.dialog.save.descLabel") ?? "Description"
                description: root.pluginApi?.tr("settings.presets.dialog.save.descDesc") ?? ""
                placeholderText: root.pluginApi?.tr("settings.presets.dialog.save.descPlaceholder") ?? "A brief description..."
            }

            NText {
                visible: saveDialog._error !== ""
                text: saveDialog._error
                color: Color.mError
                pointSize: Style.fontSizeS
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel") ?? "Cancel"
                    outlined: true
                    onClicked: {
                        saveDialog._error = "";
                        saveNameField.text = "";
                        saveDescField.text = "";
                        saveDialog.close();
                    }
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.save.save") ?? "Save"
                    onClicked: {
                        var name = saveNameField.text.trim();
                        if (!name) {
                            saveDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameRequired") ?? "Name is required.";
                            return;
                        }
                        if (name.length > 32) {
                            saveDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameTooLong") ?? "Name too long.";
                            return;
                        }
                        if (root._findPresetByName(name)) {
                            saveDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameExists") ?? "Name already exists.";
                            return;
                        }
                        root._savePreset(name, saveDescField.text);
                        saveNameField.text = "";
                        saveDescField.text = "";
                        saveDialog._error = "";
                        saveDialog.close();
                    }
                }
            }
        }
    }

    Popup {
        id: deleteDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 380 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property string _targetId: ""
        property string _targetName: ""

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: deleteDialog.width - deleteDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.delete.title") ?? "Delete Preset"
                description: (root.pluginApi?.tr("settings.presets.dialog.delete.desc") ?? "Delete \"{name}\"?").replace("{name}", deleteDialog._targetName)
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel") ?? "Cancel"
                    outlined: true
                    onClicked: deleteDialog.close()
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.delete.confirm") ?? "Delete"
                    backgroundColor: Color.mError
                    textColor: Color.mOnError
                    onClicked: {
                        root._deletePreset(deleteDialog._targetId);
                        deleteDialog.close();
                    }
                }
            }
        }
    }

    Popup {
        id: deleteAllDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 380 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: deleteAllDialog.width - deleteAllDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.deleteAll.title") ?? "Delete All"
                description: (root.pluginApi?.tr("settings.presets.dialog.deleteAll.desc") ?? "Delete all {count} presets?").replace("{count}", root.customPresets.length)
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel") ?? "Cancel"
                    outlined: true
                    onClicked: deleteAllDialog.close()
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.deleteAll.confirm") ?? "Delete All"
                    backgroundColor: Color.mError
                    textColor: Color.mOnError
                    onClicked: {
                        root._deleteAllPresets();
                        deleteAllDialog.close();
                    }
                }
            }
        }
    }

    Popup {
        id: renameDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 380 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property string _targetId: ""
        property string _targetName: ""
        property string _error: ""

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: renameDialog.width - renameDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.rename.title") ?? "Rename Preset"
                description: root.pluginApi?.tr("settings.presets.dialog.rename.desc") ?? ""
            }

            NTextInput {
                id: renameField
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presets.dialog.save.nameLabel") ?? "Preset Name"
                onTextChanged: renameDialog._error = ""
            }

            NText {
                visible: renameDialog._error !== ""
                text: renameDialog._error
                color: Color.mError
                pointSize: Style.fontSizeS
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel") ?? "Cancel"
                    outlined: true
                    onClicked: {
                        renameDialog._error = "";
                        renameDialog.close();
                    }
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.rename.confirm") ?? "Rename"
                    onClicked: {
                        var name = renameField.text.trim();
                        if (!name) {
                            renameDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameRequired") ?? "Name is required.";
                            return;
                        }
                        if (root._findPresetByName(name, renameDialog._targetId)) {
                            renameDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameExists") ?? "Name already exists.";
                            return;
                        }
                        root._renamePreset(renameDialog._targetId, name);
                        renameDialog._error = "";
                        renameDialog.close();
                    }
                }
            }
        }
    }

    Popup {
        id: updateDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 380 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property string _targetId: ""
        property string _targetName: ""

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: updateDialog.width - updateDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.update.title") ?? "Update Preset"
                description: (root.pluginApi?.tr("settings.presets.dialog.update.desc") ?? "Overwrite \"{name}\"?").replace("{name}", updateDialog._targetName)
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel") ?? "Cancel"
                    outlined: true
                    onClicked: updateDialog.close()
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.update.confirm") ?? "Update"
                    onClicked: {
                        root._updatePreset(updateDialog._targetId);
                        updateDialog.close();
                    }
                }
            }
        }
    }
}
