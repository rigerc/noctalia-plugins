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

function makeOpacitySpec(startOpacity, fadeInTo, fadeInDuration, holdDuration, fadeOutTo, fadeOutDuration) {
    return {
        startOpacity: startOpacity,
        fadeInTo: fadeInTo,
        fadeInDuration: Math.max(0, fadeInDuration || 0),
        holdDuration: Math.max(0, holdDuration || 0),
        fadeOutTo: fadeOutTo,
        fadeOutDuration: Math.max(0, fadeOutDuration || 0)
    };
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
            fadeInEasing: "outCubic",
            holdDuration: duration,
            fadeOutTo: 0,
            fadeOutDuration: fadeOutDuration,
            fadeOutEasing: "inCubic"
        },
        bloom: null
    };

    spec.colorMix = {
        lead: 0.08,
        trail: 0.72,
        glow: 1,
        halo: 0.86,
        ribbon: 0.56,
        bloom: 0.94
    };
    spec.layers = {
        lead: makeOpacitySpec(0.92, 1, 0, duration, 0, fadeOutDuration),
        trail: makeOpacitySpec(0.84, 0.84, 0, Math.max(0, Math.round(duration * 0.76)), 0, Math.max(60, Math.round(duration * 0.34))),
        glow: makeOpacitySpec(0.22, 0.72, Math.max(30, Math.round(duration * 0.16)), Math.max(0, Math.round(duration * 0.44)), 0, Math.max(70, Math.round(duration * 0.4))),
        halo: makeOpacitySpec(0, 0.52, Math.max(40, Math.round(duration * 0.2)), Math.max(0, Math.round(duration * 0.28)), 0, Math.max(80, Math.round(duration * 0.42))),
        ribbon: makeOpacitySpec(0.18, 0.55, Math.max(24, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.46)), 0, Math.max(55, Math.round(duration * 0.28)))
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
        spec.colorMix.trail = 0.84;
        spec.colorMix.glow = 1;
        spec.colorMix.halo = 0.92;
        spec.layers.trail = makeOpacitySpec(0.34, 0.76, Math.max(28, Math.round(duration * 0.14)), Math.max(0, Math.round(duration * 0.42)), 0, Math.max(76, Math.round(duration * 0.34)));
        spec.layers.glow = makeOpacitySpec(0.1, 0.52, Math.max(36, Math.round(duration * 0.18)), Math.max(0, Math.round(duration * 0.28)), 0, Math.max(86, Math.round(duration * 0.44)));
        spec.layers.halo = makeOpacitySpec(0.12, 0.64, Math.max(30, Math.round(duration * 0.16)), Math.max(0, Math.round(duration * 0.26)), 0, Math.max(80, Math.round(duration * 0.42)));
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
        spec.colorMix.lead = 0.18;
        spec.colorMix.trail = 0.9;
        spec.colorMix.glow = 0.96;
        spec.layers.trail = makeOpacitySpec(0.18, 0.8, Math.max(20, Math.round(duration * 0.1)), Math.max(0, Math.round(duration * 0.32)), 0, Math.max(84, Math.round(duration * 0.52)));
        spec.layers.glow = makeOpacitySpec(0.08, 0.42, Math.max(24, Math.round(duration * 0.14)), Math.max(0, Math.round(duration * 0.2)), 0, Math.max(70, Math.round(duration * 0.38)));
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
        spec.axis.firstEasing = "inQuint";  // Changed from "inCubic" - sharper acceleration
        spec.opacity.startOpacity = 0.92;
        spec.opacity.fadeInTo = 0.92;
        spec.colorMix.lead = 0;
        spec.colorMix.trail = 0.66;
        spec.layers.lead = makeOpacitySpec(0.96, 1, 0, Math.max(0, Math.round(duration * 0.78)), 0, Math.max(74, Math.round(duration * 0.26)));
        spec.layers.trail = makeOpacitySpec(0.32, 0.78, Math.max(22, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.38)), 0, Math.max(68, Math.round(duration * 0.32)));
        spec.layers.glow = makeOpacitySpec(0.08, 0.48, Math.max(26, Math.round(duration * 0.14)), Math.max(0, Math.round(duration * 0.22)), 0, Math.max(80, Math.round(duration * 0.44)));
        break;
    case "ribbon-pop":
        spec.trailStrength = 0.06 + intensity * 0.04;
        spec.glowStrength = 0.08 + intensity * 0.05;
        spec.ribbonStrength = 0.18 + intensity * 0.08;
        spec.length.firstTo = Math.max(endLength * 1.4, endLength + distance * (0.4 + intensity * 0.25));
        spec.length.firstDuration = Math.max(60, Math.round(duration * 0.56));
        spec.length.firstEasing = "outExpo";  // Changed from "outCubic" - dramatic stretch
        spec.length.secondTo = endLength;
        spec.length.secondDuration = Math.max(60, duration - spec.length.firstDuration);
        spec.length.secondEasing = "inOutQuart";  // Changed from "inOutCubic" - smoother settle
        spec.colorMix.ribbon = 0.62;
        spec.colorMix.trail = 0.8;
        spec.layers.ribbon = makeOpacitySpec(0.18, 0.78, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.5)), 0, Math.max(72, Math.round(duration * 0.34)));
        spec.layers.trail = makeOpacitySpec(0.3, 0.68, Math.max(22, Math.round(duration * 0.1)), Math.max(0, Math.round(duration * 0.34)), 0, Math.max(76, Math.round(duration * 0.36)));
        spec.layers.glow = makeOpacitySpec(0.14, 0.66, Math.max(28, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.3)), 0, Math.max(82, Math.round(duration * 0.4)));
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
        spec.axis.firstTo = endAxis;
        spec.axis.firstDuration = duration;
        spec.axis.firstEasing = "outElastic";  // Built-in bounce replaces manual overshoot
        spec.axis.secondTo = endAxis;
        spec.axis.secondDuration = 0;  // No second stage needed
        spec.axis.secondEasing = "linear";
        spec.opacity.startOpacity = 0.96;
        spec.opacity.fadeInTo = 0.96;
        spec.colorMix.lead = 0.14;
        spec.colorMix.trail = 0.74;
        spec.layers.lead = makeOpacitySpec(0.82, 1, Math.max(24, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.5)), 0, Math.max(82, Math.round(duration * 0.3)));
        spec.layers.trail = makeOpacitySpec(0.22, 0.72, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.28)), 0, Math.max(90, Math.round(duration * 0.44)));
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
        spec.opacity.fadeInEasing = "inOutSine";  // Smooth, slow fade-in
        spec.opacity.fadeOutDuration = Math.max(70, Math.round(duration * 0.26));
        spec.opacity.fadeOutEasing = "outSine";   // Gentle fade-out
        spec.opacity.holdDuration = Math.max(0, duration - spec.opacity.fadeInDuration - spec.opacity.fadeOutDuration);
        spec.colorMix.trail = 0.9;
        spec.colorMix.halo = 1;
        spec.layers.trail = makeOpacitySpec(0.08, 0.46, Math.max(30, Math.round(duration * 0.16)), Math.max(0, Math.round(duration * 0.18)), 0, Math.max(78, Math.round(duration * 0.42)));
        spec.layers.glow = makeOpacitySpec(0.04, 0.34, Math.max(36, Math.round(duration * 0.18)), Math.max(0, Math.round(duration * 0.14)), 0, Math.max(84, Math.round(duration * 0.46)));
        spec.layers.halo = makeOpacitySpec(0.12, 0.86, Math.max(26, Math.round(duration * 0.14)), Math.max(0, Math.round(duration * 0.3)), 0, Math.max(96, Math.round(duration * 0.48)));
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
        spec.colorMix.trail = 0.82;
        spec.layers.trail = makeOpacitySpec(0.2, 0.78, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.36)), 0, Math.max(88, Math.round(duration * 0.48)));
        spec.layers.glow = makeOpacitySpec(0.1, 0.44, Math.max(22, Math.round(duration * 0.1)), Math.max(0, Math.round(duration * 0.18)), 0, Math.max(76, Math.round(duration * 0.4)));
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
        spec.colorMix.lead = 0.12;
        spec.colorMix.trail = 0.78;
        spec.colorMix.glow = 1;
        spec.colorMix.bloom = 0.98;
        spec.layers.trail = makeOpacitySpec(0.38, 0.82, Math.max(24, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.4)), 0, Math.max(78, Math.round(duration * 0.4)));
        spec.layers.glow = makeOpacitySpec(0.12, 0.58, Math.max(32, Math.round(duration * 0.16)), Math.max(0, Math.round(duration * 0.26)), 0, Math.max(94, Math.round(duration * 0.48)));
        break;
    }

    return spec;
}

function totalDurationForSpec(spec) {
    var axisDuration = Math.max(0, spec.axis.firstDuration || 0) + Math.max(0, spec.axis.secondDuration || 0);
    var lengthDuration = Math.max(0, spec.length.firstDuration || 0) + Math.max(0, spec.length.secondDuration || 0);
    var opacityDuration = Math.max(0, spec.opacity.fadeInDuration || 0) + Math.max(0, spec.opacity.holdDuration || 0) + Math.max(0, spec.opacity.fadeOutDuration || 0);
    var bloomDuration = 0;
    var layerDuration = 0;

    if (spec.bloom)
        bloomDuration = Math.max(0, spec.bloom.delayDuration || 0) + Math.max(0, spec.bloom.riseDuration || 0) + Math.max(0, spec.bloom.fallDuration || 0);

    if (spec.layers) {
        Object.keys(spec.layers).forEach(function (key) {
            var layer = spec.layers[key];
            if (!layer)
                return;
            var duration = Math.max(0, layer.fadeInDuration || 0) + Math.max(0, layer.holdDuration || 0) + Math.max(0, layer.fadeOutDuration || 0);
            layerDuration = Math.max(layerDuration, duration);
        });
    }

    return Math.max(1, axisDuration, lengthDuration, opacityDuration, bloomDuration, layerDuration);
}
