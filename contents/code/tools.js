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


function createDirectoryActions(i18n) {
    var action = {};    
    action.text = i18n("Empty folder here");
    action.icon = "edit-reset";
    action.actionId = "_kicker_directory_empty";
    // action.actionArgument = { favoriteModel: favoriteModel, favoriteId: favoriteId };
    return [action];
}

function triggerAction(plasmoid, model, index, actionId, actionArgument) {
    var closeRequested = model.trigger(index, actionId, actionArgument);

    if (closeRequested) {
        plasmoid.expanded = false;

        return true;
    }

    return false;
}
