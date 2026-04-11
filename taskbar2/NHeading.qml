import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property string label: ""
    property string description: ""

    Layout.fillWidth: true
    spacing: Style.marginXL

    NText {
        Layout.fillWidth: true
        text: root.label
        pointSize: Style.fontSizeXXL
        wrapMode: Text.Wrap
        font.weight: Style.fontWeightSemiBold
    }

    NText {
        visible: root.description.length > 0
        Layout.fillWidth: true
        text: root.description
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
    }
}
