pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    readonly property var cfg: pluginApi?.pluginSettings || ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
    readonly property var mainInstance: pluginApi?.mainInstance

    property var editDisabledManagers: JSON.parse(JSON.stringify(root.cfg.disabledManagers ?? root.defaults.disabledManagers ?? []))
    property int editRefreshIntervalMinutes: root.normalizeInterval(root.cfg.refreshIntervalMinutes ?? root.defaults.refreshIntervalMinutes ?? 30)
    property bool editHideOnZero: root.cfg.hideOnZero ?? root.defaults.hideOnZero ?? false
    property string editPresyncCmd: root.cfg.presyncCmd ?? root.defaults.presyncCmd ?? "(checkupdates; paru -Qua) 2>/dev/null; exit 0"
    property bool editRefreshOnStartup: root.cfg.refreshOnStartup ?? root.defaults.refreshOnStartup ?? true

    readonly property var availableManagerOptions: root.buildManagerOptions(true)
    readonly property var unavailableManagerOptions: root.buildManagerOptions(false)

    readonly property int enabledManagerCount: {
        var avail = root.mainInstance?.availableManagers ?? [];
        var count = 0;
        for (var i = 0; i < avail.length; i++) {
            if (root.editDisabledManagers.indexOf(avail[i].id) === -1)
                count++;
        }
        return count;
    }

    readonly property var intervalOptions: [
        { "key": "5",   "name": root.pluginApi?.tr("settings.interval.5")   ?? "Every 5 min" },
        { "key": "15",  "name": root.pluginApi?.tr("settings.interval.15")  ?? "Every 15 min" },
        { "key": "30",  "name": root.pluginApi?.tr("settings.interval.30")  ?? "Every 30 min" },
        { "key": "60",  "name": root.pluginApi?.tr("settings.interval.60")  ?? "Every hour" },
        { "key": "120", "name": root.pluginApi?.tr("settings.interval.120") ?? "Every 2 hours" }
    ]

    spacing: Style.marginL

    // ── mpm status ────────────────────────────────────────────────────────────

    NBox {
        Layout.fillWidth: true
        implicitHeight: statusBody.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: statusBody
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                Image {
                    source: Qt.resolvedUrl("assets/icon.svg")
                    sourceSize: Qt.size(Math.round(40 * Style.uiScaleRatio), Math.round(40 * Style.uiScaleRatio))
                    fillMode: Image.PreserveAspectFit
                    Layout.alignment: Qt.AlignVCenter
                }

                NLabel {
                    Layout.fillWidth: true
                    label: (root.mainInstance?.mpmAvailable ?? false)
                        ? (root.pluginApi?.tr("settings.backend.detected") ?? "")
                        : (root.pluginApi?.tr("settings.backend.missing") ?? "")
                    description: (root.mainInstance?.mpmAvailable ?? false)
                        ? (root.pluginApi?.tr("settings.backend.detail", {
                            "version": root.mainInstance?.mpmVersion ?? "",
                            "path": root.mainInstance?.mpmPath ?? ""
                        }) ?? "")
                        : (root.pluginApi?.tr("settings.backend.installHint") ?? "")
                    labelSize: Style.fontSizeL
                }
            }
        }
    }

    // ── Package managers ──────────────────────────────────────────────────────

    NBox {
        Layout.fillWidth: true
        implicitHeight: managersBody.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: managersBody
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NLabel {
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.managers.title") ?? ""
                description: root.pluginApi?.tr("settings.managers.desc", { "count": root.enabledManagerCount }) ?? ""
                labelSize: Style.fontSizeL
            }

            NDivider { Layout.fillWidth: true }

            NText {
                visible: root.availableManagerOptions.length === 0
                text: root.pluginApi?.tr("settings.managers.noneDetected") ?? ""
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            // Available managers — toggle chips
            Flow {
                Layout.fillWidth: true
                visible: root.availableManagerOptions.length > 0
                spacing: Style.marginS

                Repeater {
                    model: root.availableManagerOptions

                    delegate: Rectangle {
                        id: managerChip
                        required property var modelData
                        readonly property bool selected: root.editDisabledManagers.indexOf(managerChip.modelData.id) === -1

                        implicitWidth: chipRow.implicitWidth + Style.marginM * 2
                        implicitHeight: chipRow.implicitHeight + Style.marginS * 2
                        radius: Style.radiusL
                        color: managerChip.selected ? Color.mSurfaceVariant : Color.mSurface

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: Style.marginXS

                            NIcon {
                                visible: managerChip.selected
                                icon: "check"
                                color: Color.mPrimary
                                pointSize: Style.fontSizeS
                            }

                            NText {
                                text: String(managerChip.modelData.name || managerChip.modelData.id)
                                pointSize: Style.fontSizeS
                                color: managerChip.selected ? Color.mPrimary : Color.mOnSurfaceVariant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setManagerEnabled(managerChip.modelData.id, !managerChip.selected)
                        }
                    }
                }
            }

            // Unavailable managers (greyed, non-interactive)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginS
                visible: root.unavailableManagerOptions.length > 0

                NText {
                    text: root.pluginApi?.tr("settings.managers.unavailable") ?? ""
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    Repeater {
                        model: root.unavailableManagerOptions

                        delegate: Rectangle {
                            id: unavailChip
                            required property var modelData

                            implicitWidth: unavailRow.implicitWidth + Style.marginM * 2
                            implicitHeight: unavailRow.implicitHeight + Style.marginS * 2
                            radius: Style.radiusL
                            color: Color.mSurface
                            opacity: 0.5

                            RowLayout {
                                id: unavailRow
                                anchors.centerIn: parent

                                NText {
                                    text: String(unavailChip.modelData.name || unavailChip.modelData.id)
                                    pointSize: Style.fontSizeS
                                    color: Color.mOnSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Behavior ──────────────────────────────────────────────────────────────

    NBox {
        Layout.fillWidth: true
        implicitHeight: behaviorBody.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: behaviorBody
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NLabel {
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.behavior") ?? ""
                labelSize: Style.fontSizeL
            }

            NComboBox {
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.refreshInterval.label") ?? ""
                description: root.pluginApi?.tr("settings.refreshInterval.desc") ?? ""
                model: root.intervalOptions
                currentKey: String(root.editRefreshIntervalMinutes)
                onSelected: key => {
                    root.editRefreshIntervalMinutes = root.normalizeInterval(parseInt(key, 10));
                }
            }

            NToggle {
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.hideOnZero.label") ?? ""
                description: root.pluginApi?.tr("settings.hideOnZero.desc") ?? ""
                checked: root.editHideOnZero
                onToggled: checked => {
                    root.editHideOnZero = checked;
                }
            }

            NToggle {
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.refreshOnStartup.label") ?? ""
                description: root.pluginApi?.tr("settings.refreshOnStartup.desc") ?? ""
                checked: root.editRefreshOnStartup
                onToggled: checked => {
                    root.editRefreshOnStartup = checked;
                }
            }

            NTextInput {
                Layout.fillWidth: true
                label: root.pluginApi?.tr("settings.presyncCmd.label") ?? ""
                description: root.pluginApi?.tr("settings.presyncCmd.desc") ?? ""
                text: root.editPresyncCmd
                onTextChanged: root.editPresyncCmd = text
            }
        }
    }

    function saveSettings() {
        if (!root.pluginApi)
            return;
        root.pluginApi.pluginSettings.disabledManagers = JSON.parse(JSON.stringify(root.editDisabledManagers));
        root.pluginApi.pluginSettings.refreshIntervalMinutes = root.editRefreshIntervalMinutes;
        root.pluginApi.pluginSettings.hideOnZero = root.editHideOnZero;
        root.pluginApi.pluginSettings.presyncCmd = root.editPresyncCmd.trim();
        root.pluginApi.pluginSettings.refreshOnStartup = root.editRefreshOnStartup;
        root.pluginApi.saveSettings();
        root.mainInstance?.refresh("settings");
    }

    function setManagerEnabled(mid, enabled) {
        var next = root.editDisabledManagers.slice();
        var idx = next.indexOf(mid);
        if (!enabled && idx === -1) {
            next.push(mid);
        } else if (enabled && idx !== -1) {
            next.splice(idx, 1);
        }
        next.sort();
        root.editDisabledManagers = next;
    }

    function buildManagerOptions(forAvailable) {
        var source = forAvailable
            ? (root.mainInstance?.availableManagers ?? [])
            : (root.mainInstance?.unavailableManagers ?? []);
        var options = [];
        var seen = ({});
        for (var i = 0; i < source.length; i++) {
            var m = source[i];
            if (!m?.id || seen[m.id])
                continue;
            seen[m.id] = true;
            options.push({ "id": m.id, "name": String(m.name || m.id) });
        }
        options.sort((a, b) => a.name.localeCompare(b.name));
        return options;
    }

    function normalizeInterval(value) {
        var valid = [5, 15, 30, 60, 120];
        if (valid.indexOf(value) >= 0)
            return value;
        var closest = valid[0];
        var minDiff = Math.abs(value - valid[0]);
        for (var i = 1; i < valid.length; i++) {
            var diff = Math.abs(value - valid[i]);
            if (diff < minDiff) {
                minDiff = diff;
                closest = valid[i];
            }
        }
        return closest;
    }
}
