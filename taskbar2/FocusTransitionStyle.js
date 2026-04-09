.pragma library

function normalizedStyle(style) {
    switch (style) {
    case "soft-comet":
    case "twin-echo":
    case "dot-wake":
    case "shard-tail":
    case "ribbon-pop":
    case "spring-caravan":
    case "halo-slip":
    case "pebble-chain":
        return style;
    default:
        return "soft-comet";
    }
}

function clamp01(value) {
    return Math.max(0, Math.min(1, value));
}

function easingValue(name, progress) {
    var t = clamp01(progress);
    switch (name) {
    case "inCubic":
        return t * t * t;
    case "outCubic":
        t -= 1;
        return t * t * t + 1;
    case "inOutCubic":
        if (t < 0.5)
            return 4 * t * t * t;
        t = 2 * t - 2;
        return 0.5 * t * t * t + 1;
    case "outBack":
        var s = 1.70158;
        t -= 1;
        return t * t * ((s + 1) * t + s) + 1;
    default:
        return t;
    }
}

function interpolate(fromValue, toValue, progress, easingName) {
    return fromValue + (toValue - fromValue) * easingValue(easingName, progress);
}

function evaluateTwoStage(startValue, stage, time) {
    var firstDuration = Math.max(0, stage.firstDuration || 0);
    var secondDuration = Math.max(0, stage.secondDuration || 0);
    var firstTo = stage.firstTo;
    var secondTo = stage.secondTo;

    if (time <= 0)
        return startValue;

    if (firstDuration > 0 && time < firstDuration)
        return interpolate(startValue, firstTo, time / firstDuration, stage.firstEasing);

    var afterFirst = firstDuration > 0 ? firstTo : startValue;
    if (secondDuration > 0 && time < firstDuration + secondDuration)
        return interpolate(afterFirst, secondTo, (time - firstDuration) / secondDuration, stage.secondEasing);

    if (secondDuration > 0)
        return secondTo;
    if (firstDuration > 0)
        return firstTo;
    return startValue;
}

function evaluateOpacity(opacity, time) {
    var fadeInDuration = Math.max(0, opacity.fadeInDuration || 0);
    var holdDuration = Math.max(0, opacity.holdDuration || 0);
    var fadeOutDuration = Math.max(0, opacity.fadeOutDuration || 0);

    if (time <= 0)
        return opacity.startOpacity;

    if (fadeInDuration > 0 && time < fadeInDuration)
        return interpolate(opacity.startOpacity, opacity.fadeInTo, time / fadeInDuration, "linear");

    time -= fadeInDuration;
    if (time < holdDuration)
        return opacity.fadeInTo;

    time -= holdDuration;
    if (fadeOutDuration > 0 && time < fadeOutDuration)
        return interpolate(opacity.fadeInTo, opacity.fadeOutTo, time / fadeOutDuration, "linear");

    return opacity.fadeOutTo;
}

function evaluateBloom(bloom, time) {
    var result = {
        active: false,
        opacity: 0,
        scale: 1
    };

    if (!bloom)
        return result;

    var delayDuration = Math.max(0, bloom.delayDuration || 0);
    var riseDuration = Math.max(0, bloom.riseDuration || 0);
    var fallDuration = Math.max(0, bloom.fallDuration || 0);

    if (time < delayDuration)
        return result;

    time -= delayDuration;

    if (riseDuration > 0 && time < riseDuration) {
        var riseProgress = time / riseDuration;
        result.active = true;
        result.opacity = interpolate(0, bloom.riseTo, riseProgress, "linear");
        result.scale = interpolate(1, bloom.scaleTo, riseProgress, "linear");
        return result;
    }

    time -= riseDuration;
    if (fallDuration > 0 && time < fallDuration) {
        var fallProgress = time / fallDuration;
        result.active = true;
        result.opacity = interpolate(bloom.riseTo, 0, fallProgress, "linear");
        result.scale = interpolate(bloom.scaleTo, 1, fallProgress, "linear");
        return result;
    }

    return result;
}

function totalDurationForSpec(spec) {
    var axisDuration = Math.max(0, spec.axis.firstDuration || 0) + Math.max(0, spec.axis.secondDuration || 0);
    var lengthDuration = Math.max(0, spec.length.firstDuration || 0) + Math.max(0, spec.length.secondDuration || 0);
    var opacityDuration = Math.max(0, spec.opacity.fadeInDuration || 0) + Math.max(0, spec.opacity.holdDuration || 0) + Math.max(0, spec.opacity.fadeOutDuration || 0);
    var bloomDuration = 0;

    if (spec.bloom)
        bloomDuration = Math.max(0, spec.bloom.delayDuration || 0) + Math.max(0, spec.bloom.riseDuration || 0) + Math.max(0, spec.bloom.fallDuration || 0);

    return Math.max(1, axisDuration, lengthDuration, opacityDuration, bloomDuration);
}

function buildSpec(params) {
    var startAxis = params.startAxis;
    var endAxis = params.endAxis;
    var startLength = params.startLength;
    var endLength = params.endLength;
    var duration = Math.max(1, params.duration);
    var intensity = params.intensityRatio;
    var distance = Math.abs(endAxis - startAxis);
    var direction = params.direction || (endAxis >= startAxis ? 1 : -1);
    var uiScaleRatio = params.uiScaleRatio || 1;
    var styleKey = normalizedStyle(params.style);
    var fadeOutDuration = 90;
    var settleDuration = Math.max(50, Math.round(duration * 0.22));
    var primaryDuration = Math.max(1, duration - settleDuration);
    var trailingGapBase = Math.max(6, Math.round((endLength * 0.55) + (6 + intensity * 10) * uiScaleRatio));

    var spec = {
        styleKey: styleKey,
        useStartLength: styleKey === "ribbon-pop",
        leadShape: "pill",
        trailShape: "none",
        trailingPieces: 0,
        trailingGap: 0,
        trailingMainRatio: 0.7,
        trailingCrossRatio: 0.7,
        trailingOpacityFalloff: 0.2,
        trailingScaleFalloff: 0.14,
        trailStrength: 0,
        glowStrength: 0,
        ribbonStrength: 0,
        haloStrength: 0,
        axis: {
            firstTo: endAxis,
            firstDuration: duration,
            firstEasing: "inOutCubic",
            secondTo: endAxis,
            secondDuration: 0,
            secondEasing: "linear"
        },
        length: {
            firstTo: endLength,
            firstDuration: 0,
            firstEasing: "linear",
            secondTo: endLength,
            secondDuration: 0,
            secondEasing: "linear"
        },
        opacity: {
            startOpacity: 0.94,
            fadeInTo: 0.94,
            fadeInDuration: 0,
            holdDuration: duration,
            fadeOutTo: 0,
            fadeOutDuration: fadeOutDuration
        },
        bloom: null
    };

    switch (styleKey) {
    case "twin-echo":
        spec.trailStrength = 0.04 + intensity * 0.03;
        spec.glowStrength = 0.05 + intensity * 0.03;
        spec.trailShape = "echo";
        spec.trailingPieces = 2;
        spec.trailingGap = trailingGapBase * 0.9;
        spec.trailingMainRatio = 0.96;
        spec.trailingCrossRatio = 0.96;
        spec.trailingOpacityFalloff = 0.22;
        spec.trailingScaleFalloff = 0.14;
        spec.opacity.startOpacity = 0.9;
        spec.opacity.fadeInTo = 0.9;
        spec.opacity.fadeOutDuration = Math.max(70, Math.round(duration * 0.24));
        break;
    case "dot-wake":
        spec.trailStrength = 0.03 + intensity * 0.02;
        spec.glowStrength = 0.04 + intensity * 0.03;
        spec.trailShape = "dot";
        spec.trailingPieces = 4;
        spec.trailingGap = trailingGapBase * 0.55;
        spec.trailingMainRatio = 0.34;
        spec.trailingCrossRatio = 0.34;
        spec.trailingOpacityFalloff = 0.16;
        spec.trailingScaleFalloff = 0.08;
        spec.opacity.startOpacity = 0.88;
        spec.opacity.fadeInTo = 0.88;
        spec.opacity.fadeOutDuration = Math.max(65, Math.round(duration * 0.22));
        break;
    case "shard-tail":
        spec.leadShape = "rect";
        spec.trailStrength = 0.07 + intensity * 0.05;
        spec.glowStrength = 0.06 + intensity * 0.05;
        spec.trailShape = "shard";
        spec.trailingPieces = 3;
        spec.trailingGap = trailingGapBase * 0.72;
        spec.trailingMainRatio = 0.52;
        spec.trailingCrossRatio = 0.58;
        spec.trailingOpacityFalloff = 0.18;
        spec.trailingScaleFalloff = 0.11;
        spec.axis.firstEasing = "inCubic";
        spec.opacity.startOpacity = 0.92;
        spec.opacity.fadeInTo = 0.92;
        break;
    case "ribbon-pop":
        spec.trailStrength = 0.06 + intensity * 0.04;
        spec.glowStrength = 0.08 + intensity * 0.05;
        spec.ribbonStrength = 0.18 + intensity * 0.08;
        spec.length.firstTo = Math.max(endLength * 1.4, endLength + distance * (0.4 + intensity * 0.25));
        spec.length.firstDuration = Math.max(60, Math.round(duration * 0.56));
        spec.length.firstEasing = "outCubic";
        spec.length.secondTo = endLength;
        spec.length.secondDuration = Math.max(60, duration - spec.length.firstDuration);
        spec.length.secondEasing = "inOutCubic";
        break;
    case "spring-caravan":
        spec.trailStrength = 0.06 + intensity * 0.05;
        spec.glowStrength = 0.07 + intensity * 0.05;
        spec.trailShape = "capsule";
        spec.trailingPieces = 2;
        spec.trailingGap = trailingGapBase;
        spec.trailingMainRatio = 0.72;
        spec.trailingCrossRatio = 0.72;
        spec.trailingOpacityFalloff = 0.22;
        spec.trailingScaleFalloff = 0.16;
        spec.axis.firstTo = endAxis + direction * Math.max(4, Math.min(22, Math.round((6 + intensity * 14) * uiScaleRatio)));
        spec.axis.firstDuration = primaryDuration;
        spec.axis.firstEasing = "outCubic";
        spec.axis.secondTo = endAxis;
        spec.axis.secondDuration = settleDuration;
        spec.axis.secondEasing = "outBack";
        spec.opacity.startOpacity = 0.96;
        spec.opacity.fadeInTo = 0.96;
        break;
    case "halo-slip":
        spec.trailStrength = 0.03 + intensity * 0.02;
        spec.glowStrength = 0.05 + intensity * 0.03;
        spec.haloStrength = 0.24 + intensity * 0.08;
        spec.trailShape = "echo";
        spec.trailingPieces = 1;
        spec.trailingGap = trailingGapBase * 0.65;
        spec.trailingMainRatio = 0.9;
        spec.trailingCrossRatio = 0.9;
        spec.trailingOpacityFalloff = 0.24;
        spec.trailingScaleFalloff = 0.12;
        spec.opacity.startOpacity = 0.1;
        spec.opacity.fadeInTo = 0.82;
        spec.opacity.fadeInDuration = Math.max(36, Math.round(duration * 0.18));
        spec.opacity.fadeOutDuration = Math.max(70, Math.round(duration * 0.26));
        spec.opacity.holdDuration = Math.max(0, duration - spec.opacity.fadeInDuration - spec.opacity.fadeOutDuration);
        break;
    case "pebble-chain":
        spec.trailStrength = 0.04 + intensity * 0.03;
        spec.glowStrength = 0.05 + intensity * 0.03;
        spec.trailShape = "pebble";
        spec.trailingPieces = 3;
        spec.trailingGap = trailingGapBase * 0.6;
        spec.trailingMainRatio = 0.5;
        spec.trailingCrossRatio = 0.56;
        spec.trailingOpacityFalloff = 0.16;
        spec.trailingScaleFalloff = 0.1;
        spec.opacity.startOpacity = 0.9;
        spec.opacity.fadeInTo = 0.9;
        break;
    case "soft-comet":
    default:
        spec.trailStrength = 0.08 + intensity * 0.05;
        spec.glowStrength = 0.09 + intensity * 0.05;
        spec.bloom = {
            delayDuration: Math.max(0, duration - Math.max(45, Math.round(duration * 0.16)) - Math.round(Math.max(60, Math.round(duration * 0.2)) * 0.5)),
            riseTo: 0.14 + intensity * 0.16,
            riseDuration: Math.max(45, Math.round(duration * 0.16)),
            fallDuration: Math.max(60, Math.round(duration * 0.2)),
            scaleTo: 1.08 + intensity * 0.12
        };
        break;
    }

    return spec;
}

function evaluateFrame(spec, progress, startAxis, startLength) {
    var totalDuration = totalDurationForSpec(spec);
    var time = clamp01(progress) * totalDuration;
    var bloom = evaluateBloom(spec.bloom, time);

    return {
        axisPosition: evaluateTwoStage(startAxis, spec.axis, time),
        length: evaluateTwoStage(startLength, spec.length, time),
        opacity: evaluateOpacity(spec.opacity, time),
        bloomActive: bloom.active,
        bloomOpacity: bloom.opacity,
        bloomScale: bloom.scale,
        totalDuration: totalDuration
    };
}
