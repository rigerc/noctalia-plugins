import QtQuick
import QtQml
import qs.Commons

QtObject {
    function clampOpacity(value, fallbackValue) {
        return Math.max(0, Math.min(100, value ?? fallbackValue ?? 100));
    }

    function stateValue(itemColors, stateKey, key) {
        return itemColors?.[stateKey]?.[key];
    }

    function fallbackItemStateColor(stateKey, colorRole) {
        if (colorRole === "border")
            return "transparent";

        if (colorRole === "text")
            return (stateKey === "hovered" || stateKey === "focused") ? Color.mOnHover : Color.mOnSurface;

        return (stateKey === "hovered" || stateKey === "focused") ? Color.mHover : Style.capsuleColor;
    }

    function resolveItemStateColor(itemColors, stateKey, colorRole) {
        const colorKey = stateValue(itemColors, stateKey, colorRole) ?? "none";
        if (!colorKey || colorKey === "none")
            return fallbackItemStateColor(stateKey, colorRole);
        if (colorRole === "text")
            return Color.resolveColorKey(colorKey);
        return Color.resolveColorKeyOptional(colorKey);
    }

    function resolveItemStateColorWithOpacity(itemColors, stateKey, colorRole) {
        const baseColor = resolveItemStateColor(itemColors, stateKey, colorRole);
        const opacityKey = colorRole + "Opacity";
        const opacity = clampOpacity(stateValue(itemColors, stateKey, opacityKey), 100) / 100;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * opacity);
    }

    function backgroundGradientEnabled(itemColors, stateKey) {
        return !!stateValue(itemColors, stateKey, "backgroundGradientEnabled");
    }

    function backgroundGradientOrientation(itemColors, stateKey, isVerticalBar) {
        const direction = stateValue(itemColors, stateKey, "backgroundGradientDirection") ?? "horizontal";
        if (direction === "vertical")
            return Gradient.Vertical;
        if (direction === "horizontal")
            return Gradient.Horizontal;
        return isVerticalBar ? Gradient.Vertical : Gradient.Horizontal;
    }

    function resolveGradientStopColor(itemColors, stateKey, colorKeyName, opacityKeyName, fallbackColorRole) {
        const colorKey = stateValue(itemColors, stateKey, colorKeyName) ?? "none";
        const baseColor = (!colorKey || colorKey === "none")
            ? resolveItemStateColor(itemColors, stateKey, fallbackColorRole)
            : Color.resolveColorKeyOptional(colorKey);
        const opacity = clampOpacity(stateValue(itemColors, stateKey, opacityKeyName), 100) / 100;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * opacity);
    }
}
