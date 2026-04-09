import QtQuick
import qs.Commons
import "FocusTransitionStyle.js" as FocusTransitionStyle

Item {
    id: root

    property bool isVerticalBar: false
    property bool transitionEnabled: true
    property int delayMs: 120
    property int durationMs: 220
    property string styleKey: "soft-comet"
    property real intensityRatio: 0.6
    property real thickness: 6
    property string colorKey: "primary"
    property string glowColorKey: "primary"
    property string effectColorKey: "tertiary"
    property string verticalPosition: "bottom"
    property real blurRadius: 6
    property real opacityRatio: 0.85
    property int totalDurationMs: Math.max(1, durationMs)

    property bool focusTravelActive: false
    property real focusTravelAxisPosition: 0
    property real focusTravelCrossPosition: 0
    property real focusTravelLength: 0
    property real focusTravelThickness: 0
    property real focusTravelStartCenterAxis: 0
    property real focusTravelOpacity: 0
    property real focusTravelLeadOpacity: 0
    property real focusTravelTrailOpacity: 0
    property real focusTravelGlowOpacity: 0
    property real focusTravelHaloOpacity: 0
    property real focusTravelRibbonOpacity: 0
    property real focusTravelTrailStrength: 0
    property real focusTravelGlowStrength: 0
    property real focusTravelBloomOpacity: 0
    property real focusTravelBloomScale: 1
    property real focusTravelLeadColorMix: 0.08
    property real focusTravelTrailColorMix: 0.72
    property real focusTravelGlowColorMix: 1
    property real focusTravelHaloColorMix: 0.86
    property real focusTravelRibbonColorMix: 0.56
    property real focusTravelBloomColorMix: 0.94
    property real focusTravelLeadEffectMix: 0.15
    property real focusTravelTrailEffectMix: 0.25
    property real focusTravelGlowEffectMix: 0.18
    property real focusTravelHaloEffectMix: 0.22
    property real focusTravelRibbonEffectMix: 0.3
    property real focusTravelBloomEffectMix: 0.2
    property real focusTravelDirectionSign: 1
    property string focusTravelLeadShape: "pill"
    property string focusTravelTrailShape: "none"
    property int focusTravelTrailingPieces: 0
    property real focusTravelTrailingGap: 0
    property real focusTravelTrailingMainRatio: 0.7
    property real focusTravelTrailingCrossRatio: 0.7
    property real focusTravelTrailingOpacityFalloff: 0.2
    property real focusTravelTrailingScaleFalloff: 0.14
    property real focusTravelRibbonStrength: 0
    property real focusTravelHaloStrength: 0
    property var focusTravelStartRect: null
    property var focusTravelEndRect: null
    property var pendingStartRect: null
    property var pendingEndRect: null
    property bool completionSignalPending: false

    readonly property real focusTravelMarkerCenterAxis: focusTravelAxisPosition + (focusTravelLength / 2)
    readonly property real focusTravelTrailStartAxis: Math.min(focusTravelStartCenterAxis, focusTravelMarkerCenterAxis)
    readonly property real focusTravelTrailExtent: Math.max(0, Math.abs(focusTravelMarkerCenterAxis - focusTravelStartCenterAxis))

    signal transitionFinished()

    function resolveFocusTransitionColor(key, fallbackColor) {
        if (!key || key === "none")
            return fallbackColor;
        return Color.resolveColorKey(key);
    }

    function mixTransitionColors(mixRatio, effectRatio) {
        const baseColor = resolveFocusTransitionColor(colorKey, Color.mPrimary);
        const glowColor = resolveFocusTransitionColor(glowColorKey, Color.mPrimary);
        const effColor = resolveFocusTransitionColor(effectColorKey, Color.mTertiary);
        const ratio = Math.max(0, Math.min(1, mixRatio));
        const eRatio = Math.max(0, Math.min(1, effectRatio || 0));
        const r1 = baseColor.r + (glowColor.r - baseColor.r) * ratio;
        const g1 = baseColor.g + (glowColor.g - baseColor.g) * ratio;
        const b1 = baseColor.b + (glowColor.b - baseColor.b) * ratio;
        return Qt.rgba(
            r1 + (effColor.r - r1) * eRatio,
            g1 + (effColor.g - g1) * eRatio,
            b1 + (effColor.b - b1) * eRatio,
            1
        );
    }

    function applyTransitionAlpha(colorValue, alphaValue) {
        return Qt.rgba(colorValue.r, colorValue.g, colorValue.b, Math.max(0, Math.min(1, alphaValue)));
    }

    function resolveEasingType(name) {
        switch (name) {
        case "inCubic":
            return Easing.InCubic;
        case "outCubic":
            return Easing.OutCubic;
        case "inOutCubic":
            return Easing.InOutCubic;
        case "outBack":
            return Easing.OutBack;
        case "inQuad":
            return Easing.InQuad;
        case "outQuad":
            return Easing.OutQuad;
        case "inOutQuad":
            return Easing.InOutQuad;
        case "inQuart":
            return Easing.InQuart;
        case "outQuart":
            return Easing.OutQuart;
        case "inOutQuart":
            return Easing.InOutQuart;
        case "inQuint":
            return Easing.InQuint;
        case "outQuint":
            return Easing.OutQuint;
        case "inOutQuint":
            return Easing.InOutQuint;
        case "inExpo":
            return Easing.InExpo;
        case "outExpo":
            return Easing.OutExpo;
        case "inOutExpo":
            return Easing.InOutExpo;
        case "inSine":
            return Easing.InSine;
        case "outSine":
            return Easing.OutSine;
        case "inOutSine":
            return Easing.InOutSine;
        case "outElastic":
            return Easing.OutElastic;
        case "outCirc":
            return Easing.OutCirc;
        default:
            return Easing.Linear;
        }
    }

    function configureAxisAnimation(firstTo, firstDuration, firstEasing, secondTo, secondDuration, secondEasing) {
        focusTravelAxisStep1.to = firstTo;
        focusTravelAxisStep1.duration = Math.max(0, Math.round(firstDuration));
        focusTravelAxisStep1.easing.type = resolveEasingType(firstEasing);

        // Configure OutElastic-specific parameters
        if (firstEasing === "outElastic") {
            focusTravelAxisStep1.easing.amplitude = 1.0;  // Overshoot amount (try 0.8-1.2)
            focusTravelAxisStep1.easing.period = 0.4;     // Bounce frequency (try 0.3-0.5, lower = fewer bounces)
            focusTravelAxisStep1.easing.mode = Easing.EaseInOut;
        }

        focusTravelAxisStep2.to = secondTo;
        focusTravelAxisStep2.duration = Math.max(0, Math.round(secondDuration));
        focusTravelAxisStep2.easing.type = resolveEasingType(secondEasing);
        focusTravelAxisSequence.restart();
    }

    function configureLengthAnimation(firstTo, firstDuration, firstEasing, secondTo, secondDuration, secondEasing) {
        focusTravelLengthStep1.to = firstTo;
        focusTravelLengthStep1.duration = Math.max(0, Math.round(firstDuration));
        focusTravelLengthStep1.easing.type = resolveEasingType(firstEasing);
        focusTravelLengthStep2.to = secondTo;
        focusTravelLengthStep2.duration = Math.max(0, Math.round(secondDuration));
        focusTravelLengthStep2.easing.type = resolveEasingType(secondEasing);
        focusTravelLengthSequence.restart();
    }

    function configureOpacityAnimation(startOpacity, fadeInTo, fadeInDuration, holdDuration, fadeOutTo, fadeOutDuration, fadeInEasing, fadeOutEasing) {
        focusTravelOpacity = startOpacity;
        focusTravelOpacityStep1.to = fadeInTo;
        focusTravelOpacityStep1.duration = Math.max(0, Math.round(fadeInDuration));
        focusTravelOpacityStep1.easing.type = resolveEasingType(fadeInEasing || "outCubic");
        focusTravelOpacityPause.duration = Math.max(0, Math.round(holdDuration));
        focusTravelOpacityStep2.to = fadeOutTo;
        focusTravelOpacityStep2.duration = Math.max(0, Math.round(fadeOutDuration));
        focusTravelOpacityStep2.easing.type = resolveEasingType(fadeOutEasing || "inCubic");
        focusTravelOpacitySequence.restart();
    }

    function configureBloomAnimation(delayDuration, riseTo, riseDuration, fallDuration, scaleTo) {
        focusTravelBloomOpacity = 0;
        focusTravelBloomScale = 1;
        focusTravelBloomPause.duration = Math.max(0, Math.round(delayDuration));
        focusTravelBloomOpacityRise.to = riseTo;
        focusTravelBloomOpacityRise.duration = Math.max(0, Math.round(riseDuration));
        focusTravelBloomOpacityFall.to = 0;
        focusTravelBloomOpacityFall.duration = Math.max(0, Math.round(fallDuration));
        focusTravelBloomScaleRise.to = scaleTo;
        focusTravelBloomScaleRise.duration = Math.max(0, Math.round(riseDuration));
        focusTravelBloomScaleFall.to = 1;
        focusTravelBloomScaleFall.duration = Math.max(0, Math.round(fallDuration));
        focusTravelBloomOpacitySequence.restart();
        focusTravelBloomScaleSequence.restart();
    }

    function configureLayerOpacityAnimation(sequence, step1, pause, step2, propertyName, spec, fadeInEasing, fadeOutEasing) {
        const layerSpec = spec || ({
            "startOpacity": 0,
            "fadeInTo": 0,
            "fadeInDuration": 0,
            "holdDuration": 0,
            "fadeOutTo": 0,
            "fadeOutDuration": 0
        });

        root[propertyName] = layerSpec.startOpacity;
        step1.to = layerSpec.fadeInTo;
        step1.duration = Math.max(0, Math.round(layerSpec.fadeInDuration));
        step1.easing.type = resolveEasingType(fadeInEasing || "outCubic");
        pause.duration = Math.max(0, Math.round(layerSpec.holdDuration));
        step2.to = layerSpec.fadeOutTo;
        step2.duration = Math.max(0, Math.round(layerSpec.fadeOutDuration));
        step2.easing.type = resolveEasingType(fadeOutEasing || "inCubic");
        sequence.restart();
    }

    function setFocusTransitionPieces(shape, count, gap, mainRatio, crossRatio, opacityFalloff, scaleFalloff) {
        focusTravelTrailShape = shape;
        focusTravelTrailingPieces = count;
        focusTravelTrailingGap = gap;
        focusTravelTrailingMainRatio = mainRatio;
        focusTravelTrailingCrossRatio = crossRatio;
        focusTravelTrailingOpacityFalloff = opacityFalloff;
        focusTravelTrailingScaleFalloff = scaleFalloff;
    }

    function cancelTransition() {
        completionSignalPending = false;
        focusTravelActive = false;
        focusTravelOpacity = 0;
        focusTravelLeadOpacity = 0;
        focusTravelTrailOpacity = 0;
        focusTravelGlowOpacity = 0;
        focusTravelHaloOpacity = 0;
        focusTravelRibbonOpacity = 0;
        focusTravelTrailStrength = 0;
        focusTravelGlowStrength = 0;
        focusTravelBloomOpacity = 0;
        focusTravelBloomScale = 1;
        focusTravelLeadColorMix = 0.08;
        focusTravelTrailColorMix = 0.72;
        focusTravelGlowColorMix = 1;
        focusTravelHaloColorMix = 0.86;
        focusTravelRibbonColorMix = 0.56;
        focusTravelBloomColorMix = 0.94;
        focusTravelLeadEffectMix = 0.15;
        focusTravelTrailEffectMix = 0.25;
        focusTravelGlowEffectMix = 0.18;
        focusTravelHaloEffectMix = 0.22;
        focusTravelRibbonEffectMix = 0.3;
        focusTravelBloomEffectMix = 0.2;
        focusTravelDirectionSign = 1;
        focusTravelLeadShape = "pill";
        focusTravelTrailShape = "none";
        focusTravelTrailingPieces = 0;
        focusTravelTrailingGap = 0;
        focusTravelTrailingMainRatio = 0.7;
        focusTravelTrailingCrossRatio = 0.7;
        focusTravelTrailingOpacityFalloff = 0.2;
        focusTravelTrailingScaleFalloff = 0.14;
        focusTravelRibbonStrength = 0;
        focusTravelHaloStrength = 0;
        focusTravelStartRect = null;
        focusTravelEndRect = null;
        pendingStartRect = null;
        pendingEndRect = null;
        focusTransitionDelayTimer.stop();
        focusTravelAxisSequence.stop();
        focusTravelLengthSequence.stop();
        focusTravelOpacitySequence.stop();
        focusTravelLeadOpacitySequence.stop();
        focusTravelTrailOpacitySequence.stop();
        focusTravelGlowOpacitySequence.stop();
        focusTravelHaloOpacitySequence.stop();
        focusTravelRibbonOpacitySequence.stop();
        focusTravelBloomOpacitySequence.stop();
        focusTravelBloomScaleSequence.stop();
    }

    function beginTransition(startRect, endRect) {
        if (!startRect || !endRect)
            return;

        const startAxis = isVerticalBar ? startRect.y : startRect.x;
        const endAxis = isVerticalBar ? endRect.y : endRect.x;
        const startLength = isVerticalBar ? startRect.height : startRect.width;
        const endLength = isVerticalBar ? endRect.height : endRect.width;
        const duration = Math.max(1, durationMs);
        const direction = endAxis >= startAxis ? 1 : -1;
        const spec = FocusTransitionStyle.buildSpec({
            "style": styleKey,
            "startAxis": startAxis,
            "endAxis": endAxis,
            "startLength": startLength,
            "endLength": endLength,
            "duration": duration,
            "direction": direction,
            "intensityRatio": intensityRatio,
            "uiScaleRatio": Style.uiScaleRatio
        });

        totalDurationMs = FocusTransitionStyle.totalDurationForSpec(spec);
        focusTravelStartRect = startRect;
        focusTravelEndRect = endRect;
        focusTravelLength = spec.useStartLength ? startLength : endLength;
        focusTravelThickness = isVerticalBar ? endRect.width : endRect.height;
        focusTravelAxisPosition = startAxis;
        focusTravelCrossPosition = isVerticalBar ? endRect.x : endRect.y;
        focusTravelStartCenterAxis = startAxis + focusTravelLength / 2;
        focusTravelTrailStrength = spec.trailStrength;
        focusTravelGlowStrength = spec.glowStrength;
        focusTravelBloomOpacity = 0;
        focusTravelBloomScale = 1;
        focusTravelLeadColorMix = spec.colorMix?.lead ?? 0.08;
        focusTravelTrailColorMix = spec.colorMix?.trail ?? 0.72;
        focusTravelGlowColorMix = spec.colorMix?.glow ?? 1;
        focusTravelHaloColorMix = spec.colorMix?.halo ?? 0.86;
        focusTravelRibbonColorMix = spec.colorMix?.ribbon ?? 0.56;
        focusTravelBloomColorMix = spec.colorMix?.bloom ?? 0.94;
        focusTravelLeadEffectMix = spec.effectMix?.lead ?? 0.15;
        focusTravelTrailEffectMix = spec.effectMix?.trail ?? 0.25;
        focusTravelGlowEffectMix = spec.effectMix?.glow ?? 0.18;
        focusTravelHaloEffectMix = spec.effectMix?.halo ?? 0.22;
        focusTravelRibbonEffectMix = spec.effectMix?.ribbon ?? 0.3;
        focusTravelBloomEffectMix = spec.effectMix?.bloom ?? 0.2;
        focusTravelDirectionSign = direction;
        focusTravelLeadShape = spec.leadShape;
        focusTravelRibbonStrength = spec.ribbonStrength;
        focusTravelHaloStrength = spec.haloStrength;
        setFocusTransitionPieces(spec.trailShape, spec.trailingPieces, spec.trailingGap, spec.trailingMainRatio, spec.trailingCrossRatio, spec.trailingOpacityFalloff, spec.trailingScaleFalloff);
        focusTravelActive = true;
        completionSignalPending = true;

        configureAxisAnimation(spec.axis.firstTo, spec.axis.firstDuration, spec.axis.firstEasing, spec.axis.secondTo, spec.axis.secondDuration, spec.axis.secondEasing);
        configureLengthAnimation(spec.length.firstTo, spec.length.firstDuration, spec.length.firstEasing, spec.length.secondTo, spec.length.secondDuration, spec.length.secondEasing);
        configureOpacityAnimation(spec.opacity.startOpacity, spec.opacity.fadeInTo, spec.opacity.fadeInDuration, spec.opacity.holdDuration, spec.opacity.fadeOutTo, spec.opacity.fadeOutDuration, spec.opacity.fadeInEasing, spec.opacity.fadeOutEasing);
        configureLayerOpacityAnimation(focusTravelLeadOpacitySequence, focusTravelLeadOpacityStep1, focusTravelLeadOpacityPause, focusTravelLeadOpacityStep2, "focusTravelLeadOpacity", spec.layers?.lead, "outCubic", "inCubic");
        configureLayerOpacityAnimation(focusTravelTrailOpacitySequence, focusTravelTrailOpacityStep1, focusTravelTrailOpacityPause, focusTravelTrailOpacityStep2, "focusTravelTrailOpacity", spec.layers?.trail, "outCubic", "inCubic");
        configureLayerOpacityAnimation(focusTravelGlowOpacitySequence, focusTravelGlowOpacityStep1, focusTravelGlowOpacityPause, focusTravelGlowOpacityStep2, "focusTravelGlowOpacity", spec.layers?.glow, "outCubic", "inCubic");
        configureLayerOpacityAnimation(focusTravelHaloOpacitySequence, focusTravelHaloOpacityStep1, focusTravelHaloOpacityPause, focusTravelHaloOpacityStep2, "focusTravelHaloOpacity", spec.layers?.halo, "outCubic", "inCubic");
        configureLayerOpacityAnimation(focusTravelRibbonOpacitySequence, focusTravelRibbonOpacityStep1, focusTravelRibbonOpacityPause, focusTravelRibbonOpacityStep2, "focusTravelRibbonOpacity", spec.layers?.ribbon, "outCubic", "inCubic");

        if (spec.bloom) {
            configureBloomAnimation(spec.bloom.delayDuration, spec.bloom.riseTo, spec.bloom.riseDuration, spec.bloom.fallDuration, spec.bloom.scaleTo);
        } else {
            focusTravelBloomOpacitySequence.stop();
            focusTravelBloomScaleSequence.stop();
            focusTravelBloomOpacity = 0;
            focusTravelBloomScale = 1;
        }
    }

    function scheduleTransition(startRect, endRect) {
        cancelTransition();
        if (!transitionEnabled || !startRect || !endRect)
            return;

        pendingStartRect = startRect;
        pendingEndRect = endRect;
        focusTransitionDelayTimer.interval = Math.max(0, delayMs);
        focusTransitionDelayTimer.restart();
    }

    Timer {
        id: focusTransitionDelayTimer
        interval: Math.max(0, root.delayMs)
        repeat: false
        onTriggered: {
            const startRect = root.pendingStartRect;
            const endRect = root.pendingEndRect;
            root.pendingStartRect = null;
            root.pendingEndRect = null;

            if (!startRect || !endRect)
                return;

            root.beginTransition(startRect, endRect);
        }
    }

    SequentialAnimation {
        id: focusTravelAxisSequence
        running: false

        NumberAnimation {
            id: focusTravelAxisStep1
            target: root
            property: "focusTravelAxisPosition"
        }

        NumberAnimation {
            id: focusTravelAxisStep2
            target: root
            property: "focusTravelAxisPosition"
        }
    }

    SequentialAnimation {
        id: focusTravelLengthSequence
        running: false

        NumberAnimation {
            id: focusTravelLengthStep1
            target: root
            property: "focusTravelLength"
        }

        NumberAnimation {
            id: focusTravelLengthStep2
            target: root
            property: "focusTravelLength"
        }
    }

    SequentialAnimation {
        id: focusTravelOpacitySequence
        running: false
        onStopped: {
            root.focusTravelActive = false;
            if (root.completionSignalPending) {
                root.completionSignalPending = false;
                root.transitionFinished();
            }
        }

        NumberAnimation {
            id: focusTravelOpacityStep1
            target: root
            property: "focusTravelOpacity"
            easing.type: Easing.OutCubic
        }

        PauseAnimation {
            id: focusTravelOpacityPause
        }

        NumberAnimation {
            id: focusTravelOpacityStep2
            target: root
            property: "focusTravelOpacity"
            easing.type: Easing.InCubic
        }
    }

    SequentialAnimation {
        id: focusTravelLeadOpacitySequence
        running: false

        NumberAnimation {
            id: focusTravelLeadOpacityStep1
            target: root
            property: "focusTravelLeadOpacity"
        }

        PauseAnimation {
            id: focusTravelLeadOpacityPause
        }

        NumberAnimation {
            id: focusTravelLeadOpacityStep2
            target: root
            property: "focusTravelLeadOpacity"
        }
    }

    SequentialAnimation {
        id: focusTravelTrailOpacitySequence
        running: false

        NumberAnimation {
            id: focusTravelTrailOpacityStep1
            target: root
            property: "focusTravelTrailOpacity"
        }

        PauseAnimation {
            id: focusTravelTrailOpacityPause
        }

        NumberAnimation {
            id: focusTravelTrailOpacityStep2
            target: root
            property: "focusTravelTrailOpacity"
        }
    }

    SequentialAnimation {
        id: focusTravelGlowOpacitySequence
        running: false

        NumberAnimation {
            id: focusTravelGlowOpacityStep1
            target: root
            property: "focusTravelGlowOpacity"
        }

        PauseAnimation {
            id: focusTravelGlowOpacityPause
        }

        NumberAnimation {
            id: focusTravelGlowOpacityStep2
            target: root
            property: "focusTravelGlowOpacity"
        }
    }

    SequentialAnimation {
        id: focusTravelHaloOpacitySequence
        running: false

        NumberAnimation {
            id: focusTravelHaloOpacityStep1
            target: root
            property: "focusTravelHaloOpacity"
        }

        PauseAnimation {
            id: focusTravelHaloOpacityPause
        }

        NumberAnimation {
            id: focusTravelHaloOpacityStep2
            target: root
            property: "focusTravelHaloOpacity"
        }
    }

    SequentialAnimation {
        id: focusTravelRibbonOpacitySequence
        running: false

        NumberAnimation {
            id: focusTravelRibbonOpacityStep1
            target: root
            property: "focusTravelRibbonOpacity"
        }

        PauseAnimation {
            id: focusTravelRibbonOpacityPause
        }

        NumberAnimation {
            id: focusTravelRibbonOpacityStep2
            target: root
            property: "focusTravelRibbonOpacity"
        }
    }

    SequentialAnimation {
        id: focusTravelBloomOpacitySequence
        running: false

        PauseAnimation {
            id: focusTravelBloomPause
        }

        NumberAnimation {
            id: focusTravelBloomOpacityRise
            target: root
            property: "focusTravelBloomOpacity"
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: focusTravelBloomOpacityFall
            target: root
            property: "focusTravelBloomOpacity"
            easing.type: Easing.InCubic
        }
    }

    SequentialAnimation {
        id: focusTravelBloomScaleSequence
        running: false

        PauseAnimation {
            duration: focusTravelBloomPause.duration
        }

        NumberAnimation {
            id: focusTravelBloomScaleRise
            target: root
            property: "focusTravelBloomScale"
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: focusTravelBloomScaleFall
            target: root
            property: "focusTravelBloomScale"
            easing.type: Easing.InCubic
        }
    }

    visible: focusTravelActive && focusTravelOpacity > 0

    readonly property color ribbonColor: mixTransitionColors(focusTravelRibbonColorMix, focusTravelRibbonEffectMix)
    readonly property color trailColor: mixTransitionColors(focusTravelTrailColorMix, focusTravelTrailEffectMix)
    readonly property color glowColor: mixTransitionColors(focusTravelGlowColorMix, focusTravelGlowEffectMix)
    readonly property color haloColor: mixTransitionColors(focusTravelHaloColorMix, focusTravelHaloEffectMix)
    readonly property color leadColor: mixTransitionColors(focusTravelLeadColorMix, focusTravelLeadEffectMix)
    readonly property color bloomColor: mixTransitionColors(focusTravelBloomColorMix, focusTravelBloomEffectMix)

    Rectangle {
        visible: root.focusTravelRibbonStrength > 0 && root.focusTravelTrailExtent > 0 && root.focusTravelRibbonOpacity > 0
        x: root.isVerticalBar ? (root.focusTravelCrossPosition + root.focusTravelThickness * 0.18) : root.focusTravelTrailStartAxis
        y: root.isVerticalBar ? root.focusTravelTrailStartAxis : (root.focusTravelCrossPosition + root.focusTravelThickness * 0.18)
        width: root.isVerticalBar ? Math.max(2, root.focusTravelThickness * 0.64) : root.focusTravelTrailExtent
        height: root.isVerticalBar ? root.focusTravelTrailExtent : Math.max(2, root.focusTravelThickness * 0.64)
        radius: Math.max(width, height) / 2
        color: root.applyTransitionAlpha(root.ribbonColor, root.focusTravelRibbonStrength * root.focusTravelOpacity * root.opacityRatio * root.focusTravelRibbonOpacity)
    }

    Rectangle {
        visible: root.focusTravelTrailExtent > 1 && root.focusTravelTrailStrength > 0 && root.focusTravelTrailOpacity > 0
        x: root.isVerticalBar ? (root.focusTravelCrossPosition - 2 - root.blurRadius * 0.5) : (root.focusTravelTrailStartAxis - root.blurRadius * 0.5)
        y: root.isVerticalBar ? (root.focusTravelTrailStartAxis - root.blurRadius * 0.5) : (root.focusTravelCrossPosition - 2 - root.blurRadius * 0.5)
        width: root.isVerticalBar ? (root.focusTravelThickness + 4 + root.blurRadius) : (root.focusTravelTrailExtent + root.blurRadius)
        height: root.isVerticalBar ? (root.focusTravelTrailExtent + root.blurRadius) : (root.focusTravelThickness + 4 + root.blurRadius)
        radius: Math.max(width, height) / 2
        color: root.applyTransitionAlpha(root.trailColor, root.focusTravelTrailStrength * root.focusTravelOpacity * root.opacityRatio * root.focusTravelTrailOpacity)
    }

    Rectangle {
        visible: root.focusTravelGlowStrength > 0 && root.focusTravelGlowOpacity > 0
        x: root.isVerticalBar ? (root.focusTravelCrossPosition - 4 - (root.focusTravelBloomScale - 1) * 2 - root.blurRadius) : (root.focusTravelAxisPosition - 4 - (root.focusTravelBloomScale - 1) * 4 - root.blurRadius)
        y: root.isVerticalBar ? (root.focusTravelAxisPosition - 4 - (root.focusTravelBloomScale - 1) * 4 - root.blurRadius) : (root.focusTravelCrossPosition - 4 - (root.focusTravelBloomScale - 1) * 2 - root.blurRadius)
        width: root.isVerticalBar ? (root.focusTravelThickness + 8 + (root.focusTravelBloomScale - 1) * 4 + root.blurRadius * 2) : (root.focusTravelLength + 8 + (root.focusTravelBloomScale - 1) * 8 + root.blurRadius * 2)
        height: root.isVerticalBar ? (root.focusTravelLength + 8 + (root.focusTravelBloomScale - 1) * 8 + root.blurRadius * 2) : (root.focusTravelThickness + 8 + (root.focusTravelBloomScale - 1) * 4 + root.blurRadius * 2)
        radius: Math.max(width, height) / 2
        color: root.applyTransitionAlpha(root.glowColor, root.focusTravelGlowStrength * root.focusTravelOpacity * root.opacityRatio * root.focusTravelGlowOpacity)
    }

    Rectangle {
        visible: root.focusTravelHaloStrength > 0 && root.focusTravelHaloOpacity > 0
        x: root.isVerticalBar ? (root.focusTravelCrossPosition - 3 - root.blurRadius * 0.25) : (root.focusTravelAxisPosition - 3 - root.blurRadius * 0.25)
        y: root.isVerticalBar ? (root.focusTravelAxisPosition - 3 - root.blurRadius * 0.25) : (root.focusTravelCrossPosition - 3 - root.blurRadius * 0.25)
        width: root.isVerticalBar ? (root.focusTravelThickness + 6 + root.blurRadius * 0.5) : (root.focusTravelLength + 6 + root.blurRadius * 0.5)
        height: root.isVerticalBar ? (root.focusTravelLength + 6 + root.blurRadius * 0.5) : (root.focusTravelThickness + 6 + root.blurRadius * 0.5)
        radius: Math.max(width, height) / 2
        color: "transparent"
        border.width: Math.max(1, Style.borderS)
        border.color: root.applyTransitionAlpha(root.haloColor, root.focusTravelHaloStrength * root.focusTravelOpacity * root.opacityRatio * root.focusTravelHaloOpacity)
    }

    Repeater {
        model: 4

        delegate: Rectangle {
            required property int index
            readonly property bool enabledPiece: root.focusTravelTrailingPieces > index && root.focusTravelTrailShape !== "none"
            readonly property real lag: root.focusTravelTrailingGap * (index + 1)
            readonly property real centerAxis: root.focusTravelMarkerCenterAxis - root.focusTravelDirectionSign * lag
            readonly property real scaleFactor: Math.max(0.18, 1 - index * root.focusTravelTrailingScaleFalloff)
            readonly property real baseMain: root.focusTravelLength * root.focusTravelTrailingMainRatio
            readonly property real baseCross: root.focusTravelThickness * root.focusTravelTrailingCrossRatio
            readonly property real pieceMain: {
                if (root.focusTravelTrailShape === "dot")
                    return Math.max(3, Math.min(baseMain, baseCross) * scaleFactor);
                return Math.max(3, baseMain * scaleFactor);
            }
            readonly property real pieceCross: {
                if (root.focusTravelTrailShape === "dot")
                    return pieceMain;
                return Math.max(3, baseCross * scaleFactor);
            }
            readonly property real pieceOpacity: Math.max(0, root.focusTravelOpacity * root.focusTravelTrailOpacity * root.opacityRatio * (1 - index * root.focusTravelTrailingOpacityFalloff))
            readonly property real pieceX: root.isVerticalBar ? (root.focusTravelCrossPosition + (root.focusTravelThickness - pieceCross) / 2) : (centerAxis - pieceMain / 2)
            readonly property real pieceY: root.isVerticalBar ? (centerAxis - pieceMain / 2) : (root.focusTravelCrossPosition + (root.focusTravelThickness - pieceCross) / 2)
            readonly property real pieceWidth: root.isVerticalBar ? pieceCross : pieceMain
            readonly property real pieceHeight: root.isVerticalBar ? pieceMain : pieceCross

            visible: enabledPiece
            x: pieceX
            y: pieceY
            width: pieceWidth
            height: pieceHeight
            radius: {
                switch (root.focusTravelTrailShape) {
                case "shard":
                    return Math.min(Style.radiusXXS, Math.min(width, height) / 3);
                case "dot":
                    return width / 2;
                default:
                    return Math.max(width, height) / 2;
                }
            }
            color: Qt.alpha(root.trailColor, pieceOpacity)
            border.width: root.focusTravelTrailShape === "echo" ? Math.max(1, Style.borderS) : 0
            border.color: root.focusTravelTrailShape === "echo" ? Qt.alpha(root.trailColor, pieceOpacity * 0.9) : "transparent"
        }
    }

    Rectangle {
        x: root.isVerticalBar ? root.focusTravelCrossPosition : root.focusTravelAxisPosition
        y: root.isVerticalBar ? root.focusTravelAxisPosition : root.focusTravelCrossPosition
        width: root.isVerticalBar ? root.focusTravelThickness : root.focusTravelLength
        height: root.isVerticalBar ? root.focusTravelLength : root.focusTravelThickness
        radius: root.focusTravelLeadShape === "rect" ? Math.min(Style.radiusXS, Math.min(width, height) / 3) : Math.max(width, height) / 2
        border.width: root.focusTravelLeadShape === "rect" ? Math.max(1, Style.borderS) : 0
        border.color: root.focusTravelLeadShape === "rect" ? root.applyTransitionAlpha(root.leadColor, 0.65 * root.focusTravelOpacity * root.opacityRatio * root.focusTravelLeadOpacity) : "transparent"
        color: root.applyTransitionAlpha(root.leadColor, root.focusTravelOpacity * root.opacityRatio * root.focusTravelLeadOpacity)
    }

    Rectangle {
        readonly property var bloomRect: root.focusTravelEndRect || ({
            "x": 0,
            "y": 0,
            "width": 0,
            "height": 0
        })

        visible: root.focusTravelBloomOpacity > 0 && root.focusTravelEndRect
        x: root.isVerticalBar ? (bloomRect.x - (root.focusTravelBloomScale - 1) * 3 - root.blurRadius) : (bloomRect.x - (root.focusTravelBloomScale - 1) * 6 - root.blurRadius)
        y: root.isVerticalBar ? (bloomRect.y - (root.focusTravelBloomScale - 1) * 6 - root.blurRadius) : (bloomRect.y - (root.focusTravelBloomScale - 1) * 3 - root.blurRadius)
        width: root.isVerticalBar ? (bloomRect.width + (root.focusTravelBloomScale - 1) * 6 + root.blurRadius * 2) : (bloomRect.width + (root.focusTravelBloomScale - 1) * 12 + root.blurRadius * 2)
        height: root.isVerticalBar ? (bloomRect.height + (root.focusTravelBloomScale - 1) * 12 + root.blurRadius * 2) : (bloomRect.height + (root.focusTravelBloomScale - 1) * 6 + root.blurRadius * 2)
        radius: Math.max(width, height) / 2
        color: root.applyTransitionAlpha(root.bloomColor, root.focusTravelBloomOpacity * root.opacityRatio)
    }
}
