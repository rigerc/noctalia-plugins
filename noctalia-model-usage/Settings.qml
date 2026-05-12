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
    property int draggedProviderIndex: -1
    property var expandedProviders: ({})

    readonly property var defaultProviderOrder: ["claude", "codex", "copilot", "openrouter", "zen", "deepseek", "kilocode", "zai", "gemini"]
    readonly property var codexbarProviderIds: ["claude", "codex", "copilot", "openrouter", "zen", "kilocode", "zai", "gemini"]

    readonly property var normalizedEditProviderOrder: {
        const saved = root.editSettings?.providerOrder;
        const source = Array.isArray(saved) ? saved : [];
        const result = [];
        const seen = {};
        for (const rawId of source) {
            const id = String(rawId || "");
            if (root.defaultProviderOrder.indexOf(id) !== -1 && !seen[id]) {
                result.push(id);
                seen[id] = true;
            }
        }
        for (const id of root.defaultProviderOrder) {
            if (!seen[id])
                result.push(id);
        }
        return result;
    }

    readonly property var providerOrderModeOptions: [
        {
            "key": "manual",
            "name": "Manual order"
        },
        {
            "key": "recent7dChange",
            "name": "Recently changed 7d usage"
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
        var names = {
            "claude": "Claude Code",
            "codex": "Codex",
            "copilot": "Copilot",
            "openrouter": "OpenRouter",
            "zen": "Zen (opencode.ai)",
            "deepseek": "DeepSeek",
            "kilocode": "Kilo Code",
            "zai": "Z.ai",
            "gemini": "Gemini"
        };
        return names[id] || id;
    }

    function providerAuthLabel(id) {
        var labels = {
            "claude": "Local files + OAuth",
            "codex": "Local files or API",
            "copilot": "GitHub auth",
            "openrouter": "API key",
            "zen": "API key",
            "deepseek": "API key",
            "kilocode": "API key or kilo login",
            "zai": "API key",
            "gemini": "Local OAuth"
        };
        return labels[id] || "";
    }

    function providerSettingsFor(id) {
        return root.editSettings?.providers?.[id] ?? ({});
    }

    function providerSupportsCodexbar(id) {
        return root.codexbarProviderIds.indexOf(String(id || "")) !== -1;
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

    function normalizeBarMetricKey(value) {
        var raw = String(value || "").trim();
        if (raw === "usage24h") return "usage5h";
        if (raw === "usage24h7d") return "usage5h7d";
        return raw;
    }

    function barMetricLabel(value) {
        var key = root.normalizeBarMetricKey(value);
        if (key === "tokens")
            return "Tokens";
        if (key === "usage")
            return "Usage % 7d";
        if (key === "usage5h")
            return "Usage % 5h";
        if (key === "usage5h7d")
            return "Usage % 5h/7d";
        return "Prompts";
    }

    function saveSettings() {
        if (root.editSettings?.barMetric)
            root.editSettings.barMetric = root.normalizeBarMetricKey(root.editSettings.barMetric);
        if (root.editSettings?.providerOrderMode !== "recent7dChange")
            root.editSettings.providerOrderMode = "manual";
        if (root.editSettings?.barIconAlertWindow !== "usage5h")
            root.editSettings.barIconAlertWindow = "usage7d";
        root.pluginApi.pluginSettings = JSON.parse(JSON.stringify(root.editSettings));
        root.pluginApi.saveSettings();
    }

    spacing: Style.marginXL
    implicitWidth: preferredWidth

    NLabel {
        Layout.fillWidth: true
        label: "Model Usage Settings"
        description: "Configure how usage appears in the bar, how providers are refreshed, and which providers are enabled or visible."
        labelSize: Style.fontSizeXL
        icon: "settings"
        iconColor: Color.mPrimary
    }

    NBox {
        Layout.fillWidth: true
        implicitHeight: summaryBody.implicitHeight + Style.marginXL * 2

        ColumnLayout {
            id: summaryBody
            anchors.fill: parent
            anchors.margins: Style.marginXL
            spacing: Style.marginL

            NLabel {
                Layout.fillWidth: true
                label: "Overview"
                description: "Quick summary of the current configuration before you adjust the details below."
                labelSize: Style.fontSizeL
            }

            Flow {
                Layout.fillWidth: true
                spacing: Style.marginM

                Repeater {
                    model: [
                        { "label": "Enabled", "value": String(root.enabledProviderCount) },
                        { "label": "Shown in bar", "value": String(root.shownInBarCount) },
                        { "label": "Bar metric", "value": root.barMetricLabel(root.editSettings?.barMetric ?? "prompts") },
                        { "label": "Order mode", "value": (root.editSettings?.providerOrderMode ?? "manual") === "recent7dChange" ? "Recent 7d change" : "Manual" }
                    ]

                    delegate: NBox {
                        id: summaryChip
                        required property var modelData
                        implicitHeight: chipContent.implicitHeight + Style.marginS * 2
                        implicitWidth: Math.max(140 * Style.uiScaleRatio, chipContent.implicitWidth + Style.marginM * 2)

                        ColumnLayout {
                            id: chipContent
                            anchors.fill: parent
                            anchors.margins: Style.marginS
                            spacing: 0

                            NText {
                                text: summaryChip.modelData.label
                                pointSize: Style.fontSizeXS
                                color: Color.mOnSurfaceVariant
                            }

                            NText {
                                text: summaryChip.modelData.value
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mOnSurface
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        implicitHeight: generalColumn.implicitHeight + Style.marginXL * 2

        ColumnLayout {
            id: generalColumn
            anchors.fill: parent
            anchors.margins: Style.marginXL
            spacing: Style.marginXL * 2

            NLabel {
                Layout.fillWidth: true
                label: "General"
                description: "These settings control the overall behavior of the bar widget and how provider data is refreshed."
                labelSize: Style.fontSizeL
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXL

                NLabel {
                    Layout.fillWidth: true
                    label: "Bar display"
                    description: "Choose what the bar shows and how it behaves when multiple providers are available."
                    labelSize: Style.fontSizeM
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginL

                    NToggle {
                        checked: root.editSettings?.barCycleEnabled ?? false
                        onToggled: value => {
                            root.editSettings.barCycleEnabled = value;
                            root.editSettingsChanged();
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Cycle through providers"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                        }
                        NText {
                            text: "When enabled, the bar shows one provider at a time and rotates through them. When disabled, all visible providers are shown together in the bar."
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.editSettings?.barCycleEnabled ?? false
                    spacing: Style.marginS

                    NText {
                        text: "Cycle interval (seconds)"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                    }

                    NText {
                        Layout.fillWidth: true
                        text: "How often the bar moves to the next provider while cycling is enabled."
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.Wrap
                    }

                    NSpinBox {
                        from: 2
                        to: 60
                        value: root.editSettings?.barCycleIntervalSec ?? 5
                        stepSize: 1
                        onValueChanged: root.editSettings.barCycleIntervalSec = value
                    }
                }

                NComboBox {
                    Layout.fillWidth: true
                    label: "Bar metric"
                    description: "Choose the number or percentage shown next to each provider in the bar."
                    model: [
                        { "key": "prompts", "name": "Prompts" },
                        { "key": "tokens", "name": "Tokens" },
                        { "key": "usage", "name": "Usage % 7d" },
                        { "key": "usage5h", "name": "Usage % 5h" },
                        { "key": "usage5h7d", "name": "Usage % 5h/7d" }
                    ]
                    currentKey: root.normalizeBarMetricKey(root.editSettings?.barMetric ?? "prompts")
                    onSelected: key => {
                        root.editSettings.barMetric = key;
                        root.editSettingsChanged();
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginL

                    NToggle {
                        checked: root.editSettings?.barTextShowOnHover ?? false
                        onToggled: value => {
                            root.editSettings.barTextShowOnHover = value;
                            root.editSettingsChanged();
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Show text on hover"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                        }
                        NText {
                            text: "When enabled, the bar defaults to icons and reveals the metric text when you hover over the widget. This is useful when you want a more compact bar."
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginM
                Layout.bottomMargin: Style.marginM
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXL

                NLabel {
                    Layout.fillWidth: true
                    label: "Usage display"
                    description: "These options are most relevant when the selected bar metric shows a usage percentage, but icon alerts can still be configured here at any time."
                    labelSize: Style.fontSizeM
                }

                NText {
                    visible: {
                        var metric = root.editSettings?.barMetric ?? "prompts";
                        return !(metric === "usage" || metric === "usage5h" || metric === "usage5h7d");
                    }
                    Layout.fillWidth: true
                    text: "You are currently showing a non-usage bar metric, so the remaining-percentage option will not affect the bar right now."
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginL
                    enabled: {
                        var metric = root.editSettings?.barMetric ?? "prompts";
                        return metric === "usage" || metric === "usage5h" || metric === "usage5h7d";
                    }

                    NToggle {
                        checked: root.editSettings?.barShowRemaining ?? false
                        onToggled: value => {
                            root.editSettings.barShowRemaining = value;
                            root.editSettingsChanged();
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Show remaining % instead of used %"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                        }
                        NText {
                            text: "Switches usage metrics from consumed percentage to remaining percentage. For example, 80% used becomes 20% remaining."
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginL

                    NToggle {
                        checked: root.editSettings?.barIconAlertOnLimit ?? false
                        onToggled: value => {
                            root.editSettings.barIconAlertOnLimit = value;
                            root.editSettingsChanged();
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Color icon red on rate limit reached"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                        }
                        NText {
                            text: "Highlights provider icons when their usage crosses the alert threshold. This makes approaching limits easier to notice in the bar at a glance."
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginL

                    NToggle {
                        checked: (root.editSettings?.barIconAlertWindow ?? "usage7d") === "usage5h"
                        onToggled: value => {
                            root.editSettings.barIconAlertWindow = value ? "usage5h" : "usage7d";
                            root.editSettingsChanged();
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Use 5h window for icon alerts"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                        }

                        NText {
                            text: "Off uses the 7d usage window. On uses the 5h usage window. Providers without the selected window will not alert."
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NText {
                        text: "Alert threshold (%)"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                    }

                    NText {
                        Layout.fillWidth: true
                        text: (root.editSettings?.barIconAlertOnLimit ?? false)
                            ? "The selected window's used percentage at which the provider icon switches to the warning color."
                            : "This threshold is saved now and will take effect when icon alerts are enabled."
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.Wrap
                    }

                    NSpinBox {
                        from: 50
                        to: 100
                        stepSize: 5
                        value: root.editSettings?.barIconAlertThreshold ?? 95
                        suffix: "%"
                        onValueChanged: root.editSettings.barIconAlertThreshold = value
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
                Layout.topMargin: Style.marginM
                Layout.bottomMargin: Style.marginM
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXL

                NLabel {
                    Layout.fillWidth: true
                    label: "Refresh behavior"
                    description: "Control how often local files are polled and how frequently API-backed providers are refreshed."
                    labelSize: Style.fontSizeM
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginL

                    NToggle {
                        checked: root.editSettings?.includeCacheTokens ?? true
                        onToggled: value => {
                            root.editSettings.includeCacheTokens = value;
                            root.editSettingsChanged();
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Include cache tokens in token count"
                            pointSize: Style.fontSizeM
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                        }
                        NText {
                            text: "Counts cache read and cache write tokens in totals wherever the provider exposes them. Disable this if you want to focus only on direct input and output tokens."
                            pointSize: Style.fontSizeXS
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.Wrap
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NText {
                        text: "Refresh interval (seconds)"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                    }

                    NText {
                        Layout.fillWidth: true
                        text: "Fallback polling interval for local file-based providers when file watching does not catch an update."
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.Wrap
                    }

                    NSpinBox {
                        from: 5
                        to: 300
                        value: root.editSettings?.refreshIntervalSec ?? 30
                        stepSize: 5
                        onValueChanged: root.editSettings.refreshIntervalSec = value
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NText {
                        text: "API providers refresh interval"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                    }

                    NText {
                        Layout.fillWidth: true
                        text: "How often to poll API-backed providers such as Codex API mode, OpenRouter, Zen, Kilo Code, Z.ai, and Gemini."
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.Wrap
                    }

                    NSpinBox {
                        from: 1
                        to: 360
                        value: root.editSettings?.apiRefreshIntervalMin ?? 1
                        stepSize: 1
                        suffix: "min"
                        onValueChanged: root.editSettings.apiRefreshIntervalMin = value
                    }
                }
            }
        }
    }

    NBox {
        Layout.fillWidth: true
        implicitHeight: providersColumn.implicitHeight + Style.marginXL * 2

        ColumnLayout {
            id: providersColumn
            anchors.fill: parent
            anchors.margins: Style.marginXL
            spacing: Style.marginL

            NLabel {
                Layout.fillWidth: true
                label: "Providers"
                description: "Enable providers, choose which ones appear in the bar, and configure provider-specific details when needed."
                labelSize: Style.fontSizeL
            }

            NComboBox {
                Layout.fillWidth: true
                label: "Provider order"
                description: "Manual order is used directly, or as a tie-breaker when sorting by recently changed 7d usage."
                model: root.providerOrderModeOptions
                currentKey: root.editSettings?.providerOrderMode ?? "manual"
                onSelected: key => {
                    root.editSettings.providerOrderMode = key;
                    root.editSettingsChanged();
                }
            }

            NText {
                visible: root.editSettings?.providerOrderMode === "recent7dChange"
                text: "Providers whose 7d usage percentage changed most recently move to the front. Providers without 7d usage stay in your manual drag order. This recent-change history resets when the shell restarts."
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            NDivider { Layout.fillWidth: true }

            NText {
                text: "Drag providers to set the manual order. The manual order also acts as the tie-break order when recent 7d change sorting is enabled."
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

                    onEntered: function(drag) {
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
                            NumberAnimation { duration: Style.animationFast }
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
                                        text: "Enable"
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
                                        text: "Show in bar"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                Item {
                                    Layout.preferredWidth: Style.marginM
                                }

                                NButton {
                                    Layout.preferredWidth: 140 * Style.uiScaleRatio
                                    text: providerCard.expanded ? "Hide details" : "Configure"
                                    outlined: true
                                    onClicked: root.toggleProviderExpanded(providerCard.providerId)
                                }
                            }

                            NText {
                                visible: !providerCard.expanded
                                text: providerCard.providerCfg.enabled ?? true
                                    ? "Enabled. Open details to configure provider-specific settings."
                                    : "Disabled. Enable this provider if you want the plugin to collect and display its usage."
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

                                NDivider { Layout.fillWidth: true }

                                NLabel {
                                    Layout.fillWidth: true
                                    label: "Provider details"
                                    description: "These options only affect " + root.providerDisplayName(providerCard.providerId) + "."
                                    labelSize: Style.fontSizeM
                                }

                                ColumnLayout {
                                    visible: root.providerSupportsCodexbar(providerCard.providerId)
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Style.marginL

                                        NToggle {
                                            checked: providerCard.providerCfg.useCodexbar ?? false
                                            onToggled: value => root.setProviderUseCodexbar(providerCard.providerId, value)
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: Style.marginXS

                                            NText {
                                                text: root.pluginApi?.tr("settings.codexbar.label")
                                                pointSize: Style.fontSizeM
                                                font.weight: Style.fontWeightSemiBold
                                                color: Color.mOnSurface
                                            }

                                            NText {
                                                text: root.pluginApi?.tr("settings.codexbar.desc")
                                                pointSize: Style.fontSizeXS
                                                color: Color.mOnSurfaceVariant
                                                wrapMode: Text.Wrap
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }

                                    NDivider { Layout.fillWidth: true }
                                }

                                ColumnLayout {
                                    visible: providerCard.providerId === "codex" && (providerCard.providerCfg.enabled ?? true)
                                    Layout.fillWidth: true
                                    spacing: Style.marginS

                                    NComboBox {
                                        Layout.fillWidth: true
                                        label: "Data source"
                                        description: "Choose whether Codex usage is read from local files or from the ChatGPT backend API."
                                        model: [
                                            { "key": "local", "name": "Local files" },
                                            { "key": "api", "name": "API" }
                                        ]
                                        currentKey: providerCard.providerCfg.usageMode ?? "local"
                                        onSelected: function(key) {
                                            root.ensureProviderSettings("codex").usageMode = key;
                                            root.editSettingsChanged();
                                        }
                                    }

                                    NText {
                                        text: providerCard.providerCfg.usageMode === "api"
                                            ? "API mode reads from the ChatGPT backend using auth from ~/.codex/auth.json. Use this when local files are unavailable or incomplete."
                                            : "Local mode reads from ~/.codex/ files such as history.jsonl and sessions. This avoids remote polling when the local data is sufficient."
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
                                        label: "OpenRouter API key"
                                        description: "You can leave this empty if OPENROUTER_API_KEY is already set in your environment."
                                        placeholderText: "OPENROUTER_API_KEY env var or enter key here"
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
                                        label: "Zen API key"
                                        description: "You can leave this empty if OPENCODE_ZEN_API_KEY or OPENCODE_API_KEY is already set in your environment."
                                        placeholderText: "OPENCODE_ZEN_API_KEY / OPENCODE_API_KEY env var or enter key here"
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
                                        label: "DeepSeek API key"
                                        description: "You can leave this empty if DEEPSEEK_API_KEY is already set in your environment."
                                        placeholderText: "DEEPSEEK_API_KEY env var or enter key here"
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
                                        label: "Kilo Code API key"
                                        description: "You can leave this empty if KILO_API_KEY is set in your environment, or if you have authenticated via kilo login."
                                        placeholderText: "KILO_API_KEY env var or enter key here"
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
                                        label: "Z.ai API key"
                                        description: "You can leave this empty if Z_AI_API_KEY is already set in your environment."
                                        placeholderText: "Z_AI_API_KEY env var or enter key here"
                                        text: providerCard.providerCfg.apiKey ?? ""
                                        onTextChanged: root.ensureProviderSettings("zai").apiKey = text
                                    }
                                }

                                NText {
                                    visible: !root.providerSupportsCodexbar(providerCard.providerId)
                                        && providerCard.providerId !== "codex"
                                        && providerCard.providerId !== "openrouter"
                                        && providerCard.providerId !== "zen"
                                        && providerCard.providerId !== "deepseek"
                                        && providerCard.providerId !== "kilocode"
                                        && providerCard.providerId !== "zai"
                                    text: "This provider does not currently expose additional settings in the panel. Its usage data will follow the general display and refresh settings above."
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

    Item {
        Layout.fillHeight: true
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginL

        NText {
            Layout.fillWidth: true
            text: "Use Reset to restore manifest defaults. Save is handled by Noctalia when you apply settings."
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
        }

        NButton {
            text: "Reset to defaults"
            outlined: true
            onClicked: {
                root.editSettings = JSON.parse(JSON.stringify(root.pluginApi?.manifest?.metadata?.defaultSettings ?? {}));
                root.expandedProviders = ({});
            }
        }
    }
}
