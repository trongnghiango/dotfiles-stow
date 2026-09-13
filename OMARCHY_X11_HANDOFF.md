# OMARCHY_X11_HANDOFF.md — X11/DWM Optimized Architecture

> **MỤC ĐÍCH TÀI LIỆU:**
> Nhánh `main` này lưu trữ cấu hình X11/DWM nhưng được thiết kế lại dựa trên triết lý sạch sẽ, tối ưu hiệu suất, và có tổ chức của Omarchy OS (Omakub).
> Bất kỳ AI Assistant nào làm việc với nhánh này **BẮT BUỘC** phải đọc và tuân thủ các quy tắc sau để giữ cho hệ thống luôn sạch sẽ và đạt hiệu năng cao nhất.

---

## 1. Triết lý Tổ chức (Clean & Organized)

### Tích hợp mã nguồn Suckless
- **KHÔNG** lưu file binary hay mã nguồn rác rưởi vào `scripts/.local/bin/` nữa.
- Toàn bộ mã nguồn cốt lõi (Core) gồm: `dwm`, `st`, `dmenu`, `dwmblocks` được đưa vào quản lý trực tiếp tại thư mục `.dotfiles/suckless/.local/src/`.
- Khi deploy, GNU Stow sẽ tự động link vào `~/.local/src/` và script `ka-setup suckless` sẽ đảm nhiệm việc `make clean install`.
- **Lợi ích**: "Single Source of Truth", 100% tự động hóa và có thể xem lịch sử git của việc thay đổi hotkey.

### Thư mục `scripts/` gọn gàng
- Các script hệ thống của DWM/statusbar phải nằm trong `scripts/.local/bin/dwmblocks-scripts/`.
- Các dmenu script phải nằm trong `scripts/.local/bin/dmenu-scripts/`.
- `scripts/.local/bin/` root chỉ dành cho các công cụ CLI mà người dùng (user) trực tiếp gõ vào terminal (như `gm`, `otp`).
- Biến `$PATH` đã được khai báo sẵn trong `shell/.config/shell/profile` để tự động load các thư mục con này.

### XDG Base Directory Tối đa
- Mọi thứ tuân thủ tuyệt đối chuẩn XDG (`~/.config/`, `~/.local/`, `~/.cache/`). 
- Nếu một ứng dụng cố tình tạo file rác ở `$HOME`, phải tìm cách đưa nó vào XDG thông qua `profile` hoặc `alias`.

---

## 2. Tối ưu Hiệu suất Tối đa (Max Performance)

Dù mượn các ý tưởng xịn sò của Omarchy, chúng ta phải giữ được tốc độ "bàn thờ" của X11/DWM.

### LF File Manager
- **Hình ảnh**: Giữ lại `ueberzug` làm engine preview hình ảnh vì trên X11/st, nó là giải pháp hiển thị ảnh sắc nét, mượt mà và native nhất (Vượt trội hơn chafa/sixel fallback).
- **Thư mục**: Dùng `eza --tree` siêu tốc để xem trước cấu trúc thư mục.
- **Văn bản**: Dùng `bat` để syntax highlight.
- **Tìm kiếm**: Đã tích hợp tính năng siêu việt `fzf_search` (Ctrl+F) kết hợp `ripgrep` và `fzf` để tìm kiếm nội dung file nhanh nhất thế giới.

### Zsh & Shell
- Đồng bộ cấu hình Zsh từ nhánh omarchy: Lịch sử vô hạn (persistent history), chống trùng lặp, tối ưu tìm kiếm lịch sử nhanh bằng phím mũi tên (history-beginning-search).

### Ứng dụng
- Giữ lại các ứng dụng X11 nhẹ nhất: `nsxiv` (xem ảnh), `mpv` (xem video GPU decode), `zathura` (đọc PDF).

---

## 3. Bộ Hotkey Chuẩn (Omarchy Style cho DWM)

Khi sửa mã nguồn trong `dwm/config.h`, tuân theo chuẩn phím tắt sau để có UX hiện đại:
- **`Super + Enter`**: Mở Terminal (`st`)
- **`Super + W`**: Mở Trình duyệt (`brave`)
- **`Super + E`**: Mở File Manager (`lf`)
- **`Super + Space`**: Mở Dmenu/Rofi
- **`Super + Shift + Q`**: Thoát DWM
- **`Super + Q`**: Đóng cửa sổ (killclient)

---
> **LỜI NHẮC CHO AI TRỢ LÝ:**
> Hãy luôn kiểm tra `OMARCHY_X11_HANDOFF.md` trước khi sửa bất kỳ file nào. 
> Mục tiêu tối thượng: **SIÊU NHANH (DWM) - CỰC SẠCH (Omarchy) - TỰ ĐỘNG HÓA CAO (ka-setup).**
