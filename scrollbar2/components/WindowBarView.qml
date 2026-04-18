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

    function resolveColor(value, fallbackColor) {
        if (mainInstance?.resolveSettingColor)
            return mainInstance.resolveSettingColor(value, fallbackColor);
        return fallbackColor;
    }

    readonly property bool onlySameOutput: settingValue("filtering", "onlySameOutput", true)
    readonly property bool onlyActiveWorkspaces: settingValue("filtering", "onlyActiveWorkspaces", true)
    readonly property string trackPosition: settingValue("track", "position", "bottom")
    readonly property string trackVerticalAlign: settingValue("track", "verticalAlign", "bottom")
    readonly property real trackThickness: Math.max(1, settingValue("track", "thickness", 6) * Style.uiScaleRatio)
    readonly property real trackBorderRadius: Math.max(0, settingValue("track", "borderRadius", 3) * Style.uiScaleRatio)
    readonly property bool trackShadowEnabled: settingValue("track", "shadowEnabled", true)
    readonly property real trackOpacity: Math.max(0, Math.min(1, settingValue("track", "opacity", 1)))
    readonly property color trackColor: resolveColor(settingValue("track", "color", "surface"), Color.mSurface)
    readonly property color separatorColor: resolveColor(settingValue("track", "separatorColor", "outline"), Color.mOutline)
    readonly property real trackWidthPercent: Math.max(5, Math.min(100, settingValue("track", "width", 90)))
    readonly property real segmentSpacing: Math.max(0, settingValue("track", "segmentSpacing", 4) * Style.uiScaleRatio)

    readonly property real focusLineThickness: Math.max(1, settingValue("focusLine", "thickness", 6) * Style.uiScaleRatio)
    readonly property real focusLineRadius: Math.max(0, settingValue("focusLine", "borderRadius", 3) * Style.uiScaleRatio)
    readonly property string focusLineVerticalAlign: settingValue("focusLine", "verticalAlign", "bottom")
    readonly property bool focusLineShadowEnabled: settingValue("focusLine", "shadowEnabled", true)
    readonly property real focusLineOpacity: Math.max(0, Math.min(1, settingValue("focusLine", "opacity", 1)))
    readonly property color focusLineFocusedColor: resolveColor(nestedStateColor("focusLine", "focused", "primary"), Color.mPrimary)
    readonly property color focusLineHoverColor: resolveColor(nestedStateColor("focusLine", "hover", "hover"), Color.mHover)
    readonly property color focusLineDefaultColor: resolveColor(nestedStateColor("focusLine", "default", "surface-variant"), Color.mSurfaceVariant)

    readonly property bool showIcon: settingValue("window", "showIcon", true)
    readonly property bool showTitle: settingValue("window", "showTitle", true)
    readonly property bool focusedOnly: settingValue("window", "focusedOnly", false)
    readonly property string focusedAlign: settingValue("window", "focusedAlign", "segment")
    readonly property real windowBorderRadius: Math.max(0, settingValue("window", "borderRadius", 6) * Style.uiScaleRatio)
    readonly property real windowMargin: Math.max(0, settingValue("window", "margin", 2) * Style.uiScaleRatio)
    readonly property real windowPaddingLeft: Math.max(0, settingValue("window", "paddingLeft", 7) * Style.uiScaleRatio)
    readonly property real windowPaddingRight: Math.max(0, settingValue("window", "paddingRight", 7) * Style.uiScaleRatio)
    readonly property string titleFontFamily: settingValue("window", "font", "JetBrains Mono")
    readonly property real titleFontSize: Math.max(1, settingValue("window", "fontSize", 11) * Style.uiScaleRatio)
    readonly property real iconScale: Math.max(0.5, settingValue("window", "iconScale", 1.0))
    readonly property real titleScale: Math.max(0.5, settingValue("window", "titleScale", 1.0))
    readonly property string iconAlign: settingValue("window", "iconAlign", "center")
    readonly property string titleAlign: settingValue("window", "titleAlign", "left")
    readonly property string titleWeightFocused: currentSettings?.window?.fontWeights?.focused ?? defaults?.window?.fontWeights?.focused ?? "semibold"
    readonly property string titleWeightHover: currentSettings?.window?.fontWeights?.hover ?? defaults?.window?.fontWeights?.hover ?? "medium"
    readonly property string titleWeightDefault: currentSettings?.window?.fontWeights?.default ?? defaults?.window?.fontWeights?.default ?? "medium"
    readonly property color iconColorFocused: resolveColor(nestedWindowStateColor("iconColors", "focused", "on-surface"), Color.mOnSurface)
    readonly property color iconColorHover: resolveColor(nestedWindowStateColor("iconColors", "hover", "on-hover"), Color.mOnHover)
    readonly property color iconColorDefault: resolveColor(nestedWindowStateColor("iconColors", "default", "on-surface-variant"), Color.mOnSurfaceVariant)
    readonly property color titleColorFocused: resolveColor(nestedWindowStateColor("titleColors", "focused", "on-surface"), Color.mOnSurface)
    readonly property color titleColorHover: resolveColor(nestedWindowStateColor("titleColors", "hover", "on-hover"), Color.mOnHover)
    readonly property color titleColorDefault: resolveColor(nestedWindowStateColor("titleColors", "default", "on-surface-variant"), Color.mOnSurfaceVariant)

    readonly property bool animationEnabled: settingValue("animation", "enabled", true)
    readonly property int animationSpeed: Math.max(0, Math.round(settingValue("animation", "speed", 420)))

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
    readonly property real computedContentHeight: {
        if (!showIcon && !showTitle)
            return Math.max(trackThickness, focusLineThickness);
        const windowContentHeight = computedLabelHeight + horizontalPadding * 2;
        return Math.max(trackThickness, focusLineThickness, windowContentHeight);
    }
    readonly property real availableContainerHeight: Math.max(1, root.height > 0 ? root.height : (hostMode === "bar" ? Style.getCapsuleHeightForScreen(screenName) : computedContentHeight))
    readonly property real visibleTrackThickness: Math.min(availableContainerHeight, trackThickness)
    readonly property real visibleFocusLineThickness: Math.min(availableContainerHeight, focusLineThickness)
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
    implicitHeight: hostVisible && segmentCount > 0 ? availableContainerHeight : 0
    visible: hostVisible && segmentCount > 0

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
        if (state === "focused")
            return focusLineFocusedColor;
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

    function titleWeight(entryKey) {
        switch (segmentState(entryKey)) {
        case "focused":
            return fontWeightValue(titleWeightFocused, Style.fontWeightSemiBold);
        case "hover":
            return fontWeightValue(titleWeightHover, Style.fontWeightMedium);
        default:
            return fontWeightValue(titleWeightDefault, Style.fontWeightMedium);
        }
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

    function separatorOffset(index) {
        return horizontalPadding + (index + 1) * segmentWidth + index * segmentSpacing;
    }

    function alignedY(alignKey, itemThickness) {
        if (alignKey === "top")
            return 0;
        if (alignKey === "center")
            return Math.round((availableContainerHeight - itemThickness) / 2);
        return Math.max(0, availableContainerHeight - itemThickness);
    }

    function trackLineY() {
        return alignedY(trackVerticalAlign, visibleTrackThickness);
    }

    function indicatorY() {
        return alignedY(focusLineVerticalAlign, visibleFocusLineThickness);
    }

    function focusedEntry() {
        if (focusedIndex < 0 || focusedIndex >= entries.length)
            return null;
        return entries[focusedIndex];
    }

    function horizontalAlignment(alignKey) {
        switch (alignKey) {
        case "center":
            return Text.AlignHCenter;
        case "right":
            return Text.AlignRight;
        default:
            return Text.AlignLeft;
        }
    }

    function fontWeightValue(weightKey, fallbackValue) {
        switch (weightKey) {
        case "light":
            return Font.Light;
        case "normal":
            return Font.Normal;
        case "medium":
            return Style.fontWeightMedium;
        case "semibold":
            return Style.fontWeightSemiBold;
        case "bold":
            return Style.fontWeightBold;
        default:
            return fallbackValue;
        }
    }

    function iconAnchor(alignKey) {
        switch (alignKey) {
        case "left":
            return 0;
        case "right":
            return 1;
        default:
            return 0.5;
        }
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
        PanelService.showContextMenu(contextMenu, root, root.screen, anchorItem ?? root);
    }

    Row {
        id: segmentsRow
        anchors.fill: parent
        anchors.leftMargin: horizontalPadding
        anchors.rightMargin: horizontalPadding
        spacing: segmentSpacing
        z: 1

        Repeater {
            model: root.entries

            delegate: Item {
                id: segmentItem

                required property var modelData
                required property int index

                readonly property string entryKey: modelData.entryKey ?? ""
                readonly property string title: root.currentTitle(modelData)
                readonly property bool showLabel: root.labelVisible(entryKey)

                width: root.segmentWidth
                height: parent ? parent.height : root.availableContainerHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.windowMargin
                    radius: Math.min(Math.max(0, root.windowBorderRadius), Math.max(0, Math.min(width, height) / 2))
                    color: root.segmentBackgroundColor(segmentItem.entryKey)

                    Behavior on color {
                        enabled: root.animationEnabled
                        ColorAnimation {
                            duration: root.animationSpeed
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.windowMargin
                    anchors.leftMargin: root.windowMargin + root.windowPaddingLeft
                    anchors.rightMargin: root.windowMargin + root.windowPaddingRight
                    spacing: root.labelGap
                    visible: root.showIcon || root.showTitle
                    layoutDirection: root.focusedOnly && root.focusedAlign === "right" && segmentItem.showLabel ? Qt.RightToLeft : Qt.LeftToRight

                    Item {
                        Layout.preferredWidth: root.showIcon ? (root.showTitle ? root.computedIconSize : Math.max(root.computedIconSize, segmentItem.width - (root.windowMargin * 2) - root.windowPaddingLeft - root.windowPaddingRight)) : 0
                        Layout.preferredHeight: root.showIcon ? root.computedIconSize : 0
                        Layout.alignment: Qt.AlignVCenter
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
                            width: root.computedIconSize
                            height: root.computedIconSize
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.horizontalCenterOffset: Math.round((parent.width - width) * (root.iconAnchor(root.iconAlign) - 0.5))
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
                            width: root.computedIconSize
                            horizontalAlignment: root.horizontalAlignment(root.iconAlign)
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.horizontalCenterOffset: Math.round((parent.width - width) * (root.iconAnchor(root.iconAlign) - 0.5))
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
                        Layout.alignment: Qt.AlignVCenter
                        visible: root.showTitle
                        text: segmentItem.title
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        opacity: segmentItem.showLabel ? 1 : 0
                        color: root.labelColor(segmentItem.entryKey, "title")
                        horizontalAlignment: root.horizontalAlignment(root.titleAlign)
                        font.family: root.titleFontFamily || Qt.application.font.family
                        pointSize: root.titleFontSize * root.titleScale
                        font.weight: root.titleWeight(segmentItem.entryKey)

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
                    preventStealing: true

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

                    onReleased: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            root.mainInstance?.closeEntry(segmentItem.entryKey);
                        } else if (mouse.button === Qt.RightButton) {
                            TooltipService.hide();
                            root.openContextMenu(segmentItem, segmentItem.modelData);
                        } else if (mouse.button === Qt.LeftButton) {
                            root.mainInstance?.focusEntry(segmentItem.entryKey);
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: trackLine
        x: 0
        y: trackLineY()
        width: root.width
        height: visibleTrackThickness
        radius: Math.min(trackBorderRadius, height / 2)
        color: Qt.alpha(trackColor, trackOpacity)
        z: 10
    }

    Item {
        id: trackSeparators
        x: 0
        y: trackLine.y
        width: root.width
        height: trackLine.height
        visible: root.segmentCount > 1 && root.segmentSpacing > 0 && trackLine.visible
        z: 11

        Repeater {
            model: Math.max(0, root.segmentCount - 1)

            delegate: Rectangle {
                required property int index

                x: root.separatorOffset(index)
                y: 0
                width: root.segmentSpacing
                height: trackSeparators.height
                color: Qt.alpha(root.separatorColor, root.trackOpacity)
            }
        }
    }

    NDropShadow {
        anchors.fill: trackLine
        source: trackLine
        autoPaddingEnabled: true
        visible: trackShadowEnabled
        z: 9
    }

    Item {
        id: focusIndicator
        visible: focusedIndex >= 0 && availableContainerHeight > 0
        x: indicatorOffset(focusedIndex)
        y: 0
        width: segmentWidth
        height: availableContainerHeight
        z: 20

        Behavior on x {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        Behavior on width {
            enabled: root.animationEnabled
            NumberAnimation {
                duration: root.animationSpeed
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        Rectangle {
            id: focusLineFill
            x: 0
            y: root.indicatorY()
            width: parent.width
            height: root.visibleFocusLineThickness
            radius: root.focusLineRadius
            color: Qt.alpha(root.focusLineFocusedColor, root.focusLineOpacity)
        }
    }

    NDropShadow {
        anchors.fill: focusIndicator
        source: focusLineFill
        autoPaddingEnabled: true
        visible: focusIndicator.visible && focusLineShadowEnabled
        z: 19
    }

    Item {
        anchors.fill: parent
        z: 10
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
                font.weight: root.fontWeightValue(root.titleWeightFocused, Style.fontWeightSemiBold)
            }
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
