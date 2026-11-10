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

import Qt5Compat.GraphicalEffects

import QtQuick
import QtQuick.Controls
import QtQuick.Window

import "../code/tools.js" as Tools
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras

import org.kde.plasma.plasmoid

AdaptiveDialog {
    id: root

    readonly property bool searching: searchField.text != ""

    function colorWithAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }
    function leave() {
        if (!searching && content.currentItem.tryExitDirectory && !content.currentItem.isAtRoot) {
            content.currentItem.tryExitDirectory();
        } else {
            root.toggle();
        }
    }
    function reset() {
        searchField.text = "";
        appsGridView.returnToRootDirectory(false);
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

    animated: !plasmoid.configuration.disableAnimations
    windowMode: plasmoid.configuration.windowMode

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
    content: FocusScope {
        id: rootContentArea

        // Use screenInfo instead of rootContentArea.height to avoid binding loop
        readonly property int contentMargin: Math.max(systemActionsGrid.visible ? systemActionsGrid.implicitHeight : 0, searchField.visible ? searchField.implicitHeight * 2 : 0, root.windowMode !== AdaptiveDialog.WindowMode.Floating ? Kirigami.Units.iconSizes.huge : 0, root.windowMode !== AdaptiveDialog.WindowMode.Floating ? root.screenInfo.height * .12 : 0) + Kirigami.Units.gridUnit
        readonly property int maxSearchWidth: Kirigami.Units.gridUnit * 32
        readonly property int searchWidth: content.width > maxSearchWidth ? Math.min(content.width * 0.75, maxSearchWidth) : content.width

        focus: true
        LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
        LayoutMirroring.childrenInherit: true
        implicitWidth: content.implicitWidth
        implicitHeight: content.implicitHeight + (contentMargin * 2)
        Keys.forwardTo: [content.currentItem, searchField]

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

        SearchBar {
            id: searchField

            visible: plasmoid.configuration.showSearch
            enabled: visible
            activeFocusOnTab: true
            anchors.top: parent.top
            anchors.topMargin: (rootContentArea.contentMargin / 2) - (height / 2)
            anchors.horizontalCenter: parent.horizontalCenter
            width: rootContentArea.searchWidth + (leftInset * 2) - Kirigami.Units.gridUnit * (rootContentArea.implicitWidth > rootContentArea.maxSearchWidth ? 6 : 2)

            onTextChanged: {
                runnerModel.query = text;
            }
            Keys.onPressed: function (event) {
                // TODO: replace with key forwarding to content Keys.forwardTo
                if (searching && (event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
                    event.accepted = true;
                    // Pass focus to content who should handle onReleased
                    content.currentItem.forceActiveFocus();
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

        // Switch between apps grid or runner results based on whether searching or not
        StackView {
            id: content

            implicitWidth: appsGridView.implicitWidth
            implicitHeight: appsGridView.implicitHeight
            focus: true
            activeFocusOnTab: true
            replaceEnter: null
            replaceExit: null

            initialItem: AppsGridView {
                id: appsGridView

                visible: !searching && appsModel.count > 0
                enabled: visible
                focus: true
                iconSize: plasmoid.configuration.appIconSize
                numberColumns: plasmoid.configuration.maxNumberColumns
                model: appsModel

                Binding on numberRows {
                    value: plasmoid.configuration.maxNumberRows
                    when: root.windowMode === AdaptiveDialog.WindowMode.Floating
                }

                DebugRect {}
            }

            Keys.onUpPressed: function (event) {
                nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
            }
            Keys.onDownPressed: function (event) {
                nextItemInFocusChain(true).forceActiveFocus(Qt.FocusReason);
            }

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                bottom: parent.bottom
                topMargin: rootContentArea.contentMargin
                bottomMargin: rootContentArea.contentMargin
                // margins: rootContentArea.contentMargin
            }
            Component {
                id: runnerResultsViewComponent

                RunnerResultsView {
                    id: runnerResultsView

                    width: rootContentArea.searchWidth
                    visible: searching
                    enabled: visible
                    focus: true
                    iconSize: plasmoid.configuration.searchIconSize
                    shrinkIconsToNative: plasmoid.configuration.adaptiveSearchIconSize
                    model: runnerModel

                    anchors {
                        top: content.top
                        bottom: content.bottom
                        horizontalCenter: content.horizontalCenter
                    }
                    DebugRect {}
                }
            }
            Connections {
                function onSearchingChanged() {
                    if (searching) {
                        content.replace(runnerResultsViewComponent);
                    } else {
                        content.replace(appsGridView);
                    }
                }

                target: root
            }
        }
        ParallelAnimation {
            id: contentOpenAnimation

            readonly property int duration: plasmoid.configuration.disableAnimations ? 0 : Kirigami.Units.longDuration * 1.5 / plasmoid.configuration.animationSpeedMultiplier

            onStarted: {
                content.layer.enabled = true;
            }
            onStopped: {
                content.layer.enabled = false;
                content.scale = 1;
                content.opacity = 1;
            }

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
        }
        ItemGridView {
            id: systemActionsGrid

            model: systemFavoritesModel
            visible: count > 0 && plasmoid.configuration.showSystemActions
            enabled: visible
            activeFocusOnTab: true
            iconSize: plasmoid.configuration.systemActionIconSize
            cellContentSpacing: Kirigami.Units.smallSpacing
            numberRows: 1
            numberColumns: model.count
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

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                margins: Kirigami.Units.largeSpacing
                bottomMargin: (rootContentArea.contentMargin / 2) - (height / 2)
            }
            DebugRect {}
        }
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
    Component.onCompleted: {
        kicker.reset.connect(reset);
    }
}
