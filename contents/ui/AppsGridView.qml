import QtQuick 2.15
import QtQuick.Controls 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

FocusScope {
    id: appsGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

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

    readonly property var currentItemGrid: stackView.currentItem
    readonly property var currentModel: currentItemGrid ? currentItemGrid.model : null //modelStack[modelStackLength - 1]

    readonly property bool isAtRoot: stackView.depth <= 1

    function tryEnterDirectory(directoryIndex) {
        let dir = currentModel.modelForRow(directoryIndex);
        if (dir && dir.hasChildren) {
            // itemGridView.setupEnterTransitionAnimation();
            // // Note: need to reassign array to cause 'changed' signal
            // modelStack = [...modelStack, dir];

            let origin = Qt.point(0, 0);
            if (currentItemGrid && currentItemGrid.currentItem) {
                origin = Qt.point(  (currentItemGrid.currentItem.x + (cellSizeWidth / 2)) - (currentItemGrid.width / 2), 
                                    (currentItemGrid.currentItem.y + (cellSizeHeight / 2)) - (currentItemGrid.height / 2) )
            }
            stackView.push(directoryView, {model: dir, origin: origin});
        }
    }

    function tryExitDirectory() {
        if (!isAtRoot) {
            // itemGridView.setupEnterTransitionAnimation(true);
            // modelStack = modelStack.slice(0, -1);

            stackView.pop();
        }
    }

    function returnToRootDirectory() {
        if (!isAtRoot) {
            // modelStack = [model];

            // Pops all items up until root
            stackView.pop(null);
        }
    }

    ActionMenu {
        id: actionMenu
        onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
        onClosed: {
            currentItemGrid.currentIndex = -1;
        }
    }

    // I believe StackView requires that the component be defined this way
    Component {
        id: directoryView
        ItemGridView {
            property var origin: Qt.point(0, 0)

            showLabels: StackView.status == StackView.Active || StackView.status == StackView.Activating

            width: numberColumns * cellSizeWidth
            height: numberRows * cellSizeHeight
            // anchors.centerIn: stackView

            cellWidth:  cellSizeWidth
            cellHeight: cellSizeHeight

            iconSize: appsGrid.iconSize

            model: appsGrid.model
            
            dragEnabled: false
            hoverEnabled: true

            onKeyNavUp: {
                currentIndex = -1;
                appsGrid.keyNavUp();
            }
            onKeyNavDown: {
                currentIndex = -1;
                appsGrid.keyNavDown();
            }

            Component.onCompleted: {
                keyNavLeft.connect(appsGrid.keyNavLeft);
                keyNavRight.connect(appsGrid.keyNavRight);
            }
        }
    }

    StackView {
        id: stackView
        initialItem: directoryView
        anchors.fill: parent
        focus: true

        property var transitionDuration: units.veryLongDuration

        pushEnter: Transition {
            id: pushEnterTransition

            NumberAnimation { 
                property: "x"; 
                from: pushEnterTransition.ViewTransition.item.origin.x
                to: 0
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "y"
                from: pushEnterTransition.ViewTransition.item.origin.y
                to: 0
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: stackView.transitionDuration * .5 }
            NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
        }

        pushExit: Transition {
            id: pushExitTransition
            YAnimator {
                from: 0
                to: -units.gridUnit * 3
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: .8; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
        }

        popEnter: Transition {
            id: popEnterTransition
           
            YAnimator {
                from: -units.gridUnit * 3
                to: 0
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
        }

        popExit: Transition {
            id: popExitTransition
            NumberAnimation {
                property: "x"
                from: 0
                to: popExitTransition.ViewTransition.item.origin.x
                duration: stackView.transitionDuration * 1.5
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                property: "y"
                from: 0
                to: popExitTransition.ViewTransition.item.origin.y
                duration: stackView.transitionDuration * 1.5
                easing.type: Easing.OutCubic
            }
            
            NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: stackView.transitionDuration * .75; easing.type: Easing.OutQuint }
            NumberAnimation { property: "scale"; from: 1.0; to: 0; duration: stackView.transitionDuration * 1.5; easing.type: Easing.OutCubic }
        }
    }
}