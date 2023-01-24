
# Example: 'make VERSION=1.0 package'

VERSION = $(shell cat metadata.json | jq .KPlugin.Version | tr -d '"')
PACKAGE_NAME = plasma-drawer-$(VERSION).plasmoid

$(PACKAGE_NAME): $(shell find contents -type f) metadata.json README.md
	zip -r $(PACKAGE_NAME) contents metadata.json README.md

package: $(PACKAGE_NAME)

install: $(PACKAGE_NAME)
	kpackagetool5 -i $(PACKAGE_NAME)

upgrade: $(PACKAGE_NAME)
	kpackagetool5 -u $(PACKAGE_NAME)

uninstall:
	kpackagetool5 -t Plasma/Applet -r P-Connor.PlasmaDrawer

test:
	QT_LOGGING_RULES="qml.debug=true" plasmoidviewer -a ./

clean:
	rm *.plasmoid
