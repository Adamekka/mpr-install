all: install

install:
		cp mpr.sh /usr/bin/mpr
		chmod +x /usr/bin/mpr

uninstall:
		rm /usr/bin/mpr

# my presets, ignore this
# mkdir -p path
# -p overwrites
# ln -sf originalfile wherelink