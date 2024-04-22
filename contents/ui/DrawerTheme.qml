import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

QtObject {
    readonly property bool usingCustomTheme: plasmoid.configuration.backgroundType != 0
    readonly property color backgroundColor: usingCustomTheme ? plasmoid.configuration.customBackgroundColor : Kirigami.Theme.backgroundColor
    readonly property color textColor: usingCustomTheme ? getReadableTextColor(backgroundColor) : Kirigami.Theme.textColor
    readonly property color softTextColor: soften(textColor, 0.225)
    readonly property color iconColor: soften(textColor, 0.1)

    function getReadableTextColor(backgroundColor) {
        return getPerceivedBrightness(backgroundColor) < .5 ? "#ddd" : "#222";
    }

    // Depending on the brightness of the color, make it brighter or darker by adjustment
    function soften(color, adjustment) {
        if (getPerceivedBrightness(color) > .5) {
            adjustment *= -1;
        } 
        return brighten(color, adjustment);
    }

    // Adjust the perceived brightness of a color approximately by adjustment
    function brighten(color, adjustment) {
        let relG = color.g / color.r;
        let relB = color.b / color.r;
        let initialBrightness = getPerceivedBrightness(color);

        let newR = Math.sqrt((Math.pow(initialBrightness + adjustment, 2) / (.299 + .587 * Math.pow(relG, 2) + .144 * Math.pow(relB, 2))));
        let newG = newR * relG;
        let newB = newR * relB;
        
        return Qt.rgba(newR, newG, newB, color.a);
    }

    // Method retrieved from http://alienryderflex.com/hsp.html
    function getPerceivedBrightness(color) {
        return Math.sqrt((Math.pow(color.r, 2) * .299) + (Math.pow(color.g, 2) * .587) + (Math.pow(color.b, 2) * .114));
    }
}
