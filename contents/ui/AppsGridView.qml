import QtQuick 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

FocusScope {
    id: appsGrid


    property int iconSize: units.iconSizes.huge
    
    // TODO - polish cell sizes for different resolutions
    property int cellSizeWidth: (iconSize * 1.5) + theme.mSize(theme.defaultFont).height
                                + (2 * units.smallSpacing)
                                + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    property int cellSizeHeight: cellSizeWidth - (iconSize * .25)

    property int numberColumns:  5
    property int numberRows:  Math.floor(height / cellSizeHeight)
    
    implicitWidth: numberColumns * cellSizeWidth
    implicitHeight: cellSizeHeight * 3

    required property var model

    property var modelStack: [model]
    readonly property int modelStackLength: modelStack.length
    readonly property var currentModel: modelStack[modelStackLength - 1]

    readonly property bool isAtRoot: modelStackLength <= 1

    function tryEnterDirectory(directoryIndex) {
        let dir = currentModel.modelForRow(directoryIndex);
        if (dir && dir.hasChildren) {
            itemGridView.setupEnterTransitionAnimation();
            // Note: need to reassign array to cause 'changed' signal
            modelStack = [...modelStack, dir];
        }
    }

    function tryExitDirectory() {
        if (!isAtRoot) {
            itemGridView.setupEnterTransitionAnimation(true);
            modelStack = modelStack.slice(0, -1);
        }
    }

    function returnToRootDirectory() {
        if (!isAtRoot) {
            modelStack = [model];
        }
    }

    ActionMenu {
        id: actionMenu
        onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
        onClosed: {
            itemGrid.currentIndex = -1;
        }
    }

    ItemGridView {
        id: itemGridView

        width: numberColumns * cellSizeWidth
        height: numberRows * cellSizeHeight
        anchors.centerIn: parent

        cellWidth:  cellSizeWidth
        cellHeight: cellSizeHeight

        iconSize: appsGrid.iconSize

        focus: true

        model: currentModel
        
        dragEnabled: false
        hoverEnabled: true

        onKeyNavUp: {
            currentIndex = -1;
            searchField.focus = true;
        }
        onKeyNavDown: {
            if (systemActionsGrid.visible) {
                systemActionsGrid.focus = true;
                systemActionsGrid.tryActivate(0, 0);
            }
        }
    }
}