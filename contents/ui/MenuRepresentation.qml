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

import QtQuick 2.15

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

    property int maxContentHeight: height * 0.7
    property int topBottomMargin: units.iconSizes.large // (height - maxContentHeight) / 4

    // keyEventProxy: searchField
    backgroundColor: "transparent"

    property bool searching: searchField.text != ""

    // TODO: remove this and all focus debug rectangles
    property bool debugFocus: false
    
    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onVisibleChanged: {
        reset();
    }

    onSearchingChanged: {
        if (!searching) {
            reset();
        }
    }

    onKeyEscapePressed: {
        if (searching) {
            searchField.text = "";
        } else {
            root.leave();
        }
    }

    function leave() {
        if (!searching && !appsGridView.isAtRoot) {
            appsGridView.tryExitDirectory();
        } else {
            root.toggle();
        }
    }

    function reset() {
        searchField.text = "";
        appsGridView.returnToRootDirectory(false);
        appsGridView.focus = true;
    }

    mainItem: MouseArea {
        id: rootMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        // hoverEnabled: true

        onClicked: {
            mouse.accepted = true;
            root.leave();
        }

        Rectangle {
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

        PlasmaComponents.TextField {
            id: searchField

            anchors.top: parent.top
            anchors.topMargin: topBottomMargin
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.2
            
            style: TextFieldStyle {
                textColor: theme.textColor
                background: Rectangle {
                    radius: height * 0.25
                    color: theme.textColor
                    opacity: 0.2
                }
            }
            horizontalAlignment: TextInput.AlignHCenter
            placeholderText: i18n("<font color='"+colorWithAlpha(theme.textColor,0.5) +"'>Plasma Search</font>")
            
            onTextChanged: {
                runnerModel.query = text;
            }

            PlasmaCore.IconItem {
                id: searchIcon
                source: "search-icon"
                visible: true
                width:  parent.height - 2
                height: width
                anchors {
                    left: parent.left
                    leftMargin: 10
                    verticalCenter: parent.verticalCenter
                }
            }

            Keys.onDownPressed: {
                event.accepted = true;
                if (searching) {
                    runnerResultsView.focus = true;
                    runnerResultsView.selectFirst();
                } else {
                    appsGridView.focus = true;
                    appsGridView.selectFirst();
                }
            }

            Keys.onPressed: {
                if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
                    event.accepted = true;
                    if (!runnerResultsView.currentMatch) {
                        runnerResultsView.selectFirst();
                    }
                    runnerResultsView.triggerSelected();
                    return;
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "red"
                opacity: 0.05
                visible: root.debugFocus && searchField.activeFocus
                z: 100
            }
        }

        Rectangle{
            id: content
            width: Math.max(appsGridView.width, runnerResultsView.width)
            height: maxContentHeight
            color: "transparent"
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }

            RunnerResultsView {
                id: runnerResultsView

                height: parent.height
                width: units.gridUnit * 30
                anchors.horizontalCenter: parent.horizontalCenter

                visible: searching
                enabled: visible

                iconSize: plasmoid.configuration.searchIconSize
                shrinkIconsToNative: plasmoid.configuration.adaptiveSearchIconSize

                Rectangle {
                    anchors.fill: parent
                    color: "red"
                    opacity: 0.05
                    visible: root.debugFocus && parent.activeFocus
                    z: 100
                }

                onKeyNavUp: {
                    searchField.focus = true;
                }
                onKeyNavDown: {
                    if (systemActionsGrid.visible) {
                        systemActionsGrid.focus = true;
                        systemActionsGrid.trySelect(0, 0);
                    }
                }

                model: runnerModel
            }

            AppsGridView {
                id: appsGridView

                anchors.centerIn: parent
                height: parent.height

                visible: !searching && appsModel.count > 0
                enabled: visible
                focus: true

                iconSize: plasmoid.configuration.appIconSize
                numberColumns: plasmoid.configuration.numberColumns

                model: appsModel

                onKeyNavUp: {
                    searchField.focus = true;
                }
                onKeyNavDown: {
                    if (systemActionsGrid.visible) {
                        systemActionsGrid.focus = true;
                        systemActionsGrid.trySelect(0, 0);
                    }
                }
            }
        }

        ItemGridView {
            id: systemActionsGrid
            
            model: systemFavoritesModel

            visible: count > 0 && plasmoid.configuration.showSystemActions
            enabled: visible

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                margins: units.largeSpacing
                bottomMargin: topBottomMargin
            }

            iconSize: plasmoid.configuration.systemActionIconSize
            cellWidth: iconSize + units.largeSpacing
            cellHeight: cellWidth
            height: cellHeight
            width: cellWidth * count
            
            opacity: 0.9

            dragEnabled: true
            showLabels: false
            usesPlasmaTheme: true

            onKeyNavUp: {
                currentIndex = -1;
                if (searching) {
                    runnerResultsView.focus = true;
                    runnerResultsView.selectLast();
                } else {
                    appsGridView.focus = true;
                    appsGridView.selectLast();
                }
            }
        }
 
        Keys.onPressed: {
            if (searchField.focus) {
                return;
            }

            if (event.key == Qt.Key_Backspace) {
                event.accepted = true;
                searchField.focus = true;
                searchField.text = searchField.text.slice(0, -1);
            } else if (event.text != "") {
                event.accepted = true;
                searchField.focus = true;
                searchField.text = searchField.text + event.text;
            }
        }
    }

    Component.onCompleted: {
        kicker.reset.connect(reset);
    }
}
