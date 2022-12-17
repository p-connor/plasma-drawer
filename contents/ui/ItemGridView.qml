/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.4

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0
import org.kde.draganddrop 2.0

FocusScope {
    id: itemGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    property bool dragEnabled: true
    property bool showLabels: true
    property alias usesPlasmaTheme: gridView.usesPlasmaTheme

    property int iconSize: root.iconSize

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias count: gridView.count
    property alias flow: gridView.flow
    property alias snapMode: gridView.snapMode
    property alias model: gridView.model

    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight

    property alias horizontalScrollBarPolicy: scrollArea.horizontalScrollBarPolicy
    property alias verticalScrollBarPolicy: scrollArea.verticalScrollBarPolicy

    property alias hoverEnabled: mouseArea.hoverEnabled

    property alias populateTransition: gridView.populate

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    function currentRow() {
        if (currentIndex == -1) {
            return -1;
        }

        return Math.floor(currentIndex / Math.floor(width / cellWidth));
    }

    function currentCol() {
        if (currentIndex == -1) {
            return -1;
        }

        return currentIndex - (currentRow() * Math.floor(width / cellWidth));
    }

    function lastRow() {
        var columns = Math.floor(width / cellWidth);
        return Math.ceil(count / columns) - 1;
    }

    function tryActivate(row, col) {
        if (count) {
            var columns = Math.floor(width / cellWidth);
            var rows = Math.ceil(count / columns);
            row = Math.min(row, rows - 1);
            col = Math.min(col, columns - 1);
            currentIndex = Math.min(row ? ((Math.max(1, row) * columns) + col)
                : col,
                count - 1);

            gridView.forceActiveFocus();
        }
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    function setupEnterTransitionAnimation(isReverse = false, pos = null) {        
        if (pos) {
            gridView.populateOrigin = pos;
        } else if (currentItem) {
            gridView.populateOrigin = Qt.point(currentItem.x, currentItem.y);
        } else {
            gridView.populateOrigin = Qt.point(gridView.width / 2, gridView.height / 2);
        }
        
        if (!isReverse) {
            gridView.populate = directoryEnterTransition;
        } else {
            gridView.populate = directoryReturnTransition;
        }
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: {
            var closeRequested = visualParent.actionTriggered(actionId, actionArgument);

            if (closeRequested) {
                root.leave();
            }
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: parent

        onDragMove: {
            var cPos = mapToItem(gridView.contentItem, event.x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item && item != kicker.dragSource && kicker.dragSource && kicker.dragSource.parent == gridView.contentItem) {
                item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
            }
        }

        PlasmaExtras.ScrollArea {
            id: scrollArea

            anchors.fill: parent

            focus: true

            horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff

            GridView {
                id: gridView

                property bool usesPlasmaTheme: false
                property var populateOrigin: Qt.point(gridView.width / 2, gridView.height / 2)

                focus: true
                visible: model.count > 0
                //enabled: visible    
                currentIndex: -1
             
                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                highlight: PlasmaComponents.Highlight {}
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0

                delegate: ItemGridDelegate {
                    showLabel: showLabels
                }

                onModelChanged: {
                    currentIndex = -1;
                }

                Transition {
                    id: directoryEnterTransition
                    // PauseAnimation {
                    //     duration: (directoryEnterTransition.ViewTransition.index) * 300
                    // }
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: units.longDuration }
                    NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: units.longDuration; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "x"; from: gridView.populateOrigin.x; duration: units.veryLongDuration; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "y"; from: gridView.populateOrigin.y; duration: units.veryLongDuration; easing.type: Easing.OutCubic }
                }

                Transition {
                    id: directoryReturnTransition
                    // PauseAnimation {
                    //     duration: (directoryEnterTransition.ViewTransition.index) * 300
                    // }
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: units.longDuration }
                    NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: units.longDuration; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "x"; from: directoryReturnTransition.ViewTransition.item.x + (directoryReturnTransition.ViewTransition.item.x - (width / 2)); duration: units.veryLongDuration; easing.type: Easing.OutCubic }
                    NumberAnimation { properties: "y"; from: directoryReturnTransition.ViewTransition.item.y + (directoryReturnTransition.ViewTransition.item.y - (height / 2)); duration: units.veryLongDuration; easing.type: Easing.OutCubic }
                }

                populate: directoryEnterTransition

                Keys.onLeftPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (!(event.modifiers & Qt.ControlModifier) && currentCol() != 0) {
                        event.accepted = true;
                        moveCurrentIndexLeft();
                    } else {
                        itemGrid.keyNavLeft();
                    }
                }

                Keys.onRightPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    var columns = Math.floor(width / cellWidth);

                    if (!(event.modifiers & Qt.ControlModifier) && currentCol() != columns - 1 && currentIndex != count - 1) {
                        event.accepted = true;
                        moveCurrentIndexRight();
                    } else {
                        itemGrid.keyNavRight();
                    }
                }

                Keys.onUpPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (currentRow() != 0) {
                        event.accepted = true;
                        moveCurrentIndexUp();
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    } else {
                        itemGrid.keyNavUp();
                    }
                }

                Keys.onDownPressed: {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (currentRow() < itemGrid.lastRow()) {
                        // Fix moveCurrentIndexDown()'s lack of proper spatial nav down
                        // into partial columns.
                        event.accepted = true;
                        var columns = Math.floor(width / cellWidth);
                        var newIndex = currentIndex + columns;
                        currentIndex = Math.min(newIndex, count - 1);
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    } else {
                        itemGrid.keyNavDown();
                    }
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent

            property int pressX: -1
            property int pressY: -1
            property Item pressedItem: null

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            hoverEnabled: true

            function updatePositionProperties(x, y) {
                var cPos = mapToItem(gridView.contentItem, x, y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    gridView.currentIndex = -1;
                    pressedItem = null;
                } else {
                    gridView.currentIndex = item.itemIndex;
                }
                itemGrid.focus = true;

                return item;
            }

            onPressed: {
                mouse.accepted = true;

                updatePositionProperties(mouse.x, mouse.y);
                pressX = mouse.x;
                pressY = mouse.y;

                if (mouse.button == Qt.RightButton) {
                    if (gridView.currentItem && gridView.currentItem.hasActionList) {
                        var mapped = mapToItem(gridView.currentItem, mouse.x, mouse.y);
                        gridView.currentItem.openActionMenu(mapped.x, mapped.y);
                    }
                } else {
                    pressedItem = gridView.currentItem;
                }
            }

            onReleased: {
                mouse.accepted = true;
                if (gridView.currentItem && gridView.currentItem == pressedItem) {
                    
                    if (gridView.model.modelForRow(gridView.currentIndex) != null) {
                        root.enterDirectoryAtCurrentIndex();
                    } else if ("trigger" in gridView.model) {
                        gridView.model.trigger(pressedItem.itemIndex, "", null);

                        root.toggle();
                    }
                } else if (!pressedItem && mouse.button == Qt.LeftButton && !dragHelper.dragging) {
                    root.leave();
                }

                pressX = -1;
                pressY = -1;
                pressedItem = null;
            }

            onPressAndHold: {
                if (!dragEnabled) {
                    pressX = -1;
                    pressY = -1;
                    return;
                }

                var cPos = mapToItem(gridView.contentItem, mouse.x, mouse.y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    return;
                }

                if (!dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                    kicker.dragSource = item;
                    dragHelper.startDrag(kicker, item.url);
                }

                pressX = -1;
                pressY = -1;
                pressedItem = null;
            }

            onPositionChanged: {
                var item = updatePositionProperties(mouse.x, mouse.y);

                if (gridView.currentIndex != -1 && item != null && item.m != null) {
                    if (dragEnabled && pressX != -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                        if ("pluginName" in item.m) {
                            dragHelper.startDrag(kicker, item.url, item.icon,
                            "text/x-plasmoidservicename", item.m.pluginName);
                        } else {
                            dragHelper.startDrag(kicker, item.url, item.icon);
                        }

                        kicker.dragSource = item;

                        pressX = -1;
                        pressY = -1;
                    }
                }
            }

            onContainsMouseChanged: {
                if (!containsMouse) {
                    if (!actionMenu.opened) {
                        gridView.currentIndex = -1;
                    }

                    pressX = -1;
                    pressY = -1;
                    pressedItem = null;
                    //hoverEnabled = false;
                }
            }
        }
    }
}
