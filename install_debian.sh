#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# BỘ CÀI ĐẶT DEBIAN LINUX TỰ ĐỘNG TINH GỌN (DEBOOTSTRAP + GRUB UEFI + DOTFILES)
# Chuẩn mực kiến trúc: Độc lập, sạch sẽ, chỉ cài đặt Base OS
# Mọi cấu hình ứng dụng, môi trường và dịch vụ sau đó do ka-cli quản lý
# ==============================================================================

# --------------------------- GIÁ TRỊ MẶC ĐỊNH --------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE=""                            # --config: file KEY=VALUE (tự dùng ./install.conf nếu có)
PRINT_CONFIG=false                        # --print-config: in cấu hình đã phân giải rồi thoát
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

# --- Khả năng truy cập sau reboot (bắt buộc cho máy không có console) ---
WIFI_SSID=""                              # --wifi-ssid: tên Wi-Fi cần tự kết nối
WIFI_PSK_FILE=""                          # --wifi-psk-file: file chứa mật khẩu Wi-Fi (không hardcode vào repo)
SSH_KEY_FILE=""                           # --ssh-key: file public key để đăng nhập không mật khẩu
SSH_PASSWORD_AUTH=true                    # --no-password-auth: tắt đăng nhập bằng mật khẩu
ALLOW_OFFLINE=false                       # --allow-offline: chấp nhận cài dù hiện không có đường mạng
FIX_CLOCK=true                            # --no-fix-clock: không tự đặt giờ từ HTTP Date khi lệch
HAS_WIFI=false                            # tự phát hiện card Wi-Fi trên máy đích
HAS_ETH_LINK=false                        # có interface Ethernet vật lý đang có link (carrier=1)
SB_ENABLED=false                          # Secure Boot đang bật → phải dùng shim + GRUB đã ký
FIRMWARE_PKGS=()                          # firmware cần cho card Wi-Fi phát hiện được
REQUIRED_TARGET_PKGS=()                   # gói bắt buộc phải có sau cài (dùng cho bước verify)

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

Ví dụ máy KHÔNG có console, chỉ vào được qua Wi-Fi + SSH:
  sudo $0 --disk /dev/nvme0n1 \\
    --user user --password 1 --hostname debian-stax-002 \\
    --wifi-ssid "Akapro-5G" --wifi-psk-file ~/wifi.psk \\
    --ssh-key ~/.ssh/id_ed25519.pub \\
    --yes

Ví dụ cài KHÔNG phân vùng swap (SWAP_SIZE=0):
  sudo $0 --disk /dev/nvme0n1 --swap 0 --yes

Ví dụ cấu hình bằng file (không phải nhớ tham số dài):
  cp install.conf.example install.conf
  vi install.conf
  sudo ./install_debian.sh --config install.conf --yes
  # hoặc đặt file ngay cạnh script: sudo ./install_debian.sh --yes (tự nạp ./install.conf)

Danh sách tham số:
  -d, --disk <path>         Đường dẫn ổ đĩa cần cài (BẮT BUỘC, vd: /dev/vda, /dev/nvme0n1, /dev/sda)
  -u, --user <name>         Tên tài khoản người dùng (mặc định: ka)
  -p, --password <pass>     Mật khẩu chung cho User và Root (mặc định: 1)
  -n, --hostname <host>     Tên máy / Hostname (mặc định: debian)
  -s, --swap <size>         Dung lượng phân vùng Swap (mặc định: 4G, đặt 0 để tắt swap; nhận dạng: 4G, 2048M)
  -C, --config <file>       Nạp cấu hình từ file KEY=VALUE (tự nạp ./install.conf nếu có)
      --print-config        In cấu hình đã phân giải rồi thoát (dry-run, không ghi đĩa)
      --suite <release>     Phiên bản Debian (trixie | bookworm | sid, mặc định: trixie)
  -m, --mirror <url>        Debian repository mirror (mặc định: http://deb.debian.org/debian)
  -t, --timezone <tz>       Múi giờ hệ thống (mặc định: Asia/Ho_Chi_Minh)
  -r, --dotfiles <url>      URL repo Git dotfiles (mặc định: repo dotfiles-stow)
  -b, --branch <name>       Nhánh git dotfiles (mặc định: main)
      --wifi-ssid <ssid>    Tên Wi-Fi sẽ tự kết nối sau reboot (cần --wifi-psk-file)
      --wifi-psk-file <f>   File chứa mật khẩu Wi-Fi (khuyến nghị; tránh lộ trong shell history)
      --ssh-key <file>      File public key cài sẵn vào authorized_keys của user
      --no-password-auth    Tắt SSH đăng nhập bằng mật khẩu (chỉ dùng key/Tailscale)
      --allow-offline       Cho phép cài khi máy không có Wi-Fi VÀ không có link Ethernet
                            (chỉ dùng khi bạn có KVM/màn hình tại máy để cứu hộ)
      --no-fix-clock        Không tự đặt giờ hệ thống khi phát hiện lệch > 5 phút
                            (mặc định tự đặt theo HTTP Date để APT không từ chối chữ ký)
  -y, --yes                 Tự động xác nhận xóa ổ đĩa không cần hỏi lại
  -c, --check               Chạy giả lập (Dry-run) kiểm tra điều kiện an toàn, không ghi đĩa
  -h, --help                Hiển thị hướng dẫn này
EOF
}

# --------------------------- FILE CẤU HÌNH (KEY=VALUE) ------------------------
# An toàn: mỗi khóa được ánh xạ qua allowlist bên dưới, không thực thi chuỗi từ file.
# Thứ tự ưu tiên: tham số dòng lệnh > file cấu hình > giá trị mặc định.
cfg_apply() {
    local key="$1" val="$2"
    case "$key" in
        DISK)               DISK="$val" ;;
        SWAP_SIZE)          SWAP_SIZE="$val" ;;
        USER_NAME)          USER_NAME="$val" ;;
        USER_PASS)          USER_PASS="$val" ;;
        HOSTNAME)           HOSTNAME="$val" ;;
        TIMEZONE)           TIMEZONE="$val" ;;
        SUITE)              SUITE="$val" ;;
        MIRROR)             MIRROR="$val" ;;
        DOTFILES_REPO)      DOTFILES_REPO="$val" ;;
        DOTFILES_BRANCH)    DOTFILES_BRANCH="$val" ;;
        WIFI_SSID)          WIFI_SSID="$val" ;;
        WIFI_PSK_FILE)      WIFI_PSK_FILE="$val" ;;
        SSH_KEY_FILE)       SSH_KEY_FILE="$val" ;;
        SSH_PASSWORD_AUTH)  SSH_PASSWORD_AUTH="$val" ;;
        ALLOW_OFFLINE)      ALLOW_OFFLINE="$val" ;;
        FIX_CLOCK)          FIX_CLOCK="$val" ;;
        AUTO_CONFIRM)       AUTO_CONFIRM="$val" ;;
        *) log_error "Khóa không hợp lệ trong file cấu hình: $key" ;;
    esac
}

cfg_trim() {
    local s="$1"
    while [ "${s# }" != "$s" ]; do s="${s# }"; done
    while [ "${s% }" != "$s" ]; do s="${s% }"; done
    printf '%s' "$s"
}

# Đổi "4G"/"2048M"/"0" → MiB. Trả mã lỗi 1 nếu không hợp lệ.
swap_size_to_mib() {
    local spec="$1"
    if [ "$spec" = "0" ]; then
        echo 0; return 0
    fi
    if [[ "$spec" =~ ^([0-9]+)[Gg]$ ]]; then
        echo $(( BASH_REMATCH[1] * 1024 )); return 0
    fi
    if [[ "$spec" =~ ^([0-9]+)[Mm]$ ]]; then
        echo "${BASH_REMATCH[1]}"; return 0
    fi
    if [[ "$spec" =~ ^[0-9]+$ ]]; then
        if [ "$spec" -le 64 ]; then
            echo $(( spec * 1024 ))
        else
            echo "$spec"
        fi
        return 0
    fi
    return 1
}

load_config() {
    local file="$1" line key val
    [ -r "$file" ] || log_error "Không đọc được file cấu hình: $file"
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in
            ''|'#'*) continue ;;
            *=*) ;;
            *) log_error "Dòng không hợp lệ trong $file (cần KEY=VALUE): $line" ;;
        esac
        key="$(cfg_trim "${line%%=*}")"
        val="$(cfg_trim "${line#*=}")"
        case "$val" in
            \"*\") val="${val#\"}"; val="${val%\"}" ;;
            \'*\') val="${val#\'}"; val="${val%\'}" ;;
        esac
        [ -n "$key" ] || log_error "Thiếu khóa trong $file: $line"
        cfg_apply "$key" "$val"
    done < "$file"
}

# Lượt quét trước: chỉ tìm --config để nạp file trước khi phân tích tham số.
_scan=("$@")
while [ ${#_scan[@]} -gt 0 ]; do
    case "${_scan[0]}" in
        -C|--config)   CONFIG_FILE="${_scan[1]:-}"; _scan=("${_scan[@]:2}") ;;
        --config=*)    CONFIG_FILE="${_scan[0]#*=}"; _scan=("${_scan[@]:1}") ;;
        *)             _scan=("${_scan[@]:1}") ;;
    esac
done
if [ -z "$CONFIG_FILE" ] && [ -f "${SCRIPT_DIR}/install.conf" ]; then
    CONFIG_FILE="${SCRIPT_DIR}/install.conf"
fi
if [ -n "$CONFIG_FILE" ]; then
    load_config "$CONFIG_FILE"
fi
unset _scan

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
        -C|--config)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            CONFIG_FILE="$2"; shift 2 ;;
        --config=*)
            CONFIG_FILE="${1#*=}"; shift ;;
        --print-config)
            PRINT_CONFIG=true; shift ;;
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
        --wifi-ssid)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            WIFI_SSID="$2"; shift 2 ;;
        --wifi-ssid=*)
            WIFI_SSID="${1#*=}"; shift ;;
        --wifi-psk-file)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            WIFI_PSK_FILE="$2"; shift 2 ;;
        --wifi-psk-file=*)
            WIFI_PSK_FILE="${1#*=}"; shift ;;
        --ssh-key)
            [ $# -ge 2 ] || log_error "Thiếu giá trị cho tham số $1"
            SSH_KEY_FILE="$2"; shift 2 ;;
        --ssh-key=*)
            SSH_KEY_FILE="${1#*=}"; shift ;;
        --no-password-auth)
            SSH_PASSWORD_AUTH=false; shift ;;
        --allow-offline)
            ALLOW_OFFLINE=true; shift ;;
        --no-fix-clock)
            FIX_CLOCK=false; shift ;;
        --fix-clock)
            FIX_CLOCK=true; shift ;;
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

# --------------------------- CHUẨN HÓA CẤU HÌNH (DRY-RUN) --------------------
if [ "$PRINT_CONFIG" = true ]; then
    _pc_mib="$(swap_size_to_mib "$SWAP_SIZE" || echo ERR)"
    [ "$_pc_mib" = "ERR" ] && log_error "Định dạng swap không hợp lệ: '$SWAP_SIZE'. Ví dụ: 4G, 2048M, 0"
    cat <<EOF
--- CẤU HÌNH ĐÃ PHÂN GIẢI (dry-run, không ghi đĩa) ---
File cấu hình : ${CONFIG_FILE:-<không có>}
Disk          : ${DISK:-<chưa đặt>}
Swap          : $SWAP_SIZE  → phân vùng swap: $([ "$_pc_mib" -gt 0 ] && echo "CÓ (${_pc_mib}MiB)" || echo KHÔNG)
User / Host   : ${USER_NAME}@${HOSTNAME}
Suite / Mirror: $SUITE ($MIRROR)
Timezone      : $TIMEZONE
Dotfiles      : $DOTFILES_REPO ($DOTFILES_BRANCH)
Wi-Fi SSID    : ${WIFI_SSID:-<không>}
SSH key       : ${SSH_KEY_FILE:-<không>}
SSH password  : $SSH_PASSWORD_AUTH
Auto confirm  : $AUTO_CONFIRM
Tự sửa giờ    : $FIX_CLOCK (lệch > 5 phút so với HTTP Date)
EOF
    exit 0
fi

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

# Chuẩn hóa dung lượng swap (4G / 2048M / 0) và chế độ swap của hệ đích
SWAP_MIB=$(swap_size_to_mib "$SWAP_SIZE") || \
    log_error "Định dạng swap không hợp lệ: '$SWAP_SIZE'. Ví dụ hợp lệ: 4G, 2048M, 0"

# Kích thước đĩa: ESP 1GiB cố định + swap + root. Root < 8GiB là không đủ cho
# debootstrap + kernel + headers (dễ "No space left on device" giữa chừng).
DISK_BYTES=$(blockdev --getsize64 "$DISK" 2>/dev/null || echo 0)
if [ "$DISK_BYTES" -gt 0 ]; then
    DISK_GIB=$(( DISK_BYTES / 1024 / 1024 / 1024 ))
    ROOT_GIB=$(( DISK_GIB - 1 - (SWAP_MIB / 1024) ))
    if [ "$ROOT_GIB" -lt 8 ] && [ "$SWAP_MIB" -gt 0 ]; then
        log_warn "Đĩa ${DISK_GIB}GiB quá nhỏ cho swap ${SWAP_MIB}MiB — tự động bỏ swap."
        SWAP_MIB=0
        SWAP_SIZE="0"
        ROOT_GIB=$(( DISK_GIB - 1 ))
    fi
    if [ "$ROOT_GIB" -lt 8 ]; then
        log_error "Đĩa ${DISK_GIB}GiB → phân vùng root chỉ còn ${ROOT_GIB}GiB, không đủ (cần ≥ 8GiB)."
    fi
    log_info "Đĩa ${DISK_GIB}GiB — phân vùng root sẽ có ~${ROOT_GIB}GiB."
fi

if [ "$SWAP_MIB" -gt 0 ]; then
    SWAP_MODE="zram"
else
    SWAP_MODE="off"
fi

# Tự động cài đặt công cụ cần thiết trên Live ISO nếu thiếu
REQUIRED_HOST_TOOLS=(debootstrap parted mkfs.vfat mkfs.ext4 efibootmgr)
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
        apt-get install -y debootstrap parted dosfstools e2fsprogs efibootmgr arch-install-scripts || \
        apt-get install -y debootstrap parted dosfstools e2fsprogs efibootmgr
    else
        log_error "Vui lòng cài đặt các công cụ thiếu (${MISSING_TOOLS[*]}) trước khi chạy script."
    fi
fi

# ------------------- ĐỒNG HỒ & MIRROR (CHẶN TRƯỚC KHI GHI ĐĨA) ---------------
# RTC sai (pin CMOS yếu) làm APT từ chối chữ ký: "Not live until <future>".
# Nếu không kiểm tra trước khi wipe, dữ liệu mất rồi mới chết giữa debootstrap.
if command -v curl &>/dev/null; then
    HTTP_DATE=$(curl -sI --max-time 8 https://deb.debian.org 2>/dev/null | \
        awk -F': ' 'tolower($1)=="date"{print $2; exit}' | tr -d '\r')
else
    HTTP_DATE=""
    log_warn "Không có curl — bỏ qua kiểm tra đồng hồ (APT có thể từ chối chữ ký nếu giờ sai)."
fi

if [ -n "$HTTP_DATE" ]; then
    REMOTE_EPOCH=$(date -u -d "$HTTP_DATE" +%s 2>/dev/null || echo 0)
    LOCAL_EPOCH=$(date -u +%s)
    SKEW=$(( REMOTE_EPOCH - LOCAL_EPOCH ))
    [ "$SKEW" -lt 0 ] && SKEW=$(( -SKEW ))
    if [ "$REMOTE_EPOCH" -gt 0 ] && [ "$SKEW" -gt 300 ]; then
        log_warn "Đồng hồ lệch ${SKEW}s so với Internet (RTC/pin CMOS yếu?)."
        if [ "$FIX_CLOCK" = true ]; then
            if date -s "$HTTP_DATE" >/dev/null 2>&1; then
                log_info "Đã đặt lại giờ theo HTTP Date: $(date -u '+%Y-%m-%d %H:%M UTC')"
            else
                log_error "Không đặt lại được giờ hệ thống — APT sẽ từ chối chữ ký. Sửa giờ rồi chạy lại."
            fi
        else
            log_warn "FIX_CLOCK=false — giữ nguyên giờ lệch; APT có thể fail."
        fi
    else
        log_info "Đồng hồ hệ thống ổn (lệch < 5 phút)."
    fi
fi

MIRROR_PROBE="${MIRROR%/}/dists/${SUITE}/Release"
MIRROR_OK=false
if command -v curl &>/dev/null; then
    curl -sSfI --max-time 10 "$MIRROR_PROBE" >/dev/null 2>&1 && MIRROR_OK=true
fi
if [ "$MIRROR_OK" = false ] && command -v wget &>/dev/null; then
    wget -q --spider --timeout=10 "$MIRROR_PROBE" >/dev/null 2>&1 && MIRROR_OK=true
fi
if [ "$MIRROR_OK" = true ]; then
    log_info "Mirror truy cập được: $MIRROR_PROBE"
elif [ "$ALLOW_OFFLINE" = true ]; then
    log_warn "Không truy cập được mirror ($MIRROR_PROBE) — tiếp tục theo --allow-offline."
else
    log_error "Không truy cập được mirror: $MIRROR_PROBE
  → Kiểm tra mạng/DNS TRƯỚC khi ghi đĩa (tránh wipe xong mới fail).
  → Nếu chủ ý cài offline: thêm --allow-offline."
fi

# ------------------- KIỂM TRA KHẢ NĂNG TRUY CẬP SAU REBOOT --------------------
# Máy không có console chỉ vào được qua mạng: thiếu SSH hoặc Wi-Fi = mất máy.
if [ -n "$WIFI_SSID" ] && [ -z "$WIFI_PSK_FILE" ]; then
    log_error "--wifi-ssid cần đi kèm --wifi-psk-file (không hardcode mật khẩu Wi-Fi vào repo)."
fi
if [ -n "$WIFI_PSK_FILE" ]; then
    [ -n "$WIFI_SSID" ] || log_error "--wifi-psk-file cần đi kèm --wifi-ssid"
    [ -r "$WIFI_PSK_FILE" ] || log_error "Không đọc được file PSK: $WIFI_PSK_FILE"
fi
if [ -n "$SSH_KEY_FILE" ]; then
    [ -r "$SSH_KEY_FILE" ] || log_error "Không đọc được SSH public key: $SSH_KEY_FILE"
    grep -qE '^(ssh-|ecdsa-|sk-)' "$SSH_KEY_FILE" 2>/dev/null \
        || log_error "$SSH_KEY_FILE không phải public key OpenSSH hợp lệ."
fi

# Phát hiện card mạng của máy đích (live ISO đã nạp driver nên thấy được)
NET_IDS=""
if command -v lspci &>/dev/null; then
    NET_IDS=$(lspci -nn 2>/dev/null | grep -iE 'network controller|ethernet controller' || true)
fi

WIFI_VIA_USB=false
if ls /sys/class/net 2>/dev/null | grep -q '^wl'; then
    HAS_WIFI=true
elif echo "$NET_IDS" | grep -qiE 'network controller.*(wireless|wi-fi)'; then
    HAS_WIFI=true
elif command -v lsusb &>/dev/null && lsusb 2>/dev/null | grep -qiE 'wireless|wlan|802\.11|wi-fi'; then
    HAS_WIFI=true
    WIFI_VIA_USB=true
    log_info "Phát hiện Wi-Fi qua USB (lsusb) — driver chưa nạp trên Live."
fi

# Firmware: phải quét CẢ Ethernet, không chỉ Wi-Fi. Card LAN Realtek/Broadcom trên
# desktop không có Wi-Fi vẫn cần firmware nhị phân, thiếu là mất mạng sau reboot.
add_fw() {
    local pkg="$1" _e
    for _e in "${FIRMWARE_PKGS[@]:-}"; do
        [ "$_e" = "$pkg" ] && return 0
    done
    FIRMWARE_PKGS+=("$pkg")
}

if echo "$NET_IDS" | grep -qi 'realtek'; then
    add_fw firmware-realtek
fi
if echo "$NET_IDS" | grep -qi 'intel' && echo "$NET_IDS" | grep -qiE 'wireless|wi-fi'; then
    add_fw firmware-iwlwifi
fi
if echo "$NET_IDS" | grep -qiE 'atheros|qualcomm'; then
    add_fw firmware-atheros
fi
if echo "$NET_IDS" | grep -qi 'broadcom'; then
    if echo "$NET_IDS" | grep -qiE 'wireless|wi-fi'; then
        add_fw firmware-brcm80211
    else
        add_fw firmware-bnx2
    fi
fi
if [ "$WIFI_VIA_USB" = true ]; then
    add_fw firmware-misc-nonfree
fi
if [ "$HAS_WIFI" = true ] && [ "${#FIRMWARE_PKGS[@]}" -eq 0 ]; then
    add_fw firmware-iwlwifi
    add_fw firmware-realtek
fi

if [ "$HAS_WIFI" = true ]; then
    if [ -z "$WIFI_SSID" ]; then
        log_warn "Máy có Wi-Fi nhưng chưa truyền --wifi-ssid/--wifi-psk-file."
        log_warn "Sau reboot máy sẽ KHÔNG tự lên mạng — chỉ vào được nếu cắm dây LAN."
    fi
else
    log_info "Không phát hiện card Wi-Fi — bỏ qua cấu hình Wi-Fi."
    if [ -n "$WIFI_SSID" ]; then
        log_warn "Bạn đã truyền --wifi-ssid nhưng KHÔNG thấy card Wi-Fi — profile sẽ không được tạo."
        log_warn "Nếu máy thật sự có card (driver chưa nạp), hãy kiểm tra 'lspci | grep -i network'."
    fi
fi

if [ "${#FIRMWARE_PKGS[@]}" -gt 0 ]; then
    log_info "Firmware mạng sẽ cài: ${FIRMWARE_PKGS[*]}"
fi

# Không có Wi-Fi ⇒ đường vào duy nhất là Ethernet, nên phải kiểm tra link NGAY.
# Mục tiêu: không bao giờ tạo ra một máy "cài xong nhưng không ai vào được".
for _nic in /sys/class/net/*; do
    _name=$(basename "$_nic")
    case "$_name" in
        lo|wl*|docker*|veth*|br-*|virbr*|tailscale*|tun*|tap*|zt*) continue ;;
    esac
    [ -e "$_nic/device" ] || continue          # bỏ qua interface ảo
    if [ "$(cat "$_nic/carrier" 2>/dev/null || echo 0)" = "1" ]; then
        HAS_ETH_LINK=true
        break
    fi
done

if [ "$HAS_WIFI" = false ]; then
    if [ "$HAS_ETH_LINK" = true ]; then
        log_info "Không có Wi-Fi — máy sẽ vào mạng qua Ethernet (DHCP). Giữ dây LAN trong lần boot đầu."
    elif [ "$ALLOW_OFFLINE" = false ]; then
        log_error "Máy KHÔNG có card Wi-Fi và Ethernet đang KHÔNG có link.
  → Sau reboot sẽ không còn đường nào vào máy (không console, không SSH).
  Cách xử lý: cắm dây LAN rồi chạy lại; hoặc thêm --allow-offline nếu có KVM/màn hình tại máy."
    else
        log_warn "Không có Wi-Fi và không có link Ethernet — cài offline theo --allow-offline."
        log_warn "Máy sẽ cần cắm dây LAN hoặc console ngay lần boot đầu tiên."
    fi
fi

# Secure Boot: GRUB không ký sẽ bị firmware chặn ("Image did not authenticate")
for _sb in /sys/firmware/efi/efivars/SecureBoot-*; do
    [ -e "$_sb" ] || continue
    if [ "$(od -An -tu1 -j4 -N1 "$_sb" 2>/dev/null | tr -d ' ')" = "1" ]; then
        SB_ENABLED=true
    fi
done
if [ "$SB_ENABLED" = true ]; then
    log_info "Secure Boot đang BẬT — sẽ cài shim-signed + grub-efi-amd64-signed."
else
    log_info "Secure Boot đang tắt (hoặc không đọc được efivar)."
fi

# Danh sách gói mang tính sống-còn, được verify lại trong chroot
REQUIRED_TARGET_PKGS=(
    openssh-server wpasupplicant wireless-regdb iw
    network-manager systemd-timesyncd grub-efi-amd64 efibootmgr
)
if [ "${#FIRMWARE_PKGS[@]}" -gt 0 ]; then
    REQUIRED_TARGET_PKGS+=("${FIRMWARE_PKGS[@]}")
fi
if [ "$SB_ENABLED" = true ]; then
    REQUIRED_TARGET_PKGS+=(shim-signed grub-efi-amd64-signed)
fi

if [ "$HAS_WIFI" = true ]; then
    if [ -n "$WIFI_SSID" ]; then
        NET_HINT="Wi-Fi (${WIFI_SSID})"
    else
        NET_HINT="Wi-Fi (CHƯA cấu hình SSID)"
    fi
elif [ "$HAS_ETH_LINK" = true ]; then
    NET_HINT="Ethernet (đang có link, DHCP)"
else
    NET_HINT="KHÔNG CÓ ĐƯỜNG MẠNG"
fi

HAS_WIFI_FLAG=no;       [ "$HAS_WIFI" = true ] && HAS_WIFI_FLAG=yes
SB_FLAG=no;             [ "$SB_ENABLED" = true ] && SB_FLAG=yes
SSH_PASS_FLAG=yes;      [ "$SSH_PASSWORD_AUTH" = true ] || SSH_PASS_FLAG=no

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
  Wi-Fi tự động   : $([ "$HAS_WIFI" = true ] && { [ -n "$WIFI_SSID" ] && echo "${WIFI_SSID} (NetworkManager)" || echo "CÓ CARD nhưng CHƯA cấu hình"; } || echo "không có card")
  Đường mạng      : $NET_HINT
  SSH sau reboot  : sshd + $([ "$SSH_PASSWORD_AUTH" = true ] && echo "mật khẩu BẬT" || echo "chỉ key")$([ -n "$SSH_KEY_FILE" ] && echo " + authorized_keys")
  Secure Boot     : $([ "$SB_ENABLED" = true ] && echo "BẬT (dùng shim + GRUB ký)" || echo "tắt")
  Firmware Wi-Fi  : $([ ${#FIRMWARE_PKGS[@]} -gt 0 ] && echo "${FIRMWARE_PKGS[*]}" || echo "không cần")
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

# ------------------- STAGE SECRETS + DANH SÁCH VERIFY CHO CHROOT --------------
# Ghi vào /root của hệ đích (0600); chroot đọc rồi xoá — không lộ qua argv/ps.
log_info "Chuẩn bị dữ liệu cấu hình truy cập cho chroot..."
install -d -m 0700 /mnt/root
: > /mnt/root/.ks-wifi-ssid
: > /mnt/root/.ks-wifi-psk
: > /mnt/root/.ks-authorized-key
: > /mnt/root/.ks-fw-pkgs
if [ -n "$WIFI_SSID" ]; then printf '%s' "$WIFI_SSID" > /mnt/root/.ks-wifi-ssid; fi
if [ -n "$WIFI_PSK_FILE" ]; then tr -d '\r\n' < "$WIFI_PSK_FILE" > /mnt/root/.ks-wifi-psk; fi
if [ -n "$SSH_KEY_FILE" ]; then cat "$SSH_KEY_FILE" > /mnt/root/.ks-authorized-key; fi
if [ "${#FIRMWARE_PKGS[@]}" -gt 0 ]; then printf '%s\n' "${FIRMWARE_PKGS[@]}" > /mnt/root/.ks-fw-pkgs; fi
printf '%s\n' "${REQUIRED_TARGET_PKGS[@]}" > /mnt/root/.ks-required-pkgs
chmod 600 /mnt/root/.ks-*

# Dù thành công hay thất bại giữa chừng, không để secrets nằm lại trên đĩa đích
# Dọn dẹp khi thoát (thành công hay thất bại):
#  1. không để secret tạm nằm lại trên đĩa đích
#  2. gỡ bind mount của chroot — nếu chroot chết giữa chừng mà không gỡ, lần chạy
#     sau sẽ gặp "device is busy" khi wipefs/parted
cleanup_on_exit() {
    rm -f /mnt/root/.ks-wifi-ssid /mnt/root/.ks-wifi-psk /mnt/root/.ks-authorized-key \
          /mnt/root/.ks-fw-pkgs /mnt/root/.ks-required-pkgs 2>/dev/null || true
    local mp
    for mp in /mnt/sys/firmware/efi/efivars /mnt/sys /mnt/proc /mnt/dev/pts /mnt/dev /mnt/run; do
        if mountpoint -q "$mp" 2>/dev/null; then
            umount -R "$mp" 2>/dev/null || umount -l "$mp" 2>/dev/null || true
        fi
    done
}
trap cleanup_on_exit EXIT INT TERM

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
TARGET_HAS_WIFI="${7:-no}"
TARGET_SSH_PASSWORD="${8:-yes}"
TARGET_SECURE_BOOT="${9:-no}"
TARGET_SWAP_MODE="${10:-zram}"

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
    systemd-timesyncd
    network-manager
    wpasupplicant
    wireless-regdb
    iw
    openssh-server
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

# Firmware Wi-Fi phải cài cùng lúc: --no-install-recommends KHÔNG kéo firmware lẫn wpasupplicant
if [ -s /root/.ks-fw-pkgs ]; then
    while IFS= read -r _fw; do
        if [ -n "$_fw" ]; then
            BASE_PKGS+=("$_fw")
        fi
    done < /root/.ks-fw-pkgs
fi

# Secure Boot bật: bắt buộc shim (Microsoft ký) + GRUB do Debian ký
if [ "$TARGET_SECURE_BOOT" = "yes" ]; then
    BASE_PKGS+=(shim-signed grub-efi-amd64-signed)
fi

apt-get install -y --no-install-recommends "${BASE_PKGS[@]}"

# NTP: đồng hồ lệch làm hỏng TLS/log/backup; Debian không bật sẵn
systemctl enable systemd-timesyncd >/dev/null 2>&1 || true

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

# efivarfs: systemd của Debian KHÔNG automount efivarfs (khác Arch). Thiếu nó thì
# efibootmgr/grub-install không ghi được NVRAM ("EFI variables are not supported").
if [ ! -d /sys/firmware/efi ] ; then
    echo "  ! Không có /sys/firmware/efi trong chroot — bỏ qua efivarfs"
elif grep -q 'efivars' /etc/fstab; then
    echo "  ✓ /etc/fstab đã có efivarfs"
else
    printf 'efivarfs\t/sys/firmware/efi/efivars\tefivarfs\tdefaults,nofail,nosuid,nodev,noexec\t0\t0\n' >> /etc/fstab
    echo "  ✓ Đã thêm efivarfs vào /etc/fstab"
fi

echo ">>> [Chroot] 4. Cài đặt GRUB EFI Bootloader..."
GRUB_EXTRA=()
if [ "$TARGET_SECURE_BOOT" = "yes" ]; then
    GRUB_EXTRA+=(--uefi-secure-boot)
fi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian "${GRUB_EXTRA[@]}" --recheck
update-grub

# Fallback path: firmware một số máy chỉ boot \EFI\BOOT\BOOTX64.EFI.
# LƯU Ý: nếu BOOTX64.EFI là shim thì shim sẽ nạp \EFI\BOOT\grubx64.efi —
# thiếu file đó là mất boot (firmware nhảy sang thiết bị khác). Vì vậy copy
# đủ bộ shim+grub+mm+fb vào EFI/BOOT, không chỉ mỗi BOOTX64.EFI.
mkdir -p /boot/efi/EFI/BOOT
for _efi_file in shimx64.efi grubx64.efi mmx64.efi fbx64.efi; do
    if [ -f "/boot/efi/EFI/debian/${_efi_file}" ]; then
        cp "/boot/efi/EFI/debian/${_efi_file}" "/boot/efi/EFI/BOOT/${_efi_file}"
    fi
done
if [ -f /boot/efi/EFI/debian/shimx64.efi ]; then
    cp /boot/efi/EFI/debian/shimx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
elif [ -f /boot/efi/EFI/debian/grubx64.efi ]; then
    cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
fi

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

USER_HOME="/home/${TARGET_USER}"
U_UID=$(id -u "${TARGET_USER}")
U_GID=$(id -g "${TARGET_USER}")

echo ">>> [Chroot] 6. Bảo đảm SSH sống ngay sau reboot..."
ssh-keygen -A >/dev/null
systemctl enable ssh >/dev/null 2>&1 || true
mkdir -p /run/sshd

SSHD_DROPIN=/etc/ssh/sshd_config.d/10-ka-hardening.conf
{
    echo "# Sinh tự động bởi install_debian.sh"
    echo "X11Forwarding no"
    echo "ClientAliveInterval 60"
    echo "ClientAliveCountMax 3"
    if [ "${TARGET_SSH_PASSWORD}" = "yes" ]; then
        echo "PasswordAuthentication yes"
    else
        echo "PasswordAuthentication no"
    fi
} > "$SSHD_DROPIN"
chmod 0644 "$SSHD_DROPIN"

if [ -s /root/.ks-authorized-key ]; then
    install -d -m 0700 -o "$U_UID" -g "$U_GID" "${USER_HOME}/.ssh"
    install -m 0600 -o "$U_UID" -g "$U_GID" /root/.ks-authorized-key "${USER_HOME}/.ssh/authorized_keys"
    echo "  ✓ Đã cài SSH public key cho ${TARGET_USER}"
fi

echo ">>> [Chroot] 7. Cấu hình Wi-Fi tự kết nối (NetworkManager)..."
NM_DIR=/etc/NetworkManager/system-connections
CONN_FILE="${NM_DIR}/wifi-auto.nmconnection"
if [ "${TARGET_HAS_WIFI}" = "yes" ] && [ -s /root/.ks-wifi-ssid ] && [ -s /root/.ks-wifi-psk ]; then
    SSID=$(cat /root/.ks-wifi-ssid)
    PSK=$(cat /root/.ks-wifi-psk)
    mkdir -p "$NM_DIR"
    {
        printf '[connection]\n'
        printf 'id=%s\n' "$SSID"
        printf 'uuid=%s\n' "$(cat /proc/sys/kernel/random/uuid)"
        printf 'type=wifi\n'
        printf 'autoconnect=true\n'
        printf 'autoconnect-retries=-1\n'
        printf 'hostname=%s\n\n' "${TARGET_HOSTNAME}"
        printf '[wifi]\n'
        printf 'mode=infrastructure\n'
        printf 'ssid=%s\n' "$SSID"
        printf 'cloned-mac=permanent\n'
        printf 'powersave=2\n\n'
        printf '[wifi-security]\n'
        printf 'key-mgmt=wpa-psk\n'
        printf 'psk=%s\n\n' "$PSK"
        printf '[ipv4]\n'
        printf 'method=auto\n'
        printf 'dhcp-send-hostname=true\n'
        printf 'dhcp-hostname=%s\n\n' "${TARGET_HOSTNAME}"
        printf '[ipv6]\n'
        printf 'method=auto\n'
    } > "$CONN_FILE"
    chmod 0600 "$CONN_FILE"
    chown 0:0 "$CONN_FILE"
    echo "  ✓ Wi-Fi '${SSID}' sẽ tự kết nối (DHCP)"
elif [ "${TARGET_HAS_WIFI}" = "yes" ]; then
    echo "  ! Có card Wi-Fi nhưng thiếu SSID/PSK — sau reboot cần cắm dây LAN"
fi

echo ">>> [Chroot] 8. Kiểm tra hậu cài đặt (fail-fast trước khi reboot)..."
FAIL=0
if [ -s /root/.ks-required-pkgs ]; then
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            echo "  [FAIL] thiếu gói: $pkg"; FAIL=1
        fi
    done < /root/.ks-required-pkgs
fi
if ! command -v wpa_supplicant >/dev/null 2>&1; then
    echo "  [FAIL] không có wpa_supplicant — Wi-Fi sẽ chết sau reboot"; FAIL=1
fi
if ! sshd -t 2>/dev/null; then
    echo "  [FAIL] sshd_config không hợp lệ"; FAIL=1
fi
if ! systemctl is-enabled ssh >/dev/null 2>&1; then
    echo "  [FAIL] ssh.service chưa được enable"; FAIL=1
fi
if [ ! -f /boot/efi/EFI/debian/grubx64.efi ]; then
    echo "  [FAIL] thiếu GRUB EFI"; FAIL=1
fi
# GRUB chỉ boot được khi kernel + initrd + grub.cfg đều có thật
if ! ls /boot/vmlinuz-* >/dev/null 2>&1; then
    echo "  [FAIL] thiếu kernel trong /boot"; FAIL=1
fi
if ! ls /boot/initrd.img-* >/dev/null 2>&1; then
    echo "  [FAIL] thiếu initrd trong /boot"; FAIL=1
fi
if [ ! -s /boot/grub/grub.cfg ]; then
    echo "  [FAIL] thiếu /boot/grub/grub.cfg"; FAIL=1
fi
if [ ! -f /boot/efi/EFI/BOOT/BOOTX64.EFI ]; then
    echo "  [FAIL] thiếu EFI fallback /EFI/BOOT/BOOTX64.EFI"; FAIL=1
fi
if [ -d /sys/firmware/efi ] && ! grep -q 'efivars' /etc/fstab; then
    echo "  [FAIL] fstab thiếu efivarfs — efibootmgr/grub-install sẽ không ghi được NVRAM"; FAIL=1
fi
if [ "$TARGET_SECURE_BOOT" = "yes" ] && [ ! -f /boot/efi/EFI/debian/shimx64.efi ]; then
    echo "  [FAIL] Secure Boot bật nhưng thiếu shimx64.efi đã ký"; FAIL=1
fi
if ! grep -qE '[[:space:]]/boot/efi[[:space:]]' /etc/fstab; then
    echo "  [FAIL] fstab thiếu mount /boot/efi"; FAIL=1
fi
# Fallback EFI: BOOTX64.EFI là shim thì bắt buộc có grubx64.efi cùng thư mục
if [ -f /boot/efi/EFI/debian/shimx64.efi ] && [ ! -f /boot/efi/EFI/BOOT/grubx64.efi ]; then
    echo "  [FAIL] EFI/BOOT thiếu grubx64.efi — shim không nạp được GRUB"; FAIL=1
fi
# Yêu cầu KHÔNG swap: fstab tuyệt đối không được còn dòng swap
if [ "$TARGET_SWAP_MODE" = "off" ] && grep -qE '[[:space:]]swap[[:space:]]' /etc/fstab; then
    echo "  [FAIL] yêu cầu KHÔNG swap nhưng /etc/fstab vẫn còn dòng swap"; FAIL=1
fi
if [ "${TARGET_HAS_WIFI}" = "yes" ] && [ -s /root/.ks-wifi-psk ]; then
    if [ ! -f "$CONN_FILE" ]; then
        echo "  [FAIL] thiếu profile Wi-Fi"; FAIL=1
    elif [ "$(stat -c %a "$CONN_FILE" 2>/dev/null)" != "600" ]; then
        echo "  [FAIL] quyền profile Wi-Fi phải là 600"; FAIL=1
    fi
fi
if [ "$FAIL" -ne 0 ]; then
    echo ">>> KIỂM TRA THẤT BẠI — dừng lại, KHÔNG reboot."
    exit 1
fi
echo "  ✓ Tất cả kiểm tra hậu cài đặt đều đạt"

echo ">>> [Chroot] 9. Tải Dotfiles Stow về ${USER_HOME}/.dotfiles..."
if [ -n "${TARGET_DOTFILES}" ]; then
    echo "Đang clone dotfiles (${TARGET_BRANCH}) vào ${USER_HOME}/.dotfiles..."
    if sudo -u "${TARGET_USER}" git clone --depth=1 -b "${TARGET_BRANCH}" "${TARGET_DOTFILES}" "${USER_HOME}/.dotfiles"; then
        echo "  ✓ Tải dotfiles thành công."
        chown -R "${TARGET_USER}:${TARGET_USER}" "${USER_HOME}/.dotfiles"
    else
        echo "  ! Không clone được dotfiles — chạy thủ công sau khi đăng nhập."
    fi
fi

echo ">>> [Chroot] 10. Dọn cache APT (đĩa nhỏ vẫn đủ chỗ)..."
apt-get clean
rm -rf /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/* 2>/dev/null || true
echo "  ✓ Đã dọn /var/cache/apt/archives"

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
        "$DOTFILES_BRANCH" \
        "$HAS_WIFI_FLAG" \
        "$SSH_PASS_FLAG" \
        "$SB_FLAG" \
        "$SWAP_MODE"
else
    log_info "Thực thi chroot bằng bind-mounts (recursive)..."
    # --rbind bắt buộc: các filesystem con (efivarfs tại /sys/firmware/efi/efivars,
    # devpts, cgroup) phải đi vào chroot. Bind thường làm efivars rỗng →
    # grub-install báo "EFI variables are not supported" và không tạo được entry.
    mount --rbind /dev /mnt/dev   && mount --make-rslave /mnt/dev
    mount --rbind /proc /mnt/proc && mount --make-rslave /mnt/proc
    mount --rbind /sys /mnt/sys   && mount --make-rslave /mnt/sys
    mount --rbind /run /mnt/run   && mount --make-rslave /mnt/run

    # Fallback: nếu vì lý do nào đó efivarfs không vào theo --rbind, bind riêng.
    if [ -d /sys/firmware/efi/efivars ] && \
       [ -z "$(ls -A /mnt/sys/firmware/efi/efivars 2>/dev/null)" ]; then
        mkdir -p /mnt/sys/firmware/efi/efivars
        mount --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars 2>/dev/null || \
            log_warn "Không bind được efivarfs — GRUB có thể không tạo được EFI entry (script sẽ tạo ở bước sau)."
    fi

    chroot /mnt /setup_system.sh \
        "$TIMEZONE" \
        "$HOSTNAME" \
        "$USER_NAME" \
        "$USER_PASS" \
        "$DOTFILES_REPO" \
        "$DOTFILES_BRANCH" \
        "$HAS_WIFI_FLAG" \
        "$SSH_PASS_FLAG" \
        "$SB_FLAG" \
        "$SWAP_MODE"

    for _mp in /mnt/sys/firmware/efi/efivars /mnt/run /mnt/sys /mnt/proc /mnt/dev/pts /mnt/dev; do
        if mountpoint -q "$_mp" 2>/dev/null; then
            umount -R "$_mp" 2>/dev/null || umount -l "$_mp" 2>/dev/null || true
        fi
    done
fi

rm -f /mnt/setup_system.sh

# --------------------------- EFI NVRAM BOOT ENTRY ----------------------------
# Firmware HP/Insyde hay không giữ entry do grub-install tạo; khi thiếu, máy chỉ
# boot được \EFI\BOOT\BOOTX64.EFI (delegate) và dễ rơi vào vòng "không boot được".
if command -v efibootmgr &>/dev/null; then
    EFI_LOADER=""
    if [ -f /mnt/boot/efi/EFI/debian/shimx64.efi ]; then
        EFI_LOADER='\EFI\debian\shimx64.efi'
    elif [ -f /mnt/boot/efi/EFI/debian/grubx64.efi ]; then
        EFI_LOADER='\EFI\debian\grubx64.efi'
    fi
    if [ -n "$EFI_LOADER" ]; then
        if efibootmgr 2>/dev/null | grep -qiE '^Boot[0-9A-Fa-f]{4}\*? debian'; then
            log_info "EFI boot entry 'debian' đã tồn tại."
        else
            log_info "Tạo EFI boot entry 'debian' → ${EFI_LOADER}..."
            efibootmgr -c -d "$DISK" -p 1 -L "debian" -l "$EFI_LOADER" >/dev/null 2>&1 || \
                log_warn "Không tạo được EFI entry từ Live (một số firmware chỉ ghi NVRAM trong BIOS setup)."
        fi
        DEBIAN_ENTRY=$(efibootmgr 2>/dev/null | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} debian.*/\1/p' | head -1)
        if [ -n "$DEBIAN_ENTRY" ]; then
            CUR_ORDER=$(efibootmgr 2>/dev/null | sed -n 's/^BootOrder: //p' | head -1)
            NEW_ORDER=$(printf '%s' "$CUR_ORDER" | tr ',' '\n' | grep -v "^${DEBIAN_ENTRY}$" | paste -sd, -)
            efibootmgr -o "${DEBIAN_ENTRY},${NEW_ORDER}" >/dev/null 2>&1 || true
            log_info "BootOrder ưu tiên: ${DEBIAN_ENTRY} (debian)."
        fi
    fi
fi

# --------------------------- HOÀN THÀNH --------------------------------------
echo -e "\n\e[1;32m===============================================================\e[0m"
echo -e "\e[1;32m   CÀI ĐẶT BASE DEBIAN HOÀN TẤT THÀNH CÔNG!                   \e[0m"
echo -e "\e[1;32m===============================================================\e[0m"
log_info "Hệ thống Base Debian ($SUITE) với GRUB EFI & Dotfiles đã sẵn sàng."
if [ "$SWAP_MIB" -gt 0 ]; then
    log_info "Phân vùng swap: ${SWAP_MIB}MiB"
else
    log_info "KHÔNG có phân vùng swap (theo yêu cầu SWAP_SIZE=0)."
fi
log_info "SSH đã bật và sẽ tự khởi động lại; host key đã sinh sẵn."
if [ "$HAS_WIFI_FLAG" = "yes" ] && [ -n "$WIFI_SSID" ]; then
    log_info "Wi-Fi '${WIFI_SSID}' sẽ tự kết nối sau reboot (DHCP)."
fi
log_info "Sau khi khởi động lại máy, đăng nhập tài khoản '${USER_NAME}' và chạy bước hậu cài:"
printf "\n  cd ~/.dotfiles && ./scripts/.local/bin/ks\n\n"
log_info "Bước đó chỉ cần chạy SAU khi đã vào được máy (SSH/LAN/Wi-Fi)."
if [ "$HAS_WIFI" = false ]; then
    log_info "Không có Wi-Fi: cắm dây LAN trước khi reboot để còn SSH vào máy."
fi
log_info "Chạy lệnh sau để unmount và khởi động lại máy:"
printf "\n  umount -R /mnt\n  reboot\n\n"
