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

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import org.kde.plasma.private.kicker 0.1 as Kicker

Item {
    id: kicker

    anchors.fill: parent

    signal reset

    property bool isDash: false

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    Plasmoid.compactRepresentation: null
    Plasmoid.fullRepresentation: compactRepresentation

    property Item dragSource: null

    property QtObject globalFavorites: rootModel.favoritesModel
    property QtObject systemFavorites: rootModel.systemFavoritesModel

    function logModelChildren(modelId, leadingSpace=0) {
        let spacing = Array(leadingSpace + 1).join(" ");
        // console.log(modelId.description);
        // console.log(modelId.data(modelId.index(0, 0), 0));
        
        for (let i = 0; i < modelId.count; i++) {
            let hasChildren = modelId.data(modelId.index(i, 0), 0x0107);
            
            console.log(spacing + `${modelId.data(modelId.index(i, 0), 0)} - `
                            // + hasChildren ? `(${modelId.modelForRow(i).count}) - ` : ' - '
                            + `${modelId.data(modelId.index(i, 0), 0x0101)}, `
                            // + `Deco: ${modelId.data(modelId.index(0, 0), 1)}, `
                            // + `IsParent: ${modelId.data(modelId.index(i, 0), 0x0106)}, `
                            // + `HasChildren: ${hasChildren}, `
                            // + `Group: ${modelId.data(modelId.index(i, 0), 0x0102)}`
                        );
            
            if (hasChildren) {
                logModelChildren(modelId.modelForRow(i), leadingSpace + 2);
                continue;
            }
        }
    }

    function action_menuedit() {
        processRunner.runMenuEditor();
    }

    Component {
        id: compactRepresentation
        CompactRepresentation {}
    }

    Component {
        id: menuRepresentation
        MenuRepresentation {}
    }

    Kicker.RootModel {
        id: rootModel

        autoPopulate: false

        appNameFormat: plasmoid.configuration.appNameFormat
        flat: true
        sorted: true
        showSeparators: false
        appletInterface: plasmoid

        paginate: false
        showAllApps: false
        showRecentApps: false
        showRecentDocs: false
        showRecentContacts: false
        showPowerSession: false

        onFavoritesModelChanged: {
            if ("initForClient" in favoritesModel) {
                favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + plasmoid.id)

                if (!plasmoid.configuration.favoritesPortedToKAstats) {
                    favoritesModel.portOldFavorites(plasmoid.configuration.favoriteApps);
                    plasmoid.configuration.favoritesPortedToKAstats = true;
                }
            } else {
                favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            }

            favoritesModel.maxFavorites = pageSize;
        }

        onSystemFavoritesModelChanged: {
           systemFavoritesModel.enabled = true;
           systemFavoritesModel.favorites = plasmoid.configuration.favoriteSystemActions;
           systemFavoritesModel.maxFavorites = 8;
        }

        Component.onCompleted: {
            if ("initForClient" in favoritesModel) {
               favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + plasmoid.id)
               if (!plasmoid.configuration.favoritesPortedToKAstats) {
                   favoritesModel.portOldFavorites(plasmoid.configuration.favoriteApps);
                   plasmoid.configuration.favoritesPortedToKAstats = true;
               }
            } else {
               favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            }
            favoritesModel.maxFavorites = pageSize;
            rootModel.refresh();
        }
    }

    Connections {
        target: globalFavorites

        function onFavoritesChanged() {
           plasmoid.configuration.favoriteApps = target.favorites;
        }
    }

    Connections {
        target: systemFavorites

        function onFavoritesChanged() {
           plasmoid.configuration.favoriteSystemActions = target.favorites;
        }
    }

    Connections {
        target: plasmoid.configuration

        function onFavoriteAppsChanged() {
            globalFavorites.favorites = plasmoid.configuration.favoriteApps;
        }

        function onFavoriteSystemActionsChanged() {
            systemFavorites.favorites = plasmoid.configuration.favoriteSystemActions;
        }

        function onHiddenApplicationsChanged() {
            // Force refresh on hidden
            rootModel.refresh();
        }
    }

    Kicker.RunnerModel {
        id: runnerModel
        favoritesModel: globalFavorites
        runners: plasmoid.configuration.useExtraRunners ? new Array("services").concat(plasmoid.configuration.extraRunners) : "services"
        appletInterface: plasmoid
        deleteWhenEmpty: false
    }

    Kicker.DragHelper {
        id: dragHelper
    }

    Kicker.ProcessRunner {
        id: processRunner;
    }

    PlasmaCore.FrameSvgItem {
        id : highlightItemSvg

        visible: false

        imagePath: "widgets/viewitem"
        prefix: "hover"
    }

    PlasmaCore.FrameSvgItem {
        id : panelSvg

        visible: false

        imagePath: "widgets/panel-background"
    }

    PlasmaComponents.Label {
        id: toolTipDelegate

        width: contentWidth
        height: contentHeight

        property Item toolTip

        text: (toolTip != null) ? toolTip.text : ""
    }

    function resetDragSource() {
        dragSource = null;
    }

    Kicker.AppsModel {
        id: appsModel

        autoPopulate: true

        flat: false
        showTopLevelItems: true
        sorted: false
        showSeparators: false
        paginate: false

        appletInterface: plasmoid
        appNameFormat: plasmoid.configuration.appNameFormat

        onFavoritesModelChanged: {
            if ("initForClient" in favoritesModel) {
                favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + plasmoid.id)

                if (!plasmoid.configuration.favoritesPortedToKAstats) {
                    favoritesModel.portOldFavorites(plasmoid.configuration.favoriteApps);
                    plasmoid.configuration.favoritesPortedToKAstats = true;
                }
            } else {
                favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            }

            favoritesModel.maxFavorites = pageSize;
        }

        Component.onCompleted: {
            if ("initForClient" in favoritesModel) {
               favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + plasmoid.id)
               if (!plasmoid.configuration.favoritesPortedToKAstats) {
                   favoritesModel.portOldFavorites(plasmoid.configuration.favoriteApps);
                   plasmoid.configuration.favoritesPortedToKAstats = true;
               }
            } else {
               favoritesModel.favorites = plasmoid.configuration.favoriteApps;
            }
            favoritesModel.maxFavorites = pageSize;
            appsModel.refresh();
        }
    }

    Component.onCompleted: {
        plasmoid.setAction("menuedit", i18n("Edit Applications..."));
        rootModel.refreshed.connect(reset);
        dragHelper.dropped.connect(resetDragSource);
    }
}
