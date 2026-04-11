import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.System
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null
    property var cfg: pluginApi?.pluginSettings || ({})
    property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property real preferredWidth: 760 * Style.uiScaleRatio
    property real tabViewportHeight: 440 * Style.uiScaleRatio

    readonly property bool isVerticalBar: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
    readonly property var itemColorStates: [
        {
            "key": "default",
            "label": pluginApi?.tr("settings.itemColors.states.default.label"),
            "description": pluginApi?.tr("settings.itemColors.states.default.desc")
        },
        {
            "key": "hovered",
            "label": pluginApi?.tr("settings.itemColors.states.hovered.label"),
            "description": pluginApi?.tr("settings.itemColors.states.hovered.desc")
        },
        {
            "key": "focused",
            "label": pluginApi?.tr("settings.itemColors.states.focused.label"),
            "description": pluginApi?.tr("settings.itemColors.states.focused.desc")
        },
        {
            "key": "inactive",
            "label": pluginApi?.tr("settings.itemColors.states.inactive.label"),
            "description": pluginApi?.tr("settings.itemColors.states.inactive.desc")
        }
    ]
    readonly property var titleFontWeightOptions: [
        {
            "key": "regular",
            "name": pluginApi?.tr("options.fontWeightRegular")
        },
        {
            "key": "medium",
            "name": pluginApi?.tr("options.fontWeightMedium")
        },
        {
            "key": "semibold",
            "name": pluginApi?.tr("options.fontWeightSemiBold")
        },
        {
            "key": "bold",
            "name": pluginApi?.tr("options.fontWeightBold")
        }
    ]
    readonly property var focusTransitionStyleOptions: [
        {
            "key": "soft-comet",
            "name": pluginApi?.tr("options.focusTransitionStyleSoftComet")
        },
        {
            "key": "twin-echo",
            "name": pluginApi?.tr("options.focusTransitionStyleTwinEcho")
        },
        {
            "key": "dot-wake",
            "name": pluginApi?.tr("options.focusTransitionStyleDotWake")
        },
        {
            "key": "shard-tail",
            "name": pluginApi?.tr("options.focusTransitionStyleShardTail")
        },
        {
            "key": "ribbon-pop",
            "name": pluginApi?.tr("options.focusTransitionStyleRibbonPop")
        },
        {
            "key": "spring-caravan",
            "name": pluginApi?.tr("options.focusTransitionStyleSpringCaravan")
        },
        {
            "key": "halo-slip",
            "name": pluginApi?.tr("options.focusTransitionStyleHaloSlip")
        },
        {
            "key": "pebble-chain",
            "name": pluginApi?.tr("options.focusTransitionStylePebbleChain")
        }
    ]
    readonly property var focusTransitionVerticalPositionOptions: [
        {
            "key": "bottom",
            "name": pluginApi?.tr("options.focusTransitionPositionBottom")
        },
        {
            "key": "middle",
            "name": pluginApi?.tr("options.focusTransitionPositionMiddle")
        },
        {
            "key": "top",
            "name": pluginApi?.tr("options.focusTransitionPositionTop")
        }
    ]
    readonly property var gradientDirectionOptions: [
        {
            "key": "horizontal",
            "name": pluginApi?.tr("options.gradientHorizontal")
        },
        {
            "key": "vertical",
            "name": pluginApi?.tr("options.gradientVertical")
        }
    ]

    property string valueHideMode: cfg.hideMode ?? defaults.hideMode ?? "hidden"
    property bool valueOnlyActiveWorkspaces: cfg.onlyActiveWorkspaces ?? defaults.onlyActiveWorkspaces ?? true
    property bool valueOnlySameOutput: cfg.onlySameOutput ?? defaults.onlySameOutput ?? true
    property bool valueColorizeIcons: cfg.colorizeIcons ?? defaults.colorizeIcons ?? false
    property string valueIconColor: cfg.iconColor ?? defaults.iconColor ?? "primary"
    property int valueIconColorOpacity: cfg.iconColorOpacity ?? defaults.iconColorOpacity ?? 100
    property bool valueShowTitle: isVerticalBar ? false : (cfg.showTitle ?? defaults.showTitle ?? false)
    property bool valueSmartWidth: cfg.smartWidth ?? defaults.smartWidth ?? true
    property int valueMaxTaskbarWidth: cfg.maxTaskbarWidth ?? defaults.maxTaskbarWidth ?? 40
    property int valueTitleWidth: cfg.titleWidth ?? defaults.titleWidth ?? 120
    property bool valueShowPinnedApps: cfg.showPinnedApps ?? defaults.showPinnedApps ?? true
    property real valueIconScale: cfg.iconScale ?? defaults.iconScale ?? 0.8
    property real valueHoverIconScaleMultiplier: cfg.hoverIconScaleMultiplier ?? defaults.hoverIconScaleMultiplier ?? 1.0
    property real valueHoverItemScalePercent: cfg.hoverItemScalePercent ?? defaults.hoverItemScalePercent ?? 0
    property int valueItemGapUnits: cfg.itemGapUnits ?? defaults.itemGapUnits ?? 2
    property string valueTitleFontFamily: cfg.titleFontFamily ?? defaults.titleFontFamily ?? ""
    property real valueTitleFontScale: cfg.titleFontScale ?? defaults.titleFontScale ?? 1.0
    property string valueTitleFontWeight: cfg.titleFontWeight ?? defaults.titleFontWeight ?? "medium"
    property var valueItemColors: normalizeItemColors(cfg.itemColors ?? defaults.itemColors ?? ({}))
    property bool valueFocusTransitionEnabled: cfg.focusTransitionEnabled ?? defaults.focusTransitionEnabled ?? true
    property int valueFocusTransitionDelayMs: cfg.focusTransitionDelayMs ?? defaults.focusTransitionDelayMs ?? 120
    property int valueFocusTransitionDurationMs: cfg.focusTransitionDurationMs ?? defaults.focusTransitionDurationMs ?? 220
    property string valueFocusTransitionStyle: cfg.focusTransitionStyle ?? defaults.focusTransitionStyle ?? "soft-comet"
    property int valueFocusTransitionIntensity: cfg.focusTransitionIntensity ?? defaults.focusTransitionIntensity ?? 60
    property real valueFocusTransitionScale: cfg.focusTransitionScale ?? defaults.focusTransitionScale ?? 1.0
    property string valueFocusTransitionLeadColor: cfg.focusTransitionLeadColor ?? defaults.focusTransitionLeadColor ?? "primary"
    property string valueFocusTransitionGlowColor: cfg.focusTransitionGlowColor ?? defaults.focusTransitionGlowColor ?? "primary"
    property int valueFocusTransitionBlur: cfg.focusTransitionBlur ?? defaults.focusTransitionBlur ?? 6
    property int valueFocusTransitionTransparency: cfg.focusTransitionTransparency ?? defaults.focusTransitionTransparency ?? 15
    property string valueFocusTransitionEffectColor: cfg.focusTransitionEffectColor ?? defaults.focusTransitionEffectColor ?? "tertiary"
    property string valueFocusTransitionVerticalPosition: cfg.focusTransitionVerticalPosition ?? defaults.focusTransitionVerticalPosition ?? "bottom"
    property bool valueGroupApps: cfg.groupApps ?? defaults.groupApps ?? false
    property string valueGroupClickAction: cfg.groupClickAction ?? defaults.groupClickAction ?? "cycle"
    property string valueGroupContextMenuMode: cfg.groupContextMenuMode ?? defaults.groupContextMenuMode ?? "extended"
    property string valueGroupIndicatorStyle: cfg.groupIndicatorStyle ?? defaults.groupIndicatorStyle ?? "number"
    property bool valueGroupByWorkspaceIndex: cfg.groupByWorkspaceIndex ?? defaults.groupByWorkspaceIndex ?? false
    property bool valueShowWorkspaceSeparators: cfg.showWorkspaceSeparators ?? defaults.showWorkspaceSeparators ?? true
    property bool valueWorkspaceSeparatorShowLabel: cfg.workspaceSeparatorShowLabel ?? defaults.workspaceSeparatorShowLabel ?? true
    property bool valueWorkspaceSeparatorShowDivider: cfg.workspaceSeparatorShowDivider ?? defaults.workspaceSeparatorShowDivider ?? true
    property string valueWorkspaceSeparatorPrefix: cfg.workspaceSeparatorPrefix ?? defaults.workspaceSeparatorPrefix ?? ""
    property string valueWorkspaceSeparatorSuffix: cfg.workspaceSeparatorSuffix ?? defaults.workspaceSeparatorSuffix ?? ""
    property string valueWorkspaceSeparatorDividerMode: cfg.workspaceSeparatorDividerMode ?? defaults.workspaceSeparatorDividerMode ?? "line"
    property string valueWorkspaceSeparatorDividerChar: cfg.workspaceSeparatorDividerChar ?? defaults.workspaceSeparatorDividerChar ?? "|"
    property string valueWorkspaceSeparatorDividerIcon: cfg.workspaceSeparatorDividerIcon ?? defaults.workspaceSeparatorDividerIcon ?? "minus"
    property bool valueWorkspaceSeparatorShowForFirst: cfg.workspaceSeparatorShowForFirst ?? defaults.workspaceSeparatorShowForFirst ?? false
    property var valueIgnoredWorkspaceIds: normalizeEditableRows(cfg.ignoredWorkspaceIds ?? defaults.ignoredWorkspaceIds)
    property var valueIgnoredWorkspaceNames: normalizeEditableRows(cfg.ignoredWorkspaceNames ?? defaults.ignoredWorkspaceNames)
    spacing: Style.marginM
    implicitWidth: preferredWidth

    function normalizeStateColors(sourceState, fallbackState) {
        return {
            "background": sourceState?.background ?? fallbackState?.background ?? "none",
            "border": sourceState?.border ?? fallbackState?.border ?? "none",
            "text": sourceState?.text ?? fallbackState?.text ?? "none",
            "backgroundOpacity": sourceState?.backgroundOpacity ?? fallbackState?.backgroundOpacity ?? 100,
            "borderOpacity": sourceState?.borderOpacity ?? fallbackState?.borderOpacity ?? 100,
            "textOpacity": sourceState?.textOpacity ?? fallbackState?.textOpacity ?? 100,
            "backgroundGradientEnabled": sourceState?.backgroundGradientEnabled ?? fallbackState?.backgroundGradientEnabled ?? false,
            "backgroundGradientDirection": sourceState?.backgroundGradientDirection ?? fallbackState?.backgroundGradientDirection ?? "horizontal",
            "backgroundGradientStart": sourceState?.backgroundGradientStart ?? fallbackState?.backgroundGradientStart ?? "none",
            "backgroundGradientEnd": sourceState?.backgroundGradientEnd ?? fallbackState?.backgroundGradientEnd ?? "none",
            "backgroundGradientStartOpacity": sourceState?.backgroundGradientStartOpacity ?? fallbackState?.backgroundGradientStartOpacity ?? 100,
            "backgroundGradientEndOpacity": sourceState?.backgroundGradientEndOpacity ?? fallbackState?.backgroundGradientEndOpacity ?? 100
        };
    }

    function normalizeItemColors(sourceColors) {
        const fallbackColors = defaults.itemColors || ({});
        return {
            "default": normalizeStateColors(sourceColors?.default, fallbackColors.default),
            "hovered": normalizeStateColors(sourceColors?.hovered, fallbackColors.hovered),
            "focused": normalizeStateColors(sourceColors?.focused, fallbackColors.focused),
            "inactive": normalizeStateColors(sourceColors?.inactive, fallbackColors.inactive)
        };
    }

    function setItemColor(stateKey, colorRole, colorKey) {
        const nextColors = normalizeItemColors(root.valueItemColors);
        nextColors[stateKey][colorRole] = colorKey;
        root.valueItemColors = nextColors;
    }

    function setItemStateValue(stateKey, fieldKey, value) {
        const nextColors = normalizeItemColors(root.valueItemColors);
        nextColors[stateKey][fieldKey] = value;
        root.valueItemColors = nextColors;
    }

    function getItemColor(stateKey, colorRole) {
        const colors = root.valueItemColors || ({});
        const state = colors[stateKey] || ({});
        return state[colorRole] ?? "none";
    }

    function getItemStateValue(stateKey, fieldKey) {
        const colors = normalizeItemColors(root.valueItemColors);
        return colors[stateKey]?.[fieldKey];
    }

    function getDefaultItemColor(stateKey, colorRole) {
        const fallbackColors = normalizeItemColors(defaults.itemColors || ({}));
        return fallbackColors[stateKey][colorRole];
    }

    function getDefaultItemStateValue(stateKey, fieldKey) {
        const fallbackColors = normalizeItemColors(defaults.itemColors || ({}));
        return fallbackColors[stateKey]?.[fieldKey];
    }

    function normalizeStringList(values) {
        const normalized = [];
        const seen = {};
        (values || []).forEach(value => {
            const text = String(value?.value ?? value ?? "").trim();
            if (text.length === 0 || seen[text])
                return;
            seen[text] = true;
            normalized.push(text);
        });
        return normalized;
    }

    function normalizeEditableRows(values) {
        const rows = [];
        (values || []).forEach(value => {
            rows.push({ "value": String(value || "") });
        });
        return rows;
    }

    function updateEditableRow(listProp, index, text) {
        const current = root[listProp] || [];
        if (index < 0 || index >= current.length)
            return;
        if (String(current[index]?.value || "") === text)
            return;
        const next = current.slice();
        next[index] = { "value": text };
        root[listProp] = next;
    }

    function removeEditableRow(listProp, index) {
        const current = root[listProp] || [];
        if (index < 0 || index >= current.length)
            return;
        const next = current.slice();
        next.splice(index, 1);
        root[listProp] = next;
    }

    function appendEditableRow(listProp) {
        const current = root[listProp] || [];
        root[listProp] = current.concat([{ "value": "" }]);
    }

    function saveSettings() {
        if (!pluginApi) {
            Logger.e("Taskbar2", "Cannot save settings: pluginApi is null");
            return;
        }

        pluginApi.pluginSettings.hideMode = root.valueHideMode;
        pluginApi.pluginSettings.onlySameOutput = root.valueOnlySameOutput;
        pluginApi.pluginSettings.onlyActiveWorkspaces = root.valueOnlyActiveWorkspaces;
        pluginApi.pluginSettings.colorizeIcons = root.valueColorizeIcons;
        pluginApi.pluginSettings.iconColor = root.valueIconColor;
        pluginApi.pluginSettings.iconColorOpacity = root.valueIconColorOpacity;
        pluginApi.pluginSettings.showTitle = root.valueShowTitle;
        pluginApi.pluginSettings.smartWidth = root.valueSmartWidth;
        pluginApi.pluginSettings.maxTaskbarWidth = root.valueMaxTaskbarWidth;
        pluginApi.pluginSettings.titleWidth = root.valueTitleWidth;
        pluginApi.pluginSettings.showPinnedApps = root.valueShowPinnedApps;
        pluginApi.pluginSettings.iconScale = root.valueIconScale;
        pluginApi.pluginSettings.hoverIconScaleMultiplier = root.valueHoverIconScaleMultiplier;
        pluginApi.pluginSettings.hoverItemScalePercent = root.valueHoverItemScalePercent;
        pluginApi.pluginSettings.itemGapUnits = root.valueItemGapUnits;
        pluginApi.pluginSettings.titleFontFamily = root.valueTitleFontFamily;
        pluginApi.pluginSettings.titleFontScale = root.valueTitleFontScale;
        pluginApi.pluginSettings.titleFontWeight = root.valueTitleFontWeight;
        pluginApi.pluginSettings.itemColors = normalizeItemColors(root.valueItemColors);
        pluginApi.pluginSettings.focusTransitionEnabled = root.valueFocusTransitionEnabled;
        pluginApi.pluginSettings.focusTransitionDelayMs = root.valueFocusTransitionDelayMs;
        pluginApi.pluginSettings.focusTransitionDurationMs = root.valueFocusTransitionDurationMs;
        pluginApi.pluginSettings.focusTransitionStyle = root.valueFocusTransitionStyle;
        pluginApi.pluginSettings.focusTransitionIntensity = root.valueFocusTransitionIntensity;
        pluginApi.pluginSettings.focusTransitionScale = root.valueFocusTransitionScale;
        pluginApi.pluginSettings.focusTransitionLeadColor = root.valueFocusTransitionLeadColor;
        pluginApi.pluginSettings.focusTransitionGlowColor = root.valueFocusTransitionGlowColor;
        pluginApi.pluginSettings.focusTransitionBlur = root.valueFocusTransitionBlur;
        pluginApi.pluginSettings.focusTransitionTransparency = root.valueFocusTransitionTransparency;
        pluginApi.pluginSettings.focusTransitionEffectColor = root.valueFocusTransitionEffectColor;
        pluginApi.pluginSettings.focusTransitionVerticalPosition = root.valueFocusTransitionVerticalPosition;
        pluginApi.pluginSettings.groupApps = root.valueGroupApps;
        pluginApi.pluginSettings.groupClickAction = root.valueGroupClickAction;
        pluginApi.pluginSettings.groupContextMenuMode = root.valueGroupContextMenuMode;
        pluginApi.pluginSettings.groupIndicatorStyle = root.valueGroupIndicatorStyle;
        pluginApi.pluginSettings.groupByWorkspaceIndex = root.valueGroupByWorkspaceIndex;
        pluginApi.pluginSettings.ignoredWorkspaceIds = normalizeStringList(root.valueIgnoredWorkspaceIds);
        pluginApi.pluginSettings.ignoredWorkspaceNames = normalizeStringList(root.valueIgnoredWorkspaceNames);
        pluginApi.pluginSettings.showWorkspaceSeparators = root.valueShowWorkspaceSeparators;
        pluginApi.pluginSettings.workspaceSeparatorShowLabel = root.valueWorkspaceSeparatorShowLabel;
        pluginApi.pluginSettings.workspaceSeparatorShowDivider = root.valueWorkspaceSeparatorShowDivider;
        pluginApi.pluginSettings.workspaceSeparatorPrefix = root.valueWorkspaceSeparatorPrefix;
        pluginApi.pluginSettings.workspaceSeparatorSuffix = root.valueWorkspaceSeparatorSuffix;
        pluginApi.pluginSettings.workspaceSeparatorDividerMode = root.valueWorkspaceSeparatorDividerMode;
        pluginApi.pluginSettings.workspaceSeparatorDividerChar = root.valueWorkspaceSeparatorDividerChar;
        pluginApi.pluginSettings.workspaceSeparatorDividerIcon = root.valueWorkspaceSeparatorDividerIcon;
        pluginApi.pluginSettings.workspaceSeparatorShowForFirst = root.valueWorkspaceSeparatorShowForFirst;
        pluginApi.saveSettings();
    }

    NBox {
        Layout.fillWidth: true
        implicitHeight: previewColumn.implicitHeight + Style.marginM * 2
        color: Color.mSurfaceVariant

        ColumnLayout {
            id: previewColumn
            anchors.fill: parent
            anchors.margins: Style.marginM
            spacing: Style.marginS

            NLabel {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionPreview.label")
                description: pluginApi?.tr("settings.focusTransitionPreview.desc")
            }

            FocusTransitionPreview {
                Layout.alignment: Qt.AlignHCenter
                isVerticalBar: root.isVerticalBar
                transitionEnabled: root.valueFocusTransitionEnabled
                delayMs: root.valueFocusTransitionDelayMs
                durationMs: root.valueFocusTransitionDurationMs
                styleKey: root.valueFocusTransitionStyle
                intensity: root.valueFocusTransitionIntensity
                scale: root.valueFocusTransitionScale
                leadColorKey: root.valueFocusTransitionLeadColor
                glowColorKey: root.valueFocusTransitionGlowColor
                blurRadius: root.valueFocusTransitionBlur
                transparency: root.valueFocusTransitionTransparency
                effectColorKey: root.valueFocusTransitionEffectColor
                verticalPosition: root.valueFocusTransitionVerticalPosition
                iconScale: root.valueIconScale
                itemGapUnits: root.valueItemGapUnits
                showTitle: root.valueShowTitle && !root.isVerticalBar
                titleWidth: root.valueTitleWidth
                hoverIconScaleMultiplier: root.valueHoverIconScaleMultiplier
                hoverItemScalePercent: root.valueHoverItemScalePercent
                titleFontFamily: root.valueTitleFontFamily
                titleFontScale: root.valueTitleFontScale
                titleFontWeight: root.valueTitleFontWeight
                colorizeIcons: root.valueColorizeIcons
                iconColorKey: root.valueIconColor
                iconColorOpacity: root.valueIconColorOpacity
                itemColors: root.valueItemColors
            }
        }
    }

    NTabBar {
        id: tabBar
        Layout.fillWidth: true
        distributeEvenly: true
        currentIndex: tabView.currentIndex

        NTabButton {
            text: qsTr("General")
            tabIndex: 0
        }
        NTabButton {
            text: qsTr("Organization")
            tabIndex: 1
        }
        NTabButton {
            text: qsTr("Layout")
            tabIndex: 2
        }
        NTabButton {
            text: qsTr("Colors")
            tabIndex: 3
        }
    }

    NTabView {
        id: tabView
        Layout.fillWidth: true
        Layout.preferredHeight: root.tabViewportHeight
        Layout.minimumHeight: Math.round(260 * Style.uiScaleRatio)
        currentIndex: tabBar.currentIndex

        Item {
            width: tabView.width
            height: tabView.height

            NScrollView {
                id: generalScrollView
                anchors.fill: parent
                clip: true
                horizontalPolicy: ScrollBar.AlwaysOff
                reserveScrollbarSpace: false
                gradientColor: Color.mSurface

                ColumnLayout {
                    width: generalScrollView.availableWidth
                    spacing: Style.marginM

                    NComboBox {
                        Layout.fillWidth: true
                        label: pluginApi?.tr("settings.hideMode.label")
                        description: pluginApi?.tr("settings.hideMode.desc")
                        model: [
                            {
                                "key": "visible",
                                "name": pluginApi?.tr("options.visible")
                            },
                            {
                                "key": "hidden",
                                "name": pluginApi?.tr("options.hidden")
                            },
                            {
                                "key": "transparent",
                                "name": pluginApi?.tr("options.transparent")
                            }
                        ]
                        currentKey: root.valueHideMode
                        onSelected: key => root.valueHideMode = key
                        defaultValue: defaults.hideMode ?? "hidden"
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: pluginApi?.tr("settings.onlySameOutput.label")
                        description: pluginApi?.tr("settings.onlySameOutput.desc")
                        checked: root.valueOnlySameOutput
                        onToggled: checked => root.valueOnlySameOutput = checked
                        defaultValue: defaults.onlySameOutput ?? true
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: pluginApi?.tr("settings.onlyActiveWorkspaces.label")
                        description: pluginApi?.tr("settings.onlyActiveWorkspaces.desc")
                        checked: root.valueOnlyActiveWorkspaces
                        onToggled: checked => root.valueOnlyActiveWorkspaces = checked
                        defaultValue: defaults.onlyActiveWorkspaces ?? true
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: pluginApi?.tr("settings.showPinnedApps.label")
                        description: pluginApi?.tr("settings.showPinnedApps.desc")
                        checked: root.valueShowPinnedApps
                        onToggled: checked => root.valueShowPinnedApps = checked
                        defaultValue: defaults.showPinnedApps ?? true
                    }
                }
            }
        }

        Item {
            width: tabView.width
            height: tabView.height

            NScrollView {
                id: organizationScrollView
                anchors.fill: parent
                clip: true
                horizontalPolicy: ScrollBar.AlwaysOff
                reserveScrollbarSpace: false
                gradientColor: Color.mSurface

                ColumnLayout {
                    width: organizationScrollView.availableWidth
                    spacing: Style.marginM

                    NHeading {
                        label: pluginApi?.tr("settings.sections.workspaceContainers.label")
                        description: pluginApi?.tr("settings.sections.workspaceContainers.desc")
                    }

            SectionHeader {
                label: pluginApi?.tr("settings.ignoredWorkspaces.label")
                description: pluginApi?.tr("settings.ignoredWorkspaces.desc")
            }

            Repeater {
                model: root.valueIgnoredWorkspaceIds

                delegate: RowLayout {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NTextInput {
                        Layout.fillWidth: true
                        label: index === 0 ? pluginApi?.tr("settings.ignoredWorkspaceIds.label") : ""
                        description: index === 0 ? pluginApi?.tr("settings.ignoredWorkspaceIds.desc") : ""
                        text: String(modelData?.value || "")
                        onTextChanged: root.updateEditableRow("valueIgnoredWorkspaceIds", index, text)
                    }

                    NButton {
                        text: pluginApi?.tr("settings.ignoredWorkspaces.remove")
                        onClicked: root.removeEditableRow("valueIgnoredWorkspaceIds", index)
                    }
                }
            }

            NButton {
                text: pluginApi?.tr("settings.ignoredWorkspaceIds.add")
                onClicked: root.appendEditableRow("valueIgnoredWorkspaceIds")
            }

            Repeater {
                model: root.valueIgnoredWorkspaceNames

                delegate: RowLayout {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NTextInput {
                        Layout.fillWidth: true
                        label: index === 0 ? pluginApi?.tr("settings.ignoredWorkspaceNames.label") : ""
                        description: index === 0 ? pluginApi?.tr("settings.ignoredWorkspaceNames.desc") : ""
                        text: String(modelData?.value || "")
                        onTextChanged: root.updateEditableRow("valueIgnoredWorkspaceNames", index, text)
                    }

                    NButton {
                        text: pluginApi?.tr("settings.ignoredWorkspaces.remove")
                        onClicked: root.removeEditableRow("valueIgnoredWorkspaceNames", index)
                    }
                }
            }

            NButton {
                text: pluginApi?.tr("settings.ignoredWorkspaceNames.add")
                onClicked: root.appendEditableRow("valueIgnoredWorkspaceNames")
            }

            NDivider {
                Layout.fillWidth: true
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.groupByWorkspaceIndex.label")
                description: pluginApi?.tr("settings.groupByWorkspaceIndex.desc")
                checked: root.valueGroupByWorkspaceIndex
                onToggled: checked => root.valueGroupByWorkspaceIndex = checked
                defaultValue: defaults.groupByWorkspaceIndex ?? false
            }

            NToggle {
                visible: root.valueGroupByWorkspaceIndex
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showWorkspaceSeparators.label")
                description: pluginApi?.tr("settings.showWorkspaceSeparators.desc")
                checked: root.valueShowWorkspaceSeparators
                onToggled: checked => root.valueShowWorkspaceSeparators = checked
                defaultValue: defaults.showWorkspaceSeparators ?? true
            }

            NToggle {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorShowForFirst.label")
                description: pluginApi?.tr("settings.workspaceSeparatorShowForFirst.desc")
                checked: root.valueWorkspaceSeparatorShowForFirst
                onToggled: checked => root.valueWorkspaceSeparatorShowForFirst = checked
                defaultValue: defaults.workspaceSeparatorShowForFirst ?? false
            }

            NDivider {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators
                Layout.fillWidth: true
            }

            NToggle {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorShowLabel.label")
                description: pluginApi?.tr("settings.workspaceSeparatorShowLabel.desc")
                checked: root.valueWorkspaceSeparatorShowLabel
                onToggled: checked => root.valueWorkspaceSeparatorShowLabel = checked
                defaultValue: defaults.workspaceSeparatorShowLabel ?? true
            }

            NTextInput {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators && root.valueWorkspaceSeparatorShowLabel
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorPrefix.label")
                description: pluginApi?.tr("settings.workspaceSeparatorPrefix.desc")
                text: root.valueWorkspaceSeparatorPrefix
                onTextChanged: root.valueWorkspaceSeparatorPrefix = text
                placeholderText: pluginApi?.tr("settings.workspaceSeparatorPrefix.placeholder")
                defaultValue: defaults.workspaceSeparatorPrefix ?? ""
            }

            NTextInput {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators && root.valueWorkspaceSeparatorShowLabel
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorSuffix.label")
                description: pluginApi?.tr("settings.workspaceSeparatorSuffix.desc")
                text: root.valueWorkspaceSeparatorSuffix
                onTextChanged: root.valueWorkspaceSeparatorSuffix = text
                placeholderText: pluginApi?.tr("settings.workspaceSeparatorSuffix.placeholder")
                defaultValue: defaults.workspaceSeparatorSuffix ?? ""
            }

            NDivider {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators
                Layout.fillWidth: true
            }

            NToggle {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorShowDivider.label")
                description: pluginApi?.tr("settings.workspaceSeparatorShowDivider.desc")
                checked: root.valueWorkspaceSeparatorShowDivider
                onToggled: checked => root.valueWorkspaceSeparatorShowDivider = checked
                defaultValue: defaults.workspaceSeparatorShowDivider ?? true
            }

            NComboBox {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators && root.valueWorkspaceSeparatorShowDivider
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorDividerMode.label")
                description: pluginApi?.tr("settings.workspaceSeparatorDividerMode.desc")
                model: [
                    {
                        "key": "line",
                        "name": pluginApi?.tr("options.separatorModeLine")
                    },
                    {
                        "key": "character",
                        "name": pluginApi?.tr("options.separatorModeCharacter")
                    },
                    {
                        "key": "icon",
                        "name": pluginApi?.tr("options.separatorModeIcon")
                    }
                ]
                currentKey: root.valueWorkspaceSeparatorDividerMode
                onSelected: key => root.valueWorkspaceSeparatorDividerMode = key
                defaultValue: defaults.workspaceSeparatorDividerMode ?? "line"
            }

            NTextInput {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators && root.valueWorkspaceSeparatorShowDivider && root.valueWorkspaceSeparatorDividerMode === "character"
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.workspaceSeparatorDividerChar.label")
                description: pluginApi?.tr("settings.workspaceSeparatorDividerChar.desc")
                text: root.valueWorkspaceSeparatorDividerChar
                onTextChanged: root.valueWorkspaceSeparatorDividerChar = text
                placeholderText: pluginApi?.tr("settings.workspaceSeparatorDividerChar.placeholder")
                defaultValue: defaults.workspaceSeparatorDividerChar ?? "|"
            }

            Item {
                visible: root.valueGroupByWorkspaceIndex && root.valueShowWorkspaceSeparators && root.valueWorkspaceSeparatorShowDivider && root.valueWorkspaceSeparatorDividerMode === "icon"
                Layout.fillWidth: true
                implicitHeight: iconPickerRow.height

                RowLayout {
                    id: iconPickerRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Style.marginM

                    NLabel {
                        label: pluginApi?.tr("settings.workspaceSeparatorDividerIcon.label")
                        description: pluginApi?.tr("settings.workspaceSeparatorDividerIcon.desc")
                        Layout.fillWidth: true
                    }

                    NIconButton {
                        icon: root.valueWorkspaceSeparatorDividerIcon || "minus"
                        tooltipText: pluginApi?.tr("settings.workspaceSeparatorDividerIcon.pickIcon")
                        onClicked: {
                            iconPicker.initialIcon = root.valueWorkspaceSeparatorDividerIcon || "minus";
                            iconPicker.query = root.valueWorkspaceSeparatorDividerIcon || "";
                            iconPicker.open();
                        }
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            NHeading {
                label: pluginApi?.tr("settings.sections.applicationGrouping.label")
                description: pluginApi?.tr("settings.sections.applicationGrouping.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.groupApps.label")
                description: pluginApi?.tr("settings.groupApps.desc")
                checked: root.valueGroupApps
                onToggled: checked => root.valueGroupApps = checked
                defaultValue: defaults.groupApps ?? false
            }

            NComboBox {
                visible: root.valueGroupApps
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.groupClickAction.label")
                description: pluginApi?.tr("settings.groupClickAction.desc")
                model: [
                    {
                        "key": "cycle",
                        "name": pluginApi?.tr("options.groupClickCycle")
                    },
                    {
                        "key": "list",
                        "name": pluginApi?.tr("options.groupClickList")
                    }
                ]
                currentKey: root.valueGroupClickAction
                onSelected: key => root.valueGroupClickAction = key
                defaultValue: defaults.groupClickAction ?? "cycle"
            }

            NComboBox {
                visible: root.valueGroupApps
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.groupContextMenuMode.label")
                description: pluginApi?.tr("settings.groupContextMenuMode.desc")
                model: [
                    {
                        "key": "extended",
                        "name": pluginApi?.tr("options.groupMenuExtended")
                    },
                    {
                        "key": "list",
                        "name": pluginApi?.tr("options.groupMenuList")
                    }
                ]
                currentKey: root.valueGroupContextMenuMode
                onSelected: key => root.valueGroupContextMenuMode = key
                defaultValue: defaults.groupContextMenuMode ?? "extended"
            }

                NComboBox {
                    visible: root.valueGroupApps
                    Layout.fillWidth: true
                    label: pluginApi?.tr("settings.groupIndicatorStyle.label")
                    description: pluginApi?.tr("settings.groupIndicatorStyle.desc")
                    model: [
                        {
                            "key": "number",
                            "name": pluginApi?.tr("options.groupIndicatorNumber")
                        },
                        {
                            "key": "dots",
                            "name": pluginApi?.tr("options.groupIndicatorDots")
                        }
                    ]
                    currentKey: root.valueGroupIndicatorStyle
                    onSelected: key => root.valueGroupIndicatorStyle = key
                    defaultValue: defaults.groupIndicatorStyle ?? "number"
                }
            }
            }
        }

        Item {
            width: tabView.width
            height: tabView.height

            NScrollView {
                id: layoutTabScrollView
                anchors.fill: parent
                clip: true
                horizontalPolicy: ScrollBar.AlwaysOff
                reserveScrollbarSpace: false
                gradientColor: Color.mSurface

                ColumnLayout {
                    width: layoutTabScrollView.availableWidth
                    spacing: Style.marginM

                    NHeading {
                        label: pluginApi?.tr("settings.sections.icon.label")
                        description: pluginApi?.tr("settings.sections.icon.desc")
                    }

            NValueSlider {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.iconScale.label")
                description: pluginApi?.tr("settings.iconScale.desc")
                from: 0.5
                to: 1
                stepSize: 0.01
                showReset: true
                value: root.valueIconScale
                defaultValue: defaults.iconScale ?? 0.8
                onMoved: value => root.valueIconScale = value
                text: Math.round(root.valueIconScale * 100) + "%"
            }

            NValueSlider {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.hoverIconScaleMultiplier.label")
                description: pluginApi?.tr("settings.hoverIconScaleMultiplier.desc")
                from: 1
                to: 1.35
                stepSize: 0.01
                showReset: true
                value: root.valueHoverIconScaleMultiplier
                defaultValue: defaults.hoverIconScaleMultiplier ?? 1.0
                onMoved: value => root.valueHoverIconScaleMultiplier = value
                text: Math.round(root.valueHoverIconScaleMultiplier * 100) + "%"
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.colorizeIcons.label")
                description: pluginApi?.tr("settings.colorizeIcons.desc")
                checked: root.valueColorizeIcons
                onToggled: checked => root.valueColorizeIcons = checked
                defaultValue: defaults.colorizeIcons ?? false
            }

            NColorChoice {
                visible: root.valueColorizeIcons
                label: pluginApi?.tr("settings.iconColor.label")
                description: pluginApi?.tr("settings.iconColor.desc")
                currentKey: root.valueIconColor
                onSelected: key => root.valueIconColor = key
                defaultValue: defaults.iconColor ?? "primary"
            }

            NValueSlider {
                visible: root.valueColorizeIcons
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.iconColorOpacity.label")
                description: pluginApi?.tr("settings.iconColorOpacity.desc")
                from: 0
                to: 100
                stepSize: 5
                showReset: true
                value: root.valueIconColorOpacity
                defaultValue: defaults.iconColorOpacity ?? 100
                onMoved: value => root.valueIconColorOpacity = Math.round(value)
                text: Math.round(root.valueIconColorOpacity) + "%"
            }

            NDivider {
                Layout.fillWidth: true
            }

            NHeading {
                label: pluginApi?.tr("settings.sections.geometry.label")
                description: pluginApi?.tr("settings.sections.geometry.desc")
            }

            NValueSlider {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.hoverItemScalePercent.label")
                description: pluginApi?.tr("settings.hoverItemScalePercent.desc")
                from: 0
                to: 5
                stepSize: 0.1
                showReset: true
                value: root.valueHoverItemScalePercent
                defaultValue: defaults.hoverItemScalePercent ?? 0
                onMoved: value => root.valueHoverItemScalePercent = value
                text: root.valueHoverItemScalePercent.toFixed(1) + "%"
            }

            NValueSlider {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.itemGapUnits.label")
                description: pluginApi?.tr("settings.itemGapUnits.desc")
                from: 0
                to: 20
                stepSize: 1
                showReset: true
                value: root.valueItemGapUnits
                defaultValue: defaults.itemGapUnits ?? 2
                onMoved: value => root.valueItemGapUnits = Math.round(value)
                text: Math.round(root.valueItemGapUnits)
            }

            NDivider {
                Layout.fillWidth: true
            }

            NHeading {
                label: pluginApi?.tr("settings.sections.animation.label")
                description: pluginApi?.tr("settings.sections.animation.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionEnabled.label")
                description: pluginApi?.tr("settings.focusTransitionEnabled.desc")
                checked: root.valueFocusTransitionEnabled
                onToggled: checked => root.valueFocusTransitionEnabled = checked
                defaultValue: defaults.focusTransitionEnabled ?? true
            }

            NDivider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
            }

            SectionHeader {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.sections.animationTiming.label")
                description: pluginApi?.tr("settings.sections.animationTiming.desc")
            }

            NValueSlider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionDelayMs.label")
                description: pluginApi?.tr("settings.focusTransitionDelayMs.desc")
                from: 0
                to: 400
                stepSize: 10
                showReset: true
                value: root.valueFocusTransitionDelayMs
                defaultValue: defaults.focusTransitionDelayMs ?? 120
                onMoved: value => root.valueFocusTransitionDelayMs = Math.round(value)
                text: Math.round(root.valueFocusTransitionDelayMs) + " ms"
            }

            NValueSlider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionDurationMs.label")
                description: pluginApi?.tr("settings.focusTransitionDurationMs.desc")
                from: 80
                to: 2000
                stepSize: 10
                showReset: true
                value: root.valueFocusTransitionDurationMs
                defaultValue: defaults.focusTransitionDurationMs ?? 220
                onMoved: value => root.valueFocusTransitionDurationMs = Math.round(value)
                text: Math.round(root.valueFocusTransitionDurationMs) + " ms"
            }

            NDivider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
            }

            SectionHeader {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.sections.animationStyle.label")
                description: pluginApi?.tr("settings.sections.animationStyle.desc")
            }

            NComboBox {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionStyle.label")
                description: pluginApi?.tr("settings.focusTransitionStyle.desc")
                model: root.focusTransitionStyleOptions
                currentKey: root.valueFocusTransitionStyle
                onSelected: key => root.valueFocusTransitionStyle = key
                defaultValue: defaults.focusTransitionStyle ?? "soft-comet"
            }

            NValueSlider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionIntensity.label")
                description: pluginApi?.tr("settings.focusTransitionIntensity.desc")
                from: 0
                to: 100
                stepSize: 5
                showReset: true
                value: root.valueFocusTransitionIntensity
                defaultValue: defaults.focusTransitionIntensity ?? 60
                onMoved: value => root.valueFocusTransitionIntensity = Math.round(value)
                text: Math.round(root.valueFocusTransitionIntensity) + "%"
            }

            NValueSlider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionScale.label")
                description: pluginApi?.tr("settings.focusTransitionScale.desc")
                from: 0.5
                to: 2.0
                stepSize: 0.05
                showReset: true
                value: root.valueFocusTransitionScale
                defaultValue: defaults.focusTransitionScale ?? 1.0
                onMoved: value => root.valueFocusTransitionScale = value
                text: root.valueFocusTransitionScale.toFixed(2) + "x"
            }

            NComboBox {
                visible: root.valueFocusTransitionEnabled && !root.isVerticalBar
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionVerticalPosition.label")
                description: pluginApi?.tr("settings.focusTransitionVerticalPosition.desc")
                model: root.focusTransitionVerticalPositionOptions
                currentKey: root.valueFocusTransitionVerticalPosition
                onSelected: key => root.valueFocusTransitionVerticalPosition = key
                defaultValue: defaults.focusTransitionVerticalPosition ?? "bottom"
            }

            NDivider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
            }

            SectionHeader {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.sections.animationColors.label")
                description: pluginApi?.tr("settings.sections.animationColors.desc")
            }

            NColorChoice {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.focusTransitionLeadColor.label")
                description: pluginApi?.tr("settings.focusTransitionLeadColor.desc")
                currentKey: root.valueFocusTransitionLeadColor
                onSelected: key => root.valueFocusTransitionLeadColor = key
                defaultValue: defaults.focusTransitionLeadColor ?? "primary"
            }

            NColorChoice {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.focusTransitionGlowColor.label")
                description: pluginApi?.tr("settings.focusTransitionGlowColor.desc")
                currentKey: root.valueFocusTransitionGlowColor
                onSelected: key => root.valueFocusTransitionGlowColor = key
                defaultValue: defaults.focusTransitionGlowColor ?? "primary"
            }

            NColorChoice {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.focusTransitionEffectColor.label")
                description: pluginApi?.tr("settings.focusTransitionEffectColor.desc")
                currentKey: root.valueFocusTransitionEffectColor
                onSelected: key => root.valueFocusTransitionEffectColor = key
                defaultValue: defaults.focusTransitionEffectColor ?? "tertiary"
            }

            NDivider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
            }

            SectionHeader {
                visible: root.valueFocusTransitionEnabled
                label: pluginApi?.tr("settings.sections.animationEffects.label")
                description: pluginApi?.tr("settings.sections.animationEffects.desc")
            }

            NValueSlider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionBlur.label")
                description: pluginApi?.tr("settings.focusTransitionBlur.desc")
                from: 0
                to: 24
                stepSize: 1
                showReset: true
                value: root.valueFocusTransitionBlur
                defaultValue: defaults.focusTransitionBlur ?? 6
                onMoved: value => root.valueFocusTransitionBlur = Math.round(value)
                text: Math.round(root.valueFocusTransitionBlur) + " px"
            }

            NValueSlider {
                visible: root.valueFocusTransitionEnabled
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.focusTransitionTransparency.label")
                description: pluginApi?.tr("settings.focusTransitionTransparency.desc")
                from: 0
                to: 85
                stepSize: 5
                showReset: true
                value: root.valueFocusTransitionTransparency
                defaultValue: defaults.focusTransitionTransparency ?? 15
                onMoved: value => root.valueFocusTransitionTransparency = Math.round(value)
                text: Math.round(root.valueFocusTransitionTransparency) + "%"
            }

            NDivider {
                Layout.fillWidth: true
            }

            NHeading {
                label: pluginApi?.tr("settings.sections.title.label")
                description: pluginApi?.tr("settings.sections.title.desc")
            }

            NToggle {
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.showTitle.label")
                description: root.isVerticalBar ? pluginApi?.tr("settings.showTitle.descDisabled") : pluginApi?.tr("settings.showTitle.desc")
                checked: root.valueShowTitle
                onToggled: checked => root.valueShowTitle = checked
                enabled: !root.isVerticalBar
                defaultValue: defaults.showTitle ?? false
            }

            NTextInput {
                visible: root.valueShowTitle && !root.isVerticalBar
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.titleWidth.label")
                description: pluginApi?.tr("settings.titleWidth.desc")
                text: String(root.valueTitleWidth)
                placeholderText: pluginApi?.tr("placeholders.enterWidthPixels")
                onTextChanged: root.valueTitleWidth = parseInt(text) || (defaults.titleWidth ?? 120)
                defaultValue: String(defaults.titleWidth ?? 120)
            }

            NToggle {
                Layout.fillWidth: true
                visible: !root.isVerticalBar && root.valueShowTitle
                label: pluginApi?.tr("settings.smartWidth.label")
                description: pluginApi?.tr("settings.smartWidth.desc")
                checked: root.valueSmartWidth
                onToggled: checked => root.valueSmartWidth = checked
                defaultValue: defaults.smartWidth ?? true
            }

            NValueSlider {
                visible: root.valueSmartWidth && !root.isVerticalBar
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.maxTaskbarWidth.label")
                description: pluginApi?.tr("settings.maxTaskbarWidth.desc")
                from: 10
                to: 100
                stepSize: 5
                showReset: true
                value: root.valueMaxTaskbarWidth
                defaultValue: defaults.maxTaskbarWidth ?? 40
                onMoved: value => root.valueMaxTaskbarWidth = Math.round(value)
                text: Math.round(root.valueMaxTaskbarWidth) + "%"
            }

            NDivider {
                Layout.fillWidth: true
            }

            NHeading {
                label: pluginApi?.tr("settings.sections.typography.label")
                description: pluginApi?.tr("settings.sections.typography.desc")
            }

            NSearchableComboBox {
                visible: !root.isVerticalBar
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.titleFontFamily.label")
                description: pluginApi?.tr("settings.titleFontFamily.desc")
                model: FontService.availableFonts
                currentKey: root.valueTitleFontFamily
                placeholder: pluginApi?.tr("settings.titleFontFamily.placeholder")
                searchPlaceholder: pluginApi?.tr("settings.titleFontFamily.searchPlaceholder")
                popupHeight: 420
                defaultValue: defaults.titleFontFamily ?? ""
                onSelected: key => root.valueTitleFontFamily = key
            }

            NValueSlider {
                visible: !root.isVerticalBar
                Layout.fillWidth: true
                label: pluginApi?.tr("settings.titleFontScale.label")
                description: pluginApi?.tr("settings.titleFontScale.desc")
                from: 0.75
                to: 1.25
                stepSize: 0.01
                showReset: true
                value: root.valueTitleFontScale
                defaultValue: defaults.titleFontScale ?? 1.0
                onMoved: value => root.valueTitleFontScale = value
                text: Math.round(root.valueTitleFontScale * 100) + "%"
            }

                    NComboBox {
                        visible: !root.isVerticalBar
                        Layout.fillWidth: true
                        label: pluginApi?.tr("settings.titleFontWeight.label")
                        description: pluginApi?.tr("settings.titleFontWeight.desc")
                        model: root.titleFontWeightOptions
                        currentKey: root.valueTitleFontWeight
                        onSelected: key => root.valueTitleFontWeight = key
                        defaultValue: defaults.titleFontWeight ?? "medium"
                    }
                }
            }
        }

        Item {
            width: tabView.width
            height: tabView.height

            NScrollView {
                id: colorsScrollView
                anchors.fill: parent
                clip: true
                horizontalPolicy: ScrollBar.AlwaysOff
                reserveScrollbarSpace: false
                gradientColor: Color.mSurface

                ColumnLayout {
                    width: colorsScrollView.availableWidth
                    spacing: Style.marginM

                    NHeading {
                        label: pluginApi?.tr("settings.sections.itemColors.label")
                        description: pluginApi?.tr("settings.sections.itemColors.desc")
                    }

                Repeater {
                    model: root.itemColorStates

                    delegate: ColumnLayout {
                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        spacing: Style.marginS

                        SectionHeader {
                            label: modelData.label
                            description: modelData.description
                        }

                        NColorChoice {
                            label: pluginApi?.tr("settings.itemColors.background.label")
                            description: pluginApi?.tr("settings.itemColors.background.desc")
                            currentKey: root.getItemColor(modelData.key, "background")
                            onSelected: key => root.setItemColor(modelData.key, "background", key)
                            defaultValue: root.getDefaultItemColor(modelData.key, "background")
                        }

                        NValueSlider {
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.backgroundOpacity.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundOpacity.desc")
                            from: 0
                            to: 100
                            stepSize: 5
                            showReset: true
                            value: root.getItemStateValue(modelData.key, "backgroundOpacity")
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundOpacity")
                            onMoved: value => root.setItemStateValue(modelData.key, "backgroundOpacity", Math.round(value))
                            text: Math.round(root.getItemStateValue(modelData.key, "backgroundOpacity")) + "%"
                        }

                        NColorChoice {
                            label: pluginApi?.tr("settings.itemColors.border.label")
                            description: pluginApi?.tr("settings.itemColors.border.desc")
                            currentKey: root.getItemColor(modelData.key, "border")
                            onSelected: key => root.setItemColor(modelData.key, "border", key)
                            defaultValue: root.getDefaultItemColor(modelData.key, "border")
                        }

                        NValueSlider {
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.borderOpacity.label")
                            description: pluginApi?.tr("settings.itemColors.borderOpacity.desc")
                            from: 0
                            to: 100
                            stepSize: 5
                            showReset: true
                            value: root.getItemStateValue(modelData.key, "borderOpacity")
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "borderOpacity")
                            onMoved: value => root.setItemStateValue(modelData.key, "borderOpacity", Math.round(value))
                            text: Math.round(root.getItemStateValue(modelData.key, "borderOpacity")) + "%"
                        }

                        NColorChoice {
                            label: pluginApi?.tr("settings.itemColors.text.label")
                            description: pluginApi?.tr("settings.itemColors.text.desc")
                            currentKey: root.getItemColor(modelData.key, "text")
                            onSelected: key => root.setItemColor(modelData.key, "text", key)
                            defaultValue: root.getDefaultItemColor(modelData.key, "text")
                        }

                        NValueSlider {
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.textOpacity.label")
                            description: pluginApi?.tr("settings.itemColors.textOpacity.desc")
                            from: 0
                            to: 100
                            stepSize: 5
                            showReset: true
                            value: root.getItemStateValue(modelData.key, "textOpacity")
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "textOpacity")
                            onMoved: value => root.setItemStateValue(modelData.key, "textOpacity", Math.round(value))
                            text: Math.round(root.getItemStateValue(modelData.key, "textOpacity")) + "%"
                        }

                        NToggle {
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.backgroundGradientEnabled.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundGradientEnabled.desc")
                            checked: root.getItemStateValue(modelData.key, "backgroundGradientEnabled")
                            onToggled: checked => root.setItemStateValue(modelData.key, "backgroundGradientEnabled", checked)
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundGradientEnabled")
                        }

                        NComboBox {
                            visible: root.getItemStateValue(modelData.key, "backgroundGradientEnabled")
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.backgroundGradientDirection.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundGradientDirection.desc")
                            model: root.gradientDirectionOptions
                            currentKey: root.getItemStateValue(modelData.key, "backgroundGradientDirection")
                            onSelected: key => root.setItemStateValue(modelData.key, "backgroundGradientDirection", key)
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundGradientDirection")
                        }

                        NColorChoice {
                            visible: root.getItemStateValue(modelData.key, "backgroundGradientEnabled")
                            label: pluginApi?.tr("settings.itemColors.backgroundGradientStart.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundGradientStart.desc")
                            currentKey: root.getItemStateValue(modelData.key, "backgroundGradientStart")
                            onSelected: key => root.setItemStateValue(modelData.key, "backgroundGradientStart", key)
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundGradientStart")
                        }

                        NValueSlider {
                            visible: root.getItemStateValue(modelData.key, "backgroundGradientEnabled")
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.backgroundGradientStartOpacity.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundGradientStartOpacity.desc")
                            from: 0
                            to: 100
                            stepSize: 5
                            showReset: true
                            value: root.getItemStateValue(modelData.key, "backgroundGradientStartOpacity")
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundGradientStartOpacity")
                            onMoved: value => root.setItemStateValue(modelData.key, "backgroundGradientStartOpacity", Math.round(value))
                            text: Math.round(root.getItemStateValue(modelData.key, "backgroundGradientStartOpacity")) + "%"
                        }

                        NColorChoice {
                            visible: root.getItemStateValue(modelData.key, "backgroundGradientEnabled")
                            label: pluginApi?.tr("settings.itemColors.backgroundGradientEnd.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundGradientEnd.desc")
                            currentKey: root.getItemStateValue(modelData.key, "backgroundGradientEnd")
                            onSelected: key => root.setItemStateValue(modelData.key, "backgroundGradientEnd", key)
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundGradientEnd")
                        }

                        NValueSlider {
                            visible: root.getItemStateValue(modelData.key, "backgroundGradientEnabled")
                            Layout.fillWidth: true
                            label: pluginApi?.tr("settings.itemColors.backgroundGradientEndOpacity.label")
                            description: pluginApi?.tr("settings.itemColors.backgroundGradientEndOpacity.desc")
                            from: 0
                            to: 100
                            stepSize: 5
                            showReset: true
                            value: root.getItemStateValue(modelData.key, "backgroundGradientEndOpacity")
                            defaultValue: root.getDefaultItemStateValue(modelData.key, "backgroundGradientEndOpacity")
                            onMoved: value => root.setItemStateValue(modelData.key, "backgroundGradientEndOpacity", Math.round(value))
                            text: Math.round(root.getItemStateValue(modelData.key, "backgroundGradientEndOpacity")) + "%"
                        }

                        NDivider {
                            visible: index < root.itemColorStates.length - 1
                            Layout.fillWidth: true
                        }
                    }
                }
                }
            }
        }
    }

    NIconPicker {
        id: iconPicker
        initialIcon: root.valueWorkspaceSeparatorDividerIcon || "minus"
        onIconSelected: function (iconName) {
            root.valueWorkspaceSeparatorDividerIcon = iconName;
        }
    }

}
