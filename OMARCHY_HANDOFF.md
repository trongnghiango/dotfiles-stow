# Handoff: Chiến lược Tích hợp Omarchy & Dotfiles

Tài liệu này tổng hợp toàn bộ nội dung thảo luận và các quyết định kiến trúc nhằm nâng cấp hệ thống `.dotfiles` từ nền tảng Arch/X11 cũ sang kiến trúc lai tạo với Omarchy (Wayland/Btrfs).

## 1. Bối cảnh & Phân tích Hiện trạng
Hệ thống `.dotfiles` ban đầu được xây dựng cho một môi trường Arch Linux tuỳ biến sâu (Suckless: DWM, st, dmenu, x11) quản lý qua GNU Stow.
*   **Ưu điểm cũ:** Rất nhẹ, siêu nhanh, thuần bàn phím (keyboard-centric).
*   **Hạn chế cũ:** Chạy trên nền X11 (lỗi thời, xé hình, quản lý đa màn hình kém), khó bảo trì, và rủi ro cao khi cập nhật (rolling-release break).

## 2. Giải pháp: Lai tạo với Omarchy
Chúng ta quyết định áp dụng mô hình "Hybrid": Sử dụng **Omarchy** làm lõi hệ điều hành (Phần Xác) và giữ lại **`.dotfiles`** cá nhân (Phần Hồn).
*   **Omarchy cung cấp:** Wayland (Hyprland mượt mà), Hệ thống Snapshot Btrfs (an toàn tuyệt đối, dễ rollback), và Kênh Cập nhật (Channels) để kiểm soát độ ổn định của Arch.
*   **Dotfiles cung cấp:** Trải nghiệm CLI quen thuộc (Neovim, Tmux, Zsh, LF...) quản lý chuyên nghiệp bằng `GNU Stow`.

## 3. Các đặc tả Kiến trúc Omarchy (Nghiên cứu từ Tài liệu gốc)
*   **Thư mục hệ thống vs cá nhân:** Omarchy để config gốc ở `/usr/share/omarchy/`. Mọi tùy biến của người dùng phải nằm ở `~/.config/`.
*   **Tương thích với Stow:** Tài liệu chính thức của Omarchy khuyên dùng `Stow` để quản lý các tuỳ biến trong thư mục `~/.config/`.
*   **Kiến trúc cấu hình Hyprland (Lua):** Không dùng file `.conf` thông thường. Omarchy chia Hyprland thành các file `.lua` (`bindings.lua`, `autostart.lua`, `monitors.lua`...).
*   **Event Hooks:** Hỗ trợ chạy script tự động tại `~/.config/omarchy/hooks/` (ví dụ: `post-update`, `battery-low`).
*   **Quản lý Alias/Function:** Omarchy ưu tiên đặt bash alias và custom functions vào `~/.bashrc` để không bị ghi đè khi update.

## 4. Kế hoạch Triển khai (Đang thực hiện)
Nhánh Git hiện tại: `feature/omarchy-hybrid`

### Các bước tiếp theo cần làm trên nhánh này:
1.  **Dọn dẹp X11:** Xóa/ẩn các module `dwm`, `st`, `dmenu`, `picom`, `x11`.
2.  **Tái cấu trúc thư mục:** Chuẩn bị sẵn module `hyprland` trong dotfiles với cấu trúc `hyprland/.config/hypr/` để chuẩn bị chứa các file `.lua` override phím tắt (keybindings).
3.  **Tối ưu danh sách cài đặt (`progs.csv`):** Bỏ các ứng dụng GUI mà Omarchy đã cài sẵn (như Foot terminal, Chromium) và các gói Suckless tự compile.
4.  **Kiểm soát Xung đột:** Viết thêm một hàm nhỏ vào script setup (hoặc thực hiện thủ công) để xoá các thư mục cấu hình mặc định (như `~/.config/nvim`, `~/.bashrc`) do Omarchy tự sinh ra, trước khi chạy lệnh `stow`.

## 5. Lưu ý An toàn
Tận dụng tối đa Btrfs của Omarchy: Luôn tạo Snapshot hệ thống trước khi chạy lệnh `stow` hàng loạt để tránh vỡ giao diện Hyprland. Nếu lỗi xảy ra, chỉ cần Reboot và chọn Snapshot cũ từ menu Boot.
