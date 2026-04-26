import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.System
import qs.Widgets
import "../components"
import "../../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias behaviorSectionTarget: pinnedBehaviorCard.sectionTarget
    property alias itemsSectionTarget: pinnedItemsCard.sectionTarget

    Layout.fillWidth: true
    spacing: Style.marginXL

    SettingsSectionCard {
        id: pinnedBehaviorCard
        sectionKey: "pinnedApps"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.section.pinnedApps.label")
        description: rootSettings?.pluginApi?.tr("settings.section.pinnedApps.desc")

        SettingsSubCard {
            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.pinnedApps.position.label")
                description: rootSettings?.pluginApi?.tr("settings.pinnedApps.position.desc")
                model: rootSettings?.pinnedAppsPositionModel
                currentKey: rootSettings?.settingValue("pinnedApps", "position") ?? "left"
                defaultValue: rootSettings?.defaultValue("pinnedApps", "position") ?? "left"
                onSelected: key => rootSettings?.setSetting("pinnedApps", "position", key)
            }

            HybridColorChoice {
                pluginApi: rootSettings?.pluginApi
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.pinnedApps.iconColor.label")
                description: rootSettings?.pluginApi?.tr("settings.pinnedApps.iconColor.desc")
                currentColor: rootSettings?.settingValue("pinnedApps", "iconColor") ?? "on-surface"
                defaultColor: rootSettings?.defaultValue("pinnedApps", "iconColor") ?? "on-surface"
                currentOpacity: 1
                defaultOpacity: 1
                showOpacityControl: false
                onColorSelected: value => rootSettings?.setSetting("pinnedApps", "iconColor", value)
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.pinnedApps.marginLeft.label")
                description: rootSettings?.pluginApi?.tr("settings.pinnedApps.marginLeft.desc")
                from: 0
                to: 48
                stepSize: 1
                value: rootSettings?.settingValue("pinnedApps", "marginLeft") ?? 8
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("pinnedApps", "marginLeft") ?? 8
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("pinnedApps", "marginLeft", Math.round(sliderValue))
            }

            NValueSlider {
                label: rootSettings?.pluginApi?.tr("settings.pinnedApps.marginRight.label")
                description: rootSettings?.pluginApi?.tr("settings.pinnedApps.marginRight.desc")
                from: 0
                to: 48
                stepSize: 1
                value: rootSettings?.settingValue("pinnedApps", "marginRight") ?? 8
                text: Math.round(value) + " px"
                defaultValue: rootSettings?.defaultValue("pinnedApps", "marginRight") ?? 8
                showReset: true
                onMoved: sliderValue => rootSettings?.setSetting("pinnedApps", "marginRight", Math.round(sliderValue))
            }

            NToggle {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.pinnedApps.hideWhenActive.label")
                description: rootSettings?.pluginApi?.tr("settings.pinnedApps.hideWhenActive.desc")
                checked: rootSettings?.settingValue("pinnedApps", "hideWhenActive") ?? false
                defaultValue: rootSettings?.defaultValue("pinnedApps", "hideWhenActive") ?? false
                onToggled: checked => rootSettings?.setSetting("pinnedApps", "hideWhenActive", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.pinnedApps.activateRunningBehavior.label")
                description: rootSettings?.pluginApi?.tr("settings.pinnedApps.activateRunningBehavior.desc")
                model: rootSettings?.pinnedAppsActivateBehaviorModel
                currentKey: rootSettings?.settingValue("pinnedApps", "activateRunningBehavior") ?? "focusCycle"
                defaultValue: rootSettings?.defaultValue("pinnedApps", "activateRunningBehavior") ?? "focusCycle"
                onSelected: key => rootSettings?.setSetting("pinnedApps", "activateRunningBehavior", key)
            }
        
        }
    }

    SettingsSectionCard {
        id: pinnedItemsCard
        sectionKey: "pinnedApps"
        rootSettings: root.rootSettings
        title: rootSettings?.pluginApi?.tr("settings.pinnedApps.items.label")
        description: rootSettings?.pluginApi?.tr("settings.pinnedApps.items.desc")

        SettingsSubCard {
            NText {
                visible: (rootSettings?.pinnedAppItems().length ?? 0) === 0
                Layout.fillWidth: true
                text: rootSettings?.pluginApi?.tr("settings.pinnedApps.items.empty")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: rootSettings?.pinnedAppItems() ?? []

                delegate: NBox {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: pinnedAppContent.implicitHeight + Style.marginM * 2

                    property string appId: String(modelData?.appId || "")
                    property string appName: rootSettings?.pluginApi?.mainInstance?.getAppNameFromDesktopEntry(appId) || appId
                    property string customIconPath: String(modelData?.customIcon || "")

                    ColumnLayout {
                        id: pinnedAppContent
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginS

                        NText {
                            Layout.fillWidth: true
                            text: appName
                            font.weight: Style.fontWeightSemiBold
                            color: Color.mOnSurface
                            elide: Text.ElideRight
                        }

                        NText {
                            Layout.fillWidth: true
                            text: appId
                            color: Color.mOnSurfaceVariant
                            elide: Text.ElideMiddle
                        }

                        NText {
                            Layout.fillWidth: true
                            text: customIconPath !== "" ? customIconPath : rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.none")
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.WrapAnywhere
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.browse")
                                onClicked: filePicker.openFilePicker()
                            }

                            NButton {
                                enabled: customIconPath !== ""
                                text: rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.clear")
                                onClicked: rootSettings?.setPinnedAppCustomIcon(appId, "")
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.pinnedApps.items.remove")
                                onClicked: rootSettings?.removePinnedApp(appId)
                            }
                        }
                    }

                    NFilePicker {
                        id: filePicker
                        title: rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.title")
                        selectionMode: "files"
                        nameFilters: ImageCacheService.basicImageFilters.concat(["*.svg"])
                        initialPath: Quickshell.env("HOME")
                        onAccepted: paths => {
                            if (paths.length > 0)
                                rootSettings?.setPinnedAppCustomIcon(appId, paths[0]);
                        }
                    }
                }
            }
        
        }
    }
}
