pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: panelContainer
    property real contentPreferredWidth: 420 * Style.uiScaleRatio
    property real contentPreferredHeight: 520 * Style.uiScaleRatio
    readonly property bool allowAttach: true

    anchors.fill: parent

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool isRefreshing: root.mainInstance?.isRefreshing ?? false
    readonly property int totalUpdateCount: root.mainInstance?.totalUpdateCount ?? 0
    readonly property bool hasError: root.mainInstance?.hasError ?? false
    readonly property bool mpmAvailable: root.mainInstance?.mpmAvailable ?? false

    readonly property var visibleResults: {
        var results = root.mainInstance?.managerResults ?? [];
        return results.filter(m => (m.packageCount || 0) > 0 || (m.errorCount || 0) > 0);
    }

    function countManagerErrors() {
        var results = root.mainInstance?.managerResults ?? [];
        var count = 0;
        for (var i = 0; i < results.length; i++)
            count += results[i].errorCount || 0;
        return count;
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.marginXL
            spacing: Style.marginXL

            // ── Title row ─────────────────────────────────────────────────────

            RowLayout {
                Layout.fillWidth: true

                NLabel {
                    label: root.pluginApi?.tr("panel.title")
                    labelSize: Style.fontSizeXL
                }

                Item { Layout.fillWidth: true }

                NButton {
                    icon: root.isRefreshing ? "loader" : "refresh"
                    fontSize: Style.fontSizeS
                    outlined: true
                    onClicked: root.mainInstance?.refresh("panel")
                }
            }

            NDivider { Layout.fillWidth: true }

            // ── Scroll area ───────────────────────────────────────────────────

            NScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalPolicy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: parent?.width ?? 0
                    spacing: Style.marginL

                    // Status message when unavailable / error / no updates
                    NLabel {
                        Layout.fillWidth: true
                        visible: !root.mpmAvailable || (root.hasError && root.visibleResults.length === 0) || (root.totalUpdateCount === 0 && !root.isRefreshing && (root.mainInstance?.lastCheckedAt ?? 0) > 0)
                        label: {
                            if (root.isRefreshing)
                                return root.pluginApi?.tr("panel.state.checkingTitle") ?? "";
                            if (!root.mpmAvailable && (root.mainInstance?.mpmPath ?? "") !== "")
                                return root.pluginApi?.tr("panel.state.brokenTitle") ?? "";
                            if (!root.mpmAvailable)
                                return root.pluginApi?.tr("panel.state.unavailableTitle") ?? "";
                            if (root.hasError)
                                return root.pluginApi?.tr("panel.state.errorTitle") ?? "";
                            return root.pluginApi?.tr("panel.state.noUpdatesTitle") ?? "";
                        }
                        description: {
                            if (root.isRefreshing)
                                return root.pluginApi?.tr("panel.state.checkingMessage") ?? "";
                            if (!root.mpmAvailable && (root.mainInstance?.mpmPath ?? "") !== "")
                                return root.pluginApi?.tr("panel.state.brokenMessage") ?? "";
                            if (!root.mpmAvailable)
                                return root.pluginApi?.tr("panel.state.unavailableMessage") ?? "";
                            if (root.hasError)
                                return root.mainInstance?.errorMessage ?? "";
                            return root.pluginApi?.tr("panel.state.noUpdatesMessage") ?? "";
                        }
                        labelSize: Style.fontSizeM
                    }

                    // Manager cards
                    Repeater {
                        model: root.visibleResults

                        delegate: NBox {
                            id: managerCard
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: cardBody.implicitHeight + Style.marginL * 2

                            ColumnLayout {
                                id: cardBody
                                anchors.fill: parent
                                anchors.margins: Style.marginL
                                spacing: Style.marginL

                                // Manager header
                                RowLayout {
                                    Layout.fillWidth: true

                                    NIcon {
                                        Layout.preferredWidth: Style.fontSizeL
                                        Layout.preferredHeight: Style.fontSizeL
                                        icon: "package"
                                        color: Color.mPrimary
                                    }

                                    NText {
                                        text: String(managerCard.modelData.name || managerCard.modelData.id)
                                        pointSize: Style.fontSizeL
                                        font.weight: Font.Bold
                                        color: Color.mOnSurface
                                    }

                                    Item { Layout.fillWidth: true }

                                    NText {
                                        text: String(managerCard.modelData.packageCount || 0) + " updates"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                // Errors
                                NBox {
                                    Layout.fillWidth: true
                                    visible: (managerCard.modelData.errorCount || 0) > 0
                                    implicitHeight: errorBody.implicitHeight + Style.marginM * 2

                                    ColumnLayout {
                                        id: errorBody
                                        x: Style.marginM
                                        y: Style.marginM
                                        width: Math.max(0, parent.width - Style.marginM * 2)
                                        spacing: Style.marginS

                                        Repeater {
                                            model: managerCard.modelData.errors || []

                                            delegate: RowLayout {
                                                id: errRow
                                                required property string modelData
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
                                                    text: errRow.modelData
                                                    pointSize: Style.fontSizeS
                                                    color: Color.mError
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }
                                    }
                                }

                                // Package list
                                Repeater {
                                    model: managerCard.modelData.packages || []

                                    delegate: RowLayout {
                                        id: pkgRow
                                        required property var modelData
                                        Layout.fillWidth: true
                                        spacing: Style.marginM

                                        NText {
                                            text: String(pkgRow.modelData.displayName || pkgRow.modelData.id)
                                            pointSize: Style.fontSizeS
                                            color: Color.mOnSurface
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        NText {
                                            text: String(pkgRow.modelData.installedVersion || "?")
                                            pointSize: Style.fontSizeS
                                            color: Color.mOnSurfaceVariant
                                        }

                                        NText {
                                            text: "→"
                                            pointSize: Style.fontSizeS
                                            color: Color.mOnSurfaceVariant
                                        }

                                        NText {
                                            text: String(pkgRow.modelData.latestVersion || "?")
                                            pointSize: Style.fontSizeS
                                            color: Color.mPrimary
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            NDivider { Layout.fillWidth: true }

            // ── Footer ────────────────────────────────────────────────────────

            RowLayout {
                Layout.fillWidth: true

                NText {
                    text: {
                        var ts = root.mainInstance?.lastCheckedAt ?? 0;
                        if (!ts)
                            return "";
                        return (root.pluginApi?.tr("panel.lastChecked", { "time": root.mainInstance?.formatTimestamp(ts) ?? "" }) ?? "");
                    }
                    pointSize: Style.fontSizeXS
                    color: Color.mOnSurfaceVariant
                }

                Item { Layout.fillWidth: true }

                NText {
                    visible: root.hasError && !root.isRefreshing
                    text: root.mainInstance?.errorMessage ?? ""
                    pointSize: Style.fontSizeXS
                    color: Color.mError
                }
            }
        }
    }
}
