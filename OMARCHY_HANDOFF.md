# Handoff: Tích hợp Kiến trúc Omarchy & Dotfiles (Hybrid)

Tài liệu này tóm tắt ngữ cảnh, quyết định kiến trúc và trạng thái của hệ thống `.dotfiles`. Mục đích là để làm "điểm neo" (anchor) cung cấp bối cảnh nhanh chóng cho các phiên làm việc mới của AI trợ lý.

## 1. Triết lý Kiến trúc: Mô hình Lai (Hybrid)
Hệ thống kết hợp sự ổn định của **Omarchy** (Hệ điều hành cốt lõi) và sự cá nhân hóa của **Dotfiles** cũ (Công cụ Terminal).
- **Phần Xác (Omarchy đảm nhận):** Quản lý môi trường Desktop (Wayland/Hyprland), quản lý phần cứng (Udiskie cho USB/MTP), giao diện hệ thống (GTK/Fonts), Clipboard (QML module), Bluetooth (Control Panel), và Snapshot hệ thống (Btrfs).
- **Phần Hồn (Dotfiles đảm nhận):** Trải nghiệm Terminal chuyên sâu (Zsh, Neovim, Tmux, LF, Fcitx5, Media TUI) được quản lý và deploy an toàn qua công cụ `stow-safe`.

## 2. Quy tắc Ghi đè (Overrides) & Dọn dẹp
Chúng ta đã thống nhất chiến lược cái gì nên ghi đè và cái gì nên bỏ để tránh xung đột với Omarchy:

### ✅ Các Module BẮT BUỘC Ghi Đè (Stow)
Đây là các cấu hình mang tính cá nhân hóa cực cao của Power-User:
- **`shell` & `zsh`**: Zsh là shell mặc định (thay thế Bash của Omarchy). Kiến trúc sạch sẽ: nạp biến môi trường từ `~/.config/shell/profile` vào `~/.zprofile`, toàn bộ config zsh bị ép vào `~/.config/zsh` (chuẩn XDG).
- **`nvim`**: Cấu hình Lua custom (ghi đè LazyVim mặc định của Omarchy).
- **`tmux`**: Prefix `C-Space` và Vi-mode (ghi đè Tmux mặc định của Omarchy).
- **`opencode`**: Khai báo 9Router Gateway và custom LLM models.
- **`fcitx5`**: Bộ gõ tiếng Việt Bamboo Telex.
- **`media`**: Cấu hình `mpv` tối ưu Pipewire, `mpd` daemon và `ncmpcpp` TUI (đã gỡ bỏ sạch sẽ mã rác gọi tín hiệu cho `dwmblocks` của X11 cũ).
- **`lf`**: File manager thuần Terminal.

### ❌ Các Module ĐÃ BỊ XÓA (Thuộc về dĩ vãng X11/DWM)
Để đạt độ sạch sẽ 100%, các script TUI thủ công sau đã bị thanh trừng vì Omarchy đã có Native UI thay thế xịn hơn:
- Quản lý ổ đĩa: `mounter`, `unmounter`, `mount-crypt-lvm` (Dùng `udiskie` của Omarchy).
- Quản lý Bluetooth: Thư mục `user/bt*` (Dùng Omarchy Bluetooth Panel).
- Quản lý Clipboard: `clipboard-tray` (Dùng Omarchy Clipboard).
- Quản lý Menu/Shortcuts: `dashboard`, `shortcuts`, và các file sinh tự động như `shortcutrc` (Dùng Omarchy Launcher).
- Giao diện GUI: `gtk` và `fontconfig` đã bị xóa khỏi repo để nhường quyền quản lý cho Omarchy Wayland, tránh xung đột xé hình hoặc lỗi font.

## 3. Tiêu chuẩn Scripting (Quy chuẩn Wayland)
Bất kỳ script CLI nào viết thêm vào `scripts/.local/bin/` bắt buộc tuân theo:
- **Picker**: Bắt buộc dùng `fzf` (đã thay thế toàn bộ `dmenu`).
- **Clipboard**: Bắt buộc dùng `wl-copy` / `wl-paste` (đã thay thế `xclip`).
- **Hình ảnh**: Dùng `imv` (Wayland native) thay cho `nsxiv`.
- **Thông báo**: Dùng `notify-send` tiêu chuẩn.

## 4. Công cụ Quản lý Cốt lõi
- **`stow-safe`**: Script bọc `stow` do chúng ta tự viết. Tự động sao lưu cấu hình cũ bằng timestamp, báo lỗi rõ ràng nếu có conflict symlink.
- **`ka-setup stow`**: Lệnh duy nhất cần nhớ để deploy toàn bộ dotfiles cá nhân đè lên Omarchy một cách an toàn.

---
> **Hướng dẫn cho AI ở Session Mới:** 
> Nếu bạn đọc được file này, có nghĩa là hệ thống đã được "dọn dẹp" (purged) cực kỳ sạch sẽ. Nhiệm vụ của bạn là duy trì kiến trúc Hybrid này. Bất cứ khi nào User yêu cầu cài đặt hoặc tạo script mới, hãy kiểm tra xem Omarchy có tính năng Native nào thay thế được không trước khi tự code manual script. Tuyệt đối không sử dụng công cụ của X11.
