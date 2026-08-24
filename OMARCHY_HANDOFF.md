# OMARCHY_HANDOFF.md — Dotfiles & Omarchy Hybrid Architecture

> **MỤC ĐÍCH TÀI LIỆU (ANCHOR CHO CÁC PHIÊN LÀM VIỆC MỚI):**
> Tài liệu này là nguồn sự thật (Source of Truth) ghi lại toàn bộ kiến trúc, quyết định kỹ thuật, quy tắc cấu hình, bộ phím tắt DWM Hybrid và trạng thái của repository `.dotfiles`. 
> Mọi AI Assistant khi mở phiên làm việc mới **BẮT BUỘC ĐỌC VÀ TUÂN THỦ NGHIÊM NGẶT** tài liệu này.

---

## 1. Triết lý Kiến trúc: Mô hình Lai (Hybrid Architecture)

Hệ thống phân định ranh giới tuyệt đối giữa **Omarchy Core** (Hệ điều hành nền tảng) và **Dotfiles Cá nhân** (Trải nghiệm Power-User):

| Thành phần | Phân vùng quản lý | Công nghệ / Công cụ đảm nhận |
|---|---|---|
| **Omarchy Core (Hạ tầng & Phần cứng)** | Môi trường Wayland/Hyprland, Theme/Wallpapers, Topbar (`omarchy-shell`), Quick-settings, Bluetooth panel, Audio/Brightness helper (`WirePlumber`), Tự động mount ổ đĩa (`udiskie`), Snapshot hệ thống (Btrfs), PAM SDDM Keyring. | Native Omarchy UI & Cgroups (`uwsm`, `omarchy-menu`, `omarchy-shell`). |
| **Dotfiles (Trải nghiệm Terminal Power-User)** | Zsh, Neovim, Tmux, Git, LF File Manager, Fcitx5 tiếng Việt, Media MPV/NCMPCPP, Bộ phím tắt DWM Hybrid, Script CLI cá nhân. | Quản lý qua Git & Triển khai an toàn qua **`stow-safe`** / **`ka-setup stow`**. |

---

## 2. Cấu trúc Stow Packages (12 Packages Cá nhân hóa)

Toàn bộ packages tuân thủ chuẩn **XDG Base Directory** (`~/.config/`, `~/.local/`):

| Package | Đường dẫn đích (`$HOME`) | Nội dung & Quyết định kỹ thuật |
|---|---|---|
| `shell/` | `~/.config/shell/`: `profile`, `aliasrc`, `inputrc` | Nạp biến môi trường XDG, alias tối ưu, cấu hình readline vi-mode. |
| `zsh/` | `~/.config/zsh/`: `.zshrc`, `functions.zsh`, `env.zsh` | Zsh vi-mode, hàm `lfcd` an toàn chống đệ quy `FUNCNEST`, nạp 9Router keys. |
| `git/` | `~/.config/git/`: `config`, `ignore` | Git aliases (`st`, `co`, `lg`, `cm`, `undo`), auto-rebase khi pull, Delta diff syntax highlighter. |
| `hypr/` | `~/.config/hypr/`: `bindings.lua`, `looknfeel.lua` | Ghi đè bộ phím tắt DWM Hybrid, giữ trạng thái maximize khi đóng cửa sổ, tối ưu 60Hz smooth animations. |
| `brave/` | `~/.config/brave-flags.conf` | Tối ưu phần cứng GPU, Wayland native, Zero-Copy Rasterization, HTTP/3, IME tiếng Việt. |
| `nvim/` | `~/.config/nvim/` | Modular Lua config (`lua/{core,plugins,utils}/`), Lazy.nvim, Snacks, LSP, auto-sync theme Omarchy. |
| `tmux/` | `~/.config/tmux/tmux.conf` | Prefix `C-Space`, escape-time 0, Vi-mode navigation, Wayland clipboard (`wl-copy`). |
| `lf/` | `~/.config/lf/`: `lfrc`, `scope`, `icons`, `cleaner` | File manager Wayland native, previewer đa năng (Chafa, Bat, Eza, cache SHA256, Sixel/Kitty detection). |
| `fcitx5/` | `~/.config/fcitx5/` | Cấu hình bộ gõ Bamboo Telex tiếng Việt, toggle hotkey. |
| `media/` | `~/.config/{mpv,ncmpcpp,mpd}` | `mpv.conf` tối ưu GPU Wayland, tự động nạp Cover Art & biểu tượng âm nhạc (`audio-cover.lua`), MPRIS Topbar, MPD PipeWire. |
| `opencode/` | `~/.config/opencode/` | Cấu hình 9Router AI gateway và 3 combo tiers (KhaBoDo, KhaSimple, KhaThinking). |
| `scripts/` | `~/.local/bin/` | Bộ CLI utilities (`stow-safe`, `ka-setup`, `ytdl-cut`, `gm`, `battery-threshold`, `omarchy-hyprland-animations-toggle`, `otp`, `weath`, cron). |

---

## 3. Hệ thống Phím tắt DWM Hybrid (`~/.config/hypr/bindings.lua`)

### ⚠️ Quy tắc Vàng: `hl.unbind` trước khi `o.bind`
Để tránh xung đột (ghost bindings / mở 2 app cùng lúc), khi ghi đè bất kỳ phím mặc định nào của Omarchy, **bắt buộc phải gọi `hl.unbind("<KEY>")` trước**:
```lua
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + W")
hl.unbind("SUPER + K")
hl.unbind("SUPER + J")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + SHIFT + SPACE")
hl.unbind("SUPER + T")
hl.unbind("SUPER + A")
hl.unbind("SUPER + D")
hl.unbind("SUPER + E")
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + M")
hl.unbind("SUPER + Z")
hl.unbind("SUPER + F")
```

### 📋 Bảng Phím tắt Chuẩn DWM Hybrid:

| Nhóm | Phím tắt | Chức năng | Cơ chế kỹ thuật |
|---|---|---|---|
| **Window Control** | <kbd>Super</kbd> + <kbd>q</kbd> | Đóng cửa sổ đang chọn | `hl.dsp.window.close()` (DWM killclient) |
| | <kbd>Super</kbd> + <kbd>t</kbd> *(hoặc <kbd>Shift</kbd>+<kbd>Space</kbd>)* | **Toggle Floating ⟷ Tiling** | `hl.dsp.window.float({ action = "toggle" })` |
| | <kbd>Super</kbd> + <kbd>\</kbd> | **Đổi hướng chia (Ngang ⟷ Dọc)** | `hl.dsp.layout("togglesplit")` |
| | <kbd>Super</kbd> + <kbd>b</kbd> | **Ẩn / Hiện thanh Topbar** | `omarchy-toggle bar` (DWM togglebar) |
| | <kbd>Super</kbd> + <kbd>a</kbd> *(hoặc <kbd>Alt</kbd>+<kbd>0</kbd>)* | **Toggle Gaps (Default ⟷ 0-Gaps)** | `omarchy-hyprland-window-gaps-toggle` |
| | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>a</kbd> *(hoặc <kbd>Alt</kbd>+<kbd>a</kbd>)* | **Toggle Animations (Smooth ⟷ 0ms DWM)** | `omarchy-hyprland-animations-toggle` |
| **Display Modes** | <kbd>Super</kbd> + <kbd>m</kbd> *(hoặc <kbd>z</kbd>)* | **Maximized (Monocle `[M]` - Giữ Topbar)** | `hl.dsp.window.fullscreen({ mode = "maximized" })` |
| | <kbd>Super</kbd> + <kbd>f</kbd> | **True Fullscreen (Tràn 100% che Topbar)** | `hl.dsp.window.fullscreen({ mode = "fullscreen" })` |
| **Stack Navigation** | <kbd>Super</kbd> + <kbd>j</kbd> | **Focus Next Window in Stack** | `hl.dsp.window.cycle_next()` *(Duyệt mượt mà cả Tiled lẫn Monocle)* |
| | <kbd>Super</kbd> + <kbd>k</kbd> | **Focus Prev Window in Stack** | `hl.dsp.window.cycle_next({ next = false })` |
| | <kbd>Super</kbd> + <kbd>h</kbd> / <kbd>l</kbd> | Focus Trái / Phải (2D) | `hl.dsp.focus({ direction = "l" / "r" })` |
| | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>j</kbd> / <kbd>k</kbd> | Hoán đổi vị trí trong Stack | `hyprctl dispatch swapnext [prev]` (DWM movestack) |
| | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>h</kbd> / <kbd>l</kbd> | Hoán đổi cửa sổ Trái / Phải | `hl.dsp.window.swap({ direction = "l" / "r" })` |
| **Resize Master** | <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>h</kbd> / <kbd>l</kbd> | Thu hẹp / Mở rộng Master Window | `hl.dsp.window.resize({ x = -50 / 50, relative = true })` |
| **App Launchers** | <kbd>Super</kbd> + <kbd>Return</kbd> | Mở Terminal (`foot`) | `{ omarchy = "terminal" }` / `foot` |
| | <kbd>Super</kbd> + <kbd>w</kbd> | Mở Web Browser (`brave`) | `{ omarchy = "browser" }` / `brave` |
| | <kbd>Super</kbd> + <kbd>e</kbd> | Mở File Manager (`lf`) | `{ tui = "lf" }` (Native Omarchy TUI launcher) |
| | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>e</kbd> | Mở Menu Emoji | `omarchy-shell shell toggle omarchy.emojis` |
| | <kbd>Super</kbd> + <kbd>Space</kbd> | Mở Omarchy Root Menu | `omarchy-menu toggle` |
| | <kbd>Super</kbd> + <kbd>d</kbd> | Mở App Launcher Menu | `omarchy-menu toggle apps` |
| | <kbd>Super</kbd> + <kbd>?</kbd> *(hoặc <kbd>F1</kbd>)* | Tra cứu Keybindings Help | `omarchy-menu-keybindings` |
| **Scratchpad** | <kbd>Super</kbd> + <kbd>`</kbd> | Bật / Tắt Scratchpad đa năng | `hl.dsp.workspace.toggle_special("scratchpad")` |
| | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>`</kbd> | Gửi cửa sổ vào Scratchpad | `hl.dsp.window.move({ workspace = "special:scratchpad" })` |
| **Multi-Monitor** | <kbd>Super</kbd> + <kbd>,</kbd> / <kbd>.</kbd> | Chuyển Focus Màn hình Trái / Phải | `hl.dsp.focus({ monitor = "-1" / "+1" })` |
| | <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>,</kbd> / <kbd>.</kbd> | Di chuyển Workspace sang Màn hình | `hl.dsp.workspace.move({ monitor = "l" / "r" })` |

---

## 4. Module LF File Manager & Previewer (`scope`)

- **Cấu hình `lfrc`:** Tích hợp bộ gõ vi-mode, Nerd Font v3 icons, gọi Native opener. *(Lưu ý: Không dùng `set sixel true` trong `lfrc` vì lf không có option boolean này, sixel chạy tự động qua stdout của scope).*
- **Bộ Previewer `scope`:**
  - **Code/Text:** Highlight cú pháp bằng `bat --color=always`.
  - **Thư mục:** Hiển thị cây phân cấp bằng `eza --tree --icons`.
  - **Hình ảnh:** Tự động nhận diện Kitty Graphics (`ghostty`/`kitty`), Sixel Graphics (`foot`), hoặc fallback sang Unicode Sextant blocks (`chafa --symbols sextant+quad+half+block`). Có tính toán biên an toàn (`calc_width`, `calc_height`) chống tràn viền line-wrap.
  - **Video Thumbnail:** Trích xuất thumbnail qua `ffmpegthumbnailer` kèm cache SHA256 (`~/.cache/lf/thumbnails/`).
  - **PDF & EPUB Cover:** Tự động trích xuất trang bìa PDF qua `pdftoppm` và bìa sách EPUB qua `unzip -p` rồi render qua `chafa`.
- **Mở file tức thì:** Nhấn <kbd>Enter</kbd> (hoặc <kbd>l</kbd>): Ảnh $\rightarrow$ `imv`, Video/Audio $\rightarrow$ `mpv`, PDF/EPUB $\rightarrow$ `zathura`.

---

## 5. Quy Chuẩn Scripting & An Toàn Wayland

Bất kỳ script CLI nào viết thêm vào `scripts/.local/bin/` bắt buộc tuân theo:
- **Picker**: Dùng `fzf` (Tuyệt đối không dùng `dmenu`).
- **Clipboard**: Dùng `wl-copy` / `wl-paste` (Tuyệt đối không dùng `xclip`).
- **Hình ảnh**: Dùng `imv` (Wayland native, tuyệt đối không dùng `nsxiv`).
- **Thông báo**: Dùng `notify-send` tiêu chuẩn.
- **Quản lý Triển khai:** Luôn sử dụng `stow-safe` (tự động backup snapshot có phiên bản trước khi symlink).

---

## 6. Danh Sách Lệnh Quản Trị Cốt Lõi

- **Triển khai toàn bộ dotfiles:** `ka-setup stow` (hoặc `ka-setup all`).
- **Triển khai từng package:** `stow-safe <package>` (ví dụ: `stow-safe hypr`).
- **Hủy triển khai:** `stow -Dvt ~ <package>`.
- **Quản lý Git nhiều tài khoản:** `gm` (`gm init`, `gm clone <url>`, `gm status`, `gm sync`).
- **Giới hạn sạc pin ThinkPad:** `battery-threshold` (service systemd oneshot 50-60%).
- **Chuyển đổi Animation (Toggle):** `omarchy-hyprland-animations-toggle` (Phím tắt: `Super + Shift + A`).

---

## 7. Các Quyết Định Kỹ Thuật Gần Đây (Recent Decisions & Context)

1. **Giữ trạng thái Monocle / Fullscreen khi đóng cửa sổ con:**
   - Cấu hình trong `hypr/.config/hypr/looknfeel.lua`: `exit_window_retains_fullscreen = true`.
   - Giúp các app mở cửa sổ con (như Settings trong Antigravity IDE, file picker, popup) khi đóng lại thì cửa sổ cha vẫn giữ nguyên chế độ Maximized (`Super + M`) mà không bị rớt về Tiling.

2. **Hệ thống Audio Thumbnail & Topbar MPRIS Sync:**
   - Package `media/` tích hợp script `audio-cover.lua` và asset `audio-placeholder.png`.
   - `mpv` luôn mở cửa sổ nổi (`force-window=immediate`). Nếu file audio có cover art thì hiển thị cover art thật; nếu không có sẽ tự động nạp hình ảnh đĩa than Neon Art.
   - Topbar được tích hợp widget `omarchy.media` để điều khiển trực quan qua D-Bus MPRIS.
   - Trình duyệt `brave` tự động đồng bộ luồng media với Topbar qua `brave-flags.conf`.

3. **Tối ưu hóa GPU & Animation 60Hz:**
   - Máy sử dụng Intel UHD Graphics (CometLake iGPU) với Fractional Scaling 1.25.
   - Đã thay thế curve cũ bằng `smoothOut` bezier `(0.16, 1, 0.3, 1)`, giảm popin và tắt `animate_manual_resizes` để triệt tiêu hoàn toàn hiện tượng micro-stutter/giật khung hình.
   - Thêm hotkey `Super + Shift + A` để chuyển nhanh giữa **Smooth** và **DWM Instant (0ms)**.

4. **Tự động hóa Cài mới 1 Lệnh (Zero-Bootstrap Issue):**
   - Lệnh `ka-setup all` tự động nhận diện đường dẫn `stow-safe`, triển khai đủ 12 packages, cấu hình Topbar, reload Hyprland mà không yêu cầu người dùng phải gõ lệnh chuẩn bị thủ công.

---
> **LỜI NHẮC QUAN TRỌNG CHO AI TRỢ LÝ Ở PHIÊN MỚI:**
> Hệ thống này là một khối thống nhất, tối ưu 0-delay và 100% sạch sẽ. Hãy duy trì kiến trúc Hybrid này, không tạo lại các script X11 cũ, và luôn kiểm tra tính năng Native của Omarchy trước khi can thiệp.
