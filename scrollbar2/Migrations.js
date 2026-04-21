.pragma library

var migrationRegistry = [
    {
        from: "display.backgroundColor",
        to: "display.background.color"
    },
    {
        from: "display.backgroundOpacity",
        to: "display.background.opacity",
        transform: "normalizeOpacity"
    },
    {
        from: "display.gradientColor",
        to: "display.gradient.color"
    },
    {
        from: "display.gradientOpacity",
        to: "display.gradient.opacity",
        transform: "normalizeOpacity"
    },
    {
        from: "track.color",
        to: "track.fill.color"
    },
    {
        from: "track.opacity",
        to: "track.fill.opacity",
        transform: "normalizeOpacity"
    },
    {
        from: "track.height",
        action: "delete"
    },
    {
        from: "focusLine.shadowEnabled",
        action: "delete"
    },
    {
        from: "animation.type",
        action: "replaceValue",
        match: "fade",
        replacement: "ease"
    },
    {
        from: "workspaceIndicator.animation.type",
        action: "replaceValue",
        match: "fade",
        replacement: "ease"
    }
];

function _deepCopy(value) {
    try {
        return JSON.parse(JSON.stringify(value || ({})));
    } catch (error) {
        return ({});
    }
}

function _getNestedValue(obj, path) {
    var parts = path.split(".");
    var current = obj;
    for (var i = 0; i < parts.length; i++) {
        if (!current || typeof current !== "object" || Array.isArray(current))
            return undefined;
        current = current[parts[i]];
    }
    return current;
}

function _setNestedValue(obj, path, value) {
    var parts = path.split(".");
    var current = obj;
    for (var i = 0; i < parts.length - 1; i++) {
        if (!current[parts[i]] || typeof current[parts[i]] !== "object" || Array.isArray(current[parts[i]]))
            current[parts[i]] = ({});
        current = current[parts[i]];
    }
    current[parts[parts.length - 1]] = value;
}

function _deleteNestedValue(obj, path) {
    var parts = path.split(".");
    var current = obj;
    for (var i = 0; i < parts.length - 1; i++) {
        if (!current || typeof current !== "object" || Array.isArray(current))
            return;
        current = current[parts[i]];
    }
    if (current)
        delete current[parts[parts.length - 1]];
}

function _hasNestedKey(obj, path) {
    return _getNestedValue(obj, path) !== undefined;
}

function _normalizeOpacity(value) {
    var numericValue = Number(value);
    if (isNaN(numericValue))
        return undefined;
    if (numericValue > 1)
        return Math.max(0, Math.min(1, numericValue / 100));
    return Math.max(0, Math.min(1, numericValue));
}

function migrateSettings(settings) {
    var next = _deepCopy(settings || ({}));
    var applied = [];

    for (var i = 0; i < migrationRegistry.length; i++) {
        var entry = migrationRegistry[i];
        var sourceExists = _hasNestedKey(next, entry.from);

        if (entry.action === "delete") {
            if (sourceExists) {
                _deleteNestedValue(next, entry.from);
                applied.push(entry.from + " (removed)");
            }
            continue;
        }

        if (entry.action === "replaceValue") {
            if (sourceExists) {
                var currentVal = _getNestedValue(next, entry.from);
                if (currentVal === entry.match) {
                    _setNestedValue(next, entry.from, entry.replacement);
                    applied.push(entry.from + ": \"" + entry.match + "\" → \"" + entry.replacement + "\"");
                }
            }
            continue;
        }

        if (entry.to) {
            if (sourceExists) {
                var rawValue = _getNestedValue(next, entry.from);
                var finalValue = rawValue;
                if (entry.transform === "normalizeOpacity")
                    finalValue = _normalizeOpacity(rawValue);
                _setNestedValue(next, entry.to, finalValue);
                _deleteNestedValue(next, entry.from);
                applied.push(entry.from + " → " + entry.to);
            }
            continue;
        }
    }

    return { settings: next, appliedMigrations: applied };
}

function buildKnownSchema(defaultSettings) {
    var paths = [];

    function walk(obj, prefix) {
        if (!obj || typeof obj !== "object" || Array.isArray(obj))
            return;
        var keys = Object.keys(obj);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            var value = obj[key];
            var path = prefix ? (prefix + "." + key) : key;
            if (value && typeof value === "object" && !Array.isArray(value)) {
                walk(value, path);
            } else {
                paths.push(path);
            }
        }
    }

    walk(defaultSettings, "");
    return paths;
}

function validateAndClean(settings, knownSchema) {
    var schemaSet = ({});
    for (var i = 0; i < knownSchema.length; i++)
        schemaSet[knownSchema[i]] = true;

    var unknownKeys = [];

    function clean(obj, prefix) {
        if (!obj || typeof obj !== "object" || Array.isArray(obj))
            return;
        var keys = Object.keys(obj);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            var value = obj[key];
            var path = prefix ? (prefix + "." + key) : key;

            if (key.charAt(0) === "_")
                continue;

            if (value && typeof value === "object" && !Array.isArray(value)) {
                clean(value, path);
                continue;
            }

            if (!schemaSet[path])
                unknownKeys.push(path);
        }
    }

    var cleaned = _deepCopy(settings || ({}));
    clean(cleaned, "");

    function stripUnknown(obj, prefix) {
        if (!obj || typeof obj !== "object" || Array.isArray(obj))
            return;
        var keys = Object.keys(obj);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            var value = obj[key];
            var path = prefix ? (prefix + "." + key) : key;

            if (key.charAt(0) === "_")
                continue;

            if (value && typeof value === "object" && !Array.isArray(value)) {
                stripUnknown(value, path);
                continue;
            }

            if (!schemaSet[path])
                delete obj[key];
        }
    }

    stripUnknown(cleaned, "");

    return { cleaned: cleaned, unknownKeys: unknownKeys };
}

function validateImport(rawSettings, defaultSettings) {
    var schemaPaths = buildKnownSchema(defaultSettings || ({}));
    var migrated = migrateSettings(rawSettings || ({}));
    var validated = validateAndClean(migrated.settings, schemaPaths);

    return {
        settings: validated.cleaned,
        report: {
            appliedMigrations: migrated.appliedMigrations,
            unknownKeys: validated.unknownKeys
        }
    };
}
