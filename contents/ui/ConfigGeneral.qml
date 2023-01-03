/***************************************************************************
 *   Copyright (C) 2014 by Eike Hein <hein@kde.org>                        *
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
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.14

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.draganddrop 2.0 as DragDrop

Kirigami.FormLayout {
    id: configGeneral

    property string cfg_icon:                   plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage:     plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage:      plasmoid.configuration.customButtonImage
    
    property int cfg_iconSize:                  plasmoid.configuration.iconSize
    
    property alias cfg_backgroundOpacity:       backgroundOpacity.value
    
    property alias cfg_numberColumns:           numberColumns.value
    
    property alias cfg_showSystemActions:       showSystemActions.checked
    property alias cfg_systemActionIconSize:    systemActionIconSize.value
    property var cfg_favoriteSystemActions:     plasmoid.configuration.favoriteSystemActions

    
    // ----------------- Icon -----------------
    Button {
        id: iconButton

        Kirigami.FormData.label: i18n("Icon:")

        implicitWidth: previewFrame.width + units.smallSpacing * 2
        implicitHeight: previewFrame.height + units.smallSpacing * 2

        // Just to provide some visual feedback when dragging;
        // cannot have checked without checkable enabled
        checkable: true
        checked: dropArea.containsAcceptableDrag

        onPressed: iconMenu.opened ? iconMenu.close() : iconMenu.open()

        DragDrop.DropArea {
            id: dropArea

            property bool containsAcceptableDrag: false

            anchors.fill: parent

            onDragEnter: {
                // Cannot use string operations (e.g. indexOf()) on "url" basic type.
                var urlString = event.mimeData.url.toString();

                // This list is also hardcoded in KIconDialog.
                var extensions = [".png", ".xpm", ".svg", ".svgz"];
                containsAcceptableDrag = urlString.indexOf("file:///") === 0 && extensions.some(function (extension) {
                    return urlString.indexOf(extension) === urlString.length - extension.length; // "endsWith"
                });

                if (!containsAcceptableDrag) {
                    event.ignore();
                }
            }
            onDragLeave: containsAcceptableDrag = false

            onDrop: {
                if (containsAcceptableDrag) {
                    // Strip file:// prefix, we already verified in onDragEnter that we have only local URLs.
                    iconDialog.setCustomButtonImage(event.mimeData.url.toString().substr("file://".length));
                }
                containsAcceptableDrag = false;
            }
        }

        KQuickAddons.IconDialog {
            id: iconDialog

            function setCustomButtonImage(image) {
                cfg_customButtonImage = image || cfg_icon || "start-here-kde"
                cfg_useCustomButtonImage = true;
            }

            onIconNameChanged: setCustomButtonImage(iconName);
        }

        PlasmaCore.FrameSvgItem {
            id: previewFrame
            anchors.centerIn: parent
            imagePath: plasmoid.location === PlasmaCore.Types.Vertical || plasmoid.location === PlasmaCore.Types.Horizontal
                    ? "widgets/panel-background" : "widgets/background"
            width: units.iconSizes.large + fixedMargins.left + fixedMargins.right
            height: units.iconSizes.large + fixedMargins.top + fixedMargins.bottom

            PlasmaCore.IconItem {
                anchors.centerIn: parent
                width: units.iconSizes.large
                height: width
                source: cfg_useCustomButtonImage ? cfg_customButtonImage : cfg_icon
            }
        }

        Menu {
            id: iconMenu

            // Appear below the button
            y: +parent.height

            onClosed: iconButton.checked = false;

            MenuItem {
                text: i18nc("@item:inmenu Open icon chooser dialog", "Choose…")
                icon.name: "document-open-folder"
                onClicked: iconDialog.open()
            }
            MenuItem {
                text: i18nc("@item:inmenu Reset icon to default", "Clear Icon")
                icon.name: "edit-clear"
                onClicked: {
                    cfg_icon = "start-here-kde"
                    cfg_useCustomButtonImage = false
                }
            }
        }
    }


    // ----------------- Appearance -----------------
    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.FormData.label: i18n("Appearance:")
        
        Label {
            text: i18n("Size of application icons:")
        }
        ComboBox {
            id: iconSize
            textRole: "text"
            valueRole: "value"
            model: [ 
                {text: i18n("Medium"), value: "medium"}, 
                {text: i18n("Large"), value: "large"}, 
                {text: i18n("Huge"), value: "huge"}, 
                {text: i18n("Enormous"), value: "enormous"} 
            ]
            onActivated: {
                cfg_iconSize = units.iconSizes[currentValue];
            }
            Component.onCompleted: {
                console.log(model);
                currentIndex = model.findIndex((size) => units.iconSizes[size.value] == cfg_iconSize);
            }
        }
    }

    
    RowLayout {
        Layout.fillWidth: true
        
        Label {
            text: i18n("Number of columns:")
        }
        SpinBox{
            id: numberColumns
            from: 3
            to: 20
        }
    }
    
    RowLayout {
        Layout.fillWidth: true
        Label {
            text: i18n("Background opacity:")
        }
        Slider{
            id: backgroundOpacity
            from: 0
            to: 100
            stepSize: 5
            implicitWidth: 200
        }
        Label {
            text: i18n(backgroundOpacity.value + "%");
        }
    }

    
    // ----------------- System Actions -----------------
    Item {
        Kirigami.FormData.isSection: true
    }
    CheckBox {
        Kirigami.FormData.label: i18n("System Actions:")

        id: showSystemActions
        text:  i18n("Show system actions")

        onToggled: {
            if (plasmoid.configuration.favoriteSystemActions.length == 0) {
                cfg_favoriteSystemActions = !checked
                                            ? plasmoid.configuration.favoriteSystemActions 
                                            : ["shutdown", "reboot", "logout", "hibernate", "suspend", "save-session", "lock-screen", "switch-user"];
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        enabled: showSystemActions.checked
        Label {
            text: i18n("Size of system actions icons:")
        }
        SpinBox{
            id: systemActionIconSize
            from: 24
            to: 128
            stepSize: 4
        }
    }

    // RowLayout {
    //     Layout.fillWidth: true
    //     enabled: showSystemActions.checked
    //     Button {
    //         enabled: showSystemActions.checked
    //         text: i18n("Unhide all system actions")
    //         onClicked: {
    //             cfg_favoriteSystemActions = ["shutdown", "reboot", "logout", "suspend", "lock-screen", "switch-user"];
    //         }
    //     }
    // }

    
    // ----------------- Other -----------------
    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.FormData.label: i18n("Other:")

        Button {
            text: i18n("Unhide all hidden applications")
            onClicked: {
                plasmoid.configuration.hiddenApplications = [""];
                unhideAllAppsPopup.text = i18n("Unhidden!");
            }
        }
        Label {
            id: unhideAllAppsPopup
        }
    }
}
