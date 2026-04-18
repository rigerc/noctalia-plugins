import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "./settings"
import "PresetUtils.js" as PresetUtils

ColumnLayout {
    id: root

    property var pluginApi: null
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property real preferredWidth: 720 * Style.uiScaleRatio
    property string selectedBuiltinPresetKey: ""
    property string selectedCustomPresetName: ""
    property string customPresetNameInput: ""
    property string presetTransferMessage: ""
    property bool presetSelectionClearedByEdit: false
    readonly property string presetExportFileName: "scrollbar-custom-presets.json"

    readonly property var fontWeightModel: ListModel {
        ListElement {
            key: "default"
            name: QT_TR_NOOP("Default")
        }
        ListElement {
            key: "light"
            name: QT_TR_NOOP("Light")
        }
        ListElement {
            key: "normal"
            name: QT_TR_NOOP("Normal")
        }
        ListElement {
            key: "medium"
            name: QT_TR_NOOP("Medium")
        }
        ListElement {
            key: "semibold"
            name: QT_TR_NOOP("Semibold")
        }
        ListElement {
            key: "bold"
            name: QT_TR_NOOP("Bold")
        }
    }
    readonly property var workspaceIndicatorLabelModeModel: [
        {
            "key": "id",
            "name": pluginApi?.tr("options.workspaceIndicatorId")
        },
        {
            "key": "name",
            "name": pluginApi?.tr("options.workspaceIndicatorName")
        }
    ]
    readonly property var workspaceIndicatorPositionModel: [
        {
            "key": "before",
            "name": pluginApi?.tr("options.workspaceIndicatorBefore")
        },
        {
            "key": "after",
            "name": pluginApi?.tr("options.workspaceIndicatorAfter")
        }
    ]
    readonly property var workspaceAnimationAxisModel: [
        {
            "key": "horizontal",
            "name": pluginApi?.tr("options.workspaceAnimationHorizontal")
        },
        {
            "key": "vertical",
            "name": pluginApi?.tr("options.workspaceAnimationVertical")
        }
    ]
    readonly property var trackLinePositionModel: [
        {
            "key": "start",
            "name": pluginApi?.tr("options.trackLinePositionStart")
        },
        {
            "key": "center",
            "name": pluginApi?.tr("options.trackLinePositionCenter")
        },
        {
            "key": "end",
            "name": pluginApi?.tr("options.trackLinePositionEnd")
        }
    ]
    readonly property var widgetSizeModeModel: [
        {
            "key": "dynamic",
            "name": pluginApi?.tr("options.widgetSizeModeDynamic")
        },
        {
            "key": "fixed",
            "name": pluginApi?.tr("options.widgetSizeModeFixed")
        }
    ]
    readonly property var renderModeModel: [
        {
            "key": "bar",
            "name": pluginApi?.tr("options.renderModeBar")
        },
        {
            "key": "window",
            "name": pluginApi?.tr("options.renderModeWindow")
        }
    ]
    readonly property var windowSpaceModeModel: [
        {
            "key": "overlay",
            "name": pluginApi?.tr("options.windowSpaceOverlay")
        },
        {
            "key": "reserve",
            "name": pluginApi?.tr("options.windowSpaceReserve")
        }
    ]
    readonly property var gradientDirectionModel: [
        {
            "key": "vertical",
            "name": pluginApi?.tr("options.gradientDirectionVertical")
        },
        {
            "key": "horizontal",
            "name": pluginApi?.tr("options.gradientDirectionHorizontal")
        }
    ]
    readonly property var builtInPresetModel: [
        {
            "key": "",
            "name": pluginApi?.tr("settings.presets.builtIn.placeholder")
        },
        {
            "key": "standard",
            "name": pluginApi?.tr("settings.presets.builtIn.standard.name")
        },
        {
            "key": "focusTrack",
            "name": pluginApi?.tr("settings.presets.builtIn.focusTrack.name")
        },
        {
            "key": "iconStrip",
            "name": pluginApi?.tr("settings.presets.builtIn.iconStrip.name")
        },
        {
            "key": "titleTrack",
            "name": pluginApi?.tr("settings.presets.builtIn.titleTrack.name")
        },
        {
            "key": "trackOnly",
            "name": pluginApi?.tr("settings.presets.builtIn.trackOnly.name")
        },
        {
            "key": "denseStrip",
            "name": pluginApi?.tr("settings.presets.builtIn.denseStrip.name")
        },
        {
            "key": "floatingPanel",
            "name": pluginApi?.tr("settings.presets.builtIn.floatingPanel.name")
        },
        {
            "key": "edgePill",
            "name": pluginApi?.tr("settings.presets.builtIn.edgePill.name")
        }
    ]
    readonly property var defaultSettings: createSettingsSnapshot(defaults, ({}))
    property var editSettings: createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults)
    property var customPresets: createCustomPresetList(pluginApi?.pluginSettings || ({}), defaults)
    readonly property string selectedPresetDescription: presetDescription(selectedBuiltinPresetKey)
    readonly property string trimmedCustomPresetName: normalizePresetName(customPresetNameInput)
    readonly property int matchingCustomPresetIndex: findCustomPresetIndex(trimmedCustomPresetName)
    readonly property bool canSaveCustomPreset: trimmedCustomPresetName !== "" && matchingCustomPresetIndex === -1
    readonly property bool canOverwriteCustomPreset: trimmedCustomPresetName !== "" && matchingCustomPresetIndex !== -1
    readonly property bool canDeleteCustomPreset: selectedCustomPresetName !== "" && findCustomPresetIndex(selectedCustomPresetName) !== -1
    readonly property string presetStatusSummary: {
        if (presetSelectionClearedByEdit)
            return pluginApi?.tr("settings.presets.summary.modified");
        if (selectedCustomPresetName !== "")
            return pluginApi?.tr("settings.presets.summary.custom", {
                "name": selectedCustomPresetName
            });
        if (selectedBuiltinPresetKey !== "")
            return pluginApi?.tr("settings.presets.summary.builtin", {
                "name": presetName(selectedBuiltinPresetKey)
            });
        if (customPresets.length > 0)
            return pluginApi?.tr("settings.presets.summary.count", {
                "count": customPresets.length
            });
        return pluginApi?.tr("settings.presets.summary.empty");
    }

    spacing: Style.marginM
    implicitWidth: preferredWidth

    function deepCopy(value) {
        return PresetUtils.deepCopy(value);
    }

    function mergeDeep(base, overrides) {
        return PresetUtils.mergeDeep(base, overrides);
    }

    function createSettingsSnapshot(primary, secondary) {
        return PresetUtils.createSettingsSnapshot(primary, secondary);
    }

    function createCustomPresetList(primary, secondary) {
        return PresetUtils.createCustomPresetList(primary, secondary);
    }

    function createCustomPresetListFromData(data) {
        return PresetUtils.createCustomPresetListFromData(data, defaults);
    }

    function normalizePresetName(name) {
        return PresetUtils.normalizePresetName(name);
    }

    function findCustomPresetIndex(name, presets) {
        return PresetUtils.findCustomPresetIndex(name, presets || customPresets);
    }

    function presetDescription(key) {
        switch (key) {
        case "standard":
            return pluginApi?.tr("settings.presets.builtIn.standard.desc");
        case "focusTrack":
            return pluginApi?.tr("settings.presets.builtIn.focusTrack.desc");
        case "iconStrip":
            return pluginApi?.tr("settings.presets.builtIn.iconStrip.desc");
        case "titleTrack":
            return pluginApi?.tr("settings.presets.builtIn.titleTrack.desc");
        case "trackOnly":
            return pluginApi?.tr("settings.presets.builtIn.trackOnly.desc");
        case "denseStrip":
            return pluginApi?.tr("settings.presets.builtIn.denseStrip.desc");
        case "floatingPanel":
            return pluginApi?.tr("settings.presets.builtIn.floatingPanel.desc");
        case "edgePill":
            return pluginApi?.tr("settings.presets.builtIn.edgePill.desc");
        default:
            return pluginApi?.tr("settings.presets.builtIn.desc");
        }
    }

    function presetName(key) {
        switch (key) {
        case "standard":
            return pluginApi?.tr("settings.presets.builtIn.standard.name");
        case "focusTrack":
            return pluginApi?.tr("settings.presets.builtIn.focusTrack.name");
        case "iconStrip":
            return pluginApi?.tr("settings.presets.builtIn.iconStrip.name");
        case "titleTrack":
            return pluginApi?.tr("settings.presets.builtIn.titleTrack.name");
        case "trackOnly":
            return pluginApi?.tr("settings.presets.builtIn.trackOnly.name");
        case "denseStrip":
            return pluginApi?.tr("settings.presets.builtIn.denseStrip.name");
        case "floatingPanel":
            return pluginApi?.tr("settings.presets.builtIn.floatingPanel.name");
        case "edgePill":
            return pluginApi?.tr("settings.presets.builtIn.edgePill.name");
        default:
            return "";
        }
    }

    function builtInPresetSnapshot(key) {
        return PresetUtils.builtInPresetSnapshot(key, defaultSettings);
    }

    function applyPresetSnapshot(snapshot) {
        editSettings = createSettingsSnapshot(snapshot, defaults);
    }

    function clearPresetSelection(markDirty) {
        if (markDirty === undefined)
            markDirty = false;

        presetSelectionClearedByEdit = markDirty && (selectedBuiltinPresetKey !== "" || selectedCustomPresetName !== "");
        selectedBuiltinPresetKey = "";
        selectedCustomPresetName = "";
    }

    function applyBuiltInPreset(key) {
        if (key === "") {
            clearPresetSelection(false);
            return;
        }

        applyPresetSnapshot(builtInPresetSnapshot(key));
        presetSelectionClearedByEdit = false;
        selectedBuiltinPresetKey = key;
        selectedCustomPresetName = "";
        customPresetNameInput = "";
    }

    function loadCustomPreset(name) {
        const index = findCustomPresetIndex(name);
        if (index === -1)
            return;

        applyPresetSnapshot(customPresets[index].settings);
        presetSelectionClearedByEdit = false;
        selectedBuiltinPresetKey = "";
        selectedCustomPresetName = customPresets[index].name;
        customPresetNameInput = customPresets[index].name;
    }

    function saveNewCustomPreset() {
        if (!canSaveCustomPreset)
            return;

        const next = deepCopy(customPresets);
        next.push({
            "name": trimmedCustomPresetName,
            "settings": deepCopy(editSettings)
        });
        customPresets = next;
        selectedCustomPresetName = trimmedCustomPresetName;
        selectedBuiltinPresetKey = "";
        presetSelectionClearedByEdit = false;
        customPresetNameInput = trimmedCustomPresetName;
    }

    function overwriteCustomPreset() {
        if (!canOverwriteCustomPreset)
            return;

        const next = deepCopy(customPresets);
        next[matchingCustomPresetIndex] = {
            "name": next[matchingCustomPresetIndex].name,
            "settings": deepCopy(editSettings)
        };
        customPresets = next;
        selectedCustomPresetName = next[matchingCustomPresetIndex].name;
        selectedBuiltinPresetKey = "";
        presetSelectionClearedByEdit = false;
        customPresetNameInput = next[matchingCustomPresetIndex].name;
    }

    function deleteSelectedCustomPreset() {
        if (!canDeleteCustomPreset)
            return;

        const index = findCustomPresetIndex(selectedCustomPresetName);
        if (index === -1)
            return;

        const next = deepCopy(customPresets);
        next.splice(index, 1);
        customPresets = next;
        selectedCustomPresetName = "";
        customPresetNameInput = "";
        presetSelectionClearedByEdit = false;
    }

    function exportCustomPresetsToFolder(folderPath) {
        const targetFolder = (folderPath ?? "").trim();
        if (targetFolder === "")
            return;

        exportAdapter.pluginId = pluginApi?.pluginId || pluginApi?.manifest?.id || "scrollbar";
        exportAdapter.version = 1;
        exportAdapter.exportedAt = new Date().toISOString();
        exportAdapter.customPresets = deepCopy(customPresets);
        exportFileView.path = targetFolder + "/" + presetExportFileName;
        exportFileView.writeAdapter();
        presetTransferMessage = pluginApi?.tr("settings.presets.custom.transfer.exported", {
            "path": exportFileView.path
        });
    }

    function importCustomPresetsFromContent(content, sourcePath) {
        let parsed = null;
        try {
            parsed = JSON.parse(content);
        } catch (error) {
            presetTransferMessage = pluginApi?.tr("settings.presets.custom.transfer.invalidJson");
            return;
        }

        const importedPresets = createCustomPresetListFromData(parsed);
        if (importedPresets.length === 0) {
            presetTransferMessage = pluginApi?.tr("settings.presets.custom.transfer.noPresets");
            return;
        }

        const next = deepCopy(customPresets);
        let added = 0;
        let overwritten = 0;

        for (let i = 0; i < importedPresets.length; i++) {
            const preset = importedPresets[i];
            const existingIndex = findCustomPresetIndex(preset.name, next);
            if (existingIndex === -1) {
                next.push(preset);
                added += 1;
            } else {
                next[existingIndex] = preset;
                overwritten += 1;
            }
        }

        customPresets = next;
        selectedBuiltinPresetKey = "";
        selectedCustomPresetName = "";
        customPresetNameInput = "";
        presetSelectionClearedByEdit = false;
        presetTransferMessage = pluginApi?.tr("settings.presets.custom.transfer.imported", {
            "count": importedPresets.length,
            "added": added,
            "overwritten": overwritten,
            "path": sourcePath || ""
        });
    }

    function settingValue(groupKey, nestedKey) {
        const group = editSettings ? editSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function conditionValue(key) {
        switch (key) {
        case "showSlots":
            return settingValue("layout", "showSlots") ?? true;
        case "hideSlots":
            return !(settingValue("layout", "showSlots") ?? true);
        case "widgetSizeModeDynamic":
            return (settingValue("layout", "widgetSizeMode") ?? "dynamic") === "dynamic";
        case "widgetSizeModeFixed":
            return (settingValue("layout", "widgetSizeMode") ?? "dynamic") === "fixed";
        case "showIcons":
            return settingValue("icons", "showIcons") ?? true;
        case "showTitle":
            return settingValue("title", "showTitle") ?? true;
        case "focusedTitleEnabled":
            return settingValue("focusedTitle", "enabled") ?? false;
        case "workspaceIndicatorEnabled":
            return settingValue("workspaceIndicator", "enabled") ?? false;
        case "edgeFadeEnabled":
            return settingValue("edgeFade", "enabled") ?? true;
        case "showFocusedFill":
            return settingValue("focused", "showFill") ?? true;
        case "showFocusedBorder":
            return settingValue("focused", "showBorder") ?? true;
        case "showUnfocusedFill":
            return settingValue("unfocused", "showFill") ?? true;
        case "showUnfocusedBorder":
            return settingValue("unfocused", "showBorder") ?? true;
        case "showHoverBorder":
            return settingValue("hover", "showBorder") ?? true;
        case "showTrackLine":
            return settingValue("indicators", "showTrackLine") ?? true;
        case "showFocusLine":
            return settingValue("indicators", "showFocusLine") ?? true;
        case "centerFocusedWindow":
            return settingValue("autoScroll", "centerFocusedWindow") ?? true;
        case "renderModeWindow":
            return (settingValue("window", "renderMode") ?? "bar") === "window";
        case "windowGradientEnabled":
            return settingValue("window", "gradientEnabled") ?? false;
        case "workspaceAnimationEnabled":
            return settingValue("workspaceAnimation", "enabled") ?? false;
        default:
            return true;
        }
    }

    function isVisibleByConditions(conditions) {
        if (!conditions || conditions.length === 0)
            return true;

        for (let i = 0; i < conditions.length; i++) {
            if (!conditionValue(conditions[i]))
                return false;
        }

        return true;
    }

    function sectionHasVisibleSettings(conditionsList) {
        if (!conditionsList || conditionsList.length === 0)
            return false;

        for (let i = 0; i < conditionsList.length; i++) {
            if (isVisibleByConditions(conditionsList[i]))
                return true;
        }

        return false;
    }

    function defaultValue(groupKey, nestedKey) {
        const group = defaultSettings ? defaultSettings[groupKey] : undefined;
        return group ? group[nestedKey] : undefined;
    }

    function setSetting(groupKey, nestedKey, value) {
        const next = deepCopy(editSettings);
        if (!next[groupKey])
            next[groupKey] = ({});
        next[groupKey][nestedKey] = value;
        editSettings = next;
        clearPresetSelection(true);
    }

    function refreshEditSettings() {
        editSettings = createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults);
        customPresets = createCustomPresetList(pluginApi?.pluginSettings || ({}), defaults);
        clearPresetSelection(false);
        customPresetNameInput = "";
        presetTransferMessage = "";
    }

    onPluginApiChanged: refreshEditSettings()

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshEditSettings();
        }
    }

    function saveSettings() {
        if (!pluginApi)
            return;

        const nextSettings = mergeDeep(pluginApi?.pluginSettings || ({}), editSettings);
        nextSettings.presets = {
            "custom": deepCopy(customPresets)
        };
        pluginApi.pluginSettings = nextSettings;
        pluginApi.saveSettings();
    }

    function openExportPresetPicker() {
        exportPresetPicker.openFilePicker();
    }

    function openImportPresetPicker() {
        importPresetPicker.openFilePicker();
    }

    NFilePicker {
        id: exportPresetPicker
        selectionMode: "folders"
        title: pluginApi?.tr("settings.presets.custom.actions.export")
        initialPath: Quickshell.env("HOME") || "/home"
        onAccepted: paths => {
            if (paths.length > 0)
                root.exportCustomPresetsToFolder(paths[0]);
        }
    }

    NFilePicker {
        id: importPresetPicker
        selectionMode: "files"
        nameFilters: ["*.json"]
        title: pluginApi?.tr("settings.presets.custom.actions.import")
        initialPath: Quickshell.env("HOME") || "/home"
        onAccepted: paths => {
            if (paths.length > 0) {
                importFileView.path = paths[0];
                importFileView.reload();
            }
        }
    }

    FileView {
        id: exportFileView
        path: ""
        printErrors: false
        watchChanges: false

        adapter: JsonAdapter {
            id: exportAdapter
            property string pluginId: "scrollbar"
            property int version: 1
            property string exportedAt: ""
            property var customPresets: []
        }

        onLoadFailed: function (_) {
            writeAdapter();
        }
    }

    FileView {
        id: importFileView
        path: ""
        printErrors: false
        watchChanges: false

        onLoaded: root.importCustomPresetsFromContent(text(), path)
        onLoadFailed: function (_) {
            root.presetTransferMessage = pluginApi?.tr("settings.presets.custom.transfer.readFailed");
        }
    }

    NTabBar {
        id: tabBar
        Layout.fillWidth: true
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            text: pluginApi?.tr("settings.tabs.layout")
            tabIndex: 0
            checked: tabView.currentIndex === 0
            onClicked: tabView.currentIndex = 0
        }
        NTabButton {
            text: pluginApi?.tr("settings.tabs.colors")
            tabIndex: 1
            checked: tabView.currentIndex === 1
            onClicked: tabView.currentIndex = 1
        }
        NTabButton {
            text: pluginApi?.tr("settings.tabs.behavior")
            tabIndex: 2
            checked: tabView.currentIndex === 2
            onClicked: tabView.currentIndex = 2
        }
        NTabButton {
            text: pluginApi?.tr("settings.tabs.presets")
            tabIndex: 3
            checked: tabView.currentIndex === 3
            onClicked: tabView.currentIndex = 3
        }
    }

    NTabView {
        id: tabView
        Layout.fillWidth: true

        LayoutSettingsTab {
            rootSettings: root
        }

        ColorsSettingsTab {
            rootSettings: root
        }

        BehaviorSettingsTab {
            rootSettings: root
        }

        PresetsTab {
            rootSettings: root
        }
    }
}
