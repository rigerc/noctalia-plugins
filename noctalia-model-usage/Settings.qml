import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./components"

ColumnLayout {
    id: root

    property var pluginApi: null
    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property color sectionBackgroundColor: Color.mSurfaceVariant

    property var editSettings: JSON.parse(JSON.stringify(pluginApi?.pluginSettings ?? pluginApi?.manifest?.metadata?.defaultSettings ?? {}))

    property int draggedProviderIndex: -1
    readonly property var defaultProviderOrder: ["claude", "codex", "copilot", "openrouter", "zen", "deepseek"]

    function providerDisplayName(id) {
        var names = {
            "claude": "Claude Code",
            "codex": "Codex",
            "copilot": "Copilot",
            "openrouter": "OpenRouter",
            "zen": "Zen (opencode.ai)",
            "deepseek": "DeepSeek"
        };
        return names[id] || id;
    }

    function providerAuthLabel(id) {
        var labels = {
            "claude": "Local files",
            "copilot": "GitHub auth",
            "openrouter": "API key",
            "zen": "API key",
            "deepseek": "API key"
        };
        return labels[id] || "";
    }

    function moveProvider(fromIndex, toIndex) {
        var order = (editSettings?.providerOrder || defaultProviderOrder).slice();
        if (fromIndex < 0 || fromIndex >= order.length || toIndex < 0 || toIndex >= order.length || fromIndex === toIndex)
            return;
        var moved = order[fromIndex];
        order.splice(fromIndex, 1);
        order.splice(toIndex, 0, moved);
        if (!editSettings)
            editSettings = {};
        editSettings.providerOrder = order;
        editSettingsChanged();
    }

    function normalizeBarMetricKey(value) {
        var raw = String(value || "").trim();
        if (raw === "usage24h") return "usage5h";
        if (raw === "usage24h7d") return "usage5h7d";
        return raw;
    }

    function saveSettings() {
        // Normalize old barMetric keys before saving
        if (root.editSettings?.barMetric) {
            root.editSettings.barMetric = root.normalizeBarMetricKey(root.editSettings.barMetric);
        }
        pluginApi.pluginSettings = JSON.parse(JSON.stringify(root.editSettings));
        pluginApi.saveSettings();
    }

    spacing: Style.marginL

    NText {
        text: "Model Usage Settings"
        pointSize: Style.fontSizeXL
        font.weight: Style.fontWeightBold
        color: Color.mOnSurface
        Layout.fillWidth: true
    }

    Rectangle {
        Layout.fillWidth: true
        color: root.sectionBackgroundColor
        radius: Style.radiusS
        implicitHeight: generalColumn.implicitHeight + Style.marginXL

        ColumnLayout {
            id: generalColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginL
            }
            spacing: Style.marginM

            NText {
                text: "General"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: Color.mPrimary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NToggle {
                    checked: editSettings?.barCycleEnabled ?? false
                    onToggled: value => {
                        editSettings.barCycleEnabled = value;
                        editSettingsChanged();
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginXS

                    NText {
                        text: "Cycle through providers"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                    }
                    NText {
                        text: "When off, all providers are shown at once in the bar"
                        pointSize: Style.fontSizeXS
                        color: Color.mOnSurfaceVariant
                    }
                }
            }

            ColumnLayout {
                visible: editSettings?.barCycleEnabled ?? false
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "Cycle interval (seconds)"
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }

                NSpinBox {
                    from: 2
                    to: 60
                    value: editSettings?.barCycleIntervalSec ?? 5
                    stepSize: 1
                    onValueChanged: {
                        editSettings.barCycleIntervalSec = value;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "Bar metric"
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }
                NText {
                    text: "What number to show in the bar capsule"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                NComboBox {
                    Layout.fillWidth: true
                    model: [
                        {
                            key: "prompts",
                            name: "Prompts"
                        },
                        {
                            key: "tokens",
                            name: "Tokens"
                        },
                        {
                            key: "usage",
                            name: "Usage % 7d"
                        },
                        {
                            key: "usage5h",
                            name: "Usage % 5h"
                        },
                        {
                            key: "usage5h7d",
                            name: "Usage % 5h/7d"
                        }
                    ]
                    currentKey: root.normalizeBarMetricKey(editSettings?.barMetric ?? "prompts")
                    onSelected: key => {
                        editSettings.barMetric = key;
                        editSettingsChanged();
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginS
                visible: {
                    var metric = editSettings?.barMetric ?? "prompts";
                    return metric === "usage" || metric === "usage5h" || metric === "usage5h7d";
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM
                    NToggle {
                        checked: editSettings?.barShowRemaining ?? false
                        onToggled: value => {
                            editSettings.barShowRemaining = value;
                            editSettingsChanged();
                        }
                    }
                    NText {
                        text: "Show remaining % instead of used %"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM
                    NToggle {
                        checked: editSettings?.barIconAlertOnLimit ?? false
                        onToggled: value => {
                            editSettings.barIconAlertOnLimit = value;
                            editSettingsChanged();
                        }
                    }
                    NText {
                        text: "Color icon red on rate limit reached"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }
                }

                NSpinBox {
                    Layout.fillWidth: true
                    visible: editSettings?.barIconAlertOnLimit ?? false
                    label: "Alert threshold (%)"
                    description: "Percentage used at which the icon turns red"
                    from: 50
                    to: 100
                    stepSize: 5
                    value: editSettings?.barIconAlertThreshold ?? 95
                    suffix: "%"
                    onValueChanged: {
                        editSettings.barIconAlertThreshold = value;
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM
                    NToggle {
                        checked: editSettings?.barTextShowOnHover ?? false
                        onToggled: value => {
                            editSettings.barTextShowOnHover = value;
                            editSettingsChanged();
                        }
                    }
                    NText {
                        text: "Show text on hover"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }
                }
                NText {
                    text: "When enabled, only the icon is shown by default and the metric text appears when you hover over the widget"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginM
                    NToggle {
                        checked: editSettings?.includeCacheTokens ?? true
                        onToggled: value => {
                            editSettings.includeCacheTokens = value;
                            editSettingsChanged();
                        }
                    }
                    NText {
                        text: "Include cache tokens in token count"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightSemiBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }
                }
                NText {
                    text: "Count cache read and cache write tokens in totals"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginXS

                NText {
                    text: "Refresh interval (seconds)"
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                }
                NText {
                    text: "Fallback polling interval when file watch misses changes"
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                NSpinBox {
                    from: 5
                    to: 300
                    value: editSettings?.refreshIntervalSec ?? 30
                    stepSize: 5
                    onValueChanged: {
                        editSettings.refreshIntervalSec = value;
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        color: root.sectionBackgroundColor
        radius: Style.radiusS
        implicitHeight: providersColumn.implicitHeight + Style.marginXL

        ColumnLayout {
            id: providersColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Style.marginL
            }
            spacing: Style.marginM

            NText {
                text: "Providers"
                pointSize: Style.fontSizeL
                font.weight: Style.fontWeightSemiBold
                color: Color.mPrimary
            }

            NText {
                text: "Drag grip handles to reorder · Toggle data collection and bar visibility"
                pointSize: Style.fontSizeXS
                color: Color.mOnSurfaceVariant
            }

            // --- Drag-and-drop reorderable provider list ---

            // Functions are defined at root level

            Repeater {
                model: editSettings?.providerOrder || defaultProviderOrder

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
                        implicitHeight: cardBody.implicitHeight + Style.marginM * 2

                        readonly property int providerIndex: providerDropArea.index
                        readonly property string providerId: String(providerDropArea.modelData || "")
                        property bool dragging: dragHandleMouseArea.drag.active

                        Drag.active: dragging
                        Drag.source: providerCard
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2
                        Drag.keys: ["model-usage-provider"]
                        z: dragging ? 1000 : 0
                        scale: dragging ? 1.02 : 1.0
                        opacity: dragging ? 0.9 : 1.0

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
                            anchors.margins: Style.marginM
                            spacing: Style.marginM

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginM

                                // Drag handle
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

                                // Enable toggle (data collection)
                                ColumnLayout {
                                    spacing: 0
                                    Layout.alignment: Qt.AlignVCenter
                                    NToggle {
                                        Layout.alignment: Qt.AlignHCenter
                                        checked: {
                                            var prov = editSettings?.providers?.[providerCard.providerId];
                                            return prov ? (prov.enabled ?? true) : true;
                                        }
                                        onToggled: function(value) {
                                            if (!editSettings.providers)
                                                editSettings.providers = {};
                                            if (!editSettings.providers[providerCard.providerId])
                                                editSettings.providers[providerCard.providerId] = {};
                                            editSettings.providers[providerCard.providerId].enabled = value;
                                            editSettingsChanged();
                                        }
                                    }
                                    NText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Collect"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                // Show in widget toggle
                                ColumnLayout {
                                    spacing: 0
                                    Layout.alignment: Qt.AlignVCenter
                                    NToggle {
                                        Layout.alignment: Qt.AlignHCenter
                                        checked: {
                                            var prov = editSettings?.providers?.[providerCard.providerId];
                                            return prov ? (prov.showInWidget ?? true) : true;
                                        }
                                        onToggled: function(value) {
                                            if (!editSettings.providers)
                                                editSettings.providers = {};
                                            if (!editSettings.providers[providerCard.providerId])
                                                editSettings.providers[providerCard.providerId] = {};
                                            editSettings.providers[providerCard.providerId].showInWidget = value;
                                            editSettingsChanged();
                                        }
                                    }
                                    NText {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Show"
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                ProviderVisual {
                                    Layout.rightMargin: Style.marginS
                                    Layout.alignment: Qt.AlignVCenter
                                    visualData: root.mainInstance?.providerVisualData(providerCard.providerId) ?? ({
                                        "source": "icon",
                                        "icon": "ai"
                                    })
                                    pointSize: Style.fontSizeL
                                }

                                // Provider name
                                NText {
                                    text: root.providerDisplayName(providerCard.providerId)
                                    pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                    Layout.fillWidth: true
                                }

                                // Auth type label
                                NText {
                                    text: root.providerAuthLabel(providerCard.providerId)
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }
                            }

                            // --- Provider-specific sub-settings ---

                            // Codex: data source selector
                            ColumnLayout {
                                visible: providerCard.providerId === "codex" && (editSettings?.providers?.codex?.enabled ?? true)
                                Layout.fillWidth: true
                                Layout.leftMargin: Style.marginXL
                                spacing: Style.marginXS

                                NText {
                                    text: "Data source"
                                    pointSize: Style.fontSizeM
                                    font.weight: Style.fontWeightSemiBold
                                    color: Color.mOnSurface
                                }
                                NText {
                                    text: "How to fetch Codex usage data"
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                }

                                NComboBox {
                                    Layout.fillWidth: true
                                    model: [
                                        { key: "local", name: "Local files" },
                                        { key: "api", name: "API" }
                                    ]
                                    currentKey: editSettings?.providers?.codex?.usageMode ?? "local"
                                    onSelected: function(key) {
                                        if (!editSettings.providers) editSettings.providers = {};
                                        if (!editSettings.providers.codex) editSettings.providers.codex = {};
                                        editSettings.providers.codex.usageMode = key;
                                        editSettingsChanged();
                                    }
                                }

                                NText {
                                    text: editSettings?.providers?.codex?.usageMode === "api"
                                        ? "Reads from ChatGPT backend API using auth from ~/.codex/auth.json"
                                        : "Reads ~/.codex/ files directly (history.jsonl, sessions/)"
                                    pointSize: Style.fontSizeXS
                                    color: Color.mOnSurfaceVariant
                                    wrapMode: Text.Wrap
                                }
                            }

                            // OpenRouter: API key
                            ColumnLayout {
                                visible: providerCard.providerId === "openrouter" && (editSettings?.providers?.openrouter?.enabled ?? false)
                                Layout.fillWidth: true
                                Layout.leftMargin: Style.marginXL
                                spacing: Style.marginXS

                                NTextInput {
                                    Layout.fillWidth: true
                                    placeholderText: "OPENROUTER_API_KEY env var or enter key here"
                                    text: editSettings?.providers?.openrouter?.apiKey ?? ""
                                    onTextChanged: {
                                        if (!editSettings.providers) editSettings.providers = {};
                                        if (!editSettings.providers.openrouter) editSettings.providers.openrouter = {};
                                        editSettings.providers.openrouter.apiKey = text;
                                    }
                                }
                            }

                            // Zen: API key
                            ColumnLayout {
                                visible: providerCard.providerId === "zen" && (editSettings?.providers?.zen?.enabled ?? false)
                                Layout.fillWidth: true
                                Layout.leftMargin: Style.marginXL
                                spacing: Style.marginXS

                                NTextInput {
                                    Layout.fillWidth: true
                                    placeholderText: "OPENCODE_ZEN_API_KEY / OPENCODE_API_KEY env var or enter key here"
                                    text: editSettings?.providers?.zen?.apiKey ?? ""
                                    onTextChanged: {
                                        if (!editSettings.providers) editSettings.providers = {};
                                        if (!editSettings.providers.zen) editSettings.providers.zen = {};
                                        editSettings.providers.zen.apiKey = text;
                                    }
                                }
                            }

                            // DeepSeek: API key
                            ColumnLayout {
                                visible: providerCard.providerId === "deepseek" && (editSettings?.providers?.deepseek?.enabled ?? false)
                                Layout.fillWidth: true
                                Layout.leftMargin: Style.marginXL
                                spacing: Style.marginXS

                                NTextInput {
                                    Layout.fillWidth: true
                                    placeholderText: "DEEPSEEK_API_KEY env var or enter key here"
                                    text: editSettings?.providers?.deepseek?.apiKey ?? ""
                                    onTextChanged: {
                                        if (!editSettings.providers) editSettings.providers = {};
                                        if (!editSettings.providers.deepseek) editSettings.providers.deepseek = {};
                                        editSettings.providers.deepseek.apiKey = text;
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
        spacing: Style.marginM

        Item {
            Layout.fillWidth: true
        }

        NButton {
            text: "Reset"
            onClicked: {
                root.editSettings = JSON.parse(JSON.stringify(pluginApi?.manifest?.metadata?.defaultSettings ?? {}));
            }
        }
    }
}
