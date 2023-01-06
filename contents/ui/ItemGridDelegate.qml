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

import QtQuick 2.0

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

Item {
    id: item

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    property bool showLabel: true

    readonly property bool isDirectory: model.hasChildren ?? false
    readonly property var directoryModel: isDirectory ? GridView.view.model.modelForRow(itemIndex) : undefined

    // For this widget, the only favoritable actions should be system actions
    readonly property bool isSystemAction: (model.favoriteId 
                                            && GridView.view.model.favoritesModel 
                                            && GridView.view.model.favoritesModel.enabled) ?? false

    readonly property int itemIndex: model.index
    readonly property url url: model.url != undefined ? model.url : ""
    property bool pressed: false
    readonly property bool hasActionList: ((("hasActionList" in model) && (model.hasActionList == true))
                                           || isDirectory
                                           || isSystemAction)

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    function openActionMenu(x, y) {
        if (isDirectory) {
            actionMenu.actionList = Tools.createDirectoryActions(i18n);
        } else if (isSystemAction) {
            actionMenu.actionList = Tools.createSystemActionActions(i18n, GridView.view.model.favoritesModel, model.favoriteId);
        } else if (hasActionList) {
            actionMenu.actionList = model.actionList;
        }

        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        return Tools.triggerAction(plasmoid, GridView.view.model, model.index, actionId, actionArgument);
    }

    // Rectangle{
    //     id: box
    //     height: parent.height // - 10
    //     width:  parent.width  // - 10
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     color: "transparent"
    // }

    Rectangle {
        id: displayBox
        width: iconSize
        height: width
        y: iconSize * 0.2
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter
        color:"transparent"

        // Icon shown if not directory or TODO: setting enabled
        PlasmaCore.IconItem {
            id: icon
            visible: !isDirectory
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: parent.height
            animated: false
            usesPlasmaTheme: item.GridView.view.usesPlasmaTheme
            source: model.decoration
        }

        // Otherwise if directory, show directory box instead
        Rectangle {
            id: directoryBackgroundBox
            visible: isDirectory

            anchors.fill: parent
            radius: width / 4
            //border.color: theme.textColor
            //border.width: 2
            color: "#33000005"

            GridView {
                id: directoryGridView
                
                anchors.fill: parent
                anchors.margins: parent.width / 10
                cellWidth: width / 2 > units.iconSizes.small ? width / 2 : width
                cellHeight: cellWidth
                
                // TODO - don't use clip here for performance reasons
                clip: true
                z: 1 // Make in front of background
                interactive: false

                model: directoryModel
                delegate: Item {
                    width: directoryGridView.cellWidth
                    height: directoryGridView.cellHeight

                    PlasmaCore.IconItem {
                        id: directoryIconItem

                        anchors.fill: parent
                        animated: false
                        usesPlasmaTheme: item.GridView.view.usesPlasmaTheme
                        source: model.decoration
                    }
                }
            }
        }
    }

    // Rectangle{
    //     id: box
    //     height: parent.height // - 10
    //     width:  parent.width  // - 10
    //     anchors.verticalCenter: box.verticalCenter
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     color:"red"
    //     opacity: 0.4
    //     // color: "transparent"
    // }

    PlasmaComponents.Label {
        id: label

        visible: showLabel

        anchors {
            top: displayBox.bottom
            topMargin: units.smallSpacing
            left: parent.left
            leftMargin: highlightItemSvg.margins.left
            right: parent.right
            rightMargin: highlightItemSvg.margins.right
        }

        horizontalAlignment: Text.AlignHCenter

        elide: Text.ElideRight
        wrapMode: Text.NoWrap

        text: model.display
    }

    // PlasmaComponents.Label {
    //     id: folderArrow

    //     visible: isDirectory

    //     anchors {
    //         top: label.bottom
    //         topMargin: units.smallSpacing
    //         left: parent.left
    //         leftMargin: highlightItemSvg.margins.left
    //         right: parent.right
    //         rightMargin: highlightItemSvg.margins.right
    //     }

    //     horizontalAlignment: Text.AlignHCenter

    //     elide: Text.ElideRight
    //     wrapMode: Text.NoWrap

    //     text: "^"
    // }

    Keys.onPressed: {
        if (event.key == Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu(item);
        } else if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
            event.accepted = true;
            GridView.view.model.trigger(index, "", null);
            root.toggle();

        }
    }
}
