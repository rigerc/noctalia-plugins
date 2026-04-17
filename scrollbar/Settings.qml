import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "./settings"

ColumnLayout {
    id: root

    property var pluginApi: null
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property real preferredWidth: 720 * Style.uiScaleRatio
    property string selectedBuiltinPresetKey: ""
    property string selectedCustomPresetName: ""
    property string customPresetNameInput: ""
    property bool presetsExpanded: false
    property bool customPresetEditorExpanded: false
    property string presetTransferMessage: ""
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
        }
    ]
    readonly property var defaultSettings: createSettingsSnapshot(defaults, ({}))
    property var editSettings: createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults)
    property var customPresets: createCustomPresetList(pluginApi?.pluginSettings || ({}), defaults)
    readonly property var customPresetModel: {
        const model = [{
            "key": "",
            "name": pluginApi?.tr("settings.presets.custom.placeholder")
        }];
        for (let i = 0; i < customPresets.length; i++) {
            model.push({
                "key": customPresets[i].name,
                "name": customPresets[i].name
            });
        }
        return model;
    }
    readonly property string selectedPresetDescription: presetDescription(selectedBuiltinPresetKey)
    readonly property string customPresetHelpText: {
        if (customPresets.length === 0)
            return pluginApi?.tr("settings.presets.custom.empty");
        if (selectedCustomPresetName !== "")
            return pluginApi?.tr("settings.presets.custom.selectedDesc", {
                "name": selectedCustomPresetName
            });
        return pluginApi?.tr("settings.presets.custom.desc");
    }
    readonly property string trimmedCustomPresetName: normalizePresetName(customPresetNameInput)
    readonly property int matchingCustomPresetIndex: findCustomPresetIndex(trimmedCustomPresetName)
    readonly property bool canSaveCustomPreset: trimmedCustomPresetName !== "" && matchingCustomPresetIndex === -1
    readonly property bool canOverwriteCustomPreset: trimmedCustomPresetName !== "" && matchingCustomPresetIndex !== -1
    readonly property bool canDeleteCustomPreset: selectedCustomPresetName !== "" && findCustomPresetIndex(selectedCustomPresetName) !== -1
    readonly property string collapsedPresetSummary: {
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
        return JSON.parse(JSON.stringify(value));
    }

    function isPlainObject(value) {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    function mergeDeep(base, overrides) {
        const result = deepCopy(base);
        applyDeepOverride(result, overrides);
        return result;
    }

    function applyDeepOverride(target, overrides) {
        if (!isPlainObject(overrides))
            return;

        for (const key in overrides) {
            const nextValue = overrides[key];
            if (isPlainObject(nextValue)) {
                if (!isPlainObject(target[key]))
                    target[key] = ({});
                applyDeepOverride(target[key], nextValue);
            } else {
                target[key] = deepCopy(nextValue);
            }
        }
    }

    function readSetting(primary, secondary, groupKey, nestedKey, legacyKey, fallbackValue) {
        const primaryGroup = primary ? primary[groupKey] : undefined;
        const nestedPrimary = primaryGroup ? primaryGroup[nestedKey] : undefined;
        if (nestedPrimary !== undefined)
            return nestedPrimary;

        const legacyPrimary = primary ? primary[legacyKey] : undefined;
        if (legacyPrimary !== undefined)
            return legacyPrimary;

        const secondaryGroup = secondary ? secondary[groupKey] : undefined;
        const nestedSecondary = secondaryGroup ? secondaryGroup[nestedKey] : undefined;
        if (nestedSecondary !== undefined)
            return nestedSecondary;

        const legacySecondary = secondary ? secondary[legacyKey] : undefined;
        if (legacySecondary !== undefined)
            return legacySecondary;

        return fallbackValue;
    }

    function createSettingsSnapshot(primary, secondary) {
        return {
            "filtering": {
                "onlySameOutput": readSetting(primary, secondary, "filtering", "onlySameOutput", "onlySameOutput", true),
                "onlyActiveWorkspaces": readSetting(primary, secondary, "filtering", "onlyActiveWorkspaces", "onlyActiveWorkspaces", true)
            },
            "interaction": {
                "enableReorder": readSetting(primary, secondary, "interaction", "enableReorder", "enableReorder", true),
                "enableScrollWheel": readSetting(primary, secondary, "interaction", "enableScrollWheel", "enableScrollWheel", true)
            },
            "autoScroll": {
                "centerFocusedWindow": readSetting(primary, secondary, "autoScroll", "centerFocusedWindow", "centerFocusedWindow", true),
                "centerAnimationMs": readSetting(primary, secondary, "autoScroll", "centerAnimationMs", "centerAnimationMs", 200)
            },
            "advanced": {
                "debugLogging": readSetting(primary, secondary, "advanced", "debugLogging", "debugLogging", false)
            },
            "layout": {
                "widgetSizeMode": readSetting(primary, secondary, "layout", "widgetSizeMode", "widgetSizeMode", "dynamic"),
                "fixedWidgetSize": readSetting(primary, secondary, "layout", "fixedWidgetSize", "fixedWidgetSize", 360),
                "maxWidgetWidth": readSetting(primary, secondary, "layout", "maxWidgetWidth", "maxWidgetWidth", 40),
                "showSlots": readSetting(primary, secondary, "layout", "showSlots", "showSlots", true),
                "slotWidth": readSetting(primary, secondary, "layout", "slotWidth", "slotWidth", 112),
                "slotSpacingUnits": readSetting(primary, secondary, "layout", "slotSpacingUnits", "slotSpacingUnits", 1),
                "radiusScale": readSetting(primary, secondary, "layout", "radiusScale", "radiusScale", 1.0),
                "slotCapsuleScale": readSetting(primary, secondary, "layout", "slotCapsuleScale", "slotCapsuleScale", 1.0)
            },
            "icons": {
                "showIcons": readSetting(primary, secondary, "icons", "showIcons", "showIcons", true),
                "iconScale": readSetting(primary, secondary, "icons", "iconScale", "iconScale", 0.8),
                "iconTintColor": readSetting(primary, secondary, "icons", "iconTintColor", "iconTintColor", "none"),
                "iconTintOpacity": readSetting(primary, secondary, "icons", "iconTintOpacity", "iconTintOpacity", 100)
            },
            "title": {
                "showTitle": readSetting(primary, secondary, "title", "showTitle", "showTitle", true),
                "titleFontFamily": readSetting(primary, secondary, "title", "titleFontFamily", "titleFontFamily", ""),
                "titleFontSize": readSetting(primary, secondary, "title", "titleFontSize", "titleFontSize", 0),
                "titleFontWeight": readSetting(primary, secondary, "title", "titleFontWeight", "titleFontWeight", "default")
            },
            "focusedTitle": {
                "enabled": readSetting(primary, secondary, "focusedTitle", "enabled", "focusedTitleEnabled", false),
                "textColor": readSetting(primary, secondary, "focusedTitle", "textColor", "focusedTitleTextColor", "on-surface"),
                "opacity": readSetting(primary, secondary, "focusedTitle", "opacity", "focusedTitleOpacity", 100)
            },
            "workspaceIndicator": {
                "enabled": readSetting(primary, secondary, "workspaceIndicator", "enabled", "workspaceIndicatorEnabled", false),
                "labelMode": readSetting(primary, secondary, "workspaceIndicator", "labelMode", "workspaceIndicatorLabelMode", "id"),
                "position": readSetting(primary, secondary, "workspaceIndicator", "position", "workspaceIndicatorPosition", "before"),
                "spacing": readSetting(primary, secondary, "workspaceIndicator", "spacing", "workspaceIndicatorSpacing", 8),
                "padding": readSetting(primary, secondary, "workspaceIndicator", "padding", "workspaceIndicatorPadding", 0),
                "fontFamily": readSetting(primary, secondary, "workspaceIndicator", "fontFamily", "workspaceIndicatorFontFamily", ""),
                "fontSize": readSetting(primary, secondary, "workspaceIndicator", "fontSize", "workspaceIndicatorFontSize", 0),
                "textColor": readSetting(primary, secondary, "workspaceIndicator", "textColor", "workspaceIndicatorTextColor", "primary"),
                "opacity": readSetting(primary, secondary, "workspaceIndicator", "opacity", "workspaceIndicatorOpacity", 100)
            },
            "edgeFade": {
                "enabled": (() => {
                    const configuredEnabled = readSetting(primary, secondary, "edgeFade", "enabled", "edgeFadeEnabled", undefined);
                    if (configuredEnabled !== undefined)
                        return configuredEnabled;

                    const configuredMode = readSetting(primary, secondary, "edgeFade", "mode", "edgeFadeMode", undefined);
                    if (configuredMode !== undefined)
                        return configuredMode !== "off";

                    const legacySize = readSetting(primary, secondary, "edgeFade", "size", "edgeFadeSize", undefined);
                    if (legacySize !== undefined)
                        return legacySize > 0;

                    return true;
                })(),
                "fadeSize": (() => {
                    const configuredFadeSize = readSetting(primary, secondary, "edgeFade", "fadeSize", "edgeFadeFadeSize", undefined);
                    if (configuredFadeSize !== undefined)
                        return configuredFadeSize;
                    return readSetting(primary, secondary, "edgeFade", "size", "edgeFadeSize", 48);
                })(),
                "fadeOpacity": readSetting(primary, secondary, "edgeFade", "fadeOpacity", "edgeFadeOpacity", 100)
            },
            "background": {
                "color": readSetting(primary, secondary, "background", "color", "backgroundColor", "none"),
                "opacity": readSetting(primary, secondary, "background", "opacity", "backgroundOpacity", 0)
            },
            "focused": {
                "showFill": readSetting(primary, secondary, "focused", "showFill", "showFocusedFill", true),
                "fillColor": readSetting(primary, secondary, "focused", "fillColor", "focusedFillColor", "primary"),
                "fillOpacity": readSetting(primary, secondary, "focused", "fillOpacity", "focusedFillOpacity", 92),
                "showBorder": readSetting(primary, secondary, "focused", "showBorder", "showFocusedBorder", true),
                "borderColor": readSetting(primary, secondary, "focused", "borderColor", "focusedBorderColor", "primary"),
                "borderOpacity": readSetting(primary, secondary, "focused", "borderOpacity", "focusedBorderOpacity", 100),
                "textColor": readSetting(primary, secondary, "focused", "textColor", "focusedTextColor", "on-primary")
            },
            "unfocused": {
                "showFill": readSetting(primary, secondary, "unfocused", "showFill", "showUnfocusedFill", true),
                "fillColor": readSetting(primary, secondary, "unfocused", "fillColor", "unfocusedFillColor", "surface-variant"),
                "fillOpacity": readSetting(primary, secondary, "unfocused", "fillOpacity", "unfocusedFillOpacity", 8),
                "showBorder": readSetting(primary, secondary, "unfocused", "showBorder", "showUnfocusedBorder", true),
                "borderColor": readSetting(primary, secondary, "unfocused", "borderColor", "unfocusedBorderColor", "outline"),
                "borderOpacity": readSetting(primary, secondary, "unfocused", "borderOpacity", "unfocusedBorderOpacity", 45),
                "textColor": readSetting(primary, secondary, "unfocused", "textColor", "unfocusedTextColor", "on-surface"),
                "inactiveOpacity": readSetting(primary, secondary, "unfocused", "inactiveOpacity", "inactiveOpacity", 45)
            },
            "hover": {
                "fillColor": readSetting(primary, secondary, "hover", "fillColor", "hoverFillColor", "hover"),
                "fillOpacity": readSetting(primary, secondary, "hover", "fillOpacity", "hoverFillOpacity", 55),
                "showBorder": readSetting(primary, secondary, "hover", "showBorder", "showHoverBorder", true),
                "borderColor": readSetting(primary, secondary, "hover", "borderColor", "hoverBorderColor", "outline"),
                "borderOpacity": readSetting(primary, secondary, "hover", "borderOpacity", "hoverBorderOpacity", 100),
                "textColor": readSetting(primary, secondary, "hover", "textColor", "hoverTextColor", "on-hover"),
                "scalePercent": readSetting(primary, secondary, "hover", "scalePercent", "hoverScalePercent", 2.5),
                "transitionDurationMs": readSetting(primary, secondary, "hover", "transitionDurationMs", "hoverTransitionDurationMs", 120)
            },
            "indicators": {
                "showTrackLine": readSetting(primary, secondary, "indicators", "showTrackLine", "showTrackLine", true),
                "trackOpacity": readSetting(primary, secondary, "indicators", "trackOpacity", "trackOpacity", 35),
                "trackLinePosition": readSetting(primary, secondary, "indicators", "trackLinePosition", "trackLinePosition", "end"),
                "trackLineThickness": readSetting(primary, secondary, "indicators", "trackLineThickness", "trackLineThickness", 2),
                "trackThumbColor": readSetting(primary, secondary, "indicators", "trackThumbColor", "trackThumbColor", "primary"),
                "showFocusLine": readSetting(primary, secondary, "indicators", "showFocusLine", "showFocusLine", true),
                "focusLineColor": readSetting(primary, secondary, "indicators", "focusLineColor", "focusLineColor", "secondary"),
                "focusLineOpacity": readSetting(primary, secondary, "indicators", "focusLineOpacity", "focusLineOpacity", 96),
                "focusLineThickness": readSetting(primary, secondary, "indicators", "focusLineThickness", "focusLineThickness", 2),
                "focusLineAnimationMs": readSetting(primary, secondary, "indicators", "focusLineAnimationMs", "focusLineAnimationMs", 120)
            },
            "workspaceAnimation": {
                "enabled": readSetting(primary, secondary, "workspaceAnimation", "enabled", "workspaceAnimationEnabled", false),
                "axis": readSetting(primary, secondary, "workspaceAnimation", "axis", "workspaceAnimationAxis", "horizontal")
            }
        };
    }

    function createCustomPresetList(primary, secondary) {
        const primaryPresets = primary?.presets?.custom;
        const secondaryPresets = secondary?.presets?.custom;
        const source = Array.isArray(primaryPresets) ? primaryPresets : (Array.isArray(secondaryPresets) ? secondaryPresets : []);
        const normalized = [];

        for (let i = 0; i < source.length; i++) {
            const entry = source[i];
            const name = normalizePresetName(entry?.name ?? "");
            if (name === "" || findCustomPresetIndex(name, normalized) !== -1)
                continue;

            normalized.push({
                "name": name,
                "settings": createSettingsSnapshot(entry?.settings || ({}), defaults)
            });
        }

        return normalized;
    }

    function createCustomPresetListFromData(data) {
        if (Array.isArray(data))
            return createCustomPresetList({
                "presets": {
                    "custom": data
                }
            }, ({}));

        if (Array.isArray(data?.customPresets))
            return createCustomPresetList({
                "presets": {
                    "custom": data.customPresets
                }
            }, ({}));

        if (Array.isArray(data?.presets?.custom))
            return createCustomPresetList(data, ({}));

        if (Array.isArray(data?.presets))
            return createCustomPresetList({
                "presets": {
                    "custom": data.presets
                }
            }, ({}));

        return [];
    }

    function normalizePresetName(name) {
        return (name ?? "").trim();
    }

    function findCustomPresetIndex(name, presets) {
        const normalizedName = normalizePresetName(name).toLowerCase();
        if (normalizedName === "")
            return -1;

        const list = presets || customPresets;
        for (let i = 0; i < list.length; i++) {
            if ((list[i]?.name ?? "").toLowerCase() === normalizedName)
                return i;
        }

        return -1;
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
        default:
            return "";
        }
    }

    function builtInPresetSnapshot(key) {
        switch (key) {
        case "standard":
            return mergeDeep(defaultSettings, {
                "indicators": {
                    "showTrackLine": false,
                    "showFocusLine": false
                }
            });
        case "focusTrack":
            return mergeDeep(defaultSettings, {
                "indicators": {
                    "showTrackLine": true,
                    "showFocusLine": true
                }
            });
        case "iconStrip":
            return mergeDeep(defaultSettings, {
                "indicators": {
                    "showTrackLine": false,
                    "showFocusLine": false
                },
                "title": {
                    "showTitle": false
                }
            });
        case "titleTrack":
            return mergeDeep(defaultSettings, {
                "layout": {
                    "showSlots": false
                },
                "focusedTitle": {
                    "enabled": true
                },
                "indicators": {
                    "showTrackLine": true,
                    "showFocusLine": true
                }
            });
        case "trackOnly":
            return mergeDeep(defaultSettings, {
                "layout": {
                    "showSlots": false
                },
                "focusedTitle": {
                    "enabled": false
                },
                "indicators": {
                    "showTrackLine": true,
                    "showFocusLine": true
                }
            });
        case "denseStrip":
            return mergeDeep(defaultSettings, {
                "layout": {
                    "widgetSizeMode": "dynamic",
                    "maxWidgetWidth": 60,
                    "showSlots": true,
                    "slotWidth": 84,
                    "slotSpacingUnits": 0,
                    "slotCapsuleScale": 0.72,
                    "radiusScale": 0.85
                },
                "icons": {
                    "showIcons": true,
                    "iconScale": 0.65
                },
                "title": {
                    "showTitle": false
                },
                "indicators": {
                    "showTrackLine": false,
                    "showFocusLine": false
                }
            });
        default:
            return deepCopy(defaultSettings);
        }
    }

    function applyPresetSnapshot(snapshot) {
        editSettings = createSettingsSnapshot(snapshot, defaults);
    }

    function clearPresetSelection() {
        selectedBuiltinPresetKey = "";
        selectedCustomPresetName = "";
    }

    function applyBuiltInPreset(key) {
        if (key === "") {
            clearPresetSelection();
            return;
        }

        applyPresetSnapshot(builtInPresetSnapshot(key));
        selectedBuiltinPresetKey = key;
        selectedCustomPresetName = "";
        customPresetNameInput = "";
    }

    function loadCustomPreset(name) {
        const index = findCustomPresetIndex(name);
        if (index === -1)
            return;

        applyPresetSnapshot(customPresets[index].settings);
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
        customPresetNameInput = trimmedCustomPresetName;
        customPresetEditorExpanded = false;
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
        customPresetNameInput = next[matchingCustomPresetIndex].name;
        customPresetEditorExpanded = false;
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
        customPresetEditorExpanded = false;
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
        customPresetEditorExpanded = false;
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
        clearPresetSelection();
    }

    function refreshEditSettings() {
        editSettings = createSettingsSnapshot(pluginApi?.pluginSettings || ({}), defaults);
        customPresets = createCustomPresetList(pluginApi?.pluginSettings || ({}), defaults);
        clearPresetSelection();
        customPresetNameInput = "";
        customPresetEditorExpanded = false;
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

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NButton {
                text: pluginApi?.tr(root.presetsExpanded ? "settings.presets.actions.hide" : "settings.presets.actions.show")
                icon: root.presetsExpanded ? "chevron-up" : "chevron-down"
                outlined: true
                onClicked: root.presetsExpanded = !root.presetsExpanded
            }

            NLabel {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.presets.label")
                description: root.collapsedPresetSummary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Color.mOutline
        }

        ColumnLayout {
            visible: root.presetsExpanded
            Layout.fillWidth: true
            spacing: Style.marginM

            NLabel {
                Layout.fillWidth: true
                description: pluginApi?.tr("settings.presets.desc")
                descriptionColor: Color.mOnSurfaceVariant
            }

            NComboBox {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.presets.builtIn.label")
                description: pluginApi?.tr("settings.presets.builtIn.desc")
                model: root.builtInPresetModel
                currentKey: root.selectedBuiltinPresetKey
                defaultValue: ""
                onSelected: key => root.applyBuiltInPreset(key)
            }

            NLabel {
                visible: root.selectedPresetDescription !== ""
                description: root.selectedPresetDescription
                descriptionColor: Color.mOnSurfaceVariant
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Color.mOutline
            }

            NComboBox {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.presets.custom.label")
                description: root.customPresetHelpText
                model: root.customPresetModel
                currentKey: root.selectedCustomPresetName
                defaultValue: ""
                onSelected: key => {
                    if (key === "") {
                        root.selectedCustomPresetName = "";
                        return;
                    }
                    root.loadCustomPreset(key);
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: pluginApi?.tr("settings.presets.custom.actions.import")
                    icon: "folder-open"
                    outlined: true
                    onClicked: importPresetPicker.openFilePicker()
                }

                NButton {
                    text: pluginApi?.tr("settings.presets.custom.actions.export")
                    icon: "folder"
                    outlined: true
                    onClicked: exportPresetPicker.openFilePicker()
                }

                NButton {
                    text: pluginApi?.tr(root.customPresetEditorExpanded ? "settings.presets.custom.actions.hideEditor" : "settings.presets.custom.actions.showEditor")
                    icon: root.customPresetEditorExpanded ? "chevron-up" : "chevron-down"
                    outlined: true
                    onClicked: root.customPresetEditorExpanded = !root.customPresetEditorExpanded
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            NLabel {
                visible: root.presetTransferMessage !== ""
                description: root.presetTransferMessage
                descriptionColor: Color.mOnSurfaceVariant
            }

            ColumnLayout {
                visible: root.customPresetEditorExpanded
                Layout.fillWidth: true
                spacing: Style.marginM

                NTextInput {
                    Layout.fillWidth: true
                    label: pluginApi?.tr("settings.presets.custom.name.label")
                    description: pluginApi?.tr("settings.presets.custom.name.desc")
                    placeholderText: pluginApi?.tr("settings.presets.custom.name.placeholder")
                    text: root.customPresetNameInput
                    onTextChanged: root.customPresetNameInput = text
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM

                    NButton {
                        text: pluginApi?.tr("settings.presets.custom.actions.save")
                        enabled: root.canSaveCustomPreset
                        onClicked: root.saveNewCustomPreset()
                    }

                    NButton {
                        text: pluginApi?.tr("settings.presets.custom.actions.overwrite")
                        enabled: root.canOverwriteCustomPreset
                        onClicked: root.overwriteCustomPreset()
                    }

                    NButton {
                        text: pluginApi?.tr("settings.presets.custom.actions.delete")
                        outlined: true
                        enabled: root.canDeleteCustomPreset
                        onClicked: root.deleteSelectedCustomPreset()
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }

                NLabel {
                    visible: root.trimmedCustomPresetName === ""
                    description: pluginApi?.tr("settings.presets.custom.validation.empty")
                    descriptionColor: Color.mOnSurfaceVariant
                }

                NLabel {
                    visible: root.trimmedCustomPresetName !== "" && root.matchingCustomPresetIndex !== -1
                    description: pluginApi?.tr("settings.presets.custom.validation.duplicate")
                    descriptionColor: Color.mPrimary
                }
            }
        }
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
    }
}
