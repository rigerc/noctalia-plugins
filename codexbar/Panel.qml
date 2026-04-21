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
                        if (mainInstance) mainInstance.refresh();
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
                            Layout.fillWidth: true

                            ColumnLayout {
                                width: parent.width
                                spacing: Style.marginM

                                RowLayout {
                                    Layout.fillWidth: true

                                    NIcon {
                                        Layout.preferredWidth: Style.fontSizeL
                                        Layout.preferredHeight: Style.fontSizeL
                                        icon: mainInstance?.providerIcon(modelData.provider) || "cpu"
                                        color: Color.mPrimary
                                    }

                                    NText {
                                        text: mainInstance?.providerDisplayName(modelData.provider) || modelData.provider
                                        pointSize: Style.fontSizeL
                                        font.weight: Font.Bold
                                        color: Color.mOnSurface
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                    }

                                    NText {
                                        text: String(modelData.source || "")
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }
                                }

                                Loader {
                                    Layout.fillWidth: true
                                    active: modelData.usage?.primary != null
                                    visible: active

                                    sourceComponent: Component {
                                        ColumnLayout {
                                            width: parent.width
                                            spacing: Style.marginS

                                            RowLayout {
                                                Layout.fillWidth: true

                                                NText {
                                                    text: pluginApi?.tr("panel.usage") + " (session)"
                                                    pointSize: Style.fontSizeM
                                                    color: Color.mOnSurfaceVariant
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                }

                                                NText {
                                                    text: (100 - modelData.usage.primary.usedPercent) + "% " + pluginApi?.tr("panel.left")
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
                                                    width: parent.width * (modelData.usage.primary.usedPercent / 100)
                                                    height: parent.height
                                                    radius: parent.radius
                                                    color: {
                                                        var left = 100 - modelData.usage.primary.usedPercent;
                                                        if (left <= 10) return Color.mError;
                                                        if (left <= 25) return "#f59e0b";
                                                        return Color.mPrimary;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Loader {
                                    Layout.fillWidth: true
                                    active: modelData.usage?.secondary != null
                                    visible: active

                                    sourceComponent: Component {
                                        ColumnLayout {
                                            width: parent.width
                                            spacing: Style.marginS

                                            RowLayout {
                                                Layout.fillWidth: true

                                                NText {
                                                    text: pluginApi?.tr("panel.usage") + " (weekly)"
                                                    pointSize: Style.fontSizeS
                                                    color: Color.mOnSurfaceVariant
                                                }

                                                Item {
                                                    Layout.fillWidth: true
                                                }

                                                NText {
                                                    text: (100 - modelData.usage.secondary.usedPercent) + "% " + pluginApi?.tr("panel.left")
                                                    pointSize: Style.fontSizeS
                                                    color: Color.mOnSurfaceVariant
                                                }
                                            }

                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 4 * Style.uiScaleRatio
                                                radius: 2 * Style.uiScaleRatio
                                                color: Color.mSurfaceVariant

                                                Rectangle {
                                                    anchors.left: parent.left
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width * (modelData.usage.secondary.usedPercent / 100)
                                                    height: parent.height
                                                    radius: parent.radius
                                                    color: Color.mPrimary
                                                }
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !!modelData.usage?.primary?.resetsAt

                                    NText {
                                        text: pluginApi?.tr("panel.resetsAt") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    NText {
                                        text: {
                                            var resetsAt = modelData.usage?.primary?.resetsAt;
                                            if (!resetsAt) return "";
                                            var d = new Date(resetsAt);
                                            var diff = (d.getTime() - Date.now()) / 1000;
                                            if (diff <= 0) return pluginApi?.tr("panel.resetsNow") || "Now";
                                            var h = Math.floor(diff / 3600);
                                            var m = Math.floor((diff % 3600) / 60);
                                            if (h > 0) return h + "h " + m + "m";
                                            return m + "m";
                                        }
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurface
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: modelData.credits?.remaining != null

                                    NText {
                                        text: pluginApi?.tr("panel.credits") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    NText {
                                        text: String(modelData.credits.remaining)
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurface
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !!(modelData.status && modelData.status.indicator && modelData.status.indicator !== "none")

                                    NText {
                                        text: pluginApi?.tr("panel.status") + ":"
                                        pointSize: Style.fontSizeS
                                        color: Color.mOnSurfaceVariant
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 8 * Style.uiScaleRatio
                                        Layout.preferredHeight: 8 * Style.uiScaleRatio
                                        radius: 4 * Style.uiScaleRatio
                                        color: modelData.status?.indicator === "major" ? Color.mError : "#f59e0b"
                                    }

                                    NText {
                                        text: String(modelData.status?.description || modelData.status?.indicator || "")
                                        pointSize: Style.fontSizeXS
                                        color: Color.mOnSurface
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
                        if (!mainInstance?.lastUpdated) return "";
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
