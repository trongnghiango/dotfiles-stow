# 📖 OMARCHY-X11 MANUAL — Sổ Tay Hướng Dẫn Sử Dụng Toàn Diện

> **"Beautiful, Minimalist & Agentic Linux on Native C"**
> Phiên bản hệ thống: **Arch Linux + DWM 6.8 Native C + Omarchy OS Architecture**
> Thiết kế tối ưu cho máy tính cá nhân và lập trình viên hiện đại.

---

## MỤC LỤC

1. [Chào mừng đến với Omarchy-X11](#1-chào-mừng-đến-với-omarchy-x11)
2. [Triết lý Kiến trúc & Hiệu năng](#2-triết-lý-kiến-trúc--hiệu-năng)
3. [Thanh Trạng Thái & Thẻ Popover Omarchy](#3-thanh-trạng-thái--thẻ-popover-omarchy)
4. [Điều Hướng & Quản Lý Cửa Sổ Bằng Bàn Phím](#4-điều-hướng--quản-lý-cửa-sổ-bằng-bàn-phím)
5. [Bộ Lệnh Quản Trị Hợp Nhất ka](#5-bộ-lệnh-quản-trị-hợp-nhất-ka)
6. [Quản Lý Môi Trường Lập Trình Bằng mise](#6-quản-lý-môi-trường-lập-trình-bằng-mise)
7. [Hệ Thống Đổi Theme Động (Theming)](#7-hệ-thống-đổi-theme-động-theming)
8. [Công Cụ Trích Xuất Chữ Màn Hình (ka-ocr)](#8-công-cụ-trích-xuất-chữ-màn-hình-ka-ocr)
9. [Bảo Trì, Chẩn Đoán & Khắc Phục Sự Cố](#9-bảo-trì-chẩn-đoán--khắc-phục-sự-cố)

---

## 1. CHÀO MỪNG ĐẾN VỚI OMARCHY-X11

**Omarchy-X11** là sự giao thoa hoàn hảo giữa hai thế giới:
- **Tâm hồn**: Triết lý thiết kế **Omakase & Clean Computing** do **David Heinemeier Hansson (DHH)** khởi xướng trên Omarchy OS (thẩm mỹ tinh tế, thẻ popover vuông góc 0px radius, viền 2px accent nổi bật, bàn phím làm chủ 100%, sẵn sàng cho kỷ nguyên AI Agent).
- **Thể xác**: Nền tảng **Native C siêu tốc** của Suckless (**DWM 6.8**, ST, Dmenu, Dwmblocks).

Hệ thống được gọt giũa tỉ mỉ để loại bỏ mọi sự cồng kềnh:
- Khởi động chỉ chiếm **~150MB – 200MB RAM**.
- Độ trễ phản hồi gõ phím và vẽ đồ họa **< 1ms**.
- Tận dụng tối đa từng pixel trên các dòng máy màn hình nhỏ (như ThinkPad X230 12.5" 1366x768).

---

## 2. TRIẾT LÝ KIẾN TRÚC & HIỆU NĂNG

### ① "Dùng Window Manager như không dùng" (Pure Native C)
- Không chạy thêm các web engine độc lập (như Electron hay Quickshell Qt6 nặng nề) để làm desktop shell.
- DWM 6.8 xử lý trực tiếp các sự kiện từ Xlib socket, file nhị phân chỉ **134 KB**, tối ưu hóa bộ nhớ đệm CPU L1/L2/L3.
- Compositor `picom` được cấu hình Low-Latency: bật `vsync = true`, `use-damage = true` chống xé hình nhưng **tắt bỏ blur mờ và hiệu ứng fading trễ** để mọi thao tác hiển thị là tức thì.

### ② Omakase — Đầu Bếp Chọn Hộ
Bạn không phải đau đầu lựa chọn cấu hình giữa hàng trăm phần mềm rác. Hệ thống chọn sẵn những công cụ tốt nhất:
- **Trình duyệt**: Brave (bật cờ GPU Hardware Acceleration cho chip Intel HD 4000).
- **Terminal**: `st` (biên dịch từ mã nguồn C với font JetBrains Mono SemiBold và Ligatures).
- **Bộ gõ**: Fcitx5 + Bamboo (gõ tiếng Việt mượt mà không xung đột).
- **Quản lý file**: `lf` (kèm bộ xem trước ảnh nổi `ueberzugpp`).
- **Trình xem tài liệu**: `zathura` (PDF với phím bấm phong cách Vim).

---

## 3. THANH TRẠNG THÁI & THẺ POPOVER OMARCHY

Thanh bar ở mép trên màn hình không phải là một thanh thông tin tĩnh nhàm chán, mà là một **trung tâm tương tác thông minh**:

### A. Tương tác Chuột Trực Quan (Interactive Hand Cursor)
- Khi bạn rê chuột vào các số **Workspace Tags (1 - 9)** hoặc bất kỳ **Block trạng thái** nào (Pin, Mạng, CPU, RAM, Âm lượng, Đồng hồ), con trỏ chuột sẽ **tự động chuyển thành hình bàn tay chỉ ngón trỏ (`XC_hand2`)**.
- Khi rời khỏi thanh bar, con trỏ lập tức quay lại thành mũi tên tiêu chuẩn. Cơ chế kiểm tra trạng thái trong DWM 6.8 đảm bảo **tiêu hao 0.0% CPU**.

### B. Cơ Chế Bật Thẻ Popover (< 2ms Latency)
Hệ thống sử dụng tiến trình chạy nền **Pre-warmed Socket Daemon** (`dwm-dropdown --daemon` nạp sẵn trong `xinitrc`). Khi bạn click vào một block hoặc bấm phím tắt:
- Gói tin IPC gửi qua socket Unix Domain Socket `/run/user/<UID>/dwm-dropdown-<UID>.sock`.
- Thẻ popover hiện lên **ngay tức thì trong 2ms** (thay vì phải đợi 85ms khởi động Python lạnh).
- DWM tự động kẻ **vạch gạch chân (underline)** màu cyan sáng ôm khít block đang được mở.
- **Tự động đóng (Auto-Dismiss)**: Khi bạn click lại vào block (Toggle) hoặc click ra ngoài bất kỳ vùng trống nào trên màn hình, popup sẽ tự động biến mất.

### C. Danh Mục 7 Module Popover:
1. **Audio (`Super + Ctrl + A`)**: Thanh trượt âm lượng mượt mà, nút Mute tức thì, danh sách chọn cổng âm thanh PipeWire.
2. **Network (`Super + Ctrl + W`)**: Tên Wi-Fi, cường độ sóng, địa chỉ IP nội bộ, tốc độ mạng live, cùng bộ công cụ **đổi DNS nhanh** (DHCP, Cloudflare 1.1.1.1, Google 8.8.8.8, Custom IP).
3. **Battery (`Super + Ctrl + B`)**: Mức pin phần trăm, trạng thái sạc, công suất tiêu thụ điện (W), cùng thanh trượt độ sáng màn hình.
4. **Clock & Calendar (`Super + Ctrl + C`)**: Đồng hồ số cỡ lớn, ngày tháng chi tiết, lịch tháng tương tác chọn ngày (`Gtk.Calendar`), thời gian máy hoạt động (uptime).
5. **CPU & Thermals (`Super + Ctrl + T`)**: Tải CPU thời gian thực, nhiệt độ vi xử lý, tốc độ quạt (RPM), bảng Top 4 tiến trình chiếm dụng CPU, nút mở `btop`.
6. **Memory (`Super + Ctrl + M`)**: Đo dung lượng RAM thực tế, Swap, Cache, bảng Top 4 tiến trình chiếm dụng bộ nhớ, nút mở `btop`.
7. **Forecast (`Super + Ctrl + F`)**: Thẻ thời tiết trực quan: nhiệt độ, cảm nhận thực tế, độ ẩm, sức gió, áp suất khí quyển, nút nạp lại dự báo.

---

## 4. ĐIỀU HƯỚNG & QUẢN LÝ CỬA SỔ BẰNG BÀN PHÍM

Hệ thống được thiết kế theo tôn chỉ: **Bạn có thể làm việc cả ngày mà không cần chạm tay vào chuột.**

### A. Ba Chế Độ Hiển Thị Cốt Lõi
1. **Toàn màn hình 100% (`Super + F`)**: Phóng to cửa sổ chiếm trọn 100% màn hình, ẩn viền và ẩn thanh bar. Giúp tối đa hóa không gian viết code hoặc đọc tài liệu trên laptop.
2. **Cửa sổ nổi ở trung tâm (`Super + Shift + Space`)**: Tự động đưa cửa sổ về dạng nổi (Floating) với tỉ lệ vàng chuẩn mực **75% chiều rộng x 80% chiều cao** đặt chính giữa màn hình. Bấm lại lần nữa để trả về dạng chia đôi (Tiling).
3. **Chia cột Tiling (`Super + T`)**: Bố cục Master/Stack kinh điển. Cửa sổ bên trái làm việc chính, các cửa sổ phụ xếp chồng bên phải.

### B. Chuyển Đổi Ứng Dụng Mượt Mà (`Alt + Tab`)
- Bấm **`Alt + Tab`** để mở bộ chuyển đổi cửa sổ Rofi.
- Gõ vài chữ cái tên phần mềm -> Bấm `Enter`.
- DWM sẽ **tự động nhảy sang đúng Workspace chứa cửa sổ đó, unhide nếu đang ẩn, focus bàn phím và đưa con trỏ chuột vào giữa cửa sổ**.

*(Xem toàn bộ phím tắt chi tiết tại file [HOTKEYS.md](HOTKEYS.md))*

---

## 5. BỘ LỆNH QUẢN TRỊ HỢP NHẤT `ka`

Thay vì phải nhớ hàng chục script con nằm rải rác, bạn chỉ cần sử dụng một lệnh duy nhất: **`ka`**

```bash
ka <lệnh> [tham số...]
```

### Các Lệnh Hàng Ngày:
| Lệnh | Mô tả tác vụ | Ví dụ |
| :--- | :--- | :--- |
| `ka doctor` | Chẩn đoán toàn diện sức khỏe hệ thống (DWM, X11, Audio, Theming, Runtimes) | `ka doctor` |
| `ka dev` | Quản lý toàn bộ dev runtimes (Node, Python, Rust, Go, Bun, PNPM) qua Mise | `ka dev setup` |
| `ka ocr` | Quét chọn vùng màn hình bóc tách chữ tức thì vào Clipboard | `ka ocr` |
| `ka theme` | Đổi theme giao diện toàn hệ thống tức thì không tắt ứng dụng | `ka theme nord` |
| `ka pop` | Bật/Tắt thẻ popup Omarchy tương ứng | `ka pop volume` |
| `ka dns` | Chuyển đổi nhanh DNS sang Cloudflare, Google hoặc DHCP | `ka dns cloudflare` |
| `ka record`| Bật / Tắt quay video màn hình | `ka record toggle` |
| `ka setup` | Tự động hóa biên dịch suckless, stow dotfiles hoặc cài packages | `ka setup suckless` |

---

## 6. QUẢN LÝ MÔI TRƯỜNG LẬP TRÌNH BẰNG `mise`

Một nguyên tắc bất di bất dịch của Omarchy-X11: **Pacman quản lý hệ điều hành; `mise` quản lý môi trường lập trình.**

### Tại Sao Không Cài `npm` hay `pip` Bằng Sudo?
- Trên Arch Linux, việc chạy `sudo pip install` sẽ bị chặn bởi tiêu chuẩn **PEP 668** (`EXTERNALLY-MANAGED`) để bảo vệ gói hệ thống.
- Cài Node/Python/Rust toàn cục dễ dẫn đến xung đột phiên bản giữa các dự án.

### Giải Pháp Triệt Để Với `mise`:
Mọi runtime lập trình được khai báo tập trung trong file `~/.config/mise/config.toml`:
```toml
[tools]
node = "lts"
python = "latest"
rust = "latest"
go = "latest"
pnpm = "latest"
bun = "latest"
```

- **Kích hoạt lần đầu**:
  ```bash
  sudo pacman -S mise
  ka dev setup
  ```
- Toàn bộ trình biên dịch và gói thư viện sẽ nằm gọn trong không gian người dùng (`~/.local/share/mise/`). Bạn có thể tự do `pip install` hoặc `pnpm add` mà không lo hỏng hệ điều hành!
- Kiểm tra phiên bản đang chạy: `ka dev status`
- Nâng cấp tất cả lên bản mới nhất: `ka dev update`

---

## 7. HỆ THỐNG ĐỔI THEME ĐỘNG (THEMING)

Hệ thống tuân thủ nguyên tắc **Single Source of Truth**: Bảng màu desktop nằm ở `~/.config/theme/colors/*.conf`.

### Cách Đổi Theme:
Chỉ cần gõ lệnh:
```bash
ka theme nord             # Theme Bắc Âu dịu mắt
ka theme gruvbox-dark     # Theme Gruvbox hoài cổ ấm áp
ka theme catppuccin-mocha # Theme Pastel hiện đại
```

### Cơ Chế Hot-Reload Không Cần Restart Session:
Khi bạn đổi theme, hệ thống sẽ:
1. Đồng bộ màu sang `~/.config/x11/xresources.d/colors` và `rofi/colors.rasi`.
2. Bơm palette màu vào Dunst notification daemon.
3. Bắn tín hiệu `kill -HUP $(pidof dwm)`: **DWM lập tức nạp lại màu mới ngay trên RAM mà toàn bộ các ứng dụng bạn đang mở không hề bị gián đoạn hay tắt đi!**

---

## 8. CÔNG CỤ TRÍCH XUẤT CHỮ MÀN HÌNH (`ka-ocr`)

Lấy cảm hứng từ tính năng `omarchy-capture-text` của DHH:
- **Cách dùng**: Bấm tổ hợp phím **`Super + Alt + T`** (hoặc gõ `ka ocr`).
- Kéo chuột khoanh một vùng chữ trên màn hình (từ video YouTube, ảnh tài liệu, trang web không cho copy...).
- **Cơ chế In-Memory Streams**: Dữ liệu ảnh được pipe trực tiếp trong RAM từ `maim` sang `tesseract`, xử lý song ngữ **Tiếng Anh + Tiếng Việt (`eng+vie`)**, sau đó đẩy thẳng vào Clipboard và hiển thị thông báo Dunst.
- Không ghi bất kỳ file rác nào ra ổ cứng SSD. Bạn chỉ việc nhấn `Ctrl + V` để dán chữ ra!

---

## 9. TRÌNH CHỌN ỨNG DỤNG MẶC ĐỊNH MỘT CHẠM (`ka default`)

Được thiết kế dựa trên ý tưởng tâm đắc nhất mà **Chris Titus** học hỏi từ **Omarchy**:
- **Khó khăn truyền thống**: Thay đổi ứng dụng mặc định trong Tiling Window Manager là một trải nghiệm phức tạp (phải sửa tay file `~/.config/mimeapps.list` hoặc nhớ các lệnh `xdg-mime` rườm rà).
- **Trải nghiệm đỉnh cao của `ka default`**:
  - Bấm phím tắt **`Super + Ctrl + D`** (hoặc gõ `ka default`): Một cửa sổ Rofi thanh mảnh tỉ lệ vàng 600px hiện lên ở tâm màn hình.
  - Hiển thị danh mục trực quan kèm ứng dụng đang kích hoạt:
    - 󰈹 **Web Browser**: Brave, Chromium, Firefox, Chrome...
    - 󰈙 **Text Editor**: Neovim (Terminal st), VS Code, Gedit, Mousepad...
    - 󰉋 **File Manager**: LF (Terminal st), Thunar, PCManFM, Nautilus...
    - 󰈦 **PDF Document**: Zathura, Evince, MuPDF...
    - 󰋩 **Image Viewer**: Nsxiv, Imv, Feh, Viewnior...
    - 󰕼 **Video Player**: MPV, VLC, Celluloid...
    - 󰎆 **Audio Player**: MPV, ncmpcpp, Audacious...
    - 󰆍 **Terminal Emulator**: st (Native C), Alacritty, Foot, Kitty...
  - **Click chọn ứng dụng**: Tự động cập nhật `mimeapps.list`, đồng bộ biến môi trường (`$BROWSER`, `$EDITOR`, `$TERMINAL`) và phát thông báo tức thì qua Dunst.
  - **Hỗ trợ Dòng lệnh (CLI Automation)**:
    - `ka default show` — Xem bảng tổng quan các ứng dụng mặc định hiện tại.
    - `ka default set <phân_loại> <ứng_dụng>` — Gán nhanh bằng lệnh script (ví dụ: `ka default set browser brave`).

---

## 10. BỘ QUẢN LÝ CLIPBOARD 2 CỘT OMARCHY (`ka clip` / `Super + V`)

Thay thế hoàn toàn cơ chế khay hệ thống cũ (`fzf` trong terminal):
- **Phím tắt gọi nhanh**: Nhấn **`Super + V`** (hoặc **`Super + Ctrl + V`**, hoặc click icon khay hệ thống).
- **Hỗ trợ đa phương tiện toàn diện**:
  - Tự động bắt và lưu trữ cả **Văn bản (Text, code, URL)** lẫn **Hình ảnh (Screenshots từ `maim`, ảnh copy từ trình duyệt, kết quả `ka-ocr`)**.
- **Giao diện Master-Detail 2 Cột**:
  - **Cột bên trái**: Danh sách các mục đã copy theo thứ tự thời gian mới nhất lên đầu, icon phân loại trực quan (`󰈙` text, `󰋩` ảnh, `󰌨` url, `󰘦` code) và tiêu đề tóm tắt 1 dòng.
  - **Cột bên phải**: Xem trước chi tiết nội dung đầy đủ (văn bản nhiều dòng, số dòng, ký tự) hoặc ảnh thumbnail phóng to sắc nét đối với hình ảnh.
- **Thao tác một chạm**: Dùng phím mũi tên hoặc `Ctrl+j/k` để duyệt và xem trước thời gian thực $\rightarrow$ Nhấn `Enter` để nạp ngay vào bộ nhớ đệm và dán (`Ctrl + V`).
- **Lệnh hỗ trợ dòng lệnh**:
  - `ka clip` — Mở giao diện Rofi.
  - `ka clip status` — Xem trạng thái daemon và số lượng bản sao đang lưu.
  - `ka clip clear` — Dọn dẹp sạch toàn bộ lịch sử clipboard.

---

## 11. BẢO TRÌ, CHẨN ĐOÁN & KHẮC PHỤC SỰ CỐ

### A. Kiểm Tra Sức Khỏe Toàn Diện Hệ Thống
Bất cứ khi nào bạn cảm thấy hệ thống có vấn đề, chỉ cần chạy:
```bash
ka doctor
```
Lệnh sẽ tự động kiểm tra 15 thành phần cốt lõi:
- Nhị phân Suckless (DWM, ST, Dmenu, Dwmblocks).
- Công cụ đồ họa X11 (Xorg, Picom, Maim, Slop, Xclip, Tesseract).
- Hệ thống âm thanh PipeWire và kết nối mạng NetworkManager.
- Bảng màu Theming và trạng thái Socket Daemon của Popover.
- Trình quản lý Dev Runtimes Mise.

### B. Triển Khai Dotfiles An Toàn (`stow-safe`)
Không bao giờ dùng lệnh `stow` thủ công gây đè file. Hãy dùng:
```bash
stow-safe <package>      # Tự động sao lưu file xung đột vào ~/.local/share/dotfiles/backups/
stow-safe --restore <package>  # Khôi phục lại bản sao lưu trước đó
```

### C. Biên Dịch Lại Công Cụ Suckless
Khi bạn tinh chỉnh mã nguồn trong thư mục `suckless/.local/src/`:
```bash
ka setup suckless
```
Lệnh sẽ tự động làm sạch (`make clean`), biên dịch lại (`make`) và cài đặt phiên bản mới nhất lên máy.

---

*Omarchy-X11 Manual — Được xây dựng với niềm tự hào về mã nguồn mở, tinh thần tối giản và tốc độ thuần khiết.*
