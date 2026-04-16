import QtQuick
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

    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance ?? null

    function settingValue(groupKey, nestedKey, legacyKey, fallbackValue) {
        const configGroup = cfg ? cfg[groupKey] : undefined;
        const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
        if (nestedConfig !== undefined)
            return nestedConfig;

        const legacyConfig = cfg ? cfg[legacyKey] : undefined;
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
    readonly property int maxWidgetWidthPercent: settingValue("layout", "maxWidgetWidth", "maxWidgetWidth", 40)
    readonly property real baseSlotLength: settingValue("layout", "slotWidth", "slotWidth", 112)
    readonly property real slotCapsuleScale: Math.max(0.3, settingValue("layout", "slotCapsuleScale", "slotCapsuleScale", 1.0))
    readonly property bool clipToBarBounds: settingValue("layout", "clipToBarBounds", "clipToBarBounds", true)
    readonly property bool showTitle: !isVertical && settingValue("title", "showTitle", "showTitle", true)
    readonly property real iconScale: settingValue("icons", "iconScale", "iconScale", 0.8)
    readonly property real edgeFadeSize: Math.max(0, Math.round(settingValue("edgeFade", "size", "edgeFadeSize", 18) * Style.uiScaleRatio))
    readonly property real edgeFadeMidpoint: Math.max(0.05, Math.min(0.95, settingValue("edgeFade", "midpoint", "edgeFadeMidpoint", 0.45)))
    readonly property real edgeFadeMidOpacity: Math.max(0, Math.min(1, settingValue("edgeFade", "midOpacity", "edgeFadeMidOpacity", 40) / 100))
    readonly property bool showTrackLine: settingValue("indicators", "showTrackLine", "showTrackLine", true)
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
    readonly property string iconTintColorKey: settingValue("icons", "iconTintColor", "iconTintColor", "none")
    readonly property real iconTintOpacity: Math.max(0, Math.min(1, settingValue("icons", "iconTintOpacity", "iconTintOpacity", 100) / 100))
    readonly property string backgroundColorKey: settingValue("background", "color", "backgroundColor", "none")
    readonly property real backgroundOpacity: Math.max(0, Math.min(1, settingValue("background", "opacity", "backgroundOpacity", 0) / 100))
    readonly property color iconTintColor: iconTintColorKey !== "none" ? Color.resolveColorKey(iconTintColorKey) : "transparent"
    readonly property bool iconTintEnabled: iconTintColorKey !== "none"
    readonly property bool backgroundEnabled: backgroundColorKey !== "none" && backgroundOpacity > 0
    readonly property color backgroundBaseColor: backgroundColorKey !== "none" ? Color.resolveColorKey(backgroundColorKey) : "transparent"
    readonly property color backgroundColor: backgroundEnabled ? Qt.alpha(backgroundBaseColor, backgroundOpacity) : "transparent"
    readonly property color fadeBaseColor: backgroundEnabled ? backgroundColor : Color.mSurface
    readonly property color focusedFillColor: Color.resolveColorKey(focusedFillColorKey)
    readonly property color focusedBorderColor: Color.resolveColorKey(focusedBorderColorKey)
    readonly property color focusedTextColor: Color.resolveColorKey(focusedTextColorKey)
    readonly property color hoverFillColor: Color.resolveColorKey(hoverFillColorKey)
    readonly property color hoverBorderColor: Color.resolveColorKey(hoverBorderColorKey)
    readonly property color hoverTextColor: Color.resolveColorKey(hoverTextColorKey)
    readonly property color unfocusedFillColor: Color.resolveColorKey(unfocusedFillColorKey)
    readonly property color unfocusedBorderColor: Color.resolveColorKey(unfocusedBorderColorKey)
    readonly property color unfocusedTextColor: Color.resolveColorKey(unfocusedTextColorKey)

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
    readonly property int effectiveSlotLength: isVertical ? slotLength : (showTitle ? slotLength : Math.round(itemSize + 2 * Math.max(Style.marginM, Style.marginS * slotCapsuleScale)))
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
    readonly property real slotCrossExtent: clipToBarBounds ? Math.min(crossExtent, scaledCapsuleHeight) : scaledCapsuleHeight
    readonly property real trackThickness: Math.max(1, Math.round(Style.borderS))
    readonly property int itemSize: Style.toOdd(slotCrossExtent * Math.max(0.1, iconScale))
    readonly property var liveEntriesByKey: mainInstance?.liveEntriesByKey ?? ({})
    readonly property string activeEntryKey: mainInstance?.activeEntryKey ?? ""
    readonly property int structureRevision: mainInstance?.structureRevision ?? 0
    readonly property int liveRevision: mainInstance?.liveRevision ?? 0
    readonly property real contentExtent: stripLoader.item?.contentExtent ?? 0
    readonly property var flickableRef: flickable

    readonly property real maxWidgetExtent: {
        if (!screen || maxWidgetWidthPercent <= 0)
            return 0;

        const barFloating = Settings.data.bar.barType === "floating";
        const margin = barFloating ? Math.ceil(Settings.data.bar.marginHorizontal) : 0;
        const available = isVertical ? (screen.height - margin * 2) : (screen.width - margin * 2);
        return Math.round(available * (maxWidgetWidthPercent / 100));
    }

    readonly property real viewportExtent: {
        if (contentExtent <= 0)
            return 0;
        if (maxWidgetExtent > 0)
            return Math.min(contentExtent, maxWidgetExtent);
        return contentExtent;
    }

    readonly property bool hasWindow: combinedModel.length > 0
    readonly property bool showLeadingFade: isVertical ? flickable.contentY > 0.5 : flickable.contentX > 0.5
    readonly property bool showTrailingFade: isVertical ? (flickable.contentY + flickable.height) < (flickable.contentHeight - 0.5) : (flickable.contentX + flickable.width) < (flickable.contentWidth - 0.5)
    readonly property real contentWidth: isVertical ? crossExtent : Math.max(crossExtent, viewportExtent)
    readonly property real contentHeight: isVertical ? Math.max(crossExtent, viewportExtent) : crossExtent
    readonly property color capsuleBaseColor: rootHoverHandler.hovered ? Color.mHover : Style.capsuleColor

    property var combinedModel: []
    property string combinedSignature: ""
    property string hoveredEntryKey: ""
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property string selectedEntryKey: ""
    property real focusedIndicatorOffset: 0
    property real focusedIndicatorLength: 0
    property bool focusedIndicatorVisible: false
    property real animatedIndicatorOffset: 0
    property real animatedIndicatorLength: 0
    readonly property var contextMenuModel: [
        {
            "label": pluginApi?.tr("menu.settings"),
            "action": "settings",
            "icon": "settings",
            "visible": true
        }
    ]
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

    onFocusedIndicatorOffsetChanged: animatedIndicatorOffset = focusedIndicatorOffset
    onFocusedIndicatorLengthChanged: animatedIndicatorLength = focusedIndicatorLength

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

    visible: hasWindow
    implicitWidth: hasWindow ? contentWidth : 0
    implicitHeight: hasWindow ? contentHeight : 0

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
            const maxY = Math.max(0, flickable.contentHeight - flickable.height);
            flickable.contentY = Math.max(0, Math.min(maxY, desiredY));
        } else {
            const desiredX = centerPoint.x - flickable.width / 2;
            const maxX = Math.max(0, flickable.contentWidth - flickable.width);
            flickable.contentX = Math.max(0, Math.min(maxX, desiredX));
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

        const item = getDelegateItem(indexOfEntry(activeEntryKey));
        const container = stripLoader.item;
        if (!item || !container) {
            focusedIndicatorVisible = false;
            focusedIndicatorLength = 0;
            return;
        }

        const point = item.mapToItem(container, 0, 0);
        const inset = Math.max(2, Math.round(Style.marginXS));

        if (isVertical) {
            focusedIndicatorOffset = Math.round(point.y + inset);
            focusedIndicatorLength = Math.max(0, Math.round(item.height - inset * 2));
        } else {
            focusedIndicatorOffset = Math.round(point.x + inset);
            focusedIndicatorLength = Math.max(0, Math.round(item.width - inset * 2));
        }

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
    onLiveRevisionChanged: Qt.callLater(updateFocusedIndicator)
    onShowFocusLineChanged: Qt.callLater(updateFocusedIndicator)

    Component.onCompleted: {
        rebuildCombinedModel("init");
    }

    HoverHandler {
        id: rootHoverHandler

        onHoveredChanged: {
            root.debugLog("HoverHandler hovered=" + hovered);
            if (!hovered && root.activeEntryKey) {
                scrollBackTimer.restart();
            } else {
                scrollBackTimer.stop();
            }
        }
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

    WheelHandler {
        enabled: root.enableScrollWheel && root.hasWindow
        target: null
        onActiveChanged: root.debugLog("WheelHandler active=" + active)
        onWheel: event => {
            root.debugLog("WheelHandler wheel delta=" + event.angleDelta.y + " contentX=" + flickable.contentX + " contentWidth=" + flickable.contentWidth + " width=" + flickable.width);
            const step = event.angleDelta.y / 120 * root.effectiveSlotLength;
            if (root.isVertical) {
                const maxY = Math.max(0, flickable.contentHeight - flickable.height);
                flickable.contentY = Math.max(0, Math.min(maxY, flickable.contentY - step));
            } else {
                const maxX = Math.max(0, flickable.contentWidth - flickable.width);
                flickable.contentX = Math.max(0, Math.min(maxX, flickable.contentX - step));
            }
            event.accepted = true;
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: root.contextMenuModel

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);
            selectedEntryKey = "";

            if (action === "settings")
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
        }
    }

    MouseArea {
        id: backgroundMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, root.screen);
                mouse.accepted = true;
            }
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
            readonly property real contentExtent: rowLayout.implicitWidth

            width: contentExtent
            height: root.crossExtent

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
                anchors.fill: parent
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
            readonly property real contentExtent: columnLayout.implicitHeight

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
                anchors.fill: parent
                spacing: root.slotSpacing

                Repeater {
                    model: root.combinedModel
                    delegate: entryDelegateComponent
                }
            }
        }
    }

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: root.capsuleBaseColor
        radius: Style.radiusL * root.radiusScale
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        Rectangle {
            visible: root.backgroundEnabled
            anchors.fill: parent
            color: root.backgroundColor
            radius: visualCapsule.radius
        }

        Item {
            anchors.fill: parent

            Flickable {
                id: flickable
                anchors.fill: parent
                clip: root.clipToBarBounds

                interactive: false
                boundsBehavior: Flickable.StopAtBounds
                contentWidth: root.isVertical ? width : root.contentExtent
                contentHeight: root.isVertical ? root.contentExtent : height

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

            EdgeFadeOverlay {
                barRoot: root
                leading: true
            }

            EdgeFadeOverlay {
                barRoot: root
                leading: false
            }
        }
    }
}
