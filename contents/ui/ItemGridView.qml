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

import QtQuick
import QtQuick.Controls

import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kquickcontrolsaddons
import org.kde.draganddrop

import "../code/tools.js" as Tools

FocusScope {
    id: itemGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    property bool dragEnabled: true
    property bool showLabels: true
    property alias usesPlasmaTheme: gridView.usesPlasmaTheme
    property bool setIconColorBasedOnTheme: false

    property int iconSize: Kirigami.Units.iconSizes.large

    property int numberColumns: Math.floor(width / cellWidth)
    property int maxVisibleRows: -1
    readonly property int numberRows: Math.ceil(count / numberColumns)
    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight

    property alias model: gridView.model

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias contentY: gridView.contentY
    property alias count: gridView.count
    property alias flow: gridView.flow
    property alias snapMode: gridView.snapMode

    property alias hoverEnabled: mouseArea.hoverEnabled

    property alias populateTransition: gridView.populate

    // ScrollView needs additional space on the right for the scrollbar,
    // so we add additional padding on the left to center the gridview
    implicitWidth: scrollView.width + scrollView.ScrollBar.vertical.width
    implicitHeight: scrollView.height

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

        property int targetIndex: -1

        visualParent: gridView
        
        onActionClicked: function (actionId, actionArgument) {
            var closeRequested = Tools.triggerAction(plasmoid, model, targetIndex, actionId, actionArgument);
            if (closeRequested) {
                root.toggle();
            }
        }

        onClosed: {
            currentIndex = -1;
        }
    }

    function openActionMenu(x, y, actionList) {
        if (actionList && "length" in actionList && actionList.length > 0) {
            actionMenu.actionList = actionList;
            actionMenu.targetIndex = currentIndex;
            actionMenu.open(x, y);
        }
    }

    DropArea {
        id: dropArea

        width: numberColumns * cellWidth
        height: (maxVisibleRows == -1 ? numberRows : maxVisibleRows) * cellHeight
        anchors.centerIn: parent

        onDragMove: function (event) {
            var cPos = mapToItem(gridView.contentItem, event.x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item && item != kicker.dragSource && kicker.dragSource && kicker.dragSource.parent == gridView.contentItem && "moveRow" in item.GridView.view.model) {
                item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
            }
        }

        PC3.ScrollView {
            id: scrollView
            width: (numberColumns * cellWidth) + ScrollBar.vertical.width
            height: parent.height
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical.interactive: true

            focus: true

            GridView {
                id: gridView
                width: numberColumns * cellWidth
                height: parent.height
                // anchors.left: parent.left
                // anchors.verticalCenter: parent.verticalCenter

                property bool usesPlasmaTheme: false
                
                focus: true
                visible: model ? model.count > 0 : false
                currentIndex: -1
                // clip: true
                layer.enabled : true

                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds
                snapMode: GridView.SnapToRow
                flickDeceleration: 4000

                highlightFollowsCurrentItem: true
                highlight: PlasmaExtras.Highlight {
                    visible: gridView.highlightFollowsCurrentItem
                }
                highlightMoveDuration: 0

                delegate: ItemGridDelegate {
                    showLabel: showLabels
                    iconColorOverride: setIconColorBasedOnTheme && drawerTheme.usingCustomTheme ? drawerTheme.iconColor : undefined
                }

                onModelChanged: {
                    currentIndex = -1;
                }

                Keys.onLeftPressed: function (event) {
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

                Keys.onRightPressed: function (event) {
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

                Keys.onUpPressed: function (event) {
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

                Keys.onDownPressed: function (event) {
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

                Keys.onPressed: function (event) {
                    if (event.key == Qt.Key_Menu && currentItem && currentItem.hasActionList) {
                        event.accepted = true;
                        openActionMenu(currentItem.x, currentItem.y, currentItem.getActionList());
                        return;
                    } 
                    if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return && currentIndex != -1)) {
                        event.accepted = true;
                        itemGrid.trigger(currentIndex);
                        // root.toggle();
                    }

                    let rowsInPage = Math.floor(gridView.height / cellHeight);

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

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    anchors.bottomMargin: 2; // Prevents autoscrolling down when mouse at bottom of grid

                    property int pressX: -1
                    property int pressY: -1

                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    enabled: itemGrid.enabled
                    hoverEnabled: enabled

                    function updatePositionProperties(x, y) {
                        var cPos = mapToItem(gridView.contentItem, x, y);
                        var index = gridView.indexAt(cPos.x, cPos.y);
                        gridView.currentIndex = index;
                        itemGrid.focus = true;

                        return index;
                    }

                    onPressed: function (mouse) {
                        mouse.accepted = true;
                        updatePositionProperties(mouse.x, mouse.y);
                        pressX = mouse.x;
                        pressY = mouse.y;

                        if (mouse.button == Qt.RightButton) {
                            if (gridView.currentItem && gridView.currentItem.hasActionList) {
                                openActionMenu(mouse.x, mouse.y, gridView.currentItem.getActionList());
                            }
                        }
                    }

                    onReleased: function (mouse) {
                        mouse.accepted = true;
                        if (gridView.currentItem) {
                            itemGrid.trigger(gridView.currentIndex);
                        } else if (!dragHelper.dragging) {
                            // TODO - pass mouse events down to root instead
                            if (mouse.button == Qt.RightButton) {
                                var cpos = mapToItem(root.mainItem, mouse.x, mouse.y);
                                root.openActionMenu(cpos.x, cpos.y);
                            } else {
                                root.leave();
                            }
                        }

                        pressX = -1;
                        pressY = -1;
                    }

                    onPressAndHold: function (mouse) {
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
                    }

                    onPositionChanged: function (mouse) {
                        updatePositionProperties(mouse.x, mouse.y);

                        if (gridView.currentIndex != -1 && currentItem && currentItem.m != null) {
                            if (dragEnabled && pressX != -1 && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                                if ("pluginName" in currentItem.m) {
                                    dragHelper.startDrag(kicker, currentItem.url, currentItem.icon,
                                    "text/x-plasmoidservicename", currentItem.m.pluginName);
                                } else {
                                    dragHelper.startDrag(kicker, currentItem.url, currentItem.icon);
                                }

                                kicker.dragSource = currentItem;

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
                            //hoverEnabled = false;
                        }
                    }
                }
            }
        }
    }
}
