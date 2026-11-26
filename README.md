# dotfiles-stow — `server-minimal`

Bản dotfiles **chỉ cho server hosting** (Debian/Ubuntu). Không X11, không desktop,
không audio/bluetooth/font GUI. Tối ưu cho hiệu năng và dấu chân nhỏ.

## Cài đặt

### 1. Cài base OS (từ Live ISO UEFI)

```bash
sudo ./install_debian.sh --disk /dev/nvme0n1 --yes
# dry-run an toàn:
sudo ./install_debian.sh --disk /dev/nvme0n1 --check
# xem cấu hình đã phân giải (không cần root, không ghi đĩa):
./install_debian.sh --print-config
```

Muốn khỏi nhớ tham số: copy file cấu hình mẫu rồi sửa.

```bash
cp install.conf.example install.conf
vi install.conf
sudo ./install_debian.sh --config install.conf --yes
# hoặc đặt install.conf cạnh script: sudo ./install_debian.sh --yes (tự nạp)
```

File cấu hình là `KEY=VALUE`, tham số dòng lệnh **luôn thắng** file.
Các khóa hợp lệ: `DISK`, `PROFILE`, `SWAP_SIZE`, `USER_NAME`, `USER_PASS`,
`HOSTNAME`, `TIMEZONE`, `SUITE`, `MIRROR`, `DOTFILES_REPO`, `DOTFILES_BRANCH`,
`WIFI_SSID`, `WIFI_PSK_FILE`, `SSH_KEY_FILE`, `SSH_PASSWORD_AUTH`,
`ALLOW_OFFLINE`, `AUTO_CONFIRM`.

### 1b. Không swap / chuẩn bị cho Kubernetes

Kubelet mặc định từ chối swap (`failSwapOn=true`), nên profile `k8s` **không tạo
phân vùng swap** và bật sẵn những thứ kubeadm cần:

```bash
sudo ./install_debian.sh --disk /dev/sda --profile k8s --yes
```

- `SWAP_SIZE` mặc định thành `0` (vẫn có thể ép `--swap 4G`, CLI thắng).
- Ghi `/etc/default/ka-server` với `KA_PROFILE=k8s`, `KA_SWAP=off` để `ks` không tạo zRAM.
- Tạo `/etc/modules-load.d/ka-k8s.conf` (`overlay`, `br_netfilter`) và
  `/etc/sysctl.d/99-ka-k8s.conf` (`ip_forward`, `bridge-nf-call-iptables/ip6tables`).

Muốn giữ swap cổ điển thì dùng `--profile server` (mặc định) hoặc `--swap 4G`.

Máy **không có console** (chỉ vào được qua mạng) phải truyền thêm Wi-Fi và SSH key,
nếu không sau reboot sẽ mất máy:

```bash
printf '%s' 'mat-khau-wifi' > /run/wifi.psk && chmod 600 /run/wifi.psk
sudo ./install_debian.sh --disk /dev/nvme0n1 \
  --user user --password 1 --hostname debian-stax-002 \
  --wifi-ssid "Akapro-5G" --wifi-psk-file /run/wifi.psk \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --yes
```

Installer chịu trách nhiệm **mọi thứ cần để còn truy cập được sau reboot**:

- `openssh-server` + `ssh-keygen -A` + `systemctl enable ssh` + drop-in hardening
- `wpasupplicant`, `wireless-regdb`, `iw` + firmware đúng hãng card (iwlwifi/realtek/atheros/brcm)
- profile NetworkManager `wifi-auto.nmconnection` (0600, DHCP) → tự kết nối
- `authorized_keys` nếu có `--ssh-key`, `PasswordAuthentication` theo `--no-password-auth`
- `systemd-timesyncd`, EFI fallback `\EFI\BOOT\BOOTX64.EFI` **kèm `grubx64.efi`/`mmx64.efi`**
  (thiếu `grubx64.efi` là shim không nạp được GRUB → máy không boot)
- EFI NVRAM entry `debian` được tạo/đưa lên đầu `BootOrder` nếu firmware chưa có
- bước verify fail-fast: thiếu gói/sshd/GRUB/fstab/profile → dừng, **không reboot**

Máy **không có card Wi-Fi**: installer bỏ qua toàn bộ phần Wi-Fi (không firmware, không
profile NetworkManager) và dùng Ethernet DHCP. Vì không còn đường dự phòng, installer
**dừng trước khi ghi đĩa** nếu Ethernet không có link (carrier=0) — trừ khi bạn thêm
`--allow-offline` và có KVM/màn hình để cứu hộ. `wpasupplicant`/`iw`/`wireless-regdb`
vẫn được cài để sau này cắm USB Wi-Fi là dùng được ngay, không cần mạng.

### 2. Cấu hình server (sau reboot)

Installer đã clone dotfiles vào `~/.dotfiles`:

```bash
cd ~/.dotfiles
./scripts/.local/bin/ks          # = ka-setup-server
```

`ks` chỉ lo phần **runtime** (cần kernel/systemd thật): `pkgs/server.csv`,
stow, Docker socket activation, sysctl/zRAM/THP/I-O scheduler, UFW + Fail2ban,
tắt dịch vụ thừa, timezone/locale. Login shell mặc định là **Bash**.

`ks` đọc profile do installer ghi ở `/etc/default/ka-server`:

| Khóa | Giá trị | Tác dụng |
|---|---|---|
| `KA_PROFILE` | `server` \| `k8s` | `k8s` → bật overlay/br_netfilter/ip_forward + bridge-nf |
| `KA_SWAP` | `zram` \| `off` | `off` → `swapoff -a`, xoá zram-generator, `vm.swappiness=0` |

Kiểm tra profile trước khi chạy: `./scripts/.local/bin/ks --check`.

## Thành phần

- `install_debian.sh` — debootstrap base OS + GRUB UEFI + user/locale.
- `install.conf.example` — mẫu file cấu hình cho installer (kể cả chế độ không swap).
- `pkgs/server.csv` — danh sách gói Debian tối giản.
- `scripts/.local/bin/ka-setup-server` (alias `ks`) — thiết lập post-install.
- `scripts/.local/bin/setup-drivers/debian.sh` — driver APT server-minimal.
- Stow packages: `shell`, `git`, `tmux`, `nvim`, `lf`, `scripts`.
- `zsh/` — tuỳ chọn, **không stow mặc định**.

## Kiểm tra sau cài

```bash
docker run --rm hello-world
systemctl status docker.socket
ufw status verbose
fail2ban-client status sshd
```

Xem [AGENTS.md](AGENTS.md) để biết chi tiết kiến trúc và quy tắc đóng góp.
