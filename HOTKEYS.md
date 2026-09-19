# ⌨️ HOTKEYS.md — Bảng Tra Cứu Phím Tắt Toàn Diện (DWM 6.8 / Omarchy-X11)

Tài liệu hướng dẫn toàn bộ tổ hợp phím tắt trên hệ thống **Arch Linux + DWM 6.8 Native C + Omarchy-X11 Architecture**. Thiết kế theo triết lý **Keyboard-First (Bàn phím làm chủ 100%)**, giúp bạn điều hướng, quản lý cửa sổ và bật các popover mà không cần chạm vào chuột.

---

## 📌 QUY ƯỚC PHÍM BIỂU TƯỢNG (MODIFIERS)

| Ký hiệu | Tên phím thực tế | Ghi chú |
| :--- | :--- | :--- |
| **`Super`** | Phím **Windows** (Mod4) | Phím điều khiển chính của Window Manager |
| **`Alt`** | Phím **Alt** (Mod1) | Phím chức năng phụ và điều hướng nhanh |
| **`Ctrl`** | Phím **Control** | Kết hợp cho các thẻ Popover và phím tiện ích |
| **`Shift`** | Phím **Shift** | Đảo ngược hành vi hoặc thao tác nâng cao |

---

## 🚀 1. KHỞI CHẠY ỨNG DỤNG NHANH (APPLICATIONS)

| Tổ hợp phím | Ứng dụng / Tác vụ | Chi tiết thực thi |
| :--- | :--- | :--- |
| **`Super + Enter`** | **Terminal ST** | Mở Simple Terminal (Native C, siêu nhẹ) |
| **`Super + Space`** | **Rofi Launcher** | Menu ứng dụng tỉ lệ vàng (APPS / RUN / FILES) |
| **`Alt + Tab`** | **Window Switcher** | Danh sách cửa sổ Rofi; tự nhảy Workspace & focus |
| **`Super + W`** | **Trình duyệt Brave** | GPU Acceleration cho Intel HD 4000 |
| **`Super + E`** | **Trình duyệt file LF** | LF Terminal file manager với preview ảnh nổi |
| **`Super + Shift + E`** | **Bộ chọn Emoji** | Mở Rofi Emoji picker |
| **`Super + C`** | **Máy tính Rofi** | Rofi Calculator tính toán nhanh |
| **`Super + V`** | **Clipboard Manager** | Rofi 2 cột (Text & Ảnh): tóm tắt bên trái, xem chi tiết bên phải |
| **`Super + D`** | **Dmenu Run** | Menu lệnh cổ điển thanh mảnh ở mép trên |
| **`Ctrl + Shift + Space`**| **Bộ gõ Fcitx5** | Bật/tắt chế độ gõ tiếng Việt Bamboo |

---

## 🪟 2. QUẢN LÝ CỬA SỔ & BỐ CỤC (WINDOW MANAGEMENT)

| Tổ hợp phím | Chức năng | Mô tả chi tiết |
| :--- | :--- | :--- |
| **`Super + Q`** | **Đóng cửa sổ** | Gửi tín hiệu Native C `killclient` đóng ứng dụng đang chọn |
| **`Super + F`** | **Toggle Fullscreen** | Phóng to 100% toàn màn hình (rất thích hợp cho màn hình 12.5" X230) |
| **`Super + Shift + Space`**| **Centered Floating** | Cửa sổ nổi tự căn giữa tỉ lệ vàng **75% chiều rộng $\times$ 80% chiều cao** |
| **`Super + J`** | **Focus Next** | Chuyển tiêu điểm sang cửa sổ kế tiếp trong stack |
| **`Super + K`** | **Focus Prev** | Chuyển tiêu điểm sang cửa sổ phía trước trong stack |
| **`Super + Shift + J`** | **Move Stack Down** | Hoán đổi vị trí cửa sổ hiện tại xuống dưới |
| **`Super + Shift + K`** | **Move Stack Up** | Hoán đổi vị trí cửa sổ hiện tại lên trên |
| **`Super + Z`** | **Zoom / Swap Master**| Đưa cửa sổ hiện tại lên làm cửa sổ chính (Master) |
| **`Super + H`** | **Thu nhỏ Master** | Giảm tỉ lệ chiều rộng của cột Master (-5%) |
| **`Super + L`** | **Mở rộng Master** | Tăng tỉ lệ chiều rộng của cột Master (+5%) |
| **`Super + I`** | **Tăng số Master** | Tăng số lượng cửa sổ trong cột Master |
| **`Super + O`** | **Giảm số Master** | Giảm số lượng cửa sổ trong cột Master |
| **`Super + B`** | **Ẩn/Hiện Statusbar**| Bật/tắt thanh trạng thái trên cùng màn hình |

---

## 🗂️ 3. CÁC LOẠI BỐ CỤC (LAYOUTS)

| Tổ hợp phím | Tên bố cục | Biểu tượng | Mô tả |
| :--- | :--- | :---: | :--- |
| **`Super + T`** | **Tile Layout** | `[]=` | Bố cục Master/Stack mặc định (Master bên trái, stack bên phải) |
| **`Super + F`** | **Fullscreen** | `[F]` | Toàn màn hình không viền, không khoảng cách |
| **`Super + M`** | **Monocle Layout** | `[M]` | Mỗi cửa sổ chiếm trọn màn hình, xếp chồng lên nhau |
| **`Super + G`** | **Spiral Layout** | `(@)` | Bố cục xoắn ốc vỏ ốc Fibonacci |
| **`Super + Y`** | **Dwindle Layout** | `[\]` | Bố cục thu nhỏ đệ quy phong cách Hyprland |
| **`Super + S`** | **Gapless Grid** | `:::` | Bố cục lưới chia đều không khoảng trống |
| **`Super + R`** | **Previous Layout** | — | Hoàn nguyên bố cục vừa sử dụng trước đó |

---

## 🪟 4. CÁC THẺ POPOVER OMARCHY (OMARCHY DIRECT POPOVERS)

*Nhờ cơ chế **Pre-warmed Socket Daemon** (`dwm-dropdown --daemon`), các thẻ popover này bật/tắt tức thì trong **< 2ms**.*

| Tổ hợp phím | Thẻ Popover | Chức năng & Tương tác |
| :--- | :--- | :--- |
| **`Super + Ctrl + A`** | **Audio / Volume** | Thanh trượt âm lượng, nút Mute, bộ chọn cổng ra âm thanh PipeWire |
| **`Super + Ctrl + W`** | **Network / Wi-Fi** | Trạng thái mạng, cường độ sóng, IP, lưu lượng live, đổi nhanh DNS |
| **`Super + Ctrl + B`** | **Battery / Power** | Thanh đo pin, công suất sạc/xả (W), thanh trượt độ sáng màn hình |
| **`Super + Ctrl + C`** | **Clock & Calendar**| Giờ, ngày tháng chi tiết, lịch tương tác tháng (`Gtk.Calendar`), uptime |
| **`Super + Ctrl + T`** | **CPU & Thermals** | Tải CPU live, cảm biến nhiệt độ phần cứng, tốc độ quạt, Top 4 tiến trình |
| **`Super + Ctrl + M`** | **Memory & RAM** | Thanh tải RAM, Swap, bộ nhớ cache, Top 4 tiến trình ngốn RAM |
| **`Super + Ctrl + F`** | **Weather Forecast**| Thẻ thời tiết trực quan: nhiệt độ, cảm nhận, độ ẩm, gió, áp suất |
| **`Super + Ctrl + D`** | **Default Handlers**| Trình chọn ứng dụng mặc định một chạm (Browser, Editor, File, PDF, Image, Video, Term) |
| **`Super + Ctrl + V`** | **Clipboard Manager**| Bật/tắt giao diện quản lý clipboard 2 cột (Text & Ảnh) |

---

## 📸 5. CHỤP ẢNH, QUAY PHIM & TRÍCH XUẤT CHỮ OCR

| Tổ hợp phím | Công cụ / Chức năng | Cơ chế thực thi |
| :--- | :--- | :--- |
| **`Super + Alt + T`** | **Instant Screen OCR** | Quét chọn vùng màn hình $\rightarrow$ Bóc tách chữ (Anh+Việt) vào Clipboard |
| **`Print`** | **Chụp toàn màn hình** | Chụp toàn bộ màn hình lưu vào `~/Pictures/Screenshots/` |
| **`Ctrl + Print`** | **Chụp vùng chọn** | Kéo chuột chọn vùng cần chụp lưu vào máy và clipboard |
| **`Shift + Print`** | **Chụp cửa sổ** | Tự động chụp riêng cửa sổ đang active |
| **`Super + Print`** | **Menu Chụp Maimpick**| Mở menu dmenu tùy chọn định dạng và chế độ chụp |
| **`Alt + Print`** | **Quay video màn hình** | Bật/Tắt quay phim màn hình kèm âm thanh mic qua `record` |

---

## 🏷️ 6. WORKSPACES (TAGS) & ĐA MÀN HÌNH (MONITORS)

| Tổ hợp phím | Chức năng | Ghi chú |
| :--- | :--- | :--- |
| **`Super + [1 - 9]`** | **Chuyển Workspace** | Nhảy sang tag làm việc từ 1 đến 9 |
| **`Super + Shift + [1 - 9]`**| **Chuyển cửa sổ sang Tag** | Đưa cửa sổ đang chọn sang tag tương ứng |
| **`Super + Ctrl + [1 - 9]`** | **Xem thêm Tag** | Xem đồng thời nhiều tag trên cùng 1 màn hình |
| **`Super + Tab`** | **Previous Workspace** | Nhảy qua lại giữa 2 Workspace vừa dùng |
| **`Super + 0`** | **Xem tất cả cửa sổ** | Hiển thị toàn bộ cửa sổ của mọi tag |
| **`Super + ,` (Phẩy)** | **Focus Monitor Trái** | Chuyển chuột và tiêu điểm sang màn hình bên trái |
| **`Super + .` (Chấm)** | **Focus Monitor Phải** | Chuyển chuột và tiêu điểm sang màn hình bên phải |
| **`Super + Shift + ,`** | **Ném cửa sổ sang Monitor Trái** | Chuyển cửa sổ sang màn hình trái |
| **`Super + Shift + .`** | **Ném cửa sổ sang Monitor Phải** | Chuyển cửa sổ sang màn hình phải |

---

## 📐 7. ĐIỀU CHỈNH KHOẢNG CÁCH (VANITY GAPS)

| Tổ hợp phím | Chức năng | Mô tả |
| :--- | :--- | :--- |
| **`Super + Alt + 0`** | **Toggle Gaps** | Bật / Tắt nhanh khoảng cách giữa các cửa sổ |
| **`Super + Alt + Shift + 0`**| **Default Gaps** | Khôi phục khoảng cách mặc định (10px) |
| **`Super + Alt + U`** | **Tăng Gaps Tổng** | Tăng khoảng cách tổng thể giữa các cửa sổ (+1px) |
| **`Super + Alt + Shift + U`**| **Giảm Gaps Tổng** | Giảm khoảng cách tổng thể (-1px) |
| **`Super + Alt + I`** | **Tăng Inner Gaps** | Tăng khoảng cách giữa các cửa sổ với nhau |
| **`Super + Alt + Shift + I`**| **Giảm Inner Gaps** | Giảm khoảng cách giữa các cửa sổ với nhau |
| **`Super + Alt + O`** | **Tăng Outer Gaps** | Tăng khoảng cách giữa cửa sổ và mép màn hình |
| **`Super + Alt + Shift + O`**| **Giảm Outer Gaps** | Giảm khoảng cách giữa cửa sổ và mép màn hình |

---

## ⚡ 8. SCRATCHPADS & HỆ THỐNG (SYSTEM ACTIONS)

| Tổ hợp phím | Chức năng | Mô tả |
| :--- | :--- | :--- |
| **`Super + X`** | **Terminal Scratchpad** | Bật/tắt terminal thả nổi bí mật (rất tiện để gõ lệnh nhanh) |
| **`Super + N`** | **Đổi Theme Nhanh** | Mở menu `theme-set` đổi bảng màu ngay lập tức |
| **`Super + F5`** | **Nạp lại Xresources** | Yêu cầu DWM đọc lại màu mà không cần khởi động lại |
| **`Super + P`** / **`Super + Backspace`**| **Menu Nguồn (Sysact)** | Mở menu Tắt máy, Khởi động lại, Khóa màn hình, Sleep |
| **`Super + Shift + Q`** | **Đăng xuất DWM** | Thoát phiên DWM trở về màn hình TTY1 an toàn |

---

## 🔊 9. PHÍM ĐA PHƯƠNG TIỆN & PHẦN CỨNG (HARDWARE KEYS)

| Phím chức năng | Tác vụ thực hiện |
| :--- | :--- |
| **`XF86AudioRaiseVolume`** | Tăng âm lượng (+3%) và gửi tín hiệu cập nhật statusbar |
| **`XF86AudioLowerVolume`** | Giảm âm lượng (-3%) và gửi tín hiệu cập nhật statusbar |
| **`XF86AudioMute`** | Bật / Tắt âm thanh (Mute toggle) |
| **`XF86AudioMicMute`** | Bật / Tắt Microphone |
| **`XF86MonBrightnessUp`** | Tăng độ sáng màn hình (+5% qua `brightnessctl`) |
| **`XF86MonBrightnessDown`**| Giảm độ sáng màn hình (-5% qua `brightnessctl`) |
| **`XF86AudioPlay / Pause`**| Tạm dừng / Phát nhạc tiếp tục qua MPD (`mpc`) |
| **`XF86AudioNext / Prev`** | Chuyển bài hát tiếp theo / quay lại bài trước |
| **`XF86AudioMedia`** | Mở trình phát nhạc ncurses `ncmpcpp` |
| **`XF86Calculator`** | Mở máy tính toán số học `bc` trong terminal |
| **`XF86ScreenSaver`** | Khóa màn hình tức thì bằng `slock` và tắt màn hình (DPMS off) |
| **`XF86Sleep`** | Đưa máy tính vào chế độ ngủ đông (Sleep) |

---

## 💡 MẸO SỬ DỤNG NHANH (QUICK PRO TIPS)
1. **Lướt web / Viết code màn hình nhỏ**: Hãy dùng **`Super + F`** để mở 100% fullscreen, tận dụng từng pixel của màn hình ThinkPad.
2. **Dán chữ từ ảnh/video**: Bấm **`Super + Alt + T`**, kéo chuột khoanh vùng chữ $\rightarrow$ Bấm **`Ctrl + V`** dán thẳng vào trình duyệt hoặc Neovim.
3. **Mở nhanh thông số máy**: Bấm **`Super + Ctrl + T`** để xem CPU và quạt mà không cần mở `btop`. Bấm lại lần nữa để đóng!
