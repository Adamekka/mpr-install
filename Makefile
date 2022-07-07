all: install

install:
		mkdir -p /usr/bin/mpr-install/
		cp mpr.sh /usr/bin/mpr-install/mpr
		chmod +x /usr/bin/mpr-install/mpr
		ln -sf /usr/bin/mpr-install/mpr /usr/bin/mpr
		cp mpr-update.sh /usr/bin/mpr-install/mpr-update
		chmod +x /usr/bin/mpr-install/mpr-update
		ln -sf /usr/bin/mpr-install/mpr-update /usr/bin/mpr-update
		cp version.txt /usr/bin/mpr-install/version

uninstall:
		rm -rf /usr/bin/mpr-install