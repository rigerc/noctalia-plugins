import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import "../components"
import "../../components"
// qmllint disable unqualified

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
        title: root.rootSettings?.pluginApi?.tr("settings.section.pinnedApps.label")
        description: root.rootSettings?.pluginApi?.tr("settings.section.pinnedApps.desc")

        SettingsSubCard {
            NComboBox {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.position.label")
                description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.position.desc")
                model: root.rootSettings?.pinnedAppsPositionModel
                currentKey: root.rootSettings?.settingValue("pinnedApps", "position") ?? "left"
                defaultValue: root.rootSettings?.defaultValue("pinnedApps", "position") ?? "left"
                onSelected: key => root.rootSettings?.setSetting("pinnedApps", "position", key)
            }

            HybridColorChoice {
                pluginApi: root.rootSettings?.pluginApi
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.iconColor.label")
                description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.iconColor.desc")
                currentColor: root.rootSettings?.settingValue("pinnedApps", "iconColor") ?? "on-surface"
                defaultColor: root.rootSettings?.defaultValue("pinnedApps", "iconColor") ?? "on-surface"
                currentOpacity: 1
                defaultOpacity: 1
                showOpacityControl: false
                onColorSelected: value => root.rootSettings?.setSetting("pinnedApps", "iconColor", value)
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.marginLeft.label")
                description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.marginLeft.desc")
                from: 0
                to: 48
                stepSize: 1
                value: root.rootSettings?.settingValue("pinnedApps", "marginLeft") ?? 8
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("pinnedApps", "marginLeft") ?? 8
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("pinnedApps", "marginLeft", Math.round(sliderValue))
            }

            NValueSlider {
                label: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.marginRight.label")
                description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.marginRight.desc")
                from: 0
                to: 48
                stepSize: 1
                value: root.rootSettings?.settingValue("pinnedApps", "marginRight") ?? 8
                text: Math.round(value) + " px"
                defaultValue: root.rootSettings?.defaultValue("pinnedApps", "marginRight") ?? 8
                showReset: true
                onMoved: sliderValue => root.rootSettings?.setSetting("pinnedApps", "marginRight", Math.round(sliderValue))
            }

            NToggle {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.hideWhenActive.label")
                description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.hideWhenActive.desc")
                checked: root.rootSettings?.settingValue("pinnedApps", "hideWhenActive") ?? false
                defaultValue: root.rootSettings?.defaultValue("pinnedApps", "hideWhenActive") ?? false
                onToggled: checked => root.rootSettings?.setSetting("pinnedApps", "hideWhenActive", checked)
            }

            NComboBox {
                Layout.fillWidth: true
                label: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.activateRunningBehavior.label")
                description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.activateRunningBehavior.desc")
                model: root.rootSettings?.pinnedAppsActivateBehaviorModel
                currentKey: root.rootSettings?.settingValue("pinnedApps", "activateRunningBehavior") ?? "focusCycle"
                defaultValue: root.rootSettings?.defaultValue("pinnedApps", "activateRunningBehavior") ?? "focusCycle"
                onSelected: key => root.rootSettings?.setSetting("pinnedApps", "activateRunningBehavior", key)
            }
        
        }
    }

    SettingsSectionCard {
        id: pinnedItemsCard
        sectionKey: "pinnedApps"
        rootSettings: root.rootSettings
        title: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.items.label")
        description: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.items.desc")

        SettingsSubCard {
            NText {
                visible: (root.rootSettings?.pinnedAppItems().length ?? 0) === 0
                Layout.fillWidth: true
                text: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.items.empty")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: root.rootSettings?.pinnedAppItems() ?? []

                delegate: NBox {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: pinnedAppContent.implicitHeight + Style.marginM * 2

                    property string appId: String(modelData?.appId || "")
                    property string appName: root.rootSettings?.pluginApi?.mainInstance?.getAppNameFromDesktopEntry(appId) || appId
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
                            text: customIconPath !== "" ? customIconPath : root.rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.none")
                            color: Color.mOnSurfaceVariant
                            wrapMode: Text.WrapAnywhere
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NButton {
                                text: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.browse")
                                onClicked: filePicker.openFilePicker()
                            }

                            NButton {
                                enabled: customIconPath !== ""
                                text: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.clear")
                                onClicked: root.rootSettings?.setPinnedAppCustomIcon(appId, "")
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            NButton {
                                text: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.items.remove")
                                onClicked: root.rootSettings?.removePinnedApp(appId)
                            }
                        }
                    }

                    NFilePicker {
                        id: filePicker
                        title: root.rootSettings?.pluginApi?.tr("settings.pinnedApps.customIcon.title")
                        selectionMode: "files"
                        nameFilters: ImageCacheService.basicImageFilters.concat(["*.svg"])
                        initialPath: Quickshell.env("HOME")
                        onAccepted: paths => {
                            if (paths.length > 0)
                                root.rootSettings?.setPinnedAppCustomIcon(appId, paths[0]);
                        }
                    }
                }
            }
        
        }
    }
}
