import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services.UI
import qs.Widgets

NBox {
    id: root

    property string title: ""
    property string description: ""
    property string sectionKey: ""
    property alias sectionTarget: contentColumn
    property real contentSpacing: Style.marginXL
    property real contentMargins: Style.marginXL
    property bool collapsible: true
    property bool collapsed: false
    property bool showLock: sectionKey !== ""
    property string lockTooltip: isLocked ? "Locked — protected from presets" : "Unlocked — presets can overwrite"
    property var rootSettings: null
    readonly property bool isLocked: showLock && rootSettings ? rootSettings.isSectionLocked(sectionKey) : false
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    Layout.preferredHeight: headerRow.height + contentWrapper.Layout.preferredHeight + root.contentMargins * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
        id: outerColumn
        anchors.fill: parent
        anchors.margins: root.contentMargins
        spacing: 0

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: Style.marginS

            NHeader {
                Layout.fillWidth: true
                label: root.title
                description: root.description
                visible: root.title !== "" || root.description !== ""
            }

            NIcon {
                visible: root.showLock
                icon: root.isLocked ? "lock" : "lock-open"
                pointSize: Style.fontSizeM
                color: root.isLocked ? Color.mPrimary : Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (root.rootSettings && root.sectionKey !== "")
                            root.rootSettings.toggleSectionLock(root.sectionKey);
                    }
                    onEntered: TooltipService.show(parent, root.lockTooltip, "top")
                    onExited: TooltipService.hide()
                }
            }

            NIcon {
                id: chevronIcon
                visible: root.collapsible
                icon: "chevron-down"
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                Layout.alignment: Qt.AlignVCenter
                rotation: root.collapsed ? 0 : 180

                Behavior on rotation {
                    enabled: root.collapsible
                    NumberAnimation {
                        duration: Style.animationFast
                        easing.type: Easing.OutCubic
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.collapsed = !root.collapsed
                }
            }

            MouseArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                enabled: root.collapsible
                onClicked: root.collapsed = !root.collapsed
                cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
            }
        }

        Item {
            id: contentWrapper
            Layout.fillWidth: true
            Layout.preferredHeight: root.collapsed ? 0 : contentColumn.implicitHeight + root.contentSpacing
            clip: true

            Behavior on Layout.preferredHeight {
                enabled: root.collapsible
                NumberAnimation {
                    duration: Style.animationFast
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: root.contentSpacing
            }
        }
    }
}

