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

import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import QtQuick.Window
import Qt5Compat.GraphicalEffects

import "../code/tools.js" as Tools

AdaptiveDialog {
    id: root

    animated: !plasmoid.configuration.disableAnimations
    windowMode: plasmoid.configuration.windowMode

    readonly property bool searching: searchField.text != ""

    readonly property int contentMargin: Math.max(Kirigami.Units.iconSizes.huge, rootContentArea.height * .12)
    
    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha)
    }

    onVisibleChanged: {
        if (visible) {
            // Set favorites here to ensure system actions are available
            systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
            contentOpenAnimation.restart();
        } else {
            contentOpenAnimation.stop();
            reset();
        }
    }

    onSearchingChanged: {
        if (!searching) {
            reset();
        }
    }

    function leave() {
        if (!searching && !content.item.isAtRoot) {
            content.item.tryExitDirectory();
        } else {
            root.toggle();
        }
    }

    function reset() {
        searchField.text = "";
        // appsGridView.returnToRootDirectory(false);
        searchField.focus = false;
        content.focus = false;
        systemActionsGrid.focus = false;
    }

    function openActionMenu(x, y, actionList = undefined) {
        if (actionList) {
            actionMenu.actionList = actionList;
        } else {
            actionMenu.actionList = Tools.createMenuEditAction(i18n, processRunner);
        }
        actionMenu.open(x, y);
    }

    background: Loader {
        id: backgroundLoader
        sourceComponent: plasmoid.configuration.backgroundType == 2 ? backgroundImageComponent : backgroundRectComponent

        Component {
            id: backgroundRectComponent
            Rectangle {
                color: colorWithAlpha(drawerTheme.backgroundColor, plasmoid.configuration.backgroundOpacity / 100)
            }
        }

        Component {
            id: backgroundImageComponent
            Image {
                source: plasmoid.configuration.customBackgroundImagePath ?? ""
                opacity: plasmoid.configuration.backgroundOpacity / 100
            }
        }

        ActionMenu {
            id: actionMenu
            visualParent: backgroundLoader
            onActionClicked: function (actionId, actionArgument) {
                var closeRequested = Tools.triggerAction(plasmoid, null, -1, actionId, actionArgument);
                if (closeRequested) {
                    root.toggle();
                }
            }
        }
    }

    onBackgroundReleased: function (mouse) {
        mouse.accepted = true;
        if (mouse.button == Qt.RightButton) {
            if (!searching) {
                root.openActionMenu(mouse.x, mouse.y);
            }
        } else {
            root.leave();
        }
    }

    content: FocusScope {
        id: rootContentArea
        focus: true
        LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

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

        SearchBar {
            id: searchField

            visible: plasmoid.configuration.showSearch
            enabled: visible

            activeFocusOnTab: true

            anchors.top: parent.top
            anchors.topMargin: (contentMargin / 2) - (height / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(Kirigami.Units.gridUnit * 20, (parent.width * 0.25) + (leftInset * 2))

            onTextChanged: {
                runnerModel.query = text;
            }

            Keys.onPressed: function (event) {
                // TODO: replace with key forwarding to content Keys.forwardTo
                if (searching && (event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
                    event.accepted = true;
                    // Pass focus to content who should handle onReleased
                    content.item.forceActiveFocus();
                    return;
                }
            }

            Keys.onUpPressed: function (event) {
                nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
            }
            Keys.onDownPressed: function (event) {
                nextItemInFocusChain(true).forceActiveFocus(Qt.FocusReason);
            }

            DebugRect {}
        }

        Component {
            id: runnerResultsViewComponent
            RunnerResultsView {
                id: runnerResultsView

                width: Math.min(Kirigami.Units.gridUnit * 32, rootContentArea.width * 0.33)
                anchors.horizontalCenter: parent.horizontalCenter

                visible: searching
                enabled: visible
                
                focus: true

                iconSize: plasmoid.configuration.searchIconSize
                shrinkIconsToNative: plasmoid.configuration.adaptiveSearchIconSize

                DebugRect {}

                model: runnerModel
            }
        }

        Component {
            id: appsGridViewComponent
            AppsGridView {
                id: appsGridView

                visible: !searching && appsModel.count > 0
                enabled: visible
                focus: true

                iconSize: plasmoid.configuration.appIconSize
                numberColumns: Math.min(plasmoid.configuration.maxNumberColumns, Math.floor((rootContentArea.width - Kirigami.Units.largeSpacing * 2) / cellSizeWidth))

                model: appsModel

                DebugRect {}
            }
        }

        // Switch between apps grid or runner results based on whether searching or not
        Loader {
            id: content
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
                topMargin: contentMargin
                bottomMargin: contentMargin
                // margins: contentMargin
            }
            sourceComponent: !searching ? appsGridViewComponent : runnerResultsViewComponent
            active: root.visible
            activeFocusOnTab: true

            Keys.onUpPressed: function (event) {
                nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
            }
            Keys.onDownPressed: function (event) {
                nextItemInFocusChain(true).forceActiveFocus(Qt.FocusReason);
            }
        }

        ParallelAnimation {
            id: contentOpenAnimation

            readonly property int duration: plasmoid.configuration.disableAnimations ? 0
                : Kirigami.Units.longDuration * 1.5 / plasmoid.configuration.animationSpeedMultiplier

            NumberAnimation {
                target: content
                property: "scale"
                from: 1.2
                to: 1
                duration: contentOpenAnimation.duration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: content
                property: "opacity"
                from: 0
                to: 1
                duration: contentOpenAnimation.duration
                easing.type: Easing.OutCubic
            }

            onStopped: {
                content.scale = 1;
                content.opacity = 1;
            }
        }

        ItemGridView {
            id: systemActionsGrid
            
            model: systemFavoritesModel

            visible: count > 0 && plasmoid.configuration.showSystemActions
            enabled: visible
            activeFocusOnTab: true

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                margins: Kirigami.Units.largeSpacing
                bottomMargin: (contentMargin / 2) - (height / 2)
            }

            iconSize: plasmoid.configuration.systemActionIconSize
            cellWidth: iconSize + (Kirigami.Units.largeSpacing * (showLabels ? 6 : 2))
            cellHeight: cellWidth
            // height: cellHeight
            // width: cellWidth * count
            numberColumns: model.count
            // maxVisibleRows: 1
            
            opacity: 0.9

            dragEnabled: true
            showLabels: plasmoid.configuration.showSystemActionLabels
            setIconColorBasedOnTheme: true
            forceSymbolicIcons: plasmoid.configuration.useSymbolicSystemActionIcons

            Keys.onUpPressed: function (event) {
                nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
            }
            Keys.onDownPressed: function (event) {
                nextItemInFocusChain(true).forceActiveFocus(Qt.FocusReason);
            }

            DebugRect {}
        }

        Keys.forwardTo: [content.item, searchField]
        Keys.onPressed: function (event) {
            if (event.key == Qt.Key_Escape) {
                if (searchField.focus || content.focus || systemActionsGrid.focus) {
                    reset();
                } else {
                    root.leave();
                }
                event.accepted = true;
            }
        }
    }

    Component.onCompleted: {
        kicker.reset.connect(reset);
    }
}
