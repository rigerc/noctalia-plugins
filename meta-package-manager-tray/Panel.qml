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

  property real contentPreferredWidth: 520 * Style.uiScaleRatio
  property real contentPreferredHeight: 560 * Style.uiScaleRatio

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginL

      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.marginXS

          NText {
            text: pluginApi?.tr("panel.title")
            pointSize: Style.fontSizeXL
            font.weight: Font.Bold
            color: Color.mOnSurface
          }

          NText {
            text: pluginApi?.tr("panel.lastChecked", {
              "time": mainInstance?.formatTimestamp(mainInstance?.lastCheckedAt ?? 0)
            })
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
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
            Layout.fillWidth: true

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Style.marginM
              spacing: Style.marginS

              NText {
                visible: mainInstance?.isRefreshing ?? false
                text: pluginApi?.tr("panel.checking")
                color: Color.mPrimary
              }

              NText {
                visible: !(mainInstance?.mpmAvailable ?? false)
                text: pluginApi?.tr("panel.mpmUnavailable")
                color: Color.resolveColorKey("destructive")
                wrapMode: Text.Wrap
              }

              NText {
                visible: !(mainInstance?.mpmAvailable ?? false)
                text: mainInstance?.mpmErrorMessage ?? ""
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
              }

              NText {
                visible: !(mainInstance?.mpmAvailable ?? false)
                text: pluginApi?.tr("panel.installHint")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
              }

              NText {
                visible: (mainInstance?.mpmAvailable ?? false) && (mainInstance?.activeManagerIds?.length ?? 0) === 0
                text: pluginApi?.tr("panel.noActiveManagers")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
              }

              NText {
                visible: (mainInstance?.mpmAvailable ?? false)
                  && !(mainInstance?.isRefreshing ?? false)
                  && (mainInstance?.activeManagerIds?.length ?? 0) > 0
                  && (mainInstance?.totalUpdateCount ?? 0) === 0
                  && !(mainInstance?.hasError ?? false)
                text: pluginApi?.tr("panel.noUpdates")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
              }

              NText {
                visible: (mainInstance?.hasError ?? false)
                  && !(mainInstance?.isRefreshing ?? false)
                  && !(mainInstance?.hasLastSuccessfulData ?? false)
                  && (mainInstance?.mpmAvailable ?? false)
                text: mainInstance?.errorMessage ?? pluginApi?.tr("panel.genericError")
                color: Color.resolveColorKey("destructive")
                wrapMode: Text.Wrap
              }
            }
          }

          Repeater {
            model: (mainInstance?.mpmAvailable ?? false) && root.visibleResults.length > 0 ? root.visibleResults : []

            delegate: NBox {
              required property var modelData
              Layout.fillWidth: true

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginS

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Style.marginM

                  NText {
                    Layout.fillWidth: true
                    text: modelData.name
                    pointSize: Style.fontSizeL
                    font.weight: Font.Bold
                    color: Color.mOnSurface
                  }

                  NText {
                    text: pluginApi?.tr("panel.managerSummary", {
                      "count": modelData.packageCount
                    })
                    color: modelData.errorCount > 0 ? Color.resolveColorKey("destructive") : Color.mSecondary
                  }
                }

                Repeater {
                  model: modelData.errors || []

                  delegate: NText {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    color: Color.resolveColorKey("destructive")
                    wrapMode: Text.Wrap
                  }
                }

                Repeater {
                  model: modelData.packages || []

                  delegate: NBox {
                    required property var modelData
                    Layout.fillWidth: true

                    ColumnLayout {
                      anchors.fill: parent
                      anchors.margins: Style.marginS
                      spacing: Style.marginXS

                      NText {
                        Layout.fillWidth: true
                        text: modelData.displayName
                        color: Color.mOnSurface
                        wrapMode: Text.Wrap
                      }

                      NText {
                        Layout.fillWidth: true
                        text: pluginApi?.tr("panel.packageVersion", {
                          "installed": modelData.installedVersion || pluginApi?.tr("common.unknown"),
                          "latest": modelData.latestVersion || pluginApi?.tr("common.unknown")
                        })
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                        wrapMode: Text.Wrap
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
