import QtQuick 2.15
import QtQuick.Controls 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

FocusScope {
    id: searchResults

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown

    width: PlasmaCore.Units.gridUnit * 20
    height: PlasmaCore.Units.gridUnit * 60

    property bool usesPlasmaTheme: true

    property alias model: runnerSectionsList.model
    property alias currentSectionIndex: runnerSectionsList.currentIndex
    property alias currentSection: runnerSectionsList.currentItem
    readonly property var currentMatch: currentSection ? currentSection.currentItem : null
    property alias sectionsCount: runnerSectionsList.count

    property int iconSize: units.iconSizes.huge
    property bool shrinkIconsToNative: false

    function selectFirst() {
        if (sectionsCount > 0) {
            runnerSectionsList.positionViewAtBeginning();
            runnerSectionsList.itemAtIndex(0).currentIndex = 0;
        }
    }

    function selectLast() {
        if (sectionsCount > 0) {
            runnerSectionsList.positionViewAtEnd();
            let lastList = runnerSectionsList.itemAtIndex(sectionsCount - 1);
            if (lastList && lastList.count > 0) {
                lastList.currentIndex = lastList.count - 1;
            }
        }
    }

    function triggerSelected() {
        if (currentSection && currentSection.currentIndex != -1) {
            currentSection.matchesList.trigger(currentSection.currentIndex);
        }
    }

    ListView {
        id: runnerSectionsList
        anchors.fill: parent
        clip: true

        focus: true
        currentIndex: -1

        keyNavigationEnabled: false
        boundsBehavior: Flickable.StopAtBounds

        highlightFollowsCurrentItem: false
        highlightMoveDuration: 0
        highlightResizeDuration: 0

        function moveUp() {
            if (currentIndex <= 0) {
                keyNavUp();
                return;
            }

            decrementCurrentIndex();
            if (currentItem && "count" in currentItem) {
                currentItem.currentIndex = currentItem.count - 1;
            }
        }

        function moveDown() {
            if (currentIndex >= count - 1) {
                keyNavDown();
                return;
            }

            incrementCurrentIndex();
            if (currentItem && "count" in currentItem) {
                currentItem.currentIndex = 0;
            }
        }

        function ensureCurrentMatchInView() {
            let section = currentItem;
            if (!section) {
                return;
            }
            let match = section.currentItem;
            if (!match) {
                return;
            }

            let headerHeight = section.matchesList.mapToItem(section, 0, 0).y;
            let matchY = section.y + match.y + headerHeight + units.smallSpacing; // Match's y relative to runnerSectionsList's start
            let mappedY = matchY - contentY; // Match's y adjusted to scrolled position

            if (mappedY < 0) {
                contentY += mappedY;
            } else if (mappedY + section.matchesList.rowHeight > height) {
                contentY += ((mappedY + section.matchesList.rowHeight) - height);
            }
        }

        delegate: FocusScope {
            width: searchResults.width
            height: matchesList.height + runnerName.height + units.smallSpacing * 5

            visible: matchesList.model && matchesList.model.count > 0

            property alias count: matchesList.count
            property alias currentIndex: matchesList.currentIndex
            property alias currentItem: matchesList.currentItem
            property alias matchesList: matchesList

            PlasmaExtras.Heading {
                id: runnerName
                text: model.display ?? ""
                level: 2
            }

            // Rectangle {
            //     id: sectionSeparator
            //     anchors.left: runnerName.right
            //     anchors.right: parent.right
            //     anchors.verticalCenter: runnerName.verticalCenter
            //     anchors.leftMargin: units.smallSpacing * 2
            //     // width: root.width
            //     height: 2 * units.devicePixelRatio
            //     color: theme.textColor
            //     opacity: .05
            // }

            ItemListView {
                id: matchesList
                width: searchResults.width
                anchors.top: runnerName.bottom
                anchors.topMargin: units.smallSpacing * 2

                focus: true

                iconSize: searchResults.iconSize
                shrinkIconsToNative: searchResults.shrinkIconsToNative

                interactive: false

                // currentIndex: index == 0 ? 0 : -1
                onCurrentIndexChanged: {
                    if (currentIndex != -1) {
                        runnerSectionsList.currentIndex = index;
                        runnerSectionsList.ensureCurrentMatchInView();
                    }
                }

                model: runnerSectionsList.model.modelForRow(index)

                onKeyNavUp: {
                    runnerSectionsList.moveUp();
                }

                onKeyNavDown: {
                    runnerSectionsList.moveDown();
                }

                Component.onCompleted: {
                    keyNavRight.connect(searchResults.keyNavRight);
                    keyNavLeft.connect(searchResults.keyNavLeft);
                }

                Rectangle {
                    anchors.fill: parent
                    color: "blue"
                    opacity: 0.05
                    visible: root.debugFocus && parent.activeFocus
                    z: 100
                }
            }
        }
    }

    Keys.onPressed: {
        if (event.key == Qt.Key_Up || event.key == Qt.Key_Down || event.key == Qt.Key_Left || event.key == Qt.Key_Right) {
            if (currentSectionIndex == -1) {
                event.accepted = true;
                runnerSectionsList.moveDown();
            }
        }
    }
}