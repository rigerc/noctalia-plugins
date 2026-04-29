pragma ComponentBehavior: Bound
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
    property int draggedProviderIndex: -1

    function providerDisplayName(providerId) {
        return tab.rootSettings?.providerOptionName(providerId) || String(providerId || "");
    }

    function providerIcon(providerId) {
        return tab.rootSettings?.effectiveProviderIcon(providerId) || "cpu";
    }

    function providerVisual(providerId) {
        return tab.rootSettings?.effectiveProviderVisual(providerId) || ({
            "source": "icon",
            "icon": tab.providerIcon(providerId),
            "asset": "",
            "assetUrl": ""
        });
    }

    function providerVisualSourceOptions(providerId) {
        if (!tab.rootSettings)
            return [];
        if (tab.rootSettings.providerSupportsBundledVisual(providerId))
            return tab.rootSettings.providerVisualSourceOptions || [];
        return tab.rootSettings.providerVisualSourceOptions && tab.rootSettings.providerVisualSourceOptions.length > 0 ? [tab.rootSettings.providerVisualSourceOptions[0]] : [];
    }

    function syncAvailableProviderChoices() {
        availableProviderChoices = tab.rootSettings ? (tab.rootSettings.getAvailableWidgetProviderOptions() || []) : [];
    }

    property string iconPickerProviderId: ""

    Connections {
        target: tab.rootSettings

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
            if (tab.draggedProviderIndex < 0 || !tab.rootSettings)
                return;
            if (tab.draggedProviderIndex === providerDropArea.index)
                return;
            tab.rootSettings.moveBarProvider(tab.draggedProviderIndex, providerDropArea.index);
            tab.draggedProviderIndex = providerDropArea.index;
        }

        NBox {
            id: dragCard

            width: parent.width
            implicitHeight: cardContent.implicitHeight + Style.marginM * 2

            readonly property int providerIndex: providerDropArea.index
            readonly property string providerId: String(providerDropArea.modelData || "")
            property bool dragging: dragMouseArea.drag.active
            property string localFieldToAdd: {
                var _ = tab.rootSettings?.editBarProviderFields;
                return tab.rootSettings?.firstAvailableBarProviderField(dragCard.providerId) ?? "primary";
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
                if (dragging)
                    tab.draggedProviderIndex = dragCard.providerIndex;
                if (!dragging) {
                    if (tab.draggedProviderIndex === dragCard.providerIndex)
                        tab.draggedProviderIndex = -1;
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
                        text: tab.providerDisplayName(dragCard.providerId)
                        pointSize: Style.fontSizeM
                        color: Color.mOnSurface
                    }

                    ProviderVisual {
                        visualData: tab.providerVisual(dragCard.providerId)
                        color: Color.mOnSurfaceVariant
                        pointSize: Style.fontSizeL
                        Layout.alignment: Qt.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NComboBox {
                            Layout.fillWidth: true
                            label: tab.rootSettings?.pluginApi?.tr("settings.general.providers.visual.source.label")
                            model: tab.providerVisualSourceOptions(dragCard.providerId)
                            currentKey: tab.rootSettings?.providerVisualSource(dragCard.providerId) ?? "icon"
                            onSelected: key => {
                                if (tab.rootSettings)
                                    tab.rootSettings.setProviderVisualSource(dragCard.providerId, key);
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.marginS

                            NButton {
                                visible: (tab.rootSettings?.providerVisualSource(dragCard.providerId) ?? "icon") === "icon"
                                text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.icon.browse")
                                icon: "pencil"
                                outlined: true
                                onClicked: {
                                    tab.iconPickerProviderId = dragCard.providerId;
                                    providerIconPicker.initialIcon = tab.providerIcon(dragCard.providerId);
                                    providerIconPicker.open();
                                }
                            }

                            NButton {
                                icon: "restore"
                                outlined: true
                                enabled: !!(tab.rootSettings?.editProviderVisuals || ({}))[dragCard.providerId] || !!(tab.rootSettings?.editBarProviderIcons || ({}))[dragCard.providerId]
                                tooltipText: tab.rootSettings?.pluginApi?.tr("settings.general.providers.icon.reset")
                                onClicked: {
                                    if (tab.rootSettings)
                                        tab.rootSettings.resetProviderVisual(dragCard.providerId);
                                }
                            }

                            NButton {
                                icon: "trash"
                                outlined: true
                                onClicked: {
                                    if (tab.rootSettings)
                                        tab.rootSettings.removeBarProvider(providerDropArea.index);
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
                        text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.fields.label")
                        pointSize: Style.fontSizeS
                        color: Color.mOnSurfaceVariant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        readonly property var availableOptions: {
                            var _ = tab.rootSettings?.editBarProviderFields;
                            return tab.rootSettings?.getAvailableBarProviderFieldOptions(dragCard.providerId) || [];
                        }

                        NComboBox {
                            id: fieldToAddCombo
                            Layout.fillWidth: true
                            label: tab.rootSettings?.pluginApi?.tr("settings.general.providers.fields.add")
                            model: parent.availableOptions
                            currentKey: dragCard.localFieldToAdd
                            enabled: parent.availableOptions.length > 0
                            onSelected: key => {
                                dragCard.localFieldToAdd = key;
                            }
                        }

                        NButton {
                            text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.fields.addButton")
                            icon: "plus"
                            enabled: parent.availableOptions.length > 0
                            onClicked: {
                                if (tab.rootSettings) {
                                    tab.rootSettings.addBarProviderField(providerDropArea.modelData, dragCard.localFieldToAdd);
                                    dragCard.localFieldToAdd = tab.rootSettings.firstAvailableBarProviderField(providerDropArea.modelData);
                                }
                            }
                        }
                    }

                    Repeater {
                        model: {
                            var _ = tab.rootSettings?.editBarProviderFields;
                            return tab.rootSettings?.getBarProviderFields(providerDropArea.modelData) || [];
                        }

                        delegate: NBox {
                            id: fieldItem
                            required property int index
                            required property var modelData

                            readonly property string providerId: dragCard.providerId
                            readonly property string fieldKey: String(modelData || "")
                            readonly property int fieldCount: tab.rootSettings?.getBarProviderFields(providerId)?.length ?? 0

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
                                        var options = tab.rootSettings?.barTextFieldOptions || [];
                                        for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
                                            if (options[optionIndex].key === fieldItem.fieldKey)
                                                return options[optionIndex].name;
                                        }
                                        return fieldItem.fieldKey;
                                    }
                                    pointSize: Style.fontSizeM
                                    color: Color.mOnSurface
                                }

                                NButton {
                                    icon: "arrow-up"
                                    outlined: true
                                    enabled: fieldItem.index > 0
                                    onClicked: {
                                        if (tab.rootSettings)
                                            tab.rootSettings.moveBarProviderField(fieldItem.providerId, fieldItem.index, -1);
                                    }
                                }

                                NButton {
                                    icon: "arrow-down"
                                    outlined: true
                                    enabled: fieldItem.index < fieldItem.fieldCount - 1
                                    onClicked: {
                                        if (tab.rootSettings)
                                            tab.rootSettings.moveBarProviderField(fieldItem.providerId, fieldItem.index, 1);
                                    }
                                }

                                NButton {
                                    icon: "trash"
                                    outlined: true
                                    enabled: fieldItem.fieldCount > 1
                                    onClicked: {
                                        if (tab.rootSettings)
                                            tab.rootSettings.removeBarProviderField(fieldItem.providerId, fieldItem.index);
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
        title: tab.rootSettings?.pluginApi?.tr("settings.general.appearance.title")
        description: tab.rootSettings?.pluginApi?.tr("settings.general.appearance.description")

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginL

            NIcon {
                Layout.preferredWidth: Style.fontSizeXL * 2
                Layout.preferredHeight: Style.fontSizeXL * 2
                Layout.alignment: Qt.AlignVCenter
                icon: tab.rootSettings?.editBarIcon ?? "sparkles"
                pointSize: Style.fontSizeXL * 1.6
                color: Color.resolveColorKey(tab.rootSettings?.editBarIconColor ?? "on-surface")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.marginM

                NButton {
                    text: tab.rootSettings?.pluginApi?.tr("settings.general.barIcon.browse")
                    onClicked: barIconPicker.open()
                }

                NText {
                    Layout.fillWidth: true
                    text: tab.rootSettings?.editBarIcon ?? "sparkles"
                    color: Color.mOnSurfaceVariant
                    elide: Text.ElideRight
                }
            }
        }

        NIconPicker {
            id: barIconPicker
            initialIcon: tab.rootSettings?.editBarIcon ?? "sparkles"
            onIconSelected: iconName => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarIcon = tab.rootSettings.normalizeIconName(iconName);
            }
        }

        NColorChoice {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.barIconColor.label")
            currentKey: tab.rootSettings?.editBarIconColor ?? "on-surface"
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarIconColor = key;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.appearance.providerIconColorize.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.appearance.providerIconColorize.desc")
            checked: tab.rootSettings?.editProviderIconColorize ?? true
            onToggled: checked => {
                if (tab.rootSettings)
                    tab.rootSettings.editProviderIconColorize = checked;
            }
        }

        NColorChoice {
            Layout.fillWidth: true
            visible: tab.rootSettings?.editProviderIconColorize ?? true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.appearance.providerIconColorizeColor.label")
            currentKey: tab.rootSettings?.editProviderIconColorizeColor ?? "on-surface"
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editProviderIconColorizeColor = key;
            }
        }
    }

    SettingsCard {
        title: tab.rootSettings?.pluginApi?.tr("settings.general.providers.title")
        description: tab.rootSettings?.pluginApi?.tr("settings.general.providers.description")

        NText {
            Layout.fillWidth: true
            visible: (tab.rootSettings?.widgetProviderOptions?.length ?? 0) === 0
            text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.noneAvailable")
            color: Color.mOnSurfaceVariant
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            visible: (tab.availableProviderChoices?.length ?? 0) > 0 && (tab.rootSettings?.editBarProviderIds?.length ?? 0) < 3
            spacing: Style.marginL

            NComboBox {
                id: providerToAddCombo
                Layout.fillWidth: true
                label: tab.rootSettings?.pluginApi?.tr("settings.general.providers.available")
                model: tab.availableProviderChoices || []
                currentKey: tab.rootSettings?.editWidgetProviderToAdd ?? ""
                onSelected: key => {
                    if (tab.rootSettings)
                        tab.rootSettings.editWidgetProviderToAdd = key;
                }
            }

            NButton {
                text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.add")
                icon: "plus"
                onClicked: {
                    var key = tab.rootSettings?.editWidgetProviderToAdd ?? "";
                    if (tab.rootSettings)
                        tab.rootSettings.addBarProvider(key);
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NText {
                text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.selected")
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
            }

            NText {
                Layout.fillWidth: true
                visible: (tab.rootSettings?.editBarProviderIds?.length ?? 0) === 0
                text: tab.rootSettings?.pluginApi?.tr("settings.general.providers.empty")
                color: Color.mOnSurfaceVariant
                wrapMode: Text.Wrap
            }

            Repeater {
                model: tab.rootSettings?.editBarProviderIds || []

                delegate: SelectedProviderDelegate {
                }
            }
        }

        NIconPicker {
            id: providerIconPicker
            initialIcon: tab.iconPickerProviderId !== "" ? tab.providerIcon(tab.iconPickerProviderId) : "cpu"
            onIconSelected: iconName => {
                if (tab.rootSettings && tab.iconPickerProviderId !== "")
                    tab.rootSettings.setBarProviderIcon(tab.iconPickerProviderId, iconName);
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.providers.labelMode.label")
            model: tab.rootSettings?.providerLabelModeOptions || []
            currentKey: tab.rootSettings?.editBarProviderLabelMode ?? "icon"
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarProviderLabelMode = key;
            }
        }

        NTextInput {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.providers.separator.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.providers.separator.desc")
            text: tab.rootSettings?.editBarProviderSeparator ?? "|"
            onTextChanged: {
                if (tab.rootSettings)
                    tab.rootSettings.editBarProviderSeparator = text;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.providers.separatorSpacing.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.providers.separatorSpacing.desc")
            from: 0
            to: 4
            stepSize: 1
            value: tab.rootSettings?.editBarProviderSeparatorSpacing ?? 1
            suffix: "sp"
            onValueChanged: {
                if (tab.rootSettings)
                    tab.rootSettings.editBarProviderSeparatorSpacing = value;
            }
        }
    }

    SettingsCard {
        title: tab.rootSettings?.pluginApi?.tr("settings.general.textStyle.title")
        description: tab.rootSettings?.pluginApi?.tr("settings.general.textStyle.description")

        NColorChoice {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.text.color.label")
            currentKey: tab.rootSettings?.editBarTextColor ?? "on-surface"
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarTextColor = key;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.text.opacity.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.text.opacity.desc")
            from: 0
            to: 100
            stepSize: 5
            value: tab.rootSettings?.editBarTextOpacityPercent ?? 100
            suffix: "%"
            onValueChanged: {
                if (tab.rootSettings)
                    tab.rootSettings.editBarTextOpacityPercent = value;
            }
        }

        NTextInput {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.textFields.separator.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.textFields.separator.desc")
            text: tab.rootSettings?.editBarTextSeparator ?? ""
            onTextChanged: {
                if (tab.rootSettings)
                    tab.rootSettings.editBarTextSeparator = text;
            }
        }

        NSpinBox {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.textFields.separatorSpacing.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.textFields.separatorSpacing.desc")
            from: 0
            to: 4
            stepSize: 1
            value: tab.rootSettings?.editBarTextSeparatorSpacing ?? 1
            suffix: "sp"
            onValueChanged: {
                if (tab.rootSettings)
                    tab.rootSettings.editBarTextSeparatorSpacing = value;
            }
        }
    }

    SettingsCard {
        title: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.title")
        description: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.description")

        NToggle {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.showOnHover.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.showOnHover.desc")
            checked: tab.rootSettings?.editBarTextShowOnHover ?? false
            onToggled: checked => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarTextShowOnHover = checked;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.expandOnChange.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.expandOnChange.desc")
            checked: tab.rootSettings?.editBarTextExpandOnChange ?? false
            enabled: tab.rootSettings?.editBarTextShowOnHover ?? false
            onToggled: checked => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarTextExpandOnChange = checked;
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.countdownOnEmpty.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.countdownOnEmpty.desc")
            checked: tab.rootSettings?.editBarCountdownOnEmpty ?? false
            onToggled: checked => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarCountdownOnEmpty = checked;
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM
            visible: tab.rootSettings?.editBarCountdownOnEmpty ?? false

            NText {
                text: tab.rootSettings?.pluginApi?.tr("settings.general.behavior.countdownWindows.label")
                pointSize: Style.fontSizeS
                color: Color.mOnSurface
            }

            Repeater {
                model: tab.rootSettings?.editBarCountdownWindows || []

                delegate: NBox {
                    id: countdownItem
                    required property int index
                    required property var modelData
                    readonly property string windowKey: String(modelData || "")

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
                                var options = tab.rootSettings?.countdownWindowOptions || [];
                                for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
                                    if (options[optionIndex].key === countdownItem.windowKey)
                                        return options[optionIndex].name;
                                }
                                return countdownItem.windowKey;
                            }
                            pointSize: Style.fontSizeM
                            color: Color.mOnSurface
                        }

                        NButton {
                            icon: "trash"
                            outlined: true
                            enabled: (tab.rootSettings?.editBarCountdownWindows?.length ?? 0) > 1
                            onClicked: {
                                if (tab.rootSettings)
                                    tab.rootSettings.removeCountdownWindow(countdownItem.index);
                            }
                        }
                    }
                }
            }

            NButton {
                visible: (tab.rootSettings?.editBarCountdownWindows?.length ?? 0) < 3
                text: tab.rootSettings?.pluginApi?.tr("settings.general.textFields.addButton")
                icon: "plus"
                outlined: true
                onClicked: {
                    if (tab.rootSettings)
                        tab.rootSettings.addCountdownWindow(tab.rootSettings.editCountdownWindowToAdd);
                }
            }
        }

        NToggle {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.enabled.label")
            description: tab.rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.enabled.desc")
            checked: tab.rootSettings?.editBarLowUsageAlertEnabled ?? false
            onToggled: checked => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarLowUsageAlertEnabled = checked;
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.window.label")
            model: tab.rootSettings?.lowUsageAlertWindowOptions || []
            currentKey: tab.rootSettings?.editBarLowUsageAlertWindow ?? "primary"
            enabled: tab.rootSettings?.editBarLowUsageAlertEnabled ?? false
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarLowUsageAlertWindow = (key === "secondary" || key === "tertiary") ? key : "primary";
            }
        }

        NColorChoice {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.lowUsageAlert.color.label")
            currentKey: tab.rootSettings?.editBarLowUsageAlertColor ?? "error"
            enabled: tab.rootSettings?.editBarLowUsageAlertEnabled ?? false
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editBarLowUsageAlertColor = key;
            }
        }

        NComboBox {
            Layout.fillWidth: true
            label: tab.rootSettings?.pluginApi?.tr("settings.general.refreshInterval.label")
            model: tab.rootSettings?.refreshIntervalOptions || []
            currentKey: String(tab.rootSettings?.editRefreshInterval ?? 120)
            onSelected: key => {
                if (tab.rootSettings)
                    tab.rootSettings.editRefreshInterval = Number(key);
            }
        }

    }
}
