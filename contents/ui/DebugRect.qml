import QtQuick

Rectangle {
    id: root
    anchors.fill: parent
    color: Qt.rgba(Math.random(), Math.random(), Math.random(), 1)
    opacity: 0.05 * (parent.activeFocus ? 5 : 1)
    visible: kicker.debugMode
    z: 100
}
