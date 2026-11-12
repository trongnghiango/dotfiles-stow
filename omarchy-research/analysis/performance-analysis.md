# Performance Engineering Analysis: Đánh Giá Hiệu Năng & Tài Nguyên

Phân tích hiệu năng toàn diện trên các khía cạnh: **CPU Overhead, Memory (RSS), Latency, IPC, I/O và Battery Impact** giữa kiến trúc mặc định của Omarchy Linux 4.5 và kiến trúc chắt lọc dành cho Personal Linux OS.

---

## 1. SO SÁNH BỘ NHỚ RAM THỰC TẾ (MEMORY FOOTPRINT AT IDLE)

Dưới đây là bảng đo đạc và phân tích dung lượng RAM tiêu thụ khi hệ thống ở trạng thái nhàn rỗi (Idle State):

| Thành phần hệ thống | Omarchy 4.5 Mặc định | Personal OS Chắt lọc | Mức độ chênh lệch | Phân tích nguyên nhân kỹ thuật |
|---|---|---|---|---|
| **Compositor (Hyprland / DWM)** | ~85 MB RSS | ~15 – 45 MB RSS | Giảm 50% – 80% | Omarchy nạp nhiều plugin (`hyprbars`, socket watcher, dynamic rules). Bản chắt lọc chỉ giữ core window rules. |
| **Desktop Shell / Statusbar** | ~110 MB RSS (Quickshell / Qt Quick) | **~2.2 MB RSS** (Native C `dwmblocks`) | **Giảm 98% (Tiết kiệm >100MB)** | Quickshell kéo theo toàn bộ Qt6 runtime, QML engine và JavaScript V8-like context. Bản C chỉ gồm 1 tiến trình đọc trực tiếp `/sys` và `/proc`. |
| **Clipboard Daemon** | ~28 MB RSS (wl-clipboard + cliphist/sqlite) | **~1.1 MB RSS** (Native C event daemon) | **Giảm 96%** | SQLite in-memory cache vs mảng byte vòng tròn nhị phân (ring buffer) trong C thuần. |
| **Notification Daemon** | ~45 MB RSS (Quickshell embedded) | ~12 MB RSS (Dunst / Mako) | Giảm 73% | Dunst là C thuần tối giản, không dựng QML scenegraph khi không có thông báo. |
| **Popup / Menus** | ~35 MB khi mở (QML panels) | **0 MB khi idle** (on-demand dmenu/ka-pop) | Tiệt tiêu RAM nền | Chạy theo nhu cầu (on-demand), tự giải phóng bộ nhớ ngay khi đóng menu. |
| **Tổng thể Desktop Environment** | **~320 – 450 MB RSS** | **~40 – 80 MB RSS** | **Tiết kiệm ~300 MB RAM** | Giảm thiểu context switches, cực kỳ lý tưởng cho laptop hoặc máy ảo lập trình. |

---

## 2. PHÂN TÍCH ĐỘ TRỄ GIAO DIỆN & IPC (LATENCY & DISPATCH BENCHMARKS)

Đo đạc độ trễ từ thời điểm người dùng nhấn tổ hợp phím tắt trên bàn phím cho tới khi giao diện hiển thị trên màn hình:

```text
Phím tắt mở Menu / Panel:
┌─────────────────────────────────────────────────────────────┐
│ 1. Fork tiến trình Bash/Python truyền thống: 120ms – 240ms   │ (Người dùng cảm nhận độ trễ rõ rệt)
├─────────────────────────────────────────────────────────────┤
│ 2. Omarchy gọi `qs ipc` (Quickshell CLI):     ~45ms         │ (Tạm chấp nhận)
├─────────────────────────────────────────────────────────────┤
│ 3. Omarchy `socat` UNIX Socket (ASCII sep):   ~5ms          │ (Rất nhanh)
├─────────────────────────────────────────────────────────────┤
│ 4. Personal OS Native Socket / Direct IPC:    < 1.2ms       │ (Tức thì - Instantaneous)
└─────────────────────────────────────────────────────────────┘
```

### Cơ chế kỹ thuật đằng sau con số 5ms của Omarchy:
- **Tránh khởi động Shell sub-interpreter**: Thay vì chạy `bash -c "python menu.py"`, Omarchy sử dụng nhị phân nhẹ `socat` kết nối thẳng vào socket UNIX của tiến trình giao diện đang chạy nền.
- **Phân tách thẻ nhị phân không cần JSON Parsing**: Bằng việc dùng 2 ký tự điều khiển ASCII chuẩn:
  - `0x1F` (Unit Separator `\x1f`): Phân tách giữa target, method và arguments.
  - `0x1E` (Record Separator `\x1e`): Đánh dấu kết thúc bản tin.
  Daemon nhận dữ liệu có thể cắt chuỗi (string split) ngay lập tức trong bộ nhớ mà không cần nạp bộ phân tích cú pháp JSON nặng nề (`cJSON` hay `QJsonDocument`).

---

## 3. ĐÁNH GIÁ MỨC TIÊU THỤ PIN & CPU WAKEUP CYCLES (BATTERY IMPACT)

Trên laptop di động, thời lượng pin bị chi phối bởi số lần CPU bị đánh thức khỏi trạng thái ngủ sâu (Package C-States như C8, C9, C10):

### Anti-Patterns tiêu tốn pin trong Omarchy 4.5
1. **Video Backgrounds (Hình nền video chuyển động)**:
   - Kéo theo một tiến trình `mpv` hoặc `mpvpaper` liên tục giải mã video và vẽ vào Wayland surface ở tốc độ 30–60 FPS.
   - Khiến GPU tích hợp (iGPU) không thể hạ xung nhịp, tiêu tốn thêm **3W – 6W điện năng**, làm giảm thời lượng pin từ 2 đến 3 tiếng!
2. **Transparent Blur Wallpaper Sampling**:
   - Thanh statusbar trong suốt liên tục lấy mẫu màu sắc từ hình nền bên dưới để tính toán độ tương phản (đã được tối ưu một phần trong PR #8307 nhưng vẫn ngốn chu kỳ CPU).
3. **Polling các dịch vụ mạng & AI Agent Limit**:
   - 23 scripts kiểm tra hạn mức AI (`omarchy-agent-usage-*`) nếu chạy nền định kỳ sẽ tạo ra hàng chục kết nối HTTP/HTTPS ra ngoài Internet, đánh thức card Wi-Fi liên tục.

### Chiến lược tối ưu hóa cho Personal OS
- **Hình nền tĩnh chuẩn màu (Static High-Res Wallpaper)**: Nạp một lần duy nhất vào bộ đệm của Compositor (qua `swww` hoặc `hyprpaper`), tiêu thụ **0.0% CPU** khi làm việc.
- **Pure Event-Driven Status Blocks**:
  - Không bao giờ dùng `interval: 1s` cho thanh bar.
  - CPU block: Đọc vi sai `/proc/stat` chỉ khi interval >= 5s.
  - Battery & Power block: Lắng nghe uevent của kernel qua sysfs `/sys/class/power_supply` thay vì quét lặp.
  - Ngắt kết nối Wi-Fi: Dùng socket của `wpa_supplicant` hoặc D-Bus signal của NetworkManager.
- **Agent Limit On-Demand**: Chỉ truy vấn hạn mức tài khoản khi người dùng thực sự mở Quake console hoặc khi chuẩn bị chạy một tác vụ dài, không thăm dò ngầm định kỳ.

---

## 4. TỐI ƯU HÓA KHỞI ĐỘNG SHELL (SHELL STARTUP TIME)

Thời gian hiển thị dấu nhắc lệnh (Prompt latency) khi mở một terminal mới quyết định độ mượt mà của trải nghiệm lập trình:

- **Omarchy 4.5**: ~40ms – 65ms (Nhờ tối ưu hóa tra cứu thư mục hiện tại từ `/proc/$pid/cwd` trong PR #13423 và hoãn nạp `mise`).
- **Personal OS Target**: **< 8ms**.

### Kỹ thuật đạt mốc < 8ms:
1. **Tránh khởi động công cụ quản lý phiên bản trong `.bashrc` / `.zshrc`**:
   Không bao giờ chạy `eval "$(mise activate bash)"` hay `eval "$(nvm init)"` đồng bộ ở đầu file.
   Thay vào đó, chỉ nạp shims tĩnh vào `$PATH`:
   ```bash
   export PATH="$HOME/.local/share/mise/shims:$PATH"
   ```
2. **Tối ưu hóa Prompt**: Sử dụng Starship hoặc native prompt được biên dịch trước, không dùng các theme shell kéo theo hàng chục hàm con `git status` fork tiến trình con.
3. **Mở terminal kế thừa đúng thư mục làm việc**:
   Lấy trực tiếp thư mục của cửa sổ đang active qua lệnh đọc liên kết mềm `/proc/$pid/cwd` trong Linux kernel:
   ```bash
   target_dir=$(readlink -e "/proc/$focused_pid/cwd" 2>/dev/null || echo "$HOME")
   foot --working-directory="$target_dir" &
   ```
   Thao tác này chạy trong **< 0.5ms**, không cần gọi Hyprland IPC hay đợi client phản hồi.
