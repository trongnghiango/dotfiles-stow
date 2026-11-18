# KaOS-CS ISO Profile

Custom Arch Linux ISO for CS Students (ThinkPad X230/T480) with Bulletproof Update System.

## Features

- **Btrfs subvolume layout**: `@` (root), `@home`, `@snapshots`, `@log`, `@pkg`
- **Snapper pre-configured**: Root + home configs with timeline & number cleanup
- **GRUB-Btrfs + systemd-boot**: Dual bootloader support with snapshot menu
- **Pacman hooks**: Auto-snapshots on package transactions
- **Bulletproof updates**: `safe-pacman`, `ka-update`, `pacman-hold`, `ka-health`
- **ThinkPad optimized**: Intel microcode, thermald, tlp, acpi_call, tp_smapi
- **Auto-setup**: Post-install runs `ka-setup all` via systemd service

## Package Selection

Based on `pkgs/arch.csv` tier 1-2 (essential + DWM/X11 core) plus:
- Bulletproof update system packages
- ThinkPad hardware support
- Development tools
- Media & productivity apps

## Build Instructions

```bash
# Install archiso
sudo pacman -S archiso arch-install-scripts

# Build ISO
cd /home/ka/Repos/github.com/trongnghiango/dotfiles-stow/iso-profile/kaos-cs
sudo mkarchiso -v -w /tmp/build -o /out .

# Test in VM
qemu-system-x86_64 -m 4G -enable-kvm -cdrom /out/KaOS-CS-*.iso
```

## Installation

1. Boot ISO (UEFI only)
2. Login as `liveuser` (no password)
3. Run installer: `sudo /root/install.sh --disk /dev/nvme0n1 --user ka --password "yourpass" --yes`
4. Reboot
5. Login as your user
6. First boot automatically runs `ka-setup all` via systemd service

## Installer Options

```bash
sudo /root/install.sh --disk /dev/nvme0n1 \
  --user ka \
  --password "SecurePass123" \
  --root-password "RootPass123" \
  --hostname kaos-cs \
  --timezone Asia/Ho_Chi_Minh \
  --swap 0 \
  --encrypt \
  --yes
```

## Post-Install Verification

```bash
# Verify snapper
snapper -c root list
snapper -c home list

# Verify update system
ka-update check
ka-update status
ka-health
safe-pacman -Syu

# Verify holds
pacman-hold list

# Verify GRUB-Btrfs menu
grub-btrfsd --syslog --timeshift-auto
```

## Directory Structure

```
iso-profile/kaos-cs/
├── profiledef.sh           # Profile definition
├── packages.x86_64         # Package list
├── README.md               # This file
├── airootfs/               # Root filesystem overlay
│   ├── etc/
│   │   ├── fstab           # Btrfs subvolume mounts
│   │   ├── mkinitcpio.conf # Btrfs hook
│   │   ├── snapper/configs/{root,home}
│   │   ├── pacman.d/hooks/ # Snapper + GRUB-Btrfs hooks
│   │   ├── default/grub    # GRUB config
│   │   ├── systemd/
│   │   │   ├── system/kaos-cs-firstboot.service
│   │   │   └── zram-generator.conf
│   │   ├── modprobe.d/thinkpad.conf
│   │   ├── sysctl.d/99-ka-performance.conf
│   │   ├── tmpfiles.d/99-ka-thp.conf
│   │   └── udev/rules.d/
│   ├── boot/loader/entries/ # systemd-boot entries
│   ├── root/install.sh      # Interactive installer
│   ├── usr/local/bin/       # Helper scripts
│   └── home/liveuser/       # Live user environment
├── syslinux/               # BIOS boot (legacy)
└── efiboot/                # UEFI boot assets
```

## Subvolume Layout

| Subvolume | Mount Point | Purpose |
|-----------|-------------|---------|
| `@` | `/` | Root filesystem |
| `@home` | `/home` | User data |
| `@snapshots` | `/.snapshots` | Snapper snapshots |
| `@log` | `/var/log` | System logs |
| `@pkg` | `/var/cache/pacman/pkg` | Package cache |

## Snapper Cleanup Policy

| Type | Limit |
|------|-------|
| Hourly | 10 |
| Daily | 10 |
| Weekly | 4 |
| Monthly | 3 |
| Yearly | 2 |
| Numbered | 50 (10 important) |
| Min age | 30 min |
| Empty pre/post | Yes (30 min) |

## GRUB-Btrfs

- Daemon: `grub-btrfsd.path` (watches /.snapshots)
- Menu entries: Auto-generated for each snapshot
- Boot parameters: `rootflags=subvol=@` + snapshot path

## Hardware Support

### ThinkPad X230 (Ivy Bridge, HD4000)
- `intel-ucode`, `thermald`, `tlp`
- `acpi_call`, `tp_smapi` for battery thresholds (50-60%)
- `i915` optimizations: RC6, FBC, semaphores
- ALSA audio backend (no PipeWire)

### ThinkPad T480 (Kaby Lake R, UHD620)
- `intel-ucode`, `thermald`, `tlp`
- Native battery thresholds (75-80%)
- PipeWire audio backend
- GLX compositor

## Rollback Testing

```bash
# Install a test package
sudo pacman -S --needed htop

# List snapshots
snapper -c root list

# Rollback to pre-install snapshot
sudo ka-update rollback <pre-snapshot-number>

# Reboot and verify htop is gone
which htop  # Should return nothing
```

## License

Part of dotfiles-stow project. See main repository for license.