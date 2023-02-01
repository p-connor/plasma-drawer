import QtQuick 2.15

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kquickcontrolsaddons 2.0

import "../code/tools.js" as Tools

Item {
    id: item

    implicitWidth: ListView.view.width
    implicitHeight: iconSize * 1.5

    property int iconSize: units.iconSizes.large
    property bool usesPlasmaTheme: true

    readonly property int sourceIconSize: matchIcon.implicitWidth

    readonly property bool hasActionList: ("hasActionList" in model) && (model.hasActionList == true)
    
    function getActionList() {
        return model.actionList;
    }

    PlasmaCore.IconItem {
        id: matchIcon

        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            margins: units.largeSpacing
        }

        width: item.iconSize
        height: width

        animated: false
        usesPlasmaTheme: usesPlasmaTheme
        source: model.decoration

        roundToIconSize: width > units.iconSizes.huge ? false : true
    }

    PlasmaComponents.Label {
        id: matchLabel

        anchors {
            left: matchIcon.right
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: units.largeSpacing
            rightMargin: units.largeSpacing
        }

        height: parent.height
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        wrapMode: Text.Wrap

        text: model.display
    }
}