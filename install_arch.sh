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
    --disk /dev/nvme0n1 \\
    --user ka \\
    --password "MatKhau123" \\
    --hostname arch-workstation \\
    --swap 8G \\
    --timezone Asia/Ho_Chi_Minh \\
    --dotfiles "https://github.com/trongnghiango/dotfiles-stow.git" \\
    --vg vg0 \\
    --yes

Danh sách tham số:
  -d, --disk <path>         Đường dẫn ổ đĩa cần cài (BẮT BUỘC, vd: /dev/vda, /dev/nvme0n1, /dev/sda)
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

# --------------------------- BƯỚC 1: GIẢI PHÓNG & PHÂN VÙNG -------------------
step "1. Giải phóng toàn bộ tài nguyên trên $DISK..."
# 1. Tắt swap toàn hệ thống
swapoff -a 2>/dev/null || true

# 2. Unmount tất cả các điểm mount đang gắn với ổ đĩa này và /mnt
log_info "Unmount các phân vùng đang hoạt động..."
if [ -b "$DISK" ]; then
    for mp in $(lsblk -nrpo MOUNTPOINT "$DISK" 2>/dev/null | sort -ru || true); do
        if [ -n "$mp" ]; then
            umount -R "$mp" 2>/dev/null || true
        fi
    done
fi
umount -R /mnt 2>/dev/null || true

# 3. Tắt TẤT CẢ các Volume Group LVM đang active trên hệ thống
log_info "Tắt các Volume Group LVM..."
vgchange -an 2>/dev/null || true

# 4. Đóng toàn bộ Device-Mapper con đang bám vào các partition của DISK
if [ -b "$DISK" ]; then
    for part in $(lsblk -nrpo NAME "$DISK" 2>/dev/null | tail -n +2 || true); do
        part_name=$(basename "$part")
        if [ -d "/sys/class/block/$part_name/holders" ]; then
            for holder in /sys/class/block/"$part_name"/holders/*; do
                if [ -e "$holder" ]; then
                    dm_name=$(basename "$holder")
                    dmsetup remove -f "$dm_name" 2>/dev/null || true
                fi
            done
        fi
    done
fi

# 5. Xóa sạch chữ ký filesystem/partition cũ
log_info "Xóa chữ ký phân vùng và cấu trúc cũ (wipefs)..."
if [ -b "$DISK" ]; then
    for part in $(lsblk -nrpo NAME "$DISK" 2>/dev/null | tail -n +2); do
        wipefs -af "$part" 2>/dev/null || true
    done
    wipefs -af "$DISK" 2>/dev/null || true
    # Xóa 10MB đầu để xóa sạch bảng phân vùng MBR/GPT cũ
    dd if=/dev/zero of="$DISK" bs=1M count=10 status=none conv=notrunc 2>/dev/null || true
fi

partprobe "$DISK" 2>/dev/null || true
udevadm settle

step "2. Tạo bảng phân vùng GPT mới..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "ESP" fat32 1MiB 1025MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart "LVM" 1025MiB 100%
parted -s "$DISK" set 2 lvm on

partprobe "$DISK" 2>/dev/null || true
udevadm settle

# Nhận diện tên phân vùng chính xác (vd: nvme0n1p1 vs sda1)
if [[ "$DISK" =~ [0-9]$ ]]; then
    PART_BOOT="${DISK}p1"
    PART_LVM="${DISK}p2"
else
    PART_BOOT="${DISK}1"
    PART_LVM="${DISK}2"
fi

# Đảm bảo device node đã xuất hiện
for _ in {1..5}; do
    if [ -b "$PART_BOOT" ] && [ -b "$PART_LVM" ]; then
        break
    fi
    sleep 1
    partprobe "$DISK" 2>/dev/null || true
    udevadm settle
done

if [ ! -b "$PART_BOOT" ] || [ ! -b "$PART_LVM" ]; then
    log_error "Phân vùng không sẵn sàng: $PART_BOOT hoặc $PART_LVM"
fi

wipefs -af "$PART_BOOT" 2>/dev/null || true
wipefs -af "$PART_LVM" 2>/dev/null || true

step "3. Thiết lập LVM (PV, VG, LV)..."
pvcreate -y -ff "$PART_LVM"
vgcreate -y "$VG_NAME" "$PART_LVM"

if [ "$SWAP_SIZE" != "0" ]; then
    lvcreate -y -L "$SWAP_SIZE" "$VG_NAME" -n swap
fi
lvcreate -y -l 100%FREE "$VG_NAME" -n root

vgchange -ay "$VG_NAME"
udevadm settle

step "4. Định dạng phân vùng và Mount..."
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
step "5. Cài đặt các gói cốt lõi qua Pacstrap..."

# Cập nhật keyring nếu cần để tránh lỗi chữ ký PGP
log_info "Làm mới Arch Linux keyring..."
pacman -Sy --noconfirm archlinux-keyring 2>/dev/null || log_warn "Không thể cập nhật keyring trên Live USB, tiếp tục pacstrap..."

# Tự động nhận diện CPU để chọn microcode tối ưu
UCODE_PKG=""
if grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_PKG="intel-ucode"
    log_info "Phát hiện CPU Intel -> Thêm gói $UCODE_PKG"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_PKG="amd-ucode"
    log_info "Phát hiện CPU AMD -> Thêm gói $UCODE_PKG"
else
    UCODE_PKG="intel-ucode amd-ucode"
    log_info "Không xác định rõ CPU -> Cài cả intel-ucode và amd-ucode"
fi

# Danh sách gói cơ sở tối giản
PKGS=(
    base
    base-devel
    linux
    linux-firmware
    lvm2
    networkmanager
    sudo
    git
    stow
    neovim
)
if [ -n "$UCODE_PKG" ]; then
    PKGS+=($UCODE_PKG)
fi

pacstrap -K /mnt "${PKGS[@]}"

genfstab -U /mnt >> /mnt/etc/fstab

# --------------------------- BƯỚC 3: CẤU HÌNH TRONG CHROOT --------------------
step "6. Cấu hình hệ thống, mkinitcpio & systemd-boot..."

# Tạo script cấu hình độc lập bên trong chroot (dùng quoted heredoc để bảo vệ an toàn 100% cú pháp và mật khẩu)
cat << 'CHROOT_SCRIPT' > /mnt/setup_system.sh
#!/usr/bin/env bash
set -euo pipefail

TARGET_TIMEZONE="$1"
TARGET_HOSTNAME="$2"
TARGET_VG="$3"
TARGET_USER="$4"
TARGET_PASS="$5"
TARGET_DOTFILES="$6"

# 1. Timezone & Locale
ln -sf "/usr/share/zoneinfo/${TARGET_TIMEZONE}" /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 2. Hostname & Hosts
echo "${TARGET_HOSTNAME}" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${TARGET_HOSTNAME}.localdomain ${TARGET_HOSTNAME}
HOSTS

# 3. Kích hoạt dịch vụ mạng
systemctl enable NetworkManager

# 4. Cấu hình mkinitcpio (Bắt buộc hook lvm2)
sed -i -E 's/^[[:space:]]*HOOKS=\(.*\)/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block lvm2 filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

# 5. Cài đặt và cấu hình systemd-boot
bootctl --path=/boot install

cat <<LOADER > /boot/loader/loader.conf
default  arch.conf
timeout  3
console-mode max
editor   no
LOADER

# Entry khởi động chính
cat <<ENTRY > /boot/loader/entries/arch.conf
title   Arch Linux (LVM)
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/${TARGET_VG}/root rw
ENTRY

# Entry dự phòng cứu hộ
cat <<FALLBACK > /boot/loader/entries/arch-fallback.conf
title   Arch Linux (LVM Fallback)
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=/dev/${TARGET_VG}/root rw
FALLBACK

# 6. Tạo người dùng & Cấp quyền Sudo (Truyền password an toàn qua stdin)
if ! id "${TARGET_USER}" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash "${TARGET_USER}"
fi

printf "%s:%s\n" "${TARGET_USER}" "${TARGET_PASS}" | chpasswd
printf "root:%s\n" "${TARGET_PASS}" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# 7. Clone Dotfiles an toàn
USER_HOME="/home/${TARGET_USER}"
if [ -n "${TARGET_DOTFILES}" ]; then
    echo ">>> Đang clone dotfiles vào ${USER_HOME}/.dotfiles..."
    if sudo -u "${TARGET_USER}" git clone --depth=1 "${TARGET_DOTFILES}" "${USER_HOME}/.dotfiles"; then
        echo -e "\e[1;32m[INFO]\e[0m Đã tải dotfiles thành công."
    else
        echo -e "\e[1;33m[WARN]\e[0m Tải dotfiles thất bại (có thể do lỗi mạng). Bạn có thể clone thủ công sau."
    fi
fi
CHROOT_SCRIPT

chmod +x /mnt/setup_system.sh

# Thực thi cấu hình trong môi trường chroot
arch-chroot /mnt /setup_system.sh \
    "$TIMEZONE" \
    "$HOSTNAME" \
    "$VG_NAME" \
    "$USER_NAME" \
    "$USER_PASS" \
    "$DOTFILES_REPO"

rm -f /mnt/setup_system.sh

# --------------------------- HOÀN THÀNH --------------------------------------
echo -e "\n\e[1;32m===============================================================\e[0m"
echo -e "\e[1;32m   CÀI ĐẶT HOÀN TẤT THÀNH CÔNG!                                \e[0m"
echo -e "\e[1;32m===============================================================\e[0m"
log_info "Hệ thống Arch Linux với LVM + systemd-boot đã sẵn sàng."
log_info "Chạy lệnh sau để khởi động lại máy:"
printf "\n  umount -R /mnt\n  reboot\n\n"
