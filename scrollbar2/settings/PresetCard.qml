import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null
    property string presetId: ""
    property string presetName: ""
    property string presetDescription: ""
    property bool isBuiltIn: false
    property bool isActive: false

    signal clicked()
    signal renameRequested()
    signal updateRequested()
    signal duplicateRequested()
    signal deleteRequested()

    property bool _isHovered: false

    implicitWidth: 155 * Style.uiScaleRatio
    implicitHeight: 76 * Style.uiScaleRatio

    NBox {
        id: cardBox
        anchors.fill: parent
        border.color: root.isActive ? Color.mPrimary : Style.boxBorderColor
        border.width: root.isActive ? 2 * Style.uiScaleRatio : Style.borderS
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.marginM
        anchors.rightMargin: root.isBuiltIn ? Style.marginM : (Style.marginM + moreBtn.buttonSize + Style.marginXS)
        spacing: Style.marginXXS

        NText {
            text: root.presetName
            pointSize: Style.fontSizeM
            font.weight: Style.fontWeightMedium
            color: root.isActive ? Color.mPrimary : Color.mOnSurface
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        NText {
            text: root.isBuiltIn
                ? (root.pluginApi?.tr("settings.presets.badge") ?? "")
                : (root.presetDescription || "")
            pointSize: Style.fontSizeS
            color: root.isBuiltIn ? Color.mPrimary : Color.mOnSurfaceVariant
            elide: Text.ElideRight
            Layout.fillWidth: true
            visible: text !== "" && text !== null
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onEntered: root._isHovered = true
        onExited: root._isHovered = false
    }

    NIconButton {
        id: moreBtn
        visible: !root.isBuiltIn
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.marginXS
        baseSize: Style.baseWidgetSize * 0.55
        icon: "dots-vertical"
        colorBg: "transparent"
        colorBgHover: Color.mHover
        colorFg: root._isHovered ? Color.mOnSurface : Color.mOnSurfaceVariant
        colorFgHover: Color.mOnSurface
        colorBorder: "transparent"
        colorBorderHover: "transparent"
        customRadius: Style.iRadiusS

        onClicked: ctxMenu.openAtItem(moreBtn, 0, moreBtn.height)
    }

    NContextMenu {
        id: ctxMenu
        parent: Overlay.overlay
        model: [
            {
                "label": root.pluginApi?.tr("settings.presets.actions.rename") ?? "",
                "action": "rename",
                "icon": "pencil"
            },
            {
                "label": root.pluginApi?.tr("settings.presets.actions.update") ?? "",
                "action": "update",
                "icon": "refresh"
            },
            {
                "label": root.pluginApi?.tr("settings.presets.actions.duplicate") ?? "",
                "action": "duplicate",
                "icon": "copy"
            },
            {
                "label": root.pluginApi?.tr("settings.presets.actions.delete") ?? "",
                "action": "delete",
                "icon": "trash"
            }
        ]
        onTriggered: action => {
            switch (action) {
            case "rename":     root.renameRequested(); break;
            case "update":     root.updateRequested(); break;
            case "duplicate":  root.duplicateRequested(); break;
            case "delete":     root.deleteRequested(); break;
            }
        }
    }
}
