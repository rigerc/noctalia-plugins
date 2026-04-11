import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property string label: ""
    property string description: ""

    Layout.fillWidth: true
    spacing: Style.marginL

    NText {
        Layout.fillWidth: true
        text: root.label
        pointSize: Style.fontSizeXL
        wrapMode: Text.Wrap
        font.weight: Style.fontWeightSemiBold
    }

    NText {
        visible: root.description.length > 0
        Layout.fillWidth: true
        text: root.description
        pointSize: Style.fontSizeXS
        color: Color.mOnSurfaceVariant
        wrapMode: Text.Wrap
    }
}
