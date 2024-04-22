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

import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import Qt5Compat.GraphicalEffects

import "../code/tools.js" as Tools

Item {
    id: item

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    property bool showLabel: true
    property var iconColorOverride: undefined

    readonly property bool isDirectory: model.hasChildren ?? false
    readonly property var directoryModel: isDirectory ? GridView.view.model.modelForRow(itemIndex) : undefined

    // For this widget, the only favoritable actions should be system actions
    readonly property bool isSystemAction: (model.favoriteId 
                                            && GridView.view.model.favoritesModel 
                                            && GridView.view.model.favoritesModel.enabled) ?? false

    readonly property int itemIndex: model.index
    readonly property url url: model.url != undefined ? model.url : ""
    property bool pressed: false

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    readonly property bool hasActionList: ((("hasActionList" in model) && (model.hasActionList == true))
                                           || isSystemAction)
    
    function getActionList() {
        return isSystemAction ? Tools.createSystemActionActions(i18n, GridView.view.model.favoritesModel, model.favoriteId) : model.actionList;
    }

    // Rectangle{
    //     id: box
    //     height: parent.height // - 10
    //     width:  parent.width  // - 10
    //     anchors.verticalCenter: parent.verticalCenter
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     color: "transparent"
    // }

    Component {
        id: iconComponent

        Item {
            anchors.centerIn: parent
            Kirigami.Icon {
                id: icon
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                animated: false
                // usesPlasmaTheme: loaderUsesPlasmaTheme
                source: model.decoration
                roundToIconSize: width > Kirigami.Units.iconSizes.huge ? false : true
            }

            // Modify icon color to text color if using custom theme
            ColorOverlay {
                visible: typeof iconColorOverride != undefined
                anchors.fill: icon
                source: icon
                color: iconColorOverride ?? "#00000000"
                cached: true
            }
        }
    }

    Component {
        id: directoryViewComponent

        Rectangle {
            id: directoryBackgroundBox

            // anchors.fill: parent
            radius: width / 4
            //border.color: Kirigami.Theme.textColor
            //border.width: 2
            color: "#33000005"

            GridView {
                id: directoryGridView
                
                anchors.fill: parent
                anchors.margins: parent.width / 10
                cellWidth: (width / 2) * 0.9 > Kirigami.Units.iconSizes.small ? width / 2 : width
                cellHeight: cellWidth
                
                // TODO - don't use clip here for performance reasons
                clip: true
                z: 1 // Make in front of background
                interactive: false

                model: directoryModel
                delegate: Item {
                    width: directoryGridView.cellWidth
                    height: directoryGridView.cellHeight

                    Kirigami.Icon {
                        id: directoryIconItem

                        width: parent.width * 0.9
                        height: parent.height * 0.9
                        anchors.centerIn: parent

                        animated: false
                        // usesPlasmaTheme: loaderUsesPlasmaTheme
                        source: model.decoration
                        roundToIconSize: width > Kirigami.Units.iconSizes.medium ? false : true
                    }
                }
            }
        }
    }

    Rectangle {
        id: displayBox
        width: iconSize
        height: width
        y: (item.height / 2) - (height / 2) - (showLabel ? label.height / 2 : 0)
        anchors.horizontalCenter: parent.horizontalCenter
        // anchors.verticalCenter: parent.verticalCenter - (showLabel ? label.height / 2 : 0)
        color:"transparent"

        // Load either icon or directory view
        Loader {
            id: displayLoader
            anchors.fill: parent

            property bool loaderUsesPlasmaTheme: item.GridView.view.usesPlasmaTheme

            sourceComponent: isDirectory && !plasmoid.configuration.useDirectoryIcons ? directoryViewComponent : iconComponent
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

    PC3.Label {
        id: label

        visible: showLabel

        anchors {
            top: displayBox.bottom
            topMargin: Kirigami.Units.smallSpacing
            left: parent.left
            leftMargin: highlightItemSvg.margins.left
            right: parent.right
            rightMargin: highlightItemSvg.margins.right
        }

        horizontalAlignment: Text.AlignHCenter

        elide: Text.ElideRight
        wrapMode: Text.NoWrap

        text: model.display
        color: drawerTheme.textColor
    }

    // PC3.Label {
    //     id: folderArrow

    //     visible: isDirectory

    //     anchors {
    //         top: label.bottom
    //         topMargin: Kirigami.Units.smallSpacing
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
}
