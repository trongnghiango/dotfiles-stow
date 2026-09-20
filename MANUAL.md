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

Thanh bar ở mép trên màn hình được tái thiết kế toàn diện theo chuẩn **Omarchy OS 4.x.x ("Quattro")**, đóng vai trò là **trung tâm quan sát nhẹ nhàng (quiet awareness)** kết hợp **điều khiển một chạm tức thì**:

```text
┌───────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│ [1][2] 3 4 5  []=  Neovim       Tue · 15:35 󰖗         []  [󰕾] [󰁹] [󰤨] [󰍛] [󰘚]  [ 󰂚 ]                 │
│ └─────── LEFT SECTION ───────┘  └── MIDDLE SECTION ─┘   └── TRAY ──┘  └── DWMBLOCKS HARDWARE & NOTIFY ───────┘ │
└───────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

### A. Bố Cục 3 Phân Vùng Chuẩn Omarchy 4.x.x
1. **Left Section (Không gian làm việc & Cửa sổ)**:
   - Tags (1 - 9) + Layout Symbol (`[]=`) + Tiêu đề cửa sổ active (`wintitle`).
   - Tự động co giãn nhưng luôn nhường chỗ cho khối Middle ở giữa.
2. **Center Section (Trung tâm màn hình — Dead-Center)**:
   - Hiển thị theo định dạng tối giản: `Tue · 15:35  󰖗` (Thứ · Giờ:Phút kèm Icon thời tiết nhịp sinh học).
   - Tự động đổi icon theo ngày/đêm: `󰖙` (Nắng ngày), `󰖕` (Nắng mây), `󰖔` (Trăng đêm), `󰼱` (Trăng mây), `󰖗` (Mưa đêm).
   - Click vào giờ mở Lịch/Đồng hồ; click vào thời tiết mở Thẻ dự báo khí quyển.
3. **Collapsible Left-Systray (Khay hệ thống thu gọn)**:
   - Đặt sang **bên trái** khối dwmblocks: Giúp các icon phần cứng ở mép phải có **tọa độ cố định vĩnh viễn**, không bao giờ bị xê dịch khi có app mở khay.
   - Thu gọn mặc định bằng chevron ``. Click vào sẽ bung ra thành `` và hiển thị toàn bộ icon (`ka-clip`, `fcitx5`...).
   - Toàn bộ khoảng cách đệm (spacing) đồng nhất 8px, kích thước icon 15px tạo padding trên/dưới 5px cân đối với thanh bar 25px.
4. **Right Section (Chỉ báo phần cứng đơn sắc & Chuông thông báo)**:
   - Chuẩn Omarchy: **KHÔNG text %, KHÔNG emoji hoạt hình đa sắc**. Dùng Nerd Font Glyphs đơn sắc thuần khiết: `sb-record` (`🔴 REC`), `ka-volume` (`󰕾`), `ka-battery` (`󰁹`), `ka-network` (`󰤨`), `ka-cpu` (`󰍛`), `ka-memory` (`󰘚`), `sb-notify` (`󰂚`/`󰂞`/`󰂛`).
   - Cảnh báo màu đỏ (`^C1^`) duy nhất khi pin < 15% hoặc CPU quá tải > 80%.

### B. Cơ Chế Bật Thẻ Popover & Sidebar (< 2ms Latency)
Hệ thống sử dụng tiến trình chạy nền **Pre-warmed Socket Daemon** (`dwm-dropdown --daemon` nạp sẵn trong `xinitrc`). Khi bạn click vào một block hoặc bấm phím tắt:
- Gói tin IPC gửi qua Unix Domain Socket `/run/user/<UID>/dwm-dropdown-<UID>.sock`.
- Thẻ popover hiện lên **ngay tức thì trong 2ms** (thay vì phải đợi 85ms khởi động Python lạnh).
- DWM tự động kẻ **vạch gạch chân (underline)** màu cyan sáng ôm khít mép container `MAX(ab_w, bh)`, **thẳng hàng 100% với viền trái của cửa sổ**.
- **Tự động đóng (Auto-Dismiss)**: Khi bạn click lại vào block (Toggle), click ra ngoài màn hình, hoặc bấm `Esc`/`q`, popup/sidebar tự động biến mất và thanh underline được xóa sạch ngay lập tức.

### C. Danh Mục 8 Module Dropdown & Sidebar:
1. **Audio (`Super + Ctrl + A`)**: Thanh trượt âm lượng mượt mà, nút Mute tức thì, danh sách chọn cổng âm thanh PipeWire.
2. **Network (`Super + Ctrl + W`)**: Tên Wi-Fi, cường độ sóng, địa chỉ IP nội bộ, tốc độ mạng live, cùng bộ công cụ **đổi DNS nhanh** (DHCP, Cloudflare 1.1.1.1, Google 8.8.8.8, Custom IP).
3. **Battery (`Super + Ctrl + B`)**: Mức pin phần trăm, trạng thái sạc, công suất tiêu thụ điện (W), cùng thanh trượt độ sáng màn hình.
4. **Clock & Calendar (`Super + Ctrl + C`)**: Đồng hồ số cỡ lớn, ngày tháng chi tiết, lịch tháng tương tác chọn ngày (`Gtk.Calendar`), thời gian máy hoạt động (uptime).
5. **CPU & Thermals (`Super + Ctrl + T`)**: Tải CPU thời gian thực, nhiệt độ vi xử lý, tốc độ quạt (RPM), bảng Top 4 tiến trình chiếm dụng CPU, nút mở `btop`.
6. **Memory (`Super + Ctrl + M`)**: Đo dung lượng RAM thực tế, Swap, Cache, bảng Top 4 tiến trình chiếm dụng bộ nhớ, nút mở `btop`.
7. **Forecast (`Super + Ctrl + F`)**: Thẻ thời tiết trực quan: nhiệt độ, cảm nhận thực tế, độ ẩm, sức gió, áp suất khí quyển, nút nạp lại dự báo.
8. **Notification Center (`Super + Shift + N`)**: Trung tâm thông báo dạng Right Sidebar full height, chiều rộng co giãn responsive 25% màn hình (340px - 500px), đọc lịch sử thông báo, nút bật/tắt DND và xóa lịch sử.

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
| `ka night` | Bật / Tắt chế độ làm việc ban đêm (Lọc ánh sáng xanh 4000K + giảm sáng) | `ka night toggle` |
| `ka notify`| Quản lý thông báo, DND và mở Notification Center Right Sidebar | `ka notify center` |
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

## 7. HỆ THỐNG ĐỔI THEME ĐỘNG (KA APPEARANCE ENGINE)

Hệ thống tuân thủ nghiêm ngặt nguyên tắc **Single Source of Truth** và kiến trúc **Official Base + Dynamic CSS Injection** (Loại bỏ 100% các theme trôi nổi bên ngoài):
- Toàn bộ tham số màu sắc, font chữ, con trỏ chuột, icon và DPI nằm ở một nơi duy nhất: `~/.config/theme/colors/*.conf`.

### A. Cách Đổi Theme:
Chỉ cần gõ lệnh:
```bash
ka theme nord             # Theme Bắc Âu dịu mát (Frost Cyan)
ka theme gruvbox-dark     # Theme Gruvbox hoài cổ ấm áp
ka theme catppuccin-mocha # Theme Pastel tím than hiện đại (Mauve)
ka theme parchment        # Theme giấy cổ điển vàng ấm (Sepia)
```

### B. Cơ Chế Bơm Màu & Hot-Reload Đa Tầng Không Cần Restart Session:
Khi bạn đổi theme, bộ điều phối `theme-set` sẽ kích hoạt chuỗi xử lý:
1. **Xresources (xrdb)**: Nạp màu ANSI, màu viền DWM `dwm.selbordercolor`, DPI `${XFT_DPI}` và gửi tín hiệu `kill -HUP $(pidof dwm)` $\rightarrow$ DWM và ST reload màu ngay trên RAM.
2. **Notification (Dunst)**: Tự động bơm block màu vào `dunstrc` và reload daemon.
3. **Menu ứng dụng (Rofi)**: Nạp màu viền và màu chọn vào `rofi/colors.rasi`.
4. **Tầng GTK3 & GTK4 (Dynamic CSS Injection)**:
   - Sử dụng theme gốc chính thức **`Adwaita-dark`** (hoặc `Adwaita` cho theme sáng) — tích hợp sẵn trên 100% các bản phân phối Linux mà không cần cài thêm gói ngoài.
   - Tự động sinh `~/.config/gtk-3.0/gtk.css` và `~/.config/gtk-4.0/gtk.css` để ghi đè các biến màu `@define-color theme_bg_color`, `@define-color theme_selected_bg_color` theo palette đang chọn.
5. **Trình duyệt Web (Brave & Brave Origin)**:
   - Đọc cờ dùng chung `~/.config/brave-flags.conf` (và symlink `brave-origin-flags.conf`) với cờ `--force-dark-mode` và `--gtk-version=4`.
   - Khi chọn **"Use GTK"**, toàn bộ giao diện Brave tự động đồng bộ màu với hệ thống.
6. **Ứng dụng Qt5 & Qt6 (VLC, qBittorrent, VirtualBox, Anki)**:
   - Nhờ biến môi trường `export QT_QPA_PLATFORMTHEME="gtk3"` trong `profile`, Qt tự động nạp plugin `libqgtk3.so` và đọc trực tiếp `gtk-3.0/gtk.css`, mang lại giao diện tối đồng nhất 100%.

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

## 10. BỘ QUẢN LÝ CLIPBOARD NATIVE GTK3 MASTER-DETAIL (`ka clip` / `Super + V`)

Thay thế hoàn toàn cơ chế khay hệ thống cũ (`fzf` trong terminal và `yad` cồng kềnh):
- **Phím tắt gọi nhanh**: Nhấn **`Super + V`** (hoặc **`Super + Ctrl + V`**, hoặc click icon khay hệ thống).
- **Cửa sổ nổi căn giữa tức thì (Centered Floating)**:
  - Tự động hiển thị nổi ở **chính giữa màn hình của Workspace hiện tại** (`ws1`, `ws2`, `ws3`...), không bị chiếm full màn hình hay kẹt ở Workspace cũ.
- **Bố cục Master-Detail chuẩn tỷ lệ vàng 2 : 3**:
  - **Cột bên trái (400px = 40% = 2 phần)**: Ô tìm kiếm thời gian thực, danh sách rút gọn theo thứ tự thời gian với số thứ tự `[01]`, icon phân loại trực quan (`󰈙` text, `󰋩` ảnh, `󰌨` url, `󰘦` code), giờ copy và tiêu đề tóm tắt.
  - **Cột bên phải (600px = 60% = 3 phần)**: Xem trước chi tiết nội dung đầy đủ:
    - *Đối với hình ảnh (Screenshot, ảnh copy, OCR)*: Hiển thị ảnh phóng to sắc nét (lên đến 540px × 320px) đúng tỷ lệ thật, thông số pixel và dung lượng.
    - *Đối với văn bản (Code, Text, URL)*: Hiển thị 100% nội dung nhiều dòng, tự động xuống dòng (`word-wrap`), không bị cắt cụt hay che khuất.
- **Khay hệ thống Native X11 (`Gtk.StatusIcon`)**:
  - Tích hợp trực tiếp vào daemon `ka-clip`, tự động vẽ icon bảng kẹp theo màu theme hiện tại từ RAM (0 file rác trên đĩa, không cần cài thêm `yad`).
- **Thao tác bàn phím thuận tiện**:
  - Phím mũi tên lên/xuống hoặc `Ctrl+j/k` để duyệt danh sách.
  - `Enter`: Nạp ngay bản sao vào Clipboard và dán (`Ctrl + V`).
  - `Del`: Xóa bản sao đang chọn khỏi lịch sử.
  - `Esc`: Đóng cửa sổ và giải phóng bộ nhớ.

---

## 11. BẢO TRÌ, CHẨN ĐOÁN & KHẮC PHỤC SỰ CỐ

### A. Kiểm Tra Sức Khỏe Toàn Diện Hệ Thống
Bất cứ khi nào bạn cảm thấy hệ thống có vấn đề, chỉ cần chạy:
```bash
ka doctor
```
Lệnh sẽ tự động kiểm tra 16 thành phần cốt lõi:
- Nhị phân Suckless (DWM, ST, Dmenu, Dwmblocks).
- Công cụ đồ họa X11 (Xorg, Picom, Maim, Slop, Xclip, Tesseract, XDG MIME).
- Hệ thống âm thanh PipeWire và kết nối mạng NetworkManager.
- Bảng màu Theming, trạng thái Socket Popovers, và Clipboard Daemon.
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
