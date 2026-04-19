import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property string title: ""
    property string description: ""
    property string icon: ""
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    spacing: Style.marginXL

    NLabel {
        Layout.fillWidth: true
        label: root.title
        description: root.description
        icon: root.icon
        labelSize: Style.fontSizeXL
        iconColor: Color.mPrimary
    }

    NDivider {
        Layout.fillWidth: true
    }

    ColumnLayout {
        id: contentColumn

        Layout.fillWidth: true
        spacing: Style.marginXL
    }

}
