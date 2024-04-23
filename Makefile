# Prerequsites: Install kreadconfig5, kpackagetool6, zip, desktoptojson
# Example usages: 'make install', 'make VERSION=1.0 package'

DIR = $(shell pwd)
VERSION = $(shell kreadconfig5 --file="$(DIR)/metadata.desktop" --group="Desktop Entry" --key="X-KDE-PluginInfo-Version")
PACKAGE_NAME = plasma-drawer-$(VERSION).plasmoid

$(PACKAGE_NAME): $(shell find contents -type f) metadata.json README.md
	zip -r $(PACKAGE_NAME) contents metadata.json README.md

# Generate .json metadata file as deprecated .desktop files are easier to work with for translation scripts
metadata.json: metadata.desktop
	desktoptojson -i metadata.desktop -o metadata.json

package: $(PACKAGE_NAME)

install: $(PACKAGE_NAME)
	kpackagetool6 -t Plasma/Applet -i $(PACKAGE_NAME)

upgrade: $(PACKAGE_NAME)
	kpackagetool6 -t Plasma/Applet -u $(PACKAGE_NAME)

uninstall:
	kpackagetool6 -t Plasma/Applet -r p-connor.PlasmaDrawer

test:
	QT_LOGGING_RULES="qml.debug=true" plasmoidviewer -a ./

clean:
	rm *.plasmoid metadata.json
