import QtQuick
import QtQuick.Controls

import org.kde.kirigami as Kirigami

TextField {
    id: root

    readonly property bool searching: text != ""

    color: drawerTheme.textColor
    font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1
    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter
    placeholderText: i18n("Search")
    placeholderTextColor: drawerTheme.softTextColor
    leftInset: -(searchIcon.width + Kirigami.Units.smallSpacing * 4)
    rightInset: -(searchIcon.width + Kirigami.Units.smallSpacing * 4)

    background: Rectangle {
        id: background

        anchors.verticalCenter: parent.verticalCenter
        height: parent.height * 0.85
        radius: height * 0.25
        color: drawerTheme.colorWithAlpha(drawerTheme.textColor, .15)
    }

    Keys.onPressed: function (event) {
        if (event.key == Qt.Key_Escape) {
            if (text != "") {
                event.accepted = true;
                text = "";
            }
            return;
        }

        // Accept focus from forwarded Key events
        if (event.text != "" && !root.activeFocus) {
            root.forceActiveFocus();
        }
    }

    Kirigami.Icon {
        id: searchIcon

        source: "search-icon"
        visible: true
        width: background.height
        height: width
        roundToIconSize: true
        isMask: true
        color: drawerTheme.iconColor

        anchors {
            left: background.left
            leftMargin: Kirigami.Units.smallSpacing * 2
            verticalCenter: parent.verticalCenter
        }
    }
}
