import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property bool condition: true
    property string disabledHint: ""
    property alias sectionTarget: sectionContent
    default property alias content: sectionContent.data

    readonly property bool isDisabled: !condition

    opacity: condition ? 1.0 : 0.4
    Layout.fillWidth: true
    Layout.preferredHeight: sectionContent.implicitHeight + Style.marginL * 2

    NBox {
        anchors.fill: parent
        enabled: condition

        ColumnLayout {
            id: sectionContent
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM
        }
    }

    NText {
        visible: root.isDisabled && root.disabledHint !== ""
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: Style.marginS
        text: root.disabledHint
        color: Color.mOnSurfaceVariant
        font.italic: true
        pointSize: Style.fontSizeS
    }
}
