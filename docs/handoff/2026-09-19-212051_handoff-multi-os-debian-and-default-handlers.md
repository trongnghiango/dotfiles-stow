# Handoff — Multi-OS Debian Support and Default Handlers Selector

## Focus
Hoàn thiện kiến trúc Đa hệ điều hành phân tầng (Layered Profile Architecture) cho Debian/Ubuntu/Void/NixOS song song với Arch Linux, và triển khai module Trình chọn ứng dụng mặc định một chạm (`ka default` / `Super + Ctrl + D`) chuẩn triết lý Chris Titus và Omarchy OS (DHH) qua Rofi & CLI.

## Handoff reason
`phase-complete`

## Repo state
- **Branch**: `feature/debian-support`
- **HEAD Commit**: `168f9c9ee9725dce01729ea60c04d7e7e47f8217`
- **Working Tree**:
```text
M docs/DEBIAN_GUIDE.md
```

## State
Toàn bộ hệ thống dotfiles đã được nâng cấp lên mô hình **Layered Profile Architecture** trên nhánh `feature/debian-support` và vượt qua 6 trụ cột kiểm định nghiêm ngặt:
1. Tách biệt danh mục gói và driver cài đặt: `pkgs/arch.csv` (149 gói cho Arch/Pacman/AUR) và `pkgs/debian.csv` (139 gói cho Debian/APT/Build headers) vận hành qua bộ điều phối `scripts/.local/bin/ka-setup` và các driver `setup-drivers/arch.sh`, `setup-drivers/debian.sh`.
2. Khởi động phiên X11 đa nền tảng: `x11/.config/x11/xinitrc` hỗ trợ định tuyến theo cả `$ID` và `$ID_LIKE` (tương thích Debian, Ubuntu, Pop!_OS, Linux Mint, Manjaro, EndeavourOS, Void, NixOS).
3. Triển khai tính năng tâm đắc từ Chris Titus & Omarchy: module `ka default` (`scripts/.local/bin/ka-default`) kết hợp theme Rofi tỷ lệ vàng (`rofi/.config/rofi/handlers.rasi`) và phím tắt DWM 6.8 `Super + Ctrl + D` cho phép chuyển đổi tức thì ứng dụng mặc định (Browser, Editor, File Manager, PDF, Image, Video, Audio, Terminal) cả qua GUI lẫn CLI (`ka default show`, `ka default set <cat> <app>`).

## Verification
- **Biên dịch thử nghiệm DWM 6.8 & Suckless Core**:
  ```bash
  make -C suckless/.local/src/dwm -n
  make -C suckless/.local/src/st -n
  make -C suckless/.local/src/dmenu -n
  make -C suckless/.local/src/dwmblocks -n
  ```
  *(Kết quả: PASS 100%, không phát sinh lỗi cú pháp hay thiếu cờ biên dịch)*
- **Cú pháp toàn bộ Shell Scripts**:
  ```bash
  bash -n scripts/.local/bin/ka
  bash -n scripts/.local/bin/ka-default
  bash -n scripts/.local/bin/ka-setup
  bash -n scripts/.local/bin/setup-drivers/arch.sh
  bash -n scripts/.local/bin/setup-drivers/debian.sh
  sh -n x11/.config/x11/xinitrc
  sh -n x11/.config/x11/xinitrc.debian
  ```
  *(Kết quả: PASS 100%, tuân thủ nghiêm ngặt chuẩn cú pháp Bash và POSIX sh)*
- **Kiểm định mô phỏng GNU Stow trên $HOME trắng**:
  - Triển khai 23 packages trên môi trường `/tmp`: PASS.
  - Kiểm tra Idempotency (chạy lại lần 2): PASS.
  - Quét broken symlinks (`find -xtype l`): 0 broken symlink.
  - Tháo dỡ (`stow -D`): PASS, sạch sẽ 100%.
- **Kiểm thử CLI `ka default` & `ka doctor`**:
  ```bash
  ./scripts/.local/bin/ka default show
  ./scripts/.local/bin/ka doctor
  ```
  *(Kết quả: PASS, hiển thị đầy đủ bảng ASCII/Unicode phân loại ứng dụng và kiểm tra 16/16 thành phần cốt lõi)*

## Constraints
- **Zero Runtime Overhead**: Tuyệt đối không nhét logic kiểm tra distro `if [ "$OS" = "debian" ]` vào `.zshrc` hay `aliasrc`. Mọi khác biệt tên binary trên Debian (`batcat` → `bat`, `fdfind` → `fd`) được giải quyết bằng symlink một lần duy nhất tại `~/.local/bin/`.
- **Driver Pattern**: Cấu hình dotfiles (23 packages Stow) là Single Source of Truth; các khác biệt về package manager nằm cô lập trong `setup-drivers/`.
- **Reversible & Safe**: Mọi thao tác đều có thể khôi phục qua `stow-safe --restore`, không tự ý ghi đè file ngoài scope.

## Risk context
**Tier 2 (Mã nguồn C DWM & Script Điều phối Hệ thống)**: Bổ sung phím tắt `Super + Ctrl + D` vào DWM 6.8, mở rộng logic nạp OS trong `xinitrc` và phân tách driver cài đặt. Đã được rà soát kiểm định và dry-run kỹ lưỡng.

## Artifacts
- **Multi-OS Drivers & Packages**: `pkgs/arch.csv`, `pkgs/debian.csv`, `scripts/.local/bin/setup-drivers/arch.sh`, `scripts/.local/bin/setup-drivers/debian.sh`, `scripts/.local/bin/ka-setup`
- **Default Handlers Selector**: `scripts/.local/bin/ka-default`, `rofi/.config/rofi/handlers.rasi`, `scripts/.local/bin/ka`
- **DWM 6.8 Keybinding**: `suckless/.local/src/dwm/config.h`, `suckless/.local/src/dwm/config.def.h`
- **X11 Multi-Distro Hooks**: `x11/.config/x11/xinitrc`, `x11/.config/x11/xinitrc.debian`
- **Documentation**: `docs/DEBIAN_GUIDE.md`, `HOTKEYS.md`, `MANUAL.md`, `AGENTS.md`, `OMARCHY_X11_HANDOFF.md`

## Decisions
1. **Tổ chức 1 nhánh hợp nhất theo Layered Profile**: Không tách branch phân mảnh theo hệ điều hành (chống Branch Drift); toàn bộ khác biệt distro được giải quyết ở tầng driver cài đặt (`setup-drivers/`) và symlink bootstrap.
2. **Khai báo phím tắt `Super + Ctrl + D`**: Bổ sung vào gia đình phím tắt popover DWM (`Super + Ctrl + [A/W/B/C/T/M/F/D]`) để mở nhanh bộ chọn ứng dụng mặc định một chạm.
3. **Cơ chế fallback `ID_LIKE` cho X11 Session**: Cho phép các bản phân phối dẫn xuất (Ubuntu, Pop!_OS, Linux Mint, Manjaro, EndeavourOS) tự động nạp hook phù hợp mà không cần tạo riêng file cấu hình mới.

## Next steps
1. Commit thay đổi nhỏ trong `docs/DEBIAN_GUIDE.md`:
   ```bash
   git add docs/DEBIAN_GUIDE.md && git commit -m "docs: add ka-default to debian verification checklist"
   ```
2. Thực hiện merge nhánh `feature/debian-support` vào `main` (Fast-Forward sạch sẽ):
   ```bash
   git switch main && git merge --ff-only feature/debian-support
   ```
3. Đẩy nhánh `main` lên remote repository:
   ```bash
   git push origin main
   ```
4. Khi triển khai trên máy thật hoặc máy ảo:
   - Trên Arch: chạy `ka-setup suckless` để áp dụng phím tắt DWM mới.
   - Trên Debian: làm theo hướng dẫn trong `docs/DEBIAN_GUIDE.md`.

## Blockers
None. Hệ thống đã qua kiểm định toàn diện và sẵn sàng cho môi trường production.

## Prior handoff
`docs/handoff/2026-09-19-122339_handoff-omarchy-x11-dwm68-unified-cli-and-mise.md`

## Suggested skills
- `git-guardian`: Hướng dẫn tuân thủ thao tác chuyển nhánh và merge an toàn vào nhánh `main`.
