# AGENTS.md — dotfiles-stow (branch `server-minimal`)

> **Mục tiêu branch**: chỉ dùng cho **server hosting tối giản** trên Debian/Ubuntu.
> Không có X11, window manager, audio, bluetooth, font GUI hay bất kỳ thành phần desktop nào.
> Mọi khẳng định dưới đây phản ánh đúng mã nguồn hiện có trong branch.

---

## 1. PHẠM VI & KIẾN TRÚC

Branch này là bản rút gọn của `main`, chỉ giữ các stow package CLI:

```
git/       ~/.config/git/{config,ignore}
lf/        ~/.config/lf/{lfrc,scope,cleaner,icons,shortcutrc}
nvim/      ~/.config/nvim/
scripts/   ~/.local/bin/{stow-safe,agent-guard,ka-setup-server,ks,setup-drivers/debian.sh}
shell/     ~/.bashrc, ~/.bash_profile, ~/.config/shell/{profile,aliasrc,inputrc,bm-dirs,bm-files}, direnv, starship.toml
tmux/      ~/.config/tmux/tmux.conf
zsh/       ~/.config/zsh/* (TUỲ CHỌN — không stow mặc định)
pkgs/      server.csv (Debian CLI packages)
```

Ngoài ra ở root: `install_debian.sh` (cài base OS qua debootstrap + GRUB UEFI).

**Không có**: `x11/`, `picom/`, `rofi/`, `dunst/`, `gtk/`, `theme/`, `suckless/`,
`hardware/`, `media/`, `input-method/`, `desktop/`, `brave/`, `pipewire/`, `hosts/`, `iso-profile/`.

---

## 2. LUỒNG CÀI ĐẶT

```
Live ISO UEFI (Debian/Ubuntu)
        │
        ▼
sudo ./install_debian.sh --disk /dev/nvme0n1 --yes
   (hoặc: sudo ./install_debian.sh --config install.conf --yes
          sudo ./install_debian.sh --disk /dev/sda --swap 0 --yes)
        │  debootstrap base OS, GRUB, EFI NVRAM entry, user, NetworkManager, locale
        ▼
reboot → đăng nhập user
        │
        ▼
git clone -b server-minimal <repo> ~/dotfiles-stow
cd ~/dotfiles-stow && ./scripts/.local/bin/ks
        │
        ├─ debian_setup_pkgs   → apt install từ pkgs/server.csv (56 gói CLI)
        ├─ setup_shell         → đảm bảo login shell là Bash
        ├─ setup_stow_server   → stow-safe shell git tmux nvim lf scripts
        ├─ setup_docker        → non-root + docker.socket activation
        ├─ setup_sys           → sysctl, zRAM, THP madvise, I/O scheduler udev
        ├─ setup_security      → UFW (SSH/80/443) + Fail2ban sshd
        ├─ setup_prune_services→ tắt bluetooth/cups/avahi/snapd/getty tty2-6
        └─ setup_locale_timezone → Asia/Ho_Chi_Minh + en_US.UTF-8
```

`ks` là symlink tương đối trỏ tới `ka-setup-server` (cùng thư mục).

---

## 3. QUY TẮC BẮT BUỘC DÀNH CHO AI AGENT

1. **Bất biến GNU Stow**: **CẤM `sed -i`** hoặc ghi đè lên bất kỳ file là symlink trỏ vào
   các gói Stow. Cấu hình động phải sinh ra trong `$XDG_RUNTIME_DIR` / drop-in và `source` tĩnh.
2. **Cấm `eval`** trên dữ liệu đọc từ file cấu hình hoặc input người dùng.
   Luôn dùng `while IFS= read -r line`.
3. **Không dùng `/tmp` cho state/socket/PID**: dùng `$XDG_RUNTIME_DIR/<app>/` (0700).
4. **Mọi script thay đổi cấu hình phải có dry-run `--check`** khi có thể.
5. **Chạy `./scripts/.local/bin/agent-guard`** trước khi kết thúc phiên.
6. **Một công cụ duy nhất cho mỗi chức năng**: không giữ bản sao Bash/Python song song.
7. **Không thêm lại thành phần desktop** (X11, WM, audio, bluetooth, font GUI) vào branch này.
8. **Không `dlopen` / nạp native ngoài vào tiến trình lõi**.

---

## 4. TỐI ƯU HIỆU NĂNG ĐANG ÁP DỤNG

| Hạng mục | Giá trị | Nguồn |
|-----------|---------|--------|
| zRAM | `zram-size=ram`, `zstd` (≤2 core dùng `lz4`), swap-priority 100 | `setup_sys` |
| sysctl VM | `page-cluster=0`, `swappiness=100`, `vfs_cache_pressure=50` | `setup_sys` |
| sysctl net | `somaxconn=65535`, `tcp_max_syn_backlog=65535`, `tcp_fastopen=3`, BBR + `fq` (fallback `fq_codel`) | `setup_sys` |
| fd/inotify | `fs.file-max=2097152`, `max_user_watches=524288` | `setup_sys` |
| THP | `madvise` + `defer` (chống micro-stutter) | `setup_sys` |
| I/O scheduler | HDD `bfq`, SATA SSD `mq-deadline`, NVMe `none` | `setup_sys` |
| Docker | `docker.socket` activation (không giữ daemon thường trực) | `setup_docker` |
| Shell | Bash history 50k, starship/zoxide/direnv cache tĩnh | `shell/.bashrc` |
| Services | Tắt bluetooth, cups, avahi, ModemManager, snapd, getty tty2-6 | `setup_prune_services` |

---

## 5. GHI CHÚ VẬN HÀNH

- **Shell**: mặc định **Bash** (login shell). `zsh/` là tuỳ chọn: cài `zsh` +
  `stow-safe zsh` + `chsh -s "$(command -v zsh)"` nếu muốn dùng.
- **Swap**: mặc định có phân vùng swap 4G. `SWAP_SIZE=0` (trong `install.conf`) hoặc
  `--swap 0` → **không tạo phân vùng swap**, `fstab` không có dòng swap; có verify
  fail-fast nếu vẫn thấy swap. `--print-config` xem trước cấu hình, `--check` dry-run.
- **Neovim**: config cần **≥ 0.11** (`winborder`, `vim.diagnostic.jump`).
  Debian 13 có 0.10.4, Debian 12 có 0.7.2 → `debian_setup_nvim` tự tải bản mới
  vào `~/.local` khi phiên bản APT < 0.11. Mặc định chỉ cài tool Mason không
  cần node/pip; đặt `KA_NVIM_FULL=1` để cài full stack (cần `nodejs`, `npm`,
  `python3-pip`, `python3-venv`).
- **Docker (Debian 13)**: `docker.io` chỉ là daemon; `docker-cli` được cài
  riêng trong `server.csv` vì trixie đã tách gói. `docker-compose` là Compose v2.
- **Debian 13 (trixie)**: đã đối chiếu — neovim 0.10.4 (bootstrap 0.11+),
  docker.io 26.1 + docker-cli, docker-compose 2.26, tree-sitter-cli 0.22.6,
  starship 1.22, eza 0.21, systemd-zram-generator 1.2, firmware-linux-free.
  `unrar-free` chỉ có lệnh `unrar-free` (lfrc đã fallback).
- **Firewall**: UFW mở SSH/80/443. Cần thêm port khác thì `sudo ufw allow <port>`.
- **Reboot** sau khi chạy `ks` để áp dụng shell, group docker và sysctl.
