# Handoff — Omarchy 4.x.x Modular Statusbar, Night Working Mode & Responsive Notification Center Sidebar

## Focus
Chuẩn hóa kiến trúc toàn diện cho thanh trạng thái DWM theo chuẩn **Omarchy OS 4.x.x ("Quattro")**, tích hợp chế độ làm việc ban đêm nhịp sinh học (**Night Working Mode**), và xây dựng Trung tâm thông báo dạng **Right Sidebar (Full Height, Responsive)** theo mô hình **Máy Trạng Thái Hợp Nhất (Unified State Machine Pattern)**.

## Handoff reason
`phase-complete`

## Repo state
- **Branch**: `main`
- **HEAD Commit**: `4c01248` (kèm các thay đổi cập nhật tài liệu dự án)
- **Modified Documents**:
  - `AGENTS.md`
  - `HOTKEYS.md`
  - `MANUAL.md`
  - `OMARCHY_X11_HANDOFF.md`
  - `suckless/.local/src/dwm/config.md`
  - `docs/handoff/latest.md`
  - `docs/handoff/2026-09-20-210140_handoff-omarchy4-statusbar-night-mode-and-notification-center.md`

## Key Architectural Achievements

### 1. Bố Cục Thanh Bar 3 Phân Vùng Chuẩn Omarchy 4.x.x ("Quattro")
- **Left Section**: Workspace Tags (1 - 9) + Layout Symbol (`[]=`) + Tiêu đề cửa sổ active (`wintitle`). Co giãn tự nhiên nhưng nhường chỗ cho khối Middle.
- **Center Section (Dead-Center)**: Hiển thị `Tue · 15:35  󰖗` (Đồng hồ tối giản + Icon thời tiết nhịp sinh học).
  - Tự động đổi icon theo ngày/đêm từ API OpenWeatherMap: `󰖙` (Nắng ngày), `󰖕` (Nắng mây), `󰖔` (Trăng đêm), `󰼱` (Trăng mây), `󰖗` (Mưa đêm).
  - Click vào thời gian mở Popover Clock/Calendar; click vào thời tiết mở Popover Forecast.
- **Collapsible Left-Systray**:
  - Đưa sang **bên trái** của khối dwmblocks: Giúp các icon phần cứng ở mép phải có **tọa độ cố định vĩnh viễn**, không bao giờ bị xê dịch khi có app mở/đóng khay.
  - Thu gọn mặc định bằng chevron ``. Click vào bung ra thành `` và hiển thị toàn bộ icon (`ka-clip`, `fcitx5`...).
  - Chuẩn hóa khoảng đệm (spacing) đồng nhất 8px, icon 15px tạo padding trên/dưới 5px cân đối với thanh bar 25px.
- **Right Section (Anchored Hardware & Notification Bell)**:
  - Loại bỏ hoàn toàn text % và emoji đa sắc, áp dụng Monochrome Nerd Font Glyphs: `sb-record` (`🔴 REC`), `ka-volume` (`󰕾`), `ka-battery` (`󰁹`), `ka-network` (`󰤨`), `ka-cpu` (`󰍛`), `ka-memory` (`󰘚`), `sb-notify` (`󰂚`/`󰂞`/`󰂛`).
  - Cảnh báo màu đỏ duy nhất khi pin < 15% (`^C1^󰁺^d^`) hoặc CPU quá tải > 80%.

### 2. Tinh Chỉnh Underline Container Alignment
- Kích thước vạch gạch chân (underline) tính toán theo công thức `MAX(ab_w, bh)`, tối thiểu bằng chiều cao statusbar (25px).
- Tọa độ X của vạch kẻ được căn chỉnh tự động: `ux = (bar_start_x + ab_x) - (uw - ab_w) / 2`.
- Vạch underline **thẳng hàng 100% với mép trái của viền cửa sổ popover/sidebar bên dưới**, tạo khối liền mạch hoàn hảo.

### 3. Chế Độ Làm Việc Ban Đêm (Night Working Mode)
- Tích hợp module `ka-night` điều khiển nhiệt độ màu và độ sáng màn hình:
  - Bật: Lọc ánh sáng xanh ấm dịu mắt **4000K** (qua `redshift`, `sct` hoặc native `xrandr --gamma`) và tự động hạ độ sáng màn hình xuống **35%**.
  - Tắt: Khôi phục 6500K và độ sáng ban ngày trước đó.
- Lệnh CLI: `ka night [on|off|toggle|status]`.
- Phím tắt Ergonomic: **`Super + Alt + N`**.

### 4. Trung Tâm Thông Báo Right Sidebar & Unified State Machine Pattern
- **Kiến trúc Không Lỗi (Zero-Bug State Machine)**:
  - Loại bỏ hoàn toàn script rời `ka-notify-center` và cơ chế file PID rác trên đĩa.
  - Tích hợp `NotifyDropdown` thành **Module thứ 8 chính thức** trong `dwm-dropdown` (kế thừa `BaseDropdown`).
  - Đăng ký Signal 8 trong DWM C-Core (`dropdowntosig()` và `manage()`).
  - DWM quản lý thống nhất con trỏ `active_block.win` và `active_block.sig`:
    - Click lại vào icon chuông: Đóng sidebar + Xóa underline.
    - Click ra ngoài màn hình: Tự đóng sidebar + Xóa underline.
    - Bấm phím `Esc` / `q` / `Super + Q`: Tự đóng sidebar + Xóa underline.
    - Click sang block khác: Đóng sidebar, mở popover mới, chuyển underline mượt mà.
- **Responsive Geometry (Đa Thiết Bị & Đa Màn Hình)**:
  - Nhận diện màn hình hiện tại chứa con trỏ chuột (`display.get_monitor_at_point()`).
  - Chiều rộng tỷ lệ vàng động: $25%$ chiều rộng màn hình, kẹp lề an toàn `340px - 500px` (màn 1366x768 tự co về 340px, màn FHD/2K tự mở rộng đến 500px).
  - Chiều cao Full Height: Bắt đầu từ mép dưới statusbar (`y = 25px`) kéo thẳng xuống đáy màn hình (`c->h = m->wh`).
- **Trigger Block (`sb-notify`)**:
  - `󰂚`: Không có thông báo (chuông yên tĩnh).
  - `󰂞`: Có thông báo trong lịch sử (chuông có chấm).
  - `󰂛`: Đang bật chế độ Không làm phiền (DND).
  - Chuột trái: Mở/đóng Sidebar; Chuột phải: Bật/tắt DND; Chuột giữa: Xóa lịch sử.
- Phím tắt: **`Super + Shift + N`**.

## Verification
1. **Kiểm tra biên dịch DWM 6.8 & Dwmblocks Native C**:
   ```bash
   make -C suckless/.local/src/dwm clean && make -C suckless/.local/src/dwm
   make -C suckless/.local/src/dwmblocks clean && make -C suckless/.local/src/dwmblocks
   ```
   *(Kết quả: PASS 100%, 0 lỗi, 0 cảnh báo mới)*
2. **Kiểm tra tính toàn vẹn cú pháp Python & GTK3**:
   ```bash
   python3 -m py_compile scripts/.local/bin/dwmblocks-scripts/dwm-dropdown
   python3 -m py_compile scripts/.local/bin/ka-clip
   ```
   *(Kết quả: PASS 100%)*
3. **Kiểm tra hoạt động máy trạng thái và toggle**:
   ```bash
   dwm-dropdown notify # Mở Sidebar
   dwm-dropdown notify # Tự động đóng và xóa underline
   ```
   *(Kết quả: Hoạt động trơn tru, không còn lỗi kẹt underline)*
4. **Kiểm tra chuỗi trạng thái dwmblocks**:
   ```bash
   suckless/.local/src/dwmblocks/build/dwmblocks -d
   ```
   *(Kết quả: [Center] `Tue · 15:35  󰖗` ; [Right] `󰖀  󰁹  󰤨  󰍛  󰘚  󰂚`)*
