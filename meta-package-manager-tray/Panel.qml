import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true
  readonly property var mainInstance: pluginApi?.mainInstance
  readonly property var visibleResults: (mainInstance?.managerResults || []).filter(function(manager) {
    return (manager.packageCount || 0) > 0 || (manager.errorCount || 0) > 0;
  })

  property real contentPreferredWidth: 540 * Style.uiScaleRatio
  property real contentPreferredHeight: 600 * Style.uiScaleRatio

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginM
      spacing: Style.marginM

      NBox {
        Layout.fillWidth: true
        implicitHeight: headerColumn.implicitHeight + Style.marginXL

        ColumnLayout {
          id: headerColumn
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Style.marginM
          spacing: Style.marginM

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Style.marginXXS

              NText {
                text: pluginApi?.tr("panel.title")
                pointSize: Style.fontSizeXL
                font.weight: Style.fontWeightBold
                color: Color.mOnSurface
              }

              NText {
                Layout.fillWidth: true
                text: pluginApi?.tr("panel.lastChecked", {
                  "time": mainInstance?.formatTimestamp(mainInstance?.lastCheckedAt ?? 0)
                })
                pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
              }
            }

            NButton {
              text: pluginApi?.tr("panel.refresh")
              onClicked: mainInstance?.manualRefresh()
            }

            NButton {
              text: pluginApi?.tr("panel.upgrade")
              enabled: mainInstance?.canRunUpgrade ?? false
              onClicked: mainInstance?.upgrade()
            }

            NIconButton {
              icon: "settings"
              onClicked: {
                BarService.openPluginSettings(pluginApi.panelOpenScreen, pluginApi.manifest);
                pluginApi.closePanel(pluginApi.panelOpenScreen);
              }
            }
          }

          GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Style.marginS
            rowSpacing: Style.marginS

            Repeater {
              model: [
                {
                  "label": pluginApi?.tr("panel.summary.updates"),
                  "value": String(mainInstance?.totalUpdateCount ?? 0),
                  "color": Color.mPrimary
                },
                {
                  "label": pluginApi?.tr("panel.summary.managers"),
                  "value": String(mainInstance?.activeManagerIds?.length ?? 0),
                  "color": Color.mSecondary
                },
                {
                  "label": pluginApi?.tr("panel.summary.errors"),
                  "value": String(countManagerErrors()),
                  "color": Color.resolveColorKey("destructive")
                }
              ]

              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Math.round(62 * Style.uiScaleRatio)
                radius: Style.radiusL
                color: Color.mSurfaceVariant

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: Style.marginXXS

                  NText {
                    text: modelData.value
                    color: modelData.color
                    font.weight: Style.fontWeightBold
                    pointSize: Style.fontSizeM
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                  }

                  NText {
                    text: modelData.label
                    color: Color.mOnSurfaceVariant
                    pointSize: Style.fontSizeS
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                  }
                }
              }
            }
          }
        }
      }

      NScrollView {
        id: scrollView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        horizontalPolicy: ScrollBar.AlwaysOff
        reserveScrollbarSpace: false
        gradientColor: Color.mSurface

        ColumnLayout {
          width: scrollView.availableWidth
          spacing: Style.marginM

          NBox {
            visible: shouldShowStateCard()
            Layout.fillWidth: true
            implicitHeight: stateColumn.implicitHeight + Style.marginXL

            ColumnLayout {
              id: stateColumn
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
                  color: Qt.alpha(stateAccentColor(), 0.14)

                  NIcon {
                    anchors.centerIn: parent
                    icon: stateIconName()
                    color: stateAccentColor()
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginXXS

                  NText {
                    text: stateTitle()
                    pointSize: Style.fontSizeM
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                  }

                  NText {
                    Layout.fillWidth: true
                    text: stateMessage()
                    color: Color.mOnSurfaceVariant
                    wrapMode: Text.WordWrap
                  }

                  NText {
                    visible: stateDetail() !== ""
                    Layout.fillWidth: true
                    text: stateDetail()
                    color: stateAccentColor()
                    wrapMode: Text.WordWrap
                  }
                }
              }
            }
          }

          Repeater {
            model: root.visibleResults

            delegate: NBox {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: cardColumn.implicitHeight + Style.marginXL

              ColumnLayout {
                id: cardColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.marginM
                spacing: Style.marginS

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginM

                  NText {
                    Layout.fillWidth: true
                    text: modelData.name
                    pointSize: Style.fontSizeL
                    font.weight: Style.fontWeightSemiBold
                    color: Color.mOnSurface
                    elide: Text.ElideRight
                  }

                  Rectangle {
                    implicitWidth: badgeLabel.implicitWidth + Math.round(18 * Style.uiScaleRatio)
                    implicitHeight: Math.round(26 * Style.uiScaleRatio)
                    radius: implicitHeight / 2
                    color: modelData.errorCount > 0
                      ? Qt.alpha(Color.resolveColorKey("destructive"), 0.14)
                      : Qt.alpha(Color.mSecondary, 0.14)

                    NText {
                      id: badgeLabel
                      anchors.centerIn: parent
                      text: pluginApi?.tr("panel.managerSummary", {
                        "count": modelData.packageCount
                      })
                      color: modelData.errorCount > 0 ? Color.resolveColorKey("destructive") : Color.mSecondary
                      font.weight: Style.fontWeightSemiBold
                      pointSize: Style.fontSizeS
                    }
                  }
                }

                Repeater {
                  model: modelData.errors || []

                  delegate: Rectangle {
                    required property string modelData
                    Layout.fillWidth: true
                    implicitHeight: errorText.implicitHeight + Style.marginM * 2
                    radius: Style.radiusM
                    color: Qt.alpha(Color.resolveColorKey("destructive"), 0.08)
                    border.color: Qt.alpha(Color.resolveColorKey("destructive"), 0.3)
                    border.width: Style.borderS

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: Style.marginM
                      spacing: Style.marginS

                      NIcon {
                        icon: "alert-triangle"
                        color: Color.resolveColorKey("destructive")
                        Layout.alignment: Qt.AlignTop
                      }

                      NText {
                        id: errorText
                        Layout.fillWidth: true
                        text: modelData
                        color: Color.resolveColorKey("destructive")
                        wrapMode: Text.WordWrap
                      }
                    }
                  }
                }

                Repeater {
                  model: modelData.packages || []

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: packageColumn.implicitHeight + Style.marginM * 2
                    radius: Style.radiusM
                    color: Color.mSurfaceVariant

                    RowLayout {
                      anchors.fill: parent
                      anchors.margins: Style.marginM
                      spacing: Style.marginM

                      Rectangle {
                        Layout.preferredWidth: Math.round(30 * Style.uiScaleRatio)
                        Layout.preferredHeight: Math.round(30 * Style.uiScaleRatio)
                        radius: Style.radiusM
                        color: Qt.alpha(Color.mPrimary, 0.12)

                        NIcon {
                          anchors.centerIn: parent
                          icon: "package"
                          color: Color.mPrimary
                          pointSize: Style.fontSizeS
                        }
                      }

                      ColumnLayout {
                        id: packageColumn
                        Layout.fillWidth: true
                        spacing: Style.marginXXS

                        NText {
                          Layout.fillWidth: true
                          text: modelData.displayName
                          color: Color.mOnSurface
                          font.weight: Style.fontWeightSemiBold
                          wrapMode: Text.WordWrap
                        }

                        NText {
                          Layout.fillWidth: true
                          text: pluginApi?.tr("panel.packageVersion", {
                            "installed": modelData.installedVersion || pluginApi?.tr("common.unknown"),
                            "latest": modelData.latestVersion || pluginApi?.tr("common.unknown")
                          })
                          pointSize: Style.fontSizeS
                          color: Color.mOnSurfaceVariant
                          wrapMode: Text.WordWrap
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  function countManagerErrors() {
    var results = mainInstance?.managerResults || [];
    var count = 0;
    for (var i = 0; i < results.length; i++) {
      count += results[i]?.errorCount || 0;
    }
    return count;
  }

  function shouldShowStateCard() {
    if (mainInstance?.isRefreshing ?? false) return true;
    if (!(mainInstance?.mpmAvailable ?? false)) return true;
    if ((mainInstance?.activeManagerIds?.length ?? 0) === 0) return true;
    if ((mainInstance?.hasError ?? false) && root.visibleResults.length === 0) return true;
    if ((mainInstance?.totalUpdateCount ?? 0) === 0 && !(mainInstance?.hasError ?? false)) return true;
    return false;
  }

  function stateIconName() {
    if (mainInstance?.isRefreshing ?? false) return "loader";
    if (!(mainInstance?.mpmAvailable ?? false)) return "alert-triangle";
    if ((mainInstance?.activeManagerIds?.length ?? 0) === 0) return "settings";
    if ((mainInstance?.hasError ?? false) && root.visibleResults.length === 0) return "alert-triangle";
    return "circle-check";
  }

  function stateAccentColor() {
    if (mainInstance?.isRefreshing ?? false) return Color.mPrimary;
    if (!(mainInstance?.mpmAvailable ?? false)) return Color.resolveColorKey("destructive");
    if ((mainInstance?.hasError ?? false) && root.visibleResults.length === 0) return Color.resolveColorKey("destructive");
    return Color.mSecondary;
  }

  function stateTitle() {
    if (mainInstance?.isRefreshing ?? false) return pluginApi?.tr("panel.state.checkingTitle");
    if (!(mainInstance?.mpmAvailable ?? false)) return pluginApi?.tr("panel.state.unavailableTitle");
    if ((mainInstance?.activeManagerIds?.length ?? 0) === 0) return pluginApi?.tr("panel.state.noManagersTitle");
    if ((mainInstance?.hasError ?? false) && root.visibleResults.length === 0) return pluginApi?.tr("panel.state.errorTitle");
    return pluginApi?.tr("panel.state.noUpdatesTitle");
  }

  function stateMessage() {
    if (mainInstance?.isRefreshing ?? false) return pluginApi?.tr("panel.checking");
    if (!(mainInstance?.mpmAvailable ?? false)) return pluginApi?.tr("panel.installHint");
    if ((mainInstance?.activeManagerIds?.length ?? 0) === 0) return pluginApi?.tr("panel.noActiveManagers");
    if ((mainInstance?.hasError ?? false) && root.visibleResults.length === 0) return pluginApi?.tr("panel.genericError");
    return pluginApi?.tr("panel.noUpdates");
  }

  function stateDetail() {
    if (!(mainInstance?.mpmAvailable ?? false)) return mainInstance?.mpmErrorMessage ?? "";
    if ((mainInstance?.hasError ?? false) && root.visibleResults.length === 0) return mainInstance?.errorMessage ?? "";
    return "";
  }
}
