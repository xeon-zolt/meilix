$(BUILD)/debootstrap:
	mkdir -p $(BUILD)

	# Remove old debootstrap
	sudo rm -rf "$@" "$@.partial"

	# Install using debootstrap
	if ! sudo debootstrap --arch=amd64 --include=software-properties-common "$(UBUNTU_CODE)" "$@.partial"; \
	then \
		cat "$@.partial/debootstrap/debootstrap.log"; \
		false; \
	fi

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/chroot: $(BUILD)/debootstrap
	# Unmount chroot if mounted
	# scripts/unmount.sh "$@.partial"

	# Remove old chroot
	sudo rm -rf "$@" "$@.partial"

	# Copy chroot
	sudo cp -a "$<" "$@.partial"

	# Make temp directory for modifications
	sudo rm -rf "$@.partial/iso"
	sudo mkdir -p "$@.partial/iso"

	# Copy chroot script
	sudo cp "scripts/chroot.sh" "$@.partial/iso/chroot.sh"

	# Mount chroot
	"scripts/mount.sh" "$@.partial"

	# Run chroot script
	sudo chroot "$@.partial" /bin/bash -e -c \
		"UPDATE=1 \
		UPGRADE=1 \
		INSTALL=\"$(DISTRO_PKGS)\" \
		LANGUAGES=\"$(LANGUAGES)\" \
		PURGE=\"$(RM_PKGS)\" \
		AUTOREMOVE=1 \
		CLEAN=1 \
		/iso/chroot.sh \
		$(DISTRO_REPOS)"

	# Unmount chroot
	"scripts/unmount.sh" "$@.partial"

	# Remove temp directory for modifications
	sudo rm -rf "$@.partial/iso"

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/chroot.tag: $(BUILD)/chroot
	sudo chroot "$<" /bin/bash -e -c "dpkg-query -W --showformat='\$${Package}\t\$${Version}\n'" > "$@"

$(BUILD)/live: $(BUILD)/chroot
	# Unmount chroot if mounted
	scripts/unmount.sh "$@.partial"

	# Remove old chroot
	sudo rm -rf "$@" "$@.partial"

	# Copy chroot
	sudo cp -a "$<" "$@.partial"

	# Make temp directory for modifications
	sudo rm -rf "$@.partial/iso"
	sudo mkdir -p "$@.partial/iso"

	# Copy chroot script
	sudo cp "scripts/chroot.sh" "$@.partial/iso/chroot.sh"

	# Mount chroot
	"scripts/mount.sh" "$@.partial"

	# Copy GPG public key for APT CDROM
	gpg --batch --yes --export --armor "$(GPG_NAME)" | sudo tee "$@.partial/iso/apt-cdrom.key"

	# Run chroot script
	sudo chroot "$@.partial" /bin/bash -e -c \
		"KEY=\"/iso/apt-cdrom.key\" \
		INSTALL=\"$(LIVE_PKGS)\" \
		PURGE=\"$(RM_PKGS)\" \
		AUTOREMOVE=1 \
		CLEAN=1 \
		/iso/chroot.sh"

	# Unmount chroot
	"scripts/unmount.sh" "$@.partial"

	# Remove temp directory for modifications
	sudo rm -rf "$@.partial/iso"

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/live.tag: $(BUILD)/live
	sudo chroot "$<" /bin/bash -e -c "dpkg-query -W --showformat='\$${Package}\t\$${Version}\n'" > "$@"

$(BUILD)/squashfs: $(BUILD)/live
	# Unmount chroot if mounted
	scripts/unmount.sh "$@.partial"

	# Remove old chroot
	sudo rm -rf "$@" "$@.partial"

	# Copy chroot
	sudo cp -a "$<" "$@.partial"

	# Create missing network-manager file
	sudo touch "$@.partial/etc/NetworkManager/conf.d/10-globally-managed-devices.conf"

	# Patch ubiquity by removing plugins and updating order
	sudo sed -i "s/^AFTER = .*\$$/AFTER = 'language'/" "$@.partial/usr/lib/ubiquity/plugins/ubi-console-setup.py"
	sudo sed -i "s/^AFTER = .*\$$/AFTER = 'console_setup'/" "$@.partial/usr/lib/ubiquity/plugins/ubi-partman.py"
	sudo sed -i "s/^AFTER = .*\$$/AFTER = 'partman'/" "$@.partial/usr/lib/ubiquity/plugins/ubi-timezone.py"
	sudo rm -f "$@.partial/usr/lib/ubiquity/plugins/ubi-prepare.py"
	sudo rm -f "$@.partial/usr/lib/ubiquity/plugins/ubi-network.py"
	sudo rm -f "$@.partial/usr/lib/ubiquity/plugins/ubi-tasks.py"
	sudo rm -f "$@.partial/usr/lib/ubiquity/plugins/ubi-usersetup.py"
	sudo rm -f "$@.partial/usr/lib/ubiquity/plugins/ubi-wireless.py"

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"

$(BUILD)/pool: $(BUILD)/chroot
	# Unmount chroot if mounted
	scripts/unmount.sh "$@.partial"

	# Remove old chroot
	sudo rm -rf "$@" "$@.partial"

	# Copy chroot
	sudo cp -a "$<" "$@.partial"

	# Make temp directory for modifications
	sudo rm -rf "$@.partial/iso"
	sudo mkdir -p "$@.partial/iso"

	# Copy chroot script
	sudo cp "scripts/chroot.sh" "$@.partial/iso/chroot.sh"

	# Mount chroot
	"scripts/mount.sh" "$@.partial"

	# Run chroot script
	sudo chroot "$@.partial" /bin/bash -e -c \
		"MAIN_POOL=\"$(MAIN_POOL)\" \
		RESTRICTED_POOL=\"$(RESTRICTED_POOL)\" \
		CLEAN=1 \
		/iso/chroot.sh"

	# Unmount chroot
	"scripts/unmount.sh" "$@.partial"

	# Save package pool
	sudo mv "$@.partial/iso/pool" "$@.partial/pool"

	# Remove temp directory for modifications
	sudo rm -rf "$@.partial/iso"

	sudo touch "$@.partial"
	sudo mv "$@.partial" "$@"
