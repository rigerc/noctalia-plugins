import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets

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

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property bool onlySameOutput: cfg.onlySameOutput ?? defaults.onlySameOutput ?? true
    readonly property bool onlyActiveWorkspaces: cfg.onlyActiveWorkspaces ?? defaults.onlyActiveWorkspaces ?? true
    readonly property bool enableReorder: cfg.enableReorder ?? defaults.enableReorder ?? true
    readonly property bool debugLogging: cfg.debugLogging ?? defaults.debugLogging ?? false
    readonly property int maxWidgetWidthPercent: cfg.maxWidgetWidth ?? defaults.maxWidgetWidth ?? 40
    readonly property real baseSlotLength: cfg.slotWidth ?? defaults.slotWidth ?? 112
    readonly property bool showTitle: !isVertical && (cfg.showTitle ?? defaults.showTitle ?? true)
    readonly property real iconScale: cfg.iconScale ?? defaults.iconScale ?? 0.8
    readonly property real edgeFadeSize: Math.max(0, Math.round((cfg.edgeFadeSize ?? defaults.edgeFadeSize ?? 18) * Style.uiScaleRatio))
    readonly property real edgeFadeMidpoint: Math.max(0.05, Math.min(0.95, cfg.edgeFadeMidpoint ?? defaults.edgeFadeMidpoint ?? 0.45))
    readonly property real edgeFadeMidOpacity: Math.max(0, Math.min(1, (cfg.edgeFadeMidOpacity ?? defaults.edgeFadeMidOpacity ?? 40) / 100))
    readonly property bool showTrackLine: cfg.showTrackLine ?? defaults.showTrackLine ?? true
    readonly property string accentColorKey: cfg.accentColor ?? defaults.accentColor ?? "primary"
    readonly property color accentColor: Color.resolveColorKey(accentColorKey)
    readonly property real inactiveOpacity: Math.max(0.05, Math.min(1, (cfg.inactiveOpacity ?? defaults.inactiveOpacity ?? 45) / 100))
    readonly property int slotSpacingUnits: cfg.slotSpacingUnits ?? defaults.slotSpacingUnits ?? 1
    readonly property real radiusScale: cfg.radiusScale ?? defaults.radiusScale ?? 1.0
    readonly property string hoverFillColorKey: cfg.hoverFillColor ?? defaults.hoverFillColor ?? "hover"
    readonly property string hoverBorderColorKey: cfg.hoverBorderColor ?? defaults.hoverBorderColor ?? "outline"
    readonly property string hoverTextColorKey: cfg.hoverTextColor ?? defaults.hoverTextColor ?? "on-hover"
    readonly property real hoverFillOpacity: Math.max(0, Math.min(1, (cfg.hoverFillOpacity ?? defaults.hoverFillOpacity ?? 55) / 100))
    readonly property real hoverScalePercent: Math.max(0, cfg.hoverScalePercent ?? defaults.hoverScalePercent ?? 2.5)
    readonly property int hoverTransitionDurationMs: Math.max(0, cfg.hoverTransitionDurationMs ?? defaults.hoverTransitionDurationMs ?? 120)
    readonly property real focusedFillOpacity: Math.max(0, Math.min(1, (cfg.focusedFillOpacity ?? defaults.focusedFillOpacity ?? 92) / 100))
    readonly property real unfocusedFillOpacity: Math.max(0, Math.min(1, (cfg.unfocusedFillOpacity ?? defaults.unfocusedFillOpacity ?? 8) / 100))
    readonly property real unfocusedBorderOpacity: Math.max(0, Math.min(1, (cfg.unfocusedBorderOpacity ?? defaults.unfocusedBorderOpacity ?? 45) / 100))
    readonly property bool showFocusedBorder: cfg.showFocusedBorder ?? defaults.showFocusedBorder ?? true
    readonly property real focusedBorderOpacity: Math.max(0, Math.min(1, (cfg.focusedBorderOpacity ?? defaults.focusedBorderOpacity ?? 100) / 100))
    readonly property bool showHoverBorder: cfg.showHoverBorder ?? defaults.showHoverBorder ?? true
    readonly property real hoverBorderOpacity: Math.max(0, Math.min(1, (cfg.hoverBorderOpacity ?? defaults.hoverBorderOpacity ?? 100) / 100))
    readonly property bool showUnfocusedBorder: cfg.showUnfocusedBorder ?? defaults.showUnfocusedBorder ?? true
    readonly property real trackOpacity: Math.max(0, Math.min(1, (cfg.trackOpacity ?? defaults.trackOpacity ?? 35) / 100))
    readonly property bool showFocusLine: cfg.showFocusLine ?? defaults.showFocusLine ?? true
    readonly property string focusLineColorKey: cfg.focusLineColor ?? defaults.focusLineColor ?? "secondary"
    readonly property color focusLineColor: Color.resolveColorKey(focusLineColorKey)
    readonly property real focusLineOpacity: Math.max(0, Math.min(1, (cfg.focusLineOpacity ?? defaults.focusLineOpacity ?? 96) / 100))
    readonly property int focusLineThickness: Math.max(1, cfg.focusLineThickness ?? defaults.focusLineThickness ?? 2)
    readonly property int focusLineAnimationMs: Math.max(0, cfg.focusLineAnimationMs ?? defaults.focusLineAnimationMs ?? 120)
    readonly property bool centerFocusedWindow: cfg.centerFocusedWindow ?? defaults.centerFocusedWindow ?? true
    readonly property int centerAnimationMs: Math.max(0, cfg.centerAnimationMs ?? defaults.centerAnimationMs ?? 200)
    readonly property bool supportsLiveReorder: enableReorder && (mainInstance?.supportsLiveReorder ?? false)

    readonly property int itemSize: Style.toOdd(capsuleHeight * Math.max(0.1, iconScale))
    readonly property int slotLength: Math.max(Math.round(baseSlotLength * Style.uiScaleRatio), Math.round(capsuleHeight * 1.4))
    readonly property real slotSpacing: Math.max(0, Math.round(slotSpacingUnits * Style.marginS))
    readonly property real crossExtent: capsuleHeight
    readonly property real trackThickness: Math.max(1, Math.round(Style.borderS))
    readonly property var liveEntriesByKey: mainInstance?.liveEntriesByKey ?? ({})
    readonly property string activeEntryKey: mainInstance?.activeEntryKey ?? ""
    readonly property int structureRevision: mainInstance?.structureRevision ?? 0
    readonly property int liveRevision: mainInstance?.liveRevision ?? 0
    readonly property real contentExtent: stripLoader.item?.contentExtent ?? 0

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

    property var combinedModel: []
    property string combinedSignature: ""
    property string hoveredEntryKey: ""
    property int dragSourceIndex: -1
    property int dragTargetIndex: -1
    property string selectedEntryKey: ""
    property real focusedIndicatorOffset: 0
    property real focusedIndicatorLength: 0
    property bool focusedIndicatorVisible: false

    function debugLog(message) {
        if (debugLogging)
            Logger.d("Scrollbar", message);
    }

    visible: hasWindow
    implicitWidth: hasWindow ? (isVertical ? crossExtent : Math.max(crossExtent, viewportExtent)) : 0
    implicitHeight: hasWindow ? (isVertical ? Math.max(crossExtent, viewportExtent) : crossExtent) : 0

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

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": pluginApi?.tr("menu.settings"),
                "action": "settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);
            selectedEntryKey = "";

            if (action === "settings")
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
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

        Item {
            id: delegateRoot
            objectName: "scrollbarDelegateRoot"

            required property var modelData
            required property int index

            readonly property var liveEntry: root.liveEntriesByKey[modelData.entryKey] || ({})
            readonly property string liveTitle: liveEntry.title || modelData.fallbackTitle || ""
            readonly property bool isFocused: !!liveEntry.isFocused
            readonly property bool isHovered: root.hoveredEntryKey === modelData.entryKey
            readonly property bool reorderEnabled: root.supportsLiveReorder
            readonly property bool showTooltip: root.showTitle ? textLabel.truncated : true
            readonly property color baseAccentColor: root.accentColor
            readonly property color accentFill: Qt.rgba(baseAccentColor.r, baseAccentColor.g, baseAccentColor.b, root.focusedFillOpacity)
            readonly property color accentOutline: Qt.rgba(baseAccentColor.r, baseAccentColor.g, baseAccentColor.b, root.focusedBorderOpacity)
            readonly property color hoverFillBaseColor: Color.resolveColorKey(root.hoverFillColorKey)
            readonly property color hoverBorderBaseColor: Color.resolveColorKey(root.hoverBorderColorKey)
            readonly property color hoverTextColor: Color.resolveColorKey(root.hoverTextColorKey)
            readonly property color mutedOutline: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, root.unfocusedBorderOpacity)
            readonly property color mutedFill: Qt.rgba(Color.mSurfaceVariant.r, Color.mSurfaceVariant.g, Color.mSurfaceVariant.b, root.unfocusedFillOpacity)
            readonly property color hoverFill: Qt.rgba(hoverFillBaseColor.r, hoverFillBaseColor.g, hoverFillBaseColor.b, root.hoverFillOpacity)
            readonly property color hoverOutline: Qt.rgba(hoverBorderBaseColor.r, hoverBorderBaseColor.g, hoverBorderBaseColor.b, root.hoverBorderOpacity)
            readonly property color slotTextColor: isFocused ? Color.mOnPrimary : (isHovered ? hoverTextColor : Color.mOnSurface)
            readonly property real hoverScaleMultiplier: 1 + (root.hoverScalePercent / 100)
            readonly property real neighborShift: {
                if (root.dragSourceIndex === -1 || root.dragTargetIndex === -1 || root.dragSourceIndex === index)
                    return 0;
                if (root.dragSourceIndex < root.dragTargetIndex && index > root.dragSourceIndex && index <= root.dragTargetIndex)
                    return -(root.isVertical ? (delegateRoot.height + root.slotSpacing) : (delegateRoot.width + root.slotSpacing));
                if (root.dragSourceIndex > root.dragTargetIndex && index >= root.dragTargetIndex && index < root.dragSourceIndex)
                    return root.isVertical ? (delegateRoot.height + root.slotSpacing) : (delegateRoot.width + root.slotSpacing);
                return 0;
            }
            property bool hadDragDuringPress: false

            Layout.preferredWidth: root.isVertical ? root.crossExtent : root.slotLength
            Layout.preferredHeight: root.isVertical ? root.slotLength : root.crossExtent
            width: Layout.preferredWidth
            height: Layout.preferredHeight
            z: root.dragSourceIndex === index ? 1000 : 1

            Item {
                id: draggableContent
                anchors.centerIn: dragArea.drag.active ? undefined : parent
                width: parent.width
                height: parent.height
                z: dragArea.drag.active ? 1000 : 0
                scale: (dragArea.drag.active ? 1.03 : 1.0) * ((delegateRoot.isHovered && !delegateRoot.isFocused) ? delegateRoot.hoverScaleMultiplier : 1.0)
                opacity: delegateRoot.isFocused ? 1.0 : root.inactiveOpacity

                transform: Translate {
                    x: !root.isVertical ? delegateRoot.neighborShift : 0
                    y: root.isVertical ? delegateRoot.neighborShift : 0

                    Behavior on x {
                        NumberAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: Style.animationFast
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: root.hoverTransitionDurationMs
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Style.animationFast
                        easing.type: Easing.OutQuad
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Style.radiusM * root.radiusScale
                    color: delegateRoot.isFocused ? delegateRoot.accentFill : (delegateRoot.isHovered ? delegateRoot.hoverFill : delegateRoot.mutedFill)
                    border.color: delegateRoot.isFocused ? delegateRoot.accentOutline : (delegateRoot.isHovered ? delegateRoot.hoverOutline : delegateRoot.mutedOutline)
                    border.width: {
                        if (delegateRoot.isFocused) return root.showFocusedBorder ? Style.borderS : 0;
                        if (delegateRoot.isHovered) return root.showHoverBorder ? Style.borderS : 0;
                        return root.showUnfocusedBorder ? Style.borderS : 0;
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: root.hoverTransitionDurationMs
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: root.hoverTransitionDurationMs
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.marginM
                    anchors.rightMargin: Style.marginM
                    anchors.topMargin: Style.marginS
                    anchors.bottomMargin: Style.marginS
                    spacing: Style.marginS
                    visible: !root.isVertical

                    Item {
                        Layout.preferredWidth: root.itemSize
                        Layout.preferredHeight: root.itemSize
                        Layout.alignment: Qt.AlignVCenter

                        IconImage {
                            id: appIcon
                            anchors.fill: parent
                            source: ThemeIcons.iconForAppId(delegateRoot.modelData.appId)
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        NText {
                            anchors.centerIn: parent
                            visible: !appIcon.visible
                            text: delegateRoot.liveTitle.charAt(0).toUpperCase()
                            font.weight: Style.fontWeightBold
                            pointSize: Math.max(Style.fontSizeXS, root.barFontSize - 1)
                            color: delegateRoot.slotTextColor
                        }
                    }

                    NText {
                        id: textLabel
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        text: delegateRoot.liveTitle
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        visible: root.showTitle
                        color: delegateRoot.slotTextColor
                        pointSize: root.barFontSize
                        font.weight: delegateRoot.isFocused ? Style.fontWeightSemiBold : Style.fontWeightMedium
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginS
                    spacing: Style.marginXS
                    visible: root.isVertical

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: root.itemSize
                        Layout.preferredHeight: root.itemSize

                        IconImage {
                            id: appIconVertical
                            anchors.fill: parent
                            source: ThemeIcons.iconForAppId(delegateRoot.modelData.appId)
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        NText {
                            anchors.centerIn: parent
                            visible: !appIconVertical.visible
                            text: delegateRoot.liveTitle.charAt(0).toUpperCase()
                            font.weight: Style.fontWeightBold
                            pointSize: Math.max(Style.fontSizeXS, root.barFontSize - 1)
                            color: delegateRoot.slotTextColor
                        }
                    }

                    NText {
                        Layout.fillWidth: true
                        text: delegateRoot.isFocused ? "\u2022" : ""
                        horizontalAlignment: Text.AlignHCenter
                        color: delegateRoot.slotTextColor
                        pointSize: root.barFontSize
                    }
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                preventStealing: true
                drag.target: delegateRoot.reorderEnabled ? draggableContent : null
                drag.axis: root.isVertical ? Drag.YAxis : Drag.XAxis

                onEntered: {
                    root.hoveredEntryKey = delegateRoot.modelData.entryKey;
                    root.debugLog("Hover enter " + delegateRoot.modelData.entryKey);
                    if (delegateRoot.showTooltip)
                        TooltipService.show(delegateRoot, delegateRoot.liveTitle, BarService.getTooltipDirection(root.screen?.name));
                }

                onExited: {
                    if (root.hoveredEntryKey === delegateRoot.modelData.entryKey)
                        root.hoveredEntryKey = "";
                    TooltipService.hide();
                }

                onPressed: mouse => {
                    delegateRoot.hadDragDuringPress = false;
                    if (mouse.button === Qt.RightButton)
                        root.selectedEntryKey = delegateRoot.modelData.entryKey;
                }

                onPositionChanged: {
                    if (drag.active) {
                        delegateRoot.hadDragDuringPress = true;
                        root.dragSourceIndex = index;
                        root.updateDragTargetForItem(index, draggableContent);
                    }
                }

                onReleased: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        root.mainInstance?.closeEntry(delegateRoot.modelData.entryKey);
                        return;
                    }

                    if (mouse.button === Qt.RightButton) {
                        TooltipService.hide();
                        root.debugLog("Open context menu for " + delegateRoot.modelData.entryKey);
                        PanelService.showContextMenu(contextMenu, delegateRoot, root.screen);
                        return;
                    }

                    if (delegateRoot.hadDragDuringPress || root.dragSourceIndex === index) {
                        root.completeDragReorder();
                    } else {
                        root.mainInstance?.focusEntry(delegateRoot.modelData.entryKey);
                        Qt.callLater(function () {
                            root.centerEntryAt(index);
                        });
                    }
                }
            }
        }
    }

    Component {
        id: horizontalStripComponent

        Item {
            readonly property real contentExtent: rowLayout.implicitWidth

            width: contentExtent
            height: root.crossExtent
            y: parent ? Style.pixelAlignCenter(parent.height, height) : 0

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
            readonly property real contentExtent: columnLayout.implicitHeight

            width: root.crossExtent
            height: contentExtent
            x: parent ? Style.pixelAlignCenter(parent.width, width) : 0

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
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: root.slotSpacing

                Repeater {
                    model: root.combinedModel
                    delegate: entryDelegateComponent
                }
            }
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        clip: true
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

    Item {
        anchors.fill: parent
        visible: root.showTrackLine

        Rectangle {
            visible: !root.isVertical
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            height: root.trackThickness
            radius: height / 2
            color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, root.trackOpacity)
        }

        Rectangle {
            visible: !root.isVertical && flickable.contentWidth > 0
            anchors.bottom: parent.bottom
            height: root.trackThickness
            radius: height / 2
            width: Math.max(Style.marginXL, Math.round((flickable.width / flickable.contentWidth) * parent.width))
            x: flickable.contentWidth > flickable.width ? Math.round((flickable.contentX / Math.max(1, flickable.contentWidth - flickable.width)) * Math.max(0, parent.width - width)) : 0
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.85)
        }

        Rectangle {
            visible: !root.isVertical && root.focusedIndicatorVisible
            anchors.bottom: parent.bottom
            height: root.focusLineThickness
            radius: height / 2
            width: root.focusedIndicatorLength
            x: root.focusedIndicatorOffset - flickable.contentX
            color: Qt.rgba(root.focusLineColor.r, root.focusLineColor.g, root.focusLineColor.b, root.focusLineOpacity)
            z: 2

            Behavior on x {
                NumberAnimation {
                    duration: root.focusLineAnimationMs
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on width {
                NumberAnimation {
                    duration: root.focusLineAnimationMs
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            visible: root.isVertical
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 1
            width: root.trackThickness
            radius: width / 2
            color: Qt.rgba(Color.mOutline.r, Color.mOutline.g, Color.mOutline.b, root.trackOpacity)
        }

        Rectangle {
            visible: root.isVertical && flickable.contentHeight > 0
            anchors.right: parent.right
            anchors.rightMargin: 1
            width: root.trackThickness
            radius: width / 2
            height: Math.max(Style.marginXL, Math.round((flickable.height / flickable.contentHeight) * parent.height))
            y: flickable.contentHeight > flickable.height ? Math.round((flickable.contentY / Math.max(1, flickable.contentHeight - flickable.height)) * Math.max(0, parent.height - height)) : 0
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.85)
        }

        Rectangle {
            visible: root.isVertical && root.focusedIndicatorVisible
            anchors.right: parent.right
            width: root.focusLineThickness
            radius: width / 2
            height: root.focusedIndicatorLength
            y: root.focusedIndicatorOffset - flickable.contentY
            color: Qt.rgba(root.focusLineColor.r, root.focusLineColor.g, root.focusLineColor.b, root.focusLineOpacity)
            z: 2

            Behavior on y {
                NumberAnimation {
                    duration: root.focusLineAnimationMs
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: root.focusLineAnimationMs
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Rectangle {
        visible: !root.isVertical && root.edgeFadeSize > 0 && root.showLeadingFade
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.edgeFadeSize
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Color.mSurface }
            GradientStop { position: root.edgeFadeMidpoint; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, root.edgeFadeMidOpacity) }
            GradientStop { position: 1.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.0) }
        }
    }

    Rectangle {
        visible: !root.isVertical && root.edgeFadeSize > 0 && root.showTrailingFade
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.edgeFadeSize
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.0) }
            GradientStop { position: 1.0 - root.edgeFadeMidpoint; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, root.edgeFadeMidOpacity) }
            GradientStop { position: 1.0; color: Color.mSurface }
        }
    }

    Rectangle {
        visible: root.isVertical && root.edgeFadeSize > 0 && root.showLeadingFade
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.edgeFadeSize
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Color.mSurface }
            GradientStop { position: root.edgeFadeMidpoint; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, root.edgeFadeMidOpacity) }
            GradientStop { position: 1.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.0) }
        }
    }

    Rectangle {
        visible: root.isVertical && root.edgeFadeSize > 0 && root.showTrailingFade
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.edgeFadeSize
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, 0.0) }
            GradientStop { position: 1.0 - root.edgeFadeMidpoint; color: Qt.rgba(Color.mSurface.r, Color.mSurface.g, Color.mSurface.b, root.edgeFadeMidOpacity) }
            GradientStop { position: 1.0; color: Color.mSurface }
        }
    }
}
