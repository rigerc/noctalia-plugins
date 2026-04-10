.pragma library

function clamp(value, minValue, maxValue) {
    return Math.max(minValue, Math.min(maxValue, value));
}

function buildIndicatorRect(params) {
    var itemRect = params.itemRect || ({
        "x": 0,
        "y": 0,
        "width": 0,
        "height": 0
    });
    var iconRect = params.iconRect || itemRect;
    var scale = Math.max(0.5, params.scale || 1);
    var itemSize = Math.max(1, params.itemSize || 1);
    var isVerticalBar = !!params.isVerticalBar;
    var verticalPosition = params.verticalPosition || "bottom";
    var edgeMargin = Math.max(2, Math.round(2 * scale));
    var availableMainSpace = isVerticalBar ? iconRect.height : iconRect.width;
    var availableCrossSpace = (isVerticalBar ? itemRect.width : itemRect.height) - edgeMargin * 2;
    var markerLength = Math.min(availableMainSpace, Math.max(6, Math.round(itemSize * 0.25 * scale)));
    var markerThickness = Math.min(Math.max(2, availableCrossSpace), Math.round(6 * scale));
    var markerY = 0;

    if (verticalPosition === "top")
        markerY = Math.round(itemRect.y + edgeMargin);
    else if (verticalPosition === "middle")
        markerY = Math.round(itemRect.y + (itemRect.height - markerThickness) / 2);
    else
        markerY = Math.round(itemRect.y + itemRect.height - markerThickness - edgeMargin);

    if (isVerticalBar) {
        return {
            "x": Math.round(itemRect.x + itemRect.width - markerThickness - edgeMargin),
            "y": Math.round(iconRect.y + (iconRect.height - markerLength) / 2),
            "width": markerThickness,
            "height": markerLength
        };
    }

    return {
        "x": Math.round(iconRect.x + (iconRect.width - markerLength) / 2),
        "y": clamp(markerY, itemRect.y + edgeMargin, itemRect.y + Math.max(edgeMargin, itemRect.height - markerThickness - edgeMargin)),
        "width": markerLength,
        "height": markerThickness
    };
}
