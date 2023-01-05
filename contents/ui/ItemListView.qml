import QtQuick 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

FocusScope {
    id: itemList

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    width: PlasmaCore.Units.gridUnit * 20
    height: listView.contentHeight

    property int iconSize: units.iconSizes.large
    readonly property alias rowWidth: itemList.width
    readonly property int rowHeight: iconSize * 1.5

    property alias currentIndex: listView.currentIndex
    property alias currentItem: listView.currentItem
    property alias contentItem: listView.contentItem
    property alias count: listView.count
    property alias model: listView.model
    property alias interactive: listView.interactive

    function triggerItem(itemIndex) {
        model.trigger(itemIndex, "", null);
        root.toggle();
    }

    // onCurrentIndexChanged: {
    //     if (currentIndex != -1) {
    //         itemList.focus = true;
    //     }
    // }

    ListView {
        id: listView
        anchors.fill: parent

        focus: true

        currentIndex: -1
        highlightFollowsCurrentItem: true
        highlight: PlasmaComponents.Highlight {}
        highlightMoveDuration: 0

        delegate: ItemListDelegate {
            width: rowWidth
            height: rowHeight
            iconSize: itemList.iconSize

            Rectangle {
                anchors.fill: parent
                color: "green"
                opacity: 0.1
                visible: root.debugFocus && parent.activeFocus
                z: 100
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        enabled: itemList.enabled
        hoverEnabled: enabled

        function updatePositionProperties(x, y) {
            var cPos = mapToItem(contentItem, x, y);
            var index = listView.indexAt(cPos.x, cPos.y);
            currentIndex = index;
            // itemList.focus = true;
        }

        onReleased: {
            mouse.accepted = true;
            triggerItem(currentIndex);
        }

        onPositionChanged: {
            updatePositionProperties(mouse.x, mouse.y);
        }

        onExited: {
            currentIndex = -1;
        }
    }

    Keys.onPressed: {
        if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
            event.accepted = true;
            triggerItem(currentIndex);
            return;
        }
        
        if (event.key == Qt.Key_Up) {
            if (currentIndex == -1) {
                currentIndex = 0;
                return;
            }
            
            if (currentIndex > 0) {
                event.accepted = true;
                listView.decrementCurrentIndex();
            } else {
                currentIndex = -1;
                keyNavUp();
            }
            return;
        }
        
        if (event.key == Qt.Key_Down) {
            if (currentIndex == -1) {
                currentIndex = 0;
                return;
            }
            
            if (currentIndex < count - 1) {
                event.accepted = true;
                listView.incrementCurrentIndex();
            } else {
                currentIndex = -1;
                keyNavDown();
            }
            return;
        }
        
        if (event.key == Qt.Key_Left) {
            if (currentIndex == -1) {
                currentIndex = 0;
                return;
            }
            
            currentIndex = -1;
            keyNavLeft();
            return;
        }
        
        if (event.key == Qt.Key_Right) {
            if (currentIndex == -1) {
                currentIndex = 0;
                return;
            }

            currentIndex = -1;
            keyNavRight();
            return;
        }
    }
}