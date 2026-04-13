import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})
  readonly property var mainInstance: pluginApi?.mainInstance

  property var editEnabledManagerIds: JSON.parse(JSON.stringify(cfg.enabledManagerIds ?? defaults.enabledManagerIds ?? []))
  property int editRefreshIntervalMinutes: cfg.refreshIntervalMinutes ?? defaults.refreshIntervalMinutes ?? 30
  property string editIconName: cfg.iconName ?? defaults.iconName ?? "package"
  property string editIconColor: cfg.iconColor ?? defaults.iconColor ?? "primary"
  property string editCountColor: cfg.countColor ?? defaults.countColor ?? "secondary"
  property string editErrorColor: cfg.errorColor ?? defaults.errorColor ?? "destructive"
  property bool editEnableNotifications: cfg.enableNotifications ?? defaults.enableNotifications ?? false
  property string editTerminalCommand: cfg.terminalCommand ?? defaults.terminalCommand ?? ""

  readonly property var refreshIntervalOptions: [
    { "key": 5, "name": pluginApi?.tr("settings.interval.5m") },
    { "key": 15, "name": pluginApi?.tr("settings.interval.15m") },
    { "key": 30, "name": pluginApi?.tr("settings.interval.30m") },
    { "key": 60, "name": pluginApi?.tr("settings.interval.60m") },
    { "key": 120, "name": pluginApi?.tr("settings.interval.120m") }
  ]

  readonly property var availableManagerOptions: buildManagerOptions(true)
  readonly property var unavailableManagerOptions: buildManagerOptions(false)
  readonly property int selectedManagerCount: root.editEnabledManagerIds.length

  spacing: Style.marginL

  NHeader {
    label: pluginApi?.tr("settings.header.label")
    description: pluginApi?.tr("settings.header.description")
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: backendColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: backendColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginS

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        Rectangle {
          Layout.preferredWidth: Math.round(34 * Style.uiScaleRatio)
          Layout.preferredHeight: Math.round(34 * Style.uiScaleRatio)
          radius: Style.radiusM
          color: mainInstance?.mpmAvailable
            ? Qt.alpha(Color.mPrimary, 0.14)
            : Qt.alpha(resolveColor(root.editErrorColor, Color.resolveColorKey("destructive")), 0.16)

          NIcon {
            anchors.centerIn: parent
            icon: mainInstance?.mpmAvailable ? "circle-check" : "alert-triangle"
            color: mainInstance?.mpmAvailable
              ? Color.mPrimary
              : resolveColor(root.editErrorColor, Color.resolveColorKey("destructive"))
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXXS

          NText {
            text: mainInstance?.mpmAvailable
              ? pluginApi?.tr("settings.backend.detected")
              : pluginApi?.tr("settings.backend.missing")
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightSemiBold
            color: Color.mOnSurface
          }

          NText {
            Layout.fillWidth: true
            text: mainInstance?.mpmAvailable
              ? pluginApi?.tr("settings.backend.detail", {
                  "version": mainInstance?.mpmVersion || pluginApi?.tr("common.unknown"),
                  "path": mainInstance?.mpmPath || pluginApi?.tr("common.unknown")
                })
              : mainInstance?.mpmErrorMessage || pluginApi?.tr("settings.backend.installHint")
            color: Color.mOnSurfaceVariant
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: managersColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: managersColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.managers.title")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: Color.mPrimary
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.managers.desc", {
          "count": root.selectedManagerCount
        })
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }

      NText {
        text: pluginApi?.tr("settings.managers.availableTitle")
        font.weight: Style.fontWeightSemiBold
        color: Color.mOnSurface
      }

      Flow {
        Layout.fillWidth: true
        width: managersColumn.width
        spacing: Style.marginS

        Repeater {
          model: root.availableManagerOptions

          delegate: Rectangle {
            required property var modelData
            readonly property bool selected: root.editEnabledManagerIds.indexOf(modelData.id) !== -1

            implicitWidth: chipLabel.implicitWidth + Math.round((selected ? 38 : 24) * Style.uiScaleRatio)
            implicitHeight: Math.round(32 * Style.uiScaleRatio)
            radius: implicitHeight / 2
            color: selected ? Qt.alpha(Color.mPrimary, 0.14) : Color.mSurfaceVariant
            border.color: selected ? Color.mPrimary : Color.mOutline
            border.width: Style.borderS

            RowLayout {
              anchors.centerIn: parent
              spacing: Style.marginXS

              NIcon {
                visible: selected
                icon: "check"
                color: Color.mPrimary
                pointSize: Style.fontSizeXS
              }

              NText {
                id: chipLabel
                text: modelData.name
                color: selected ? Color.mPrimary : Color.mOnSurface
                font.weight: selected ? Style.fontWeightSemiBold : Style.fontWeightNormal
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.setManagerEnabled(parent.modelData.id, !parent.selected)
            }
          }
        }
      }

      NText {
        visible: root.availableManagerOptions.length === 0
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.managers.noAvailable")
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        visible: root.unavailableManagerOptions.length > 0

        NText {
          text: pluginApi?.tr("settings.managers.unavailableTitle")
          font.weight: Style.fontWeightSemiBold
          color: Color.mOnSurface
        }

        Flow {
          Layout.fillWidth: true
          width: managersColumn.width
          spacing: Style.marginS

          Repeater {
            model: root.unavailableManagerOptions

            delegate: Rectangle {
              required property var modelData

              implicitWidth: chipLabel.implicitWidth + Math.round(20 * Style.uiScaleRatio)
              implicitHeight: Math.round(30 * Style.uiScaleRatio)
              radius: implicitHeight / 2
              color: Color.mSurfaceVariant
              border.color: Qt.alpha(Color.mOutline, 0.8)
              border.width: Style.borderS
              opacity: 0.72

              NText {
                id: chipLabel
                anchors.centerIn: parent
                text: modelData.name
                color: Color.mOnSurfaceVariant
              }
            }
          }
        }

        NText {
          Layout.fillWidth: true
          text: pluginApi?.tr("settings.managers.unavailable")
          color: Color.mOnSurfaceVariant
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: appearanceColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: appearanceColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.appearance.title")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: Color.mPrimary
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.appearance.desc")
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NLabel {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.icon.label")
          description: pluginApi?.tr("settings.icon.desc")
        }

        Rectangle {
          Layout.preferredWidth: Math.round(116 * Style.uiScaleRatio)
          Layout.preferredHeight: Math.round(40 * Style.uiScaleRatio)
          radius: Style.radiusL
          color: Style.capsuleColor
          border.color: Style.capsuleBorderColor
          border.width: Style.capsuleBorderWidth

          RowLayout {
            anchors.centerIn: parent
            spacing: Style.marginXS

            NIcon {
              icon: root.editIconName
              color: resolveColor(root.editIconColor, Color.mPrimary)
            }

            NText {
              text: "12"
              color: resolveColor(root.editCountColor, Color.mOnSurface)
              font.weight: Style.fontWeightSemiBold
            }
          }
        }

        NButton {
          text: pluginApi?.tr("settings.icon.pick")
          onClicked: iconPicker.open()
        }
      }

      NIconPicker {
        id: iconPicker
        initialIcon: root.editIconName
        onIconSelected: iconName => root.editIconName = iconName
      }

      NColorChoice {
        label: pluginApi?.tr("settings.iconColor.label")
        description: pluginApi?.tr("settings.iconColor.desc")
        currentKey: root.editIconColor
        onSelected: key => root.editIconColor = key
      }

      NColorChoice {
        label: pluginApi?.tr("settings.countColor.label")
        description: pluginApi?.tr("settings.countColor.desc")
        currentKey: root.editCountColor
        onSelected: key => root.editCountColor = key
      }

      NColorChoice {
        label: pluginApi?.tr("settings.errorColor.label")
        description: pluginApi?.tr("settings.errorColor.desc")
        currentKey: root.editErrorColor
        onSelected: key => root.editErrorColor = key
      }
    }
  }

  NBox {
    Layout.fillWidth: true
    implicitHeight: behaviorColumn.implicitHeight + Style.marginXL

    ColumnLayout {
      id: behaviorColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NText {
        text: pluginApi?.tr("settings.behavior.title")
        pointSize: Style.fontSizeL
        font.weight: Style.fontWeightSemiBold
        color: Color.mPrimary
      }

      NText {
        Layout.fillWidth: true
        text: pluginApi?.tr("settings.behavior.desc")
        color: Color.mOnSurfaceVariant
        wrapMode: Text.WordWrap
      }

      NComboBox {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.refreshInterval.label")
        description: pluginApi?.tr("settings.refreshInterval.desc")
        model: root.refreshIntervalOptions
        currentKey: root.editRefreshIntervalMinutes
        onSelected: key => root.editRefreshIntervalMinutes = Number(key)
      }

      NToggle {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.notifications.label")
        description: pluginApi?.tr("settings.notifications.desc")
        checked: root.editEnableNotifications
        onToggled: checked => root.editEnableNotifications = checked
      }

      NTextInput {
        Layout.fillWidth: true
        label: pluginApi?.tr("settings.terminal.label")
        description: pluginApi?.tr("settings.terminal.desc")
        placeholderText: pluginApi?.tr("settings.terminal.placeholder")
        text: root.editTerminalCommand
        onTextChanged: root.editTerminalCommand = text
      }
    }
  }

  function saveSettings() {
    if (!pluginApi) return;

    pluginApi.pluginSettings.enabledManagerIds = JSON.parse(JSON.stringify(root.editEnabledManagerIds));
    pluginApi.pluginSettings.refreshIntervalMinutes = root.editRefreshIntervalMinutes;
    pluginApi.pluginSettings.iconName = root.editIconName;
    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.pluginSettings.countColor = root.editCountColor;
    pluginApi.pluginSettings.errorColor = root.editErrorColor;
    pluginApi.pluginSettings.enableNotifications = root.editEnableNotifications;
    pluginApi.pluginSettings.terminalCommand = root.editTerminalCommand;
    pluginApi.saveSettings();
    pluginApi.mainInstance?.refresh(false, "settings");
  }

  function setManagerEnabled(id, enabled) {
    var next = root.editEnabledManagerIds.slice();
    var index = next.indexOf(id);

    if (enabled && index === -1) next.push(id);
    if (!enabled && index !== -1) next.splice(index, 1);

    next.sort();
    root.editEnabledManagerIds = next;
  }

  function buildManagerOptions(availableOnly) {
    var source = availableOnly
      ? (mainInstance?.availableManagers ?? [])
      : (mainInstance?.unavailableManagers ?? []);
    var options = [];
    var seen = {};

    for (var i = 0; i < source.length; i++) {
      var manager = source[i];
      if (!manager?.id || seen[manager.id]) continue;
      seen[manager.id] = true;
      options.push({
        "id": manager.id,
        "name": manager.name || manager.id
      });
    }

    if (availableOnly && options.length === 0) {
      var fallbackIds = defaults.enabledManagerIds ?? [];
      for (var j = 0; j < fallbackIds.length; j++) {
        var fallbackId = fallbackIds[j];
        if (seen[fallbackId]) continue;
        seen[fallbackId] = true;
        options.push({
          "id": fallbackId,
          "name": fallbackId
        });
      }
    }

    options.sort(function(a, b) {
      return a.name.localeCompare(b.name);
    });

    return options;
  }

  function resolveColor(key, fallbackColor) {
    if (!key || key === "none") return fallbackColor;
    return Color.resolveColorKey(key);
  }
}
