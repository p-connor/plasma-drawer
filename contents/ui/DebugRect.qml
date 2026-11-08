import QtQuick

Rectangle {
    id: root

    anchors.fill: parent
    color: Qt.rgba(Math.random(), Math.random(), Math.random(), 1)
    opacity: 0.05 * (parent.activeFocus ? 3 : 1)
    visible: kicker.debugMode
    z: 100

    Rectangle {
        id: focusIndicator

        anchors.fill: parent
        visible: root.parent.activeFocus
        border.color: "magenta"
        border.width: 3
        color: Qt.rgba(0, 0, 0, 1)
        radius: 25
        opacity: 1
    }
}
