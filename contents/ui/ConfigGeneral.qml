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
import QtQuick.Dialogs 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kirigami 2.5 as Kirigami
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.kquickcontrolsaddons 2.0 as KQuickAddons
import org.kde.draganddrop 2.0 as DragDrop

Kirigami.FormLayout {
    id: configGeneral

    property string cfg_icon:                       plasmoid.configuration.icon
    property bool cfg_useCustomButtonImage:         plasmoid.configuration.useCustomButtonImage
    property string cfg_customButtonImage:          plasmoid.configuration.customButtonImage

    property alias cfg_backgroundType:              backgroundType.currentIndex
    property var cfg_customBackgroundColor:         plasmoid.configuration.customBackgroundColor
    property var cfg_customBackgroundImagePath:     plasmoid.configuration.customBackgroundImagePath
    property alias cfg_backgroundOpacity:           backgroundOpacity.value

    property int cfg_appIconSize:                   plasmoid.configuration.appIconSize
    property alias cfg_useDirectoryIcons:           useDirectoryIcons.checked
    property alias cfg_maxNumberColumns:            maxNumberColumns.value

    property alias cfg_showSearch:                  showSearch.checked
    property alias cfg_adaptiveSearchIconSize:      adaptSearchIcons.checked
    property int cfg_searchIconSize:                plasmoid.configuration.searchIconSize  

    property alias cfg_showSystemActions:           showSystemActions.checked
    property alias cfg_showSystemActionLabels:      showSystemActionLabels.checked
    property alias cfg_systemActionsUsePlasmaIcons: systemActionsUsePlasmaIcons.checked
    property int cfg_systemActionIconSize:          plasmoid.configuration.systemActionIconSize
    property var cfg_favoriteSystemActions:         plasmoid.configuration.favoriteSystemActions

    property alias cfg_disableAnimations:           disableAnimations.checked
    property alias cfg_animationSpeedMultiplier:    animationSpeedMultiplier.value


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

    // ----------------- Background -----------------
    Item {
        Kirigami.FormData.isSection: true
    }

    ComboBox {
        id: backgroundType
        Kirigami.FormData.label: i18n("Background:")
        
        model: [ 
            i18n("Use theme color"), 
            i18n("Use custom color"), 
            i18n("Use image")
        ]
    }

    RowLayout {
        Layout.fillWidth: true
        visible: backgroundType.currentIndex == 1   // backgroundType in custom color mode
        
        Label {
            text: i18n("Custom Color:")
        }
        KQuickControls.ColorButton {
            id: backgroundColorPicker
            dialogTitle: i18n("Background Color")
            showAlphaChannel: false
            onAccepted: {
                cfg_customBackgroundColor = color
            }
            Component.onCompleted: {
                color = plasmoid.configuration.customBackgroundColor
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: backgroundType.currentIndex == 2   // backgroundType in image mode
        
        Button {
            text: "Select Image File"
            icon.name: "fileopen"
            onClicked: {
                backgroundImageFileDialog.open()
            }
        }
        Label {
            text: i18n("Path: ") + (cfg_customBackgroundImagePath ?? i18n("None"))
        }
    }
    FileDialog {
        id: backgroundImageFileDialog
        title: "Please choose an image file"
        folder: shortcuts.home
        nameFilters: [ "Image files (*.jpg *.jpeg *.png *.bmp)", "All files (*)" ]
        onAccepted: {
            cfg_customBackgroundImagePath = String(fileUrl).replace("file://", "");
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
            text: i18n("%1%", backgroundOpacity.value);
        }
    }

    // ----------------- Application Grid -----------------
    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.FormData.label: i18n("Applications:")
        
        Label {
            text: i18n("Max columns in grid:")
        }
        SpinBox{
            id: maxNumberColumns
            from: 3
            to: 20
        }
    }

    RowLayout {
        Layout.fillWidth: true
        
        Label {
            text: i18n("Size of application icons:")
        }
        ComboBox {
            id: appIconSize
            model: [ 
                i18n(units.iconSizes.medium), 
                i18n(units.iconSizes.large), 
                i18n(units.iconSizes.huge), 
                i18n(units.iconSizes.huge + ((units.iconSizes.enormous - units.iconSizes.huge) / 2)),
                i18n(units.iconSizes.enormous),
                i18n(units.iconSizes.enormous + (units.iconSizes.enormous / 2)),
                i18n(units.iconSizes.enormous * 2)
            ]
            onActivated: {
                cfg_appIconSize = parseInt(currentText);
            }
            Component.onCompleted: {
                currentIndex = model.findIndex((size) => size == cfg_appIconSize);
            }
        }
    }

    CheckBox {        
        id: useDirectoryIcons
        text:  i18n("Use directory icons")
    }

    // ----------------- Search -----------------
    Item {
        Kirigami.FormData.isSection: true
    }

    CheckBox {
        Kirigami.FormData.label: i18n("Search:")

        id: showSearch
        text:  i18n("Show search bar")
    }

    Button {    
        enabled: showSearch.checked && KQuickAddons.KCMShell.authorize("kcm_plasmasearch.desktop").length > 0
        icon.name: "settings-configure"
        text: i18nc("@action:button", "Configure Enabled Search Plugins…")
        onClicked: KQuickAddons.KCMShell.openSystemSettings("kcm_plasmasearch")
    }
    
    CheckBox {        
        id: adaptSearchIcons
        enabled: showSearch.checked
        text:  i18n("Adaptive search result size")
    }
    
    RowLayout {
        Layout.fillWidth: true
        enabled: showSearch.checked
        
        Label {
            text: adaptSearchIcons.checked ? i18n("Max size of search result icons:") : i18n("Size of search result icons:")
        }
        ComboBox {
            id: searchIconSize
            model: [ 
                i18n(units.iconSizes.small),
                i18n(units.iconSizes.smallMedium),
                i18n(units.iconSizes.medium), 
                i18n(units.iconSizes.large), 
                i18n(units.iconSizes.huge), 
                i18n(units.iconSizes.enormous)
            ]
            onActivated: {
                cfg_searchIconSize = parseInt(currentText);
            }
            Component.onCompleted: {
                currentIndex = model.findIndex((size) => size == cfg_searchIconSize);
            }
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
            cfg_favoriteSystemActions = !checked
                                        ? plasmoid.configuration.favoriteSystemActions 
                                        : ["shutdown", "reboot", "logout", "hibernate", "suspend", "save-session", "lock-screen", "switch-user"];
        }
    }
    RowLayout {
        Layout.fillWidth: true
        enabled: showSystemActions.checked
        Label {
            text: i18n("Size of system action icons:")
        }
        ComboBox {
            id: systemActionIconSize
            model: [ 
                i18n(units.iconSizes.medium), 
                i18n(units.iconSizes.large), 
                i18n(units.iconSizes.huge), 
                i18n(units.iconSizes.huge + ((units.iconSizes.enormous - units.iconSizes.huge) / 2))
            ]
            onActivated: {
                cfg_systemActionIconSize = parseInt(currentText);
            }
            Component.onCompleted: {
                currentIndex = model.findIndex((size) => size == cfg_systemActionIconSize);
            }
        }
    }
    CheckBox {
        id: showSystemActionLabels
        enabled: showSystemActions.checked
        text:  i18n("Show system action labels")
    }
    CheckBox {
        id: systemActionsUsePlasmaIcons
        enabled: showSystemActions.checked
        text:  i18n("Use plasma icons")
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

    CheckBox {       
        Kirigami.FormData.label: i18n("Other:")

        id: disableAnimations
        text:  i18n("Disable animations")
    }

    RowLayout {
        Layout.fillWidth: true
        enabled: !disableAnimations.checked
        
        Label {
            text: i18n("Animation speed multiplier:")
        }
        Slider{
            id: animationSpeedMultiplier
            from: 0.1
            to: 3.0
            stepSize: 0.1
            implicitWidth: 200
        }
        Label {
            text: (animationSpeedMultiplier.value).toFixed(1);
        }
    }
    
    RowLayout {
        Layout.fillWidth: true

        Button {
            text: i18n("Unhide all hidden applications")
            icon.name: "view-visible"
            onClicked: {
                plasmoid.configuration.hiddenApplications = [""];
                unhideAllAppsPopup.text = i18n("Unhidden!");
                plasmoid.rootItem.appsModel.refresh();
            }
        }
        Label {
            id: unhideAllAppsPopup
        }
    }
}
