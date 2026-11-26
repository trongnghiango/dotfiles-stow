#!/usr/bin/env bash
# ==============================================================================
# fix-gpt — Khôi phục bảng phân vùng GPT cho máy đã cài bằng install_debian.sh
#
# Tình huống: firmware HP hỏi "Authenticate to Save/Restore GPT" và chọn nhầm
# "2" (overwrite HDD GPT with backup GPT) → bảng phân vùng quay về layout cũ,
# mất phân vùng root mới → không boot được. Dữ liệu trên đĩa vẫn còn.
#
# Layout đích (do installer tạo):
#   sda1  1MiB   .. 1025MiB   vfat  ESP
#   sda2  1025MiB.. 100%      ext4  root
#
# Dùng:
#   sudo bash fix-gpt.sh            # chỉ kiểm tra, không ghi
#   sudo bash fix-gpt.sh --yes      # sửa thật (có backup GPT cũ)
# ==============================================================================
set -euo pipefail
IFS=$'\n\t'

DISK="${DISK:-/dev/sda}"
ESP_END_MIB=1025
EXPECTED_ROOT_UUID="${EXPECTED_ROOT_UUID:-d0ccdedd-6087-4402-84cf-60b7ba33f67f}"
APPLY=false
[ "${1:-}" = "--yes" ] && APPLY=true

log()  { printf '[fix-gpt] %s\n' "$*"; }
warn() { printf '[fix-gpt] WARN: %s\n' "$*" >&2; }
die()  { printf '[fix-gpt] ERROR: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "chạy bằng sudo/root"
[ -d /sys/firmware/efi ] || die "phải boot ở chế độ UEFI (live USB UEFI)"
[ -b "$DISK" ] || die "không thấy $DISK"

MODEL=$(lsblk -dno MODEL "$DISK" | tr -s ' ' || true)
log "Ổ đích: $DISK ($MODEL)"
echo "$MODEL" | grep -qi kingston || die "model không phải KINGSTON — kiểm tra lại DISK"

ROOT_SRC=$(findmnt -no SOURCE / 2>/dev/null || true)
case "$ROOT_SRC" in
    "$DISK"|"$DISK"*) die "không chạy khi / đang nằm trên $DISK" ;;
esac

# --- 1. Xác nhận ext4 mới vẫn còn ở offset 1025MiB (trước khi động vào bảng) ---
SUPER_OFFSET=$(( ESP_END_MIB * 1024 * 1024 + 1080 ))   # superblock 1024B + magic 0x38
MAGIC=$(dd if="$DISK" bs=1 count=2 skip="$SUPER_OFFSET" status=none | od -An -tx1 | tr -d ' \n')
log "ext4 magic @1025MiB+1080 = $MAGIC (mong đợi 53ef)"
[ "$MAGIC" = "53ef" ] || die "không thấy ext4 magic — DỪNG, không sửa gì (dữ liệu không ở vị trí mong đợi)"

log "Trạng thái GPT hiện tại:"
sgdisk -v "$DISK" 2>/dev/null || parted -s "$DISK" unit MiB print

if [ "$APPLY" != true ]; then
    log "Dry-run: chưa ghi gì. Chạy lại với --yes để sửa."
    exit 0
fi

# --- 2. Công cụ cần thiết ---
if ! command -v sgdisk >/dev/null || ! command -v efibootmgr >/dev/null; then
    log "Cài gdisk + efibootmgr..."
    if command -v apt-get >/dev/null; then
        apt-get update -qq >/dev/null 2>&1 || true
        apt-get install -y --no-install-recommends gdisk efibootmgr >/dev/null 2>&1 || \
            warn "không cài được gdisk/efibootmgr (thiếu mạng?)"
    fi
fi

# --- 3. Backup bảng cũ ---
STAMP=$(date +%Y%m%d-%H%M%S)
if command -v sgdisk >/dev/null; then
    sgdisk -b "/root/gpt-backup-$STAMP.bin" "$DISK" >/dev/null && \
        log "Đã backup GPT cũ: /root/gpt-backup-$STAMP.bin"
fi
sfdisk -d "$DISK" > "/root/gpt-backup-$STAMP.sfdisk" 2>/dev/null || true

# --- 4. Tạo lại bảng đúng layout ---
log "Tạo lại GPT: ESP 1..${ESP_END_MIB}MiB + root ${ESP_END_MIB}MiB..100%"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB "${ESP_END_MIB}MiB"
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart root ext4 "${ESP_END_MIB}MiB" 100%
partprobe "$DISK" 2>/dev/null || true
udevadm settle 2>/dev/null || sleep 2

ROOT_DEV="${DISK}2"
ESP_DEV="${DISK}1"
[ -b "$ROOT_DEV" ] || die "không thấy $ROOT_DEV sau khi tạo bảng"

# --- 5. Đối chiếu UUID filesystem (bằng chứng dữ liệu còn nguyên) ---
ROOT_UUID_NOW=$(blkid -s UUID -o value "$ROOT_DEV" 2>/dev/null || true)
log "UUID $ROOT_DEV = ${ROOT_UUID_NOW:-<rỗng>}"
if [ "$ROOT_UUID_NOW" != "$EXPECTED_ROOT_UUID" ]; then
    warn "UUID không khớp mong đợi ($EXPECTED_ROOT_UUID)."
    warn "Khôi phục bảng cũ bằng: sfdisk $DISK < /root/gpt-backup-$STAMP.sfdisk"
    die "dừng để tránh ghi đè"
fi

# --- 6. Sửa vị trí backup GPT nếu lệch (nguyên nhân firmware hỏi lại mỗi lần) ---
if command -v sgdisk >/dev/null; then
    sgdisk -e "$DISK" >/dev/null 2>&1 || true
    log "Kiểm tra lại tính nhất quán GPT:"
    sgdisk -v "$DISK" || warn "sgdisk báo vấn đề (xem log trên)"
fi

# --- 7. Kiểm tra nội dung ESP + fstab ---
mkdir -p /mnt/fix-esp /mnt/fix-root
mount "$ESP_DEV" /mnt/fix-esp || die "không mount được ESP"
mount "$ROOT_DEV" /mnt/fix-root || die "không mount được root"
FIX_FAIL=0
for f in EFI/debian/shimx64.efi EFI/debian/grubx64.efi EFI/BOOT/BOOTX64.EFI EFI/BOOT/grubx64.efi; do
    if [ ! -f "/mnt/fix-esp/$f" ]; then
        echo "  [FAIL] ESP thiếu $f"; FIX_FAIL=1
    fi
done
for f in boot/grub/grub.cfg etc/fstab etc/default/grub; do
    if [ ! -e "/mnt/fix-root/$f" ]; then
        echo "  [FAIL] root thiếu /$f"; FIX_FAIL=1
    fi
done
if ! ls /mnt/fix-root/boot/vmlinuz-* >/dev/null 2>&1; then
    echo "  [FAIL] root thiếu /boot/vmlinuz-*"; FIX_FAIL=1
fi
if ! ls /mnt/fix-root/boot/initrd.img-* >/dev/null 2>&1; then
    echo "  [FAIL] root thiếu /boot/initrd.img-*"; FIX_FAIL=1
fi
grep -q efivars /mnt/fix-root/etc/fstab || \
    printf 'efivarfs\t/sys/firmware/efi/efivars\tefivarfs\tdefaults,nofail,nosuid,nodev,noexec\t0\t0\n' \
        >> /mnt/fix-root/etc/fstab
sync
umount /mnt/fix-esp /mnt/fix-root

if [ "$FIX_FAIL" -ne 0 ]; then
    die "có file boot bị thiếu — không tự sửa, cần cài lại hoặc kiểm tra tay"
fi

# --- 8. Tạo lại EFI boot entry theo bảng mới ---
if command -v efibootmgr >/dev/null; then
    mountpoint -q /sys/firmware/efi/efivars || \
        mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || \
        die "không mount được efivarfs — không tạo được EFI entry"
    for e in $(efibootmgr 2>/dev/null | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} debian.*/\1/p'); do
        efibootmgr -b "$e" -B >/dev/null 2>&1 || true
        log "Đã xoá entry cũ Boot$e"
    done
    efibootmgr -c -d "$DISK" -p 1 -L debian -l '\EFI\debian\shimx64.efi' >/dev/null || \
        die "không tạo được EFI entry"
    ENTRY=$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} debian.*/\1/p' | head -1)
    CUR=$(efibootmgr | sed -n 's/^BootOrder: //p' | head -1)
    NEW=$(printf '%s' "$CUR" | tr ',' '\n' | grep -v "^${ENTRY}$" | paste -sd, -)
    efibootmgr -o "${ENTRY},${NEW}" >/dev/null || warn "không đặt được BootOrder"
    log "EFI entry:"
    efibootmgr | sed -n '1,6p'
else
    warn "không có efibootmgr — firmware sẽ dùng fallback \\EFI\\BOOT\\BOOTX64.EFI"
fi

sync
cat <<DONE

[fix-gpt] XONG. Bảng phân vùng:
$(parted -s "$DISK" unit MiB print 2>/dev/null || lsblk -o NAME,SIZE,FSTYPE "$DISK")

Bước tiếp theo:
  1. RÚT USB Ventoy ra (quan trọng: để firmware không boot live nữa)
  2. reboot
  3. Nếu firmware lại hỏi "Authenticate to Save/Restore GPT" → chọn 1
     (overwrite BACKUP GPT with HDD GPT), TUYỆT ĐỐI không chọn 2
DONE
