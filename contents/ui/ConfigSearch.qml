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

    Kirigami.FormLayout {
        Kirigami.Heading {
            text: i18n("Search Plugin Allowlist")
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
        ColumnLayout {
            Repeater {
                model: defaultRunners

                CheckBox {
                    required property var modelData
                    checked: cfg_searchRunners.includes(modelData.id)
                    text: modelData.name

                    onToggled: {
                        if (checked) {
                            addRunner(modelData.id);
                        } else {
                            removeRunner(modelData.id);
                        }
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        Kirigami.Heading {
            level: 2
            text: i18n("Custom Search Plugins")
        }
        Label {
            text: i18n("Add any custom plugins to allowlist here")
        }
        RowLayout {
            Layout.fillWidth: true

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
        ColumnLayout {
            Repeater {
                model: cfg_searchRunners.filter((runner) => !defaultRunners.some((m) => m.id === runner))

                Kirigami.Chip {
                    id: chip
                    text: modelData
                    onRemoved: removeRunner(modelData)
                }
            }
        }
    }
}
