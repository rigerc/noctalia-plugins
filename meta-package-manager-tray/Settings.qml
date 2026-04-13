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
  property int editRefreshIntervalMinutes: normalizeRefreshInterval(cfg.refreshIntervalMinutes ?? defaults.refreshIntervalMinutes ?? 30)
  property string editIconName: cfg.iconName ?? defaults.iconName ?? "package"
  property string editIconColor: cfg.iconColor ?? defaults.iconColor ?? "primary"
  property bool editShowCountText: cfg.showCountText ?? defaults.showCountText ?? true
  property string editCountTextPosition: normalizeCountTextPosition(cfg.countTextPosition ?? defaults.countTextPosition ?? "right")
  property string editCountTextFontFamily: cfg.countTextFontFamily ?? defaults.countTextFontFamily ?? ""
  property string editCountTextFontWeight: normalizeCountTextFontWeight(cfg.countTextFontWeight ?? defaults.countTextFontWeight ?? "bold")
  property real editCountTextScale: normalizeCountTextScale(cfg.countTextScale ?? defaults.countTextScale ?? 1.0)
  property string editCountColor: cfg.countColor ?? defaults.countColor ?? "secondary"
  property string editErrorColor: cfg.errorColor ?? defaults.errorColor ?? "destructive"
  property bool editEnableNotifications: cfg.enableNotifications ?? defaults.enableNotifications ?? false
  property string editTerminalCommand: cfg.terminalCommand ?? defaults.terminalCommand ?? ""

  readonly property var refreshIntervalOptions: [
    { "key": "5", "name": pluginApi?.tr("settings.interval.5m") },
    { "key": "15", "name": pluginApi?.tr("settings.interval.15m") },
    { "key": "30", "name": pluginApi?.tr("settings.interval.30m") },
    { "key": "60", "name": pluginApi?.tr("settings.interval.60m") },
    { "key": "120", "name": pluginApi?.tr("settings.interval.120m") }
  ]
  readonly property var countTextPositionOptions: [
    { "key": "left", "name": pluginApi?.tr("settings.countTextPosition.left") },
    { "key": "right", "name": pluginApi?.tr("settings.countTextPosition.right") }
  ]
  readonly property var countTextFontWeightOptions: [
    { "key": "regular", "name": pluginApi?.tr("settings.countTextFontWeight.regular") },
    { "key": "medium", "name": pluginApi?.tr("settings.countTextFontWeight.medium") },
    { "key": "semibold", "name": pluginApi?.tr("settings.countTextFontWeight.semibold") },
    { "key": "bold", "name": pluginApi?.tr("settings.countTextFontWeight.bold") }
  ]

  readonly property var availableManagerOptions: buildManagerOptions(true)
  readonly property var unavailableManagerOptions: buildManagerOptions(false)
  readonly property int selectedManagerCount: root.editEnabledManagerIds.length
  readonly property string previewCountText: root.editShowCountText ? "12" : ""

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
                font.weight: selected ? Style.fontWeightSemiBold : Style.fontWeightRegular
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

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginS

          NLabel {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.icon.label")
            description: pluginApi?.tr("settings.icon.desc")
          }

          NToggle {
            Layout.fillWidth: true
            label: pluginApi?.tr("settings.showCountText.label")
            description: pluginApi?.tr("settings.showCountText.desc")
            checked: root.editShowCountText
            onToggled: checked => root.editShowCountText = checked
          }
        }

        ColumnLayout {
          spacing: Style.marginS

          Rectangle {
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            Layout.preferredWidth: Math.round(140 * Style.uiScaleRatio)
            Layout.preferredHeight: Math.round(42 * Style.uiScaleRatio)
            radius: Style.radiusL
            color: Style.capsuleColor
            border.color: Style.capsuleBorderColor
            border.width: Style.capsuleBorderWidth

            RowLayout {
              anchors.centerIn: parent
              spacing: Style.marginXS

              NText {
                visible: root.editShowCountText && root.editCountTextPosition === "left"
                text: root.previewCountText
                color: resolveColor(root.editCountColor, Color.mOnSurface)
                pointSize: Style.fontSizeM * root.editCountTextScale
                font.family: root.editCountTextFontFamily !== "" ? root.editCountTextFontFamily : Qt.application.font.family
                font.weight: root.fontWeightForKey(root.editCountTextFontWeight)
              }

              NIcon {
                icon: root.editIconName
                color: resolveColor(root.editIconColor, Color.mPrimary)
              }

              NText {
                visible: root.editShowCountText && root.editCountTextPosition === "right"
                text: root.previewCountText
                color: resolveColor(root.editCountColor, Color.mOnSurface)
                pointSize: Style.fontSizeM * root.editCountTextScale
                font.family: root.editCountTextFontFamily !== "" ? root.editCountTextFontFamily : Qt.application.font.family
                font.weight: root.fontWeightForKey(root.editCountTextFontWeight)
              }
            }
          }

          NButton {
            text: pluginApi?.tr("settings.icon.pick")
            onClicked: iconPicker.open()
          }
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
        enabled: root.editShowCountText
        label: pluginApi?.tr("settings.countColor.label")
        description: pluginApi?.tr("settings.countColor.desc")
        currentKey: root.editCountColor
        onSelected: key => root.editCountColor = key
      }

      NComboBox {
        Layout.fillWidth: true
        enabled: root.editShowCountText
        label: pluginApi?.tr("settings.countTextPosition.label")
        description: pluginApi?.tr("settings.countTextPosition.desc")
        model: root.countTextPositionOptions
        currentKey: root.editCountTextPosition
        onSelected: key => root.editCountTextPosition = key
      }

      NTextInput {
        Layout.fillWidth: true
        enabled: root.editShowCountText
        label: pluginApi?.tr("settings.countTextFontFamily.label")
        description: pluginApi?.tr("settings.countTextFontFamily.desc")
        placeholderText: pluginApi?.tr("settings.countTextFontFamily.placeholder")
        text: root.editCountTextFontFamily
        onTextChanged: root.editCountTextFontFamily = text
      }

      NComboBox {
        Layout.fillWidth: true
        enabled: root.editShowCountText
        label: pluginApi?.tr("settings.countTextFontWeight.label")
        description: pluginApi?.tr("settings.countTextFontWeight.desc")
        model: root.countTextFontWeightOptions
        currentKey: root.editCountTextFontWeight
        onSelected: key => root.editCountTextFontWeight = key
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginS
        enabled: root.editShowCountText

        NLabel {
          Layout.fillWidth: true
          label: pluginApi?.tr("settings.countTextScale.label") + ": " + root.formatScalePercent(root.editCountTextScale)
          description: pluginApi?.tr("settings.countTextScale.desc")
        }

        NSlider {
          Layout.fillWidth: true
          from: 0.8
          to: 1.6
          stepSize: 0.05
          value: root.editCountTextScale
          onValueChanged: root.editCountTextScale = Math.round(value * 20) / 20
        }
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
        currentKey: String(root.editRefreshIntervalMinutes)
        onSelected: key => root.editRefreshIntervalMinutes = root.normalizeRefreshInterval(parseInt(key, 10))
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

    var nextEnabledManagerIds = JSON.parse(JSON.stringify(root.editEnabledManagerIds));
    var nextRefreshIntervalMinutes = root.normalizeRefreshInterval(root.editRefreshIntervalMinutes);
    var shouldRefresh = root.shouldRefreshAfterSave(nextEnabledManagerIds, nextRefreshIntervalMinutes);

    pluginApi.pluginSettings.enabledManagerIds = nextEnabledManagerIds;
    pluginApi.pluginSettings.refreshIntervalMinutes = nextRefreshIntervalMinutes;
    pluginApi.pluginSettings.iconName = root.editIconName;
    pluginApi.pluginSettings.iconColor = root.editIconColor;
    pluginApi.pluginSettings.showCountText = root.editShowCountText;
    pluginApi.pluginSettings.countTextPosition = root.normalizeCountTextPosition(root.editCountTextPosition);
    pluginApi.pluginSettings.countTextFontFamily = root.editCountTextFontFamily.trim();
    pluginApi.pluginSettings.countTextFontWeight = root.normalizeCountTextFontWeight(root.editCountTextFontWeight);
    pluginApi.pluginSettings.countTextScale = root.normalizeCountTextScale(root.editCountTextScale);
    pluginApi.pluginSettings.countColor = root.editCountColor;
    pluginApi.pluginSettings.errorColor = root.editErrorColor;
    pluginApi.pluginSettings.enableNotifications = root.editEnableNotifications;
    pluginApi.pluginSettings.terminalCommand = root.editTerminalCommand;
    pluginApi.saveSettings();

    if (shouldRefresh) {
      pluginApi.mainInstance?.refresh(false, "settings");
    }
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

  function normalizeRefreshInterval(value) {
    var numericValue = parseInt(value, 10);
    var validValues = [5, 15, 30, 60, 120];

    if (validValues.indexOf(numericValue) !== -1) return numericValue;
    return defaults.refreshIntervalMinutes ?? 30;
  }

  function fontWeightForKey(key) {
    switch (key) {
    case "regular":
      return Style.fontWeightRegular;
    case "medium":
      return Style.fontWeightMedium;
    case "semibold":
      return Style.fontWeightSemiBold;
    case "bold":
    default:
      return Style.fontWeightBold;
    }
  }

  function formatScalePercent(value) {
    return Math.round(value * 100) + "%";
  }

  function shouldRefreshAfterSave(nextEnabledManagerIds, nextRefreshIntervalMinutes) {
    var currentEnabledManagerIds = cfg.enabledManagerIds ?? defaults.enabledManagerIds ?? [];
    var currentRefreshIntervalMinutes = normalizeRefreshInterval(cfg.refreshIntervalMinutes ?? defaults.refreshIntervalMinutes ?? 30);

    if (nextRefreshIntervalMinutes !== currentRefreshIntervalMinutes) return true;
    if (nextEnabledManagerIds.length !== currentEnabledManagerIds.length) return true;

    for (var i = 0; i < nextEnabledManagerIds.length; i++) {
      if (nextEnabledManagerIds[i] !== currentEnabledManagerIds[i]) return true;
    }

    return false;
  }

  function normalizeCountTextPosition(value) {
    return value === "left" ? "left" : "right";
  }

  function normalizeCountTextFontWeight(value) {
    switch (value) {
    case "regular":
    case "medium":
    case "semibold":
    case "bold":
      return value;
    default:
      return "bold";
    }
  }

  function normalizeCountTextScale(value) {
    var numericValue = Number(value);

    if (isNaN(numericValue)) return 1.0;
    return Math.max(0.8, Math.min(1.6, numericValue));
  }
}
