pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./components"

ColumnLayout {
    id: root

    property var pluginApi: null
    readonly property var mainInstance: pluginApi?.mainInstance
    property real preferredWidth: 760 * Style.uiScaleRatio

    property var editSettings: JSON.parse(JSON.stringify(pluginApi?.pluginSettings ?? pluginApi?.manifest?.metadata?.defaultSettings ?? {}))
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    property int draggedProviderIndex: -1
    property var expandedProviders: ({})

    function tr(key, vars) {
        return root.pluginApi?.tr(key, vars);
    }

    readonly property var providerCatalog: ProviderCatalog {}
    readonly property var normalizedEditProviderOrder: providerCatalog.normalizeProviderOrder(root.editSettings?.providerOrder)

    readonly property var providerOrderModeOptions: [
        {
            "key": "manual",
            "name": root.tr("settings.summary.manual")
        },
        {
            "key": "recent7dChange",
            "name": root.tr("settings.summary.recent7dChange")
        }
    ]

    readonly property int enabledProviderCount: {
        var count = 0;
        var order = root.normalizedEditProviderOrder;
        for (var i = 0; i < order.length; i++) {
            var prov = root.providerSettingsFor(order[i]);
            if (prov.enabled ?? true)
                count++;
        }
        return count;
    }

    readonly property int shownInBarCount: {
        var count = 0;
        var order = root.normalizedEditProviderOrder;
        for (var i = 0; i < order.length; i++) {
            var prov = root.providerSettingsFor(order[i]);
            if ((prov.enabled ?? true) && (prov.showInWidget ?? true))
                count++;
        }
        return count;
    }

    function providerDisplayName(id) {
        return root.tr("providers.names." + id) || id;
    }

    function providerAuthLabel(id) {
        return root.tr("providers.auth." + id) || "";
    }

    function providerSettingsFor(id) {
        return root.editSettings?.providers?.[id] ?? ({});
    }

    function providerSupportsCodexbar(id) {
        return root.providerCatalog.supportsCodexbar(id);
    }

    function codexbarName(providerId) {
        return root.providerCatalog.codexbarName(providerId);
    }

    function ensureProviderSettings(id) {
        if (!root.editSettings)
            root.editSettings = {};
        if (!root.editSettings.providers)
            root.editSettings.providers = {};
        if (!root.editSettings.providers[id])
            root.editSettings.providers[id] = {};
        return root.editSettings.providers[id];
    }

    function updateProviderSetting(id, key, value) {
        const settings = Object.assign({}, root.editSettings ?? ({}));
        const providers = Object.assign({}, settings.providers ?? ({}));
        const provider = Object.assign({}, providers[id] ?? ({}));
        provider[key] = value;
        providers[id] = provider;
        settings.providers = providers;
        root.editSettings = settings;
    }

    function setProviderEnabled(id, value) {
        root.updateProviderSetting(id, "enabled", value);
    }

    function setProviderShownInBar(id, value) {
        root.updateProviderSetting(id, "showInWidget", value);
    }

    function setProviderUseCodexbar(id, value) {
        root.updateProviderSetting(id, "useCodexbar", value);
    }

    function isProviderExpanded(id) {
        return root.expandedProviders?.[id] ?? false;
    }

    function setProviderExpanded(id, value) {
        var next = Object.assign({}, root.expandedProviders);
        next[id] = value;
        root.expandedProviders = next;
    }

    function toggleProviderExpanded(id) {
        root.setProviderExpanded(id, !root.isProviderExpanded(id));
    }

    function moveProvider(fromIndex, toIndex) {
        var order = (root.normalizedEditProviderOrder).slice();
        if (fromIndex < 0 || fromIndex >= order.length || toIndex < 0 || toIndex >= order.length || fromIndex === toIndex)
            return;
        var moved = order[fromIndex];
        order.splice(fromIndex, 1);
        order.splice(toIndex, 0, moved);
        if (!root.editSettings)
            root.editSettings = {};
        root.editSettings.providerOrder = order;
        root.editSettingsChanged();
    }

    function barMetricLabel(value) {
        var key = String(value || "").trim();
        if (key === "tokens")
            return root.tr("settings.barMetrics.tokens");
        if (key === "usage")
            return root.tr("settings.barMetrics.usage");
        if (key === "usage5h")
            return root.tr("settings.barMetrics.usage5h");
        if (key === "usage5h7d")
            return root.tr("settings.barMetrics.usage5h7d");
        return root.tr("settings.barMetrics.prompts");
    }

    function saveSettings() {
        if (!pluginApi)
            return;
        const s = JSON.parse(JSON.stringify(root.editSettings ?? ({})));

        if (s.providerOrderMode !== "recent7dChange")
            s.providerOrderMode = "manual";
        s.recentChangeWidgetProviderLimit = Math.max(1, Math.min(root.normalizedEditProviderOrder.length,
            Number(s.recentChangeWidgetProviderLimit ?? root.normalizedEditProviderOrder.length)));
        if (s.barIconAlertWindow !== "usage5h")
            s.barIconAlertWindow = "usage7d";
        root.pluginApi.pluginSettings = s;
        root.pluginApi.saveSettings();
    }

    spacing: Style.marginXL
    implicitWidth: preferredWidth

    NLabel {
        Layout.fillWidth: true
        label: root.tr("settings.title")
        description: root.tr("settings.description")
        labelSize: Style.fontSizeXL
        icon: "settings"
        iconColor: Color.mPrimary
    }

    NTabBar {
        id: settingsTabBar
        Layout.fillWidth: true

        NTabButton {
            tabIndex: 0
            text: root.tr("settings.general.label")
            icon: "adjustments-horizontal"
            checked: settingsTabBar.currentIndex === 0
        }
        NTabButton {
            tabIndex: 1
            text: root.tr("settings.providers.label")
            icon: "plug-connected"
            checked: settingsTabBar.currentIndex === 1
        }
    }

    NTabView {
        Layout.fillWidth: true
        currentIndex: settingsTabBar.currentIndex

        NBox {
            Layout.fillWidth: true
            implicitHeight: generalColumn.implicitHeight + Style.marginXL * 2
            height: implicitHeight

            ColumnLayout {
                id: generalColumn
                anchors.fill: parent
                anchors.margins: Style.marginXL
                spacing: 0

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXL

                    NLabel {
                        Layout.fillWidth: true
                        label: root.tr("settings.barDisplay.label")
                        description: root.tr("settings.barDisplay.desc")
                        labelSize: Style.fontSizeXL
                        icon: "layout-navbar"
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: root.tr("settings.cycle.label")
                        description: root.tr("settings.cycle.desc")
                        checked: root.editSettings?.barCycleEnabled ?? false
                        onToggled: checked => {
                            root.editSettings.barCycleEnabled = checked;
                            root.editSettingsChanged();
                        }
                        defaultValue: root.defaults.barCycleEnabled ?? false
                    }

                    NSpinBox {
                        Layout.fillWidth: true
                        label: root.tr("settings.cycle.intervalLabel")
                        description: root.tr("settings.cycle.intervalDesc")
                        from: 2
                        to: 60
                        value: root.editSettings?.barCycleIntervalSec ?? 5
                        stepSize: 1
                        onValueChanged: root.editSettings.barCycleIntervalSec = value
                        defaultValue: root.defaults.barCycleIntervalSec ?? 5
                        visible: root.editSettings?.barCycleEnabled ?? false
                    }

                    NComboBox {
                        Layout.fillWidth: true
                        label: root.tr("settings.barMetric.label")
                        description: root.tr("settings.barMetric.desc")
                        model: [
                            {
                                "key": "prompts",
                                "name": root.tr("settings.barMetrics.prompts")
                            },
                            {
                                "key": "tokens",
                                "name": root.tr("settings.barMetrics.tokens")
                            },
                            {
                                "key": "usage",
                                "name": root.tr("settings.barMetrics.usage")
                            },
                            {
                                "key": "usage5h",
                                "name": root.tr("settings.barMetrics.usage5h")
                            },
                            {
                                "key": "usage5h7d",
                                "name": root.tr("settings.barMetrics.usage5h7d")
                            }
                        ]
                        currentKey: root.editSettings?.barMetric ?? "prompts"
                        onSelected: key => {
                            root.editSettings.barMetric = key;
                            root.editSettingsChanged();
                        }
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: root.tr("settings.hover.label")
                        description: root.tr("settings.hover.desc")
                        checked: root.editSettings?.barTextShowOnHover ?? false
                        onToggled: checked => {
                            root.editSettings.barTextShowOnHover = checked;
                            root.editSettingsChanged();
                        }
                        defaultValue: root.defaults.barTextShowOnHover ?? false
                    }
                }

                NDivider {
                    Layout.fillWidth: true
                    Layout.topMargin: Style.marginL
                    Layout.bottomMargin: Style.marginL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXL

                    NLabel {
                        Layout.fillWidth: true
                        label: root.tr("settings.usageDisplay.label")
                        description: root.tr("settings.usageDisplay.desc")
                        labelSize: Style.fontSizeXL
                        icon: "chart-pie"
                    }

                    NText {
                        visible: {
                            var metric = root.editSettings?.barMetric ?? "prompts";
                            return !(metric === "usage" || metric === "usage5h" || metric === "usage5h7d");
                        }
                        Layout.fillWidth: true
                        text: root.tr("settings.usageDisplay.nonUsage")
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.Wrap
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: root.tr("settings.usageDisplay.remainingLabel")
                        description: root.tr("settings.usageDisplay.remainingDesc")
                        enabled: {
                            var metric = root.editSettings?.barMetric ?? "prompts";
                            return metric === "usage" || metric === "usage5h" || metric === "usage5h7d";
                        }
                        checked: root.editSettings?.barShowRemaining ?? false
                        onToggled: checked => {
                            root.editSettings.barShowRemaining = checked;
                            root.editSettingsChanged();
                        }
                        defaultValue: root.defaults.barShowRemaining ?? false
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: root.tr("settings.iconAlert.label")
                        description: root.tr("settings.iconAlert.desc")
                        checked: root.editSettings?.barIconAlertOnLimit ?? false
                        onToggled: checked => {
                            root.editSettings.barIconAlertOnLimit = checked;
                            root.editSettingsChanged();
                        }
                        defaultValue: root.defaults.barIconAlertOnLimit ?? false
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: root.tr("settings.iconAlert.windowLabel")
                        description: root.tr("settings.iconAlert.windowDesc")
                        checked: (root.editSettings?.barIconAlertWindow ?? "usage7d") === "usage5h"
                        onToggled: checked => {
                            root.editSettings.barIconAlertWindow = checked ? "usage5h" : "usage7d";
                            root.editSettingsChanged();
                        }
                        defaultValue: (root.defaults.barIconAlertWindow ?? "usage7d") === "usage5h"
                    }

                    NSpinBox {
                        Layout.fillWidth: true
                        label: root.tr("settings.iconAlert.thresholdLabel")
                        description: (root.editSettings?.barIconAlertOnLimit ?? false) ? root.tr("settings.iconAlert.thresholdDescEnabled") : root.tr("settings.iconAlert.thresholdDescDisabled")
                        from: 50
                        to: 100
                        stepSize: 5
                        value: root.editSettings?.barIconAlertThreshold ?? 95
                        suffix: "%"
                        onValueChanged: root.editSettings.barIconAlertThreshold = value
                        defaultValue: root.defaults.barIconAlertThreshold ?? 95
                    }
                }

                NDivider {
                    Layout.fillWidth: true
                    Layout.topMargin: Style.marginL
                    Layout.bottomMargin: Style.marginL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXL

                    NLabel {
                        Layout.fillWidth: true
                        label: root.tr("settings.refresh.label")
                        description: root.tr("settings.refresh.desc")
                        labelSize: Style.fontSizeXL
                        icon: "refresh"
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: root.tr("settings.refresh.cacheLabel")
                        description: root.tr("settings.refresh.cacheDesc")
                        checked: root.editSettings?.includeCacheTokens ?? true
                        onToggled: checked => {
                            root.editSettings.includeCacheTokens = checked;
                            root.editSettingsChanged();
                        }
                        defaultValue: root.defaults.includeCacheTokens ?? true
                    }

                    NSpinBox {
                        Layout.fillWidth: true
                        label: root.tr("settings.refresh.intervalLabel")
                        description: root.tr("settings.refresh.intervalDesc")
                        from: 5
                        to: 300
                        value: root.editSettings?.refreshIntervalSec ?? 30
                        stepSize: 5
                        onValueChanged: root.editSettings.refreshIntervalSec = value
                        defaultValue: root.defaults.refreshIntervalSec ?? 30
                    }

                    NSpinBox {
                        Layout.fillWidth: true
                        label: root.tr("settings.refresh.apiIntervalLabel")
                        description: root.tr("settings.refresh.apiIntervalDesc")
                        from: 1
                        to: 360
                        value: root.editSettings?.apiRefreshIntervalMin ?? 1
                        stepSize: 1
                        suffix: root.tr("units.minutesShort")
                        onValueChanged: root.editSettings.apiRefreshIntervalMin = value
                        defaultValue: root.defaults.apiRefreshIntervalMin ?? 1
                    }
                }
            }
        }

        NBox {
            Layout.fillWidth: true
            implicitHeight: providersColumn.implicitHeight + Style.marginXL * 2
            height: implicitHeight

            ColumnLayout {
                id: providersColumn
                anchors.fill: parent
                anchors.margins: Style.marginXL
                spacing: Style.marginL

                NComboBox {
                    Layout.fillWidth: true
                    label: root.tr("settings.providers.orderLabel")
                    description: root.tr("settings.providers.orderDesc")
                    model: root.providerOrderModeOptions
                    currentKey: root.editSettings?.providerOrderMode ?? "manual"
                    onSelected: key => {
                        root.editSettings.providerOrderMode = key;
                        root.editSettingsChanged();
                    }
                }

                NText {
                    visible: root.editSettings?.providerOrderMode === "recent7dChange"
                    text: root.tr("settings.providers.recentHelp")
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                NSpinBox {
                    Layout.fillWidth: true
                    visible: root.editSettings?.providerOrderMode === "recent7dChange"
                    label: root.tr("settings.providers.recentLimitLabel")
                    description: root.tr("settings.providers.recentLimitDesc")
                    from: 1
                    to: root.normalizedEditProviderOrder.length
                    value: Math.max(1, Math.min(root.normalizedEditProviderOrder.length,
                        Number(root.editSettings?.recentChangeWidgetProviderLimit ?? root.normalizedEditProviderOrder.length)))
                    stepSize: 1
                    onValueChanged: root.editSettings.recentChangeWidgetProviderLimit = value
                    defaultValue: root.defaults.recentChangeWidgetProviderLimit ?? root.normalizedEditProviderOrder.length
                }

                NText {
                    text: root.tr("settings.providers.dragHelp")
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                Repeater {
                    model: root.normalizedEditProviderOrder

                    delegate: DropArea {
                        id: providerDropArea

                        required property int index
                        required property string modelData

                        Layout.fillWidth: true
                        implicitHeight: providerCard.implicitHeight

                        onEntered: function (drag) {
                            if (root.draggedProviderIndex < 0)
                                return;
                            if (root.draggedProviderIndex === providerDropArea.index)
                                return;
                            root.moveProvider(root.draggedProviderIndex, providerDropArea.index);
                            root.draggedProviderIndex = providerDropArea.index;
                        }

                        NBox {
                            id: providerCard
                            width: parent.width
                            implicitHeight: cardBody.implicitHeight + Style.marginL * 2

                            readonly property int providerIndex: providerDropArea.index
                            readonly property string providerId: String(providerDropArea.modelData || "")
                            readonly property var providerCfg: root.providerSettingsFor(providerId)
                            readonly property bool expanded: root.isProviderExpanded(providerId)
                            property bool dragging: dragHandleMouseArea.drag.active

                            Drag.active: dragging
                            Drag.source: providerCard
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                            Drag.keys: ["model-usage-provider"]
                            z: dragging ? 1000 : 0
                            scale: dragging ? 1.02 : 1.0
                            opacity: dragging ? 0.92 : 1.0

                            onDraggingChanged: {
                                if (dragging)
                                    root.draggedProviderIndex = providerCard.providerIndex;
                                if (!dragging && root.draggedProviderIndex === providerCard.providerIndex)
                                    root.draggedProviderIndex = -1;
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: Style.animationFast
                                }
                            }

                            ColumnLayout {
                                id: cardBody
                                anchors.fill: parent
                                anchors.margins: Style.marginL
                                spacing: Style.marginL

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Style.marginXL

                                    Item {
                                        Layout.preferredWidth: Style.fontSizeL + Style.marginS * 2
                                        Layout.preferredHeight: Style.fontSizeL + Style.marginS * 2

                                        NIcon {
                                            anchors.centerIn: parent
                                            icon: "grip-vertical"
                                            color: Color.mOnSurfaceVariant
                                        }

                                        MouseArea {
                                            id: dragHandleMouseArea
                                            anchors.fill: parent
                                            cursorShape: Qt.OpenHandCursor
                                            drag.target: providerCard
                                        }
                                    }

                                    ProviderVisual {
                                        Layout.alignment: Qt.AlignVCenter
                                        visualData: root.mainInstance?.providerVisualData(providerCard.providerId) ?? ({
                                                "source": "icon",
                                                "icon": "ai"
                                            })
                                        pointSize: Style.fontSizeL
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: Style.marginXS

                                        NText {
                                            text: root.providerDisplayName(providerCard.providerId)
                                            pointSize: Style.fontSizeM
                                            font.weight: Style.fontWeightSemiBold
                                            color: Color.mOnSurface
                                        }

                                        NText {
                                            text: root.providerAuthLabel(providerCard.providerId)
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 90 * Style.uiScaleRatio
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: Style.marginXS

                                        NToggle {
                                            Layout.alignment: Qt.AlignHCenter
                                            checked: providerCard.providerCfg.enabled ?? true
                                            onToggled: value => root.setProviderEnabled(providerCard.providerId, value)
                                        }

                                        NText {
                                            Layout.alignment: Qt.AlignHCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            text: root.tr("settings.providers.enable")
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.preferredWidth: 110 * Style.uiScaleRatio
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: Style.marginXS

                                        NToggle {
                                            Layout.alignment: Qt.AlignHCenter
                                            checked: providerCard.providerCfg.showInWidget ?? true
                                            onToggled: value => root.setProviderShownInBar(providerCard.providerId, value)
                                        }

                                        NText {
                                            Layout.alignment: Qt.AlignHCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            text: root.tr("settings.providers.showInBar")
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                        }
                                    }

                                    Item {
                                        Layout.preferredWidth: Style.marginM
                                    }

                                    NButton {
                                        Layout.preferredWidth: 140 * Style.uiScaleRatio
                                        text: providerCard.expanded ? root.tr("settings.providers.hideDetails") : root.tr("settings.providers.configure")
                                        outlined: true
                                        onClicked: root.toggleProviderExpanded(providerCard.providerId)
                                    }
                                }

                                NText {
                                    visible: !providerCard.expanded
                                    text: providerCard.providerCfg.enabled ?? true ? root.tr("settings.providers.enabledSummary") : root.tr("settings.providers.disabledSummary")
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                ColumnLayout {
                                    visible: providerCard.expanded
                                    Layout.fillWidth: true
                                    Layout.leftMargin: Style.marginXL * 2
                                    spacing: Style.marginL

                                    NLabel {
                                        Layout.fillWidth: true
                                        label: root.tr("settings.providers.detailsLabel")
                                        description: root.tr("settings.providers.detailsDesc", {
                                            "provider": root.providerDisplayName(providerCard.providerId)
                                        })
                                        labelSize: Style.fontSizeL
                                        icon: "settings-2"
                                    }

                                    ColumnLayout {
                                        id: codexbarSection
                                        visible: root.providerSupportsCodexbar(providerCard.providerId)
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        property string checkState: "idle"
                                        property string checkError: ""

                                        CodexbarFetcher {
                                            id: codexbarChecker
                                            codexbarProvider: root.codexbarName(providerCard.providerId)
                                            onDataReady: _ => {
                                                if (providerCard.providerCfg.useCodexbar)
                                                    codexbarSection.checkState = "ok";
                                            }
                                            onFetchError: message => {
                                                if (providerCard.providerCfg.useCodexbar) {
                                                    codexbarSection.checkState = "error";
                                                    codexbarSection.checkError = message;
                                                }
                                            }
                                        }

                                        NToggle {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.codexbar.label")
                                            description: root.tr("settings.codexbar.desc")
                                            checked: providerCard.providerCfg.useCodexbar ?? false
                                            onToggled: checked => {
                                                root.setProviderUseCodexbar(providerCard.providerId, checked);
                                                if (checked) {
                                                    codexbarSection.checkState = "running";
                                                    codexbarSection.checkError = "";
                                                    codexbarChecker.fetch();
                                                } else {
                                                    codexbarSection.checkState = "idle";
                                                }
                                            }
                                            defaultValue: root.defaults.providers?.[providerCard.providerId]?.useCodexbar ?? false
                                        }

                                        RowLayout {
                                            visible: codexbarSection.checkState !== "idle"
                                            Layout.fillWidth: true
                                            spacing: Style.marginS

                                            NText {
                                                visible: codexbarSection.checkState === "running"
                                                text: root.tr("settings.codexbar.checking")
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                            }

                                            NIcon {
                                                visible: codexbarSection.checkState === "ok"
                                                icon: "check"
                                                color: Color.mPrimary
                                            }

                                            NText {
                                                visible: codexbarSection.checkState === "ok"
                                                text: root.tr("settings.codexbar.ok")
                                                pointSize: Style.fontSizeXS
                                                color: Color.mPrimary
                                            }

                                            NIcon {
                                                visible: codexbarSection.checkState === "error"
                                                icon: "x"
                                                color: Color.mError
                                            }

                                            NText {
                                                visible: codexbarSection.checkState === "error"
                                                Layout.fillWidth: true
                                                text: codexbarSection.checkError
                                                pointSize: Style.fontSizeXS
                                                color: Color.mError
                                                wrapMode: Text.Wrap
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        visible: providerCard.providerId === "codex" && (providerCard.providerCfg.enabled ?? true)
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NComboBox {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.codex.sourceLabel")
                                            description: root.tr("settings.codex.sourceDesc")
                                            model: [
                                                {
                                                    "key": "local",
                                                    "name": root.tr("settings.codex.local")
                                                },
                                                {
                                                    "key": "api",
                                                    "name": root.tr("settings.codex.api")
                                                }
                                            ]
                                            currentKey: providerCard.providerCfg.usageMode ?? "local"
                                            onSelected: function (key) {
                                                root.ensureProviderSettings("codex").usageMode = key;
                                                root.editSettingsChanged();
                                            }
                                        }

                                        NText {
                                            text: providerCard.providerCfg.usageMode === "api" ? root.tr("settings.codex.apiHelp") : root.tr("settings.codex.localHelp")
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                            wrapMode: Text.Wrap
                                            Layout.fillWidth: true
                                        }
                                    }

                                    ColumnLayout {
                                        visible: providerCard.providerId === "openrouter"
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NTextInput {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.apiKey.openrouterLabel")
                                            description: root.tr("settings.apiKey.openrouterDesc")
                                            placeholderText: root.tr("settings.apiKey.openrouterPlaceholder")
                                            text: providerCard.providerCfg.apiKey ?? ""
                                            onTextChanged: root.ensureProviderSettings("openrouter").apiKey = text
                                        }
                                    }

                                    ColumnLayout {
                                        visible: providerCard.providerId === "zen"
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NTextInput {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.apiKey.zenLabel")
                                            description: root.tr("settings.apiKey.zenDesc")
                                            placeholderText: root.tr("settings.apiKey.zenPlaceholder")
                                            text: providerCard.providerCfg.apiKey ?? ""
                                            onTextChanged: root.ensureProviderSettings("zen").apiKey = text
                                        }
                                    }

                                    ColumnLayout {
                                        visible: providerCard.providerId === "deepseek"
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NTextInput {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.apiKey.deepseekLabel")
                                            description: root.tr("settings.apiKey.deepseekDesc")
                                            placeholderText: root.tr("settings.apiKey.deepseekPlaceholder")
                                            text: providerCard.providerCfg.apiKey ?? ""
                                            onTextChanged: root.ensureProviderSettings("deepseek").apiKey = text
                                        }
                                    }

                                    ColumnLayout {
                                        visible: providerCard.providerId === "kilocode"
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NTextInput {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.apiKey.kilocodeLabel")
                                            description: root.tr("settings.apiKey.kilocodeDesc")
                                            placeholderText: root.tr("settings.apiKey.kilocodePlaceholder")
                                            text: providerCard.providerCfg.apiKey ?? ""
                                            onTextChanged: root.ensureProviderSettings("kilocode").apiKey = text
                                        }
                                    }

                                    ColumnLayout {
                                        visible: providerCard.providerId === "zai"
                                        Layout.fillWidth: true
                                        spacing: Style.marginS

                                        NTextInput {
                                            Layout.fillWidth: true
                                            label: root.tr("settings.apiKey.zaiLabel")
                                            description: root.tr("settings.apiKey.zaiDesc")
                                            placeholderText: root.tr("settings.apiKey.zaiPlaceholder")
                                            text: providerCard.providerCfg.apiKey ?? ""
                                            onTextChanged: root.ensureProviderSettings("zai").apiKey = text
                                        }
                                    }

                                    NText {
                                        visible: !root.providerSupportsCodexbar(providerCard.providerId) && providerCard.providerId !== "deepseek"
                                        text: root.tr("settings.providers.noAdditional")
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginL

        NText {
            Layout.fillWidth: true
            text: root.tr("settings.footerHelp")
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
        }

        NButton {
            text: root.tr("settings.reset")
            outlined: true
            onClicked: {
                root.editSettings = JSON.parse(JSON.stringify(root.pluginApi?.manifest?.metadata?.defaultSettings ?? {}));
                root.expandedProviders = ({});
            }
        }
    }
}
