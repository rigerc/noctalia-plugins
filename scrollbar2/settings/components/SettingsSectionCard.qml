import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

NBox {
    id: root

    property string title: ""
    property string description: ""
    property alias sectionTarget: contentColumn
    property real contentSpacing: Style.marginXL
    property real contentMargins: Style.marginXL
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    Layout.preferredHeight: contentColumn.implicitHeight + contentMargins * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: root.contentMargins
        spacing: root.contentSpacing

        NHeader {
            Layout.fillWidth: true
            label: root.title
            description: root.description
            visible: root.title !== "" || root.description !== ""
        }
    }
}
