import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets
import "./components"

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property var currentSettings: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance ?? null

    function refreshSettingsSnapshot() {
        currentSettings = pluginApi?.pluginSettings || ({});
    }

    function clampScrollOffset(value) {
        return Math.max(minScrollOffset, Math.min(maxScrollOffset, value));
    }

    function clampScrollPosition() {
        if (!flickable)
            return;

        if (isVertical)
            flickable.contentY = clampScrollOffset(flickable.contentY);
        else
            flickable.contentX = clampScrollOffset(flickable.contentX);
    }

    onPluginApiChanged: refreshSettingsSnapshot()

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshSettingsSnapshot();
        }
    }

    function settingValue(groupKey, nestedKey, legacyKey, fallbackValue) {
        const configGroup = currentSettings ? currentSettings[groupKey] : undefined;
        const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
        if (nestedConfig !== undefined)
            return nestedConfig;

        const legacyConfig = currentSettings ? currentSettings[legacyKey] : undefined;
        if (legacyConfig !== undefined)
            return legacyConfig;

        const defaultsGroup = defaults ? defaults[groupKey] : undefined;
        const nestedDefault = defaultsGroup ? defaultsGroup[nestedKey] : undefined;
        if (nestedDefault !== undefined)
            return nestedDefault;

        const legacyDefault = defaults ? defaults[legacyKey] : undefined;
        if (legacyDefault !== undefined)
            return legacyDefault;

        return fallbackValue;
    }

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property bool onlySameOutput: settingValue("filtering", "onlySameOutput", "onlySameOutput", true)
    readonly property bool onlyActiveWorkspaces: settingValue("filtering", "onlyActiveWorkspaces", "onlyActiveWorkspaces", true)
    readonly property bool enableReorder: settingValue("interaction", "enableReorder", "enableReorder", true)
    readonly property bool debugLogging: settingValue("advanced", "debugLogging", "debugLogging", false)
    readonly property string widgetSizeMode: settingValue("layout", "widgetSizeMode", "widgetSizeMode", "dynamic")
    readonly property int fixedWidgetSize: Math.max(120, Math.round(settingValue("layout", "fixedWidgetSize", "fixedWidgetSize", 360)))
    readonly property int maxWidgetWidthPercent: settingValue("layout", "maxWidgetWidth", "maxWidgetWidth", 40)
    readonly property bool showSlots: settingValue("layout", "showSlots", "showSlots", true)
    readonly property real baseSlotLength: settingValue("layout", "slotWidth", "slotWidth", 112)
    readonly property real slotCapsuleScale: Math.max(0.3, settingValue("layout", "slotCapsuleScale", "slotCapsuleScale", 1.0))
    readonly property bool showTitle: !isVertical && settingValue("title", "showTitle", "showTitle", true)
    readonly property real iconScale: settingValue("icons", "iconScale", "iconScale", 0.8)
    readonly property bool edgeFadeEnabled: settingValue("edgeFade", "enabled", "edgeFadeEnabled", true)
    readonly property real edgeFadeSize: Math.max(0, Math.round(settingValue("edgeFade", "fadeSize", "edgeFadeSize", 48) * Style.uiScaleRatio))
    readonly property real edgeFadeOpacity: Math.max(0, Math.min(1, settingValue("edgeFade", "fadeOpacity", "edgeFadeOpacity", 100) / 100))
    readonly property bool showTrackLine: settingValue("indicators", "showTrackLine", "showTrackLine", true)
    readonly property string trackLinePosition: settingValue("indicators", "trackLinePosition", "trackLinePosition", "end")
    readonly property int trackLineThickness: Math.max(1, Math.min(8, Math.round(settingValue("indicators", "trackLineThickness", "trackLineThickness", 2))))
    readonly property string trackThumbColorKey: settingValue("indicators", "trackThumbColor", "trackThumbColor", "primary")
    readonly property color trackThumbColor: Color.resolveColorKey(trackThumbColorKey)
    readonly property real inactiveOpacity: Math.max(0.05, Math.min(1, settingValue("unfocused", "inactiveOpacity", "inactiveOpacity", 45) / 100))
    readonly property int slotSpacingUnits: settingValue("layout", "slotSpacingUnits", "slotSpacingUnits", 1)
    readonly property real radiusScale: settingValue("layout", "radiusScale", "radiusScale", 1.0)
    readonly property string hoverFillColorKey: settingValue("hover", "fillColor", "hoverFillColor", "hover")
    readonly property string hoverBorderColorKey: settingValue("hover", "borderColor", "hoverBorderColor", "outline")
    readonly property string hoverTextColorKey: settingValue("hover", "textColor", "hoverTextColor", "on-hover")
    readonly property real hoverFillOpacity: Math.max(0, Math.min(1, settingValue("hover", "fillOpacity", "hoverFillOpacity", 55) / 100))
    readonly property real hoverScalePercent: Math.max(0, settingValue("hover", "scalePercent", "hoverScalePercent", 2.5))
    readonly property int hoverTransitionDurationMs: Math.max(0, settingValue("hover", "transitionDurationMs", "hoverTransitionDurationMs", 120))
    readonly property real focusedFillOpacity: Math.max(0, Math.min(1, settingValue("focused", "fillOpacity", "focusedFillOpacity", 92) / 100))
    readonly property string focusedFillColorKey: settingValue("focused", "fillColor", "focusedFillColor", "primary")
    readonly property string focusedBorderColorKey: settingValue("focused", "borderColor", "focusedBorderColor", "primary")
    readonly property string focusedTextColorKey: settingValue("focused", "textColor", "focusedTextColor", "on-primary")
    readonly property bool showFocusedFill: settingValue("focused", "showFill", "showFocusedFill", true)
    readonly property real unfocusedFillOpacity: Math.max(0, Math.min(1, settingValue("unfocused", "fillOpacity", "unfocusedFillOpacity", 8) / 100))
    readonly property real unfocusedBorderOpacity: Math.max(0, Math.min(1, settingValue("unfocused", "borderOpacity", "unfocusedBorderOpacity", 45) / 100))
    readonly property string unfocusedFillColorKey: settingValue("unfocused", "fillColor", "unfocusedFillColor", "surface-variant")
    readonly property string unfocusedBorderColorKey: settingValue("unfocused", "borderColor", "unfocusedBorderColor", "outline")
    readonly property string unfocusedTextColorKey: settingValue("unfocused", "textColor", "unfocusedTextColor", "on-surface")
    readonly property bool showUnfocusedFill: settingValue("unfocused", "showFill", "showUnfocusedFill", true)
    readonly property bool showFocusedBorder: settingValue("focused", "showBorder", "showFocusedBorder", true)
    readonly property real focusedBorderOpacity: Math.max(0, Math.min(1, settingValue("focused", "borderOpacity", "focusedBorderOpacity", 100) / 100))
    readonly property bool showHoverBorder: settingValue("hover", "showBorder", "showHoverBorder", true)
    readonly property real hoverBorderOpacity: Math.max(0, Math.min(1, settingValue("hover", "borderOpacity", "hoverBorderOpacity", 100) / 100))
    readonly property bool showUnfocusedBorder: settingValue("unfocused", "showBorder", "showUnfocusedBorder", true)
    readonly property real trackOpacity: Math.max(0, Math.min(1, settingValue("indicators", "trackOpacity", "trackOpacity", 35) / 100))
    readonly property bool showFocusLine: settingValue("indicators", "showFocusLine", "showFocusLine", true)
    readonly property string focusLineColorKey: settingValue("indicators", "focusLineColor", "focusLineColor", "secondary")
    readonly property color focusLineColor: Color.resolveColorKey(focusLineColorKey)
    readonly property real focusLineOpacity: Math.max(0, Math.min(1, settingValue("indicators", "focusLineOpacity", "focusLineOpacity", 96) / 100))
    readonly property int focusLineThickness: Math.max(1, settingValue("indicators", "focusLineThickness", "focusLineThickness", 2))
    readonly property int focusLineAnimationMs: Math.max(0, settingValue("indicators", "focusLineAnimationMs", "focusLineAnimationMs", 120))
    readonly property bool enableScrollWheel: settingValue("interaction", "enableScrollWheel", "enableScrollWheel", true)
    readonly property bool centerFocusedWindow: settingValue("autoScroll", "centerFocusedWindow", "centerFocusedWindow", true)
    readonly property int centerAnimationMs: Math.max(0, settingValue("autoScroll", "centerAnimationMs", "centerAnimationMs", 200))
    readonly property bool supportsLiveReorder: enableReorder && (mainInstance?.supportsLiveReorder ?? false)

    readonly property bool showIcons: settingValue("icons", "showIcons", "showIcons", true)
    readonly property string titleFontFamily: settingValue("title", "titleFontFamily", "titleFontFamily", "")
    readonly property int titleFontSize: Math.max(0, settingValue("title", "titleFontSize", "titleFontSize", 0))
    readonly property string titleFontWeightKey: settingValue("title", "titleFontWeight", "titleFontWeight", "default")
    readonly property bool workspaceIndicatorEnabled: settingValue("workspaceIndicator", "enabled", "workspaceIndicatorEnabled", false)
    readonly property string workspaceIndicatorLabelMode: settingValue("workspaceIndicator", "labelMode", "workspaceIndicatorLabelMode", "id")
    readonly property string workspaceIndicatorPosition: settingValue("workspaceIndicator", "position", "workspaceIndicatorPosition", "before")
    readonly property real workspaceIndicatorSpacing: Math.max(0, Math.round(settingValue("workspaceIndicator", "spacing", "workspaceIndicatorSpacing", 8) * Style.uiScaleRatio))
    readonly property real workspaceIndicatorPadding: Math.max(0, Math.round(settingValue("workspaceIndicator", "padding", "workspaceIndicatorPadding", 0) * Style.uiScaleRatio))
    readonly property string workspaceIndicatorFontFamily: settingValue("workspaceIndicator", "fontFamily", "workspaceIndicatorFontFamily", "")
    readonly property int workspaceIndicatorFontSize: Math.max(0, settingValue("workspaceIndicator", "fontSize", "workspaceIndicatorFontSize", 0))
    readonly property string workspaceIndicatorTextColorKey: settingValue("workspaceIndicator", "textColor", "workspaceIndicatorTextColor", "primary")
    readonly property real workspaceIndicatorOpacity: Math.max(0, Math.min(1, settingValue("workspaceIndicator", "opacity", "workspaceIndicatorOpacity", 100) / 100))
    readonly property bool workspaceAnimationEnabled: settingValue("workspaceAnimation", "enabled", "workspaceAnimationEnabled", false)
    readonly property string workspaceAnimationAxis: settingValue("workspaceAnimation", "axis", "workspaceAnimationAxis", "horizontal")
    readonly property string iconTintColorKey: settingValue("icons", "iconTintColor", "iconTintColor", "none")
    readonly property real iconTintOpacity: Math.max(0, Math.min(1, settingValue("icons", "iconTintOpacity", "iconTintOpacity", 100) / 100))
    readonly property string backgroundColorKey: settingValue("background", "color", "backgroundColor", "none")
    readonly property real backgroundOpacity: Math.max(0, Math.min(1, settingValue("background", "opacity", "backgroundOpacity", 0) / 100))
    readonly property color iconTintColor: iconTintColorKey !== "none" ? Color.resolveColorKey(iconTintColorKey) : "transparent"
    readonly property bool iconTintEnabled: iconTintColorKey !== "none"
    readonly property bool backgroundEnabled: backgroundColorKey !== "none" && backgroundOpacity > 0
    readonly property color backgroundBaseColor: backgroundColorKey !== "none" ? Color.resolveColorKey(backgroundColorKey) : "transparent"
    readonly property color backgroundColor: backgroundEnabled ? Qt.alpha(backgroundBaseColor, backgroundOpacity) : "transparent"
    readonly property color focusedFillColor: Color.resolveColorKey(focusedFillColorKey)
    readonly property color focusedBorderColor: Color.resolveColorKey(focusedBorderColorKey)
    readonly property color focusedTextColor: Color.resolveColorKey(focusedTextColorKey)
    readonly property color hoverFillColor: Color.resolveColorKey(hoverFillColorKey)
    readonly property color hoverBorderColor: Color.resolveColorKey(hoverBorderColorKey)
    readonly property color hoverTextColor: Color.resolveColorKey(hoverTextColorKey)
    readonly property color unfocusedFillColor: Color.resolveColorKey(unfocusedFillColorKey)
    readonly property color unfocusedBorderColor: Color.resolveColorKey(unfocusedBorderColorKey)
    readonly property color unfocusedTextColor: Color.resolveColorKey(unfocusedTextColorKey)
    readonly property color workspaceIndicatorTextColor: Color.resolveColorKey(workspaceIndicatorTextColorKey)

    readonly property int titleFontWeightValue: {
        if (titleFontWeightKey === "light")
            return Font.Light;
        if (titleFontWeightKey === "normal")
            return Font.Normal;
        if (titleFontWeightKey === "medium")
            return Font.Medium;
        if (titleFontWeightKey === "semibold")
            return Font.DemiBold;
        if (titleFontWeightKey === "bold")
            return Font.Bold;
        return -1;
    }

    readonly property int slotLength: Math.max(Math.round(baseSlotLength * Style.uiScaleRatio), Math.round(capsuleHeight * 1.4))
    readonly property real hoverScaleMultiplier: 1 + (hoverScalePercent / 100)
    readonly property real dragScaleMultiplier: supportsLiveReorder ? 1.03 : 1.0
    readonly property real maxVisualScaleMultiplier: Math.max(1.0, hoverScaleMultiplier, dragScaleMultiplier)
    readonly property real slotSpacing: Math.max(0, Math.round(slotSpacingUnits * Style.marginS))
    readonly property real indicatorSpace: {
        let space = 0;
        if (showTrackLine)
            space = Math.max(space, trackThickness + 1);
        if (showFocusLine)
            space = Math.max(space, focusLineThickness);
        return space;
    }
    readonly property real scaledCapsuleHeight: capsuleHeight * slotCapsuleScale
    readonly property real crossExtent: {
        const widgetSize = isVertical ? width : height;
        if (widgetSize <= capsuleHeight)
            return capsuleHeight;
        return widgetSize - indicatorSpace;
    }
    readonly property real slotCrossExtent: scaledCapsuleHeight
    readonly property real trackThickness: trackLineThickness
    readonly property int itemSize: Style.toOdd(slotCrossExtent * Math.max(0.1, iconScale))
    readonly property int effectiveSlotLength: isVertical ? slotLength : (showTitle ? slotLength : Math.round(itemSize + 2 * Math.max(Style.marginM, Style.marginS * slotCapsuleScale)))
    readonly property real paintOverflowInset: hasWindow ? Math.max(0, Math.ceil(Math.max(effectiveSlotLength, slotCrossExtent) * (maxVisualScaleMultiplier - 1.0) / 2)) : 0
    readonly property var liveEntriesByKey: mainInstance?.liveEntriesByKey ?? ({})
    readonly property string activeEntryKey: mainInstance?.activeEntryKey ?? ""
    readonly property int structureRevision: mainInstance?.structureRevision ?? 0
    readonly property int liveRevision: mainInstance?.liveRevision ?? 0
    readonly property int workspaceRevision: mainInstance?.workspaceRevision ?? 0
    readonly property real logicalContentExtent: stripLoader.item?.logicalExtent ?? 0
    readonly property real stripContentExtent: stripLoader.item?.contentExtent ?? 0
    readonly property var flickableRef: flickable
    readonly property var activeWorkspace: {
        const revision = workspaceRevision;
        return mainInstance?.resolveWorkspaceForScreen(screenName) ?? null;
    }
    readonly property string activeWorkspaceToken: mainInstance?.workspaceToken(activeWorkspace) ?? ""
    readonly property string activeWorkspaceIdText: {
        if (!activeWorkspace)
            return "";
        if (activeWorkspace.idx !== undefined && activeWorkspace.idx !== null && String(activeWorkspace.idx) !== "")
            return String(activeWorkspace.idx);
        if (activeWorkspace.id !== undefined && activeWorkspace.id !== null && String(activeWorkspace.id) !== "")
            return String(activeWorkspace.id);
        return "";
    }
    readonly property string activeWorkspaceNameText: String(activeWorkspace?.name || "").trim()
    readonly property string workspaceIndicatorText: {
        if (!activeWorkspace)
            return "";
        if (workspaceIndicatorLabelMode === "name")
            return activeWorkspaceNameText || activeWorkspaceIdText;
        return activeWorkspaceIdText;
    }
    readonly property bool showWorkspaceIndicator: workspaceIndicatorEnabled && workspaceIndicatorText !== ""
    readonly property real workspaceIndicatorPointSize: workspaceIndicatorFontSize > 0 ? workspaceIndicatorFontSize : Math.max(Style.fontSizeXS, Math.round(barFontSize * 0.85))
    readonly property bool indicatorBeforeStrip: workspaceIndicatorPosition !== "after"
    readonly property string workspaceIndicatorFamily: workspaceIndicatorFontFamily || Settings.data.ui.fontFixed
    readonly property real contentSpacing: showWorkspaceIndicator && hasWindow ? workspaceIndicatorSpacing : 0
    readonly property bool hasContent: hasWindow || showWorkspaceIndicator
    readonly property real stripImplicitWidth: hasWindow ? contentWidth : 0
    readonly property real stripImplicitHeight: hasWindow ? contentHeight : 0
    readonly property real layoutInnerWidth: isVertical ? Math.max(stripImplicitWidth, workspaceLabelMeasure.implicitWidth) : (stripImplicitWidth + (showWorkspaceIndicator ? workspaceLabelMeasure.implicitWidth + contentSpacing : 0))
    readonly property real layoutInnerHeight: isVertical ? (stripImplicitHeight + (showWorkspaceIndicator ? workspaceLabelMeasure.implicitHeight + contentSpacing : 0)) : Math.max(stripImplicitHeight, workspaceLabelMeasure.implicitHeight)
    readonly property real layoutImplicitWidth: layoutInnerWidth + workspaceIndicatorPadding * 2
    readonly property real layoutImplicitHeight: layoutInnerHeight + workspaceIndicatorPadding * 2
    readonly property real workspaceSlideDistance: Math.max(Style.marginXL, Math.round(barFontSize * 1.4))
    readonly property bool useFixedWidgetSize: widgetSizeMode === "fixed"
    readonly property real scaledFixedWidgetExtent: Math.round(fixedWidgetSize * Style.uiScaleRatio)

    readonly property real maxWidgetExtent: {
        if (!screen || maxWidgetWidthPercent <= 0)
            return 0;

        const barFloating = Settings.data.bar.barType === "floating";
        const margin = barFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        const available = isVertical ? (screen.height - margin * 2) : (screen.width - margin * 2);
        return Math.round(available * (maxWidgetWidthPercent / 100));
    }
    readonly property real fixedWidgetExtent: {
        if (!screen)
            return 0;

        const barFloating = Settings.data.bar.barType === "floating";
        const margin = barFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        const available = isVertical ? (screen.height - margin * 2) : (screen.width - margin * 2);
        return Math.max(0, Math.min(scaledFixedWidgetExtent, available));
    }

    readonly property real viewportExtent: {
        if (logicalContentExtent <= 0)
            return 0;
        if (useFixedWidgetSize && fixedWidgetExtent > 0)
            return fixedWidgetExtent;
        if (maxWidgetExtent > 0)
            return Math.min(logicalContentExtent, maxWidgetExtent);
        return logicalContentExtent;
    }

    readonly property bool hasWindow: combinedModel.length > 0
    readonly property real logicalViewportExtent: isVertical ? flickable.height : flickable.width
    readonly property real minScrollOffset: hasWindow ? paintOverflowInset : 0
    readonly property real maxScrollOffset: {
        const totalExtent = stripContentExtent;
        const viewport = logicalViewportExtent;
        if (totalExtent <= 0 || viewport <= 0)
            return minScrollOffset;
        return Math.max(minScrollOffset, totalExtent - viewport - paintOverflowInset);
    }
    readonly property real logicalScrollOffset: {
        const rawOffset = isVertical ? flickable.contentY : flickable.contentX;
        return Math.max(0, rawOffset - minScrollOffset);
    }
    readonly property real logicalOverflowRange: Math.max(0, logicalContentExtent - logicalViewportExtent)
    readonly property bool showLeadingFade: logicalScrollOffset > 0.5
    readonly property bool showTrailingFade: (logicalScrollOffset + logicalViewportExtent) < (logicalContentExtent - 0.5)
    readonly property bool useEdgeFadeMask: edgeFadeEnabled && edgeFadeSize > 0 && (showLeadingFade || showTrailingFade)
    readonly property real contentWidth: isVertical ? crossExtent : Math.max(crossExtent, viewportExtent)
    readonly property real contentHeight: isVertical ? Math.max(crossExtent, viewportExtent) : crossExtent
    readonly property color capsuleBaseColor: Style.capsuleColor
    readonly property real indicatorAnchorInset: 1

    property var combinedModel: []
    property string combinedSignature: ""
    property string hoveredEntryKey: ""
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property string selectedEntryKey: ""
    property string selectedAppId: ""
    property real focusedIndicatorOffset: 0
    property real focusedIndicatorLength: 0
    property bool focusedIndicatorVisible: false
    property real animatedIndicatorOffset: 0
    property real animatedIndicatorLength: 0
    property var contextMenuModel: []
    readonly property bool focusedIndicatorInView: {
        if (!focusedIndicatorVisible)
            return false;
        if (isVertical) {
            const viewY = animatedIndicatorOffset - flickable.contentY;
            return (viewY + animatedIndicatorLength) > 0 && viewY < flickable.height;
        } else {
            const viewX = animatedIndicatorOffset - flickable.contentX;
            return (viewX + animatedIndicatorLength) > 0 && viewX < flickable.width;
        }
    }
    readonly property real edgeFadeOpacityRatio: Math.max(0, Math.min(1, edgeFadeOpacity))

    onFocusedIndicatorOffsetChanged: animatedIndicatorOffset = focusedIndicatorOffset
    onFocusedIndicatorLengthChanged: animatedIndicatorLength = focusedIndicatorLength
    onShowSlotsChanged: {
        if (showSlots)
            return;

        hoveredEntryKey = "";
        if (dragSourceIndex !== -1 || dragTargetIndex !== -1)
            completeDragReorder();
    }

    Behavior on animatedIndicatorOffset {
        enabled: focusedIndicatorVisible
        NumberAnimation {
            duration: root.focusLineAnimationMs
            easing.type: Easing.OutCubic
        }
    }

    Behavior on animatedIndicatorLength {
        enabled: focusedIndicatorVisible
        NumberAnimation {
            duration: root.focusLineAnimationMs
            easing.type: Easing.OutCubic
        }
    }

    function debugLog(message) {
        if (debugLogging)
            Logger.d("Scrollbar", message);
    }

    function scrollByWheelDelta(delta) {
        if (!enableScrollWheel || !hasWindow)
            return false;

        const step = delta / 120 * effectiveSlotLength;
        if (isVertical) {
            flickable.contentY = clampScrollOffset(flickable.contentY - step);
        } else {
            flickable.contentX = clampScrollOffset(flickable.contentX - step);
        }

        return true;
    }

    function clearContextSelection() {
        selectedEntryKey = "";
        selectedAppId = "";
    }

    function widgetSettingsMenuItem() {
        return {
            "label": I18n.tr("actions.widget-settings"),
            "action": "widget-settings",
            "icon": "settings"
        };
    }

    function desktopEntryActionsForApp(appId) {
        if (!appId)
            return [];

        try {
            if (typeof DesktopEntries === "undefined")
                return [];

            const entry = DesktopEntries.heuristicLookup ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId?.(appId);
            if (!entry || !entry.actions || entry.actions.length === 0)
                return [];

            return entry.actions.map(function (desktopAction, index) {
                return {
                    "label": desktopAction.name,
                    "action": "desktop-action-" + index,
                    "icon": "chevron-right",
                    "desktopAction": desktopAction
                };
            });
        } catch (error) {
            debugLog("desktopEntryActionsForApp failed: " + error);
            return [];
        }
    }

    function openWidgetContextMenu(anchorItem) {
        clearContextSelection();
        contextMenuModel = [widgetSettingsMenuItem()];
        PanelService.showContextMenu(contextMenu, root, root.screen, anchorItem ?? root);
    }

    function openSlotContextMenu(anchorItem, entryData) {
        const model = [];
        const entryKey = entryData?.entryKey ?? "";
        const appId = entryData?.appId ?? "";

        selectedEntryKey = entryKey;
        selectedAppId = appId;

        if (entryKey) {
            model.push({
                "label": I18n.tr("common.focus"),
                "action": "focus",
                "icon": "eye"
            });
            model.push({
                "label": I18n.tr("common.close"),
                "action": "close",
                "icon": "x"
            });
            desktopEntryActionsForApp(appId).forEach(function (item) {
                model.push(item);
            });
        }

        model.push(widgetSettingsMenuItem());
        contextMenuModel = model;
        PanelService.showContextMenu(contextMenu, root, root.screen, anchorItem ?? root);
    }

    visible: hasContent
    implicitWidth: hasContent ? layoutImplicitWidth : 0
    implicitHeight: hasContent ? layoutImplicitHeight : 0

    function filteredSignature(entries) {
        return (entries || []).map(function (entry) {
            return entry.entryKey;
        }).join("||");
    }

    function rebuildCombinedModel(reason) {
        const nextEntries = mainInstance ? (mainInstance.getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces) || []) : [];
        const nextSignature = filteredSignature(nextEntries);
        const structureChanged = nextSignature !== combinedSignature;

        combinedModel = nextEntries;
        combinedSignature = nextSignature;
        debugLog("rebuildCombinedModel(" + (reason || "unknown") + "): windows=" + combinedModel.length + " changed=" + structureChanged);

        if (structureChanged) {
            scheduleCenterActive(true);
        } else {
            Qt.callLater(updateFocusedIndicator);
        }
    }

    function indexOfEntry(entryKey) {
        for (let i = 0; i < combinedModel.length; i++) {
            if (combinedModel[i]?.entryKey === entryKey)
                return i;
        }
        return -1;
    }

    function getDelegateItem(index) {
        if (index < 0)
            return null;
        return stripLoader.item?.delegateItemAt(index) ?? null;
    }

    function indicatorCrossOffset(lineThickness) {
        const thickness = Math.max(1, Math.round(lineThickness || 1));
        const available = isVertical ? contentWidth : contentHeight;
        const maxOffset = Math.max(0, Math.round(available - thickness));
        if (trackLinePosition === "center")
            return Math.round(maxOffset / 2);
        if (trackLinePosition === "start")
            return Math.min(indicatorAnchorInset, maxOffset);
        return Math.max(0, maxOffset - indicatorAnchorInset);
    }

    function indicatorGeometryForIndex(index) {
        const item = getDelegateItem(index);
        const container = stripLoader.item;
        if (!item || !container)
            return null;

        const point = item.mapToItem(container, 0, 0);

        if (isVertical) {
            const start = Math.round(point.y);
            const length = Math.max(1, Math.round(item.height));
            return {
                "offset": start,
                "length": length
            };
        }

        const start = Math.round(point.x);
        const length = Math.max(1, Math.round(item.width));
        return {
            "offset": start,
            "length": length
        };
    }

    function centerEntryAt(index) {
        if (index < 0 || index >= combinedModel.length)
            return false;

        const item = getDelegateItem(index);
        const container = stripLoader.item;
        if (!item || !container)
            return false;

        const centerPoint = item.mapToItem(container, item.width / 2, item.height / 2);
        if (isVertical) {
            const desiredY = centerPoint.y - flickable.height / 2;
            flickable.contentY = clampScrollOffset(desiredY);
        } else {
            const desiredX = centerPoint.x - flickable.width / 2;
            flickable.contentX = clampScrollOffset(desiredX);
        }
        return true;
    }

    function scheduleCenterActive(always) {
        if (!activeEntryKey)
            return;
        if (!always && !centerFocusedWindow)
            return;
        centerRetryTimer.attempts = 0;
        centerRetryTimer.start();
    }

    function tryCenterActive() {
        if (!activeEntryKey) {
            centerRetryTimer.stop();
            return;
        }
        const index = indexOfEntry(activeEntryKey);
        if (centerEntryAt(index)) {
            Qt.callLater(updateFocusedIndicator);
            centerRetryTimer.stop();
            return;
        }
        centerRetryTimer.attempts += 1;
        if (centerRetryTimer.attempts < centerRetryTimer.maxAttempts) {
            centerRetryTimer.start();
        } else {
            Qt.callLater(updateFocusedIndicator);
        }
    }

    function updateFocusedIndicator() {
        if (!showFocusLine || !activeEntryKey) {
            focusedIndicatorVisible = false;
            focusedIndicatorLength = 0;
            return;
        }

        const geometry = indicatorGeometryForIndex(indexOfEntry(activeEntryKey));
        if (!geometry) {
            focusedIndicatorVisible = false;
            focusedIndicatorLength = 0;
            return;
        }

        focusedIndicatorOffset = geometry.offset;
        focusedIndicatorLength = geometry.length;

        focusedIndicatorVisible = focusedIndicatorLength > 0;
    }

    function updateDragTargetForItem(sourceIndex, dragItem) {
        if (!supportsLiveReorder || !dragItem || sourceIndex < 0 || sourceIndex >= combinedModel.length) {
            dragTargetIndex = -1;
            return;
        }

        const container = stripLoader.item;
        if (!container) {
            dragTargetIndex = -1;
            return;
        }

        const dragCenter = dragItem.mapToItem(container, dragItem.width / 2, dragItem.height / 2);
        const dragAxis = isVertical ? dragCenter.y : dragCenter.x;
        let nextTargetIndex = -1;
        let closestDistance = Number.POSITIVE_INFINITY;

        for (let i = 0; i < combinedModel.length; i++) {
            if (i === sourceIndex)
                continue;

            const candidateItem = getDelegateItem(i);
            if (!candidateItem)
                continue;

            const candidateCenter = candidateItem.mapToItem(container, candidateItem.width / 2, candidateItem.height / 2);
            const candidateAxis = isVertical ? candidateCenter.y : candidateCenter.x;
            const distance = Math.abs(candidateAxis - dragAxis);
            if (distance < closestDistance) {
                closestDistance = distance;
                nextTargetIndex = i;
            }
        }

        dragTargetIndex = nextTargetIndex;
    }

    function completeDragReorder() {
        const fromIndex = dragSourceIndex;
        const toIndex = dragTargetIndex;

        dragSourceIndex = -1;
        dragTargetIndex = -1;

        if (!supportsLiveReorder || fromIndex < 0 || toIndex < 0 || fromIndex === toIndex)
            return;

        const fromItem = combinedModel[fromIndex];
        const toItem = combinedModel[toIndex];
        if (!fromItem || !toItem)
            return;

        debugLog("Reorder requested " + fromItem.entryKey + " -> " + toItem.entryKey);
        mainInstance?.reorderFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces, fromItem.entryKey, toItem.entryKey);
    }

    onMainInstanceChanged: rebuildCombinedModel("mainInstanceChanged")
    onStructureRevisionChanged: rebuildCombinedModel("structureRevision")
    onOnlySameOutputChanged: rebuildCombinedModel("onlySameOutputChanged")
    onOnlyActiveWorkspacesChanged: rebuildCombinedModel("onlyActiveWorkspacesChanged")
    onScreenChanged: rebuildCombinedModel("screenChanged")
    onActiveEntryKeyChanged: {
        scheduleCenterActive(false);
    }
    onActiveWorkspaceTokenChanged: {
        if (!workspaceStateInitialized) {
            previousWorkspaceToken = activeWorkspaceToken;
            previousWorkspaceIndex = workspaceNumericIndex(activeWorkspace);
            workspaceStateInitialized = true;
            return;
        }

        if (activeWorkspaceToken === previousWorkspaceToken || activeWorkspaceToken === "")
            return;

        if (workspaceAnimationEnabled)
            triggerWorkspaceSlide(activeWorkspace);

        previousWorkspaceToken = activeWorkspaceToken;
        previousWorkspaceIndex = workspaceNumericIndex(activeWorkspace);
    }
    onStripContentExtentChanged: Qt.callLater(clampScrollPosition)
    onPaintOverflowInsetChanged: Qt.callLater(clampScrollPosition)
    onContentWidthChanged: Qt.callLater(clampScrollPosition)
    onContentHeightChanged: Qt.callLater(clampScrollPosition)
    onLiveRevisionChanged: Qt.callLater(updateFocusedIndicator)
    onShowFocusLineChanged: Qt.callLater(updateFocusedIndicator)
    onTrackLineThicknessChanged: Qt.callLater(updateFocusedIndicator)

    Component.onCompleted: {
        rebuildCombinedModel("init");
        previousWorkspaceToken = activeWorkspaceToken;
        previousWorkspaceIndex = workspaceNumericIndex(activeWorkspace);
        workspaceStateInitialized = true;
    }

    property real workspaceSlideOffset: 0
    property string previousWorkspaceToken: ""
    property real previousWorkspaceIndex: NaN
    property bool workspaceStateInitialized: false
    property bool workspaceSlideBackAnimationActive: false

    Behavior on workspaceSlideOffset {
        enabled: workspaceSlideBackAnimationActive
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    function workspaceNumericIndex(workspace) {
        const numericIndex = Number(workspace?.idx);
        return Number.isFinite(numericIndex) ? numericIndex : NaN;
    }

    function triggerWorkspaceSlide(workspace) {
        const nextIndex = workspaceNumericIndex(workspace);
        let direction = 1;

        if (Number.isFinite(previousWorkspaceIndex) && Number.isFinite(nextIndex) && nextIndex !== previousWorkspaceIndex)
            direction = nextIndex > previousWorkspaceIndex ? 1 : -1;

        workspaceSlideResetTimer.stop();
        workspaceSlideCleanupTimer.stop();
        workspaceSlideBackAnimationActive = false;
        workspaceSlideOffset = direction * workspaceSlideDistance;
        workspaceSlideResetTimer.restart();
    }

    Timer {
        id: scrollBackTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (root.activeEntryKey)
                root.centerEntryAt(root.indexOfEntry(root.activeEntryKey));
        }
    }

    Timer {
        id: workspaceSlideResetTimer
        interval: 1
        repeat: false
        onTriggered: {
            root.workspaceSlideBackAnimationActive = true;
            root.workspaceSlideOffset = 0;
            workspaceSlideCleanupTimer.restart();
        }
    }

    Timer {
        id: workspaceSlideCleanupTimer
        interval: 220
        repeat: false
        onTriggered: {
            root.workspaceSlideBackAnimationActive = false;
        }
    }

    WheelHandler {
        enabled: root.enableScrollWheel && root.hasWindow
        target: null
        onActiveChanged: root.debugLog("WheelHandler active=" + active)
        onWheel: event => {
            root.debugLog("WheelHandler wheel delta=" + event.angleDelta.y + " contentX=" + flickable.contentX + " contentWidth=" + flickable.contentWidth + " width=" + flickable.width);
            event.accepted = root.scrollByWheelDelta(event.angleDelta.y);
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: root.contextMenuModel

        onTriggered: (action, item) => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);
            if (action === "focus" && root.selectedEntryKey) {
                root.mainInstance?.focusEntry(root.selectedEntryKey);
            } else if (action === "close" && root.selectedEntryKey) {
                root.mainInstance?.closeEntry(root.selectedEntryKey);
            } else if (action === "widget-settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            } else if (action.startsWith("desktop-action-") && item?.desktopAction) {
                if (item.desktopAction.command && item.desktopAction.command.length > 0) {
                    Quickshell.execDetached(item.desktopAction.command);
                } else if (item.desktopAction.execute) {
                    item.desktopAction.execute();
                }
            }

            clearContextSelection();
        }
    }

    MouseArea {
        id: backgroundMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: false

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.openWidgetContextMenu(root);
                mouse.accepted = true;
            }
        }

        onWheel: wheel => {
            root.debugLog("background onWheel delta=" + wheel.angleDelta.y);
            wheel.accepted = root.scrollByWheelDelta(wheel.angleDelta.y);
        }
    }

    Timer {
        id: centerRetryTimer
        interval: 16
        repeat: false
        property int attempts: 0
        readonly property int maxAttempts: 12
        onTriggered: tryCenterActive()
    }

    Component {
        id: entryDelegateComponent

        WindowSlot {
            barRoot: root

            contextMenu: contextMenu
        }
    }

    Component {
        id: horizontalStripComponent

        Item {
            readonly property real logicalExtent: rowLayout.implicitWidth
            readonly property real contentExtent: logicalExtent + root.paintOverflowInset * 2

            width: contentExtent
            height: root.crossExtent
            z: 0

            function delegateItemAt(index) {
                for (let i = 0; i < rowLayout.children.length; i++) {
                    const child = rowLayout.children[i];
                    if (child?.objectName === "scrollbarDelegateRoot" && child.index === index)
                        return child;
                }
                return null;
            }

            RowLayout {
                id: rowLayout
                x: root.paintOverflowInset
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.slotSpacing

                Repeater {
                    model: root.combinedModel
                    delegate: entryDelegateComponent
                }
            }
        }
    }

    Component {
        id: verticalStripComponent

        Item {
            readonly property real logicalExtent: columnLayout.implicitHeight
            readonly property real contentExtent: logicalExtent + root.paintOverflowInset * 2

            width: root.crossExtent
            height: contentExtent

            function delegateItemAt(index) {
                for (let i = 0; i < columnLayout.children.length; i++) {
                    const child = columnLayout.children[i];
                    if (child?.objectName === "scrollbarDelegateRoot" && child.index === index)
                        return child;
                }
                return null;
            }

            ColumnLayout {
                id: columnLayout
                y: root.paintOverflowInset
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.slotSpacing

                Repeater {
                    model: root.combinedModel
                    delegate: entryDelegateComponent
                }
            }
        }
    }

    NText {
        id: workspaceLabelMeasure
        visible: false
        text: root.workspaceIndicatorText
        family: root.workspaceIndicatorFamily
        pointSize: root.workspaceIndicatorPointSize
    }

    Item {
        id: widgetContent
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.layoutImplicitWidth
        height: root.layoutImplicitHeight
        z: 1

        transform: Translate {
            x: root.workspaceAnimationEnabled && root.workspaceAnimationAxis === "horizontal" ? root.workspaceSlideOffset : 0
            y: root.workspaceAnimationEnabled && root.workspaceAnimationAxis === "vertical" ? root.workspaceSlideOffset : 0
        }

        NText {
            id: leadingWorkspaceLabel
            visible: root.showWorkspaceIndicator && root.indicatorBeforeStrip
            text: root.workspaceIndicatorText
            color: root.workspaceIndicatorTextColor
            opacity: root.workspaceIndicatorOpacity
            family: root.workspaceIndicatorFamily
            pointSize: root.workspaceIndicatorPointSize
            z: 20
            x: root.isVertical ? Style.pixelAlignCenter(widgetContent.width, width) : root.workspaceIndicatorPadding
            y: root.isVertical ? root.workspaceIndicatorPadding : Style.pixelAlignCenter(widgetContent.height, height)
        }

        Item {
            id: stripContainer
            visible: root.hasWindow
            width: root.stripImplicitWidth
            height: root.stripImplicitHeight
            x: root.isVertical ? Style.pixelAlignCenter(widgetContent.width, width) : (root.showWorkspaceIndicator && root.indicatorBeforeStrip ? root.workspaceIndicatorPadding + workspaceLabelMeasure.implicitWidth + root.contentSpacing : root.workspaceIndicatorPadding)
            y: root.isVertical ? (root.showWorkspaceIndicator && root.indicatorBeforeStrip ? root.workspaceIndicatorPadding + workspaceLabelMeasure.implicitHeight + root.contentSpacing : root.workspaceIndicatorPadding) : Style.pixelAlignCenter(widgetContent.height, height)

            Item {
                id: visualCapsule
                anchors.fill: parent

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.effect: MultiEffect {
                        maskEnabled: root.useEdgeFadeMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        maskSource: fadeMask
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.capsuleBaseColor
                        radius: Style.radiusL * root.radiusScale
                        border.color: Style.capsuleBorderColor
                        border.width: Style.capsuleBorderWidth
                    }

                    Rectangle {
                        visible: root.backgroundEnabled
                        anchors.fill: parent
                        color: root.backgroundColor
                        radius: Style.radiusL * root.radiusScale
                    }

                    Item {
                        anchors.fill: parent

                        Flickable {
                            id: flickable
                            anchors.fill: parent
                            clip: true
                            interactive: false
                            boundsBehavior: Flickable.StopAtBounds
                            contentWidth: root.isVertical ? width : root.stripContentExtent
                            contentHeight: root.isVertical ? root.stripContentExtent : height

                            Behavior on contentX {
                                enabled: root.centerAnimationMs > 0
                                NumberAnimation {
                                    duration: root.centerAnimationMs
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Behavior on contentY {
                                enabled: root.centerAnimationMs > 0
                                NumberAnimation {
                                    duration: root.centerAnimationMs
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Loader {
                                id: stripLoader
                                sourceComponent: root.isVertical ? verticalStripComponent : horizontalStripComponent
                            }
                        }

                        TrackOverlay {
                            barRoot: root
                        }
                    }
                }

                Rectangle {
                    id: fadeMask
                    readonly property real maskExtent: root.isVertical ? height : width
                    readonly property real viewportExtent: root.logicalViewportExtent
                    readonly property real requestedNormalizedFade: viewportExtent > 0 ? Math.min(0.49, root.edgeFadeSize / viewportExtent) : 0
                    readonly property real normalizedLeadingFade: root.showLeadingFade ? requestedNormalizedFade : 0
                    readonly property real normalizedTrailingFade: root.showTrailingFade ? requestedNormalizedFade : 0
                    readonly property real normalizedTotalFade: normalizedLeadingFade + normalizedTrailingFade
                    readonly property real fadeScale: normalizedTotalFade > 0.98 ? (0.98 / normalizedTotalFade) : 1.0
                    readonly property real leadingFadeExtent: normalizedLeadingFade * fadeScale
                    readonly property real trailingFadeExtent: normalizedTrailingFade * fadeScale
                    readonly property real leadingFadeMidpoint: leadingFadeExtent * 0.4
                    readonly property real trailingFadeMidpoint: 1.0 - trailingFadeExtent * 0.4

                    width: parent.width
                    height: parent.height
                    radius: Style.radiusL * root.radiusScale
                    color: "white"
                    visible: true
                    opacity: 0
                    layer.enabled: true
                    layer.smooth: true

                    gradient: Gradient {
                        orientation: root.isVertical ? Gradient.Vertical : Gradient.Horizontal

                        GradientStop {
                            position: 0.0
                            color: root.showLeadingFade ? "transparent" : "white"
                        }
                        GradientStop {
                            position: fadeMask.leadingFadeMidpoint
                            color: root.showLeadingFade ? Qt.rgba(1, 1, 1, root.edgeFadeOpacityRatio) : "white"
                        }
                        GradientStop {
                            position: fadeMask.leadingFadeExtent
                            color: "white"
                        }
                        GradientStop {
                            position: 1.0 - fadeMask.trailingFadeExtent
                            color: "white"
                        }
                        GradientStop {
                            position: fadeMask.trailingFadeMidpoint
                            color: root.showTrailingFade ? Qt.rgba(1, 1, 1, root.edgeFadeOpacityRatio) : "white"
                        }
                        GradientStop {
                            position: 1.0
                            color: root.showTrailingFade ? "transparent" : "white"
                        }
                    }
                }
            }
        }

        NText {
            id: trailingWorkspaceLabel
            visible: root.showWorkspaceIndicator && !root.indicatorBeforeStrip
            text: root.workspaceIndicatorText
            color: root.workspaceIndicatorTextColor
            opacity: root.workspaceIndicatorOpacity
            family: root.workspaceIndicatorFamily
            pointSize: root.workspaceIndicatorPointSize
            z: 20
            x: root.isVertical ? Style.pixelAlignCenter(widgetContent.width, width) : (root.hasWindow ? stripContainer.x + stripContainer.width + root.contentSpacing : root.workspaceIndicatorPadding)
            y: root.isVertical ? (root.hasWindow ? stripContainer.y + stripContainer.height + root.contentSpacing : root.workspaceIndicatorPadding) : Style.pixelAlignCenter(widgetContent.height, height)
        }
    }
}
