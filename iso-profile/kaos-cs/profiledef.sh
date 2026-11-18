# KaOS-CS archiso profile definition
# Based on releng profile from archiso

# Profile name and description
profile_name="kaos-cs"
profile_description="KaOS-CS - Arch Linux for CS Students (ThinkPad X230/T480) with Bulletproof Updates"

# Architecture
arch="x86_64"

# ISO label
iso_name="KaOS-CS"
iso_label="KAOS_CS_$(date +%Y%m)"
iso_publisher="KaOS-CS <https://github.com/trongnghiango/dotfiles-stow>"
iso_application="KaOS-CS Live/Install"

# Installation settings
install_dir="kaos-cs"
bootmodes=('uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
# syslinux not needed for UEFI-only, but kept for reference
# bootmodes+=('bios.syslinux.mbr' 'bios.syslinux.eltorito')

# Pacman configuration
pacman_conf="airootfs/etc/pacman.conf"

# Packages (from packages.x86_64)
packages=()

# Airootfs customization
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15')

# Kernel command line options
kernel_cmdline="quiet loglevel=3 rd.udev.log_level=3"

# Build options
buildmodes=('iso')

# Override mkinitcpio.conf for Btrfs + snapshots
# This will be copied to airootfs/etc/mkinitcpio.conf
# The actual file is created in airootfs/etc/mkinitcpio.conf

# Profile packages file
# packages file is at packages.x86_64 (relative to profile root)
# This is handled by mkarchiso automatically

# Post-install script
# The install script will be at airootfs/root/install.sh

# Bootloader config
# systemd-boot entries in airootfs/boot/loader/entries/
# grub config in airootfs/etc/default/grub (for grub-btrfs)