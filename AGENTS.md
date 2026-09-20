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
  - `ka doctor` — Chẩn đoán toàn diện sức khỏe, binary, audio, theming và dev runtimes
  - `ka dev [setup|status|update]` — Quản lý toàn bộ dev SDKs (Node, Python, Go, Rust, Bun, PNPM) qua Mise
  - `ka ocr` — Bóc tách chữ trên màn hình (In-memory OCR, song ngữ Anh-Việt) vào Clipboard
  - `ka theme [nord|gruvbox-dark|catppuccin-mocha]` — Đổi theme toàn diện, hot-reload tức thì
  - `ka default [show|set <cat> <app>]` — Quản lý & chọn ứng dụng mặc định một chạm (Rofi / CLI)
  - `ka clip [menu|daemon|clear|status]` — Quản lý lịch sử clipboard tỷ lệ 2 : 3 (Text đầy đủ & Ảnh phóng to) qua GTK3 native
  - `ka pop <module>` — Bật/Tắt thẻ popup Omarchy (volume, clock, battery, cpu, mem, net, forecast)
  - `ka dns [dhcp|cloudflare|google|custom <ip>]` — Chuyển đổi DNS server 1 chạm
  - `ka record [toggle|status]` — Quay video màn hình
  - `ka setup [all|suckless|stow|pkgs]` — Tự động hóa triển khai hệ thống
- **DWM 6.8 Native C Core:**
  - Nâng cấp lên DWM 6.8 với các bản vá bảo mật upstream (heap overflow, EWMH focus, format 32 check, underflow guard)
  - Tự động đổi con trỏ chuột thành hình bàn tay chỉ (`XC_hand2`) khi rê vào Tags (1-9) và các blocks thanh trạng thái
  - Bộ đệm Pre-Warmed Socket Daemon (`dwm-dropdown --daemon`) giảm độ trễ mở popup từ 85ms xuống < 2ms
- **Deploy & Management:**
  - `stow-safe <package>` — Deploy an toàn (tự động backup vào `~/.local/share/dotfiles/backups/`)
  - `ka-setup suckless` — Biên dịch và cài đặt DWM 6.8, ST, Dmenu, Dwmblocks
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
