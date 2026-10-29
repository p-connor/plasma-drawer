import QtQuick
import QtQuick.Window

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

// PlasmaCore Dialog with some tweaks to make it full-screen over panels.
// See https://invent.kde.org/plasma/libplasma/-/blob/master/src/plasmaquick/dialog.cpp
PlasmaCore.Dialog {
    id: root

    // Whether to enable opening animations
    property bool animated: true
    // Whether to remove the default theme background (does not remove blur)
    property bool removeBackground: false
    // Toggles window visibility
    function toggle() {
        visible = !visible;
    }

    hideOnWindowDeactivate: true
    // Ensure we stack above panels
    type: PlasmaCore.Dialog.Dock

    readonly property var screenInfo: visualParent ? visualParent.Screen : Screen
    readonly property rect screenRect: Qt.rect(screenInfo.virtualX, screenInfo.virtualY, screenInfo.width, screenInfo.height)
    
    // -- POSITION AND SIZE --

    // Dialog places itself like a popup and clamps to the available (dock-excluded) area, which
    // misplaces a window that covers the dock. So we force the window back to the screen origin
    // whenever Dialog moves it.
    function applyPosition() {
        // Moving the window makes Dialog resize mainItem to the window's current size, so only
        // do it once the window has reached full size; doing it earlier collapses mainItem.
        if (visible && width >= screenRect.width && height >= screenRect.height) {
            if (x !== screenRect.x) {
                x = screenRect.x;
            }
            if (y !== screenRect.y) {
                y = screenRect.y;
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

    onMainItemChanged: {
        if (mainItem) {
            mainItem.width = Qt.binding(() => screenRect.width);
            mainItem.height = Qt.binding(() => screenRect.height);
            mainItem.transform = [mainItemOffset];
        }
    }

    // Dialog offsets mainItem by its theme-set frame margins by overriding x/y.
    readonly property Translate mainItemOffset: Translate {
        x: -root.margins.left
        y: -root.margins.top
    }


    // -- ANIMATION --

    readonly property bool onPanelEdge: plasmoid.location === PlasmaCore.Types.TopEdge
        || plasmoid.location === PlasmaCore.Types.BottomEdge
        || plasmoid.location === PlasmaCore.Types.LeftEdge
        || plasmoid.location === PlasmaCore.Types.RightEdge

    location: !animated ? PlasmaCore.Types.Desktop
        : onPanelEdge ? plasmoid.location : PlasmaCore.Types.BottomEdge


    // -- BACKGROUND --

    // NoBackground removes blur as well, so we use StandardBackground and remove
    // the frame background in updateBackgroundVisibility
    backgroundHints: PlasmaCore.Dialog.StandardBackground

    function updateBackgroundVisibility() {
        // Dialog's frame background is a sibling of mainItem under the window's contentItem
        for (const child of contentItem.children) {
            if (child !== mainItem) {
                child.visible = !removeBackground;
            }
        }
    }
    onRemoveBackgroundChanged: updateBackgroundVisibility()
    Component.onCompleted: updateBackgroundVisibility()
}
