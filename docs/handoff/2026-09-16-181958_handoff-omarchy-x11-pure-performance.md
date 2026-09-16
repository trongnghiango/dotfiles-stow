# Handoff — Omarchy X11 Pure Native Architecture, Dynamic Theming & Window Navigation

## Focus
Tối ưu hóa toàn diện hệ thống Arch Linux + DWM theo triết lý Omarchy (DHH) và hiệu năng Pure Native của Suckless C; sửa lỗi cài đặt tự động ka-setup/stow-safe; cấu hình mise dev runtime; tích hợp hệ thống theme động theme-set; khắc phục cảnh báo starship timeout; tinh chỉnh tỷ lệ vàng Rofi và hỗ trợ EWMH _NET_ACTIVE_WINDOW focus cửa sổ.

## Handoff reason
`user-initiated`

## Repo state
- **Branch**: `main`
- **HEAD commit**: `78240fa4421e0506ac9b975f5ec03543a5a80514`
- **Working Tree**:
  ```
   M AGENTS.md
   M OMARCHY_X11_HANDOFF.md
  ```

## State
Hệ thống dotfiles đã được hoàn thiện và nâng cấp lên kiến trúc hiện đại, sạch sẽ và đạt độ ổn định cao nhất. Đã khắc phục triệt để lỗi crash do biến đếm Bash `((i++))` và hiện tượng Stow Tree Folding; dọn dẹp danh mục `progs.csv` còn 149 gói sạch sẽ theo cấu trúc 5 cột phân tầng; đưa `mise` vào quản lý dev runtimes thay thế cài đặt qua Pacman; xây dựng Stow package `theme/` với lệnh `theme-set` hot-reload màu DWM qua SIGHUP; tối ưu `starship.toml` loại bỏ warning scan timeout; tái cấu trúc Rofi launcher từ 800px xuống 580px thanh thoát; vá mã nguồn C của DWM để tự động căn giữa cửa sổ nổi (75%x80%), toggle fullscreen bằng `Super+F`, và tự động nhảy đúng Workspace/Tag khi chọn cửa sổ trong Rofi (`Alt+Tab`).

## Verification
- Mã nguồn C của DWM đã biên dịch thành công 100% không có lỗi:
  ```bash
  cd suckless/.local/src/dwm && make clean && make
  ```
- Script `ka-setup` và `theme-set` vượt qua kiểm tra cú pháp Bash:
  ```bash
  bash -n scripts/.local/bin/ka-setup
  bash -n theme/.local/bin/theme-set
  bash -n scripts/.local/bin/rofi-launcher
  ```
- Rofi theme và cấu hình Xresources đã được xác thực biên dịch:
  ```bash
  rofi -dump-theme -theme rofi/.config/rofi/launcher.rasi > /dev/null
  xrdb -n x11/.config/x11/xresources
  ```
- Toàn bộ 143 gói Pacman và 6 gói AUR trong `progs.csv` đều tồn tại và hợp lệ trên kho Arch.

## Constraints
- Giữ nguyên kiến trúc X11/DWM siêu nhẹ Native C, không cài thêm các web engine độc lập (như Helium).
- Duy trì tính lũy đẳng (idempotent) của `ka-setup` và `stow-safe`.
- Quản lý toàn bộ cấu hình theo chuẩn GNU Stow (23 packages đồng bộ 1:1 với thư mục).
- Mọi runtime lập trình (Node, Python, Rust, Go) quản lý qua `mise`, không cài qua global pip hay npm.

## Risk context
- **Tier 2 / Standard**: Thay đổi mã nguồn C của DWM, cấu hình quản lý gói phần mềm hệ thống và biến môi trường shell.

## Artifacts
- **Commit Chain**:
  - `a2d576d` `fix(ka-setup,stow-safe): read progs.csv with profile system, fix set-e counter bugs, prevent stow tree-folding`
  - `5b9cd1a` `feat(progs,input-method,mise): add declarative package list, fcitx5-bamboo package, mise runtime config`
  - `e8c35d3` `fix(x11,zsh): source profile in xinitrc, replace nvm lazy-load with mise`
  - `b5eb9f2` `fix(starship): add config to eliminate scan_timeout warnings in large repos`
  - `2d1fcf0` `feat(theme,desktop): integrate dynamic X11 theme system and clean dotfiles structure`
  - `78b06bf` `feat(gtk): configure sidebar bookmarks and sort newest files first in file dialogs`
  - `3b3281e` `feat(dwm): add centered floating and toggle fullscreen for small screens (ThinkPad X230)`
  - `6987c79` `style(rofi): balance launcher window proportions and typography for compact desktop`
  - `78240fa` `feat(dwm,rofi): jump to exact workspace and window on ROFI window selection`
- **Key Files**:
  - `OMARCHY_X11_HANDOFF.md`: Tài liệu kiến trúc toàn diện.
  - `AGENTS.md`: Chỉ dẫn vận hành hệ thống cho AI Assistant.
  - `progs.csv`: Bảng khai báo 149 gói 5 cột.
  - `theme/`: Package theme động độc lập.

## Decisions
1. **Quản lý Theme động**: Triển khai `theme/` với CLI `theme-set`, dùng `colors/*.conf` làm Single Source of Truth, reload màu DWM qua tín hiệu `SIGHUP` không cần restart session.
2. **Quản lý Runtime bằng `mise`**: Đưa `mise` vào Tier 4 thay cho việc cài `rust`, `npm`, `python-pip` toàn cục, loại bỏ hoàn toàn nguy cơ xung đột PEP 668 trên Arch Linux.
3. **Ergonomic Window Control trên ThinkPad X230**:
   - `Super + Shift + Space`: Nổi và tự động căn giữa tỉ lệ 75% chiều rộng $\times$ 80% chiều cao màn hình.
   - `Super + F`: Native C `togglefullscreen` bung to 100% diện tích và thu nhỏ ngược lại.
   - `Alt + Tab`: Mở bộ chọn cửa sổ Rofi, tự động nhảy đúng Tag/Monitor và đưa con trỏ chuột vào giữa cửa sổ vừa chọn.
4. **Tỉ lệ vàng Rofi**: Thu nhỏ khung Rofi từ 800px xuống 580px (~42% màn hình), font 11pt, icon 20px, 6 dòng $\times$ 2 cột giúp giao diện thanh thoát, không bị cảm giác zoom to.
5. **Hộp thoại Tệp GTK**: Ghim các thư mục hay dùng (Downloads, Repos, Documents, Dotfiles...) vào thanh bên trái và mặc định sắp xếp file mới nhất lên đầu (`modified descending`).

## Next steps
1. Trên máy local, chạy biên dịch DWM phiên bản mới nhất:
   ```bash
   ./scripts/.local/bin/ka-setup suckless
   ```
2. Đăng xuất và đăng nhập lại DWM (`Super + Shift + Q`) để kích hoạt toàn bộ hotkey và cơ chế focus cửa sổ mới.
3. Kiểm tra các thay đổi tài liệu và commit:
   ```bash
   git add AGENTS.md OMARCHY_X11_HANDOFF.md docs/handoff/
   git commit -m "docs: update AGENTS.md, OMARCHY_X11_HANDOFF.md and handoff log"
   ```
4. Đẩy toàn bộ các commit lên remote repository:
   ```bash
   git push origin main
   ```

## Blockers
N/A

## Prior handoff
`docs/handoff/2026-09-13-201344_handoff-fonts-dwm-optimization.md`

## Suggested skills
- `git-guardian`: Quản lý commit và push an toàn lên remote branch `main`.
- `ka-ops`: Hỗ trợ quản lý và triển khai Docker/container tối giản nếu cần.
