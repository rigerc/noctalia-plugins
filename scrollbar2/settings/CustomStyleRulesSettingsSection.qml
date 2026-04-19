import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    readonly property var mainInstance: rootSettings?.mainInstance ?? null

    Layout.fillWidth: true
    spacing: Style.marginL

    function previewIconColor(colorKey) {
        const key = String(colorKey || "");
        switch (key) {
        case "primary":
            return Color.mPrimary;
        case "on-primary":
            return Color.mOnPrimary;
        case "secondary":
            return Color.mSecondary;
        case "on-secondary":
            return Color.mOnSecondary;
        case "tertiary":
            return Color.mTertiary;
        case "on-tertiary":
            return Color.mOnTertiary;
        case "error":
            return Color.mError;
        case "on-error":
            return Color.mOnError;
        case "surface":
            return Color.mSurface;
        case "on-surface":
            return Color.mOnSurface;
        case "surface-variant":
            return Color.mSurfaceVariant;
        case "on-surface-variant":
            return Color.mOnSurfaceVariant;
        case "outline":
            return Color.mOutline;
        case "hover":
            return Color.mHover;
        case "on-hover":
            return Color.mOnHover;
        default:
            return Color.mOnSurfaceVariant;
        }
    }

    NBox {
        Layout.fillWidth: true
        Layout.preferredHeight: sectionContent.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: sectionContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.section.customStyleRules.label")
                description: rootSettings?.pluginApi?.tr("settings.section.customStyleRules.desc")
            }

            NText {
                Layout.fillWidth: true
                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.regexHelp")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.actions.add")
                icon: "plus"
                onClicked: rootSettings?.addStyleRule()
            }

            NText {
                visible: (rootSettings?.styleRuleSnapshot.length ?? 0) === 0
                Layout.fillWidth: true
                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.empty")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: rootSettings?.styleRuleSnapshot ?? []

                delegate: NBox {
                    id: ruleCard

                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    Layout.preferredHeight: ruleContent.implicitHeight + Style.marginM * 2

                    readonly property bool regexValid: rootSettings?.isValidRegex(modelData?.pattern) ?? true
                    readonly property bool editTarget: (root.mainInstance?.requestedStyleRuleRevision ?? 0) > 0
                        && String(root.mainInstance?.requestedStyleRuleMatchField || "") === String(modelData?.matchField || "appId")
                        && String(root.mainInstance?.requestedStyleRulePattern || "") === String(modelData?.pattern || "").trim()

                    ColumnLayout {
                        id: ruleContent
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NText {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.ruleTitle", {
                                    "index": index + 1
                                })
                                font.weight: Style.fontWeightSemiBold
                                color: Color.mOnSurface
                            }

                            NText {
                                visible: ruleCard.editTarget
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.editing")
                                color: Color.mPrimary
                                font.weight: Style.fontWeightSemiBold
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.actions.moveUp")
                                icon: "chevron-up"
                                enabled: index > 0
                                onClicked: rootSettings?.moveStyleRule(index, -1)
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.actions.moveDown")
                                icon: "chevron-down"
                                enabled: index < ((rootSettings?.styleRuleSnapshot.length ?? 0) - 1)
                                onClicked: rootSettings?.moveStyleRule(index, 1)
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.actions.remove")
                                icon: "trash"
                                onClicked: rootSettings?.removeStyleRule(index)
                            }
                        }

                        NToggle {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.enabled.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.enabled.desc")
                            checked: modelData?.enabled !== false
                            onToggled: checked => rootSettings?.updateStyleRule(index, {
                                    "enabled": checked
                                })
                            defaultValue: true
                        }

                        NComboBox {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.matchField.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.matchField.desc")
                            model: [
                                {
                                    "key": "appId",
                                    "name": rootSettings?.pluginApi?.tr("settings.customStyleRules.matchField.appId")
                                },
                                {
                                    "key": "title",
                                    "name": rootSettings?.pluginApi?.tr("settings.customStyleRules.matchField.title")
                                }
                            ]
                            currentKey: modelData?.matchField ?? "appId"
                            defaultValue: "appId"
                            onSelected: key => rootSettings?.updateStyleRule(index, {
                                    "matchField": key
                                })
                        }

                        NTextInput {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.desc")
                            placeholderText: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.placeholder")
                            text: modelData?.pattern ?? ""
                            onTextChanged: rootSettings?.updateStyleRule(index, {
                                    "pattern": text
                                })
                        }

                        NText {
                            visible: !regexValid && String(modelData?.pattern || "").trim() !== ""
                            Layout.fillWidth: true
                            text: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.invalid")
                            color: Color.mError
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginM

                            NLabel {
                                Layout.fillWidth: true
                                label: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.label")
                                description: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.desc")
                            }

                            NIcon {
                                icon: String(modelData?.customIcon || "")
                                pointSize: Style.fontSizeXL
                                visible: icon !== ""
                                color: root.previewIconColor(String(modelData?.colors?.icon?.default?.color ?? "on-surface-variant"))
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.pick")
                                onClicked: {
                                    iconPicker.activeIndex = index;
                                    iconPicker.initialIcon = String(modelData?.customIcon || "");
                                    iconPicker.open();
                                }
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.clear")
                                enabled: String(modelData?.customIcon || "") !== ""
                                onClicked: rootSettings?.updateStyleRule(index, {
                                        "customIcon": ""
                                    })
                            }
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.segmentColors.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.segmentColors.desc")
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.label")
                            description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.focused.desc")
                            currentColor: modelData?.colors?.segment?.focused?.color ?? "primary"
                            defaultColor: rootSettings?.defaultStateValue("focusLine", "colors", "focused", "color") ?? "primary"
                            currentOpacity: modelData?.colors?.segment?.focused?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("focusLine", "colors", "focused", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "segment", "focused", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "segment", "focused", "opacity", value)
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.label")
                            description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.hover.desc")
                            currentColor: modelData?.colors?.segment?.hover?.color ?? "hover"
                            defaultColor: rootSettings?.defaultStateValue("focusLine", "colors", "hover", "color") ?? "hover"
                            currentOpacity: modelData?.colors?.segment?.hover?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("focusLine", "colors", "hover", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "segment", "hover", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "segment", "hover", "opacity", value)
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.label")
                            description: rootSettings?.pluginApi?.tr("settings.focusLine.colors.default.desc")
                            currentColor: modelData?.colors?.segment?.default?.color ?? "surface-variant"
                            defaultColor: rootSettings?.defaultStateValue("focusLine", "colors", "default", "color") ?? "surface-variant"
                            currentOpacity: modelData?.colors?.segment?.default?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("focusLine", "colors", "default", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "segment", "default", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "segment", "default", "opacity", value)
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconColors.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconColors.desc")
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.window.iconColors.focused.label")
                            description: rootSettings?.pluginApi?.tr("settings.window.iconColors.focused.desc")
                            currentColor: modelData?.colors?.icon?.focused?.color ?? "on-surface"
                            defaultColor: rootSettings?.defaultStateValue("window", "iconColors", "focused", "color") ?? "on-surface"
                            currentOpacity: modelData?.colors?.icon?.focused?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("window", "iconColors", "focused", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "icon", "focused", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "icon", "focused", "opacity", value)
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.label")
                            description: rootSettings?.pluginApi?.tr("settings.window.iconColors.hover.desc")
                            currentColor: modelData?.colors?.icon?.hover?.color ?? "on-hover"
                            defaultColor: rootSettings?.defaultStateValue("window", "iconColors", "hover", "color") ?? "on-hover"
                            currentOpacity: modelData?.colors?.icon?.hover?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("window", "iconColors", "hover", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "icon", "hover", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "icon", "hover", "opacity", value)
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.label")
                            description: rootSettings?.pluginApi?.tr("settings.window.iconColors.default.desc")
                            currentColor: modelData?.colors?.icon?.default?.color ?? "on-surface-variant"
                            defaultColor: rootSettings?.defaultStateValue("window", "iconColors", "default", "color") ?? "on-surface-variant"
                            currentOpacity: modelData?.colors?.icon?.default?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("window", "iconColors", "default", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "icon", "default", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "icon", "default", "opacity", value)
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.titleColors.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.titleColors.desc")
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.label")
                            description: rootSettings?.pluginApi?.tr("settings.window.titleColors.focused.desc")
                            currentColor: modelData?.colors?.title?.focused?.color ?? "on-surface"
                            defaultColor: rootSettings?.defaultStateValue("window", "titleColors", "focused", "color") ?? "on-surface"
                            currentOpacity: modelData?.colors?.title?.focused?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("window", "titleColors", "focused", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "title", "focused", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "title", "focused", "opacity", value)
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.label")
                            description: rootSettings?.pluginApi?.tr("settings.window.titleColors.hover.desc")
                            currentColor: modelData?.colors?.title?.hover?.color ?? "on-hover"
                            defaultColor: rootSettings?.defaultStateValue("window", "titleColors", "hover", "color") ?? "on-hover"
                            currentOpacity: modelData?.colors?.title?.hover?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("window", "titleColors", "hover", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "title", "hover", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "title", "hover", "opacity", value)
                        }

                        HybridColorChoice {
                            pluginApi: rootSettings?.pluginApi
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.label")
                            description: rootSettings?.pluginApi?.tr("settings.window.titleColors.default.desc")
                            currentColor: modelData?.colors?.title?.default?.color ?? "on-surface-variant"
                            defaultColor: rootSettings?.defaultStateValue("window", "titleColors", "default", "color") ?? "on-surface-variant"
                            currentOpacity: modelData?.colors?.title?.default?.opacity ?? 1
                            defaultOpacity: rootSettings?.defaultStateValue("window", "titleColors", "default", "opacity") ?? 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleColorState(index, "title", "default", "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleColorState(index, "title", "default", "opacity", value)
                        }
                    }
                }
            }
        }
    }

    NIconPicker {
        id: iconPicker

        property int activeIndex: -1

        initialIcon: ""
        onIconSelected: iconName => {
            if (activeIndex >= 0)
                rootSettings?.updateStyleRule(activeIndex, {
                        "customIcon": iconName
                    });
        }
    }
}
