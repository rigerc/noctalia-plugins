import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

RowLayout {
    id: root

    property var rootSettings: null
    property var pluginApi: null
    property string label: ""
    property string description: ""
    property string currentIcon: ""
    property color previewColor: Color.mOnSurfaceVariant
    property var iconPicker: null
    property int pickerIndex: -1
    property string pickText: "Pick"
    property string clearText: "Clear"

    signal iconPicked(string iconName)
    signal iconCleared()

    Layout.fillWidth: true
    spacing: Style.marginM

    NLabel {
        Layout.fillWidth: true
        label: root.label
        description: root.description
    }

    NIcon {
        icon: root.currentIcon
        pointSize: Style.fontSizeXL
        visible: root.currentIcon !== ""
        color: root.previewColor
    }

    NButton {
        text: root.pickText
        onClicked: {
            if (root.iconPicker) {
                root.iconPicker.activeIndex = root.pickerIndex;
                root.iconPicker.initialIcon = root.currentIcon;
                root.iconPicker.open();
            }
        }
    }

    NButton {
        text: root.clearText
        enabled: root.currentIcon !== ""
        onClicked: root.iconCleared()
    }
}
