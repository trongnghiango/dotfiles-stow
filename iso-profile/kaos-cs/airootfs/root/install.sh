#!/usr/bin/env bash
# KaOS-CS Installer Script
# Runs from live ISO to install KaOS-CS on target disk
# Supports: ThinkPad X230/T480, Btrfs subvolumes, Snapper, GRUB-Btrfs, systemd-boot

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC}    $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $*" >&2; exit 1; }
log_step()    { echo -e "\n${CYAN}${BOLD}▸ $*${NC}"; }

# Defaults
DISK=""
USER_NAME="ka"
USER_PASS="ka"
ROOT_PASS="ka"
HOSTNAME="kaos-cs"
TIMEZONE="Asia/Ho_Chi_Minh"
DOTFILES_REPO="https://github.com/trongnghiango/dotfiles-stow.git"
SWAP_SIZE="0"  # zram handles swap, but allow optional swap partition
AUTO_CONFIRM=false
ENCRYPT=false
BOOT_MODE="uefi"  # uefi only for modern ThinkPads

usage() {
    cat <<EOF
${BOLD}KaOS-CS Installer${NC} - Arch Linux for CS Students (ThinkPad X230/T480)

${BOLD}Usage:${NC}
  sudo $0 --disk <device> [options]

${BOLD}Required:${NC}
  -d, --disk <device>       Target disk (e.g., /dev/nvme0n1, /dev/sda)

${BOLD}Optional:${NC}
  -u, --user <name>         Username (default: ka)
  -p, --password <pass>     User password (default: ka)
  -r, --root-password <pass> Root password (default: same as user)
  -n, --hostname <host>     Hostname (default: kaos-cs)
  -t, --timezone <tz>       Timezone (default: Asia/Ho_Chi_Minh)
  -s, --swap <size>         Swap partition size (default: 0, use zram)
  -e, --encrypt             Encrypt root with LUKS2 (experimental)
  -y, --yes                 Auto-confirm (no prompts)
  -h, --help                Show this help

${BOLD}Examples:${NC}
  # Interactive install on NVMe
  sudo $0 --disk /dev/nvme0n1

  # Automated install with encryption
  sudo $0 --disk /dev/nvme0n1 --user student --password "SecurePass123" --encrypt --yes

${BOLD}Post-install:${NC}
  After reboot, run: ka-setup all
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d|--disk) DISK="$2"; shift 2 ;;
        -u|--user) USER_NAME="$2"; shift 2 ;;
        -p|--password) USER_PASS="$2"; shift 2 ;;
        -r|--root-password) ROOT_PASS="$2"; shift 2 ;;
        -n|--hostname) HOSTNAME="$2"; shift 2 ;;
        -t|--timezone) TIMEZONE="$2"; shift 2 ;;
        -s|--swap) SWAP_SIZE="$2"; shift 2 ;;
        -e|--encrypt) ENCRYPT=true; shift ;;
        -y|--yes) AUTO_CONFIRM=true; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        *) log_error "Invalid option: $1" ;;
    esac
done

# Validation
[[ -z "$DISK" ]] && log_error "Disk not specified. Use --disk <device>"
[[ ! -b "$DISK" ]] && log_error "Disk $DISK does not exist"
[[ "$EUID" -ne 0 ]] && log_error "Must run as root"
[[ ! -d "/sys/firmware/efi" ]] && log_error "System not booted in UEFI mode"

# Show configuration
cat <<INFO
================================================================================
${BOLD}K A O S - C S   I N S T A L L E R${NC}
================================================================================
Target Disk      : $DISK
Hostname         : $HOSTNAME
Username         : $USER_NAME
Timezone         : $TIMEZONE
Swap Size        : $SWAP_SIZE
Encryption       : $ENCRYPT
Boot Mode        : UEFI (systemd-boot)
Filesystem       : Btrfs with subvolumes (@, @home, @snapshots, @log, @pkg)
Auto-confirm     : $AUTO_CONFIRM
================================================================================
INFO

if [[ "$AUTO_CONFIRM" != "true" ]]; then
    echo -e "${YELLOW}[WARN]${NC} ALL DATA ON $DISK WILL BE DESTROYED!"
    read -rp "Continue? (yes/no): " confirm
    [[ "$confirm" != "yes" ]] && log_info "Aborted by user" && exit 0
fi

# ==============================================================================
# STEP 1: Clean up and partition
# ==============================================================================
log_step "1. Preparing disk $DISK..."

# Unmount anything on target disk
swapoff -a 2>/dev/null || true
for mp in $(lsblk -nrpo MOUNTPOINT "$DISK" 2>/dev/null | sort -ru); do
    [[ -n "$mp" ]] && umount -R "$mp" 2>/dev/null || true
done
umount -R /mnt 2>/dev/null || true

# Close LUKS if any
vgchange -an 2>/dev/null || true
for part in $(lsblk -nrpo NAME "$DISK" 2>/dev/null | tail -n +2); do
    cryptsetup close "$(basename "$part")" 2>/dev/null || true
done

# Wipe disk
log_info "Wiping disk signatures..."
wipefs -af "$DISK" 2>/dev/null || true
dd if=/dev/zero of="$DISK" bs=1M count=10 status=none conv=notrunc 2>/dev/null || true
partprobe "$DISK" 2>/dev/null || true
udevadm settle

# Partition layout
# 1. ESP: 1GiB (fat32)
# 2. Root: rest (btrfs, optionally LUKS)
log_info "Creating GPT partitions..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "ESP" fat32 1MiB 1025MiB
parted -s "$DISK" set 1 esp on

if [[ "$SWAP_SIZE" != "0" ]]; then
    # With swap partition
    parted -s "$DISK" mkpart "SWAP" linux-swap 1025MiB "$((1025 + ${SWAP_SIZE%G} * 1024))MiB"
    ROOT_START="$((1025 + ${SWAP_SIZE%G} * 1024))MiB"
else
    ROOT_START="1025MiB"
fi
parted -s "$DISK" mkpart "ROOT" "$ROOT_START" 100%

partprobe "$DISK" 2>/dev/null || true
udevadm settle

# Determine partition names
if [[ "$DISK" =~ [0-9]$ ]]; then
    PART_ESP="${DISK}p1"
    if [[ "$SWAP_SIZE" != "0" ]]; then
        PART_SWAP="${DISK}p2"
        PART_ROOT="${DISK}p3"
    else
        PART_ROOT="${DISK}p2"
    fi
else
    PART_ESP="${DISK}1"
    if [[ "$SWAP_SIZE" != "0" ]]; then
        PART_SWAP="${DISK}2"
        PART_ROOT="${DISK}3"
    else
        PART_ROOT="${DISK}2"
    fi
fi

# Wait for partitions
for _ in {1..10}; do
    [[ -b "$PART_ESP" && -b "$PART_ROOT" ]] && break
    sleep 1
    partprobe "$DISK" 2>/dev/null || true
    udevadm settle
done

[[ -b "$PART_ESP" && -b "$PART_ROOT" ]] || log_error "Partitions not ready"

# ==============================================================================
# STEP 2: Format and setup Btrfs
# ==============================================================================
log_step "2. Setting up filesystems..."

# ESP
log_info "Formatting ESP ($PART_ESP)..."
mkfs.fat -F 32 -n "ESP" "$PART_ESP"

# Root - optionally encrypted
if [[ "$ENCRYPT" == "true" ]]; then
    log_info "Setting up LUKS2 encryption on $PART_ROOT..."
    echo -n "$ROOT_PASS" | cryptsetup luksFormat --type luks2 --pbkdf argon2id "$PART_ROOT" -
    echo -n "$ROOT_PASS" | cryptsetup open "$PART_ROOT" cryptroot -
    ROOT_DEV="/dev/mapper/cryptroot"
else
    ROOT_DEV="$PART_ROOT"
fi

# Btrfs on root
log_info "Creating Btrfs filesystem on $ROOT_DEV..."
mkfs.btrfs -f -L "KARCH" "$ROOT_DEV"

# Mount root to create subvolumes
mount "$ROOT_DEV" /mnt

log_info "Creating Btrfs subvolumes..."
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg

umount /mnt

# Mount subvolumes with proper options
MOUNT_OPTS="rw,noatime,compress=zstd:3,space_cache=v2"
log_info "Mounting subvolumes..."
mount -o "$MOUNT_OPTS,subvol=@" "$ROOT_DEV" /mnt
mkdir -p /mnt/{home,boot,var/log,var/cache/pacman/pkg,.snapshots}
mount -o "$MOUNT_OPTS,subvol=@home" "$ROOT_DEV" /mnt/home
mount -o "$MOUNT_OPTS,subvol=@snapshots" "$ROOT_DEV" /mnt/.snapshots
mount -o "$MOUNT_OPTS,subvol=@log" "$ROOT_DEV" /mnt/var/log
mount -o "$MOUNT_OPTS,subvol=@pkg" "$ROOT_DEV" /mnt/var/cache/pacman/pkg
mount -o rw,relatime,fmask=0022,dmask=0022 "$PART_ESP" /mnt/boot

# Swap partition if requested
if [[ "$SWAP_SIZE" != "0" ]]; then
    log_info "Setting up swap partition..."
    mkswap -L "SWAP" "$PART_SWAP"
    swapon "$PART_SWAP"
fi

# ==============================================================================
# STEP 3: Install base system
# ==============================================================================
log_step "3. Installing base system..."

# Update keyring
log_info "Updating archlinux-keyring..."
pacman -Sy --noconfirm archlinux-keyring

# Detect microcode
UCODE_PKG=""
if grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_PKG="intel-ucode"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_PKG="amd-ucode"
else
    UCODE_PKG="intel-ucode amd-ucode"
fi

# Base packages (minimal for bootstrapping)
BASE_PKGS=(
    base base-devel linux-lts linux-firmware "$UCODE_PKG"
    lvm2 networkmanager sudo git stow zsh man-db zram-generator
    btrfs-progs dosfstools cryptsetup grub efibootmgr
    snapper grub-btrfs reflector needrestart
    thermald tlp acpi_call tp_smapi
    intel-media-driver vulkan-intel brightnessctl
    bluez bluez-utils pipewire wireplumber pipewire-alsa pipewire-pulse
    noto-fonts noto-fonts-cjk ttf-jetbrains-mono
)

log_info "Running pacstrap..."
pacstrap -K /mnt "${BASE_PKGS[@]}"

# Generate fstab
log_info "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# ==============================================================================
# STEP 4: Configure system in chroot
# ==============================================================================
log_step "4. Configuring system..."

cat << 'CHROOT_SCRIPT' > /mnt/setup_chroot.sh
#!/usr/bin/env bash
set -euo pipefail

HOSTNAME="$1"
USERNAME="$2"
USERPASS="$3"
ROOTPASS="$4"
TIMEZONE="$5"
ENCRYPT="$6"
PART_ESP="$7"
PART_ROOT="$8"
SWAP_SIZE="$9"
DOTFILES_REPO="${10}"

# Timezone & Locale
ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
hwclock --systohc
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "${HOSTNAME}" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTS

# Network
systemctl enable NetworkManager
systemctl enable systemd-resolved
systemctl enable systemd-timesyncd

# Initramfs - Btrfs + encryption hooks
if [[ "$ENCRYPT" == "true" ]]; then
    sed -i -E 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt btrfs filesystems fsck)/' /etc/mkinitcpio.conf
else
    sed -i -E 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block btrfs filesystems fsck)/' /etc/mkinitcpio.conf
fi
mkinitcpio -P

# Bootloader - systemd-boot
bootctl --path=/boot install

# Get root UUID
ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
ESP_UUID=$(blkid -s UUID -o value "$PART_ESP")

# Update loader entries with actual UUIDs
sed -i "s/ROOT_UUID/$ROOT_UUID/g" /boot/loader/entries/*.conf
sed -i "s/ESP_UUID/$ESP_UUID/g" /boot/loader/entries/*.conf

# Also update fstab
sed -i "s/ROOT_UUID/$ROOT_UUID/g" /etc/fstab
sed -i "s/ESP_UUID/$ESP_UUID/g" /etc/fstab
if [[ "$SWAP_SIZE" != "0" ]]; then
    SWAP_UUID=$(blkid -s UUID -o value "$PART_SWAP" 2>/dev/null || echo "")
    if [[ -n "$SWAP_UUID" ]]; then
        sed -i "s/SWAP_UUID/$SWAP_UUID/g" /etc/fstab
    fi
fi

# GRUB for grub-btrfs (also install for snapshot menu)
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=KaOS-CS
grub-mkconfig -o /boot/grub/grub.cfg

# Users
useradd -m -G wheel -s /bin/bash "$USERNAME"
echo "${USERNAME}:${USERPASS}" | chpasswd
echo "root:${ROOTPASS}" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable thermald
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable paccache.timer
systemctl enable systemd-oomd

# Snapper setup
snapper -c root create-config /
snapper -c root set-config \
    TIMELINE_CREATE="yes" TIMELINE_LIMIT_HOURLY="10" TIMELINE_LIMIT_DAILY="10" \
    TIMELINE_LIMIT_WEEKLY="4" TIMELINE_LIMIT_MONTHLY="3" TIMELINE_LIMIT_YEARLY="2" \
    NUMBER_LIMIT="50" NUMBER_LIMIT_IMPORTANT="10" NUMBER_MIN_AGE="1800" \
    EMPTY_PRE_POST_CLEANUP="yes" EMPTY_PRE_POST_MIN_AGE="1800"

# Home snapper config (if separate subvolume)
snapper -c home create-config /home
snapper -c home set-config \
    TIMELINE_CREATE="yes" TIMELINE_LIMIT_HOURLY="10" TIMELINE_LIMIT_DAILY="10" \
    TIMELINE_LIMIT_WEEKLY="4" TIMELINE_LIMIT_MONTHLY="3" TIMELINE_LIMIT_YEARLY="2" \
    NUMBER_LIMIT="50" NUMBER_LIMIT_IMPORTANT="10" NUMBER_MIN_AGE="1800" \
    EMPTY_PRE_POST_CLEANUP="yes" EMPTY_PRE_POST_MIN_AGE="1800"

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
systemctl enable --now grub-btrfsd.path

# Create initial snapshots
snapper -c root create --type single --description "Post-install clean state" --number-cleanup=number
snapper -c home create --type single --description "Post-install clean state" --number-cleanup=number

# Clone dotfiles
USER_HOME="/home/${USERNAME}"
sudo -u "$USERNAME" git clone --depth=1 "$DOTFILES_REPO" "$USER_HOME/.dotfiles"

# Remove passwordless sudo for liveuser
rm -f /etc/sudoers.d/10-wheel

echo "Chroot configuration complete!"
CHROOT_SCRIPT

chmod +x /mnt/setup_chroot.sh

# Determine PART_SWAP for chroot
if [[ "$SWAP_SIZE" != "0" ]]; then
    PART_SWAP_ARG="$PART_SWAP"
else
    PART_SWAP_ARG=""
fi

arch-chroot /mnt /setup_chroot.sh \
    "$HOSTNAME" \
    "$USER_NAME" \
    "$USER_PASS" \
    "$ROOT_PASS" \
    "$TIMEZONE" \
    "$ENCRYPT" \
    "$PART_ESP" \
    "$PART_ROOT" \
    "$SWAP_SIZE" \
    "$DOTFILES_REPO"

rm /mnt/setup_chroot.sh

# ==============================================================================
# STEP 5: Finalize
# ==============================================================================
log_step "5. Finalizing installation..."

# Sync
sync

log_success "=================================================================="
log_success "  K A O S - C S   I N S T A L L A T I O N   C O M P L E T E"
log_success "=================================================================="
echo
log_info "System installed on $DISK"
log_info "Username: $USER_NAME"
log_info "Hostname: $HOSTNAME"
log_info ""
log_info "Next steps:"
log_info "  1. umount -R /mnt"
log_info "  2. reboot"
log_info "  3. Login as $USER_NAME"
log_info "  4. Run: ka-setup all"
echo