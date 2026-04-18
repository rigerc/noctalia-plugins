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
    property string hostMode: "bar"
    property bool visibleInCurrentMode: true

    property var currentSettings: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance ?? null

    property string hoveredEntryKey: ""
    property string selectedEntryKey: ""
    property string selectedAppId: ""
    property var contextMenuModel: []

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isVerticalBar: barPosition === "left" || barPosition === "right"
    readonly property bool hostVisible: visibleInCurrentMode && (hostMode !== "bar" || !isVerticalBar)

    function refreshSettingsSnapshot() {
        currentSettings = pluginApi?.pluginSettings || ({});
    }

    onPluginApiChanged: refreshSettingsSnapshot()

    Connections {
        target: pluginApi

        function onPluginSettingsChanged() {
            root.refreshSettingsSnapshot();
        }
    }

    function settingValue(groupKey, nestedKey, fallbackValue) {
        const configGroup = currentSettings ? currentSettings[groupKey] : undefined;
        const nestedConfig = configGroup ? configGroup[nestedKey] : undefined;
        if (nestedConfig !== undefined)
            return nestedConfig;

        const defaultsGroup = defaults ? defaults[groupKey] : undefined;
        const nestedDefault = defaultsGroup ? defaultsGroup[nestedKey] : undefined;
        if (nestedDefault !== undefined)
            return nestedDefault;

        return fallbackValue;
    }

    function nestedStateColor(groupKey, stateKey, fallbackValue) {
        const group = currentSettings?.[groupKey]?.colors;
        if (group && group[stateKey] !== undefined)
            return group[stateKey];

        const defaultGroup = defaults?.[groupKey]?.colors;
        if (defaultGroup && defaultGroup[stateKey] !== undefined)
            return defaultGroup[stateKey];

        return fallbackValue;
    }

    function nestedWindowStateColor(groupKey, stateKey, fallbackValue) {
        const group = currentSettings?.window?.[groupKey];
        if (group && group[stateKey] !== undefined)
            return group[stateKey];

        const defaultGroup = defaults?.window?.[groupKey];
        if (defaultGroup && defaultGroup[stateKey] !== undefined)
            return defaultGroup[stateKey];

        return fallbackValue;
    }

    function nestedBorderValue(borderKey, fallbackValue) {
        const borders = currentSettings?.track?.borders;
        if (borders && borders[borderKey] !== undefined)
            return borders[borderKey];

        const defaultBorders = defaults?.track?.borders;
        if (defaultBorders && defaultBorders[borderKey] !== undefined)
            return defaultBorders[borderKey];

        return fallbackValue;
    }

    function resolveColor(value, fallbackColor) {
        if (mainInstance?.resolveSettingColor)
            return mainInstance.resolveSettingColor(value, fallbackColor);
        return fallbackColor;
    }

    readonly property bool onlySameOutput: settingValue("filtering", "onlySameOutput", true)
    readonly property bool onlyActiveWorkspaces: settingValue("filtering", "onlyActiveWorkspaces", true)
    readonly property string trackPosition: settingValue("track", "position", "bottom")
    readonly property real trackThickness: Math.max(1, settingValue("track", "thickness", 6) * Style.uiScaleRatio)
    readonly property real trackHeightSetting: Math.max(0, settingValue("track", "height", 0) * Style.uiScaleRatio)
    readonly property real trackBorderRadius: Math.max(0, settingValue("track", "borderRadius", 3) * Style.uiScaleRatio)
    readonly property bool trackShadowEnabled: settingValue("track", "shadowEnabled", true)
    readonly property real trackOpacity: Math.max(0, Math.min(1, settingValue("track", "opacity", 1)))
    readonly property color trackColor: resolveColor(settingValue("track", "color", "#16161f"), Color.mSurface)
    readonly property real trackWidthPercent: Math.max(5, Math.min(100, settingValue("track", "width", 90)))
    readonly property real segmentSpacing: Math.max(0, settingValue("track", "segmentSpacing", 4) * Style.uiScaleRatio)
    readonly property bool borderTop: nestedBorderValue("top", false)
    readonly property bool borderRight: nestedBorderValue("right", false)
    readonly property bool borderBottom: nestedBorderValue("bottom", false)
    readonly property bool borderLeft: nestedBorderValue("left", false)
    readonly property bool borderSegment: nestedBorderValue("segment", false)
    readonly property color borderColor: resolveColor(settingValue("track", "borderColor", "#2a2a42"), Color.mOutline)
    readonly property real borderWidth: Math.max(0, settingValue("track", "borderWidth", 1) * Style.uiScaleRatio)

    readonly property real focusLineThickness: Math.max(1, settingValue("focusLine", "thickness", 6) * Style.uiScaleRatio)
    readonly property real focusLineRadius: Math.max(0, settingValue("focusLine", "borderRadius", 3) * Style.uiScaleRatio)
    readonly property string focusLineVerticalAlign: settingValue("focusLine", "verticalAlign", "bottom")
    readonly property bool focusLineShadowEnabled: settingValue("focusLine", "shadowEnabled", true)
    readonly property real focusLineOpacity: Math.max(0, Math.min(1, settingValue("focusLine", "opacity", 1)))
    readonly property color focusLineFocusedColor: resolveColor(nestedStateColor("focusLine", "focused", "#00e5ff"), Color.mPrimary)
    readonly property color focusLineHoverColor: resolveColor(nestedStateColor("focusLine", "hover", "#1a2a36"), Color.mHover)
    readonly property color focusLineDefaultColor: resolveColor(nestedStateColor("focusLine", "default", "#12121e"), Color.mSurfaceVariant)

    readonly property bool showIcon: settingValue("window", "showIcon", true)
    readonly property bool showTitle: settingValue("window", "showTitle", true)
    readonly property bool focusedOnly: settingValue("window", "focusedOnly", false)
    readonly property string focusedAlign: settingValue("window", "focusedAlign", "segment")
    readonly property string titleFontFamily: settingValue("window", "font", "JetBrains Mono")
    readonly property real titleFontSize: Math.max(1, settingValue("window", "fontSize", 11) * Style.uiScaleRatio)
    readonly property real iconScale: Math.max(0.5, settingValue("window", "iconScale", 1.0))
    readonly property real titleScale: Math.max(0.5, settingValue("window", "titleScale", 1.0))
    readonly property color iconColorFocused: resolveColor(nestedWindowStateColor("iconColors", "focused", "#ffffff"), Color.mOnSurface)
    readonly property color iconColorHover: resolveColor(nestedWindowStateColor("iconColors", "hover", "#9090b8"), Color.mOnSurfaceVariant)
    readonly property color iconColorDefault: resolveColor(nestedWindowStateColor("iconColors", "default", "#404060"), Color.mOnSurfaceVariant)
    readonly property color titleColorFocused: resolveColor(nestedWindowStateColor("titleColors", "focused", "#ffffff"), Color.mOnSurface)
    readonly property color titleColorHover: resolveColor(nestedWindowStateColor("titleColors", "hover", "#9090b8"), Color.mOnSurfaceVariant)
    readonly property color titleColorDefault: resolveColor(nestedWindowStateColor("titleColors", "default", "#404060"), Color.mOnSurfaceVariant)

    readonly property bool animationEnabled: settingValue("animation", "enabled", true)
    readonly property string animationType: settingValue("animation", "type", "spring")
    readonly property int animationSpeed: Math.max(0, Math.round(settingValue("animation", "speed", 420)))
    readonly property bool isFadeAnimation: animationType === "fade"

    readonly property int revisionToken: (mainInstance?.structureRevision ?? 0) + (mainInstance?.liveRevision ?? 0) + (mainInstance?.titleRevision ?? 0)
    readonly property var entries: {
        revisionToken;
        if (!mainInstance)
            return [];
        return mainInstance.getFilteredEntries(screenName, onlySameOutput, onlyActiveWorkspaces) || [];
    }
    readonly property int segmentCount: entries.length
    readonly property real availableWidth: Math.max(160 * Style.uiScaleRatio, Math.round((screen?.width || 1200) * trackWidthPercent / 100))
    readonly property real horizontalPadding: Math.max(2, Math.round(2 * Style.uiScaleRatio))
    readonly property real labelPaddingH: Math.max(6, Math.round(7 * Style.uiScaleRatio))
    readonly property real labelGap: Math.max(4, Math.round(5 * Style.uiScaleRatio))
    readonly property real computedIconSize: Math.max(12 * Style.uiScaleRatio, Math.round((titleFontSize + 5 * Style.uiScaleRatio) * iconScale))
    readonly property real computedLabelHeight: Math.max(computedIconSize, Math.round(titleFontSize * titleScale * 1.5))
    readonly property real computedTrackHeight: {
        if (!showIcon && !showTitle)
            return trackHeightSetting > 0 ? Math.max(trackHeightSetting, trackThickness) : trackThickness;
        const contentHeight = computedLabelHeight + horizontalPadding * 2;
        return trackHeightSetting > 0 ? Math.max(trackHeightSetting, trackThickness) : Math.max(trackThickness, contentHeight);
    }
    readonly property real segmentWidth: {
        if (segmentCount <= 0)
            return 0;
        const totalSpacing = Math.max(0, segmentCount - 1) * segmentSpacing;
        return Math.max(1, Math.floor((availableWidth - totalSpacing - horizontalPadding * 2) / segmentCount));
    }
    readonly property real actualTrackWidth: segmentCount > 0 ? (segmentWidth * segmentCount) + (Math.max(0, segmentCount - 1) * segmentSpacing) + horizontalPadding * 2 : availableWidth
    readonly property int focusedIndex: {
        if (!mainInstance?.activeEntryKey)
            return -1;
        for (let i = 0; i < entries.length; i++) {
            if (entries[i]?.entryKey === mainInstance.activeEntryKey)
                return i;
        }
        return -1;
    }

    implicitWidth: hostVisible && segmentCount > 0 ? actualTrackWidth : 0
    implicitHeight: hostVisible && segmentCount > 0 ? computedTrackHeight : 0
    visible: hostVisible && segmentCount > 0

    function hasBorder(flag) {
        return flag ? borderWidth : 0;
    }

    function segmentState(entryKey) {
        const isFocused = mainInstance?.activeEntryKey === entryKey;
        if (isFocused)
            return "focused";
        if (hoveredEntryKey === entryKey)
            return "hover";
        return "default";
    }

    function segmentBackgroundColor(entryKey) {
        const state = segmentState(entryKey);
        if (isFadeAnimation) {
            if (state === "focused")
                return focusLineFocusedColor;
            if (state === "hover")
                return focusLineHoverColor;
            return focusLineDefaultColor;
        }
        if (state === "hover")
            return focusLineHoverColor;
        return focusLineDefaultColor;
    }

    function labelColor(entryKey, kind) {
        const state = segmentState(entryKey);
        if (kind === "icon") {
            if (state === "focused")
                return iconColorFocused;
            if (state === "hover")
                return iconColorHover;
            return iconColorDefault;
        }
        if (state === "focused")
            return titleColorFocused;
        if (state === "hover")
            return titleColorHover;
        return titleColorDefault;
    }

    function labelVisible(entryKey) {
        if (!focusedOnly)
            return true;
        if (focusedAlign === "center")
            return false;
        return mainInstance?.activeEntryKey === entryKey;
    }

    function indicatorOffset(index) {
        if (index < 0)
            return 0;
        return horizontalPadding + index * (segmentWidth + segmentSpacing);
    }

    function indicatorY() {
        if (focusLineVerticalAlign === "top")
            return 0;
        if (focusLineVerticalAlign === "center")
            return Math.round((computedTrackHeight - focusLineThickness) / 2);
        return Math.max(0, computedTrackHeight - focusLineThickness);
    }

    function focusLineEasingType() {
        switch (animationType) {
        case "linear":
            return Easing.Linear;
        case "ease":
            return Easing.InOutQuad;
        default:
            return Easing.OutBack;
        }
    }

    function focusLineOvershoot() {
        return animationType === "spring" ? 1.15 : 0;
    }

    function focusedEntry() {
        if (focusedIndex < 0 || focusedIndex >= entries.length)
            return null;
        return entries[focusedIndex];
    }

    function currentTitle(entry) {
        if (!entry)
            return "";
        if (mainInstance?.titleEntriesByKey && mainInstance.titleEntriesByKey[entry.entryKey] !== undefined)
            return mainInstance.titleEntriesByKey[entry.entryKey];
        return entry.fallbackTitle || "";
    }

    function clearContextSelection() {
        selectedEntryKey = "";
        selectedAppId = "";
    }

    function openContextMenu(anchorItem, entry) {
        const model = [];

        if (entry) {
            selectedEntryKey = entry.entryKey ?? "";
            selectedAppId = entry.appId ?? "";
            model.push({
                "label": pluginApi?.tr("menu.focus"),
                "action": "focus",
                "icon": "eye"
            });
            model.push({
                "label": pluginApi?.tr("menu.closeWindow"),
                "action": "close",
                "icon": "x"
            });
            const desktopActions = mainInstance?.desktopEntryActionsForApp(selectedAppId) || [];
            desktopActions.forEach(function (item) {
                model.push(item);
            });
        } else {
            clearContextSelection();
        }

        model.push({
            "label": pluginApi?.tr("menu.settings"),
            "action": "settings",
            "icon": "settings"
        });

        contextMenuModel = model;
        PanelService.showContextMenu(contextMenu, anchorItem ?? root, root.screen, anchorItem ?? root);
    }

    Rectangle {
        id: trackRect
        anchors.fill: parent
        radius: trackBorderRadius
        color: Qt.alpha(trackColor, trackOpacity)
        border.width: 0

        Rectangle {
            visible: borderTop
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: borderWidth
            color: borderColor
        }

        Rectangle {
            visible: borderBottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: borderWidth
            color: borderColor
        }

        Rectangle {
            visible: borderLeft
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: borderWidth
            color: borderColor
        }

        Rectangle {
            visible: borderRight
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: borderWidth
            color: borderColor
        }
    }

    NDropShadow {
        anchors.fill: trackRect
        source: trackRect
        autoPaddingEnabled: true
        visible: trackShadowEnabled
        z: -1
    }

    Rectangle {
        id: focusIndicator
        visible: !isFadeAnimation && focusedIndex >= 0
        x: indicatorOffset(focusedIndex)
        y: indicatorY()
        width: segmentWidth
        height: Math.min(computedTrackHeight, focusLineThickness)
        radius: focusLineRadius
        color: Qt.alpha(focusLineFocusedColor, focusLineOpacity)
        z: 2

        Behavior on x {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.focusLineEasingType()
                easing.overshoot: root.focusLineOvershoot()
            }
        }

        Behavior on width {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: root.focusLineEasingType()
                easing.overshoot: root.focusLineOvershoot()
            }
        }
    }

    NDropShadow {
        anchors.fill: focusIndicator
        source: focusIndicator
        autoPaddingEnabled: true
        visible: focusIndicator.visible && focusLineShadowEnabled
        z: 1
    }

    Row {
        id: segmentsRow
        anchors.fill: parent
        anchors.margins: horizontalPadding
        spacing: segmentSpacing
        z: 3

        Repeater {
            model: root.entries

            delegate: Item {
                id: segmentItem

                required property var modelData
                required property int index

                readonly property string entryKey: modelData.entryKey ?? ""
                readonly property string title: root.currentTitle(modelData)
                readonly property bool showLabel: root.labelVisible(entryKey)
                readonly property string tooltipText: title

                width: root.segmentWidth
                height: root.computedTrackHeight - horizontalPadding * 2

                Rectangle {
                    anchors.fill: parent
                    radius: Math.max(0, root.trackBorderRadius - Style.borderS)
                    color: root.segmentBackgroundColor(segmentItem.entryKey)
                    border.width: root.borderSegment ? root.borderWidth : 0
                    border.color: root.borderColor
                    z: 1

                    Behavior on color {
                        enabled: root.animationEnabled
                        ColorAnimation {
                            duration: root.animationSpeed
                        }
                    }

                    Behavior on border.color {
                        enabled: root.animationEnabled
                        ColorAnimation {
                            duration: root.animationSpeed
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.labelPaddingH
                    anchors.rightMargin: root.labelPaddingH
                    spacing: root.labelGap
                    z: 2
                    visible: root.showIcon || root.showTitle
                    layoutDirection: root.focusedOnly && root.focusedAlign === "right" && segmentItem.showLabel ? Qt.RightToLeft : Qt.LeftToRight

                    Item {
                        Layout.preferredWidth: root.showIcon ? root.computedIconSize : 0
                        Layout.preferredHeight: root.showIcon ? root.computedIconSize : 0
                        visible: root.showIcon
                        opacity: segmentItem.showLabel ? 1 : 0

                        Behavior on opacity {
                            enabled: root.animationEnabled
                            NumberAnimation {
                                duration: root.animationSpeed
                            }
                        }

                        IconImage {
                            id: appIcon
                            anchors.fill: parent
                            source: ThemeIcons.iconForAppId(segmentItem.modelData.appId)
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready

                            layer.enabled: visible
                            layer.effect: ShaderEffect {
                                property color targetColor: root.labelColor(segmentItem.entryKey, "icon")
                                property real colorizeMode: 0.0

                                fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                            }
                        }

                        NText {
                            anchors.centerIn: parent
                            visible: !appIcon.visible
                            text: segmentItem.title.length > 0 ? segmentItem.title.charAt(0).toUpperCase() : "?"
                            pointSize: Math.max(Style.fontSizeXS, root.titleFontSize * root.titleScale * 0.95)
                            font.weight: Style.fontWeightBold
                            color: root.labelColor(segmentItem.entryKey, "icon")

                            Behavior on color {
                                enabled: root.animationEnabled
                                ColorAnimation {
                                    duration: root.animationSpeed
                                }
                            }
                        }
                    }

                    NText {
                        Layout.fillWidth: true
                        visible: root.showTitle
                        text: segmentItem.title
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: segmentItem.showLabel ? 1 : 0
                        color: root.labelColor(segmentItem.entryKey, "title")
                        font.family: root.titleFontFamily || Qt.application.font.family
                        pointSize: root.titleFontSize * root.titleScale
                        font.weight: root.segmentState(segmentItem.entryKey) === "focused" ? Style.fontWeightSemiBold : Style.fontWeightMedium

                        Behavior on color {
                            enabled: root.animationEnabled
                            ColorAnimation {
                                duration: root.animationSpeed
                            }
                        }

                        Behavior on opacity {
                            enabled: root.animationEnabled
                            NumberAnimation {
                                duration: root.animationSpeed
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        root.hoveredEntryKey = segmentItem.entryKey;
                        if (segmentItem.title)
                            TooltipService.show(segmentItem, segmentItem.title, BarService.getTooltipDirection(root.screen?.name));
                    }

                    onExited: {
                        if (root.hoveredEntryKey === segmentItem.entryKey)
                            root.hoveredEntryKey = "";
                        TooltipService.hide();
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton) {
                            root.mainInstance?.focusEntry(segmentItem.entryKey);
                        } else if (mouse.button === Qt.MiddleButton) {
                            root.mainInstance?.closeEntry(segmentItem.entryKey);
                        } else if (mouse.button === Qt.RightButton) {
                            TooltipService.hide();
                            root.openContextMenu(segmentItem, segmentItem.modelData);
                        }
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        z: 4
        visible: root.focusedOnly && root.focusedAlign === "center" && root.focusedEntry() !== null

        RowLayout {
            anchors.centerIn: parent
            spacing: root.labelGap

            Item {
                Layout.preferredWidth: root.showIcon ? root.computedIconSize : 0
                Layout.preferredHeight: root.showIcon ? root.computedIconSize : 0
                visible: root.showIcon

                IconImage {
                    id: centeredIcon
                    anchors.fill: parent
                    source: ThemeIcons.iconForAppId(root.focusedEntry()?.appId ?? "")
                    smooth: true
                    asynchronous: true
                    visible: status === Image.Ready

                    layer.enabled: visible
                    layer.effect: ShaderEffect {
                        property color targetColor: root.iconColorFocused
                        property real colorizeMode: 0.0

                        fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Shaders/qsb/appicon_colorize.frag.qsb")
                    }
                }

                NText {
                    anchors.centerIn: parent
                    visible: !centeredIcon.visible
                    text: root.currentTitle(root.focusedEntry()).length > 0 ? root.currentTitle(root.focusedEntry()).charAt(0).toUpperCase() : "?"
                    pointSize: Math.max(Style.fontSizeXS, root.titleFontSize * root.titleScale * 0.95)
                    font.weight: Style.fontWeightBold
                    color: root.iconColorFocused
                }
            }

            NText {
                visible: root.showTitle
                text: root.currentTitle(root.focusedEntry())
                elide: Text.ElideRight
                maximumLineCount: 1
                color: root.titleColorFocused
                font.family: root.titleFontFamily || Qt.application.font.family
                pointSize: root.titleFontSize * root.titleScale
                font.weight: Style.fontWeightSemiBold
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        z: 0

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.openContextMenu(root, null);
        }
    }

    NPopupContextMenu {
        id: contextMenu
        model: root.contextMenuModel

        onTriggered: function (action, item) {
            contextMenu.close();
            PanelService.closeContextMenu(root.screen);

            if (action === "focus") {
                root.mainInstance?.focusEntry(root.selectedEntryKey);
            } else if (action === "close") {
                root.mainInstance?.closeEntry(root.selectedEntryKey);
            } else if (action === "settings") {
                BarService.openPluginSettings(root.screen, pluginApi.manifest);
            } else if (action.startsWith("desktop-action-") && item?.desktopAction) {
                if (item.desktopAction.command && item.desktopAction.command.length > 0) {
                    Quickshell.execDetached(item.desktopAction.command);
                } else if (item.desktopAction.execute) {
                    item.desktopAction.execute();
                }
            }

            root.clearContextSelection();
        }
    }

    Connections {
        target: mainInstance

        function onStructureRevisionChanged() {
            root.hoveredEntryKey = "";
        }
    }
}
