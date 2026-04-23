// Shared pure helpers for scrollbar2. Keep these free of QML-only dependencies so they can
// be reused from both QML and JS contexts without side effects.

function deepCopy(value) {
    try {
        return JSON.parse(JSON.stringify(value || ({})));
    } catch (error) {
        return ({});
    }
}

function _clamp01(value) {
    return Math.max(0, Math.min(1, value));
}

// Accepts `0..1` values, or `0..100` (interpreted as percent) when > 1.
function normalizeOpacityValue(value, fallbackValue) {
    const numericValue = Number(value);
    if (isNaN(numericValue))
        return fallbackValue;
    if (numericValue > 1)
        return _clamp01(numericValue / 100);
    return _clamp01(numericValue);
}

function settingValue(currentSettings, defaults, groupKey, nestedKey, fallbackValue) {
    const configGroup = currentSettings ? currentSettings[groupKey] : undefined;
    const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
    if (nestedConfig !== undefined)
        return nestedConfig;

    const defaultsGroup = defaults ? defaults[groupKey] : undefined;
    const nestedDefault = defaultsGroup ? defaultsGroup[nestedKey] : undefined;
    if (nestedDefault !== undefined)
        return nestedDefault;

    return fallbackValue;
}

function objectSettingValue(currentSettings, defaults, groupKey, objectKey, nestedKey, fallbackValue) {
    const configValue = currentSettings?.[groupKey]?.[objectKey]?.[nestedKey];
    if (configValue !== undefined)
        return configValue;

    const defaultValue = defaults?.[groupKey]?.[objectKey]?.[nestedKey];
    if (defaultValue !== undefined)
        return defaultValue;

    return fallbackValue;
}

function normalizeStyleRuleMatchField(matchField) {
    switch (String(matchField || "")) {
    case "title":
    case "tag":
    case "floating":
    case "urgent":
    case "grouped":
    case "sharedAppId":
    case "sharedTitle":
        return String(matchField);
    default:
        return "appId";
    }
}

function normalizeBadgeTarget(target) {
    switch (String(target || "")) {
    case "title":
    case "segment":
        return String(target);
    default:
        return "icon";
    }
}

function normalizeBadgePosition(position) {
    switch (String(position || "")) {
    case "top-left":
        return "top-left";
    default:
        return "top-right";
    }
}

function normalizePrefixTarget(target) {
    switch (String(target || "")) {
    case "title":
        return "title";
    default:
        return "icon";
    }
}

function styleRuleAllowsEmptyPattern(matchField) {
    switch (normalizeStyleRuleMatchField(matchField)) {
    case "tag":
    case "floating":
    case "urgent":
    case "grouped":
    case "sharedAppId":
    case "sharedTitle":
        return true;
    default:
        return false;
    }
}

// QML JS importer expects symbols on the module scope.
// eslint-disable-next-line no-unused-vars
var _exports = ({
    deepCopy,
    normalizeOpacityValue,
    settingValue,
    objectSettingValue,
    normalizeStyleRuleMatchField,
    normalizeBadgeTarget,
    normalizeBadgePosition,
    normalizePrefixTarget,
    styleRuleAllowsEmptyPattern
});

