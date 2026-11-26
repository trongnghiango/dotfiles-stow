# Cài Debian 13 bằng tay — từng lệnh CLI (A → Z)

> Trích nguyên các lệnh từ `install_debian.sh` để chạy thủ công, không dùng script.
> Môi trường: boot **live USB UEFI** (Debian/Ubuntu live), có mạng, quyền root.
> Kết quả: ESP 1 GiB + root ext4, **không swap**, UEFI + GRUB, SSH bật sẵn.

---

## 0. Biến môi trường — sửa 4 dòng đầu cho khớp máy

```bash
export DISK=/dev/sda                  # ổ đích (KIỂM TRA KỸ: đây là ổ sẽ bị xoá)
export SUITE=trixie                   # Debian 13
export MIRROR=http://deb.debian.org/debian
export TARGET_HOSTNAME=debian
export TARGET_TZ=Asia/Ho_Chi_Minh
export NEW_USER=user
export NEW_PASS='1'
export ESP_END_MIB=1025               # ESP từ 1MiB → 1025MiB (1 GiB)
```

Kiểm tra trước khi làm gì tiếp:

```bash
sudo -v
lsblk -o NAME,SIZE,MODEL,FSTYPE "$DISK"        # phải đúng ổ, không phải USB đang boot
findmnt -no SOURCE /                            # phải KHÁC $DISK
[ -d /sys/firmware/efi ] && echo "UEFI OK"      # bắt buộc UEFI
curl -sSI "$MIRROR/dists/$SUITE/Release" | head -1   # phải 200
date -u                                          # giờ phải đúng, lệch là APT từ chối chữ ký
```

Cài công cụ cần thiết trên live:

```bash
sudo apt-get update
sudo apt-get install -y debootstrap parted dosfstools e2fsprogs gdisk efibootmgr
```

---

## 1. Xoá sạch chữ ký + bảng phân vùng cũ

```bash
sudo swapoff -a 2>/dev/null || true
sudo umount -R /mnt 2>/dev/null || true

# xoá chữ ký filesystem trên từng phân vùng cũ (nếu có)
for p in $(lsblk -nrpo NAME "$DISK" | tail -n +2); do
    sudo wipefs -a "$p" 2>/dev/null || true
done

sudo sgdisk --zap-all "$DISK"
sudo wipefs -a "$DISK"
sudo dd if=/dev/zero of="$DISK" bs=1M count=10 status=progress conv=notrunc
sudo partprobe "$DISK"; sudo udevadm settle
```

---

## 2. Tạo GPT: ESP 1 GiB + root phần còn lại (KHÔNG swap)

```bash
sudo parted -s "$DISK" mklabel gpt
sudo parted -s "$DISK" mkpart ESP  fat32 1MiB ${ESP_END_MIB}MiB
sudo parted -s "$DISK" set 1 esp on
sudo parted -s "$DISK" mkpart root ext4  ${ESP_END_MIB}MiB 100%
sudo partprobe "$DISK"; sudo udevadm settle
sudo parted -s "$DISK" unit MiB print
```

Nếu ổ NVMe tên kiểu `/dev/nvme0n1` thì phân vùng là `/dev/nvme0n1p1`, `/dev/nvme0n1p2`. Đặt lại:

```bash
case "$DISK" in
  *[0-9]) export P1="${DISK}p1"; export P2="${DISK}p2" ;;
  *)      export P1="${DISK}1";  export P2="${DISK}2"  ;;
esac
```

---

## 3. Format + mount

```bash
sudo mkfs.vfat -F 32 "$P1"
sudo mkfs.ext4 -F "$P2"

sudo mkdir -p /mnt
sudo mount "$P2" /mnt
sudo mkdir -p /mnt/boot/efi
sudo mount "$P1" /mnt/boot/efi
```

---

## 4. Debootstrap base system

```bash
sudo debootstrap --arch=amd64 "$SUITE" /mnt "$MIRROR"
```

---

## 5. fstab (UUID) + efivarfs

```bash
ROOT_UUID=$(sudo blkid -s UUID -o value "$P2")
ESP_UUID=$(sudo blkid -s UUID -o value "$P1")

sudo tee /mnt/etc/fstab >/dev/null <<EOF
# <file system>        <mount point>  <type>   <options>                                                <dump> <pass>
UUID=${ROOT_UUID}      /              ext4     rw,relatime,errors=remount-ro                            0      1
UUID=${ESP_UUID}       /boot/efi      vfat     rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro  0  2
efivarfs               /sys/firmware/efi/efivars  efivarfs  defaults,nofail,nosuid,nodev,noexec             0      0
EOF
```

> Dòng `efivarfs` là bắt buộc trên Debian: systemd của Debian không tự mount efivarfs, thiếu nó thì `efibootmgr`/`grub-install` không ghi được NVRAM.

---

## 6. DNS + apt sources

```bash
sudo cp -L /etc/resolv.conf /mnt/etc/resolv.conf

sudo tee /mnt/etc/apt/sources.list >/dev/null <<EOF
deb ${MIRROR} ${SUITE} main contrib non-free non-free-firmware
deb ${MIRROR} ${SUITE}-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security ${SUITE}-security main contrib non-free non-free-firmware
EOF
```

---

## 7. Vào chroot (bind mount có `--rbind` + efivarfs)

```bash
sudo mount --rbind /dev  /mnt/dev  && sudo mount --make-rslave /mnt/dev
sudo mount --rbind /proc /mnt/proc && sudo mount --make-rslave /mnt/proc
sudo mount --rbind /sys  /mnt/sys  && sudo mount --make-rslave /mnt/sys
sudo mount --rbind /run  /mnt/run  && sudo mount --make-rslave /mnt/run

# efivarfs phải nhìn thấy trong chroot (grub-install cần ghi NVRAM)
ls /mnt/sys/firmware/efi/efivars | head -3

sudo chroot /mnt /bin/bash
```

Từ đây mọi lệnh chạy **trong** chroot:

```bash
export DEBIAN_FRONTEND=noninteractive
export TARGET_HOSTNAME=debian NEW_USER=user NEW_PASS='1' TARGET_TZ=Asia/Ho_Chi_Minh
```

---

## 8. Kernel + gói cơ sở

```bash
apt-get update

apt-get install -y --no-install-recommends \
  linux-image-amd64 linux-headers-amd64 grub-efi-amd64 efibootmgr \
  locales tzdata systemd-timesyncd network-manager wpasupplicant wireless-regdb iw \
  openssh-server sudo git curl wget stow neovim build-essential ca-certificates \
  intel-microcode firmware-realtek firmware-linux-free

# Nếu Secure Boot BẬT, cài thêm bản ký:
# apt-get install -y shim-signed grub-efi-amd64-signed

systemctl enable systemd-timesyncd
```

---

## 9. Timezone, locale, hostname, mạng

```bash
ln -sf "/usr/share/zoneinfo/${TARGET_TZ}" /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8
echo 'LANG=en_US.UTF-8' > /etc/default/locale

echo "${TARGET_HOSTNAME}" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${TARGET_HOSTNAME}.localdomain ${TARGET_HOSTNAME}
EOF

systemctl enable NetworkManager
```

---

## 10. Cài GRUB EFI + fallback

```bash
# Secure Boot TẮT:
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian --recheck
# Secure Boot BẬT: thêm --uefi-secure-boot

update-grub

# Fallback cho firmware chỉ boot \EFI\BOOT\BOOTX64.EFI
mkdir -p /boot/efi/EFI/BOOT
for f in shimx64.efi grubx64.efi mmx64.efi fbx64.efi; do
    [ -f "/boot/efi/EFI/debian/$f" ] && cp "/boot/efi/EFI/debian/$f" "/boot/efi/EFI/BOOT/$f"
done
if [ -f /boot/efi/EFI/debian/shimx64.efi ]; then
    cp /boot/efi/EFI/debian/shimx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
else
    cp /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
fi
```

> Thiếu `grubx64.efi` cạnh `BOOTX64.EFI` là shim không nạp được GRUB → firmware báo `3F0`.

---

## 11. User + sudo + SSH

```bash
id "${NEW_USER}" >/dev/null 2>&1 || useradd -m -s /bin/bash "${NEW_USER}"
usermod -aG sudo "${NEW_USER}"
printf '%s:%s\n' "${NEW_USER}" "${NEW_PASS}" | chpasswd
printf 'root:%s\n' "${NEW_PASS}" | chpasswd

echo '%sudo ALL=(ALL:ALL) ALL' > /etc/sudoers.d/99-sudo-group
chmod 0440 /etc/sudoers.d/99-sudo-group

ssh-keygen -A
systemctl enable ssh
mkdir -p /run/sshd

cat > /etc/ssh/sshd_config.d/10-hardening.conf <<'EOF'
X11Forwarding no
ClientAliveInterval 60
ClientAliveCountMax 3
PasswordAuthentication yes
EOF
chmod 0644 /etc/ssh/sshd_config.d/10-hardening.conf
```

Nếu có SSH public key (khuyến nghị):

```bash
install -d -m 0700 -o "${NEW_USER}" -g "${NEW_USER}" "/home/${NEW_USER}/.ssh"
# dán key rồi: install -m 0600 -o ... /tmp/id.pub /home/${NEW_USER}/.ssh/authorized_keys
```

---

## 12. Kiểm tra hậu cài (trong chroot, trước khi thoát)

```bash
ls /boot/vmlinuz-* /boot/initrd.img-* /boot/grub/grub.cfg      # phải có đủ
ls /boot/efi/EFI/debian/grubx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI
grep -E 'UUID|efivarfs' /etc/fstab
ssh-keygen -A && sshd -t && echo "sshd OK"
grep -q swap /etc/fstab && echo "CẢNH BÁO: còn swap" || echo "không swap OK"
```

Thoát chroot và gỡ mount:

```bash
exit

for mp in /mnt/sys/firmware/efi/efivars /mnt/sys /mnt/proc /mnt/dev/pts /mnt/dev /mnt/run; do
    mountpoint -q "$mp" && sudo umount -R "$mp" 2>/dev/null
done
```

---

## 13. Tạo EFI boot entry (từ live, không trong chroot)

```bash
sudo mount -t efivarfs efivarfs /sys/firmware/efi/efivars 2>/dev/null || true

LOADER='\EFI\debian\grubx64.efi'
[ -f /mnt/boot/efi/EFI/debian/shimx64.efi ] && LOADER='\EFI\debian\shimx64.efi'

# xoá entry debian cũ (nếu có) rồi tạo lại
for e in $(sudo efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} debian.*/\1/p'); do
    sudo efibootmgr -b "$e" -B
done
sudo efibootmgr -c -d "$DISK" -p 1 -L debian -l "$LOADER"

ENTRY=$(sudo efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)\*\{0,1\} debian.*/\1/p' | head -1)
CUR=$(sudo efibootmgr | sed -n 's/^BootOrder: //p')
NEW=$(printf '%s' "$CUR" | tr ',' '\n' | grep -v "^${ENTRY}$" | paste -sd, -)
sudo efibootmgr -o "${ENTRY},${NEW}"
sudo efibootmgr | head -6
```

---

## 14. Kiểm tra lần cuối + reboot

```bash
sudo sgdisk -v "$DISK"        # phải "No problems found"
sudo blkid "$P1" "$P2"        # ESP vfat + root ext4, UUID khớp fstab
sudo e2fsck -fn "$P2"         # phải sạch

sudo umount -R /mnt
sudo reboot
```

Rút USB trước khi reboot. Nếu firmware hỏi `Authenticate to Save/Restore GPT` → chọn **1**.

---

## 15. Sau khi vào Debian (kiểm tra + tinh chỉnh)

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub   # host key đã sinh
systemctl status ssh --no-pager
ip -4 a; ip r
timedatectl                                        # phải "synchronized: yes" sau ~1 phút
df -h /
free -h

# nếu dùng VM/passthrough (IOMMU): dùng drop-in, không sửa trực tiếp /etc/default/grub
echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"' | sudo tee /etc/default/grub.d/99-iommu.cfg
sudo update-grub

# công cụ theo dõi
sudo apt install -y lm-sensors smartmontools
sudo sensors-detect --auto
sudo smartctl -H /dev/sda
```

---

## Ghi chú nhanh

| Tình huống | Xử lý |
|---|---|
| APT báo `Not live until ...` | giờ hệ thống sai → `sudo date -s "$(curl -sI https://deb.debian.org | awk -F': ' 'tolower($1)=="date"{print $2}' | tr -d '\r')"` |
| Firmware báo `3F0` | kiểm tra `EFI/BOOT/grubx64.efi` có tồn tại; nếu Secure Boot bật mà shim lỗi → tắt Secure Boot |
| `efibootmgr: EFI variables are not supported` | `mount -t efivarfs efivarfs /sys/firmware/efi/efivars` |
| Muốn có swap | thêm phân vùng giữa ESP và root: `parted mkpart swap linux-swap 1025MiB 5121MiB`, `mkswap`, thêm dòng fstab `UUID=… none swap sw 0 0` |
| Muốn cài nhanh không gõ tay | dùng `sudo ./install_debian.sh --config install.conf --yes` (script làm đúng các bước trên) |
