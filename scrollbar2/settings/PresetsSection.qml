import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import "../Migrations.js" as Migrations

ColumnLayout {
    id: root

    property var rootSettings: null
    property var pluginApi: rootSettings?.pluginApi ?? null
    property var builtInPresets: []
    property var customPresets: []
    property alias builtInSectionTarget: builtInHeader
    property alias customSectionTarget: customSectionRow
    property alias backupSectionTarget: backupHeader
    property alias customRulesSectionTarget: customRulesHeader

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

    function _presetSettingsSnapshot(settings) {
        return rootSettings?.presetSettingsSnapshot
            ? rootSettings.presetSettingsSnapshot(settings)
            : rootSettings.normalizeSettingsSnapshot(rootSettings.deepCopy(settings || ({})));
    }

    function _customRuleSignature(rule) {
        return JSON.stringify(rootSettings.normalizeCustomStyleRule(rule));
    }

    function _cloneImportReport(report) {
        return {
            appliedMigrations: Array.isArray(report?.appliedMigrations) ? report.appliedMigrations.slice() : [],
            unknownKeys: Array.isArray(report?.unknownKeys) ? report.unknownKeys.slice() : [],
            details: Array.isArray(report?.details) ? rootSettings.deepCopy(report.details) : [],
            customRulesIgnored: Math.max(0, Number(report?.customRulesIgnored ?? 0)),
            addedRules: Math.max(0, Number(report?.addedRules ?? 0)),
            skippedDuplicateRules: Math.max(0, Number(report?.skippedDuplicateRules ?? 0))
        };
    }

    function _makePresetSafeImport(validatedResult) {
        var report = _cloneImportReport(validatedResult?.report);
        report.customRulesIgnored += Array.isArray(validatedResult?.settings?.customStyleRules)
            ? validatedResult.settings.customStyleRules.length
            : 0;
        return {
            settings: _presetSettingsSnapshot(validatedResult?.settings || ({})),
            report: report
        };
    }

    function _validatedImportedPresets(rawPresets) {
        var validatedPresets = [];
        var allReports = [];
        var totalIgnoredRules = 0;
        var sourcePresets = Array.isArray(rawPresets) ? rawPresets : [];

        for (var i = 0; i < sourcePresets.length; i++) {
            var preset = sourcePresets[i];
            if (!preset || typeof preset !== "object")
                continue;

            var presetResult = _makePresetSafeImport(
                Migrations.validateImport(preset.settings || ({}), rootSettings.defaultSettings)
            );
            var createdAt = Number(preset.createdAt);
            if (isNaN(createdAt))
                createdAt = Date.now();
            var updatedAt = Number(preset.updatedAt);
            if (isNaN(updatedAt))
                updatedAt = createdAt;

            validatedPresets.push({
                id: String(preset.id || _generateId()),
                name: String(preset.name || "").trim().substring(0, 32),
                description: String(preset.description || "").trim().substring(0, 120),
                createdAt: createdAt,
                updatedAt: updatedAt,
                settings: presetResult.settings,
                version: Number(preset.version || 1)
            });

            totalIgnoredRules += presetResult.report.customRulesIgnored;
            if (presetResult.report.appliedMigrations.length > 0
                || presetResult.report.unknownKeys.length > 0
                || presetResult.report.customRulesIgnored > 0) {
                allReports.push({
                    name: preset.name || "",
                    report: presetResult.report
                });
            }
        }

        return {
            presets: validatedPresets,
            report: {
                appliedMigrations: [],
                unknownKeys: [],
                details: allReports,
                customRulesIgnored: totalIgnoredRules
            }
        };
    }

    function _prepareCustomRulesImport(rawRules) {
        var existingRules = rootSettings.styleRuleItems();
        var existingSignatures = ({});
        var nextRules = [];
        var skippedDuplicateRules = 0;
        var i;

        for (i = 0; i < existingRules.length; i++)
            existingSignatures[_customRuleSignature(existingRules[i])] = true;

        for (i = 0; i < rawRules.length; i++) {
            var rawRule = rawRules[i];
            if (!rawRule || typeof rawRule !== "object")
                continue;

            var normalizedRule = rootSettings.normalizeCustomStyleRule(rawRule);
            var signature = _customRuleSignature(normalizedRule);
            if (existingSignatures[signature]) {
                skippedDuplicateRules++;
                continue;
            }

            existingSignatures[signature] = true;
            nextRules.push(normalizedRule);
        }

        return {
            rules: nextRules,
            report: {
                appliedMigrations: [],
                unknownKeys: [],
                details: [],
                customRulesIgnored: 0,
                addedRules: nextRules.length,
                skippedDuplicateRules: skippedDuplicateRules
            }
        };
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
        var d = rootSettings ? _presetSettingsSnapshot(rootSettings.defaultSettings) : ({});
        return [
            {
                id: "builtin:default",
                name: pluginApi?.tr("settings.presets.builtinPresets.default.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.default.desc"),
                builtIn: true,
                settings: d
            },
            {
                id: "builtin:minimal",
                name: pluginApi?.tr("settings.presets.builtinPresets.minimal.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.minimal.desc"),
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
                name: pluginApi?.tr("settings.presets.builtinPresets.bordered.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.bordered.desc"),
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
                name: pluginApi?.tr("settings.presets.builtinPresets.floating.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.floating.desc"),
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
                name: pluginApi?.tr("settings.presets.builtinPresets.compact.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.compact.desc"),
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
            },
            {
                id: "builtin:indicator",
                name: pluginApi?.tr("settings.presets.builtinPresets.indicator.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.indicator.desc"),
                builtIn: true,
                settings: _deepMerge(d, {
                    track: {
                        thickness: 4,
                        segmentSpacing: 2,
                        shadowEnabled: false
                    },
                    focusLine: {
                        thickness: 4,
                        shadowEnabled: false
                    },
                    window: {
                        showIcon: false,
                        showTitle: false
                    },
                    animation: {
                        enabled: true,
                        speed: 300
                    }
                })
            },
            {
                id: "builtin:pill",
                name: pluginApi?.tr("settings.presets.builtinPresets.pill.name"),
                description: pluginApi?.tr("settings.presets.builtinPresets.pill.desc"),
                builtIn: true,
                settings: _deepMerge(d, {
                    track: {
                        thickness: 8,
                        borderRadius: 4,
                        shadowEnabled: false,
                        segmentSpacing: 3
                    },
                    focusLine: {
                        thickness: 8,
                        borderRadius: 4,
                        shadowEnabled: false
                    },
                    window: {
                        showIcon: false,
                        showTitle: false
                    },
                    animation: {
                        enabled: true,
                        speed: 350
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
            settings: _presetSettingsSnapshot(rootSettings.editSettings),
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
            settings: _presetSettingsSnapshot(preset.settings),
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
                presets[i].settings = _presetSettingsSnapshot(rootSettings.editSettings);
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

    function _backupPayload() {
        return {
            scrollbar2Backup: true,
            version: 1,
            exportedAt: Date.now(),
            settings: rootSettings.normalizeSettingsSnapshot(rootSettings.deepCopy(rootSettings.editSettings)),
            presets: rootSettings.deepCopy(customPresets),
            activePresetId: rootSettings._activePresetId || ""
        };
    }

    function _presetPayload(preset) {
        return {
            scrollbar2Preset: true,
            version: 1,
            exportedAt: Date.now(),
            preset: {
                name: preset.name || "",
                description: preset.description || "",
                settings: rootSettings.deepCopy(preset.settings || ({}))
            }
        };
    }

    function _presetsBulkPayload() {
        return {
            scrollbar2Presets: true,
            version: 1,
            exportedAt: Date.now(),
            presets: rootSettings.deepCopy(customPresets)
        };
    }

    function _customRulesPayload() {
        return {
            scrollbar2CustomStyleRules: true,
            version: 1,
            exportedAt: Date.now(),
            rules: rootSettings.deepCopy(rootSettings.styleRuleItems())
        };
    }

    function _writeJsonToFile(path, data) {
        if (!path)
            return;
        var dir = path.substring(0, path.lastIndexOf("/"));
        if (dir)
            Quickshell.execDetached(["mkdir", "-p", dir]);
        exportWriter._pendingJson = JSON.stringify(data, null, 2);
        exportWriter.path = path;
        exportTimer.start();
    }

    Timer {
        id: exportTimer
        interval: 300
        repeat: false
        onTriggered: {
            if (exportWriter._pendingJson !== "") {
                exportWriter.setText(exportWriter._pendingJson);
                exportWriter._pendingJson = "";
            }
        }
    }

    function _exportBackup(path) {
        if (!path || path.trim() === "")
            return;
        path = _ensureFilePath(path, "scrollbar2-backup-" + _timestampString() + ".json");
        _writeJsonToFile(path, _backupPayload());
    }

    function _exportPreset(preset, path) {
        if (!path || path.trim() === "")
            return;
        if (!preset)
            return;
        path = _ensureFilePath(path, _safeFileName(preset.name || "preset") + ".json");
        _writeJsonToFile(path, _presetPayload(preset));
    }

    function _exportAllPresets(path) {
        if (!path || path.trim() === "")
            return;
        path = _ensureFilePath(path, "scrollbar2-presets-" + _timestampString() + ".json");
        _writeJsonToFile(path, _presetsBulkPayload());
    }

    function _exportCustomRules(path) {
        if (!path || path.trim() === "")
            return;
        path = _ensureFilePath(path, "scrollbar2-custom-style-rules-" + _timestampString() + ".json");
        _writeJsonToFile(path, _customRulesPayload());
    }

    function _ensureFilePath(path, defaultName) {
        if (!path || path.trim() === "")
            return path;
        var lastSlash = path.lastIndexOf("/");
        var lastSegment = lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
        if (lastSegment.indexOf(".") < 0)
            return _joinPath(path, defaultName);
        return path;
    }

    function _joinPath(dir, file) {
        return dir + (dir.charAt(dir.length - 1) === "/" ? "" : "/") + file;
    }

    function _timestampString() {
        var d = new Date();
        return d.getFullYear() + "-" + _pad2(d.getMonth() + 1) + "-" + _pad2(d.getDate()) + "-" + _pad2(d.getHours()) + _pad2(d.getMinutes());
    }

    function _pad2(n) {
        return n < 10 ? "0" + n : "" + n;
    }

    function _safeFileName(name) {
        return name.replace(/[^a-zA-Z0-9_\- ]/g, "").trim().replace(/\s+/g, "-").substring(0, 48);
    }

    function _parseImportFile(jsonText) {
        if (!jsonText || jsonText.trim() === "")
            return { error: pluginApi?.tr("settings.presets.import.errors.empty") };

        var data;
        try {
            data = JSON.parse(jsonText);
        } catch (e) {
            return { error: pluginApi?.tr("settings.presets.import.errors.invalidJson") };
        }

        if (!data || typeof data !== "object" || Array.isArray(data))
            return { error: pluginApi?.tr("settings.presets.import.errors.invalidFormat") };

        if (data.scrollbar2Backup) {
            var backupResult = Migrations.validateImport(data.settings || ({}), rootSettings.defaultSettings);
            var importedPresets = _validatedImportedPresets(data.presets || []);
            var backupReport = _cloneImportReport(backupResult.report);
            backupReport.details = importedPresets.report.details;
            backupReport.customRulesIgnored += importedPresets.report.customRulesIgnored;
            return {
                type: "backup",
                settings: backupResult.settings,
                presets: importedPresets.presets,
                activePresetId: String(data.activePresetId || ""),
                report: backupReport
            };
        }

        if (data.scrollbar2Preset) {
            var presetObj = data.preset || ({});
            var presetResult = _makePresetSafeImport(
                Migrations.validateImport(presetObj.settings || ({}), rootSettings.defaultSettings)
            );
            return {
                type: "preset",
                preset: {
                    name: String(presetObj.name || "").trim().substring(0, 32),
                    description: String(presetObj.description || "").trim().substring(0, 120),
                    settings: presetResult.settings
                },
                report: presetResult.report
            };
        }

        if (data.scrollbar2Presets) {
            var validatedPresets = _validatedImportedPresets(data.presets || []);
            return {
                type: "presets",
                presets: validatedPresets.presets.map(function (preset) {
                    return {
                        name: preset.name,
                        description: preset.description,
                        settings: preset.settings
                    };
                }),
                report: validatedPresets.report
            };
        }

        if (data.scrollbar2CustomStyleRules) {
            var preparedRules = _prepareCustomRulesImport(Array.isArray(data.rules) ? data.rules : []);
            return {
                type: "customRules",
                rules: preparedRules.rules,
                report: preparedRules.report
            };
        }

        return { error: pluginApi?.tr("settings.presets.import.errors.unrecognized") };
    }

    function _applyImportResult(result) {
        if (!result)
            return;

        if (result.type === "backup") {
            rootSettings.editSettings = rootSettings.createSettingsSnapshot(result.settings, rootSettings.defaults);
            rootSettings.styleRulesRevision += 1;
            var api = pluginApi;
            if (api) {
                var existingPresets = rootSettings.deepCopy(api.pluginSettings._presets || []);
                var mergedPresets = existingPresets.concat(result.presets);
                api.pluginSettings._presets = mergedPresets;
                rootSettings._activePresetId = result.activePresetId || "";
            }
        }

        if (result.type === "preset") {
            var preset = result.preset;
            var copyName = preset.name || (pluginApi?.tr("settings.presets.import.importedPreset"));
            var suffix = 1;
            while (_findPresetByName(copyName)) {
                suffix++;
                copyName = (preset.name || "Imported") + " " + suffix;
            }
            var now = Date.now();
            var newPreset = {
                id: _generateId(),
                name: copyName,
                description: preset.description || "",
                createdAt: now,
                updatedAt: now,
                settings: preset.settings,
                version: 1
            };
            var presets = rootSettings.deepCopy(customPresets);
            presets.push(newPreset);
            var api2 = pluginApi;
            if (api2) {
                api2.pluginSettings._presets = presets;
                api2.saveSettings();
            }
        }

        if (result.type === "presets") {
            var api3 = pluginApi;
            if (!api3)
                return;
            var existing = rootSettings.deepCopy(api3.pluginSettings._presets || []);
            for (var i = 0; i < result.presets.length; i++) {
                var ip = result.presets[i];
                var ipName = ip.name || (pluginApi?.tr("settings.presets.import.importedPreset"));
                var ipSuffix = 1;
                while (_findPresetByName(ipName)) {
                    ipSuffix++;
                    ipName = (ip.name || "Imported") + " " + ipSuffix;
                }
                var ipNow = Date.now();
                existing.push({
                    id: _generateId(),
                    name: ipName,
                    description: ip.description || "",
                    createdAt: ipNow,
                    updatedAt: ipNow,
                    settings: ip.settings,
                    version: 1
                });
            }
            api3.pluginSettings._presets = existing;
            api3.saveSettings();
        }

        if (result.type === "customRules") {
            var mergedRules = rootSettings.styleRuleItems().concat(result.rules || []);
            rootSettings.setStyleRuleItems(mergedRules);
        }
    }

    function _formatReport(report) {
        if (!report)
            return "";
        var lines = [];
        if (report.appliedMigrations && report.appliedMigrations.length > 0) {
            var migLabel = pluginApi?.tr("settings.presets.import.report.migrated");
            lines.push(migLabel.replace("{count}", report.appliedMigrations.length));
        }
        if (report.unknownKeys && report.unknownKeys.length > 0) {
            var unkLabel = pluginApi?.tr("settings.presets.import.report.unknown");
            lines.push(unkLabel.replace("{count}", report.unknownKeys.length));
        }
        if ((report.customRulesIgnored || 0) > 0) {
            var ignoredLabel = pluginApi?.tr("settings.presets.import.report.customRulesIgnored");
            lines.push(ignoredLabel.replace("{count}", report.customRulesIgnored));
        }
        if ((report.addedRules || 0) > 0) {
            var addedLabel = pluginApi?.tr("settings.presets.import.report.addedRules");
            lines.push(addedLabel.replace("{count}", report.addedRules));
        }
        if ((report.skippedDuplicateRules || 0) > 0) {
            var skippedLabel = pluginApi?.tr("settings.presets.import.report.skippedDuplicateRules");
            lines.push(skippedLabel.replace("{count}", report.skippedDuplicateRules));
        }
        if (report.details && report.details.length > 0) {
            for (var i = 0; i < report.details.length; i++) {
                var d = report.details[i];
                lines.push(d.name + ":");
                if (d.report.appliedMigrations.length > 0)
                    lines.push("  " + (pluginApi?.tr("settings.presets.import.report.migrated")).replace("{count}", d.report.appliedMigrations.length));
                if (d.report.unknownKeys.length > 0)
                    lines.push("  " + (pluginApi?.tr("settings.presets.import.report.unknown")).replace("{count}", d.report.unknownKeys.length));
                if ((d.report.customRulesIgnored || 0) > 0)
                    lines.push("  " + (pluginApi?.tr("settings.presets.import.report.customRulesIgnored")).replace("{count}", d.report.customRulesIgnored));
            }
        }
        return lines.join("\n");
    }

    function _detailsSectionLabel(sectionKey) {
        switch (sectionKey) {
        case "display":
            return pluginApi?.tr("settings.section.display.label");
        case "track":
            return pluginApi?.tr("settings.section.track.label");
        case "filtering":
            return pluginApi?.tr("settings.section.filtering.label");
        case "animation":
            return pluginApi?.tr("settings.section.animation.label");
        case "focusLine":
            return pluginApi?.tr("settings.section.focusLine.label");
        case "window":
            return pluginApi?.tr("settings.section.window.label");
        case "workspaceIndicator":
            return pluginApi?.tr("settings.section.workspaceIndicator.label");
        case "specialWorkspaceOverlay":
            return pluginApi?.tr("settings.section.specialWorkspaceOverlay.label");
        case "pinnedApps":
            return pluginApi?.tr("settings.section.pinnedApps.label");
        case "customStyleRules":
            return pluginApi?.tr("settings.section.customStyleRules.label");
        default:
            return sectionKey;
        }
    }

    function _detailsValueToString(value) {
        if (value === undefined)
            return "undefined";
        if (value === null)
            return "null";
        if (typeof value === "string")
            return value === "" ? "\"\"" : value;
        if (typeof value === "number" || typeof value === "boolean")
            return String(value);
        return JSON.stringify(value);
    }

    function _flattenDetails(value, prefix, rows) {
        if (Array.isArray(value)) {
            if (value.length === 0 && prefix)
                rows.push({ "path": prefix, "value": "[]" });
            for (var i = 0; i < value.length; i++)
                _flattenDetails(value[i], prefix + "[" + i + "]", rows);
            return rows;
        }

        if (value && typeof value === "object") {
            var keys = Object.keys(value);
            if (keys.length === 0 && prefix) {
                rows.push({ "path": prefix, "value": "{}" });
                return rows;
            }

            for (var j = 0; j < keys.length; j++) {
                var key = keys[j];
                _flattenDetails(value[key], prefix ? (prefix + "." + key) : key, rows);
            }
            return rows;
        }

        if (prefix)
            rows.push({ "path": prefix, "value": _detailsValueToString(value) });
        return rows;
    }

    function _detailsGroupsForPreset(preset) {
        var settings = preset?.settings || ({});
        var groups = [];
        var seen = ({});
        var orderedKeys = [
            "display",
            "track",
            "filtering",
            "animation",
            "focusLine",
            "window",
            "workspaceIndicator",
            "specialWorkspaceOverlay",
            "pinnedApps",
            "customStyleRules"
        ];

        function addGroup(sectionKey) {
            if (seen[sectionKey] || sectionKey.indexOf("_") === 0)
                return;
            seen[sectionKey] = true;
            var rows = [];
            root._flattenDetails(settings[sectionKey], "", rows);
            if (rows.length > 0) {
                groups.push({
                    "key": sectionKey,
                    "label": root._detailsSectionLabel(sectionKey),
                    "rows": rows
                });
            }
        }

        for (var i = 0; i < orderedKeys.length; i++) {
            if (settings[orderedKeys[i]] !== undefined)
                addGroup(orderedKeys[i]);
        }

        var extraKeys = Object.keys(settings);
        for (var j = 0; j < extraKeys.length; j++)
            addGroup(extraKeys[j]);

        return groups;
    }

    function _openDetails(preset) {
        detailsDialog._preset = preset || null;
        detailsDialog._groups = root._detailsGroupsForPreset(preset);
        detailsDialog.open();
    }

    NHeader {
        label: pluginApi?.tr("settings.presets.section.label")
        description: pluginApi?.tr("settings.presets.section.desc")
        Layout.fillWidth: true
    }

    NLabel {
        id: backupHeader
        label: pluginApi?.tr("settings.presets.backup.label")
        description: pluginApi?.tr("settings.presets.backup.desc")
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
            text: pluginApi?.tr("settings.presets.backup.export")
            icon: "download"
            fontSize: Style.fontSizeS
            onClicked: backupExportPicker.openFilePicker()
        }

        NButton {
            text: pluginApi?.tr("settings.presets.backup.import")
            icon: "upload"
            fontSize: Style.fontSizeS
            onClicked: backupImportPicker.openFilePicker()
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        id: customRulesHeader
        label: pluginApi?.tr("settings.presets.customRules.label")
        description: pluginApi?.tr("settings.presets.customRules.desc")
        Layout.fillWidth: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
            text: pluginApi?.tr("settings.presets.customRules.export")
            icon: "download"
            fontSize: Style.fontSizeS
            onClicked: customRulesExportPicker.openFilePicker()
        }

        NButton {
            text: pluginApi?.tr("settings.presets.customRules.import")
            icon: "upload"
            fontSize: Style.fontSizeS
            onClicked: customRulesImportPicker.openFilePicker()
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    NLabel {
        id: builtInHeader
        label: pluginApi?.tr("settings.presets.builtin.label")
        description: pluginApi?.tr("settings.presets.builtin.desc")
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
                onDetailsRequested: root._openDetails(modelData)
                onExportRequested: {
                    presetExportPicker._targetPreset = modelData;
                    presetExportPicker.openFilePicker();
                }
            }
        }
    }

    NDivider {
        Layout.fillWidth: true
    }

    RowLayout {
        id: customSectionRow
        Layout.fillWidth: true
        spacing: Style.marginM

        NLabel {
            label: pluginApi?.tr("settings.presets.custom.label")
            description: pluginApi?.tr("settings.presets.custom.desc")
            Layout.fillWidth: true
        }

        NButton {
            text: pluginApi?.tr("settings.presets.actions.save")
            icon: "device-floppy"
            fontSize: Style.fontSizeS
            onClicked: saveDialog.open()
        }

        NButton {
            text: pluginApi?.tr("settings.presets.actions.importPreset")
            icon: "upload"
            fontSize: Style.fontSizeS
            onClicked: presetImportPicker.openFilePicker()
        }

        NButton {
            visible: root.customPresets.length > 0
            text: pluginApi?.tr("settings.presets.actions.exportAll")
            icon: "download"
            fontSize: Style.fontSizeS
            onClicked: bulkExportPicker.openFilePicker()
        }

        NButton {
            visible: root.customPresets.length > 0
            text: pluginApi?.tr("settings.presets.actions.deleteAll")
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
                onDetailsRequested: root._openDetails(modelData)
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
                onExportRequested: {
                    presetExportPicker._targetPreset = modelData;
                    presetExportPicker.openFilePicker();
                }
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
                text: pluginApi?.tr("settings.presets.empty.label")
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
            }

            NText {
                text: pluginApi?.tr("settings.presets.empty.desc")
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }
    }

    Popup {
        id: detailsDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 760 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property var _preset: null
        property var _groups: []

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: detailsDialog.width - detailsDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.details.title")
                description: root.pluginApi?.tr("settings.presets.dialog.details.desc")
            }

            NLabel {
                Layout.fillWidth: true
                label: detailsDialog._preset?.name ?? ""
                description: detailsDialog._preset?.description || (detailsDialog._preset?.builtIn ? (root.pluginApi?.tr("settings.presets.badge")) : "")
                icon: detailsDialog._preset?.builtIn ? "template" : "device-floppy"
                visible: detailsDialog._preset !== null
            }

            NScrollView {
                id: detailsScroll

                Layout.fillWidth: true
                Layout.preferredHeight: 480 * Style.uiScaleRatio
                horizontalPolicy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: detailsScroll.availableWidth
                    spacing: Style.marginL

                    NBox {
                        visible: detailsDialog._groups.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: emptyDetailsContent.implicitHeight + Style.marginL * 2

                        ColumnLayout {
                            id: emptyDetailsContent
                            anchors.fill: parent
                            anchors.margins: Style.marginL
                            spacing: Style.marginS

                            NText {
                                Layout.fillWidth: true
                                text: root.pluginApi?.tr("settings.presets.dialog.details.empty.label")
                                pointSize: Style.fontSizeM
                                color: Color.mOnSurfaceVariant
                            }

                            NText {
                                Layout.fillWidth: true
                                text: root.pluginApi?.tr("settings.presets.dialog.details.empty.desc")
                                pointSize: Style.fontSizeS
                                color: Color.mOnSurfaceVariant
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Repeater {
                        model: detailsDialog._groups

                        delegate: NBox {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: groupContent.implicitHeight + Style.marginL * 2

                            ColumnLayout {
                                id: groupContent
                                anchors.fill: parent
                                anchors.margins: Style.marginL
                                spacing: Style.marginM

                                NLabel {
                                    Layout.fillWidth: true
                                    label: modelData.label || ""
                                    description: (root.pluginApi?.tr("settings.presets.dialog.details.rowCount"))
                                        .replace("{count}", modelData.rows?.length ?? 0)
                                    icon: "list-details"
                                }

                                Repeater {
                                    model: modelData.rows || []

                                    delegate: RowLayout {
                                        required property var modelData

                                        Layout.fillWidth: true
                                        spacing: Style.marginM

                                        NText {
                                            Layout.preferredWidth: Math.max(180 * Style.uiScaleRatio, detailsScroll.availableWidth * 0.34)
                                            text: modelData.path || ""
                                            color: Color.mOnSurface
                                            wrapMode: Text.WrapAnywhere
                                        }

                                        NText {
                                            Layout.fillWidth: true
                                            text: modelData.value || ""
                                            color: Color.mOnSurfaceVariant
                                            wrapMode: Text.WrapAnywhere
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: detailsDialog.close()
                }
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
                label: root.pluginApi?.tr("settings.presets.dialog.save.title")
                description: root.pluginApi?.tr("settings.presets.dialog.save.desc")
            }

            NTextInput {
                id: saveNameField
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presets.dialog.save.nameLabel")
                description: root.pluginApi?.tr("settings.presets.dialog.save.nameDesc")
                placeholderText: root.pluginApi?.tr("settings.presets.dialog.save.namePlaceholder")
                onTextChanged: saveDialog._error = ""
            }

            NTextInput {
                id: saveDescField
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presets.dialog.save.descLabel")
                description: root.pluginApi?.tr("settings.presets.dialog.save.descDesc")
                placeholderText: root.pluginApi?.tr("settings.presets.dialog.save.descPlaceholder")
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
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: {
                        saveDialog._error = "";
                        saveNameField.text = "";
                        saveDescField.text = "";
                        saveDialog.close();
                    }
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.save.save")
                    onClicked: {
                        var name = saveNameField.text.trim();
                        if (!name) {
                            saveDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameRequired");
                            return;
                        }
                        if (name.length > 32) {
                            saveDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameTooLong");
                            return;
                        }
                        if (root._findPresetByName(name)) {
                            saveDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameExists");
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
                label: root.pluginApi?.tr("settings.presets.dialog.delete.title")
                description: (root.pluginApi?.tr("settings.presets.dialog.delete.desc")).replace("{name}", deleteDialog._targetName)
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: deleteDialog.close()
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.delete.confirm")
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
                label: root.pluginApi?.tr("settings.presets.dialog.deleteAll.title")
                description: (root.pluginApi?.tr("settings.presets.dialog.deleteAll.desc")).replace("{count}", root.customPresets.length)
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: deleteAllDialog.close()
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.deleteAll.confirm")
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
                label: root.pluginApi?.tr("settings.presets.dialog.rename.title")
                description: root.pluginApi?.tr("settings.presets.dialog.rename.desc")
            }

            NTextInput {
                id: renameField
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presets.dialog.save.nameLabel")
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
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: {
                        renameDialog._error = "";
                        renameDialog.close();
                    }
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.rename.confirm")
                    onClicked: {
                        var name = renameField.text.trim();
                        if (!name) {
                            renameDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameRequired");
                            return;
                        }
                        if (root._findPresetByName(name, renameDialog._targetId)) {
                            renameDialog._error = root.pluginApi?.tr("settings.presets.dialog.save.nameExists");
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
                label: root.pluginApi?.tr("settings.presets.dialog.update.title")
                description: (root.pluginApi?.tr("settings.presets.dialog.update.desc")).replace("{name}", updateDialog._targetName)
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: updateDialog.close()
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.update.confirm")
                    onClicked: {
                        root._updatePreset(updateDialog._targetId);
                        updateDialog.close();
                    }
                }
            }
        }
    }

    FileView {
        id: importFileReader
        watchChanges: false
        preload: false
        blockLoading: true

        onLoaded: {
            var result = _parseImportFile(text());
            if (result.error) {
                importErrorDialog._errorMessage = result.error;
                importErrorDialog.open();
                return;
            }
            importConfirmDialog._importResult = result;
            importConfirmDialog._reportText = _formatReport(result.report);
            importConfirmDialog.open();
        }

        onLoadFailed: {
            importErrorDialog._errorMessage = pluginApi?.tr("settings.presets.import.errors.readFailed");
            importErrorDialog.open();
        }
    }

    FileView {
        id: exportWriter
        watchChanges: false
        preload: false

        property string _pendingJson: ""
    }

    NFilePicker {
        id: backupExportPicker
        selectionMode: "folders"
        title: pluginApi?.tr("settings.presets.backup.export")
        initialPath: Quickshell.env("HOME") + "/Downloads"

        onAccepted: paths => {
            if (paths.length > 0)
                _exportBackup(String(paths[0]));
        }
    }

    NFilePicker {
        id: backupImportPicker
        selectionMode: "files"
        title: pluginApi?.tr("settings.presets.backup.import")
        initialPath: Quickshell.env("HOME")
        nameFilters: ["*.json"]

        onAccepted: paths => {
            if (paths.length > 0)
                importFileReader.path = String(paths[0]);
        }
    }

    NFilePicker {
        id: presetExportPicker
        selectionMode: "folders"
        title: pluginApi?.tr("settings.presets.actions.export")
        initialPath: Quickshell.env("HOME") + "/Downloads"

        property var _targetPreset: null

        onAccepted: paths => {
            if (paths.length > 0 && _targetPreset)
                _exportPreset(_targetPreset, String(paths[0]));
            _targetPreset = null;
        }
    }

    NFilePicker {
        id: presetImportPicker
        selectionMode: "files"
        title: pluginApi?.tr("settings.presets.actions.importPreset")
        initialPath: Quickshell.env("HOME")
        nameFilters: ["*.json"]

        onAccepted: paths => {
            if (paths.length > 0)
                importFileReader.path = String(paths[0]);
        }
    }

    NFilePicker {
        id: bulkExportPicker
        selectionMode: "folders"
        title: pluginApi?.tr("settings.presets.actions.exportAll")
        initialPath: Quickshell.env("HOME") + "/Downloads"

        onAccepted: paths => {
            if (paths.length > 0)
                _exportAllPresets(String(paths[0]));
        }
    }

    NFilePicker {
        id: customRulesExportPicker
        selectionMode: "folders"
        title: pluginApi?.tr("settings.presets.customRules.export")
        initialPath: Quickshell.env("HOME") + "/Downloads"

        onAccepted: paths => {
            if (paths.length > 0)
                _exportCustomRules(String(paths[0]));
        }
    }

    NFilePicker {
        id: customRulesImportPicker
        selectionMode: "files"
        title: pluginApi?.tr("settings.presets.customRules.import")
        initialPath: Quickshell.env("HOME")
        nameFilters: ["*.json"]

        onAccepted: paths => {
            if (paths.length > 0)
                importFileReader.path = String(paths[0]);
        }
    }

    Popup {
        id: importConfirmDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 460 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property var _importResult: null
        property string _reportText: ""

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mPrimary
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: importConfirmDialog.width - importConfirmDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.importConfirm.title")
                description: {
                    var r = importConfirmDialog._importResult;
                    if (!r)
                        return "";
                    switch (r.type) {
                    case "backup":
                        return root.pluginApi?.tr("settings.presets.dialog.importConfirm.backupDesc");
                    case "preset":
                        return root.pluginApi?.tr("settings.presets.dialog.importConfirm.presetDesc");
                    case "presets":
                        return (root.pluginApi?.tr("settings.presets.dialog.importConfirm.presetsDesc")).replace("{count}", r.presets ? r.presets.length : 0);
                    case "customRules":
                        return (root.pluginApi?.tr("settings.presets.dialog.importConfirm.customRulesDesc"))
                            .replace("{count}", r.rules ? r.rules.length : 0);
                    default:
                        return "";
                    }
                }
            }

            NBox {
                visible: importConfirmDialog._reportText !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: reportContent.implicitHeight + Style.marginL * 2

                ColumnLayout {
                    id: reportContent
                    anchors.fill: parent
                    anchors.margins: Style.marginL
                    spacing: Style.marginS

                    NText {
                        text: root.pluginApi?.tr("settings.presets.import.report.label")
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightMedium
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NText {
                        text: importConfirmDialog._reportText
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: {
                        importConfirmDialog._importResult = null;
                        importConfirmDialog._reportText = "";
                        importConfirmDialog.close();
                    }
                }

                NButton {
                    text: root.pluginApi?.tr("settings.presets.dialog.importConfirm.confirm")
                    onClicked: {
                        root._applyImportResult(importConfirmDialog._importResult);
                        importConfirmDialog._importResult = null;
                        importConfirmDialog._reportText = "";
                        importConfirmDialog.close();
                    }
                }
            }
        }
    }

    Popup {
        id: importErrorDialog
        parent: Overlay.overlay
        modal: true
        dim: false
        anchors.centerIn: parent
        width: 380 * Style.uiScaleRatio
        padding: Style.marginL
        closePolicy: Popup.CloseOnEscape

        property string _errorMessage: ""

        background: Rectangle {
            color: Color.mSurface
            radius: Style.radiusS
            border.color: Color.mError
            border.width: Style.borderM
        }

        contentItem: ColumnLayout {
            width: importErrorDialog.width - importErrorDialog.padding * 2
            spacing: Style.marginL

            NHeader {
                label: root.pluginApi?.tr("settings.presets.dialog.importError.title")
                description: importErrorDialog._errorMessage
            }

            RowLayout {
                spacing: Style.marginM
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    text: root.pluginApi?.tr("common.cancel")
                    outlined: true
                    onClicked: {
                        importErrorDialog._errorMessage = "";
                        importErrorDialog.close();
                    }
                }
            }
        }
    }
}
