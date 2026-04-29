import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "../components"

SettingsTabPage {
    id: tab

    property var rootSettings: null
    property var availableProviderChoices: []
    readonly property var mainInstance: rootSettings?.pluginApi?.mainInstance

    function providerDisplayName(providerId) {
        return rootSettings?.providerOptionName(providerId) || String(providerId || "");
    }

    function providerIcon(providerId) {
        return rootSettings?.effectiveProviderIcon(providerId) || "cpu";
    }

    function providerVisual(providerId) {
        return rootSettings?.effectiveProviderVisual(providerId) || ({
            "source": "icon",
            "icon": tab.providerIcon(providerId),
            "asset": "",
            "assetUrl": ""
        });
    }

    function providerVisualSourceOptions(providerId) {
        if (!rootSettings)
            return [];
        if (rootSettings.providerSupportsBundledVisual(providerId))
            return rootSettings.providerVisualSourceOptions || [];
        return rootSettings.providerVisualSourceOptions && rootSettings.providerVisualSourceOptions.length > 0 ? [rootSettings.providerVisualSourceOptions[0]] : [];
    }

    function syncAvailableProviderChoices() {
        availableProviderChoices = rootSettings ? (rootSettings.getAvailableWidgetProviderOptions() || []) : [];
    }

    property string iconPickerProviderId: ""

    Connections {
        target: rootSettings

        function onEditBarProviderIdsChanged() {
            tab.syncAvailableProviderChoices();
        }

        function onWidgetProviderOptionsChanged() {
            tab.syncAvailableProviderChoices();
        }
    }

    onRootSettingsChanged: syncAvailableProviderChoices()
    Component.onCompleted: syncAvailableProviderChoices()

    component SettingsCard: NBox {
        id: card

        property string title: ""
        property string description: ""
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NLabel {
                visible: card.title !== "" || card.description !== ""
                Layout.fillWidth: true
                label: card.title
                description: card.description
                labelSize: Style.fontSizeL
            }
        }
    }

    component SelectedProviderDelegate: DropArea {
        id: providerDropArea

        required property int index
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: dragCard.implicitHeight

        onEntered: drag => {
            if (!drag.source || !rootSettings)
                return;
            if (drag.source.providerIndex === index)
                return;
            rootSettings.moveBarProvider(drag.source.providerIndex, index);
            drag.source.providerIndex = index;
        }

        NBox {
            id: dragCard

            width: parent.width
            implicitHeight: cardContent.implicitHeight + Style.marginM * 2

            property int providerIndex: index
            property bool dragging: dragMouseArea.drag.active
            property string localFieldToAdd: {
                var _ = rootSettings?.editBarProviderFields;
                return rootSettings?.firstAvailableBarProviderField(modelData) ?? "primary";
            }

            Drag.active: dragging
            Drag.source: dragCard
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.keys: ["codexbar-provider"]
            z: dragging ? 1000 : 0
            scale: dragging ? 1.02 : 1.0
            opacity: dragging ? 0.9 : 1.0

            onDraggingChanged: {
                if (!dragging) {
                    x = 0;
                    y = 0;
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Style.animationFast
                }
            }

            ColumnLayout {
                id: cardContent
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                RowLayout {
                    id: providerRow
                    Layout.fillWidth: true
                    spacing: Style.marginM

                    Item {
                        Layout.preferredWidth: Style.fontSizeL + Style.marginS * 2
                        Layout.preferredHeight: Style.fontSizeL + Style.marginS * 2

                        NIcon {
                            anchors.centerIn: parent
                            icon: "grip-vertical"
                            color: Color.mOnSurfaceVariant
                        }

                        MouseArea {
                            id: dragMouseArea
                            anchors.fill: parent
                            cursorShape: Qt.OpenHandCursor
                            drag.target: dragCard
                        }
                    }

                    NText {
                        text: tab.providerDisplayName(modelData)
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurface
                    }

                    ProviderVisual {
                        visualData: tab.providerVisual(modelData)
                        color: Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeL
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NComboBox {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.general.providers.visual.source.label")
                            model: tab.providerVisualSourceOptions(modelData)
                            currentKey: rootSettings?.providerVisualSource(modelData) ?? "icon"
                            onSelected: key => {
                                if (rootSettings)
                                    rootSettings.setProviderVisualSource(modelData, key);
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NButton {
                                visible: (rootSettings?.providerVisualSource(modelData) ?? "icon") === "icon"
                                text: rootSettings?.pluginApi?.tr("settings.general.providers.icon.browse")
                                icon: "pencil"
                                outlined: true
                                onClicked: {
                                    tab.iconPickerProviderId = String(modelData || "");
                                    providerIconPicker.initialIcon = tab.providerIcon(modelData);
                                    providerIconPicker.open();
                                }
                            }

                            NButton {
                                icon: "restore"
                                outlined: true
                                enabled: !!(rootSettings?.editProviderVisuals || ({}))[String(modelData || "")] || !!(rootSettings?.editBarProviderIcons || ({}))[String(modelData || "")]
                                tooltipText: rootSettings?.pluginApi?.tr("settings.general.providers.icon.reset")
                                onClicked: {
                                    if (rootSettings)
                                        rootSettings.resetProviderVisual(modelData);
                                }
                            }

                            NButton {
                                icon: "trash"
                                outlined: true
                                onClicked: {
                                    if (rootSettings)
                                        rootSettings.removeBarProvider(index);
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.fontSizeL + Style.marginS * 2 + Style.marginM
                    spacing: Style.marginS

                    NText {
                        text: rootSettings?.pluginApi?.tr("settings.general.providers.fields.label")
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        readonly property var availableOptions: {
                            var _ = rootSettings?.editBarProviderFields;
                            return rootSettings?.getAvailableBarProviderFieldOptions(modelData) || [];
                        }

                        NComboBox {
                            id: fieldToAddCombo
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.general.providers.fields.add")
                            model: parent.availableOptions
                            currentKey: dragCard.localFieldToAdd
                            enabled: parent.availableOptions.length > 0
                            onSelected: key => {
                                dragCard.localFieldToAdd = key;
                            }
                        }

                        NButton {
                            text: rootSettings?.pluginApi?.tr("settings.general.providers.fields.addButton")
                            icon: "plus"
                            enabled: parent.availableOptions.length > 0
                            onClicked: {
                                if (rootSettings) {
                                    rootSettings.addBarProviderField(modelData, dragCard.localFieldToAdd);
                                    dragCard.localFieldToAdd = rootSettings.firstAvailableBarProviderField(modelData);
                                }
                            }
                        }
                    }

                    Repeater {
                        model: {
                            var _ = rootSettings?.editBarProviderFields;
                            return rootSettings?.getBarProviderFields(modelData) || [];
                        }

                        delegate: NBox {
                            required property int index
                            required property var modelData

                            readonly property var outerModelData: providerDropArea.modelData

                            Layout.fillWidth: true
                            implicitHeight: fieldRow.implicitHeight + Style.marginS * 2

                            RowLayout {
                                id: fieldRow
                                anchors.fill: parent
                                anchors.margins: Style.marginS
                                spacing: Style.marginS

                                NText {
                                    Layout.fillWidth: true
                                    text: {
                                        var options = rootSettings?.barTextFieldOptions || [];
                                        for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
                                            if (options[optionIndex].key === modelData)
                                                return options[optionIndex].name;
                                        }
                                        return String(modelData || "");
                                    }
                                    pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }

                                NButton {
                                    icon: "arrow-up"
                                    outlined: true
                                    enabled: index > 0
                                    onClicked: {
                                        if (rootSettings)
                                            rootSettings.moveBarProviderField(outerModelData, index, -1);
                                    }
                                }

                                NButton {
                                    icon: "arrow-down"
                                    outlined: true
                                    enabled: {
                                        var _ = rootSettings?.editBarProviderFields;
                                        return index < (rootSettings?.getBarProviderFields(outerModelData)?.length ?? 0) - 1;
                                    }
                                    onClicked: {
                                        if (rootSettings)
                                            rootSettings.moveBarProviderField(outerModelData, index, 1);
                                    }
                                }

                                NButton {
                                    icon: "trash"
                                    outlined: true
                                    enabled: {
                                        var _ = rootSettings?.editBarProviderFields;
                                        return (rootSettings?.getBarProviderFields(outerModelData)?.length ?? 0) > 1;
                                    }
                                    onClicked: {
                                        if (rootSettings)
                                            rootSettings.removeBarProviderField(outerModelData, index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    title: rootSettings?.pluginApi?.tr("settings.tabs.general")
    description: rootSettings?.pluginApi?.tr("settings.general.description")
    icon: "sparkles"

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.appearance.title")
        description: rootSettings?.pluginApi?.tr("settings.general.appearance.description")

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginL

            NIcon {
                Layout.preferredWidth: Style.fontSizeXL * 2
                Layout.preferredHeight: Style.fontSizeXL * 2
                Layout.alignment: Qt.AlignVCenter
                icon: rootSettings?.editBarIcon ?? "sparkles"
                pointSize: Style.fontSizeXL * 1.6
                color: Color.resolveColorKey(rootSettings?.editBarIconColor ?? "on-surface")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: rootSettings?.pluginApi?.tr("settings.general.barIcon.browse")
                    onClicked: barIconPicker.open()
                }

                NText {
                    Layout.fillWidth: true
                    text: rootSettings?.editBarIcon ?? "sparkles"
                    color: Color.mOnSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        NIconPicker {
            id: barIconPicker
            initialIcon: rootSettings?.editBarIcon ?? "sparkles"
            onIconSelected: iconName => {
                if (rootSettings)
                    rootSettings.editBarIcon = rootSettings.normalizeIconName(iconName);
            }
        }

        NColorChoice {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.barIconColor.label")
            currentKey: rootSettings?.editBarIconColor ?? "on-surface"
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editBarIconColor = key;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.appearance.providerIconColorize.label")
            description: rootSettings?.pluginApi?.tr("settings.general.appearance.providerIconColorize.desc")
            checked: rootSettings?.editProviderIconColorize ?? true
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editProviderIconColorize = checked;
            }
        }

        NColorChoice {
            Layout.fillWidth: true
            visible: rootSettings?.editProviderIconColorize ?? true
            label: rootSettings?.pluginApi?.tr("settings.general.appearance.providerIconColorizeColor.label")
            currentKey: rootSettings?.editProviderIconColorizeColor ?? "on-surface"
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editProviderIconColorizeColor = key;
            }
        }
    }

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.providers.title")
        description: rootSettings?.pluginApi?.tr("settings.general.providers.description")

        NText {
            Layout.fillWidth: true
            visible: (rootSettings?.widgetProviderOptions?.length ?? 0) === 0
            text: rootSettings?.pluginApi?.tr("settings.general.providers.noneAvailable")
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            visible: (tab.availableProviderChoices?.length ?? 0) > 0 && (rootSettings?.editBarProviderIds?.length ?? 0) < 3
            spacing: Style.marginL

            NComboBox {
                id: providerToAddCombo
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.general.providers.available")
                model: tab.availableProviderChoices || []
                currentKey: rootSettings?.editWidgetProviderToAdd ?? ""
                onSelected: key => {
                    if (rootSettings)
                        rootSettings.editWidgetProviderToAdd = key;
                }
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.general.providers.add")
                icon: "plus"
                onClicked: {
                    var key = rootSettings?.editWidgetProviderToAdd ?? "";
                    if (rootSettings)
                        rootSettings.addBarProvider(key);
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
                text: rootSettings?.pluginApi?.tr("settings.general.providers.selected")
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
            }

            NText {
                Layout.fillWidth: true
                visible: (rootSettings?.editBarProviderIds?.length ?? 0) === 0
                text: rootSettings?.pluginApi?.tr("settings.general.providers.empty")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
            }

            Repeater {
                model: rootSettings?.editBarProviderIds || []

                delegate: SelectedProviderDelegate {
                }
            }
        }

        NIconPicker {
            id: providerIconPicker
            initialIcon: tab.iconPickerProviderId !== "" ? tab.providerIcon(tab.iconPickerProviderId) : "cpu"
            onIconSelected: iconName => {
                if (rootSettings && tab.iconPickerProviderId !== "")
                    rootSettings.setBarProviderIcon(tab.iconPickerProviderId, iconName);
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.providers.labelMode.label")
            model: rootSettings?.providerLabelModeOptions || []
            currentKey: rootSettings?.editBarProviderLabelMode ?? "icon"
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editBarProviderLabelMode = key;
            }
        }

        NTextInput {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.providers.separator.label")
            description: rootSettings?.pluginApi?.tr("settings.general.providers.separator.desc")
            text: rootSettings?.editBarProviderSeparator ?? "|"
            onTextChanged: {
                if (rootSettings)
                    rootSettings.editBarProviderSeparator = text;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.providers.separatorSpacing.label")
            description: rootSettings?.pluginApi?.tr("settings.general.providers.separatorSpacing.desc")
            from: 0
            to: 4
            stepSize: 1
            value: rootSettings?.editBarProviderSeparatorSpacing ?? 1
            suffix: "sp"
            onValueChanged: {
                if (rootSettings)
                    rootSettings.editBarProviderSeparatorSpacing = value;
            }
        }
    }

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.textStyle.title")
        description: rootSettings?.pluginApi?.tr("settings.general.textStyle.description")

        NColorChoice {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.text.color.label")
            currentKey: rootSettings?.editBarTextColor ?? "on-surface"
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editBarTextColor = key;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.text.opacity.label")
            description: rootSettings?.pluginApi?.tr("settings.general.text.opacity.desc")
            from: 0
            to: 100
            stepSize: 5
            value: rootSettings?.editBarTextOpacityPercent ?? 100
            suffix: "%"
            onValueChanged: {
                if (rootSettings)
                    rootSettings.editBarTextOpacityPercent = value;
            }
        }

        NTextInput {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.textFields.separator.label")
            description: rootSettings?.pluginApi?.tr("settings.general.textFields.separator.desc")
            text: rootSettings?.editBarTextSeparator ?? ""
            onTextChanged: {
                if (rootSettings)
                    rootSettings.editBarTextSeparator = text;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.textFields.separatorSpacing.label")
            description: rootSettings?.pluginApi?.tr("settings.general.textFields.separatorSpacing.desc")
            from: 0
            to: 4
            stepSize: 1
            value: rootSettings?.editBarTextSeparatorSpacing ?? 1
            suffix: "sp"
            onValueChanged: {
                if (rootSettings)
                    rootSettings.editBarTextSeparatorSpacing = value;
            }
        }
    }

    SettingsCard {
        title: rootSettings?.pluginApi?.tr("settings.general.behavior.title")
        description: rootSettings?.pluginApi?.tr("settings.general.behavior.description")

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.behavior.showOnHover.label")
            description: rootSettings?.pluginApi?.tr("settings.general.behavior.showOnHover.desc")
            checked: rootSettings?.editBarTextShowOnHover ?? false
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editBarTextShowOnHover = checked;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.behavior.expandOnChange.label")
            description: rootSettings?.pluginApi?.tr("settings.general.behavior.expandOnChange.desc")
            checked: rootSettings?.editBarTextExpandOnChange ?? false
            enabled: rootSettings?.editBarTextShowOnHover ?? false
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editBarTextExpandOnChange = checked;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.behavior.countdownOnEmpty.label")
            description: rootSettings?.pluginApi?.tr("settings.general.behavior.countdownOnEmpty.desc")
            checked: rootSettings?.editBarCountdownOnEmpty ?? false
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editBarCountdownOnEmpty = checked;
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM
            visible: rootSettings?.editBarCountdownOnEmpty ?? false

            NText {
                text: rootSettings?.pluginApi?.tr("settings.general.behavior.countdownWindows.label")
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
            }

            Repeater {
                model: rootSettings?.editBarCountdownWindows || []

                delegate: NBox {
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: countdownWinRow.implicitHeight + Style.marginM * 2

                    RowLayout {
                        id: countdownWinRow
                        anchors.fill: parent
                        anchors.margins: Style.marginM
                        spacing: Style.marginM

                        NText {
                            Layout.fillWidth: true
                            text: {
                                var options = rootSettings?.countdownWindowOptions || [];
                                for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
                                    if (options[optionIndex].key === modelData)
                                        return options[optionIndex].name;
                                }
                                return String(modelData || "");
                            }
                            pointSize: Style.fontSizeM
                            color: Color.mOnSurface
                        }

                        NButton {
                            icon: "trash"
                            outlined: true
                            enabled: (rootSettings?.editBarCountdownWindows?.length ?? 0) > 1
                            onClicked: {
                                if (rootSettings)
                                    rootSettings.removeCountdownWindow(index);
                            }
                        }
                    }
                }
            }

            NButton {
                visible: (rootSettings?.editBarCountdownWindows?.length ?? 0) < 3
                text: rootSettings?.pluginApi?.tr("settings.general.textFields.addButton")
                icon: "plus"
                outlined: true
                onClicked: {
                    if (rootSettings)
                        rootSettings.addCountdownWindow(rootSettings.editCountdownWindowToAdd);
                }
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.enabled.label")
            description: rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.enabled.desc")
            checked: rootSettings?.editBarLowUsageAlertEnabled ?? false
            onToggled: checked => {
                if (rootSettings)
                    rootSettings.editBarLowUsageAlertEnabled = checked;
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.window.label")
            model: rootSettings?.lowUsageAlertWindowOptions || []
            currentKey: rootSettings?.editBarLowUsageAlertWindow ?? "primary"
            enabled: rootSettings?.editBarLowUsageAlertEnabled ?? false
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editBarLowUsageAlertWindow = (key === "secondary" || key === "tertiary") ? key : "primary";
            }
        }

        NColorChoice {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.color.label")
            currentKey: rootSettings?.editBarLowUsageAlertColor ?? "error"
            enabled: rootSettings?.editBarLowUsageAlertEnabled ?? false
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editBarLowUsageAlertColor = key;
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.general.refreshInterval.label")
            model: rootSettings?.refreshIntervalOptions || []
            currentKey: String(rootSettings?.editRefreshInterval ?? 120)
            onSelected: key => {
                if (rootSettings)
                    rootSettings.editRefreshInterval = Number(key);
            }
        }

    }
}
