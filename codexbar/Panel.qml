pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./components"

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 420 * Style.uiScaleRatio
    property real contentPreferredHeight: 520 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var providerVisuals: mainInstance?.normalizeProviderVisuals(cfg.providerVisuals ?? defaults.providerVisuals ?? ({})) || ({})
    readonly property bool providerIconColorize: cfg.providerIconColorize ?? defaults.providerIconColorize ?? true
    readonly property color resolvedProviderIconColorizeColor: Color.resolveColorKey(cfg.providerIconColorizeColor ?? defaults.providerIconColorizeColor ?? "on-surface")

    function windowRoleLabel(provider, role) {
        if (provider && provider._windowLabels && provider._windowLabels[role])
            return provider._windowLabels[role];
        return role.charAt(0).toUpperCase() + role.slice(1);
    }

    function capitalizeFirst(value) {
        var s = String(value || "").trim();
        if (s.length === 0)
            return "";
        return s.charAt(0).toUpperCase() + s.slice(1);
    }

    function formatProviderError(errorValue) {
        if (!errorValue)
            return "";
        var message = String(errorValue.message || "").trim();
        if (message !== "")
            return message;
        try {
            return JSON.stringify(errorValue);
        } catch (_e) {
            return String(errorValue);
        }
    }

    anchors.fill: parent

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginXL
            spacing: Style.marginXL

            RowLayout {
                Layout.fillWidth: true

                NLabel {
                    label: root.pluginApi?.tr("panel.title")
                    labelSize: Style.fontSizeXL
                }

                Item {
                    Layout.fillWidth: true
                }

                NButton {
                    icon: "refresh"
                    fontSize: Style.fontSizeS
                    outlined: true
                    onClicked: {
                        if (root.mainInstance)
                            root.mainInstance.refresh();
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            NScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalPolicy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent?.width ?? 0
                    spacing: Style.marginL

                    Repeater {
                        model: root.mainInstance?.providerData || []

                        delegate: NBox {
                            id: providerCard
                            required property var modelData
                            readonly property var provider: modelData
                            readonly property string providerId: String(provider.provider || "")
                            readonly property var providerUsage: provider.usage || ({})
                            readonly property var providerVisualData: root.mainInstance?.providerVisual(providerId, root.providerVisuals, ({})) || ({
                                "source": "icon",
                                "icon": root.mainInstance?.providerIcon(providerId) || "cpu",
                                "asset": "",
                                "assetUrl": ""
                            })
                            readonly property string providerName: root.capitalizeFirst(root.mainInstance?.providerDisplayName(providerId) || providerId)
                            Layout.fillWidth: true
                            implicitHeight: cardBody.implicitHeight + Style.marginL * 2

                            ColumnLayout {
                                id: cardBody
                                anchors.fill: parent
                                anchors.margins: Style.marginL
                                spacing: Style.marginL

                                RowLayout {
                                    Layout.fillWidth: true

                                    ProviderVisual {
                                        Layout.preferredWidth: Style.fontSizeL
                                        Layout.preferredHeight: Style.fontSizeL
                                        Layout.rightMargin: Style.marginS
                                        visualData: providerCard.providerVisualData
                                        color: Color.mPrimary
                                        colorize: root.providerIconColorize
                                        colorizeColor: root.resolvedProviderIconColorizeColor
                                    }

                                    NText {
                                        text: providerCard.providerName
                                        pointSize: Style.fontSizeL
                                        font.weight: Font.Bold
                                        color: Color.mOnSurface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NText {
                                        text: String(providerCard.provider.source || "")
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                NBox {
                                    Layout.fillWidth: true
                                    visible: !!providerCard.provider.error
                                    implicitHeight: errorBody.implicitHeight + Style.marginM * 2

                                    ColumnLayout {
                                        id: errorBody
                                        x: Style.marginM
                                        y: Style.marginM
                                        width: Math.max(0, parent.width - Style.marginM * 2)
                                        spacing: Style.marginS

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: Style.marginS

                                            NIcon {
                                                Layout.preferredWidth: Style.fontSizeM
                                                Layout.preferredHeight: Style.fontSizeM
                                                icon: "alert-triangle"
                                                color: Color.mError
                                            }

                                            NText {
                                                Layout.fillWidth: true
                                                text: root.pluginApi?.tr("panel.providerError")
                                                pointSize: Style.fontSizeS
                                                color: Color.mError
                                                font.weight: Font.Medium
                                            }
                                        }

                                        NText {
                                            Layout.fillWidth: true
                                            text: root.formatProviderError(providerCard.provider.error)
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }

                                Repeater {
                                    model: ["secondary", "primary", "tertiary"]

                                    delegate: Loader {
                                        id: usageWindowLoader
                                        required property var modelData
                                        required property int index
                                        readonly property string windowKey: String(modelData || "")
                                        readonly property var usageWindow: providerCard.providerUsage[windowKey] || null
                                        readonly property int usedPercent: usageWindow ? Number(usageWindow.usedPercent) : 0
                                        readonly property int leftPercent: 100 - usedPercent
                                        Layout.fillWidth: true
                                        active: usageWindow != null
                                        visible: active
                                        Layout.bottomMargin: 15

                                        sourceComponent: Component {
                                            ColumnLayout {
                                                width: parent ? parent.width : 0
                                                spacing: Style.marginL

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    NText {
                                                        text: root.pluginApi?.tr("panel.usage") + " (" + root.windowRoleLabel(providerCard.provider, usageWindowLoader.windowKey) + ")"
                                                        pointSize: Style.fontSizeM
                                                        color: Color.mOnSurfaceVariant
                                                    }

                                                    Item {
                                                        Layout.fillWidth: true
                                                    }

                                                    NText {
                                                        text: usageWindowLoader.leftPercent + "% " + root.pluginApi?.tr("panel.left")
                                                        pointSize: Style.fontSizeM
                                                        color: Color.mOnSurface
                                                        font.weight: Font.Medium
                                                    }
                                                }

                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.preferredHeight: 6 * Style.uiScaleRatio
                                                    radius: 3 * Style.uiScaleRatio
                                                    color: Color.mSurfaceVariant

                                                    Rectangle {
                                                        anchors.left: parent.left
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: parent.width * (usageWindowLoader.usedPercent / 100)
                                                        height: parent.height
                                                        radius: parent.radius
                                                        color: {
                                                            var left = usageWindowLoader.leftPercent;
                                                            if (left <= 10)
                                                                return Color.mError;
                                                            if (left <= 25)
                                                                return "#f59e0b";
                                                            return Color.mPrimary;
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    visible: !!usageWindowLoader.usageWindow && (!!usageWindowLoader.usageWindow.resetsAt || !!usageWindowLoader.usageWindow.resetDescription)
                                                    spacing: Style.marginM

                                                    NText {
                                                        text: {
                                                            var win = usageWindowLoader.usageWindow;
                                                            if (!win)
                                                                return "";
                                                            if (win.resetsAt)
                                                                return root.pluginApi?.tr("panel.resetsIn") + " " + root.mainInstance.formatResetsCountdown(win.resetsAt);
                                                            return String(win.resetDescription || "").trim();
                                                        }
                                                        pointSize: Style.fontSizeXS
                                                        color: Color.mOnSurfaceVariant
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !!providerCard.provider.credits && providerCard.provider.credits.remaining != null

                                    NText {
                                        text: root.pluginApi?.tr("panel.credits") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    NText {
                                        text: providerCard.provider.credits ? String(providerCard.provider.credits.remaining) : ""
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurface
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !!providerCard.provider.status

                                    NText {
                                        text: root.pluginApi?.tr("panel.status") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 8 * Style.uiScaleRatio
                                        Layout.preferredHeight: 8 * Style.uiScaleRatio
                                        radius: 4 * Style.uiScaleRatio
                                        color: {
                                            if (!providerCard.provider.status)
                                                return Color.mPrimary;
                                            var ind = String(providerCard.provider.status.indicator || "");
                                            if (ind === "major" || ind === "critical")
                                                return Color.mError;
                                            if (ind === "minor" || ind === "maintenance")
                                                return "#f59e0b";
                                            return Color.mPrimary;
                                        }
                                    }

                                    NText {
                                        text: {
                                            var ind = String(providerCard.provider.status?.indicator || "");
                                            var desc = String(providerCard.provider.status?.description || "").trim();
                                            if (ind === "none")
                                                return desc || root.pluginApi?.tr("panel.statusOperational") || "Operational";
                                            if (desc)
                                                return desc;
                                            if (ind === "minor")
                                                return "Partial outage";
                                            if (ind === "major")
                                                return "Major outage";
                                            if (ind === "critical")
                                                return "Critical issue";
                                            if (ind === "maintenance")
                                                return "Maintenance";
                                            return ind.charAt(0).toUpperCase() + ind.slice(1);
                                        }
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurface
                                    }
                                }

                                NButton {
                                    Layout.alignment: Qt.AlignLeft
                                    visible: !!providerCard.provider.status && String(providerCard.provider.status.url || "").length > 0
                                    text: root.pluginApi?.tr("panel.openStatusPage")
                                    icon: "external-link"
                                    outlined: true
                                    onClicked: {
                                        var url = String(providerCard.provider.status?.url || "");
                                        if (url)
                                            Qt.openUrlExternally(url);
                                    }
                                }
                            }
                        }
                    }

                    NLabel {
                        Layout.fillWidth: true
                        visible: !root.mainInstance || !Array.isArray(root.mainInstance.providerData) || root.mainInstance.providerData.length === 0
                        label: root.pluginApi?.tr("panel.noProviders")
                        labelSize: Style.fontSizeM
                    }
                }
            }

            NDivider {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true

                NText {
                    text: {
                        if (!root.mainInstance?.lastUpdated)
                            return "";
                        var d = new Date(root.mainInstance.lastUpdated);
                        return root.pluginApi?.tr("panel.lastUpdated") + ": " + Qt.formatTime(d, "hh:mm");
                    }
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                NText {
                    visible: root.mainInstance?.lastError
                    text: root.mainInstance?.lastError || ""
                    pointSize: Style.fontSizeXS
                    color: Color.mError
                }
            }
        }
    }
}
