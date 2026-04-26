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
    property var rootSettings: null
    readonly property bool isLocked: showLock && rootSettings ? rootSettings.isSectionLocked(sectionKey) : false
    readonly property string lockTooltip: isLocked
        ? (rootSettings?.pluginApi?.tr("settings.sectionCard.lockedTooltip") ?? "")
        : (rootSettings?.pluginApi?.tr("settings.sectionCard.unlockedTooltip") ?? "")
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    Layout.preferredHeight: headerRow.height + contentWrapper.Layout.preferredHeight + root.contentMargins * 2
    color: Color.mSurfaceVariant

    ColumnLayout {
        id: outerColumn
        anchors.fill: parent
        anchors.margins: root.contentMargins
        spacing: 0

        Item {
            id: headerRow
            Layout.fillWidth: true
            implicitHeight: Math.max(headerHitArea.implicitHeight, lockIcon.implicitHeight, chevronIcon.implicitHeight)

            Item {
                id: headerHitArea
                anchors.left: parent.left
                anchors.right: root.showLock ? lockIcon.left : chevronIcon.left
                anchors.rightMargin: Style.marginS
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: sectionHeader.implicitHeight
                visible: root.title !== "" || root.description !== ""

                NHeader {
                    id: sectionHeader
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    label: root.title
                    description: root.description
                }

                TapHandler {
                    enabled: root.collapsible
                    cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onTapped: root.collapsed = !root.collapsed
                }
            }

            NIcon {
                id: lockIcon
                visible: root.showLock
                anchors.right: chevronIcon.left
                anchors.rightMargin: Style.marginS
                anchors.verticalCenter: parent.verticalCenter
                icon: root.isLocked ? "lock" : "lock-open"
                pointSize: Style.fontSizeM
                color: root.isLocked ? Color.mPrimary : Color.mOnSurfaceVariant

                TapHandler {
                    cursorShape: Qt.PointingHandCursor
                    onTapped: {
                        if (root.rootSettings && root.sectionKey !== "")
                            root.rootSettings.toggleSectionLock(root.sectionKey);
                    }
                }

                HoverHandler {
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hovered)
                            TooltipService.show(parent, root.lockTooltip, "top");
                        else
                            TooltipService.hide();
                    }
                }
            }

            NIcon {
                id: chevronIcon
                visible: root.collapsible
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: "chevron-down"
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                rotation: root.collapsed ? 0 : 180

                Behavior on rotation {
                    enabled: root.collapsible
                    NumberAnimation {
                        duration: Style.animationFast
                        easing.type: Easing.OutCubic
                    }
                }

                TapHandler {
                    cursorShape: Qt.PointingHandCursor
                    onTapped: root.collapsed = !root.collapsed
                }
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
