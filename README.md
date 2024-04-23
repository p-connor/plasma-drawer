## Plasma Drawer
A fullscreen customizable launcher with application directories and krunner-like search for KDE Plasma

### Screenshots

![Custom setup](https://github.com/p-connor/plasma-drawer/blob/main/screenshots/custom.png?raw=true)

![Manjaro default setup](https://github.com/p-connor/plasma-drawer/blob/main/screenshots/manjaro-default.png?raw=true)

![Krunner-like search](https://github.com/p-connor/plasma-drawer/blob/main/screenshots/manjaro-search.png?raw=true)

### Installation

Download the [latest release](https://github.com/p-connor/plasma-drawer/releases/latest) and run the following command:

`kpackagetool5 -i plasma-drawer-VERSION.plasmoid`

To uninstall, use the following command:

`kpackagetool5 -t Plasma/Applet -r p-connor.plasma-drawer`

### Usage

Add the widget to your panel or desktop, then click its icon to open it.

#### Customizing Apps and Directories

Right click the widget icon, then select "Edit Applications." Then rearrange or adjust as desired. 
The applications in the grid will be arranged left to right, top to bottom.

#### Customizing Search Runners

Right click the icon widget, then select "Configure Plasma Drawer." Then click "Configure Enabled Search Plugins."

#### Customizing System Actions

System actions can be individually hidden by right clicking and selecting "Remove action," or disabled entirely in the widget configuration.
The actions can also be rearranged by long pressing and dragging the icon to the desired position.

### Internationalization

If you would like to contribute by adding translations for your language, follow the instructions in the [Translations Readme](translate/README.md)
