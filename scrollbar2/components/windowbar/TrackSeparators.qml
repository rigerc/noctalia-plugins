pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: separators

    required property var view
    required property Item trackLine

    x: 0
    y: trackLine.y
    width: separators.view.effectiveTrackWidth
    height: trackLine.height
    visible: separators.view.segmentCount > 1 && separators.view.segmentSpacing > 0 && trackLine.visible
    z: 11

    Repeater {
        model: Math.max(0, separators.view.segmentCount - 1)

        delegate: Rectangle {
            required property int index

            x: separators.view.separatorOffset(index)
            y: 0
            width: separators.view.segmentSpacing
            height: separators.height
            color: Qt.alpha(separators.view.separatorColor, separators.view.trackOpacity)
        }
    }
}

