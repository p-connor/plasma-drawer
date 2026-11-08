import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons
import org.kde.plasma.components 3.0 as PC3

import org.kde.plasma.plasmoid

Item {
    id: item

    property int iconSize: Kirigami.Units.iconSizes.large
    readonly property int sourceIconSize: matchIcon.implicitWidth
    readonly property bool hasActionList: ("hasActionList" in model) && (model.hasActionList == true)

    function getActionList() {
        return model.actionList;
    }

    implicitWidth: ListView.view.width
    implicitHeight: iconSize * 1.5

    Kirigami.Icon {
        id: matchIcon

        width: item.iconSize
        height: width
        animated: false
        source: model.decoration
        roundToIconSize: width > Kirigami.Units.iconSizes.huge ? false : true

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: Kirigami.Units.largeSpacing * 1.5
        }
    }
    PC3.Label {
        id: matchLabel

        height: parent.height
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.Wrap
        text: model.display
        color: drawerTheme.textColor

        anchors {
            left: matchIcon.right
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Kirigami.Units.largeSpacing * 1.5
            rightMargin: Kirigami.Units.largeSpacing * 1.5
        }
    }
}
