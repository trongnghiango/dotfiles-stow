# Handoff — Fonts, DWM/X11 & Dotfiles Performance Optimization

## Focus
Tối ưu hóa hệ thống Fonts theo triết lý Omarchy 4.x / DHH, khắc phục các lỗi giao diện DWM (bar full-width, systray padding, tofu emoji), chuẩn hóa phím tắt, audit hiệu năng và tự động hóa bootstrap cài đặt với `ka-setup`.

## Handoff reason
`user-initiated`

## Repo state
- **Branch**: `main`
- **HEAD commit**: `760eec7af56c13860d29396cf4e8f337e228ec5b`
- **Working Tree**: Clean (`git status --short` is empty)

## State
Toàn bộ hệ thống dotfiles đã được tái cấu trúc và tối ưu hóa toàn diện. Đã dọn dẹp 355 MB file font binary nặng trong Git, chuyển sang mô hình "Font nhẹ (JetBrains Mono) + Fallback Symbol (Symbols Nerd Font)", sửa lỗi render ký tự biến thể Unicode `U+FE0F` trong DWM/Dmenu, đưa thanh bar DWM về 100% full-width, giải quyết xung đột hotkey (`Super+Space`, `Super+D`, `Super+E`, `Ctrl+Print`), cải tiến công cụ chụp màn hình tự động copy vào clipboard, tối ưu hóa Zsh compinit cache (giảm thời gian khởi động terminal còn <20ms), và hoàn thiện script cài đặt tự động `ka-setup all` cho Arch Linux mới tinh.

## Verification
- Mã nguồn C của Suckless (`dwm`, `st`, `dmenu`) đều compile thành công không có lỗi.
- **Lệnh kiểm tra lại**:
  ```bash
  cd suckless/.local/src/dwm && make clean && make
  cd ../st && make clean && make
  cd ../dmenu && make clean && make
  ```

## Constraints
- Giữ nguyên kiến trúc X11/DWM siêu nhẹ theo đúng tài liệu `OMARCHY_X11_HANDOFF.md`.
- Tuyệt đối không commit binary fonts (`.ttf`, `.woff2`) vào Git repo. Quản lý font qua package manager (`pacman` / `pkgs.fonts`).
- Tuân thủ cấu trúc GNU Stow packages.

## Risk context
- **Tier 2 / Standard**: Các thay đổi liên quan đến cấu hình hệ thống, compile binary suckless và cấu hình shell.

## Artifacts
- **Commit History**:
  - `51deb06` `perf(fonts): optimize typography and remove font binaries bloat`
  - `be1ef4f` `fix(suckless): skip unicode variation selectors to prevent missing glyph boxes`
  - `5f35838` `feat(dwm): make bar full-width, tighten systray, and streamline keybindings`
  - `5ae2ef3` `feat(scripts): enhance screenshot clipboard copy and fix weather icons`
  - `f4bfa2b` `fix(ka-setup): add base-devel, suckless build deps, maim, and rofi to pkgs list`
  - `3526c76` `perf(core): optimize zsh compinit caching, picom shadow excludes, and process cleanup`
  - `760eec7` `fix(zsh): support arch zsh-syntax-highlighting path and add to ka-setup pkgs`
- **Configuration Schema**:
  - DeepSeek Harness Vision model config: `llm-pi-ai` provider with `input: [text, image]`.

## Decisions
1. **Kiến trúc Fonts**: Áp dụng chuẩn Omarchy 4.x — sử dụng `JetBrains Mono` + `Symbols Nerd Font` cho Monospace/CLI và `Inter` / `Liberation Sans` cho UI. Loại bỏ binary fonts trong Git để giảm dung lượng repo.
2. **X11 Emoji Render Patch**: Thêm logic bỏ qua Unicode Variation Selectors (`U+FE00` - `U+FE0F`) trong `drw.c` của DWM và Dmenu để ngăn chặn hoàn toàn lỗi ô vuông missing glyph.
3. **Bar & Systray Geometry**: Đặt `vertpad = 0`, `sidepad = 0` và padding systray = 4px để đạt giao diện Full-Width liền mạch.
4. **Phím tắt chuẩn hóa**:
   - `Super + Space`: Rofi App Launcher (`rofi-launcher`)
   - `Super + D`: Dmenu Run
   - `Super + E`: LF File Manager (`st -e lfub`)
   - `Super + W`: Brave Browser
   - `Print` / `Ctrl+Print` / `Shift+Print`: Chụp màn hình qua `shot` và tự copy vào clipboard.

## Next steps
1. Trên máy local, chạy `sudo pacman -S --needed zsh-syntax-highlighting` để kích hoạt màu sắc lệnh syntax highlighting trên terminal.
2. Cài đặt các binary mới compile:
   ```bash
   cd ~/.dotfiles/suckless/.local/src/dwm && sudo make install
   cd ~/.dotfiles/suckless/.local/src/dmenu && sudo make install
   cd ~/.dotfiles/suckless/.local/src/st && sudo make install
   ```
3. Khởi động lại DWM (`Super + Shift + Q`) để nạp toàn bộ cấu hình mới.

## Blockers
N/A

## Prior handoff
N/A (Lần tạo handoff đầu tiên trong chuỗi phiên làm việc này)

## Suggested skills
- `git-guardian`: Quản lý an toàn các commit và push lên remote repo.
- `ka-ops`: Hỗ trợ thêm các cấu hình NixOS hoặc CI/CD nếu cần.
