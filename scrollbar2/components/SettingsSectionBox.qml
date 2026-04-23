import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property string title: ""
    property string description: ""
    property alias sectionTarget: sectionContent
    default property alias content: sectionContent.data

    Layout.fillWidth: true
    Layout.preferredHeight: sectionContent.implicitHeight + Style.marginL * 2

    NBox {
        anchors.fill: parent

        ColumnLayout {
            id: sectionContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM

            NHeader {
                Layout.fillWidth: true
                label: root.title
                description: root.description
            }
        }
    }
}
