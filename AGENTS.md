# AGENTS.md — dotfiles

Personal dotfiles managed with **GNU Stow** + Git. Primary: **Arch Linux** + **DWM** (startx, no DM). Also runs on NixOS (`thinkbox`) and Void.

> [!IMPORTANT]
> **X11 Omarchy Philosophy**: Nhánh `main` này được thiết kế lại dựa trên triết lý sạch sẽ, tối ưu của Omarchy OS (DHH), nhưng giữ nguyên công nghệ X11/DWM (Native C) để đạt hiệu năng tối đa.
> Mọi AI Assistant khi làm việc với repository này **BẮT BUỘC ĐỌC** file `OMARCHY_X11_HANDOFF.md` để hiểu kiến trúc.

## Structure

Each top-level directory is a Stow package containing `$HOME`-relative paths (23 packages total):

| Package | What |
|---------|------|
| `shell/` | profile, aliasrc, shortcutrc, inputrc, mise/config.toml, starship.toml |
| `zsh/` | .zshrc, .zprofile (startx hook on tty1), env.zsh (mise activate) |
| `nvim/` | init.lua (modularized with neovide.lua), lua/{core,plugins,utils}/ — fully tracked |
| `tmux/` | prefix Ctrl+Space, vi nav, escape-time 0 |
| `x11/` | xinitrc (D-Bus → DWM), xprofile (GTK file chooser configs), xresources (#if __has_include) |
| `suckless/`| Source code của DWM, ST, Dmenu, Dwmblocks (tự động compile qua `ka-setup suckless`) |
| `scripts/` | `~/.local/bin` — Các công cụ hệ thống chia gọn vào `dwmblocks-scripts` và `dmenu-scripts` |
| `theme/` | Theme system (`theme-set`: 1 file màu → generate Xresources, Rofi, Dunst, hooks) |
| `desktop/` | XDG mimeapps.list, user-dirs.dirs, custom .desktop handlers (file, img, pdf, text, video) |
| `input-method/` | Fcitx5 + Bamboo bộ gõ tiếng Việt (hotkeys, profile, classicui) |
| `yay/` | yay AUR helper config (cleanafter, removemake) |
| `dunst/` | Dunst notification daemon config (hỗ trợ managed block tự động đổi màu) |
| `rofi/` | Rofi app launcher & window switcher configs (tỉ lệ vàng 580px, font 11pt, icon 20px) |
| `picom/` | Picom compositor config tối ưu Low-Latency (vsync glx, use-damage, tắt blur/fading) |
| `gtk/` | GTK 2/3/4 settings (Adwaita Base + Dynamic CSS Injection, Papirus-Dark, bookmarks) |
| `fontconfig/` | Fontconfig rules (loại bỏ font bitmap) |
| `nsxiv/` | Nsxiv image viewer keybinds |
| `brave/` | Brave browser flags config (X11 + HD4000 GPU decode) |
| `pipewire/` | RNNoise AI real-time stereo noise suppression cho microphone |
| `media/` | mpv, ncmpcpp, mpd configs |
| `opencode/` | 9Router gateway config, 3 combo tiers (KhaBoDo, KhaSimple, KhaThinking) |
| `git/` | gitconfig with delta diff, aliases, smart pull/push/fetch, rerere |
| `nixos/` | flake.nix, hosts/thinkbox/, home/home.nix |

## Key commands / workflow

- **Unified System CLI (`ka`):**
  - `ka doctor` — Chẩn đoán toàn diện sức khỏe, binary, audio, theming, dev runtimes và ka-pop
  - `ka dev [setup|status|update]` — Quản lý toàn bộ dev SDKs (Node, Python, Go, Rust, Bun, PNPM) qua Mise
  - `ka ocr` — Bóc tách chữ trên màn hình (In-memory OCR, song ngữ Anh-Việt) vào Clipboard
  - `ka theme [nord|gruvbox-dark|catppuccin-mocha]` — Đổi theme toàn diện, hot-reload tức thì
  - `ka default [show|set <cat> <app>]` — Quản lý & chọn ứng dụng mặc định một chạm (Rofi / CLI)
  - `ka clip [menu|daemon|clear|status]` — Quản lý lịch sử clipboard tỷ lệ 2 : 3 (Text đầy đủ & Ảnh phóng to) qua GTK3 native
  - `ka pop <module>` — Bật/Tắt thẻ popup Omarchy Native C (`ka-pop`: < 0.8ms cold launch, 0MB idle RAM)
  - `ka daemon [start|stop|restart|status]` — Quản lý tiến trình nền hợp nhất ka-daemon
  - `ka night [on|off|toggle|status]` — Bật/Tắt chế độ làm việc ban đêm (Lọc ánh sáng xanh 4000K + giảm sáng 35%)
  - `ka notify [center|dnd|clear|status|test]` — Quản lý thông báo, DND và mở Notification Center Right Sidebar
  - `ka dns [dhcp|cloudflare|google|custom <ip>]` — Chuyển đổi DNS server 1 chạm
  - `ka record [toggle|status]` — Quay video màn hình
  - `ka setup [all|suckless|stow|pkgs|sys]` — Tự động hóa triển khai hệ thống (Arch, Debian, Void, Fedora)
- **DWM 6.8 Native C Core & Zero-Fork Statusbar (dwmblocks):**
  - Nâng cấp lên DWM 6.8 với các bản vá bảo mật upstream (heap overflow, EWMH focus, format 32 check, underflow guard)
  - **Zero-Fork Statusbar (9/9 Blocks In-Process C)**: `ka-clock`, `ka-forecast`, `sb-record`, `ka-volume`, `ka-battery`, `ka-network`, `ka-cpu`, `ka-memory`, `sb-notify` đều chạy 100% C thuần bên trong tiến trình dwmblocks, cập nhật trực tiếp in-memory buffer (0 system calls qua pipe, 0 lần fork, 0.0% CPU usage)
  - **Triệt tiêu Zombie (`signal(SIGCHLD, SIG_IGN)`)**: Tự động thu dọn tiến trình con ở tầng kernel, xử lý chuẩn POSIX `ECHILD`
  - **Edge-Flush Dropdown Alignment**:
    - Left/Center blocks: Căn mép TRÁI cửa sổ popup thẳng hàng 100% với mép TRÁI vạch underline (`c->x = active_block.screen_x`)
    - Right-clamped blocks: Căn mép PHẢI cửa sổ popup ôm sát 100% với mép PHẢI vạch underline (`c->x = active_block.screen_x + active_block.w - WIDTH(c)`)
  - **Zero Stray Underline**: DWM tự động phát hiện khi popup đóng (bằng `Esc`, `q`, phím tắt, hoặc click ra ngoài) và xóa sạch `active_block.sig = 0`, vẽ lại bar tức thì
  - **Tối ưu hóa Khởi động Shell (< 8ms)**: Cơ chế Static Pre-compiled Cache tại `$XDG_CACHE_HOME/zsh/` cho Starship, Zoxide, Mise, Direnv
  - **Tối ưu hóa Hiển thị & Low-DPI**: Fontconfig Subpixel RGB rendering cho màn hình 1366x768 và cờ tăng tốc OpenGL GLX cho Intel HD 4000 trong Picom
- **Deploy & Management:**
  - `stow-safe <package>` — Deploy an toàn (tự động backup vào `~/.local/share/dotfiles/backups/`)
  - `ka-setup suckless` — Biên dịch và cài đặt DWM 6.8, ST, Dmenu, Dwmblocks, ka-pop
  - `ka-setup sys` — Tự động cấu hình zRAM (`zstd`) + Sysctl Virtual Memory tuning (`vm.swappiness = 180`)
  - Session start: auto via `zsh/.config/zsh/.zprofile` → `startx "$XINITRC"` → `exec ssh-agent dwm`

## Essential Ergonomic Hotkeys

| Hotkey | Action | Note |
| :--- | :--- | :--- |
| `Super + Enter` | Terminal | `st` native C |
| `Super + Space` | App Launcher | `rofi-launcher` tỉ lệ vàng (APPS/RUN/FILES/WINDOWS) |
| `Alt + Tab` | Window Switcher | Rofi window switcher, DWM tự nhảy Workspace & focus |
| `Super + W` | Web Browser | `brave` GPU acceleration |
| `Super + E` | File Manager | `lf` với image preview `ueberzugpp` |
| `Super + V` | Clipboard Manager | Lịch sử clipboard tỷ lệ 2 : 3 (Text & Ảnh) qua GTK3 native |
| `Super + Q` | Close Window | Native C `killclient` |
| `Super + F` | Toggle Fullscreen | Native C `togglefullscreen` 100% full màn hình |
| `Super + Shift + Space` | Centered Floating | Cửa sổ nổi tự căn giữa tỉ lệ vàng 75% $\times$ 80% |
| `Super + [1 - 9]` | Switch Tag | Chuyển tag làm việc |
| `Super + Shift + [1 - 9]` | Move to Tag | Di chuyển cửa sổ sang tag |
| `Super + Ctrl + A` | Popover Audio | Bật/tắt thẻ âm lượng & output |
| `Super + Ctrl + W` | Popover Network | Bật/tắt thẻ Wi-Fi, IP & DNS switcher |
| `Super + Ctrl + B` | Popover Battery | Bật/tắt thẻ pin, công suất & độ sáng |
| `Super + Ctrl + C` | Popover Clock | Bật/tắt thẻ đồng hồ & lịch tương tác |
| `Super + Ctrl + T` | Popover CPU | Bật/tắt thẻ CPU, nhiệt độ, quạt & top processes |
| `Super + Ctrl + M` | Popover Memory | Bật/tắt thẻ RAM, Swap & top processes |
| `Super + Ctrl + F` | Popover Forecast | Bật/tắt thẻ thời tiết khí quyển |
| `Super + Ctrl + D` | Default Handlers | Bật/tắt menu chọn ứng dụng mặc định một chạm |
| `Super + Alt + T` | Instant Screen OCR | Quét chọn vùng màn hình bóc tách chữ vào Clipboard |
| `Super + Alt + N` | Night Working Mode | Bật/tắt chế độ ban đêm (Lọc ánh sáng xanh 4000K + giảm sáng 35%) |
| `Super + Shift + N` | Notification Center | Mở Trung tâm thông báo dạng Right Sidebar (Full Height, responsive) |
| `Super + Shift + Q` | Logout DWM | Thoát về TTY1 |
| `Super + F5` | Reload Xresources | DWM nạp lại màu Xresources |

## Environment

- `EDITOR=nvim`, `TERMINAL=st`, `BROWSER=brave`
- `SUDO_ASKPASS=$HOME/.local/bin/dmenupass`
- Full XDG dirs set in `shell/.config/shell/profile`
- `ZDOTDIR=$XDG_CONFIG_HOME/zsh`
- Dev runtimes: Quản lý qua `mise` (`shell/.config/mise/config.toml`)
- vi mode in: zsh, tmux, lf, ncmpcpp, mpv

## Stow quirks

- `scripts/.local/bin/cron/` subdirectory has actual files; `checkup`/`crontog`/`newsup` are symlinks to `cron/*`
- `scripts/.local/bin/user/` has bluetooth scripts (`btmgr`, `btpair`, `btclean`, etc.)
- `.stow-local-ignore` used in `opencode/` to completely ignore `node_modules`
- `.gitignore` ignores `.zcompdump*`, `profile.local`, `**/node_modules/`, and dynamic theme artifacts (`current.conf`, `xresources.d/`)

## NixOS

- `nixos/flake.nix` → `nixosConfigurations.thinkbox` (x86_64-linux, systemd-boot, state 24.11)
- Home-manager with `backupFileExtension = "backup"`
- `home-manager.extraSpecialArgs.dotfiles` points to `/home/ka/.dotfiles`
