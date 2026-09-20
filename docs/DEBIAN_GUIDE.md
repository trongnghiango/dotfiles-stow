# DEBIAN_GUIDE.md — Hướng dẫn Triển khai và Kiểm thử trên Debian Linux

> **Kiến trúc**: Omarchy-X11 Layered Profile Architecture  
> **Nhánh phát triển**: `feature/debian-support`  
> **Hỗ trợ**: Debian 12 (Bookworm), Debian 13 (Trixie), Debian Sid, Ubuntu 24.04+

---

## 1. Tổng quan Kiến trúc Đa Distro

Hệ thống dotfiles được thiết kế theo mô hình **Single Source of Truth** không phân mảnh cấu hình:
- **Tầng 1 — Cấu hình dùng chung (85%)**: Neovim, Tmux, Git, Shell (Zsh), Theme (palettes, templates, hooks), Rofi, Dunst, Fontconfig và mã nguồn C thuần DWM 6.8 / ST (`suckless/`).
- **Tầng 2 — Quản lý Runtime (Mise)**: Toàn bộ SDKs (Node, Rust, Go, Python, Bun, PNPM) chạy độc lập trong user space qua `~/.config/mise/config.toml`.
- **Tầng 3 — Zero-cost Compatibility Symlinks**: Tự động giải quyết xung đột tên binary trên Debian (`batcat` → `bat`, `fdfind` → `fd`) vào `~/.local/bin/`, không tốn bất kỳ chu kỳ CPU nào lúc runtime.
- **Tầng 4 — Drivers độc lập**:
  - Arch Linux: `pkgs/arch.csv` + `scripts/.local/bin/setup-drivers/arch.sh` (Pacman / AUR)
  - Debian Linux: `pkgs/debian.csv` + `scripts/.local/bin/setup-drivers/debian.sh` (APT / Build headers / Bootstrap)

---

## 2. Quy trình Kiểm thử trên máy / máy ảo Debian (Clean Install)

### Bước 1: Chuẩn bị môi trường Debian tối giản (Minimal Install)
Cài đặt Debian (Network Install hoặc Minimal) không kèm Desktop Environment (chỉ chọn Standard System Utilities và SSH Server nếu cần).

### Bước 2: Clone repository trên nhánh `feature/debian-support`
```bash
# Cài đặt git nếu chưa có
sudo apt update && sudo apt install -y git

# Clone repo
git clone -b feature/debian-support https://github.com/trongnghiango/dotfiles-stow.git ~/dotfiles-stow
cd ~/dotfiles-stow
```

### Bước 3: Chạy thiết lập tự động qua `ka-setup`
```bash
# 1. Cài đặt các gói cốt lõi và build dependencies cho Suckless
./scripts/.local/bin/ka-setup pkgs core

# 2. Hoặc chạy toàn bộ quy trình cấu hình (pkgs -> shell -> stow -> suckless -> pam -> brave)
./scripts/.local/bin/ka-setup all
```

*Trong quá trình chạy:*
- `ka-setup` tự động nhận diện `ID=debian` từ `/etc/os-release`.
- Nạp driver `setup-drivers/debian.sh`.
- Cài đặt toàn bộ build headers cho DWM 6.8 (`libx11-dev`, `libxft-dev`, `libxinerama-dev`, `libimlib2-dev`, `libxcb1-dev`, `libharfbuzz-dev`, v.v.).
- Tạo symlink `bat` và `fd` trong `~/.local/bin/`.
- Tự động biên dịch `dwm`, `st`, `dmenu`, `dwmblocks` từ thư mục `suckless/` cài vào `/usr/local/bin/`.
- Cấu hình GNU Stow triển khai an toàn qua `stow-safe`.

### Bước 4: Kiểm tra sức khỏe hệ thống
```bash
ka doctor
```
Lệnh này sẽ kiểm tra:
- Các binary Suckless (`/usr/local/bin/dwm`, `st`, `dmenu`, `dwmblocks`)
- X11 tools (`picom`, `maim`, `slop`, `xclip`, `tesseract`)
- PipeWire Audio stack (`pipewire`, `wireplumber`)
- Dev runtimes (`mise`, `nvim`, `tmux`, `zsh`)

### Bước 5: Khởi động giao diện DWM
Đăng xuất và đăng nhập lại trên TTY1 (hoặc gõ `startx`), file `x11/.config/x11/xinitrc` sẽ tự động nạp `xinitrc.debian` để khởi động PipeWire và Polkit của Debian.

---

## 3. Danh sách kiểm tra sau khi kiểm thử thành công (Checklist Merge to Main)

- [ ] Trình duyệt Brave khởi động mượt mà với GPU decode.
- [ ] DWM 6.8 hiển thị đầy đủ tags, icon bàn tay tương tác `XC_hand2`.
- [ ] Phím tắt mở cửa sổ nổi ở tâm `Super + Shift + Space` và Fullscreen `Super + F` hoạt động chuẩn xác.
- [ ] Các thẻ popup `ka pop <module>` (volume, clock, battery, cpu, mem, net, forecast) phản hồi < 2ms qua socket daemon.
- [ ] Trình chọn ứng dụng mặc định một chạm `ka default` (`Super + Ctrl + D`) mở giao diện Rofi mượt mà.
- [ ] Trình quản lý clipboard GTK3 Master-Detail `ka clip` (`Super + V`) mở nổi ở giữa màn hình với tỷ lệ 2 : 3.
- [ ] Bộ engine giao diện `ka theme [nord|catppuccin-mocha|gruvbox-dark]` nạp CSS động mượt mà cho cả GTK, Brave và Qt.
- [ ] Bộ gõ tiếng Việt Fcitx5 hoạt động ổn định trên cả terminal `st` lẫn ứng dụng GTK.
- [ ] Khi mọi thứ đã ổn định, merge `feature/debian-support` vào `main`.
