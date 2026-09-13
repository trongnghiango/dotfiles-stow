#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# BỘ CÀI ĐẶT ARCH LINUX TINH GỌN (LVM + SYSTEMD-BOOT + DOTFILES)
# Hỗ trợ tùy biến toàn bộ thông số qua CLI Flag
# ==============================================================================

# --------------------------- GIÁ TRỊ MẶC ĐỊNH --------------------------------
DISK=""
VG_NAME="vg0"
SWAP_SIZE="4G"
USER_NAME="ka"
USER_PASS="1"
HOSTNAME="archlinux"
TIMEZONE="Asia/Ho_Chi_Minh"
DOTFILES_REPO="https://github.com/trongnghiango/dotfiles-stow.git"
AUTO_CONFIRM=false

# --------------------------- HÀM TIỆN ÍCH & LOG ------------------------------
log_info() { echo -e "$(date '+%H:%M:%S') \e[1;32m[INFO]\e[0m  $*"; }
log_warn() { echo -e "$(date '+%H:%M:%S') \e[1;33m[WARN]\e[0m  $*"; }
log_error() { echo -e "$(date '+%H:%M:%S') \e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }
step() { echo -e "\n\e[1;34m>>> $*\e[0m"; }

usage() {
    cat <<EOF
Cách dùng:
  sudo $0 --disk <ổ_đĩa> [TÙY CHỌN]

Ví dụ lệnh cài full tùy biến:
  sudo $0 \\
    --disk /dev/vda \\
    --user ka \\
    --password "1" \\
    --hostname arch \\
    --swap 8G \\
    --timezone Asia/Ho_Chi_Minh \\
    --dotfiles "https://github.com/trongnghiango/dotfiles-stow.git" \\
    --vg vg-arch \\
    --yes

Danh sách tham số:
  -d, --disk <path>         Đường dẫn ổ đĩa cần cài (BẮT BUỘC, vd: /dev/vda, /dev/nvme0n1)
  -u, --user <name>         Tên tài khoản người dùng (mặc định: ka)
  -p, --password <pass>     Mật khẩu chung cho User và Root (mặc định: 1)
  -n, --hostname <host>     Tên máy / Hostname (mặc định: archlinux)
  -s, --swap <size>         Dung lượng phân vùng Swap LVM (mặc định: 4G, đặt 0 để tắt swap)
  -t, --timezone <tz>       Múi giờ hệ thống (mặc định: Asia/Ho_Chi_Minh)
  -r, --dotfiles <url>      URL repo Git dotfiles (mặc định: repo dotfiles-stow)
  -v, --vg <name>           Tên LVM Volume Group (mặc định: vg0)
  -y, --yes                 Tự động xác nhận xóa ổ đĩa không cần hỏi lại
  -h, --help                Hiển thị hướng dẫn này
EOF
}

# --------------------------- PHÂN TÍCH THAM SỐ -------------------------------
TEMP=$(getopt -o d:u:p:n:s:t:r:v:yh --long disk:,user:,password:,hostname:,swap:,timezone:,dotfiles:,vg:,yes,help -n "$0" -- "$@") || {
    log_error "Tham số không hợp lệ. Dùng $0 --help để xem hướng dẫn."
}
eval set -- "$TEMP"
unset TEMP

while true; do
    case "$1" in
        -d|--disk) DISK="$2"; shift 2 ;;
        -u|--user) USER_NAME="$2"; shift 2 ;;
        -p|--password) USER_PASS="$2"; shift 2 ;;
        -n|--hostname) HOSTNAME="$2"; shift 2 ;;
        -s|--swap) SWAP_SIZE="$2"; shift 2 ;;
        -t|--timezone) TIMEZONE="$2"; shift 2 ;;
        -r|--dotfiles) DOTFILES_REPO="$2"; shift 2 ;;
        -v|--vg) VG_NAME="$2"; shift 2 ;;
        -y|--yes) AUTO_CONFIRM=true; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        *) log_error "Lỗi phân tích tham số: $1" ;;
    esac
done

# --------------------------- KIỂM TRA ĐIỀU KIỆN -------------------------------
if [ -z "$DISK" ]; then
    log_error "Chưa chỉ định ổ đĩa! Vui lòng thêm tham số --disk <tên_ổ_đĩa> (hoặc chạy $0 --help)"
fi

if [ "$EUID" -ne 0 ]; then
    log_error "Vui lòng chạy script với quyền root (sudo)."
fi

if [ ! -d "/sys/firmware/efi" ]; then
    log_error "Hệ thống đang boot ở chế độ BIOS/Legacy. Bắt buộc UEFI để dùng systemd-boot."
fi

if [ ! -b "$DISK" ]; then
    log_error "Ổ đĩa '$DISK' không tồn tại trên hệ thống!"
fi

cat <<INFO
==============================================================================
THÔNG TIN CẤU HÌNH CÀI ĐẶT:
------------------------------------------------------------------------------
  Ổ đĩa đích      : $DISK
  Volume Group    : $VG_NAME
  Swap size       : $SWAP_SIZE
  Tài khoản       : $USER_NAME
  Hostname        : $HOSTNAME
  Múi giờ         : $TIMEZONE
  Dotfiles Repo   : $DOTFILES_REPO
==============================================================================
INFO

if [ "$AUTO_CONFIRM" = false ]; then
    echo -e "\e[1;33m[CẢNH BÁO]\e[0m Toàn bộ dữ liệu trên \e[1;31m$DISK\e[0m sẽ bị XÓA HOÀN TOÀN!"
    read -rp "Bạn có chắc chắn muốn tiến hành cài đặt? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        log_info "Đã hủy cài đặt theo yêu cầu người dùng."
        exit 0
    fi
fi

# --------------------------- BƯỚC 1: DỌN DẸP & PHÂN VÙNG ----------------------
step "1. Dọn dẹp tài nguyên cũ và phân vùng ổ đĩa..."
swapoff -a 2>/dev/null || true
mountpoint -q /mnt/boot && umount -R /mnt/boot 2>/dev/null || true
mountpoint -q /mnt && umount -R /mnt 2>/dev/null || true
vgchange -an "$VG_NAME" 2>/dev/null || true

# Tạo bảng phân vùng GPT mới
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "ESP" fat32 1MiB 1025MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart "LVM" 1025MiB 100%
parted -s "$DISK" set 2 lvm on

# Nhận diện tên phân vùng (xử lý vd /dev/nvme0n1p1 vs /dev/vda1)
if [[ "$DISK" =~ [0-9]$ ]]; then
    PART_BOOT="${DISK}p1"
    PART_LVM="${DISK}p2"
else
    PART_BOOT="${DISK}1"
    PART_LVM="${DISK}2"
fi

udevadm settle

step "2. Thiết lập LVM (PV, VG, LV)..."
pvcreate -f "$PART_LVM"
vgcreate -f "$VG_NAME" "$PART_LVM"

if [ "$SWAP_SIZE" != "0" ]; then
    lvcreate -L "$SWAP_SIZE" "$VG_NAME" -n swap
fi
lvcreate -l 100%FREE "$VG_NAME" -n root

step "3. Định dạng phân vùng và Mount..."
mkfs.vfat -F 32 "$PART_BOOT"
mkfs.ext4 -F "/dev/${VG_NAME}/root"

mount "/dev/${VG_NAME}/root" /mnt
mkdir -p /mnt/boot
mount "$PART_BOOT" /mnt/boot

if [ "$SWAP_SIZE" != "0" ]; then
    mkswap "/dev/${VG_NAME}/swap"
    swapon "/dev/${VG_NAME}/swap"
fi

# --------------------------- BƯỚC 2: CÀI ĐẶT BASE OS --------------------------
step "4. Cài đặt các gói cốt lõi qua Pacstrap..."
pacstrap -K /mnt \
    base \
    base-devel \
    linux \
    linux-firmware \
    lvm2 \
    networkmanager \
    sudo \
    git \
    stow \
    neovim

genfstab -U /mnt >> /mnt/etc/fstab

# --------------------------- BƯỚC 3: CẤU HÌNH TRONG CHROOT --------------------
step "5. Cấu hình hệ thống, mkinitcpio & systemd-boot..."

arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# 1. Timezone & Locale
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 2. Hostname & Hosts
echo "${HOSTNAME}" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTS

# 3. Kích hoạt dịch vụ mạng
systemctl enable NetworkManager

# 4. Thêm hook lvm2 vào mkinitcpio
if ! grep -q "lvm2" /etc/mkinitcpio.conf; then
    sed -i 's/^HOOKS=(\(.*\)block\(.*\)filesystems\(.*\))/HOOKS=(\1block lvm2\2filesystems\3)/' /etc/mkinitcpio.conf
fi
mkinitcpio -P

# 5. Cài đặt và cấu hình systemd-boot
bootctl --path=/boot install

cat <<LOADER > /boot/loader/loader.conf
default  arch.conf
timeout  3
console-mode max
editor   no
LOADER

cat <<ENTRY > /boot/loader/entries/arch.conf
title   Arch Linux (LVM)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/${VG_NAME}/root rw
ENTRY

# 6. Tạo người dùng & Cấp quyền Sudo
useradd -m -G wheel -s /bin/bash "${USER_NAME}"
echo "${USER_NAME}:${USER_PASS}" | chpasswd
echo "root:${USER_PASS}" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# 7. Clone Dotfiles vào ~/.dotfiles
USER_HOME="/home/${USER_NAME}"
if [ -n "${DOTFILES_REPO}" ]; then
    echo ">>> Đang clone dotfiles vào \${USER_HOME}/.dotfiles..."
    sudo -u "${USER_NAME}" git clone "${DOTFILES_REPO}" "\${USER_HOME}/.dotfiles"
fi

EOF

# --------------------------- HOÀN THÀNH --------------------------------------
echo -e "\n\e[1;32m===============================================================\e[0m"
echo -e "\e[1;32m   CÀI ĐẶT HOÀN TẤT THÀNH CÔNG!                                \e[0m"
echo -e "\e[1;32m===============================================================\e[0m"
log_info "Hệ thống Arch Linux với LVM + systemd-boot đã sẵn sàng."
log_info "Chạy lệnh sau để khởi động lại máy:"
printf "\n  umount -R /mnt\n  reboot\n\n"
