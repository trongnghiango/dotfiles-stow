# Handoff — Omarchy Statusbar Dropdowns, Streamlined Network Block & Real-time DWM Underline

## Focus
Phát triển hệ thống thẻ popup GUI Omarchy OS (`dwm-dropdown`) thống nhất cho toàn bộ statusbar (Volume, Clock & Calendar, Battery & Brightness, CPU & Thermals, Memory & Storage, Network & DNS, Forecast & Atmosphere); tinh gọn statusbar bằng cách loại bỏ module net-traffic rườm rà và gộp Wi-Fi/Ethernet vào block siêu gọn `ka-network` (Signal 4); tích hợp tính năng chuyển đổi DNS nhanh (DHCP, Cloudflare, Google, Custom IP); và sửa dứt điểm trong mã nguồn C của DWM lỗi lệch vạch underline, đảm bảo quy tắc chỉ duy nhất 1 dropdown tồn tại tại 1 thời điểm với cơ chế tiêu diệt tức thì (`killdropdown`) và đóng khi click ra ngoài (`isinsideclient`).

## Handoff reason
`user-initiated`

## Repo state
- **Branch**: `main`
- **Working Tree**: Clean (`git status --short` is empty)

## State
Toàn bộ hệ thống tương tác giữa DWM và dwmblocks đã được nâng cấp lên chuẩn cao nhất:
1. **DWM Native C Engine**:
   - Vạch underline màu cyan sáng (`#8FBCBB`) được tính toán động theo thời gian thực trên mỗi khung hình vẽ statusbar (`drawstatusbar`), ôm khít tuyệt đối nội dung chữ và icon của block được click (đã gọt sạch khoảng trắng thừa ở đuôi). Vạch không bao giờ bị lệch đầu hay trôi vị trí khi các con số CPU/RAM nhảy.
   - Cơ chế bảo vệ click bên trong popup (`isinsideclient`) giúp các thao tác bấm nút "Refresh", kéo thanh trượt, đổi DNS, hoặc chọn ngày lịch không bao giờ làm mất vạch underline hay đẩy popup dạt sang mép phải.
   - Khi dropdown đang mở, DWM chặn sự kiện crossing lướt chuột (`enternotify`), chỉ đóng dropdown khi người dùng **thực sự click chuột ra ngoài vùng bao của popup**.
   - Thiết lập quy tắc tiêu diệt tức thì (`killdropdown` via `XKillClient`) đối với bất kỳ dropdown cũ nào ngay khi dropdown mới xuất hiện.
2. **Hệ thống Dropdown Thống Nhất (`dwm-dropdown`)**:
   - Quản lý tập trung 7 module thẻ popup bằng Python GTK3 theo phong cách Omarchy OS (vuông góc 100% `0px border-radius`, viền 2px accent, tự động đồng bộ palette màu từ `~/.config/theme/colors/current.conf`).
   - Module `network` tích hợp đầy đủ công cụ chuyển đổi DNS trực tiếp: `DHCP (Tự động)`, `Cloudflare (1.1.1.1)`, `Google (8.8.8.8)` và `Custom IP` thông qua công cụ `set-dns`.
3. **Dwmblocks Tinh Gọn**:
   - Loại bỏ module net-traffic dài dòng trên statusbar; gộp trạng thái mạng vào `ka-network` (chỉ hiển thị `📶 52%` hoặc `🌐`), chu kỳ 10s tiết kiệm pin tối đa.
   - Bảng 8 blocks chuẩn mực: `ka-forecast (14)`, `ka-memory (10)`, `ka-cpu (15)`, `ka-network (4)`, `ka-battery (30)`, `ka-volume (11)`, `sb-record (9)`, `ka-clock (1)`.

## Verification
- Mã nguồn C của DWM biên dịch thành công 100% không có lỗi:
  ```bash
  cd suckless/.local/src/dwm && make clean && make
  ```
- Mã nguồn Dwmblocks biên dịch thành công 100%:
  ```bash
  cd suckless/.local/src/dwmblocks && make clean && make
  ```
- Cú pháp Bash và Python của toàn bộ script vượt qua kiểm tra:
  ```bash
  bash -n scripts/.local/bin/set-dns
  bash -n scripts/.local/bin/dwmblocks-scripts/ka-network
  python3 -m py_compile scripts/.local/bin/dwmblocks-scripts/dwm-dropdown
  ```
- Thử nghiệm khởi động và kích hoạt độc lập từng module dropdown (`volume`, `clock`, `battery`, `cpu`, `memory`, `network`, `forecast`) đều thành công.

## Constraints
- Giữ nguyên kiến trúc X11/DWM siêu nhẹ Native C, không cài thêm web engine độc lập (như Helium/Electron).
- Duy trì tính lũy đẳng (idempotent) của `ka-setup` và `stow-safe`.
- Quản lý cấu hình theo chuẩn GNU Stow (23 packages đồng bộ 1:1 với thư mục).
- Mọi runtime lập trình quản lý qua `mise`.

## Key Files
- `suckless/.local/src/dwm/dwm.c`: Xử lý `killdropdown`, `isinsideclient`, `dropdowntosig`, chặn `enternotify`.
- `suckless/.local/src/dwm/patch/bar_status2d.c`: Tính toán vạch underline động thời gian thực và neo vị trí dropdown.
- `suckless/.local/src/dwm/patch/bar_statuscmd.c`: Xử lý click block và hủy dropdown cũ.
- `suckless/.local/src/dwmblocks/config.h`: Cấu hình danh sách 8 blocks tinh gọn.
- `scripts/.local/bin/dwmblocks-scripts/dwm-dropdown`: Bộ công cụ quản lý 7 thẻ popover GUI Omarchy.
- `scripts/.local/bin/dwmblocks-scripts/ka-network`: Script hiển thị trạng thái Wi-Fi/Ethernet siêu ngắn gọn.
- `scripts/.local/bin/set-dns`: Công cụ chuyển đổi DNS hỗ trợ DHCP, Cloudflare, Google và Custom IP.
- `OMARCHY_X11_HANDOFF.md`: Tài liệu kiến trúc toàn diện.
- `AGENTS.md`: Hướng dẫn vận hành repo.

## Next steps
1. Cài đặt binary DWM và Dwmblocks mới nhất lên máy:
   ```bash
   sudo make -C ~/.local/src/dwm install
   sudo make -C ~/.local/src/dwmblocks install
   ```
2. Khởi động lại statusbar và nạp lại DWM:
   ```bash
   pkill dwmblocks && setsid -f dwmblocks
   ```
   Đăng xuất và đăng nhập lại DWM (`Super + Shift + Q`).
3. Trải nghiệm hệ thống dropdown mới:
   - Click chuột trái vào Wi-Fi `📶 52%` để xem thông tin mạng và thử đổi DNS.
   - Click vào các icon khác để mở các thẻ popup tương ứng.
   - Click ra ngoài để đóng popup mượt mà.
