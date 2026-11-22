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
shell/     ~/.config/shell/{profile,aliasrc,inputrc,bm-dirs,bm-files}, direnv, starship.toml
tmux/      ~/.config/tmux/tmux.conf
zsh/       ~/.config/zsh/{.zshrc,.zprofile,env.zsh,functions.zsh}, ~/.zshenv
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
        │  debootstrap base OS, GRUB, user, NetworkManager, locale/timezone
        ▼
reboot → đăng nhập user
        │
        ▼
git clone -b server-minimal <repo> ~/dotfiles-stow
cd ~/dotfiles-stow && ./scripts/.local/bin/ks
        │
        ├─ debian_setup_pkgs   → apt install từ pkgs/server.csv (56 gói CLI)
        ├─ setup_shell         → chsh sang Zsh (nếu có zsh)
        ├─ setup_stow_server   → stow-safe shell zsh git tmux nvim lf scripts
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
| Shell | Zsh completion/starship/zoxide có cache tĩnh 24h | `zsh/.zshrc` |
| Services | Tắt bluetooth, cups, avahi, ModemManager, snapd, getty tty2-6 | `setup_prune_services` |

---

## 5. GHI CHÚ VẬN HÀNH

- **Shell**: mặc định chuyển sang Zsh. Nếu muốn giữ Bash, bỏ qua bước
  `setup_shell` (hoặc sửa hàm này trả về 0) — branch không cung cấp `.bashrc`.
- **Neovim**: Debian bookworm có 0.7.2; `debian_setup_nvim` tự tải bản mới
  (≥0.9) vào `~/.local` nếu phiên bản APT quá cũ.
- **Docker compose**: dùng gói `docker-compose` của Debian; nếu bản distro
  không còn gói này, script sẽ cảnh báo và bỏ qua từng gói.
- **Firewall**: UFW mở SSH/80/443. Cần thêm port khác thì `sudo ufw allow <port>`.
- **Reboot** sau khi chạy `ks` để áp dụng shell, group docker và sysctl.
