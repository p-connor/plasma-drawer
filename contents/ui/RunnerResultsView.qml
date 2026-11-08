import QtQuick
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.extras as PlasmaExtras

import org.kde.plasma.plasmoid

FocusScope {
    id: searchResults

    property alias model: runnerSectionsList.model
    property alias currentSectionIndex: runnerSectionsList.currentIndex
    property alias currentSection: runnerSectionsList.currentItem
    readonly property var currentMatch: currentSection ? currentSection.currentItem : null
    property alias sectionsCount: runnerSectionsList.count
    property int iconSize: Kirigami.Units.iconSizes.huge
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
                lastList.currentIndex = lastList.lastVisibleIndex;
            }
        }
    }
    function removeSelection() {
        if (currentSection) {
            currentSection.currentIndex = -1;
        }
    }
    function triggerSelected() {
        if (currentSection && currentSection.currentIndex != -1) {
            currentSection.matchesList.trigger(currentSection.currentIndex);
        }
    }

    width: Kirigami.Units.gridUnit * 20
    height: Kirigami.Units.gridUnit * 60

    // TODO: Move off of ScrollView as it hijacks up/down key events
    // See https://code.qt.io/cgit/qt/qtdeclarative.git/tree/src/quicktemplates/qquickscrollview.cpp?h=6.9.3#n642
    PC3.ScrollView {
        id: scrollView

        // Add spacing on the left by right adjusting the ScrollView, which
        // centers the runnerSectionsList
        width: parent.width - ScrollBar.vertical.width
        height: parent.height
        anchors.right: parent.right
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.interactive: true
        focus: true

        ListView {
            id: runnerSectionsList

            function moveUp() {
                decrementCurrentIndex();
                if (currentItem && "count" in currentItem) {
                    currentItem.currentIndex = currentItem.lastVisibleIndex;
                }
            }
            function moveDown() {
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
                let matchY = section.y + match.y + headerHeight + Kirigami.Units.smallSpacing; // Match's y relative to runnerSectionsList's start
                let mappedY = matchY - contentY; // Match's y adjusted to scrolled position

                if (mappedY < 0) {
                    contentY += mappedY;
                } else if (mappedY + section.matchesList.rowHeight > height) {
                    contentY += ((mappedY + section.matchesList.rowHeight) - height);
                }
            }

            // ScrollView automatically sizes its child
            anchors.verticalCenter: parent.verticalCenter
            clip: true

            // TODO - Find a better way to provide scrollbar content height without buffering delegates
            cacheBuffer: height * 100
            focus: true
            currentIndex: -1
            keyNavigationEnabled: false
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            highlightMoveDuration: 0
            highlightResizeDuration: 0

            delegate: FocusScope {
                property alias count: matchesList.count
                property alias expanded: matchesList.expanded
                property alias expandable: matchesList.expandable
                property alias lastVisibleIndex: matchesList.lastVisibleIndex
                property alias currentIndex: matchesList.currentIndex
                property alias currentItem: matchesList.currentItem
                property alias matchesList: matchesList

                width: scrollView.width - scrollView.ScrollBar.vertical.width - Kirigami.Units.smallSpacing
                height: matchesList.height + sectionHeader.height + Kirigami.Units.largeSpacing * 4
                visible: (matchesList && matchesList.model && matchesList.model.count > 0)
                focus: index == 0

                Item {
                    id: sectionHeader

                    width: parent.width
                    height: runnerName.height
                    anchors.top: parent.top

                    PlasmaExtras.Heading {
                        id: runnerName

                        text: model.display ?? ""
                        level: 2
                        color: drawerTheme.textColor
                    }
                    Button {
                        id: showMoreButton

                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        visible: matchesList.expandable
                        focusPolicy: Qt.ClickFocus

                        contentItem: PC3.Label {
                            id: showMoreLabel

                            verticalAlignment: Text.AlignBottom
                            text: matchesList.expanded ? i18n("Show Less") : i18n("Show More")
                            color: showMoreButton.hovered ? drawerTheme.textColor : drawerTheme.softTextColor
                            font.underline: showMoreButton.activeFocus
                        }
                        background: Item {
                            anchors.fill: showMoreLabel
                            visible: false
                        }

                        onPressed: {
                            matchesList.focus = true;
                            matchesList.expanded = !matchesList.expanded;
                        }
                        Keys.onPressed: function (event) {
                            if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
                                // matchesList.focus = true;
                                matchesList.expanded = !matchesList.expanded;
                                event.accepted = true;
                                return;
                            }

                            if (event.key == Qt.Key_Up) {
                                focus = false;
                                matchesList.focus = true;
                                runnerSectionsList.moveUp();
                                event.accepted = true;
                                return;
                            }

                            if (event.key == Qt.Key_Down || event.key == Qt.Key_Left) {
                                focus = false;
                                matchesList.focus = true;
                                matchesList.currentIndex = 0;
                                event.accepted = true;
                                return;
                            }
                        }

                        DebugRect {}
                    }
                }

                // Rectangle {
                //     id: sectionSeparator
                //     anchors.left: runnerName.right
                //     anchors.right: parent.right
                //     anchors.verticalCenter: runnerName.verticalCenter
                //     anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                //     // width: root.width
                //     height: 2 * Kirigami.Units.devicePixelRatio
                //     color: Kirigami.Theme.textColor
                //     opacity: .05
                // }

                ItemListView {
                    id: matchesList

                    width: parent.width
                    anchors.top: sectionHeader.bottom
                    anchors.topMargin: Kirigami.Units.smallSpacing * 2
                    focus: true
                    iconSize: searchResults.iconSize
                    shrinkIconsToNative: searchResults.shrinkIconsToNative
                    maxVisibleRows: 5
                    interactive: false
                    model: runnerSectionsList.model.modelForRow(index)

                    //currentIndex: index == 0 ? 0 : -1
                    onCurrentIndexChanged: {
                        if (currentIndex != -1) {
                            runnerSectionsList.currentIndex = index;
                            runnerSectionsList.ensureCurrentMatchInView();
                        }
                    }
                    Keys.onPressed: function (event) {
                        if (event.key == Qt.Key_Right && showMoreButton.visible) {
                            event.accepted = true;
                            showMoreButton.focus = true;
                        }
                    }

                    DebugRect {}
                }
            }

            Keys.onPressed: function (event) {
                switch (event.key) {
                case Qt.Key_Up:
                case Qt.Key_PageUp:
                    if (currentIndex > 0) {
                        event.accepted = true;
                        moveUp();
                    }
                    break;
                case Qt.Key_Down:
                case Qt.Key_PageDown:
                    if (currentIndex < count - 1) {
                        event.accepted = true;
                        moveDown();
                    }
                    break;
                case Qt.Key_Right:
                    if (showMoreButton.visible) {
                        event.accepted = true;
                        showMoreButton.focus = true;
                    }
                    break;
                }
            }

            DebugRect {}
        }
    }

    // Keys.onPressed: function (event) {
    //     if (event.key == Qt.Key_Up || event.key == Qt.Key_Down || event.key == Qt.Key_Left || event.key == Qt.Key_Right) {
    //         if (currentSectionIndex == -1) {
    //             event.accepted = true;
    //             runnerSectionsList.moveDown();
    //         }
    //     }
    // }
}
