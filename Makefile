
# Example: 'make VERSION=1.0 package'

VERSION = $(shell cat metadata.json | jq .KPlugin.Version | tr -d '"')
PACKAGE_NAME = plasma-drawer-$(VERSION).plasmoid

$(PACKAGE_NAME):
	zip -r plasma-drawer-$(VERSION).plasmoid contents metadata.json README.md

package: $(PACKAGE_NAME)

install: $(PACKAGE_NAME)
	kpackagetool5 -i $(PACKAGE_NAME)

upgrade: $(PACKAGE_NAME)
	kpackagetool5 -u ./

uninstall:
	kpackagetool5 -t Plasma/Applet -r P-Connor.PlasmaDrawer

clean:
	rm *.plasmoid
