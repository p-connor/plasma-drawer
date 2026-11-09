import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons

import org.kde.plasma.plasmoid

FocusScope {
    id: appsGrid

    property int iconSize: Kirigami.Units.iconSizes.huge
    property int numberColumns: 5
    property int numberRows: 4
    readonly property int implicitCellWidth: currentItemGrid.implicitCellWidth
    readonly property int implicitCellHeight: currentItemGrid.implicitCellHeight
    required property var model
    readonly property var currentItemGrid: stackView.currentItem
    readonly property var currentModel: currentItemGrid ? currentItemGrid.model : null //modelStack[modelStackLength - 1]

    readonly property bool isAtRoot: stackView.depth <= 1

    function tryEnterDirectory(directoryIndex) {
        let dir = currentModel.modelForRow(directoryIndex);
        if (dir && dir.hasChildren && currentItemGrid) {
            let origin = Qt.point(0, 0);
            let item = currentItemGrid.itemAtIndex(directoryIndex);
            if (item) {
                origin = Qt.point((item.x + (currentItemGrid.cellWidth / 2)) - (currentItemGrid.width / 2), (item.y + (currentItemGrid.cellHeight / 2)) - (currentItemGrid.height / 2) - currentItemGrid.contentY);
            }
            stackView.push(directoryView, {
                model: dir,
                origin: origin
            });
            // Grid focus is temporarily removed, and re-enabled on any keyboard navigation attempt below.
            // This prevents the highlight from showing before any keystroke
            stackView.focus = false;
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

    implicitWidth: stackView.implicitWidth
    implicitHeight: stackView.implicitHeight
    Keys.forwardTo: [currentItemGrid]

    onActiveFocusChanged: function () {
        // If we lose focus, re-enable the grid focus in case we get it back later
        if (!activeFocus) {
            stackView.focus = true;
        }
    }
    onCurrentItemGridChanged: function () {
        Keys.forwardTo = [currentItemGrid];
    }
    Keys.onPressed: function (event) {
        switch (event.key) {
        case Qt.Key_Escape:
        case Qt.Key_Backspace:
            if (!isAtRoot) {
                stackView.focus = true;
                event.accepted = true;
                tryExitDirectory();
            }
            break;
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

            numberColumns: appsGrid.numberColumns
            numberRows: appsGrid.numberRows
            iconSize: appsGrid.iconSize
            model: appsGrid.model
            dragEnabled: false
            hoverEnabled: true
            layer.enabled: true
        }
    }
    StackView {
        id: stackView

        property var transitionDuration: plasmoid.configuration.disableAnimations ? 0 : Kirigami.Units.veryLongDuration / plasmoid.configuration.animationSpeedMultiplier

        initialItem: directoryView
        implicitWidth: currentItemGrid.implicitWidth
        implicitHeight: currentItemGrid.implicitHeight
        anchors.fill: parent
        focus: true
        pushEnter: !plasmoid.configuration.disableAnimations ? pushEnterTransition : instantEnterTransition
        pushExit: !plasmoid.configuration.disableAnimations ? pushExitTransition : instantExitTransition
        popEnter: !plasmoid.configuration.disableAnimations ? popEnterTransition : instantEnterTransition
        popExit: !plasmoid.configuration.disableAnimations ? popExitTransition : instantExitTransition
        replaceEnter: instantEnterTransition
        replaceExit: instantExitTransition

        Transition {
            id: pushEnterTransition

            NumberAnimation {
                property: "x"
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
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1.0
                duration: stackView.transitionDuration * .5
            }
            NumberAnimation {
                property: "scale"
                from: 0
                to: 1.0
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }
        }
        Transition {
            id: pushExitTransition

            NumberAnimation {
                property: "y"
                from: 0
                to: -(appsGrid.iconSize * .5)
                duration: stackView.transitionDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0
                duration: stackView.transitionDuration * .5
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0.8
                duration: stackView.transitionDuration * .5
                easing.type: Easing.OutCubic
            }
        }
        Transition {
            id: popEnterTransition

            SequentialAnimation {
                PauseAnimation {
                    duration: stackView.transitionDuration * .2
                }
                ParallelAnimation {
                    NumberAnimation {
                        property: "y"
                        from: -(appsGrid.iconSize * .5)
                        to: 0
                        duration: stackView.transitionDuration
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1.0
                        duration: stackView.transitionDuration * .5
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        property: "scale"
                        from: 0.8
                        to: 1.0
                        duration: stackView.transitionDuration
                        easing.type: Easing.OutCubic
                    }
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
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0
                duration: stackView.transitionDuration * .75
                easing.type: Easing.OutQuint
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: 0
                duration: stackView.transitionDuration * 1.5
                easing.type: Easing.OutCubic
            }
        }
        Transition {
            id: instantEnterTransition

            PropertyAction {
                property: "opacity"
                value: 1.0
            }
            PropertyAction {
                property: "scale"
                value: 1.0
            }
        }
        Transition {
            id: instantExitTransition

            PropertyAction {
                property: "opacity"
                value: 0
            }
            PropertyAction {
                property: "scale"
                value: 0
            }
        }
    }
}
