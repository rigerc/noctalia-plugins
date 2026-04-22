import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 420 * Style.uiScaleRatio
    property real contentPreferredHeight: 520 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    readonly property var mainInstance: pluginApi?.mainInstance

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
                    label: pluginApi?.tr("panel.title")
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
                        if (mainInstance)
                            mainInstance.refresh();
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
                        model: mainInstance?.providerData || []

                        delegate: NBox {
                            required property var modelData
                            readonly property var provider: modelData
                            Layout.fillWidth: true
                            implicitHeight: cardBody.implicitHeight + Style.marginL * 2

                            ColumnLayout {
                                id: cardBody
                                anchors.fill: parent
                                anchors.margins: Style.marginL
                                spacing: Style.marginL

                                RowLayout {
                                    Layout.fillWidth: true

                                    NIcon {
                                        Layout.preferredWidth: Style.fontSizeL
                                        Layout.preferredHeight: Style.fontSizeL
                                        icon: mainInstance?.providerIcon(provider.provider) || "cpu"
                                        color: Color.mPrimary
                                    }

                                    NText {
                                        text: root.capitalizeFirst(mainInstance?.providerDisplayName(provider.provider) || provider.provider)
                                        pointSize: Style.fontSizeL
                                        font.weight: Font.Bold
                                        color: Color.mOnSurface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NText {
                                        text: String(provider.source || "")
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                NBox {
                                    Layout.fillWidth: true
                                    visible: !!provider.error
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
                                                text: pluginApi?.tr("panel.providerError")
                                                pointSize: Style.fontSizeS
                                                color: Color.mError
                                                font.weight: Font.Medium
                                            }
                                        }

                                        NText {
                                            Layout.fillWidth: true
                                            text: root.formatProviderError(provider.error)
                                            pointSize: Style.fontSizeXS
                                            color: Color.mOnSurfaceVariant
                                            wrapMode: Text.Wrap
                                        }
                                    }
                                }

                                Repeater {
                                    model: ["secondary", "primary", "tertiary"]

                                    delegate: Loader {
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        active: provider.usage ? provider.usage[modelData] != null : false
                                        visible: active
                                        Layout.bottomMargin: 15

                                        sourceComponent: Component {
                                            ColumnLayout {
                                                width: parent ? parent.width : 0
                                                spacing: Style.marginL

                                                RowLayout {
                                                    Layout.fillWidth: true

                                                    NText {
                                                        text: pluginApi?.tr("panel.usage") + " (" + root.windowRoleLabel(provider, modelData) + ")"
                                                        pointSize: Style.fontSizeM
                                                        color: Color.mOnSurfaceVariant
                                                    }

                                                    Item {
                                                        Layout.fillWidth: true
                                                    }

                                                    NText {
                                                        text: (100 - provider.usage[modelData].usedPercent) + "% " + pluginApi?.tr("panel.left")
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
                                                        width: parent.width * (provider.usage[modelData].usedPercent / 100)
                                                        height: parent.height
                                                        radius: parent.radius
                                                        color: {
                                                            var left = 100 - provider.usage[modelData].usedPercent;
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
                                                    visible: {
                                                        var win = provider.usage ? provider.usage[modelData] : null;
                                                        if (!win)
                                                            return false;
                                                        return !!win.resetsAt || !!win.resetDescription;
                                                    }
                                                    spacing: Style.marginM

                                                    NText {
                                                        text: {
                                                            var win = provider.usage ? provider.usage[modelData] : null;
                                                            if (!win)
                                                                return "";
                                                            if (win.resetsAt)
                                                                return pluginApi?.tr("panel.resetsIn") + " " + mainInstance.formatResetsCountdown(win.resetsAt);
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
                                    visible: !!provider.credits && provider.credits.remaining != null

                                    NText {
                                        text: pluginApi?.tr("panel.credits") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    NText {
                                        text: provider.credits ? String(provider.credits.remaining) : ""
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurface
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !!provider.status

                                    NText {
                                        text: pluginApi?.tr("panel.status") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 8 * Style.uiScaleRatio
                                        Layout.preferredHeight: 8 * Style.uiScaleRatio
                                        radius: 4 * Style.uiScaleRatio
                                        color: {
                                            if (!provider.status)
                                                return Color.mPrimary;
                                            var ind = String(provider.status.indicator || "");
                                            if (ind === "major" || ind === "critical")
                                                return Color.mError;
                                            if (ind === "minor" || ind === "maintenance")
                                                return "#f59e0b";
                                            return Color.mPrimary;
                                        }
                                    }

                                    NText {
                                        text: {
                                            var ind = String(provider.status?.indicator || "");
                                            var desc = String(provider.status?.description || "").trim();
                                            if (ind === "none")
                                                return desc || pluginApi?.tr("panel.statusOperational") || "Operational";
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
                                    visible: !!provider.status && String(provider.status.url || "").length > 0
                                    text: pluginApi?.tr("panel.openStatusPage")
                                    icon: "external-link"
                                    outlined: true
                                    onClicked: {
                                        var url = String(provider.status?.url || "");
                                        if (url)
                                            Qt.openUrlExternally(url);
                                    }
                                }
                            }
                        }
                    }

                    NLabel {
                        Layout.fillWidth: true
                        visible: !mainInstance || !Array.isArray(mainInstance.providerData) || mainInstance.providerData.length === 0
                        label: pluginApi?.tr("panel.noProviders")
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
                        if (!mainInstance?.lastUpdated)
                            return "";
                        var d = new Date(mainInstance.lastUpdated);
                        return pluginApi?.tr("panel.lastUpdated") + ": " + Qt.formatTime(d, "hh:mm");
                    }
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                Item {
                    Layout.fillWidth: true
                }

                NText {
                    visible: mainInstance?.lastError
                    text: mainInstance?.lastError || ""
                    pointSize: Style.fontSizeXS
                    color: Color.mError
                }
            }
        }
    }
}
