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
    height: background.height

    property int iconSize: units.iconSizes.large
    
    property int maxRows: -1
    readonly property int lastVisibleIndex: expandable && !expanded ? maxRows - 1 : count - 1
    property bool expanded: false
    readonly property bool expandable: maxRows != -1 && maxRows < count
    
    // If this property is true, the icon size will shrink when shrinkThreshold percent
    // of the model items have a source icon size less than the target
    property bool shrinkIconsToNative: false
    property var shrinkThreshold: shrinkIconsToNative ? .30 : 1.0

    readonly property alias rowWidth: itemList.width
    readonly property int rowHeight: iconSize * 1.5

    property alias currentIndex: listView.currentIndex
    property alias currentItem: listView.currentItem
    property alias contentItem: listView.contentItem
    property alias count: listView.count
    property alias model: listView.model
    property alias interactive: listView.interactive

    function trigger(itemIndex) {
        model.trigger(itemIndex, "", null);
        root.toggle();
    }

    onExpandedChanged: {
        if (!expanded && currentIndex > maxRows - 1) {
            currentIndex = maxRows - 1
        }
    }

    onExpandableChanged: {
        expanded: false
    }

    // onCurrentIndexChanged: {
    //     if (currentIndex != -1) {
    //         itemList.focus = true;
    //     }
    // }

    Rectangle {
        id: background
        width: rowWidth
        height: listView.height + (units.smallSpacing * 2)
        color: "#08FFFFFF"
        radius: units.smallSpacing * 3

        ListView {
            id: listView
            width: parent.width
            height: contentHeight
            state: "UNEXPANDED"
            y: units.smallSpacing

            clip: true

            focus: true

            currentIndex: -1
            highlightFollowsCurrentItem: true
            highlight: PlasmaComponents.Highlight {}
            highlightMoveDuration: 0

            property int targetIconSize: itemList.iconSize
            onCountChanged: {
                if (shrinkIconsToNative) {
                    let smaller = 0;
                    let nextSmallestSize = units.iconSizes.tiny;
                    for (let i = 0; i < count; i++) {
                        let item = itemAtIndex(i);
                        if (!item) {
                            continue;
                        }
                        if (item.sourceIconSize < itemList.iconSize) {
                            smaller++;
                            nextSmallestSize = Math.max(nextSmallestSize, item.sourceIconSize);
                        }
                    }
                    if (smaller / count > itemList.shrinkThreshold) {
                        itemList.iconSize = nextSmallestSize;
                    } else {
                        itemList.iconSize = targetIconSize;
                    }
                }
            }

            states: [
                State {
                    name: "UNEXPANDED"
                    when: !expandable || !expanded
                    PropertyChanges {
                        target: listView
                        height: expandable ? maxRows * rowHeight : contentHeight
                    }
                },
                State {
                    name: "EXPANDED"
                    when: expandable && expanded
                    PropertyChanges {
                        target: listView
                        height: contentHeight
                    }
                }
            ]
            transitions: Transition {
                from: "*"; to: "*"
                NumberAnimation { 
                    target: listView
                    property: "height"
                    duration: plasmoid.configuration.disableAnimations ? 0 : units.veryLongDuration
                    easing.type: Easing.OutCubic 
                }
            }

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

            Component.onCompleted: {
                targetIconSize = itemList.iconSize;
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                anchors.bottomMargin: 2     // Prevents autoscrolling down when mouse at bottom of list

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
                    itemList.trigger(currentIndex);
                }

                onPositionChanged: {
                    updatePositionProperties(mouse.x, mouse.y);
                }

                onExited: {
                    currentIndex = -1;
                }
            }
        }
    }

    Keys.onPressed: {
        if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
            event.accepted = true;
            itemList.trigger(currentIndex);
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
            
            if (currentIndex < lastVisibleIndex) {
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

        if (event.key == Qt.Key_PageUp) {
            if (currentIndex == -1) {
                currentIndex = 0;
                return;
            }
            
            currentIndex = -1;
            keyNavUp();
            return;
        }
        
        if (event.key == Qt.Key_PageDown) {
            if (currentIndex == -1) {
                currentIndex = 0;
                return;
            }
            
            currentIndex = -1;
            keyNavDown();
            return;
        }
    }
}