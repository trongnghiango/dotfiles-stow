# Handoff — Screen Recording (Omarchy Style), Clean Dependency Tree & Git Sync

## Focus
Tái cấu trúc Cây phụ thuộc (Parent-Child Dependency Tree) trong `progs.csv`, giải quyết trọn vẹn xung đột git rebase với `origin/main`, hoàn thiện hệ thống quay màn hình phong cách Omarchy (tùy chọn Audio/Desktop/Mic/Webcam PIP ở góc dưới bên phải 240x180), tinh chỉnh điều hướng Rofi hiện đại không bị nhảy mode, và bổ sung hỗ trợ DWM native floating/fullscreen/window-switcher.

## Handoff reason
`user-initiated`

## Repo state
- **Branch**: `main`
- **HEAD commit**: `0a0a8dd5d341bd211f0a6d784c43f415973fe48f`
- **Working Tree**: Clean (`git status --short` is empty)

## State
Toàn bộ hệ thống dotfiles đã được đồng bộ hoàn hảo với remote `origin/main` sau khi giải quyết triệt để xung đột rebase giữa bản sửa lỗi P0/P1/P2 và các tính năng cục bộ. File `progs.csv` được tổ chức lại thành Cây phụ thuộc rõ ràng (144 gói sạch, dọn sạch 7 gói mồ côi và tích hợp `pass/pass-otp`). Tính năng quay màn hình phong cách Omarchy (`scripts/.local/bin/record`) được tích hợp đầy đủ các chế độ thu âm thanh (Silent, Desktop, Mic, Both), cửa sổ webcam PIP dạng floating tự động neo ở góc dưới bên phải (240x180) thông qua thuộc tính `isbottomright` và rule DWM native, phím tắt `Alt+Print` 1-click toggle bật/tắt ghi hình, chỉ báo `🔴 REC` trên statusbar `dwmblocks` cho phép click chuột trái để dừng quay. Trình chọn ứng dụng Rofi đã được chuẩn hóa điều hướng Tab/Vim-keys tránh nhảy mode nhầm lẫn.

## Verification
- Mã nguồn C của DWM biên dịch thành công 100% không có lỗi:
  ```bash
  cd suckless/.local/src/dwm && make clean && make
  ```
- Mã nguồn Dwmblocks biên dịch thành công 100%:
  ```bash
  cd suckless/.local/src/dwmblocks && make clean && make
  ```
- Các script hệ thống vượt qua kiểm tra cú pháp Bash:
  ```bash
  bash -n scripts/.local/bin/ka-setup
  bash -n scripts/.local/bin/record
  bash -n scripts/.local/bin/rofi-launcher
  bash -n theme/.local/bin/theme-set
  ```
- `progs.csv` và `ka-setup pkgs` filter hoạt động chính xác cho mọi target (`core`, `dev`, `media`, `tools`, `virt`, `docker`, `music`, `bluetooth`, `otp`):
  ```bash
  ./scripts/.local/bin/ka-setup pkgs core
  ```
- Git status và tracking sạch sẽ, không còn xung đột:
  ```bash
  git status
  ```

## Constraints
- Giữ nguyên kiến trúc X11/DWM siêu nhẹ Native C, không cài thêm các web engine độc lập (như Helium).
- Duy trì tính lũy đẳng (idempotent) của `ka-setup` và `stow-safe`.
- Quản lý toàn bộ cấu hình theo chuẩn GNU Stow (23 packages đồng bộ 1:1 với thư mục).
- Mọi runtime lập trình (Node, Python, Rust, Go) quản lý qua `mise`, không cài qua global pip hay npm.

## Risk context
- **Tier 2 / Standard**: Các thay đổi liên quan đến mã nguồn C của DWM, Dwmblocks, script hệ thống quay màn hình và bộ lọc gói cài đặt.

## Artifacts
- **Commit History**:
  - `e2b31a9` `refactor(progs): organize clean parent-child dependency tree and eliminate orphaned packages`
  - `d98e292` `feat(record): emulate Omarchy screen recording with audio, webcam PIP and Alt+Print toggle`
  - `612f515` `feat(dwmblocks): support left-click on REC status indicator to stop recording`
  - `a9c3c39` `fix(rofi): eliminate accidental mode switching on Tab and streamline launcher UI`
  - `0a0a8dd` `feat(record,dwm): position webcam PIP overlay floating at bottom-right corner`
- **Key Files**:
  - `scripts/.local/bin/record`: Script quay màn hình phong cách Omarchy.
  - `scripts/.local/bin/dwmblocks-scripts/sb-record`: Module chỉ báo `🔴 REC` trên dwmblocks.
  - `suckless/.local/src/dwm/dwm.c`: Xử lý `isbottomright`, `togglefullscreen()`, `_NET_ACTIVE_WINDOW`.
  - `suckless/.local/src/dwm/config.h`: Quy tắc rule và hotkeys mới (`Alt+Print`, `Alt+Tab`, `Super+F`).
  - `progs.csv`: Bảng 144 gói theo Subsystem Parent Target.
  - `OMARCHY_X11_HANDOFF.md`: Tài liệu kiến trúc toàn diện.
  - `AGENTS.md`: Hướng dẫn vận hành repo.

## Decisions
1. **Nhất quán hóa `progs.csv` theo Cây phụ thuộc Parent Target**: Thay thế nhãn mơ hồ `core`/`opt` bằng các subsystem rõ ràng (`base`, `x11`, `dwm`, `st`, `lf`, `docker`, `music`, `bluetooth`, `otp`, `vscode`...).
2. **Loại bỏ 7 gói mồ côi / không phù hợp phần cứng**: `sof-firmware` (X230 Gen 3 kernel dùng `snd_hda_intel`, không dùng DSP firmware), `tuned`, `tree-sitter-cli`, `moreutils`, `libnewt`, `socat`, `lxappearance`.
3. **Bổ sung gói bảo mật bắt buộc**: Thêm `pass` và `pass-otp` để hỗ trợ đầy đủ script `otp`.
4. **Tích hợp công cụ quay màn hình `record`**: Thay thế `dmenurecord` cũ, hỗ trợ 1-click toggle qua phím `Alt+Print Screen`, giải quyết webcam PIP bằng mpv native với rule `isbottomright` neo ở góc dưới bên phải (240x180) cách mép 15px.
5. **Chỉ báo ghi hình dwmblocks**: Hiển thị nhãn `🔴 REC` chỉ khi đang quay (interval 0, signal 9 = 0% CPU overhead), click chuột trái vào nhãn để dừng quay.
6. **Cấu hình điều hướng Rofi**: Gán Tab/Shift-Tab cho di chuyển dòng (`kb-row-down/up`), tách biệt với lệnh chuyển mode (`Control+Tab`), bỏ mode-switcher trung gian để giao diện gọn gàng chuẩn Spotlight.

## Next steps
1. Chạy biên dịch và cài đặt lại DWM & Dwmblocks trên máy để cập nhật binary nhị phân mới nhất:
   ```bash
   ./scripts/.local/bin/ka-setup suckless
   ```
2. Đăng xuất và đăng nhập lại DWM (`Super + Shift + Q`) để nạp toàn bộ cấu hình hotkey, kích thước cửa sổ nổi và chỉ báo thanh bar mới.
3. Thử nghiệm tính năng quay màn hình:
   - Bấm `Alt + Print Screen` để mở menu chọn âm thanh & vùng quay.
   - Thử quay có Webcam PIP (nếu có cắm webcam) và xác nhận khung hình xuất hiện nhỏ gọn ở góc dưới bên phải.
   - Click chuột trái vào chữ `🔴 REC` trên thanh bar để kết thúc quay.
4. Thử nghiệm điều hướng cửa sổ Rofi:
   - Bấm `Super + Space` để tìm kiếm ứng dụng và dùng phím `Tab` để di chuyển chọn app (không còn bị nhảy mode).
   - Bấm `Alt + Tab` để mở bộ chọn cửa sổ và xác nhận DWM chuyển đúng Workspace.

## Blockers
N/A

## Prior handoff
`docs/handoff/2026-09-16-181958_handoff-omarchy-x11-pure-performance.md`

## Suggested skills
- `git-guardian`: Giám sát an toàn cho mọi thao tác git trong tương lai trên branch `main`.
- `ka-ops`: Hỗ trợ quản lý và triển khai Docker/container nếu cần mở rộng stack dịch vụ.
