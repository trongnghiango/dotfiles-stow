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
| `gtk/` | GTK 2/3/4 theme settings (Arc-Gruvbox, Papirus-Dark, gtk-3.0/bookmarks) |
| `fontconfig/` | Fontconfig rules (loại bỏ font bitmap) |
| `nsxiv/` | Nsxiv image viewer keybinds |
| `brave/` | Brave browser flags config (X11 + HD4000 GPU decode) |
| `pipewire/` | RNNoise AI real-time stereo noise suppression cho microphone |
| `media/` | mpv, ncmpcpp, mpd configs |
| `opencode/` | 9Router gateway config, 3 combo tiers (KhaBoDo, KhaSimple, KhaThinking) |
| `git/` | gitconfig with delta diff, aliases, smart pull/push/fetch, rerere |
| `nixos/` | flake.nix, hosts/thinkbox/, home/home.nix |

## Key commands / workflow

- **Autoconfig & Package Deploy:**
  - `./scripts/.local/bin/ka-setup all [profile]` — Chạy toàn bộ cấu hình (mặc định: `core`)
  - `ka-setup pkgs [core|dev|media|tools|virt|sys|all]` — Cài đặt gói từ `progs.csv` theo profile hoặc tier
  - `ka-setup suckless` — Biên dịch và cài đặt DWM, ST, Dmenu, Dwmblocks từ mã nguồn local
  - `ka-setup stow` — Deploy tất cả 23 dotfiles packages qua `stow-safe`
- **Dynamic Theming:**
  - `theme-set` — Xem theme hiện tại và danh sách theme có sẵn
  - `theme-set <nord|gruvbox-dark|catppuccin-mocha>` — Đổi theme tức thì, hot-reload DWM via SIGHUP
- **Deploy (Safe):** `stow-safe <package>` (auto-backs up conflicting files to `~/.local/share/dotfiles/backups/`)
- **Deploy (Native):** `stow -vt ~ <package>` (repeat for each package)
- **Undeploy:** `stow -Dvt ~ <package>` or `stow-safe --unstow <package>`
- **Session start:** auto via `zsh/.config/zsh/.zprofile` — khi login tty1, gọi `startx "$XINITRC"` → `xinitrc` → `exec ssh-agent dwm`
- **Web App Mini:** `brave-app <url>` — Mở webapp nổi ở trung tâm màn hình không thanh tab/url
- **Statusbar Dropdown Popovers:** `dwm-dropdown <volume|clock|battery|cpu|memory|network|forecast>` — Thẻ popup GUI phong cách Omarchy (0px border-radius, viền 2px accent, auto-dismiss, toggle)
- **Shortcuts:** `shortcuts` regenerates `shortcutrc`/`shortcutenvrc`/`zshnameddirrc` from `bm-dirs`/`bm-files`
- **Git Manager:** `gm` — multi-account git tool under `~/Repos/`, uses git `includeIf`
- **Wallpapers:** `setbg` — handles WebP, pywal, xwallpaper; runs at X startup
- **Cron:** `cron/crontog` toggles all cron jobs; `cron/checkup` (pacman), `cron/newsup` (RSS)

## Essential Ergonomic Hotkeys

| Hotkey | Action | Note |
| :--- | :--- | :--- |
| `Super + Enter` | Terminal | `st` native C |
| `Super + Space` | App Launcher | `rofi-launcher` tỉ lệ vàng (APPS/RUN/FILES/WINDOWS) |
| `Alt + Tab` | Window Switcher | Rofi window switcher, DWM tự nhảy Workspace & focus |
| `Super + W` | Web Browser | `brave` GPU acceleration |
| `Super + E` | File Manager | `lf` với image preview `ueberzugpp` |
| `Super + Q` | Close Window | Native C `killclient` |
| `Super + F` | Toggle Fullscreen | Native C `togglefullscreen` 100% full màn hình |
| `Super + Shift + Space` | Centered Floating | Cửa sổ nổi tự căn giữa tỉ lệ vàng 75% $\times$ 80% |
| `Super + [1 - 9]` | Switch Tag | Chuyển tag làm việc |
| `Super + Shift + [1 - 9]` | Move to Tag | Di chuyển cửa sổ sang tag |
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
