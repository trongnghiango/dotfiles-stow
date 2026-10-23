#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# BỘ CÀI ĐẶT DEBIAN LINUX TỰ ĐỘNG TINH GỌN (DEBOOTSTRAP + GRUB UEFI + DOTFILES)
# Chuẩn mực kiến trúc: Độc lập, sạch sẽ, chỉ cài đặt Base OS
# Mọi cấu hình ứng dụng, môi trường và dịch vụ sau đó do ka-cli quản lý
# ==============================================================================

# --------------------------- GIÁ TRỊ MẶC ĐỊNH --------------------------------
DISK=""
SWAP_SIZE="4G"
USER_NAME="ka"
USER_PASS="1"
HOSTNAME="debian"
TIMEZONE="Asia/Ho_Chi_Minh"
SUITE="trixie"                            # trixie (13 stable), bookworm (12 oldstable), sid (unstable)
MIRROR="http://deb.debian.org/debian"
DOTFILES_REPO="https://github.com/trongnghiango/dotfiles-stow.git"
DOTFILES_BRANCH="main"
AUTO_CONFIRM=false
DRY_RUN=false

# --------------------------- HÀM TIỆN ÍCH & LOG ------------------------------
log_info()  { echo -e "$(date '+%H:%M:%S') \e[1;32m[INFO]\e[0m  $*"; }
log_warn()  { echo -e "$(date '+%H:%M:%S') \e[1;33m[WARN]\e[0m  $*"; }
log_error() { echo -e "$(date '+%H:%M:%S') \e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }
step()      { echo -e "\n\e[1;34m>>> $*\e[0m"; }

usage() {
    cat <<EOF
Cách dùng:
  sudo $0 --disk <ổ_đĩa> [TÙY CHỌN]

Ví dụ lệnh cài đặt tiêu chuẩn:
  sudo $0 --disk /dev/vda --yes

Ví dụ kiểm tra giả lập an toàn (dry-run):
  sudo $0 --disk /dev/nvme0n1 --check

Ví dụ tùy biến đầy đủ thông số:
  sudo $0 \\
    --disk /dev/nvme0n1 \\
    --user ka \\
    --password "MatKhau123" \\
    --hostname debian-box \\
    --swap 4G \\
    --suite trixie \\
    --timezone Asia/Ho_Chi_Minh \\
    --dotfiles "https://github.com/trongnghiango/dotfiles-stow.git" \\
    --branch main \\
    --yes

Danh sách tham số:
  -d, --disk <path>         Đường dẫn ổ đĩa cần cài (BẮT BUỘC, vd: /dev/vda, /dev/nvme0n1, /dev/sda)
  -u, --user <name>         Tên tài khoản người dùng (mặc định: ka)
  -p, --password <pass>     Mật khẩu chung cho User và Root (mặc định: 1)
  -n, --hostname <host>     Tên máy / Hostname (mặc định: debian)
  -s, --swap <size>         Dung lượng phân vùng Swap (mặc định: 4G, đặt 0 để tắt swap; nhận dạng: 4G, 2048M)
      --suite <release>     Phiên bản Debian (trixie | bookworm | sid, mặc định: trixie)
  -m, --mirror <url>        Debian repository mirror (mặc định: http://deb.debian.org/debian)
  -t, --timezone <tz>       Múi giờ hệ thống (mặc định: Asia/Ho_Chi_Minh)
  -r, --dotfiles <url>      URL repo Git dotfiles (mặc định: repo dotfiles-stow)
  -b, --branch <name>       Nhánh git dotfiles (mặc định: main)
  -y, --yes                 Tự động xác nhận xóa ổ đĩa không cần hỏi lại
  -c, --check               Chạy giả lập (Dry-run) kiểm tra điều kiện an toàn, không ghi đĩa
  -h, --help                Hiển thị hướng dẫn này
EOF
}

# --------------------------- PHÂN TÍCH THAM SỐ (THUẦN BASH, KHÔNG DÙNG EVAL) ---
while [ $# -gt 0 ]; do
    case "$1" in
        -d|--disk)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            DISK="$2"; shift 2 ;;
        --disk=*)
            DISK="${1#*=}"; shift ;;
        -u|--user)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            USER_NAME="$2"; shift 2 ;;
        --user=*)
            USER_NAME="${1#*=}"; shift ;;
        -p|--password)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            USER_PASS="$2"; shift 2 ;;
        --password=*)
            USER_PASS="${1#*=}"; shift ;;
        -n|--hostname)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            HOSTNAME="$2"; shift 2 ;;
        --hostname=*)
            HOSTNAME="${1#*=}"; shift ;;
        -s|--swap)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            SWAP_SIZE="$2"; shift 2 ;;
        --swap=*)
            SWAP_SIZE="${1#*=}"; shift ;;
        --suite)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            SUITE="$2"; shift 2 ;;
        --suite=*)
            SUITE="${1#*=}"; shift ;;
        -m|--mirror)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            MIRROR="$2"; shift 2 ;;
        --mirror=*)
            MIRROR="${1#*=}"; shift ;;
        -t|--timezone)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            TIMEZONE="$2"; shift 2 ;;
        --timezone=*)
            TIMEZONE="${1#*=}"; shift ;;
        -r|--dotfiles)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            DOTFILES_REPO="$2"; shift 2 ;;
        --dotfiles=*)
            DOTFILES_REPO="${1#*=}"; shift ;;
        -b|--branch)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            DOTFILES_BRANCH="$2"; shift 2 ;;
        --branch=*)
            DOTFILES_BRANCH="${1#*=}"; shift ;;
        -y|--yes)
            AUTO_CONFIRM=true; shift ;;
        -c|--check)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage; exit 0 ;;
        --)
            shift; break ;;
        -*)
            log_error "Tham số không hợp lệ: $1. Dùng $0 --help để xem hướng dẫn." ;;
        *)
            log_error "Tham số không xác định: $1" ;;
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
    log_error "Hệ thống đang boot ở chế độ BIOS/Legacy. Script này bắt buộc chuẩn UEFI."
fi

if [ ! -b "$DISK" ]; then
    log_error "Ổ đĩa '$DISK' không tồn tại trên hệ thống!"
fi

# Ngăn chặn chọn nhầm ổ đĩa đang chứa Root hệ thống hiện tại
CURRENT_ROOT_SRC=$(findmnt -n -o SOURCE / 2>/dev/null || true)
if [ -n "$CURRENT_ROOT_SRC" ]; then
    CURRENT_ROOT_DISK=$(lsblk -nrpo PKNAME "$CURRENT_ROOT_SRC" 2>/dev/null || true)
    [ -z "$CURRENT_ROOT_DISK" ] && CURRENT_ROOT_DISK="$CURRENT_ROOT_SRC"
    if [ "$DISK" = "$CURRENT_ROOT_DISK" ] || [ "$DISK" = "$CURRENT_ROOT_SRC" ]; then
        log_error "Ổ đĩa '$DISK' đang chứa hệ điều hành đang chạy (root /)! Để đảm bảo an toàn, không thể cài đè lên chính nó."
    fi
fi

# Ngăn chặn chọn nhầm thiết bị Live USB/CD đang khởi động
for live_mp in /run/live/medium /cdrom /run/archiso/bootmnt /run/initramfs/live; do
    if mountpoint -q "$live_mp" 2>/dev/null; then
        LIVE_SRC=$(findmnt -n -o SOURCE "$live_mp" 2>/dev/null || true)
        if [ -n "$LIVE_SRC" ]; then
            LIVE_DISK=$(lsblk -nrpo PKNAME "$LIVE_SRC" 2>/dev/null || true)
            [ -z "$LIVE_DISK" ] && LIVE_DISK="$LIVE_SRC"
            if [ "$DISK" = "$LIVE_DISK" ] || [ "$DISK" = "$LIVE_SRC" ]; then
                log_error "Ổ đĩa '$DISK' là thiết bị Live USB/CD đang khởi động! Không thể chọn làm đích cài đặt."
            fi
        fi
    fi
done

# Chuẩn hóa và tính toán dung lượng phân vùng Swap (hỗ trợ G/g, M/m, hoặc 0)
SWAP_MIB=0
if [ "$SWAP_SIZE" != "0" ]; then
    if [[ "$SWAP_SIZE" =~ ^([0-9]+)[Gg]$ ]]; then
        SWAP_MIB=$(( BASH_REMATCH[1] * 1024 ))
    elif [[ "$SWAP_SIZE" =~ ^([0-9]+)[Mm]$ ]]; then
        SWAP_MIB=${BASH_REMATCH[1]}
    elif [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
        if [ "$SWAP_SIZE" -le 64 ]; then
            SWAP_MIB=$(( SWAP_SIZE * 1024 ))
        else
            SWAP_MIB=$SWAP_SIZE
        fi
    else
        log_error "Định dạng swap không hợp lệ: '$SWAP_SIZE'. Ví dụ hợp lệ: 4G, 2048M, 0"
    fi
fi

# Tự động cài đặt công cụ cần thiết trên Live ISO nếu thiếu
REQUIRED_HOST_TOOLS=(debootstrap parted mkfs.vfat mkfs.ext4)
MISSING_TOOLS=()
for tool in "${REQUIRED_HOST_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("$tool")
    fi
done

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    log_warn "Thiếu các công cụ môi trường Live: ${MISSING_TOOLS[*]}"
    if command -v apt-get &>/dev/null; then
        log_info "Đang tự động cài đặt công cụ qua apt-get..."
        apt-get update -y
        apt-get install -y debootstrap parted dosfstools e2fsprogs arch-install-scripts || \
        apt-get install -y debootstrap parted dosfstools e2fsprogs
    else
        log_error "Vui lòng cài đặt các công cụ thiếu (${MISSING_TOOLS[*]}) trước khi chạy script."
    fi
fi

cat <<INFO
==============================================================================
THÔNG TIN CẤU HÌNH CÀI ĐẶT DEBIAN:
------------------------------------------------------------------------------
  Ổ đĩa đích      : $DISK
  Phân vùng       : ESP (1GB FAT32) + $([ "$SWAP_MIB" -gt 0 ] && echo "Swap (${SWAP_MIB}MiB) + " || echo "")Root (ext4)
  Phiên bản Debian: $SUITE (Mirror: $MIRROR)
  Tài khoản       : $USER_NAME
  Hostname        : $HOSTNAME
  Múi giờ         : $TIMEZONE
  Dotfiles Repo   : $DOTFILES_REPO (Nhánh: $DOTFILES_BRANCH)
==============================================================================
INFO

if [ "$DRY_RUN" = true ]; then
    log_info "[DRY-RUN] Kiểm tra điều kiện an toàn và cú pháp hoàn tất! Không có thay đổi nào được ghi lên đĩa."
    exit 0
fi

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
swapoff -a 2>/dev/null || true

# Unmount tất cả phân vùng đang gắn với ổ đĩa này và /mnt
log_info "Unmount các phân vùng đang hoạt động..."
if [ -b "$DISK" ]; then
    for mp in $(lsblk -nrpo MOUNTPOINT "$DISK" 2>/dev/null | sort -ru || true); do
        if [ -n "$mp" ]; then
            umount -R "$mp" 2>/dev/null || true
        fi
    done
fi
umount -R /mnt 2>/dev/null || true

# Tắt LVM nếu có volume group bám vào disk cũ
if command -v vgchange &>/dev/null; then
    vgchange -an 2>/dev/null || true
fi

# Đóng Device-Mapper holders
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

# Xóa sạch chữ ký filesystem cũ
log_info "Xóa chữ ký phân vùng và cấu trúc cũ (wipefs)..."
if [ -b "$DISK" ]; then
    for part in $(lsblk -nrpo NAME "$DISK" 2>/dev/null | tail -n +2 || true); do
        wipefs -af "$part" 2>/dev/null || true
    done
    wipefs -af "$DISK" 2>/dev/null || true
    dd if=/dev/zero of="$DISK" bs=1M count=10 status=none conv=notrunc 2>/dev/null || true
fi

partprobe "$DISK" 2>/dev/null || true
udevadm settle 2>/dev/null || sleep 1

step "2. Tạo bảng phân vùng GPT (Chuẩn EFI 1GB + Swap + Root ext4)..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart "ESP" fat32 1MiB 1025MiB
parted -s "$DISK" set 1 esp on

if [ "$SWAP_MIB" -gt 0 ]; then
    ROOT_START_MIB=$(( 1025 + SWAP_MIB ))
    parted -s "$DISK" mkpart "swap" linux-swap 1025MiB "${ROOT_START_MIB}MiB"
    parted -s "$DISK" mkpart "root" ext4 "${ROOT_START_MIB}MiB" 100%
else
    parted -s "$DISK" mkpart "root" ext4 1025MiB 100%
fi

partprobe "$DISK" 2>/dev/null || true
udevadm settle 2>/dev/null || sleep 1

# Nhận diện chính xác tên phân vùng (nvme0n1p1 vs sda1)
if [[ "$DISK" =~ [0-9]$ ]]; then
    PART_BOOT="${DISK}p1"
    if [ "$SWAP_MIB" -gt 0 ]; then
        PART_SWAP="${DISK}p2"
        PART_ROOT="${DISK}p3"
    else
        PART_SWAP=""
        PART_ROOT="${DISK}p2"
    fi
else
    PART_BOOT="${DISK}1"
    if [ "$SWAP_MIB" -gt 0 ]; then
        PART_SWAP="${DISK}2"
        PART_ROOT="${DISK}3"
    else
        PART_SWAP=""
        PART_ROOT="${DISK}2"
    fi
fi

# Chờ device nodes xuất hiện
for _ in {1..5}; do
    if [ -b "$PART_BOOT" ] && [ -b "$PART_ROOT" ]; then
        break
    fi
    sleep 1
    partprobe "$DISK" 2>/dev/null || true
    udevadm settle 2>/dev/null || true
done

if [ ! -b "$PART_BOOT" ] || [ ! -b "$PART_ROOT" ]; then
    log_error "Phân vùng không sẵn sàng: $PART_BOOT hoặc $PART_ROOT"
fi

wipefs -af "$PART_BOOT" 2>/dev/null || true
[ -n "$PART_SWAP" ] && wipefs -af "$PART_SWAP" 2>/dev/null || true
wipefs -af "$PART_ROOT" 2>/dev/null || true

step "3. Định dạng phân vùng và Mount..."
log_info "Format EFI: $PART_BOOT (FAT32)..."
mkfs.vfat -F 32 "$PART_BOOT"

if [ -n "$PART_SWAP" ]; then
    log_info "Format Swap: $PART_SWAP..."
    mkswap "$PART_SWAP"
    swapon "$PART_SWAP"
fi

log_info "Format Root: $PART_ROOT (ext4)..."
mkfs.ext4 -F "$PART_ROOT"

log_info "Mount phân vùng vào /mnt..."
mkdir -p /mnt
mount "$PART_ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$PART_BOOT" /mnt/boot/efi

# --------------------------- BƯỚC 2: DEBOOTSTRAP BASE OS ---------------------
step "4. Bootstrapping Debian ($SUITE) vào /mnt..."
log_info "Chạy debootstrap --arch=amd64 $SUITE /mnt $MIRROR..."
debootstrap --arch=amd64 "$SUITE" /mnt "$MIRROR"

step "5. Tạo /etc/fstab với định danh UUID tĩnh..."
mkdir -p /mnt/etc
if command -v genfstab &>/dev/null; then
    log_info "Tạo fstab qua genfstab..."
    genfstab -U /mnt > /mnt/etc/fstab
else
    log_info "Tạo fstab tự động theo UUID của phân vùng..."
    ROOT_UUID=$(blkid -s UUID -o value "$PART_ROOT")
    BOOT_UUID=$(blkid -s UUID -o value "$PART_BOOT")
    cat <<FSTAB > /mnt/etc/fstab
# /etc/fstab: static file system information.
# <file system>                             <mount point>   <type>  <options>       <dump>  <pass>
UUID=${ROOT_UUID}   /               ext4    errors=remount-ro 0       1
UUID=${BOOT_UUID}   /boot/efi       vfat    umask=0077        0       2
FSTAB
    if [ -n "$PART_SWAP" ]; then
        SWAP_UUID=$(blkid -s UUID -o value "$PART_SWAP")
        echo "UUID=${SWAP_UUID}   none            swap    sw                0       0" >> /mnt/etc/fstab
    fi
fi

# --------------------------- BƯỚC 3: CẤU HÌNH TRONG CHROOT --------------------
step "6. Thiết lập môi trường và cấu hình hệ thống trong Chroot..."

# Chuẩn bị file sources.list chính thức cho Debian
cat <<SOURCES > /mnt/etc/apt/sources.list
# Debian $SUITE Repositories
deb $MIRROR $SUITE main contrib non-free non-free-firmware
deb-src $MIRROR $SUITE main contrib non-free non-free-firmware

deb $MIRROR ${SUITE}-updates main contrib non-free non-free-firmware
deb-src $MIRROR ${SUITE}-updates main contrib non-free non-free-firmware
SOURCES

if [ "$SUITE" != "sid" ]; then
    cat <<SEC_SOURCES >> /mnt/etc/apt/sources.list

deb http://security.debian.org/debian-security ${SUITE}-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security ${SUITE}-security main contrib non-free non-free-firmware
SEC_SOURCES
fi

# Tạo script cấu hình độc lập bên trong chroot
cat << 'CHROOT_SCRIPT' > /mnt/setup_system.sh
#!/usr/bin/env bash
set -euo pipefail

TARGET_TIMEZONE="$1"
TARGET_HOSTNAME="$2"
TARGET_USER="$3"
TARGET_PASS="$4"
TARGET_DOTFILES="$5"
TARGET_BRANCH="$6"

export DEBIAN_FRONTEND=noninteractive

echo ">>> [Chroot] 1. Cập nhật APT và cài đặt Kernel & Gói cơ sở..."
apt-get update -y

# Tự động nhận diện CPU Microcode
UCODE_PKG=""
if grep -q "GenuineIntel" /proc/cpuinfo; then
    UCODE_PKG="intel-microcode"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    UCODE_PKG="amd64-microcode"
fi

BASE_PKGS=(
    linux-image-amd64
    linux-headers-amd64
    grub-efi-amd64
    efibootmgr
    locales
    tzdata
    network-manager
    sudo
    git
    curl
    wget
    stow
    neovim
    build-essential
    ca-certificates
    firmware-linux-free
)
[ -n "$UCODE_PKG" ] && BASE_PKGS+=("$UCODE_PKG")

apt-get install -y --no-install-recommends "${BASE_PKGS[@]}"

echo ">>> [Chroot] 2. Thiết lập Timezone & Locales..."
ln -sf "/usr/share/zoneinfo/${TARGET_TIMEZONE}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata 2>/dev/null || true

grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen 2>/dev/null || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/default/locale

echo ">>> [Chroot] 3. Cấu hình Hostname & Mạng..."
echo "${TARGET_HOSTNAME}" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${TARGET_HOSTNAME}.localdomain ${TARGET_HOSTNAME}
HOSTS

systemctl enable NetworkManager

echo ">>> [Chroot] 4. Cài đặt GRUB EFI Bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck
update-grub

echo ">>> [Chroot] 5. Tạo người dùng và phân quyền Sudo..."
if ! id "${TARGET_USER}" &>/dev/null; then
    useradd -m -s /bin/bash "${TARGET_USER}"
fi

# Thêm vào nhóm sudo chuẩn của Debian
usermod -aG sudo "${TARGET_USER}"

# Đặt mật khẩu an toàn qua stdin
printf "%s:%s\n" "${TARGET_USER}" "${TARGET_PASS}" | chpasswd
printf "root:%s\n" "${TARGET_PASS}" | chpasswd

# Cấp quyền sudoers
echo "%sudo ALL=(ALL:ALL) ALL" > /etc/sudoers.d/99-sudo-group
chmod 0440 /etc/sudoers.d/99-sudo-group

echo ">>> [Chroot] 6. Tải Dotfiles Stow về thư mục người dùng..."
USER_HOME="/home/${TARGET_USER}"
if [ -n "${TARGET_DOTFILES}" ]; then
    echo "Đang clone dotfiles (${TARGET_BRANCH}) vào ${USER_HOME}/dotfiles-stow..."
    if sudo -u "${TARGET_USER}" git clone --depth=1 -b "${TARGET_BRANCH}" "${TARGET_DOTFILES}" "${USER_HOME}/dotfiles-stow"; then
        echo "✓ Tải dotfiles thành công."
        chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/dotfiles-stow"
    else
        echo "Lưu ý: Không thể clone dotfiles (vui lòng clone thủ công sau khi đăng nhập)."
    fi
fi

CHROOT_SCRIPT

chmod +x /mnt/setup_system.sh

# Đồng bộ cấu hình DNS (/etc/resolv.conf) vào Chroot để APT và Git tải mạng ổn định
if [ -f /etc/resolv.conf ]; then
    log_info "Đồng bộ cấu hình DNS (/etc/resolv.conf) vào chroot..."
    cp -L /etc/resolv.conf /mnt/etc/resolv.conf 2>/dev/null || true
fi

# Hàm gọi chroot an toàn (dùng arch-chroot nếu có, hoặc bind mount thủ công chuẩn Linux)
if command -v arch-chroot &>/dev/null; then
    log_info "Thực thi chroot bằng arch-chroot..."
    arch-chroot /mnt /setup_system.sh \
        "$TIMEZONE" \
        "$HOSTNAME" \
        "$USER_NAME" \
        "$USER_PASS" \
        "$DOTFILES_REPO" \
        "$DOTFILES_BRANCH"
else
    log_info "Thực thi chroot bằng bind-mounts tiêu chuẩn..."
    mount --bind /dev /mnt/dev
    mount --bind /dev/pts /mnt/dev/pts
    mount --bind /proc /mnt/proc
    mount --bind /sys /mnt/sys
    mount --bind /run /mnt/run

    chroot /mnt /setup_system.sh \
        "$TIMEZONE" \
        "$HOSTNAME" \
        "$USER_NAME" \
        "$USER_PASS" \
        "$DOTFILES_REPO" \
        "$DOTFILES_BRANCH"

    umount /mnt/run /mnt/sys /mnt/proc /mnt/dev/pts /mnt/dev 2>/dev/null || true
fi

rm -f /mnt/setup_system.sh

# --------------------------- HOÀN THÀNH --------------------------------------
echo -e "\n\e[1;32m===============================================================\e[0m"
echo -e "\e[1;32m   CÀI ĐẶT BASE DEBIAN HOÀN TẤT THÀNH CÔNG!                   \e[0m"
echo -e "\e[1;32m===============================================================\e[0m"
log_info "Hệ thống Base Debian ($SUITE) với GRUB EFI & Dotfiles đã sẵn sàng."
log_info "Sau khi khởi động lại máy, đăng nhập tài khoản '${USER_NAME}' và dùng ka-setup:"
printf "\n  cd ~/dotfiles-stow && ./scripts/.local/bin/ka-setup all\n\n"
log_info "Chạy lệnh sau để unmount và khởi động lại máy:"
printf "\n  umount -R /mnt\n  reboot\n\n"
