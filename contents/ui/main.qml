/***************************************************************************
 *   Copyright (C) 2014-2015 by Eike Hein <hein@kde.org>                   *
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
import QtQuick.Layouts
import org.kde.plasma.plasmoid

import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg as KSvg

import org.kde.plasma.private.kicker as Kicker

PlasmoidItem {
    id: kicker

    // onActiveFocusItemChanged: {
    //     console.log("activeFocusItem", activeFocusItem);
    // }

    anchors.fill: parent

    signal reset

    preferredRepresentation: fullRepresentation

    compactRepresentation: null
    fullRepresentation: compactRepresentation

    property Item dragSource: null

    property alias systemFavoritesModel: systemModel.favoritesModel

    function logModelChildren(model, leadingSpace = 0) {
        let spacing = Array(leadingSpace + 1).join(" ");
        // console.log(model.description);
        // console.log(model.data(model.index(0, 0), 0));
        
        var count = ("count" in model ? model.count : 1);

        for (let i = 0; i < count; i++) {
            let hasChildren = model.data(model.index(i, 0), 0x0107);
            
            console.log(spacing + `${model.data(model.index(i, 0), 0)} - `
                            // + hasChildren ? `(${model.modelForRow(i).count}) - ` : ' - '
                            + `${model.data(model.index(i, 0), 0x0101)}, `
                            + `Deco: ${model.data(model.index(0, 0), 1)}, `
                            + `IsParent: ${model.data(model.index(i, 0), 0x0106)}, `
                            + `HasChildren: ${hasChildren}, `
                            + `Group: ${model.data(model.index(i, 0), 0x0102)}`
                        );
            
            if (hasChildren || count > 1) {
                logModelChildren(model.modelForRow(i), leadingSpace + 2);
                continue;
            }
        }
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    Component {
        id: menuRepresentation
        MenuRepresentation {}
    }

    Connections {
        target: systemFavoritesModel

        function onCountChanged() {
            if (systemFavoritesModel.count == 0) {
                plasmoid.configuration.showSystemActions = false;
            }
        }

        function onFavoritesChanged() {
            if (target.count > 0 && target.favorites.toString() != plasmoid.configuration.favoriteSystemActions.toString()) {
                plasmoid.configuration.favoriteSystemActions = target.favorites;
            }
        }
    }

    readonly property DrawerTheme drawerTheme: DrawerTheme {}

    readonly property Kicker.AppsModel appsModel: Kicker.AppsModel {
        autoPopulate: true

        flat: false
        showTopLevelItems: true
        sorted: false
        showSeparators: false
        paginate: false

        appletInterface: kicker
        appNameFormat: plasmoid.configuration.appNameFormat

        Component.onCompleted: {
            appsModel.refresh();
        }
    }

    Kicker.SystemModel {
        id: systemModel

        Component.onCompleted: {
            systemFavoritesModel.enabled = true;
            systemFavoritesModel.maxFavorites = 8;

            // Favorites set on MenuRepresentation visible instead to ensure that system actions are
            // available at set time
            // systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
        }
    }

    Kicker.RunnerModel {
        id: runnerModel

        appletInterface: kicker
        
        runners: [  "krunner_services",
                    "krunner_systemsettings",
                    "krunner_sessions",
                    "krunner_powerdevil",
                    "calculator",
                    "unitconverter" ]   // TODO: Make this configurable, or set to KRunner's configured runners
        // mergeResults: true
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    KSvg.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    KSvg.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    function resetDragSource() {
        dragSource = null;
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Edit Applications...")
            icon.name: "kmenuedit"
            onTriggered: processRunner.runMenuEditor()
        }
    ]
}
