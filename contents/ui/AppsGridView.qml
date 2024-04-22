import QtQuick
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.kquickcontrolsaddons
import org.kde.kirigami as Kirigami

FocusScope {
    id: appsGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    property int iconSize: Kirigami.Units.iconSizes.huge
    
    // TODO - polish cell sizes for different resolutions
    readonly property int cellSizeWidth: (iconSize * 1.5) + Kirigami.Units.gridUnit
                                + (2 * Kirigami.Units.smallSpacing)
                                + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom,
                                                highlightItemSvg.margins.left + highlightItemSvg.margins.right))
    readonly property int minCellSizeHeight: (cellSizeWidth - (iconSize * .33))
    // cellSizeHeight grows to match the appsGrid height if there is some space left at the bottom
    readonly property int cellSizeHeight: minCellSizeHeight + ((height % minCellSizeHeight) / Math.floor(height / minCellSizeHeight))

    property int numberColumns:  5
    property int numberRows:  Math.floor(height / cellSizeHeight)

    required property var model

    readonly property var currentItemGrid: stackView.currentItem
    readonly property var currentModel: currentItemGrid ? currentItemGrid.model : null //modelStack[modelStackLength - 1]

    readonly property bool isAtRoot: stackView.depth <= 1

    implicitWidth: currentItemGrid.implicitWidth
    implicitHeight: currentItemGrid.implicitHeight

    function tryEnterDirectory(directoryIndex) {
        let dir = currentModel.modelForRow(directoryIndex);
        if (dir && dir.hasChildren && currentItemGrid) {
            let origin = Qt.point(0, 0);
            let item = currentItemGrid.itemAtIndex(directoryIndex);
            if (item) {
                origin = Qt.point(  (item.x + (cellSizeWidth / 2)) - (currentItemGrid.width / 2), 
                                    (item.y + (cellSizeHeight / 2)) - (currentItemGrid.height / 2) - currentItemGrid.contentY )
            }
            stackView.push(directoryView, {model: dir, origin: origin});
        }
    }

    function tryExitDirectory() {
        if (!isAtRoot) {
            stackView.pop();
        }
    }

    function returnToRootDirectory(doTransition = true) {
        if (!isAtRoot) {
            // Pops all items up until root
            stackView.pop(null, doTransition ? undefined : StackView.ReplaceTransition);
        }
    }

    function selectFirst() {
        if (currentItemGrid && currentItemGrid.count > 0) {
            currentItemGrid.trySelect(0, 0);
        }
    }

    function selectLast() {
        if (currentItemGrid && currentItemGrid.count > 0) {
            currentItemGrid.trySelect(currentItemGrid.lastRow(), 0);
        }
    }

    function removeSelection() {
        if (currentItemGrid) {
            currentItemGrid.currentIndex = -1;
        }
    }

    // ActionMenu {
    //     id: actionMenu
    //     onActionClicked: visualParent.actionTriggered(actionId, actionArgument)
    //     onClosed: {
    //         currentItemGrid.currentIndex = -1;
    //     }
    // }

    // I believe StackView requires that the component be defined this way
    Component {
        id: directoryView
        ItemGridView {
            property var origin: Qt.point(0, 0)

            // width: appsGrid.numberColumns * cellSizeWidth
            // height: appsGrid.numberRows * cellSizeHeight
            numberColumns: appsGrid.numberColumns
            maxVisibleRows: appsGrid.numberRows

            cellWidth:  cellSizeWidth
            cellHeight: cellSizeHeight

            
            iconSize: appsGrid.iconSize
            usesPlasmaTheme: false

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

        implicitWidth: currentItemGrid.implicitWidth
        implicitHeight: currentItemGrid.implicitHeight
        anchors.top: parent.top

        focus: true

        property var transitionDuration: plasmoid.configuration.disableAnimations ? 0 : Kirigami.Units.veryLongDuration / plasmoid.configuration.animationSpeedMultiplier

        pushEnter: !plasmoid.configuration.disableAnimations ? pushEnterTransition : instantEnterTransition
        pushExit:  !plasmoid.configuration.disableAnimations ? pushExitTransition  : instantExitTransition
        popEnter:  !plasmoid.configuration.disableAnimations ? popEnterTransition  : instantEnterTransition
        popExit:   !plasmoid.configuration.disableAnimations ? popExitTransition   : instantExitTransition

        replaceEnter: instantEnterTransition
        replaceExit: instantExitTransition

        Transition {
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

        Transition {
            id: pushExitTransition
            NumberAnimation { property: "y"; from: 0; to: -(appsGrid.iconSize * .5); duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: 1.0; to: 0; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.8; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
        }

        Transition {
            id: popEnterTransition
           
            SequentialAnimation {
                PauseAnimation { duration: stackView.transitionDuration * .2 }
                ParallelAnimation {
                    NumberAnimation { property: "y"; from: -(appsGrid.iconSize * .5); to: 0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: stackView.transitionDuration * .5; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "scale"; from: 0.8; to: 1.0; duration: stackView.transitionDuration; easing.type: Easing.OutCubic }
                }
            }
        }

        Transition {
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

        Transition {
            id: instantEnterTransition

            PropertyAction { property: "opacity"; value: 1.0 }
            PropertyAction { property: "scale"; value: 1.0 }
        }

        Transition {
            id: instantExitTransition

            PropertyAction { property: "opacity"; value: 0 }
            PropertyAction { property: "scale"; value: 0 }
        }
    }
}
