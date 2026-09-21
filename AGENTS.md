# AGENTS.md — dotfiles

Personal dotfiles managed with **GNU Stow** + Git. Primary: **Arch Linux** + **DWM** (startx, no DM). Also runs on NixOS (`thinkbox`) and Void.

> [!IMPORTANT]
> **X11 Omarchy Philosophy**: Nhánh `main` này được thiết kế lại dựa trên triết lý sạch sẽ, tối ưu của Omarchy OS (DHH), nhưng giữ nguyên công nghệ X11/DWM (Native C) để đạt hiệu năng tối đa.
> Mọi AI Assistant khi làm việc với repository này **BẮT BUỘC ĐỌC** file `OMARCHY_X11_HANDOFF.md` và **TUÂN THỦ TUYỆT ĐỐI 7 NGUYÊN TẮC THÉP** bên dưới trước khi chạm vào bất kỳ dòng code nào.

## 7 NGUYÊN TẮC THÉP CHO BỘ KHUNG GẦM ĐA DISTRO (CHỐNG RÁC CODE & SMELL)

> **Mục tiêu tối thượng**: Độc lập distro (Arch, Debian, Void, Fedora, NixOS), hiệu năng cao nhất trên máy 10-15 năm tuổi, không phát sinh rác code, không monkey-patching khi fix bug.

1. **Tam Giác Cô Lập Kiến Trúc (Architectural Isolation)**:
   - **Tầng Engine (Distro OS)**: Chỉ quản lý tải gói, nằm riêng tại `pkgs/*.csv` và `scripts/.local/bin/setup-drivers/`.
   - **Tầng Chassis (Hardware Profile)**: Quản lý đặc tính vật lý (DPI, pin, touchpad, cờ GPU), nằm riêng tại `hardware/.config/hardware/`.
   - **Tầng Cockpit (Userland Dotfiles)**: DWM, ST, Zsh, Neovim, Theme. Tầng này **hoàn toàn mù (agnostic) về Distro**.
   - **CẤM**: Không viết `if [ "$DISTRO" = "arch" ]` hoặc kiểm tra distro trong UI, scripts, dwm, theme.
2. **Zero-Binary trong Git (Biên dịch Cục bộ)**:
   - **CẤM**: Tuyệt đối KHÔNG commit file thực thi nhị phân compiled ELF (`dwm`, `st`, `dmenu`, `ka-pop`, `*.o`) vào Git repository.
   - Mọi binary C Native phải được biên dịch tại máy đích qua `ka-setup suckless` để tối ưu theo vi kiến trúc CPU cục bộ (`-march=native -O3 -flto`) và tương thích đúng thư viện C (glibc vs musl).
3. **Zero-Cost Shim Layer (Giải quyết phân mảnh tên Binary FHS)**:
   - Khi distro đổi tên binary (như Debian đổi `bat` thành `batcat`, `fd` thành `fdfind`), xử lý bằng symlink 1 lần duy nhất trong `setup-drivers/` trỏ về `~/.local/bin/bat` và `~/.local/bin/fd`.
   - **CẤM**: Không viết `if command -v batcat; then ...` lặp đi lặp lại trong scripts hay config.
4. **Init-Agnostic & Zero Systemd Lock-in**:
   - Dotfiles phải chạy trơn tru trên cả **Void Linux (runit)**, **Alpine (OpenRC)** và **Systemd**.
   - **CẤM**: Không gọi cứng `systemctl --user` nếu không bọc điều kiện kiểm tra `[ -d /run/systemd/system ]`.
   - Mọi daemon (`ka-daemon`, `dunst`, `picom`) phải chạy được bằng tiến trình POSIX nền thuần túy (`setsid` / `&`).
5. **Dynamic Path Resolution (Không hardcode đường dẫn hệ thống)**:
   - **CẤM**: Không chạy thẳng đường dẫn tuyệt đối như `/usr/lib/polkit-gnome/...` vì Void/Fedora dùng `/usr/libexec/...`.
   - Luôn dùng vòng lặp dò tìm danh sách đường dẫn khả dĩ hoặc `command -v`.
6. **Hư Hỏng Có Kiểm Soát (Graceful Degradation)**:
   - Lệnh thăm dò phần cứng (`sensors`, `brightnessctl`, `/sys/class/power_supply`) luôn phải có fallback an toàn (`|| true` hoặc `|| echo fallback`). Không để `set -e` làm sập script khi chạy trên máy không có pin hoặc thiếu cảm biến.
7. **XDG Base Directory 100% & Idempotency**:
   - Config vào `~/.config/`, Data vào `~/.local/share/`, Cache vào `~/.cache/`. Không tạo file rác tại `$HOME`.
   - `ka-setup` chạy 1 lần hay 100 lần kết quả phải đồng nhất, không ghi đè cấu hình cá nhân, không tạo symlink trùng lặp.

---

## KỶ LUẬT SỬA LỖI & CHỐNG PHÁT SINH CODE SMELL (BUG-FIXING DISCIPLINE)

Mọi AI Agent khi sửa lỗi (bug-fixing) **BẮT BUỘC** tuân thủ:
- **Tìm nguyên nhân gốc rễ (Root Cause Analysis - RCA)**: Dùng `coredumpctl`, `gdb`, log X11 để xác định con trỏ lỗi hoặc race condition cụ thể. Tuyệt đối không "đoán mò" rồi chắp vá tạm thời.
- **Không tự ý thêm cờ thử nghiệm (No Speculative Flags)**: Không thêm các cờ render lạ vào Picom hay Mesa khi chưa đo lường; tránh gây crash dây chuyền cho các ứng dụng Electron/Chromium.
- **Triệt tiêu Zombie & Leak**: Mọi lệnh chạy nền bất đồng bộ phải dùng `signal(SIGCHLD, SIG_IGN)` hoặc thu dọn tiến trình con đầy đủ, tránh để lại zombie processes (`<defunct>`).
- **Debounce trên GUI Events**: Mọi thao tác kéo thả slider trên giao diện (Volume, Brightness) phải có bộ đệm (Debounce/Throttle ~50ms), không gọi `system()` liên tục làm nghẽn CPU.
- **Tôn trọng Single Source of Truth**: Bảng màu chỉ lấy từ `colors/*.conf` qua `theme-set`. Không hardcode mã màu hex trong mã nguồn C hay scripts.

---

## Structure

Each top-level directory is a Stow package containing `$HOME`-relative paths (24 packages total):

| Package | What |
|---------|------|
| `shell/` | profile, aliasrc, shortcutrc, inputrc, mise/config.toml, starship.toml |
| `hardware/` | profiles/ (generic, generic-laptop, generic-desktop, thinkpad-x230, thinkpad-t480), current.conf |
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
  - `ka pop <module>` — Bật/Tắt thẻ popup Omarchy Native C (`ka-pop`: < 15ms cold launch, 0MB idle RAM, 9 modules bao gồm Clipboard)
  - `ka daemon [start|stop|restart|status]` — Quản lý tiến trình nền hợp nhất ka-daemon
  - `ka profile [detect|set <name>|list|show]` — Quản lý & tự động nhận diện cấu hình phần cứng (Laptop / Desktop / ThinkPad)
  - `ka night [on|off|toggle|status]` — Bật/Tắt chế độ làm việc ban đêm (Lọc ánh sáng xanh 4000K + giảm sáng 35%)
  - `ka notify [center|dnd|clear|status|test]` — Quản lý thông báo, DND và mở Notification Center Right Sidebar
  - `ka dns [dhcp|cloudflare|google|custom <ip>]` — Chuyển đổi DNS server 1 chạm
  - `ka record [toggle|status]` — Quay video màn hình
  - `ka setup [all|suckless|stow|pkgs|sys]` — Tự động hóa triển khai hệ thống (Arch, Debian, Void, Fedora)
- **DWM 6.8 Native C Core & Zero-Fork Statusbar (dwmblocks):**
  - Nâng cấp lên DWM 6.8 với các bản vá bảo mật upstream (heap overflow, EWMH focus, format 32 check, underflow guard)
  - **Zero-Fork Statusbar (9/9 Blocks In-Process C)**: `ka-clock`, `ka-forecast`, `sb-record`, `ka-volume`, `ka-battery`, `ka-network`, `ka-cpu`, `ka-memory`, `sb-notify` đều chạy 100% C thuần bên trong tiến trình dwmblocks. Triệt tiêu toàn bộ `popen()` và `/bin/sh`, chuyển sang `exec_capture` và `spawn_cmd` trực tiếp.
  - **Zero-Fork DWM-Statusbar IPC**: DWM đọc PID statusbar trực tiếp từ `$XDG_RUNTIME_DIR/dwmblocks.pid` (< 0.005ms) + fallback quét `/proc` (0 fork, loại bỏ 100% `popen("pgrep")` làm khựng chuột trong DWM).
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
  - `ka-setup sys` — Tự động cấu hình zRAM thích ứng (`lz4` cho <=2 nhân, `zstd` cho >=4 nhân) + Sysctl VM tuning (`vm.swappiness = 180`, `vm.page-cluster = 0`)
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
