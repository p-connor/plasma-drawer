/***************************************************************************
 *   Copyright (C) 2013 by Aurélien Gâteau <agateau@kde.org>               *
 *   Copyright (C) 2013-2015 by Eike Hein <hein@kde.org>                   *
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

.pragma library

const CUSTOM_ACTION_PREFIX = "_plasmaDrawer";

function createSystemActionActions(i18n, favoriteModel, favoriteId) {
    if (!favoriteId || !favoriteModel) {
        return null;
    }

    var actions;

    if (favoriteModel.isFavorite(favoriteId)) {
        actions = [
            {
                text: i18n("Remove action"),
                icon: "remove",
                actionId: CUSTOM_ACTION_PREFIX + "_favorite_remove"
            },
            {
                text: i18n("Show all"),
                icon: "view-visible",
                actionId: CUSTOM_ACTION_PREFIX + "_favorite_reset"
            }
        ];
    } else if (favoriteModel.maxFavorites === -1 || favoriteModel.count < favoriteModel.maxFavorites) {
        actions = [
            {
                text: i18n("Add to system actions bar"),
                icon: "add",
                actionId: CUSTOM_ACTION_PREFIX + "_favorite_add"
            }
        ];
    } else {
        return null;
    }

    actions.forEach((action) => action.actionArgument = { favoriteModel: favoriteModel, favoriteId: favoriteId });
    return actions;
}

function createMenuEditAction(i18n, processRunner) {
    return [
        {
            text: i18n("Edit Applications"),
            icon: "kmenuedit",
            actionId: CUSTOM_ACTION_PREFIX + "_menuedit",
            actionArgument: { processRunner: processRunner }
        }
    ];
}

function startsWith(txt, needle) {
    return txt.substr(0, needle.length) === needle;
}

function triggerAction(plasmoid, model, index, actionId, actionArgument) {
    
    if (startsWith(actionId, CUSTOM_ACTION_PREFIX)) {
        return handleCustomAction(actionId, actionArgument);
    }
    
    var closeRequested = model.trigger(index, actionId, actionArgument);

    if (closeRequested) {
        plasmoid.expanded = false;

        return true;
    }

    return false;
}

function handleCustomAction(actionId, actionArgument) {
    console.log(`Handling custom action ${actionId}`);
    
    if (actionId === CUSTOM_ACTION_PREFIX + "_menuedit") { 
        console.log("running menu editor from processRunner");
        actionArgument.processRunner.runMenuEditor();
        return true;
    }
    
    if (actionArgument.favoriteId && actionArgument.favoriteModel) {
        var favoriteId = actionArgument.favoriteId;
        var favoriteModel = actionArgument.favoriteModel;

        if (actionId === CUSTOM_ACTION_PREFIX + "_favorite_remove") {
            favoriteModel.removeFavorite(favoriteId);
        } else if (actionId === CUSTOM_ACTION_PREFIX + "_favorite_add") {
            favoriteModel.addFavorite(favoriteId);
        } else if (actionId == CUSTOM_ACTION_PREFIX + "_favorite_reset") {
            favoriteModel.favorites = [ "shutdown", 
                                        "reboot", 
                                        "logout", 
                                        "hibernate", 
                                        "suspend", 
                                        "save-session", 
                                        "lock-screen", 
                                        "switch-user" ];
        }
        return false;
    }
}
