# dotfiles-stow — `server-minimal`

Bản dotfiles **chỉ cho server hosting** (Debian/Ubuntu). Không X11, không desktop,
không audio/bluetooth/font GUI. Tối ưu cho hiệu năng và dấu chân nhỏ.

## Cài đặt

### 1. Cài base OS (từ Live ISO UEFI)

```bash
sudo ./install_debian.sh --disk /dev/nvme0n1 --yes
# dry-run an toàn:
sudo ./install_debian.sh --disk /dev/nvme0n1 --check
```

### 2. Cấu hình server (sau reboot)

```bash
git clone -b server-minimal https://github.com/trongnghiango/dotfiles-stow.git ~/dotfiles-stow
cd ~/dotfiles-stow
./scripts/.local/bin/ks          # = ka-setup-server
```

`ks` sẽ cài `pkgs/server.csv` (54 gói CLI), stow các package CLI, cấu hình
Docker socket activation, sysctl/zRAM/THP/I-O scheduler, UFW + Fail2ban,
tắt dịch vụ thừa, và đặt timezone/locale. Login shell mặc định là **Bash**.

## Thành phần

- `install_debian.sh` — debootstrap base OS + GRUB UEFI + user/locale.
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
