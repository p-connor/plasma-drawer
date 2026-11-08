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

import "../code/tools.js" as Tools
import org.kde.draganddrop
import org.kde.kquickcontrolsaddons

import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras as PlasmaExtras

FocusScope {
    id: itemGrid

    property bool dragEnabled: true
    property bool showLabels: true
    property bool setIconColorBasedOnTheme: false
    property bool forceSymbolicIcons: false
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
    function openActionMenu(x, y, actionList) {
        if (actionList && "length" in actionList && actionList.length > 0) {
            actionMenu.actionList = actionList;
            actionMenu.targetIndex = currentIndex;
            actionMenu.open(x, y);
        }
    }

    // ScrollView needs additional space on the right for the scrollbar,
    // so we add additional padding on the left to center the gridview
    implicitWidth: scrollView.width + scrollView.ScrollBar.vertical.width
    implicitHeight: scrollView.height
    Keys.forwardTo: [gridView]

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

        // TODO: Move off of ScrollView as it hijacks up/down key events
        // See https://code.qt.io/cgit/qt/qtdeclarative.git/tree/src/quicktemplates/qquickscrollview.cpp?h=6.9.3#n642
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

                property var lastActiveFocusIndex: undefined

                width: numberColumns * cellWidth
                height: parent.height
                // anchors.left: parent.left
                // anchors.verticalCenter: parent.verticalCenter

                focus: true
                visible: model ? model.count > 0 : false
                currentIndex: -1
                // clip: true

                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds
                snapMode: GridView.SnapToRow
                flickDeceleration: 4000
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 0

                highlight: PlasmaExtras.Highlight {
                    visible: gridView.highlightFollowsCurrentItem
                }
                delegate: ItemGridDelegate {
                    showLabel: showLabels
                    iconColorOverride: setIconColorBasedOnTheme && drawerTheme.usingCustomTheme ? drawerTheme.iconColor : undefined
                    forceSymbolicIcons: itemGrid.forceSymbolicIcons

                    DebugRect {}
                }

                onModelChanged: {
                    currentIndex = -1;
                }
                onActiveFocusChanged: {
                    if (activeFocus) {
                        currentIndex = lastActiveFocusIndex ?? 0;
                    } else {
                        lastActiveFocusIndex = currentIndex;
                        currentIndex = -1;
                    }
                }
                Keys.onPressed: function (event) {
                    function accept(event) {
                        // Take focus on forwarded key events
                        if (!gridView.activeFocus) {
                            gridView.forceActiveFocus();
                        }
                        event.accepted = true;
                    }

                    // Returns true if nothing was previously selected
                    function ensureSelection(event) {
                        if (currentIndex == -1) {
                            currentIndex = 0;
                            accept(event);
                            return true;
                        }
                        return false;
                    }

                    switch (event.key) {
                    case Qt.Key_Up:
                        if (!ensureSelection(event) && currentRow() != 0) {
                            accept(event);
                            moveCurrentIndexUp();
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }
                        break;
                    case Qt.Key_Down:
                        if (!ensureSelection(event) && currentRow() < itemGrid.lastRow()) {
                            // moveCurrentIndexDown() doesn't handle spatial nav down into partial rows.
                            accept(event);
                            var columns = Math.floor(width / cellWidth);
                            var newIndex = currentIndex + columns;
                            currentIndex = Math.min(newIndex, count - 1);
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }
                        break;
                    case Qt.Key_Left:
                        if (!ensureSelection(event) && !(event.modifiers & Qt.ControlModifier) && currentCol() != 0) {
                            accept(event);
                            moveCurrentIndexLeft();
                        }
                        break;
                    case Qt.Key_Right:
                        if (!ensureSelection(event) && !(event.modifiers & Qt.ControlModifier) && currentCol() != numberColumns - 1 && currentIndex != count - 1) {
                            accept(event);
                            moveCurrentIndexRight();
                        }
                        break;
                    case Qt.Key_PageUp:
                        if (currentRow() != 0) {
                            accept(event);
                            trySelect(currentRow() - rowsInPage, currentCol());
                            positionViewAtIndex(currentIndex, GridView.Beginning);
                        }
                        break;
                    case Qt.Key_PageDown:
                        if (currentRow() != numberRows - 1) {
                            accept(event);
                            trySelect(currentRow() + numberRows, currentCol());
                            positionViewAtIndex(currentIndex, GridView.Beginning);
                        }
                        break;
                    case Qt.Key_Menu:
                        if (currentItem && currentItem.hasActionList) {
                            accept(event);
                            openActionMenu(currentItem.x, currentItem.y, currentItem.getActionList());
                        }
                        break;
                    case Qt.Key_Enter:
                    case Qt.Key_Return:
                        if (currentIndex != -1) {
                            accept(event);
                            itemGrid.trigger(currentIndex);
                        }
                        break;
                    }
                }

                MouseArea {
                    id: mouseArea

                    property int pressX: -1
                    property int pressY: -1

                    function updatePositionProperties(x, y) {
                        var cPos = mapToItem(gridView.contentItem, x, y);
                        var index = gridView.indexAt(cPos.x, cPos.y);
                        gridView.currentIndex = index;
                        //itemGrid.focus = true;

                        return index;
                    }

                    anchors.fill: parent
                    anchors.bottomMargin: 2 // Prevents autoscrolling down when mouse at bottom of grid

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    enabled: itemGrid.enabled
                    hoverEnabled: enabled

                    onPressed: function (mouse) {
                        mouse.accepted = true;
                        updatePositionProperties(mouse.x, mouse.y);
                        itemGrid.focus = true;
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
                        itemGrid.focus = true;
                        if (gridView.currentItem) {
                            itemGrid.trigger(gridView.currentIndex);
                        } else if (!dragHelper.dragging) {
                            // TODO - pass mouse events down to root instead
                            if (mouse.button == Qt.RightButton) {
                                var cpos = mapToItem(root.content, mouse.x, mouse.y);
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
                                    dragHelper.startDrag(kicker, currentItem.url, currentItem.icon, "text/x-plasmoidservicename", currentItem.m.pluginName);
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
