import QtQuick
import QtQuick.Window

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

// PlasmaCore Dialog with some tweaks to make it cover the screen 
// See https://invent.kde.org/plasma/libplasma/-/blob/master/src/plasmaquick/dialog.cpp
PlasmaCore.Dialog {
    id: dialog

    // How much of the screen content covers.     
    enum WindowMode {
        // Background and content cover full screen over panels
        Fullscreen,
        // Background covers full screen, content covers non-panel area. Panels shown
        Maximized
    }
    property int windowMode: FullScreenDialog.WindowMode.Fullscreen
    
    // The content item, sized by the dialog
    required property Item content

    // Optional background item, sized by the dialog. If unset, the default theme
    // background is kept.
    property Item background

    // Whether to enable opening animations
    property bool animated: true
    
    // Toggles window visibility
    function toggle() {
        visible = !visible;
    }

    // Fired on mouse pressed event on the background element
    signal backgroundReleased(var mouse)

    hideOnWindowDeactivate: true
    // Ensure we stack above panels in Fullscreen mode
    type: windowMode === FullScreenDialog.WindowMode.Fullscreen ? PlasmaCore.Dialog.Dock : PlasmaCore.Dialog.Normal

    readonly property var _screenInfo: visualParent ? visualParent.Screen : Screen
    readonly property rect _screenRect: Qt.rect(_screenInfo.virtualX, _screenInfo.virtualY, _screenInfo.width, _screenInfo.height)
    readonly property rect _contentRect: (windowMode === FullScreenDialog.WindowMode.Maximized 
        && plasmoid.containment.availableScreenRect.width > 0 
        && plasmoid.containment.availableScreenRect.height > 0)
            ? plasmoid.containment.availableScreenRect 
            : Qt.rect(0, 0, _screenRect.width, _screenRect.height)

    
    // -- POSITION AND SIZE --

    // Dialog places itself like a popup and clamps to the available (dock-excluded) area, which
    // misplaces a window that covers the dock. So we force the window back to the screen origin
    // whenever Dialog moves it.
    function applyPosition() {
        // Moving the window makes Dialog resize mainItem to the window's current size, so only
        // do it once the window has reached full size; doing it earlier collapses mainItem.
        if (visible && width >= _screenRect.width && height >= _screenRect.height) {
            if (x !== _screenRect.x) {
                x = _screenRect.x;
            }
            if (y !== _screenRect.y) {
                y = _screenRect.y;
            }
        }
    }
    onXChanged: applyPosition()
    onYChanged: applyPosition()
    onVisibleChanged: {
        if (visible) {
            applyPosition();
        }
    }

    // Dialog sizes the window from mainItem and offsets it by its theme-set frame margins (by overriding x/y).
    // So mainItem covers the whole screen, shifted back by the margins, and holds our background and content.
    mainItem: Item {
        width: dialog._screenRect.width
        height: dialog._screenRect.height
        transform: Translate {
            x: -dialog.margins.left
            y: -dialog.margins.top
        }

        Item {
            id: backgroundContainer
            anchors.fill: parent

            MouseArea {
                id: backgroundMouseArea
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent

                onReleased: function (mouse) {
                    dialog.backgroundReleased(mouse);
                }
            }
        }

        Item {
            id: contentContainer
            x: dialog._contentRect.x
            y: dialog._contentRect.y
            width: dialog._contentRect.width
            height: dialog._contentRect.height
        }
    }

    onBackgroundChanged: {
        if (background) {
            background.parent = backgroundContainer;
            background.anchors.fill = backgroundContainer;
        }
        updateBackgroundVisibility();
    }
    onContentChanged: {
        if (content) {
            content.parent = contentContainer;
            content.anchors.fill = contentContainer;
        }
    }


    // -- ANIMATION --

    readonly property bool _onPanelEdge: plasmoid.location === PlasmaCore.Types.TopEdge
        || plasmoid.location === PlasmaCore.Types.BottomEdge
        || plasmoid.location === PlasmaCore.Types.LeftEdge
        || plasmoid.location === PlasmaCore.Types.RightEdge

    location: !animated ? PlasmaCore.Types.Desktop
        : _onPanelEdge ? plasmoid.location : PlasmaCore.Types.BottomEdge


    // -- BACKGROUND --

    // NoBackground removes blur as well, so we use StandardBackground and remove
    // the frame background in updateBackgroundVisibility
    backgroundHints: PlasmaCore.Dialog.StandardBackground

    function updateBackgroundVisibility() {
        // Dialog's frame background is a sibling of mainItem under the window's contentItem
        for (const child of dialog.contentItem.children) {
            if (child !== mainItem) {
                child.visible = !background;
            }
        }
    }
    Component.onCompleted: updateBackgroundVisibility()
}
