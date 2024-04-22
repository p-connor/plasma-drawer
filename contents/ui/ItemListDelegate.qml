import QtQuick

import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PC3
import org.kde.kirigami as Kirigami
import org.kde.kquickcontrolsaddons

Item {
    id: item

    implicitWidth: ListView.view.width
    implicitHeight: iconSize * 1.5

    property int iconSize: Kirigami.Units.iconSizes.large
    property bool usesPlasmaTheme: true

    readonly property int sourceIconSize: matchIcon.implicitWidth

    readonly property bool hasActionList: ("hasActionList" in model) && (model.hasActionList == true)
    
    function getActionList() {
        return model.actionList;
    }

    Kirigami.Icon {
        id: matchIcon

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            margins: Kirigami.Units.largeSpacing
        }

        width: item.iconSize
        height: width

        animated: false
        // usesPlasmaTheme: usesPlasmaTheme
        source: model.decoration

        roundToIconSize: width > Kirigami.Units.iconSizes.huge ? false : true
    }

    PC3.Label {
        id: matchLabel

        anchors {
            left: matchIcon.right
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Kirigami.Units.largeSpacing
            rightMargin: Kirigami.Units.largeSpacing
        }

        height: parent.height
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.Wrap

        text: model.display
        color: drawerTheme.textColor
    }
}
