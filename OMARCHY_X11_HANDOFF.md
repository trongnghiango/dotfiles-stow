# OMARCHY_X11_HANDOFF.md — X11/DWM Pure Native & Optimized Architecture

> **MỤC ĐÍCH TÀI LIỆU:**
> Nhánh `main` này lưu trữ cấu hình Arch Linux + X11 + DWM được thiết kế lại dựa trên triết lý **Omakase & Clean Computing của Omarchy (DHH)** kết hợp với **tốc độ thuần khiết Native của Suckless (C-Code)**.
> Mọi AI Assistant khi làm việc với repository này **BẮT BUỘC ĐỌC VÀ TUÂN THỦ** các nguyên tắc kiến trúc sau đây.

---

## 1. Triết lý Cốt lõi (Core Philosophy)

### ① Pure Native Performance — "Dùng WM như không dùng"
- **Không cõng engine nặng nề**: Tuyệt đối không cài thêm các web engine độc lập (như Helium, Electron bloat) khi DWM và Brave đã giải quyết được ở mức native.
- **Tiêu thụ tài nguyên tối thiểu**: Khởi động hệ thống chỉ tốn **~150MB - 200MB RAM**, độ trễ gõ phím (input latency) gần như bằng 0.
- **Low-Latency Compositor**: Giữ `picom` để chống xé hình (`vsync = true`, `use-damage = true`), nhưng **tắt bỏ blur nặng và fading trễ** để đảm bảo tốc độ phản hồi tức thì.
- **Tối ưu màn hình ThinkPad X230 (12.5" 1366x768)**: Tránh chia nhỏ màn hình vụn vặt; ưu tiên chuyển đổi mượt mà giữa **Toàn màn hình (Fullscreen)** và **Cửa sổ nổi ở trung tâm (Centered Floating)**.

### ② Omakase & Single Source of Truth
- **Một nguồn sự thật duy nhất cho màu sắc**: Bảng màu desktop nằm ở `theme/.config/theme/colors/*.conf`. Mọi ứng dụng (DWM, ST, Rofi, Dunst) đều nhận màu từ nguồn này thông qua `theme-set`.
- **Mã nguồn Suckless nằm trực tiếp trong Git**: Toàn bộ source code của `dwm`, `st`, `dmenu`, `dwmblocks` nằm trong `suckless/.local/src/`. Không clone từ GitLab hay download binary rời rạc bên ngoài.

### ③ Agentic-Ready Architecture (Thân thiện với AI)
- **Khai báo dạng bảng (`progs.csv`)**: Danh sách phần mềm được chuẩn hóa 5 cột (`TAG,NAME,TIER,DEPS,PURPOSE`) để AI đọc hiểu, phân loại và cài đặt chính xác theo từng profile.
- **Tập lệnh Lũy đẳng (`ka-setup`)**: Chạy 1 lần hay 100 lần kết quả vẫn chuẩn xác, không tạo file rác, không ghi đè trùng lặp, có cơ chế an toàn khi chạy lại.
- **XDG Base Directory 100%**: Mọi file cấu hình đưa về `~/.config/`, dữ liệu vào `~/.local/share/`, cache vào `~/.cache/`.

---

## 2. Quản lý Môi trường & Gói phần mềm

### Runtime Lập trình: Dùng `mise` (Không dùng Pacman cho dev runtimes)
- **Quy tắc**: Pacman quản lý hệ điều hành và phần cứng; **`mise` quản lý môi trường lập trình** (Node.js, Python, Rust, Go, PNPM, Bun).
- **Tránh lỗi PEP 668**: Không cài Python modules toàn cục qua `sudo pip`. Dùng `mise` để tạo môi trường dev sạch sẽ trong user space.
- **Cấu hình toàn cục**: Nằm tại `shell/.config/mise/config.toml` (tự động link qua Stow).
- **Zsh Hook**: Nạp qua `eval "$(mise activate zsh)"` trong `zsh/.config/zsh/env.zsh`.

### Danh mục Gói (`progs.csv`)
- **Profile `core` (95 Pacman + 2 AUR)**: Nền tảng DWM/X11, Fonts, Shell, Audio PipeWire, Fcitx5 Bamboo, Brave Browser, Yay.
- **Profile `dev`**: Công cụ lập trình (Neovim, VSCode, Mise, Git-delta, LazyGit).
- **Profile `media`**: Âm thanh đa phương tiện (MPD, ncmpcpp, MPV, pulsemixer, yt-dlp).
- **Profile `tools`**: Tiện ích văn phòng (Pandoc, Anki, Telegram Desktop, Zathura).
- **Profile `virt`**: Container tối giản (Docker, Docker-compose, Lazydocker). Loại bỏ hoàn toàn QEMU/Libvirt nặng nề.

---

## 3. Hệ thống Giao diện & Window Management

### Dynamic Theming (`theme-set`)
- **Lệnh điều khiển**: `theme-set [nord | gruvbox-dark | catppuccin-mocha]`
- **Cơ chế Hot-Reload không restart session**:
  1. Link `colors/current.conf` trỏ vào palette tương ứng.
  2. Sinh ra file màu `~/.config/x11/xresources.d/colors` và `~/.config/rofi/colors.rasi`.
  3. Bơm block màu vào `~/.config/dunst/dunstrc`.
  4. Chạy `hooks.d/10-xrdb.sh`: nạp `xrdb -merge` và bắn `kill -HUP $(pidof dwm)` $\rightarrow$ DWM reload màu ngay trên RAM mà cửa sổ làm việc không bị tắt.
  5. Chạy `hooks.d/20-dunst.sh` và `30-dwmblocks.sh` để đồng bộ notification và statusbar.

### Native C Window Management (DWM 6.8)
- **Nâng cấp DWM 6.8 Upstream**: Tích hợp các bản vá bảo mật và logic quan trọng nhất từ upstream DWM 6.8 (triệt tiêu Heap Overflow trong `getatomprop`, bảo toàn `_NET_ACTIVE_WINDOW` cho Proton/Steam trong `setfocus`, kiểm tra `format == 32` trong `getstate`, chặn unsigned underflow trong `drw_text`, bảo toàn errno trong `die`, và tự động resize fullscreen windows khi chuyển monitor trong `sendmon`).
- **Interactive Pointer Hand Cursor (`XC_hand2`)**: 
  - Tự động chuyển con trỏ chuột từ mũi tên sang bàn tay chỉ ngón trỏ khi rê vào các thẻ Workspace Tags (1 - 9) và các block tương tác trên dwmblocks.
  - Tự động hoàn nguyên con trỏ mũi tên mặc định khi chuột rời khỏi thanh bar (`LeaveNotify`).
  - Sử dụng cơ chế kiểm tra trạng thái `bar->cursor != cur` chỉ phát lệnh X11 khi đổi trạng thái, tiêu thụ 0.0% CPU (zero-flicker, 0ms latency).
- **Centered Floating (`Super + Shift + Space`)**: Cửa sổ nổi tự động tính toán kích thước vàng (**75% chiều rộng $\times$ 80% chiều cao**) và đặt chính xác vào **tâm giữa màn hình** ThinkPad X230. Bấm lại để quay về Tiling.
- **Toggle Fullscreen (`Super + F`)**: Chuyển đổi tức thì giữa kích thước cửa sổ hiện tại và chế độ toàn màn hình 100% (Native C function `togglefullscreen`).
- **Web App Cửa sổ Nổi (`brave-app <url>`)**: Khởi chạy trang web (YouTube, ChatGPT, Gemini...) dưới dạng ứng dụng mini không viền, tự động nổi ở giữa màn hình.
- **ROFI Window Switcher (`Alt + Tab`)**: 
  - DWM đã patch xử lý sự kiện `_NET_ACTIVE_WINDOW` trong `clientmessage()`.
  - Khi chọn cửa sổ trong ROFI (bằng `Alt + Tab` hoặc tab `WINDOWS`), DWM sẽ **tự động chuyển sang đúng Workspace/Tag đó, unhide cửa sổ nếu bị ẩn, focus bàn phím và warp con trỏ chuột vào giữa cửa sổ**.

### Hệ thống Dropdown Popover Thống Nhất (`dwm-dropdown`)
- **Triết lý Omarchy**: Mọi block trên statusbar (`dwmblocks`) khi click chuột trái đều hiển thị thẻ popup GUI sắc nét, vuông góc nguyên bản (`border-radius: 0px`), viền nổi 2px accent (`border: 2px solid @accent`), tự động nhận màu động từ `~/.config/theme/colors/current.conf`.
- **Pre-Warmed Socket Daemon (< 2ms Latency)**:
  - Khởi chạy nền daemon `dwm-dropdown --daemon` trong `xinitrc`, nạp sẵn GTK3 và CSS theme vào RAM (~25MB).
  - Lắng nghe yêu cầu bật/tắt qua Unix Domain Socket `/run/user/$UID/dwm-dropdown-$UID.sock`.
  - Thời gian hiển thị giảm từ 85ms xuống dưới **2ms** (ngang ngửa tốc độ Native C của Quickshell trên Wayland).
  - Tự động fallback chạy standalone nếu daemon chưa khởi động.
- **Cơ chế DWM Native C**:
  - Gạch chân (underline) màu cyan sáng ôm khít chính xác từng ký tự/icon của block được click (`drawstatusbar` tính toán động theo thời gian thực, không bị trôi vị trí khi CPU/Mạng nhảy số).
  - Cửa sổ dropdown neo sát mép dưới statusbar (`y = m->wy`), tự động canh lề theo trục X của block và kẹp lề màn hình an toàn.
  - Tự động đóng khi click lại vào block (Toggle) hoặc click ra ngoài màn hình (Auto-Dismiss).
- **Danh mục 7 Dropdown Modules**:
  - `dwm-dropdown volume`: Thanh trượt âm lượng (hỗ trợ cuộn chuột), nút Mute nhanh, bộ chọn cổng ra âm thanh (PipeWire `wpctl`).
  - `dwm-dropdown clock`: Giờ hiện tại cỡ lớn, ngày tháng chi tiết, lịch tháng tương tác (`Gtk.Calendar`), thời gian hoạt động hệ thống (uptime).
  - `dwm-dropdown battery`: Thanh đo pin, trạng thái sạc/xả, công suất tiêu thụ (W), thanh trượt độ sáng màn hình (`brightnessctl`).
  - `dwm-dropdown cpu`: Thanh tải CPU tổng quan, nhiệt độ phần cứng (`sensors`), tốc độ quạt (RPM), bảng top 4 tiến trình ngốn CPU, nút mở nhanh `btop`.
  - `dwm-dropdown memory`: Thanh tải RAM & Swap, dung lượng chi tiết, bảng top 4 tiến trình ngốn RAM, nút mở nhanh `btop`.
  - `dwm-dropdown network`: Thông tin Wi-Fi SSID, cường độ sóng, địa chỉ IPv4 nội bộ, tốc độ tải lên/xuống (RX/TX live throughput), nút đổi DNS trực tiếp (DHCP, Cloudflare, Google, Custom IP).
  - `dwm-dropdown forecast`: Thẻ thời tiết trực quan, nhiệt độ hiện tại & cảm nhận thực tế, độ ẩm, sức gió, áp suất khí quyển, nút nạp lại dự báo.

### Bộ Lệnh Hợp Nhất Hệ Thống (`ka`) & Trích Xuất Chữ OCR (`ka-ocr`)
- **Unified CLI (`ka`)**:
  - Quản lý toàn bộ cấu hình, theme, DNS, popover và chẩn đoán hệ thống thông qua 1 điểm vào duy nhất.
  - Hỗ trợ `ka doctor` (quét kiểm tra toàn bộ 16 thành phần cốt lõi của máy), `ka dev [setup|status|update]` (quản lý Node, Python, Rust, Go, PNPM, Bun qua Mise).
  - Hỗ trợ `ka default [show|set]` và giao diện Rofi một chạm `Super + Ctrl + D` (học hỏi từ DHH & Chris Titus: chuyển đổi tức thì trình duyệt, trình soạn thảo, file manager, PDF, image, video, terminal mà không chạm vào cấu hình text).
  - Hỗ trợ `ka clip [menu|daemon|clear|status]` và phím tắt **`Super + V`** / **`Super + Ctrl + V`**: Trình quản lý clipboard 2 cột Master/Detail (bên trái danh sách rút gọn theo thời gian, bên phải xem trước chi tiết nội dung text hoặc phóng to ảnh preview) hỗ trợ cả Văn bản và Hình ảnh/Screenshots.
- **Instant In-Memory OCR (`ka-ocr`)**:
  - Kích hoạt qua phím tắt **`Super + Alt + T`** hoặc lệnh `ka ocr`.
  - Quét vùng màn hình qua `slop` $\rightarrow$ chụp ảnh raw stdout qua `maim` $\rightarrow$ bóc tách chữ qua `tesseract` (song ngữ Anh-Việt) $\rightarrow$ đưa thẳng vào Clipboard và phát thông báo qua `dunstify` (không ghi bất kỳ file rác nào ra đĩa SSD).

### Giao diện Rofi Chuẩn Tỉ Lệ Vàng
- Chiều rộng thu gọn **580px** (thay vì 800px thô to), font **11pt**, icon **20px**, 6 dòng $\times$ 2 cột.
- Cân đối tuyệt đối ở tâm màn hình, không còn hiện tượng phóng to quá khổ.

### GTK File Chooser (Hộp thoại Upload/Download)
- **Thanh bên trái (Bookmarks)**: Khai báo sẵn trong `gtk/.config/gtk-3.0/bookmarks` (Downloads, Repos, Documents, Pictures, Videos, Dotfiles).
- **Mặc định tệp mới nhất lên đầu**: Tự động áp dụng qua GSettings trong `xprofile` (`sort-column='modified'`, `sort-order='descending'`, `sort-directories-first=true`).

---

## 4. Cấu trúc GNU Stow Packages (23 Packages)

| Package | Mô tả cấu hình |
| :--- | :--- |
| `shell/` | `profile`, `aliasrc`, `inputrc`, `mise/config.toml`, `starship.toml` |
| `zsh/` | `.zshrc`, `.zprofile` (gọi `startx` tại tty1), `env.zsh` |
| `git/` | `~/.config/git/config` với delta diff và smart aliases |
| `yay/` | `~/.config/yay/config.json` cấu hình dọn dẹp cache |
| `tmux/` | `tmux.conf` (prefix Ctrl+Space, vi mode, escape-time 0) |
| `nvim/` | Neovim IDE modular (`init.lua`, `lua/{core,plugins,utils}/`) |
| `lf/` | Trình quản lý file terminal (`lfrc`, preview ảnh `ueberzugpp`) |
| `brave/` | `brave-flags.conf` tối ưu phần cứng Intel HD 4000 & X11 |
| `input-method/`| Fcitx5 + Bamboo bộ gõ tiếng Việt (hotkeys, profile, classicui) |
| `opencode/` | Gateway AI code agents (đã có `.stow-local-ignore` chặn `node_modules`) |
| `pipewire/` | RNNoise AI khử ồn thời gian thực cho microphone |
| `media/` | Cấu hình `mpv`, `ncmpcpp`, `mpd` |
| `x11/` | `xinitrc` (D-Bus, autostart), `xprofile`, `xresources` (dùng `#if __has_include`) |
| `picom/` | Compositor tối ưu Low-Latency (vsync glx, tắt blur/fading) |
| `rofi/` | `launcher.rasi`, `config.rasi`, `colors.rasi` thiết kế tỉ lệ vàng |
| `dunst/` | Daemon thông báo với block quản lý màu tự động |
| `gtk/` | Cấu hình giao diện Arc-Gruvbox, font Inter 10, GTK bookmarks |
| `fontconfig/` | Khử font bitmap, tối ưu hiển thị chữ trên màn hình |
| `nsxiv/` | Trình xem ảnh X11 siêu nhẹ |
| `theme/` | Hệ thống theme động (`theme-set`, palettes, templates, hooks) |
| `desktop/` | XDG `mimeapps.list`, `user-dirs.dirs`, custom desktop handlers |
| `suckless/` | Source code DWM, ST, Dmenu, Dwmblocks tại `~/.local/src/` |
| `scripts/` | `~/.local/bin/` (chia thư mục `dwmblocks-scripts` và `dmenu-scripts`) |

---

## 5. Danh mục Hotkey Thiết Yếu (Ergonomic Shortcuts)

| Phím tắt | Chức năng | Ghi chú |
| :--- | :--- | :--- |
| **`Super + Enter`** | Mở Terminal | Gọi `st` native C |
| **`Super + Space`** | Menu ứng dụng | Mở `rofi-launcher` (APPS/RUN/FILES/WINDOWS) |
| **`Alt + Tab`** | Chuyển đổi cửa sổ | Mở thẳng bộ chọn cửa sổ Rofi, tự nhảy Workspace |
| **`Super + W`** | Mở trình duyệt web | Mở `brave` đã tối ưu cờ phần cứng |
| **`Super + E`** | Mở trình quản lý tệp | Mở `lf` có preview ảnh nổi `ueberzugpp` |
| **`Super + Q`** | Đóng cửa sổ hiện tại | Native C `killclient` |
| **`Super + F`** | Bật/tắt Fullscreen 100% | Native C `togglefullscreen` (cực chuẩn cho X230) |
| **`Super + Shift + Space`** | Nổi ở giữa màn hình | Nổi thông minh, tự căn giữa tỉ lệ vàng 75% $\times$ 80% |
| **`Super + [1 - 9]`** | Chuyển Workspace / Tag | Chuyển tag làm việc |
| **`Super + Shift + [1 - 9]`**| Ném cửa sổ sang Tag khác| Di chuyển cửa sổ |
| **`Super + Ctrl + A`** | Popover Audio | Bật/tắt thẻ âm lượng & output |
| **`Super + Ctrl + W`** | Popover Network | Bật/tắt thẻ Wi-Fi, IP & DNS switcher |
| **`Super + Ctrl + B`** | Popover Battery | Bật/tắt thẻ pin, công suất & độ sáng |
| **`Super + Ctrl + C`** | Popover Clock | Bật/tắt thẻ đồng hồ & lịch tương tác |
| **`Super + Ctrl + T`** | Popover CPU | Bật/tắt thẻ CPU, nhiệt độ, quạt & top processes |
| **`Super + Ctrl + M`** | Popover Memory | Bật/tắt thẻ RAM, Swap & top processes |
| **`Super + Ctrl + F`** | Popover Forecast | Bật/tắt thẻ thời tiết khí quyển |
| **`Super + Ctrl + D`** | Default Handlers | Bật/tắt menu chọn ứng dụng mặc định một chạm |
| **`Super + Alt + T`** | Instant Screen OCR | Quét vùng màn hình bóc tách chữ vào Clipboard |
| **`Super + Shift + Q`** | Đăng xuất DWM | Thoát về TTY1 |
| **`Super + F5`** | Nạp lại Xresources | DWM reload bảng màu |

---
> **LỜI NHẮC CHO CÁC AI PHIÊN TIẾP THEO:**
> - Luôn bảo đảm tính **Idempotent** của script.
> - Tuyệt đối không đưa rác và binary lạ vào `$HOME`.
> - Giữ vững tiêu chuẩn: **SIÊU NHANH (DWM/C) - CỰC GỌN (Omarchy) - TỰ ĐỘNG HÓA CAO (ka-setup).**
