import QtQuick
import qs.Commons

Item {
    id: separators

    required property var view
    required property Item trackLine

    x: 0
    y: trackLine.y
    width: view.effectiveTrackWidth
    height: trackLine.height
    visible: view.segmentCount > 1 && view.segmentSpacing > 0 && trackLine.visible
    z: 11

    Repeater {
        model: Math.max(0, view.segmentCount - 1)

        delegate: Rectangle {
            required property int index

            x: view.separatorOffset(index)
            y: 0
            width: view.segmentSpacing
            height: separators.height
            color: Qt.alpha(view.separatorColor, view.trackOpacity)
        }
    }
}

