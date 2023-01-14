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
import QtQuick.Controls 2.15

import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0
import org.kde.draganddrop 2.0
import org.kde.kirigami 2.16 as Kirigami

FocusScope {
    id: itemGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    property bool dragEnabled: true
    property bool showLabels: true
    property alias usesPlasmaTheme: gridView.usesPlasmaTheme

    property int iconSize: units.iconSizes.large

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias contentY: gridView.contentY
    property alias count: gridView.count
    property alias flow: gridView.flow
    property alias snapMode: gridView.snapMode
    property alias model: gridView.model

    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight
    readonly property int numberColumns: Math.floor(width / cellWidth)
    readonly property int numberRows: Math.ceil(count / numberColumns)

    property alias hoverEnabled: mouseArea.hoverEnabled

    property alias populateTransition: gridView.populate

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    function itemAtIndex(index) {
        return gridView.itemAtIndex(index);
    }

    function currentRow() {
        if (currentIndex == -1) {
            return -1;
        }

        return Math.floor(currentIndex / numberColumns);
    }

    function currentCol() {
        if (currentIndex == -1) {
            return -1;
        }

        return currentIndex - (currentRow() * numberColumns);
    }

    function lastRow() {
        return numberRows - 1;
    }

    function trySelect(row, col) {
        if (count) {
            // Constrains between 0 and numberRows - 1
            row = Math.min(Math.max(row, 0), numberRows - 1);
            col = Math.min(Math.max(col, 0), numberColumns - 1);
            currentIndex = Math.min(((row * numberColumns) + col), count - 1);

            gridView.forceActiveFocus();
        }
    }

    function trigger(index) {
        if (gridView.model.modelForRow(index) != null) {
            appsGrid.tryEnterDirectory(index);
        } else if ("trigger" in gridView.model) {
            gridView.model.trigger(index, "", null);
            root.toggle();
        }
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    ActionMenu {
        id: actionMenu

        onActionClicked: {
            var closeRequested = visualParent.actionTriggered(actionId, actionArgument);

            if (closeRequested) {
                root.toggle();
            }
        }
    }

    DropArea {
        id: dropArea

        anchors.fill: parent

        onDragMove: {
            var cPos = mapToItem(gridView.contentItem, event.x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item && item != kicker.dragSource && kicker.dragSource && kicker.dragSource.parent == gridView.contentItem && "moveRow" in item.GridView.view.model) {
                item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
            }
        }

        GridView {
            id: gridView
            anchors.fill: parent

            property bool usesPlasmaTheme: false

            focus: true
            visible: model ? model.count > 0 : false
            currentIndex: -1
            clip: true
            
            keyNavigationWraps: false
            boundsBehavior: Flickable.StopAtBounds
            snapMode: GridView.SnapToRow

            highlightFollowsCurrentItem: true
            highlight: PlasmaComponents.Highlight {
                visible: gridView.highlightFollowsCurrentItem
            }
            highlightMoveDuration: 0

            delegate: ItemGridDelegate {
                showLabel: showLabels
            }

            onModelChanged: {
                currentIndex = -1;
            }

            ScrollBar.vertical: PC3.ScrollBar {
                parent: gridView.parent
                anchors.top: gridView.top
                anchors.left: gridView.right
                anchors.bottom: gridView.bottom
            }

            Kirigami.WheelHandler {
                target: gridView
                filterMouseEvents: true
                // `20 * Qt.styleHints.wheelScrollLines` is the default speed.
                // `* PlasmaCore.Units.devicePixelRatio` is needed on X11
                // because Plasma doesn't support Qt scaling.
                horizontalStepSize: 20 * Qt.styleHints.wheelScrollLines * units.devicePixelRatio
                verticalStepSize: 20 * Qt.styleHints.wheelScrollLines * units.devicePixelRatio
            }

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

            Keys.onPressed: {
                let rowsInPage = Math.floor(gridView.height / cellSizeHeight);

                if (event.key == Qt.Key_PageUp) {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (currentRow() != 0) {
                        event.accepted = true;
                        trySelect(currentRow() - rowsInPage, currentCol());
                        positionViewAtIndex(currentIndex, GridView.Beginning);
                    } else {
                        itemGrid.keyNavUp();
                    }
                    return;
                }
                
                if (event.key == Qt.Key_PageDown) {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }

                    if (currentRow() != numberRows - 1) {
                        event.accepted = true;
                        trySelect(currentRow() + rowsInPage, currentCol());
                        positionViewAtIndex(currentIndex, GridView.Beginning);
                    } else {
                        itemGrid.keyNavDown();
                    }
                    return;
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            anchors.bottomMargin: 2; // Prevents autoscrolling down when mouse at bottom of grid

            property int pressX: -1
            property int pressY: -1
            property Item pressedItem: null

            acceptedButtons: Qt.LeftButton | Qt.RightButton

            enabled: itemGrid.enabled
            hoverEnabled: enabled

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
                    itemGrid.trigger(gridView.currentIndex);
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
