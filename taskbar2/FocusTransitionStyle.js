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

function makeLayerRoles(lead, trail, glow, halo, ribbon, bloom) {
    return {
        lead: lead || "lead",
        trail: trail || "glow",
        glow: glow || "glow",
        halo: halo || "effect",
        ribbon: ribbon || "effect",
        bloom: bloom || "glow"
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
    var fadeOutDuration = Math.max(74, Math.round(duration * 0.28));
    var trailingGapBase = Math.max(6, Math.round((endLength * 0.55) + (6 + intensity * 10) * uiScaleRatio));

    var spec = {
        styleKey: styleKey,
        useStartLength: styleKey === "ribbon-pop",
        leadShape: "pill",
        leadMainScale: 1,
        leadCrossScale: 1,
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
            startOpacity: 0.92,
            fadeInTo: 0.92,
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
        lead: 0.12,
        trail: 0.62,
        glow: 0.92,
        halo: 0.5,
        ribbon: 0.56,
        bloom: 0.88
    };
    spec.effectMix = {
        lead: 0.08,
        trail: 0.08,
        glow: 0.22,
        halo: 0.45,
        ribbon: 0.4,
        bloom: 0.32
    };
    spec.layerRoles = makeLayerRoles("lead", "glow", "glow", "effect", "effect", "glow");
    spec.layers = {
        lead: makeOpacitySpec(0.88, 1, 0, duration, 0, fadeOutDuration),
        trail: makeOpacitySpec(0.3, 0.72, Math.max(20, Math.round(duration * 0.1)), Math.max(0, Math.round(duration * 0.34)), 0, Math.max(70, Math.round(duration * 0.34))),
        glow: makeOpacitySpec(0.12, 0.54, Math.max(24, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.22)), 0, Math.max(78, Math.round(duration * 0.4))),
        halo: makeOpacitySpec(0.04, 0.42, Math.max(26, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.22)), 0, Math.max(82, Math.round(duration * 0.42))),
        ribbon: makeOpacitySpec(0.1, 0.44, Math.max(20, Math.round(duration * 0.1)), Math.max(0, Math.round(duration * 0.3)), 0, Math.max(70, Math.round(duration * 0.3)))
    };

    switch (styleKey) {
    case "twin-echo":
        spec.leadShape = "bracket";
        spec.leadMainScale = 1.08;
        spec.trailStrength = 0.05 + intensity * 0.03;
        spec.glowStrength = 0.04 + intensity * 0.02;
        spec.haloStrength = 0.2 + intensity * 0.07;
        spec.trailShape = "echo";
        spec.trailingPieces = 2;
        spec.trailingGap = trailingGapBase * 0.82;
        spec.trailingMainRatio = 0.94;
        spec.trailingCrossRatio = 0.82;
        spec.opacity.startOpacity = 0.86;
        spec.opacity.fadeInTo = 0.92;
        spec.opacity.fadeOutDuration = Math.max(70, Math.round(duration * 0.22));
        spec.colorMix.lead = 0.34;
        spec.colorMix.trail = 0.78;
        spec.colorMix.halo = 0.94;
        spec.effectMix.trail = 0.16;
        spec.effectMix.halo = 0.18;
        spec.layerRoles = makeLayerRoles("lead", "glow", "effect", "effect", "effect", "glow");
        spec.layers.trail = makeOpacitySpec(0.2, 0.68, Math.max(24, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.28)), 0, Math.max(72, Math.round(duration * 0.34)));
        spec.layers.halo = makeOpacitySpec(0.12, 0.84, Math.max(28, Math.round(duration * 0.14)), Math.max(0, Math.round(duration * 0.3)), 0, Math.max(88, Math.round(duration * 0.46)));
        break;
    case "dot-wake":
        spec.leadShape = "dot";
        spec.leadMainScale = 1.2;
        spec.leadCrossScale = 1.2;
        spec.trailStrength = 0.02 + intensity * 0.02;
        spec.glowStrength = 0.04 + intensity * 0.03;
        spec.trailShape = "dot";
        spec.trailingPieces = 5;
        spec.trailingGap = trailingGapBase * 0.46;
        spec.trailingMainRatio = 0.36;
        spec.trailingCrossRatio = 0.36;
        spec.trailingOpacityFalloff = 0.14;
        spec.trailingScaleFalloff = 0.08;
        spec.opacity.startOpacity = 0.82;
        spec.opacity.fadeInTo = 0.88;
        spec.opacity.fadeOutDuration = Math.max(62, Math.round(duration * 0.22));
        spec.colorMix.lead = 0.64;
        spec.colorMix.trail = 0.86;
        spec.colorMix.glow = 0.92;
        spec.effectMix.lead = 0.08;
        spec.layerRoles = makeLayerRoles("glow", "effect", "glow", "effect", "effect", "glow");
        spec.layers.trail = makeOpacitySpec(0.08, 0.84, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.3)), 0, Math.max(86, Math.round(duration * 0.5)));
        break;
    case "shard-tail":
        spec.leadShape = "diamond";
        spec.leadMainScale = 1.18;
        spec.leadCrossScale = 0.94;
        spec.trailStrength = 0.06 + intensity * 0.05;
        spec.glowStrength = 0.04 + intensity * 0.04;
        spec.trailShape = "shard";
        spec.trailingPieces = 3;
        spec.trailingGap = trailingGapBase * 0.72;
        spec.trailingMainRatio = 0.52;
        spec.trailingCrossRatio = 0.54;
        spec.axis.firstEasing = "inQuint";
        spec.opacity.startOpacity = 0.9;
        spec.opacity.fadeInTo = 0.94;
        spec.colorMix.lead = 0.1;
        spec.colorMix.trail = 0.58;
        spec.effectMix.lead = 0.26;
        spec.effectMix.trail = 0.12;
        spec.layerRoles = makeLayerRoles("lead", "effect", "glow", "effect", "effect", "glow");
        spec.layers.lead = makeOpacitySpec(0.94, 1, 0, Math.max(0, Math.round(duration * 0.76)), 0, Math.max(74, Math.round(duration * 0.24)));
        break;
    case "ribbon-pop":
        spec.leadShape = "pill";
        spec.leadMainScale = 0.98;
        spec.trailStrength = 0.05 + intensity * 0.04;
        spec.glowStrength = 0.07 + intensity * 0.05;
        spec.ribbonStrength = 0.22 + intensity * 0.1;
        spec.length.firstTo = Math.max(endLength * 1.45, endLength + distance * (0.42 + intensity * 0.28));
        spec.length.firstDuration = Math.max(58, Math.round(duration * 0.54));
        spec.length.firstEasing = "outExpo";
        spec.length.secondTo = endLength;
        spec.length.secondDuration = Math.max(56, duration - spec.length.firstDuration);
        spec.length.secondEasing = "inOutQuart";
        spec.colorMix.ribbon = 0.46;
        spec.colorMix.trail = 0.72;
        spec.colorMix.glow = 0.84;
        spec.effectMix.ribbon = 0.24;
        spec.layerRoles = makeLayerRoles("lead", "glow", "effect", "effect", "effect", "glow");
        spec.layers.ribbon = makeOpacitySpec(0.14, 0.82, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.52)), 0, Math.max(74, Math.round(duration * 0.34)));
        break;
    case "spring-caravan":
        spec.leadShape = "pill";
        spec.leadMainScale = 1.04;
        spec.trailStrength = 0.05 + intensity * 0.05;
        spec.glowStrength = 0.05 + intensity * 0.04;
        spec.trailShape = "capsule";
        spec.trailingPieces = 3;
        spec.trailingGap = trailingGapBase * 0.92;
        spec.trailingMainRatio = 0.7;
        spec.trailingCrossRatio = 0.7;
        spec.trailingOpacityFalloff = 0.22;
        spec.trailingScaleFalloff = 0.16;
        spec.axis.firstDuration = duration;
        spec.axis.firstEasing = "outElastic";
        spec.opacity.startOpacity = 0.92;
        spec.opacity.fadeInTo = 0.96;
        spec.colorMix.lead = 0.18;
        spec.colorMix.trail = 0.64;
        spec.colorMix.glow = 0.88;
        spec.effectMix.glow = 0.12;
        spec.layerRoles = makeLayerRoles("lead", "glow", "effect", "effect", "effect", "glow");
        spec.layers.trail = makeOpacitySpec(0.16, 0.7, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.26)), 0, Math.max(90, Math.round(duration * 0.44)));
        break;
    case "halo-slip":
        spec.leadShape = "ring";
        spec.leadMainScale = 1.26;
        spec.leadCrossScale = 1.14;
        spec.trailStrength = 0.02 + intensity * 0.02;
        spec.glowStrength = 0.03 + intensity * 0.02;
        spec.haloStrength = 0.34 + intensity * 0.1;
        spec.trailShape = "echo";
        spec.trailingPieces = 1;
        spec.trailingGap = trailingGapBase * 0.7;
        spec.trailingMainRatio = 0.92;
        spec.trailingCrossRatio = 0.92;
        spec.opacity.startOpacity = 0.06;
        spec.opacity.fadeInTo = 0.78;
        spec.opacity.fadeInDuration = Math.max(34, Math.round(duration * 0.18));
        spec.opacity.fadeInEasing = "inOutSine";
        spec.opacity.fadeOutDuration = Math.max(72, Math.round(duration * 0.26));
        spec.opacity.fadeOutEasing = "outSine";
        spec.opacity.holdDuration = Math.max(0, duration - spec.opacity.fadeInDuration - spec.opacity.fadeOutDuration);
        spec.colorMix.lead = 0.42;
        spec.colorMix.trail = 0.82;
        spec.colorMix.halo = 0.98;
        spec.effectMix.halo = 0.14;
        spec.layerRoles = makeLayerRoles("effect", "glow", "effect", "effect", "effect", "glow");
        spec.layers.glow = makeOpacitySpec(0.04, 0.26, Math.max(34, Math.round(duration * 0.16)), Math.max(0, Math.round(duration * 0.1)), 0, Math.max(82, Math.round(duration * 0.4)));
        spec.layers.halo = makeOpacitySpec(0.2, 0.92, Math.max(24, Math.round(duration * 0.12)), Math.max(0, Math.round(duration * 0.34)), 0, Math.max(96, Math.round(duration * 0.46)));
        break;
    case "pebble-chain":
        spec.leadShape = "dot";
        spec.leadMainScale = 1.14;
        spec.leadCrossScale = 1.08;
        spec.trailStrength = 0.04 + intensity * 0.03;
        spec.glowStrength = 0.04 + intensity * 0.03;
        spec.trailShape = "pebble";
        spec.trailingPieces = 4;
        spec.trailingGap = trailingGapBase * 0.56;
        spec.trailingMainRatio = 0.54;
        spec.trailingCrossRatio = 0.56;
        spec.trailingOpacityFalloff = 0.14;
        spec.trailingScaleFalloff = 0.1;
        spec.opacity.startOpacity = 0.86;
        spec.opacity.fadeInTo = 0.9;
        spec.colorMix.lead = 0.28;
        spec.colorMix.trail = 0.68;
        spec.colorMix.glow = 0.82;
        spec.effectMix.trail = 0.18;
        spec.layerRoles = makeLayerRoles("lead", "effect", "glow", "effect", "effect", "glow");
        spec.layers.trail = makeOpacitySpec(0.14, 0.8, Math.max(18, Math.round(duration * 0.08)), Math.max(0, Math.round(duration * 0.34)), 0, Math.max(86, Math.round(duration * 0.48)));
        break;
    case "soft-comet":
    default:
        spec.leadShape = "pill";
        spec.leadMainScale = 1.08;
        spec.trailStrength = 0.08 + intensity * 0.05;
        spec.glowStrength = 0.08 + intensity * 0.05;
        spec.bloom = {
            delayDuration: Math.max(0, duration - Math.max(44, Math.round(duration * 0.16)) - Math.round(Math.max(60, Math.round(duration * 0.22)) * 0.5)),
            riseTo: 0.16 + intensity * 0.16,
            riseDuration: Math.max(44, Math.round(duration * 0.16)),
            fallDuration: Math.max(60, Math.round(duration * 0.22)),
            scaleTo: 1.1 + intensity * 0.16
        };
        spec.colorMix.lead = 0.08;
        spec.colorMix.trail = 0.62;
        spec.colorMix.glow = 0.88;
        spec.colorMix.bloom = 0.96;
        spec.effectMix.bloom = 0.14;
        spec.layerRoles = makeLayerRoles("lead", "glow", "glow", "effect", "effect", "effect");
        break;
    }

    spec.axis.firstTo = endAxis;
    if (spec.axis.secondDuration === 0)
        spec.axis.secondTo = endAxis;

    if (styleKey !== "ribbon-pop") {
        spec.length.firstTo = endLength;
        spec.length.secondTo = endLength;
    }

    if (distance > 0 && styleKey !== "spring-caravan" && styleKey !== "ribbon-pop") {
        spec.axis.firstDuration = Math.max(Math.round(duration * 0.58), Math.min(duration, Math.round(duration * (0.4 + Math.min(1, distance / Math.max(endLength, 1)) * 0.24))));
        spec.axis.secondDuration = Math.max(0, duration - spec.axis.firstDuration);
        if (spec.axis.secondDuration === 0)
            spec.axis.secondTo = endAxis;
    }

    if (styleKey === "soft-comet" || styleKey === "twin-echo" || styleKey === "halo-slip")
        spec.length.firstDuration = Math.max(0, Math.round(duration * 0.08));

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
