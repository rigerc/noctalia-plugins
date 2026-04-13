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

  readonly property var managerOptions: buildManagerOptions()

  spacing: Style.marginL

  NBox {
    Layout.fillWidth: true

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NIcon {
        icon: mainInstance?.mpmAvailable ? "circle-check" : "alert-triangle"
        color: mainInstance?.mpmAvailable ? Color.mPrimary : resolveColor(editErrorColor, Color.resolveColorKey("destructive"))
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginXS

        NText {
          text: mainInstance?.mpmAvailable
            ? pluginApi?.tr("settings.backend.detected")
            : pluginApi?.tr("settings.backend.missing")
          color: mainInstance?.mpmAvailable ? Color.mOnSurface : resolveColor(editErrorColor, Color.resolveColorKey("destructive"))
          font.weight: Font.Bold
        }

        NText {
          text: mainInstance?.mpmAvailable
            ? pluginApi?.tr("settings.backend.detail", {
              "version": mainInstance?.mpmVersion || pluginApi?.tr("common.unknown"),
              "path": mainInstance?.mpmPath || pluginApi?.tr("common.unknown")
            })
            : mainInstance?.mpmErrorMessage || pluginApi?.tr("settings.backend.installHint")
          color: Color.mOnSurfaceVariant
          wrapMode: Text.Wrap
        }
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("settings.managers.title")
    font.pointSize: Style.fontSizeM
    font.weight: Font.Medium
    color: Color.mOnSurface
  }

  Repeater {
    model: root.managerOptions

    delegate: NToggle {
      required property var modelData
      Layout.fillWidth: true
      label: modelData.name
      description: modelData.description
      checked: root.editEnabledManagerIds.indexOf(modelData.id) !== -1
      enabled: modelData.available
      onToggled: checked => root.setManagerEnabled(modelData.id, checked)
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("settings.appearance.title")
    font.pointSize: Style.fontSizeM
    font.weight: Font.Medium
    color: Color.mOnSurface
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM

    NLabel {
      Layout.fillWidth: true
      label: pluginApi?.tr("settings.icon.label")
      description: pluginApi?.tr("settings.icon.desc")
    }

    NIcon {
      icon: root.editIconName
      color: resolveColor(root.editIconColor, Color.mPrimary)
      pointSize: Style.fontSizeXXL
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

  NBox {
    Layout.fillWidth: true

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginS

      NIcon {
        icon: root.editIconName
        color: resolveColor(root.editIconColor, Color.mPrimary)
      }

      NText {
        text: "12"
        color: resolveColor(root.editCountColor, Color.mOnSurface)
        font.weight: Font.Bold
      }

      NText {
        text: pluginApi?.tr("settings.preview.label")
        color: Color.mOnSurfaceVariant
      }
    }
  }

  NDivider {
    Layout.fillWidth: true
  }

  NText {
    text: pluginApi?.tr("settings.behavior.title")
    font.pointSize: Style.fontSizeM
    font.weight: Font.Medium
    color: Color.mOnSurface
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

  function buildManagerOptions() {
    var known = {};
    var options = [];
    var defaultsIds = defaults.enabledManagerIds ?? [];
    var selectedIds = editEnabledManagerIds ?? [];
    var available = mainInstance?.availableManagers ?? [];
    var unavailable = mainInstance?.unavailableManagers ?? [];

    function pushOption(id, name, availableState, description) {
      if (!id || known[id]) return;
      known[id] = true;
      options.push({
        "id": id,
        "name": name || id,
        "available": availableState,
        "description": description
      });
    }

    for (var i = 0; i < available.length; i++) {
      var manager = available[i];
      pushOption(
        manager.id,
        manager.name,
        true,
        pluginApi?.tr("settings.managers.available")
      );
    }

    for (var j = 0; j < unavailable.length; j++) {
      var unavailableManager = unavailable[j];
      pushOption(
        unavailableManager.id,
        unavailableManager.name,
        false,
        pluginApi?.tr("settings.managers.unavailable")
      );
    }

    for (var k = 0; k < defaultsIds.length; k++) {
      pushOption(
        defaultsIds[k],
        defaultsIds[k],
        true,
        pluginApi?.tr("settings.managers.available")
      );
    }

    for (var m = 0; m < selectedIds.length; m++) {
      pushOption(
        selectedIds[m],
        selectedIds[m],
        true,
        pluginApi?.tr("settings.managers.available")
      );
    }

    options.sort(function(a, b) {
      if (a.available !== b.available) return a.available ? -1 : 1;
      return a.name.localeCompare(b.name);
    });

    return options;
  }

  function resolveColor(key, fallbackColor) {
    if (!key || key === "none") return fallbackColor;
    return Color.resolveColorKey(key);
  }
}
