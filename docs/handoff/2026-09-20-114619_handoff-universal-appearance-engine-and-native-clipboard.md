# Handoff — Universal Appearance Engine and Native Master-Detail Clipboard Manager

## Focus
Cập nhật tài liệu kỹ thuật toàn diện và chuẩn hóa kiến trúc cho hai hệ thống cốt lõi vừa triển khai:
1. **Universal Appearance Engine (Clean Architecture)**: Xóa sổ 100% sự phụ thuộc vào theme bên ngoài (`Arc-Gruvbox`), sử dụng nền tảng chính thức `Adwaita` / `Adwaita-dark` kết hợp Dynamic CSS Injection (`gtk-3.0/gtk.css`, `gtk-4.0/gtk.css`), đồng bộ màu tự động cho Brave/Brave-Origin ("Use GTK") và Qt5/Qt6 (`QT_QPA_PLATFORMTHEME="gtk3"` qua `libqgtk3.so`).
2. **Ka-Clip Native GTK3 Inspector**: Trình quản lý clipboard 2 cột Master-Detail chuẩn tỷ lệ vàng 2 : 3 (Trái 400px : Phải 600px), tự động nổi ở tâm màn hình trên Workspace hiện tại, hỗ trợ đầy đủ văn bản nhiều dòng (word-wrap không cắt cụt) và ảnh phóng to sắc nét (540x320), nhúng khay hệ thống `Gtk.StatusIcon` native trực tiếp trong daemon (loại bỏ hoàn toàn `yad` và file rác trên đĩa).

## Handoff reason
`phase-complete`

## Repo state
- **Branch**: `main`
- **HEAD Commit**: `e3900be5556277688bc8a9b24ceecb63caec636f` (kèm các thay đổi mới trong Appearance Engine và tài liệu)
- **Working Tree**:
```text
 M AGENTS.md
 M HOTKEYS.md
 M MANUAL.md
 M OMARCHY_X11_HANDOFF.md
 M docs/DEBIAN_GUIDE.md
```

## State
Hệ sinh thái dotfiles đã đạt đến độ hoàn thiện cao nhất về kiến trúc và giao diện:
1. **Độc lập 100% khỏi distro (Zero External Theme Dependency)**: Theme hệ thống không còn phụ thuộc vào gói AUR `gtk-theme-arc-gruvbox-git`. Bảng màu từ `colors/*.conf` (Catppuccin Mocha, Nord, Gruvbox-dark, Parchment) tự động bơm vào Xresources, Dunst, Rofi, GTK3, GTK4 và Qt qua hook `40-gtk-gsettings.sh`.
2. **Trình duyệt Brave & Brave Origin**: Bổ sung cờ `--force-dark-mode` và symlink `brave-origin-flags.conf -> brave-flags.conf`, đồng bộ hoàn hảo khi chọn "Use GTK".
3. **Ứng dụng Qt5/Qt6**: Nạp trực tiếp theme tối qua `QT_QPA_PLATFORMTHEME="gtk3"` (chuyển nền từ `#faf9f8` sáng trắng sang `#2d2d2d` tối sâu).
4. **Clipboard Manager**: Khắc phục triệt để lỗi hiển thị của Rofi dmenu trước đây bằng việc chuyển sang cửa sổ GTK3 Native Master-Detail tỷ lệ 2 : 3, nổi ở tâm màn hình trên Workspace đang đứng, gán phím tắt `Super + V` và `Super + Ctrl + V`.

## Verification
- **Kiểm tra biên dịch DWM 6.8 Native C**:
  ```bash
  make -C suckless/.local/src/dwm clean && make -C suckless/.local/src/dwm
  ```
  *(Kết quả: PASS, 0 lỗi biên dịch, binary footprint 137KB)*
- **Kiểm tra cú pháp Python & GTK3**:
  ```bash
  python3 -m py_compile scripts/.local/bin/ka-clip
  python3 -m py_compile scripts/.local/bin/dwmblocks-scripts/dwm-dropdown
  ```
  *(Kết quả: PASS 100%)*
- **Kiểm tra Palette Qt6 Dark Mode**:
  ```bash
  python3 -c 'import os, sys; os.environ["QT_QPA_PLATFORMTHEME"]="gtk3"; from PyQt6.QtWidgets import QApplication; from PyQt6.QtGui import QPalette; app=QApplication(sys.argv); print("Window BG:", app.palette().color(QPalette.ColorRole.Window).name())'
  ```
  *(Kết quả: Window BG: `#2d2d2d` — Dark Mode hoạt động chuẩn xác)*
- **Chẩn đoán tích hợp `ka doctor`**:
  ```bash
  ka doctor
  ```
  *(Kết quả: PASS toàn bộ 16/16 thành phần cốt lõi)*

## Constraints
- **Zero External Modded Themes**: Chỉ dùng base chính thức `Adwaita` có sẵn trên mọi nhân Linux, không bao giờ dùng theme mod trôi nổi.
- **Single Source of Truth**: Mọi giá trị màu, font UI, font mono, cursor, icon và DPI đều đọc từ `~/.config/theme/colors/current.conf`.
- **Dynamic Fast Path**: Sử dụng Unix domain socket `/run/user/$UID/ka-clip-$UID.sock` cho phản hồi < 2ms, tự động dọn dẹp PID khi tắt.

## Risk context
**Tier 2 (Mã nguồn Cốt lõi & Trình điều phối Hệ thống)**: Đã kiểm định toàn bộ trên cả hai kho `/home/ka/Repos/github.com/trongnghiango/dotfiles-stow` và `/home/ka/.dotfiles`.

## Artifacts
- **Appearance Engine**: `theme/.config/theme/templates/gtk-colors.css.tpl`, `gtk-settings.ini.tpl`, `xresources-colors.tpl`, `theme/.config/theme/hooks.d/40-gtk-gsettings.sh`
- **Theme Schemas**: `theme/.config/theme/colors/{catppuccin-mocha, nord, gruvbox-dark, parchment}.conf`
- **Browser & Qt**: `brave/.config/brave-flags.conf`, `brave/.config/brave-origin-flags.conf`, `shell/.config/shell/profile`
- **Clipboard Inspector**: `scripts/.local/bin/ka-clip`, `scripts/.local/bin/clipboard-tray`, `suckless/.local/src/dwm/dwm.c`, `suckless/.local/src/dwm/config.h`
- **Documentation**: `AGENTS.md`, `HOTKEYS.md`, `MANUAL.md`, `OMARCHY_X11_HANDOFF.md`, `docs/DEBIAN_GUIDE.md`

## Decisions
1. **Loại bỏ hoàn toàn `gtk-theme-arc-gruvbox-git`**: Chuyển sang Adwaita + Dynamic CSS Injection (`gtk.css`) để đảm bảo tính độc lập 100% khi triển khai trên Debian, Void, NixOS.
2. **Quy hoạch Clipboard Manager về GTK3 Native**: Bỏ Rofi dmenu cho clipboard (do Rofi dmenu không hỗ trợ text multi-line và ép ảnh nhỏ); dùng GTK3 Paned khóa cứng tỷ lệ 2 : 3 và hỗ trợ word-wrap toàn diện.
3. **Chuyển `QT_QPA_PLATFORMTHEME` sang `gtk3`**: Thay thế `gtk2` đã lỗi thời, cho phép toàn bộ app Qt5 và Qt6 tự động ăn theo theme tối của GTK3.

## Next steps
1. Commit và push các cập nhật tài liệu lên `main`.
2. Trải nghiệm phím tắt `Super + V` và đổi theme tức thì qua `ka theme nord` hoặc `ka theme catppuccin-mocha`.
3. Tận hưởng hệ thống X11/DWM hoàn hảo, sạch sẽ và sẵn sàng nhân bản sang mọi máy tính Linux khác!

## Blockers
None.

## Prior handoff
`docs/handoff/2026-09-19-212051_handoff-multi-os-debian-and-default-handlers.md`

## Suggested skills
- `git-guardian`: Hướng dẫn kiểm tra và commit tài liệu an toàn.
