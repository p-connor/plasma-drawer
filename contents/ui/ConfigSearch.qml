import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore 6.3
import QtQuick.Dialogs

import org.kde.plasma.components as PC3
import org.kde.kcmutils as KCM
import org.kde.config as KConfig
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root
    
    property var cfg_searchRunners:  plasmoid.configuration.searchRunners

    // TODO: Find some way to load installed plugins dynamically instead of hard-coding the defaults
    readonly property var defaultRunners: [
        { id: "baloosearch", name: i18nc("KRunner Plugin", "File Search") },
        { id: "browserhistory", name: i18nc("KRunner Plugin", "Browser History") },
        { id: "browsertabs", name: i18nc("KRunner Plugin", "Browser Tabs") },
        { id: "calculator", name: i18nc("KRunner Plugin", "Calculator") },
        { id: "helprunner", name: i18nc("KRunner Plugin", "Help Runner") },
        { id: "krunner_appstream", name: i18nc("KRunner Plugin", "Software Center") },
        { id: "krunner_bookmarksrunner", name: i18nc("KRunner Plugin", "Bookmarks") },
        { id: "krunner_charrunner", name: i18nc("KRunner Plugin", "Special Characters") },
        { id: "krunner_dictionary", name: i18nc("KRunner Plugin", "Dictionary") },
        { id: "krunner_katesessions", name: i18nc("KRunner Plugin", "Kate Sessions") },
        { id: "krunner_kill", name: i18nc("KRunner Plugin", "Terminate Applications") },
        { id: "krunner_konsoleprofiles", name: i18nc("KRunner Plugin", "Konsole Profiles") },
        { id: "krunner_kwin", name: i18nc("KRunner Plugin", "KWin") },
        { id: "krunner_placesrunner", name: i18nc("KRunner Plugin", "Places") },
        { id: "krunner_plasma-desktop", name: i18nc("KRunner Plugin", "Plasma Desktop Shell") },
        { id: "krunner_powerdevil", name: i18nc("KRunner Plugin", "Power") },
        { id: "krunner_recentdocuments", name: i18nc("KRunner Plugin", "Recent Files") },
        { id: "krunner_services", name: i18nc("KRunner Plugin", "Applications") },
        { id: "krunner_sessions", name: i18nc("KRunner Plugin", "Desktop Sessions") },
        { id: "krunner_shell", name: i18nc("KRunner Plugin", "Command Line") },
        { id: "krunner_spellcheck", name: i18nc("KRunner Plugin", "Spell Checker") },
        { id: "krunner_systemsettings", name: i18nc("KRunner Plugin", "System Settings") },
        { id: "krunner_webshortcuts", name: i18nc("KRunner Plugin", "Web Search Keywords") },
        { id: "locations", name: i18nc("KRunner Plugin", "Locations") },
        { id: "org.kde.activities2", name: i18nc("KRunner Plugin", "Activities") },
        { id: "org.kde.datetime", name: i18nc("KRunner Plugin", "Date and Time") },
        { id: "unitconverter", name: i18nc("KRunner Plugin", "Unit Converter") },
        { id: "windows", name: i18nc("KRunner Plugin", "Windows") }
    ].sort((a, b) => a.name.localeCompare(b.name))

    function addRunner(runnerId) {
        if (runnerId 
                && !/^\s*$/.test(runnerId) 
                && !cfg_searchRunners.includes(runnerId) 
                && cfg_searchRunners.length < 10000) {
            cfg_searchRunners = [ ...cfg_searchRunners, runnerId ];
        }
    }

    function removeRunner(runnerId) {
        if (runnerId) {
            cfg_searchRunners = cfg_searchRunners.filter((r) => r !== runnerId);
        }
    }

    function moveRunner(fromIndex, toIndex) {
        if (fromIndex >= 0 && fromIndex < cfg_searchRunners.length && toIndex >= 0) {
            let arr = [...cfg_searchRunners];
            let element = arr[fromIndex];
            arr.splice(fromIndex, 1);
            arr.splice(toIndex, 0, element);
            cfg_searchRunners = arr;
        }
    }
    
    Component {
        id: delegateComponent
        ItemDelegate {
            id: listItem
            readonly property bool isActive: cfg_searchRunners.includes(modelData)

            contentItem: RowLayout {
                Kirigami.ListItemDragHandle {
                    enabled: isActive
                    listItem: listItem
                    listView: runnerListView
                    property int index: cfg_searchRunners.indexOf(modelData)
                    property int dropNewIndex
                    onMoveRequested: (oldIndex, newIndex) => {
                        dropNewIndex = newIndex;
                    }
                    onDropped: () => {
                        moveRunner(cfg_searchRunners.indexOf(modelData), dropNewIndex);
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: defaultRunners.find((m) => m.id === modelData)?.name ?? modelData
                }
                CheckBox {
                    checked: isActive
                    onToggled: {
                        checked ? addRunner(modelData) : removeRunner(modelData);
                    }
                }
            }
        }
    }

    Column {
        width: parent.width

        Kirigami.Heading {
            text: i18n("Plugin Allowlist")
        }
        Label {
            text: i18n("Note: Selected plugins must also be enabled in System Settings")
            font.italic: true
        }
        Button {    
            enabled: KConfig.KAuthorized.authorizeControlModule("kcm_plasmasearch")
            icon.name: "settings-configure"
            text: i18nc("@action:button", "Configure Enabled Search Plugins…")
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_plasmasearch")
        }

        Kirigami.Separator {
            width: parent.width
        }

        ListView {
            id: runnerListView
            model: cfg_searchRunners.concat(defaultRunners.map((m) => m.id).filter((m) => !cfg_searchRunners.includes(m)))
            width: parent.width
            height: contentItem.height
            interactive: false

            delegate: Loader {
                required property var modelData
                width: runnerListView.width
                sourceComponent: delegateComponent
            }
        }

        Kirigami.Separator {
            width: parent.width
        }

        Item {
            Kirigami.FormData.isSection: true
        }
        Kirigami.Heading {
            level: 2
            text: i18n("Custom Search Plugins")
        }
        Label {
            text: i18n("Add any custom plugins you've installed")
        }
        RowLayout {
            Label { text: i18n("Plugin ID:") }
            TextField {
                id: insertTextField
                Keys.onPressed: (event) => {
                    if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return)) {
                        event.accepted = true;
                        addRunner(insertTextField.text);
                        insertTextField.text = "";
                    }
                }
            }
            PC3.ToolButton {
                icon.name: "edit-add"
                onClicked: {
                    addRunner(insertTextField.text);
                    insertTextField.text = "";
                }
            }
        }
    }
}
