import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: delegateRoot
    objectName: "scrollbarDelegateRoot"

    property var barRoot: null
    property var contextMenu: null

    required property var modelData
    required property int index

    readonly property var liveEntry: (barRoot?.liveEntriesByKey && barRoot.liveEntriesByKey[modelData.entryKey]) || ({})
    readonly property string liveTitle: liveEntry.title || modelData.fallbackTitle || ""
    readonly property bool isFocused: !!liveEntry.isFocused
    readonly property bool isHovered: barRoot?.hoveredEntryKey === modelData.entryKey
    readonly property bool reorderEnabled: barRoot?.supportsLiveReorder ?? false
    readonly property bool showTooltip: barRoot?.showTitle ? textLabel.truncated : true
    readonly property color focusedFillBaseColor: barRoot?.focusedFillColor ?? "transparent"
    readonly property color focusedBorderBaseColor: barRoot?.focusedBorderColor ?? "transparent"
    readonly property color focusedTextColor: barRoot?.focusedTextColor ?? Color.mOnSurface
    readonly property color accentFill: barRoot?.showFocusedFill ? Qt.alpha(focusedFillBaseColor, barRoot.focusedFillOpacity) : "transparent"
    readonly property color accentOutline: Qt.alpha(focusedBorderBaseColor, barRoot.focusedBorderOpacity)
    readonly property color hoverFillBaseColor: barRoot?.hoverFillColor ?? "transparent"
    readonly property color hoverBorderBaseColor: barRoot?.hoverBorderColor ?? "transparent"
    readonly property color hoverTextColor: barRoot?.hoverTextColor ?? Color.mOnSurface
    readonly property color unfocusedFillBaseColor: barRoot?.unfocusedFillColor ?? "transparent"
    readonly property color unfocusedBorderBaseColor: barRoot?.unfocusedBorderColor ?? "transparent"
    readonly property color unfocusedTextColor: barRoot?.unfocusedTextColor ?? Color.mOnSurface
    readonly property color mutedOutline: Qt.alpha(unfocusedBorderBaseColor, barRoot?.unfocusedBorderOpacity ?? 1)
    readonly property color mutedFill: barRoot?.showUnfocusedFill ? Qt.alpha(unfocusedFillBaseColor, barRoot.unfocusedFillOpacity) : "transparent"
    readonly property color hoverFill: Qt.alpha(hoverFillBaseColor, barRoot?.hoverFillOpacity ?? 1)
    readonly property color hoverOutline: Qt.alpha(hoverBorderBaseColor, barRoot?.hoverBorderOpacity ?? 1)
    readonly property color slotTextColor: isFocused ? focusedTextColor : (isHovered ? hoverTextColor : unfocusedTextColor)
    readonly property real hoverScaleMultiplier: 1 + ((barRoot?.hoverScalePercent ?? 0) / 100)
    readonly property real neighborShift: {
        if (!barRoot || barRoot.dragSourceIndex === -1 || barRoot.dragTargetIndex === -1 || barRoot.dragSourceIndex === index)
            return 0;
        if (barRoot.dragSourceIndex < barRoot.dragTargetIndex && index > barRoot.dragSourceIndex && index <= barRoot.dragTargetIndex)
            return -(barRoot.isVertical ? (delegateRoot.height + barRoot.slotSpacing) : (delegateRoot.width + barRoot.slotSpacing));
        if (barRoot.dragSourceIndex > barRoot.dragTargetIndex && index >= barRoot.dragTargetIndex && index < barRoot.dragSourceIndex)
            return barRoot.isVertical ? (delegateRoot.height + barRoot.slotSpacing) : (delegateRoot.width + barRoot.slotSpacing);
        return 0;
    }
    property bool hadDragDuringPress: false

    Layout.preferredWidth: barRoot?.isVertical ? barRoot.slotCrossExtent : barRoot.effectiveSlotLength
    Layout.preferredHeight: barRoot?.isVertical ? barRoot.effectiveSlotLength : barRoot.slotCrossExtent
    Layout.alignment: barRoot?.isVertical ? Qt.AlignHCenter : Qt.AlignVCenter
    width: Layout.preferredWidth
    height: Layout.preferredHeight
    z: barRoot?.dragSourceIndex === index ? 1000 : 1

    Item {
        id: draggableContent
        anchors.fill: dragArea.drag.active ? undefined : parent
        z: dragArea.drag.active ? 1000 : 0
        scale: (dragArea.drag.active ? 1.03 : 1.0) * ((delegateRoot.isHovered && !delegateRoot.isFocused) ? delegateRoot.hoverScaleMultiplier : 1.0)
        opacity: (delegateRoot.isFocused || delegateRoot.isHovered) ? 1.0 : (barRoot?.inactiveOpacity ?? 1.0)

        transform: Translate {
            x: !barRoot?.isVertical ? delegateRoot.neighborShift : 0
            y: barRoot?.isVertical ? delegateRoot.neighborShift : 0

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
                duration: barRoot?.hoverTransitionDurationMs ?? Style.animationFast
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
            radius: Style.radiusM * (barRoot?.radiusScale ?? 1)
            color: delegateRoot.isFocused ? delegateRoot.accentFill : (delegateRoot.isHovered ? delegateRoot.hoverFill : delegateRoot.mutedFill)
            border.color: delegateRoot.isFocused ? delegateRoot.accentOutline : (delegateRoot.isHovered ? delegateRoot.hoverOutline : delegateRoot.mutedOutline)
            border.width: {
                if (delegateRoot.isFocused)
                    return barRoot?.showFocusedBorder ? Style.borderS : 0;
                if (delegateRoot.isHovered)
                    return barRoot?.showHoverBorder ? Style.borderS : 0;
                return barRoot?.showUnfocusedBorder ? Style.borderS : 0;
            }

            Behavior on color {
                ColorAnimation {
                    duration: barRoot?.hoverTransitionDurationMs ?? Style.animationFast
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: barRoot?.hoverTransitionDurationMs ?? Style.animationFast
                    easing.type: Easing.OutQuad
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.marginM
            anchors.rightMargin: Style.marginM
            anchors.topMargin: Style.marginS * (barRoot?.slotCapsuleScale ?? 1)
            anchors.bottomMargin: Style.marginS * (barRoot?.slotCapsuleScale ?? 1)
            spacing: Style.marginS
            visible: !(barRoot?.isVertical ?? false)

            Item {
                Layout.preferredWidth: barRoot?.itemSize ?? 0
                Layout.preferredHeight: barRoot?.itemSize ?? 0
                Layout.alignment: Qt.AlignVCenter
                visible: barRoot?.showIcons ?? true

                IconImage {
                    id: appIcon
                    anchors.fill: parent
                    source: ThemeIcons.iconForAppId(delegateRoot.modelData.appId)
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: (barRoot?.iconTintEnabled ?? false) && visible
                    layer.effect: ShaderEffect {
                        property color targetColor: Qt.alpha(barRoot?.iconTintColor ?? "transparent", barRoot?.iconTintOpacity ?? 1)
                        property real colorizeMode: 0.0

                        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                }

                NText {
                    anchors.centerIn: parent
                    visible: (barRoot?.showIcons ?? true) && !appIcon.visible
                    text: delegateRoot.liveTitle.charAt(0).toUpperCase()
                    font.weight: Style.fontWeightBold
                    pointSize: Math.max(Style.fontSizeXS, (barRoot?.barFontSize ?? Style.fontSizeM) - 1)
                    color: delegateRoot.slotTextColor
                }
            }

            NText {
                id: textLabel
                Layout.fillWidth: barRoot?.showTitle ?? false
                Layout.preferredWidth: (barRoot?.showTitle ?? false) ? -1 : 0
                Layout.alignment: Qt.AlignVCenter
                text: delegateRoot.liveTitle
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: barRoot?.showTitle ?? false
                color: delegateRoot.slotTextColor
                font.family: barRoot?.titleFontFamily || Qt.application.font.family
                pointSize: barRoot?.titleFontSize > 0 ? barRoot.titleFontSize : Math.max(Style.fontSizeXS, (barRoot?.barFontSize ?? Style.fontSizeM) * (barRoot?.slotCapsuleScale ?? 1))
                font.weight: barRoot?.titleFontWeightValue >= 0 ? barRoot.titleFontWeightValue : (delegateRoot.isFocused ? Style.fontWeightSemiBold : Style.fontWeightMedium)
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: Style.marginS
            anchors.bottomMargin: Style.marginS
            anchors.leftMargin: Style.marginS * (barRoot?.slotCapsuleScale ?? 1)
            anchors.rightMargin: Style.marginS * (barRoot?.slotCapsuleScale ?? 1)
            spacing: Style.marginXS
            visible: barRoot?.isVertical ?? false

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: barRoot?.itemSize ?? 0
                Layout.preferredHeight: barRoot?.itemSize ?? 0
                visible: barRoot?.showIcons ?? true

                IconImage {
                    id: appIconVertical
                    anchors.fill: parent
                    source: ThemeIcons.iconForAppId(delegateRoot.modelData.appId)
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: (barRoot?.iconTintEnabled ?? false) && visible
                    layer.effect: ShaderEffect {
                        property color targetColor: Qt.alpha(barRoot?.iconTintColor ?? "transparent", barRoot?.iconTintOpacity ?? 1)
                        property real colorizeMode: 0.0

                        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                }

                NText {
                    anchors.centerIn: parent
                    visible: (barRoot?.showIcons ?? true) && !appIconVertical.visible
                    text: delegateRoot.liveTitle.charAt(0).toUpperCase()
                    font.weight: Style.fontWeightBold
                    pointSize: Math.max(Style.fontSizeXS, (barRoot?.barFontSize ?? Style.fontSizeM) - 1)
                    color: delegateRoot.slotTextColor
                }
            }

            NText {
                Layout.fillWidth: true
                text: delegateRoot.isFocused ? "\u2022" : ""
                horizontalAlignment: Text.AlignHCenter
                color: delegateRoot.slotTextColor
                pointSize: barRoot?.barFontSize ?? Style.fontSizeM
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
        drag.axis: barRoot?.isVertical ? Drag.YAxis : Drag.XAxis

        onEntered: {
            barRoot.hoveredEntryKey = delegateRoot.modelData.entryKey;
            barRoot.debugLog("Hover enter " + delegateRoot.modelData.entryKey);
            if (delegateRoot.showTooltip)
                TooltipService.show(delegateRoot, delegateRoot.liveTitle, BarService.getTooltipDirection(barRoot.screen?.name));
        }

        onExited: {
            if (barRoot.hoveredEntryKey === delegateRoot.modelData.entryKey)
                barRoot.hoveredEntryKey = "";
            TooltipService.hide();
        }

        onPressed: mouse => {
            delegateRoot.hadDragDuringPress = false;
            if (mouse.button === Qt.RightButton)
                barRoot.selectedEntryKey = delegateRoot.modelData.entryKey;
        }

        onPositionChanged: {
            if (drag.active) {
                delegateRoot.hadDragDuringPress = true;
                barRoot.dragSourceIndex = index;
                barRoot.updateDragTargetForItem(index, draggableContent);
            }
        }

        onReleased: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                barRoot.mainInstance?.closeEntry(delegateRoot.modelData.entryKey);
                return;
            }

            if (mouse.button === Qt.RightButton) {
                TooltipService.hide();
                barRoot.debugLog("Open context menu for " + delegateRoot.modelData.entryKey);
                PanelService.showContextMenu(contextMenu, delegateRoot, barRoot.screen);
                return;
            }

            if (delegateRoot.hadDragDuringPress || barRoot.dragSourceIndex === index) {
                barRoot.completeDragReorder();
            } else {
                barRoot.mainInstance?.focusEntry(delegateRoot.modelData.entryKey);
                Qt.callLater(function () {
                    barRoot.centerEntryAt(index);
                });
            }
        }

        onWheel: wheel => {
            if (!(barRoot?.enableScrollWheel ?? false) || !(barRoot?.hasWindow ?? false)) {
                wheel.accepted = false;
                return;
            }
            barRoot.debugLog("delegate onWheel delta=" + wheel.angleDelta.y);
            const flickable = barRoot.flickableRef;
            const step = wheel.angleDelta.y / 120 * barRoot.effectiveSlotLength;
            if (barRoot.isVertical) {
                const maxY = Math.max(0, flickable.contentHeight - flickable.height);
                flickable.contentY = Math.max(0, Math.min(maxY, flickable.contentY - step));
            } else {
                const maxX = Math.max(0, flickable.contentWidth - flickable.width);
                flickable.contentX = Math.max(0, Math.min(maxX, flickable.contentX - step));
            }
            wheel.accepted = true;
        }
    }
}
