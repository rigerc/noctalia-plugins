import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

ColumnLayout {
    id: root

    property var rootSettings: null
    property alias rulesSectionTarget: sectionContent
    readonly property var mainInstance: rootSettings?.mainInstance ?? null

    property var _cachedRules: []
    property int _targetRevision: 0

    Timer {
        id: updateTimer
        interval: 0
        repeat: false
        onTriggered: {
            root._cachedRules = rootSettings?.styleRuleItems() ?? [];
        }
    }

    Connections {
        target: rootSettings
        function onStyleRulesRevisionChanged() {
            updateTimer.restart();
        }
    }

    Component.onCompleted: {
        root._cachedRules = rootSettings?.styleRuleItems() ?? [];
    }

    Layout.fillWidth: true
    spacing: Style.marginL

    function previewIconColor(colorKey) {
        const resolved = root.mainInstance?.resolveSettingColor?.(String(colorKey || ""), undefined);
        return resolved !== undefined ? resolved : Color.mOnSurfaceVariant;
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
                visible: _cachedRules.length === 0
                Layout.fillWidth: true
                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.empty")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.WordWrap
            }

            Repeater {
                model: _cachedRules

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

                            Item { Layout.fillWidth: true }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.actions.moveUp")
                                icon: "chevron-up"
                                enabled: index > 0
                                onClicked: rootSettings?.moveStyleRule(index, -1)
                            }

                            NButton {
                                text: rootSettings?.pluginApi?.tr("settings.customStyleRules.actions.moveDown")
                                icon: "chevron-down"
                                enabled: index < (root._cachedRules.length - 1)
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
                            onToggled: checked => rootSettings?.updateStyleRule(index, { "enabled": checked })
                            defaultValue: true
                        }

                        NComboBox {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.matchField.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.matchField.desc")
                            model: rootSettings?.styleRuleMatchFieldModel ?? []
                            currentKey: modelData?.matchField ?? "appId"
                            defaultValue: "appId"
                            onSelected: key => rootSettings?.updateStyleRule(index, {
                                "matchField": rootSettings?.normalizeStyleRuleMatchField(key) ?? "appId"
                            })
                        }

                        NTextInput {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.desc")
                            placeholderText: rootSettings?.styleRulePatternPlaceholder(modelData?.matchField ?? "appId") ?? ""
                            text: modelData?.pattern ?? ""
                            onTextChanged: rootSettings?.updateStyleRule(index, { "pattern": text })
                        }

                        NText {
                            visible: !regexValid && String(modelData?.pattern || "").trim() !== ""
                            Layout.fillWidth: true
                            text: rootSettings?.pluginApi?.tr("settings.customStyleRules.pattern.invalid")
                            color: Color.mError
                            wrapMode: Text.WordWrap
                        }

                        IconPickerField {
                            Layout.fillWidth: true
                            rootSettings: root.rootSettings
                            pluginApi: rootSettings?.pluginApi
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.desc")
                            currentIcon: String(modelData?.customIcon || "")
                            previewColor: root.previewIconColor(String(modelData?.colors?.icon?.default?.color ?? "on-surface-variant"))
                            iconPicker: iconPicker
                            pickerIndex: index
                            pickText: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.pick") ?? "Pick"
                            clearText: rootSettings?.pluginApi?.tr("settings.customStyleRules.customIcon.clear") ?? "Clear"
                            onIconCleared: rootSettings?.updateStyleRule(index, { "customIcon": "" })
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.segmentColors.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.segmentColors.desc")
                        }

                        ColorStateEditor {
                            rootSettings: root.rootSettings
                            styleRuleMode: true
                            ruleData: modelData
                            ruleIndex: ruleCard.index
                            styleRuleColorGroup: "segment"
                            showEnabledToggles: true
                            defaultEnabled: false
                            defaultColors: ({
                                "focused": "primary",
                                "hover": "hover",
                                "default": "surface-variant"
                            })
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconColors.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconColors.desc")
                        }

                        ColorStateEditor {
                            rootSettings: root.rootSettings
                            styleRuleMode: true
                            ruleData: modelData
                            ruleIndex: ruleCard.index
                            styleRuleColorGroup: "icon"
                            showEnabledToggles: true
                            defaultEnabled: false
                            defaultColors: ({
                                "focused": "on-surface",
                                "hover": "on-hover",
                                "default": "on-surface-variant"
                            })
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.titleColors.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.titleColors.desc")
                        }

                        ColorStateEditor {
                            rootSettings: root.rootSettings
                            styleRuleMode: true
                            ruleData: modelData
                            ruleIndex: ruleCard.index
                            styleRuleColorGroup: "title"
                            showEnabledToggles: true
                            defaultEnabled: false
                            defaultColors: ({
                                "focused": "on-surface",
                                "hover": "on-hover",
                                "default": "on-surface-variant"
                            })
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.desc")
                        }

                        NToggle {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.enabled.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.enabled.desc")
                            checked: modelData?.blink?.enabled ?? false
                            onToggled: checked => rootSettings?.updateStyleRuleBlink(index, { "enabled": checked })
                            defaultValue: false
                        }

                        SettingsColorField {
                            pluginApi: rootSettings?.pluginApi
                            rootSettings: root.rootSettings
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.color.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.color.desc")
                            currentColor: modelData?.blink?.color?.color ?? "primary"
                            defaultColor: "primary"
                            currentOpacity: modelData?.blink?.color?.opacity ?? 1
                            defaultOpacity: 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleBlinkColor(index, "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleBlinkColor(index, "opacity", value)
                        }

                        NValueSlider {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.interval.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.blink.interval.desc")
                            from: 200; to: 5000; stepSize: 50
                            value: Math.max(200, Math.min(5000, modelData?.blink?.interval ?? 800))
                            text: value + " ms"
                            defaultValue: 800
                            showReset: true
                            onMoved: sliderValue => rootSettings?.updateStyleRuleBlink(index, { "interval": Math.round(sliderValue) })
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.desc")
                        }

                        NToggle {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.enabled.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.enabled.desc")
                            checked: modelData?.badge?.enabled ?? false
                            onToggled: checked => rootSettings?.updateStyleRuleBadge(index, { "enabled": checked })
                            defaultValue: false
                        }

                        SettingsColorField {
                            pluginApi: rootSettings?.pluginApi
                            rootSettings: root.rootSettings
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.color.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.color.desc")
                            currentColor: modelData?.badge?.color?.color ?? "error"
                            defaultColor: "error"
                            currentOpacity: modelData?.badge?.color?.opacity ?? 1
                            defaultOpacity: 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleBadgeColor(index, "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleBadgeColor(index, "opacity", value)
                        }

                        NComboBox {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.target.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.target.desc")
                            model: rootSettings?.styleRuleBadgeTargetModel ?? []
                            currentKey: modelData?.badge?.target ?? "icon"
                            defaultValue: "icon"
                            onSelected: key => rootSettings?.updateStyleRuleBadge(index, {
                                "target": rootSettings?.normalizeBadgeTarget(key) ?? "icon"
                            })
                        }

                        NComboBox {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.position.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.position.desc")
                            model: rootSettings?.styleRuleBadgePositionModel ?? []
                            currentKey: modelData?.badge?.position ?? "top-right"
                            defaultValue: "top-right"
                            onSelected: key => rootSettings?.updateStyleRuleBadge(index, {
                                "position": rootSettings?.normalizeBadgePosition(key) ?? "top-right"
                            })
                        }

                        NValueSlider {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.size.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.badge.size.desc")
                            from: 2; to: 16; stepSize: 1
                            value: Math.max(2, Math.min(16, modelData?.badge?.size ?? 6))
                            text: value + " px"
                            defaultValue: 6
                            showReset: true
                            onMoved: sliderValue => rootSettings?.updateStyleRuleBadge(index, { "size": Math.round(sliderValue) })
                        }

                        NHeader {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.desc")
                        }

                        NToggle {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.enabled.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.enabled.desc")
                            checked: modelData?.iconPrefix?.enabled ?? false
                            onToggled: checked => rootSettings?.updateStyleRuleIconPrefix(index, { "enabled": checked })
                            defaultValue: false
                        }

                        NComboBox {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.target.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.target.desc")
                            model: rootSettings?.styleRulePrefixTargetModel ?? []
                            currentKey: modelData?.iconPrefix?.target ?? "icon"
                            defaultValue: "icon"
                            onSelected: key => rootSettings?.updateStyleRuleIconPrefix(index, {
                                "target": rootSettings?.normalizePrefixTarget(key) ?? "icon"
                            })
                        }

                        IconPickerField {
                            Layout.fillWidth: true
                            rootSettings: root.rootSettings
                            pluginApi: rootSettings?.pluginApi
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.icon.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.icon.desc")
                            currentIcon: String(modelData?.iconPrefix?.icon || "")
                            previewColor: root.previewIconColor(String(modelData?.iconPrefix?.color?.color ?? "on-surface-variant"))
                            iconPicker: prefixIconPicker
                            pickerIndex: index
                            pickText: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.icon.pick") ?? "Pick"
                            clearText: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.icon.clear") ?? "Clear"
                            onIconCleared: rootSettings?.updateStyleRuleIconPrefix(index, { "icon": "" })
                        }

                        SettingsColorField {
                            pluginApi: rootSettings?.pluginApi
                            rootSettings: root.rootSettings
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.color.label")
                            description: rootSettings?.pluginApi?.tr("settings.customStyleRules.iconPrefix.color.desc")
                            currentColor: modelData?.iconPrefix?.color?.color ?? "on-surface-variant"
                            defaultColor: "on-surface-variant"
                            currentOpacity: modelData?.iconPrefix?.color?.opacity ?? 1
                            defaultOpacity: 1
                            showOpacityControl: true
                            onColorSelected: value => rootSettings?.updateStyleRuleIconPrefixColor(index, "color", value)
                            onOpacitySelected: value => rootSettings?.updateStyleRuleIconPrefixColor(index, "opacity", value)
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
                rootSettings?.updateStyleRule(activeIndex, { "customIcon": iconName });
        }
    }

    NIconPicker {
        id: prefixIconPicker

        property int activeIndex: -1

        initialIcon: ""
        onIconSelected: iconName => {
            if (activeIndex >= 0)
                rootSettings?.updateStyleRuleIconPrefix(activeIndex, { "icon": iconName });
        }
    }
}
