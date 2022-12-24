/***************************************************************************
 *   Copyright (C) 2014 by Weng Xuetian <wengxt@gmail.com>
 *   Copyright (C) 2013-2017 by Eike Hein <hein@kde.org>                   *
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
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker

import "../code/tools.js" as Tools
import QtQuick.Window 2.0
import QtQuick.Controls.Styles 1.4


Kicker.DashboardWindow {
    
    id: root

    property int iconSize:    plasmoid.configuration.iconSize
    property int spaceWidth:  plasmoid.configuration.spaceWidth
    property int spaceHeight: plasmoid.configuration.spaceHeight
    property int cellSizeWidth: spaceWidth + iconSize + theme.mSize(theme.defaultFont).height
                                + (2 * units.smallSpacing)
                                + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                highlightItemSvg.margins.left + highlightItemSvg.margins.right))

    property int cellSizeHeight: spaceHeight + iconSize + theme.mSize(theme.defaultFont).height
                                 + (2 * units.smallSpacing)
                                 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                 highlightItemSvg.margins.left + highlightItemSvg.margins.right))


    // property bool searching: (searchField.text != "")

    // keyEventProxy: searchField
    backgroundColor: "transparent"

    property bool linkUseCustomSizeGrid: plasmoid.configuration.useCustomSizeGrid
    property int gridNumCols:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberColumns : Math.floor(width  * 0.85  / cellSizeWidth) 
    property int gridNumRows:  plasmoid.configuration.useCustomSizeGrid ? plasmoid.configuration.numberRows : Math.floor(height * 0.8  /  cellSizeHeight)
    property int gridWidth:  gridNumCols * cellSizeWidth
    property int gridHeight: gridNumRows * cellSizeHeight

    property var modelStack: [appsModel]
    property int modelStackLength: modelStack.length;
    readonly property var currentModel: modelStack[modelStackLength - 1]
    
    // property bool showFavorites: plasmoid.configuration.showFavorites
    
    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onKeyEscapePressed: {
        // if (searching) {
        //     searchField.text = ""
        // } else {
            root.leave();
        // }
    }

    onVisibleChanged: {
        reset();
    }

    // onSearchingChanged: {
    //     if (searching) {
    //         currentModel = runnerModel;
    //         paginationBar.model = runnerModel;
    //     } else {
    //         reset();
    //     }
    // }

    function enterDirectoryAtCurrentIndex() {
        // if (rootMouseArea.mouseX != false) {
        //     let point = rootMouseArea.mapToItem(itemGridView.contentItem, rootMouseArea.mouseX, rootMouseArea.mouseY);
        //     directoryEnterTransition.populateOrigin = (point.x, point.y);
        //     itemGridView.populateTransition = directoryEnterTransition;
        // } else {
        //     itemGridView.zoomFromPos = (gridWidth / 2, gridHeight / 2);
        // }

        itemGridView.setupEnterTransitionAnimation();
        let dir = currentModel.modelForRow(itemGridView.currentIndex);
        if (dir.hasChildren) {
            //modelStack.push(dir);
            modelStack = [...modelStack, dir];
        }
    }

    function leave() {
        itemGridView.setupEnterTransitionAnimation(true);
        if (modelStack.length > 1) {
            //modelStack.pop();
            // Note: need to reassign array to cause 'changed' signal
            modelStack = modelStack.slice(0, -1);
        } else {
            root.toggle();
        }
    }

    function reset() {
        // if (!searching) {
        //     currentModel = appsModel;
        // }
        modelStack = [appsModel]
        // searchField.text = "";
    }

    mainItem: MouseArea {
        id: rootMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        hoverEnabled: true

        onClicked: {
            root.leave();
        }

        Rectangle{
            anchors.fill: parent
            color: colorWithAlpha(theme.backgroundColor, plasmoid.configuration.backgroundOpacity / 100)
        }

        PlasmaExtras.Heading {
            id: dummyHeading
            visible: false
            width: 0
            level: 5
        }

        TextMetrics {
            id: headingMetrics
            font: dummyHeading.font
        }

        ActionMenu {
            id: actionMenu
            onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
            onClosed: {
                itemGrid.currentIndex = -1;
            }
        }

        Rectangle{
            width: gridWidth
            height: gridHeight
            color: "transparent"
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            ItemGridView {
                id: itemGridView

                hoverEnabled: true

                visible: model.count > 0
                anchors.fill: parent

                cellWidth:  cellSizeWidth
                cellHeight: cellSizeHeight

                horizontalScrollBarPolicy: Qt.ScrollBarAlwaysOff
                verticalScrollBarPolicy: Qt.ScrollBarAlwaysOff

                dragEnabled: true

                model: currentModel
                
                // onCurrentIndexChanged: {
                //     if (currentIndex != -1 && !searching) {
                //         pageListScrollArea.focus = true;
                //         focus = true;
                //     }
                // }

                // onCountChanged: {
                //     if (index == 0) {
                //         if (searching) {
                //             currentIndex = 0;
                //         } else if (count == 0) {
                //             root.showFavorites = false;
                //             root.startIndex = 1;
                //             if (pageList.currentIndex == 0) {
                //                 pageList.currentIndex = 1;
                //             }
                //         } else {
                //             root.showFavorites = plasmoid.configuration.showFavorites;
                //             root.startIndex = (showFavorites && plasmoid.configuration.startOnFavorites) ? 0 : 1
                //         }
                //     }
                // }

                onKeyNavUp: {
                    currentIndex = -1;
                }

                onKeyNavDown: {
                    // if(systemFavoritesGrid.visible) {
                    //     currentIndex = -1;
                    //     systemFavoritesGrid.focus = true;
                    //     systemFavoritesGrid.tryActivate(0, 0);
                    // }
                }
            }
        }
    }

    Component.onCompleted: {
        kicker.reset.connect(reset);

        // console.log("\n\n ---- PRINTING ---- \n\n");
        // logModelChildren(appsModel);
    }
}
