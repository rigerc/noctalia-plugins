import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    required property var entryRoot
    required property var entryState

    anchors.fill: parent
    visible: entryState.showSeparatorVisual || entryRoot.dragSourceIndex !== -1

    Item {
        anchors.centerIn: parent
        width: entryRoot.isVerticalBar ? entryRoot.barHeight : entryState.separatorVisualWidth
        height: entryRoot.isVerticalBar ? entryState.separatorVisualHeight : entryRoot.barHeight
        opacity: entryState.showSeparatorVisual ? 1 : (entryRoot.dragTargetIndex === entryState.modelIndex ? 0.9 : 0.22)

        RowLayout {
            visible: !entryRoot.isVerticalBar
            anchors.centerIn: parent
            spacing: Style.marginS

            NText {
                visible: entryState.showSeparatorVisual && entryRoot.workspaceSeparatorShowLabel && entryState.separatorLabel.length > 0
                text: entryState.separatorLabel
                pointSize: Math.max(Style.fontSizeXS, entryRoot.barFontSize * 0.9)
                color: Color.mOnSurfaceVariant
                font.weight: Style.fontWeightSemiBold
            }

            Loader {
                visible: entryState.showSeparatorVisual && entryRoot.workspaceSeparatorShowDivider
                Layout.preferredWidth: entryState.separatorLineLength
                Layout.preferredHeight: Math.max(1, Style.borderS)
                sourceComponent: entryRoot.workspaceSeparatorDividerMode === "line" ? lineDividerComponent : (entryRoot.workspaceSeparatorDividerMode === "character" ? charDividerComponent : iconDividerComponent)
            }
        }

        ColumnLayout {
            visible: entryRoot.isVerticalBar
            anchors.centerIn: parent
            spacing: Style.marginS

            NText {
                visible: entryState.showSeparatorVisual && entryRoot.workspaceSeparatorShowLabel && entryState.separatorLabel.length > 0
                text: entryState.separatorLabel
                pointSize: Math.max(Style.fontSizeXS, entryRoot.barFontSize * 0.9)
                color: Color.mOnSurfaceVariant
                font.weight: Style.fontWeightSemiBold
                rotation: -90
            }

            Loader {
                visible: entryState.showSeparatorVisual && entryRoot.workspaceSeparatorShowDivider
                Layout.preferredWidth: Math.max(1, Style.borderS)
                Layout.preferredHeight: entryState.separatorLineLength
                sourceComponent: entryRoot.workspaceSeparatorDividerMode === "line" ? lineDividerComponentVertical : (entryRoot.workspaceSeparatorDividerMode === "character" ? charDividerComponentVertical : iconDividerComponentVertical)
            }
        }
    }

    Component {
        id: lineDividerComponent
        Rectangle {
            Layout.preferredWidth: root.entryState.separatorLineLength
            Layout.preferredHeight: Math.max(1, Style.borderS)
            radius: height / 2
            color: Qt.alpha(Color.mOutline, 0.7)
        }
    }

    Component {
        id: lineDividerComponentVertical
        Rectangle {
            Layout.preferredWidth: Math.max(1, Style.borderS)
            Layout.preferredHeight: root.entryState.separatorLineLength
            radius: width / 2
            color: Qt.alpha(Color.mOutline, 0.7)
        }
    }

    Component {
        id: charDividerComponent
        NText {
            text: root.entryRoot.workspaceSeparatorDividerChar || "|"
            pointSize: Math.max(Style.fontSizeXS, root.entryRoot.barFontSize * 0.9)
            color: Color.mOnSurfaceVariant
            font.weight: Style.fontWeightSemiBold
        }
    }

    Component {
        id: charDividerComponentVertical
        NText {
            text: root.entryRoot.workspaceSeparatorDividerChar || "|"
            pointSize: Math.max(Style.fontSizeXS, root.entryRoot.barFontSize * 0.9)
            color: Color.mOnSurfaceVariant
            font.weight: Style.fontWeightSemiBold
            rotation: -90
        }
    }

    Component {
        id: iconDividerComponent
        NIcon {
            icon: root.entryRoot.workspaceSeparatorDividerIcon || "minus"
            pointSize: Math.max(Style.fontSizeXS, root.entryRoot.barFontSize)
            color: Color.mOnSurfaceVariant
        }
    }

    Component {
        id: iconDividerComponentVertical
        NIcon {
            icon: root.entryRoot.workspaceSeparatorDividerIcon || "minus"
            pointSize: Math.max(Style.fontSizeXS, root.entryRoot.barFontSize)
            color: Color.mOnSurfaceVariant
            rotation: -90
        }
    }
}
