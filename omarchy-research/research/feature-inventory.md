# Feature Inventory: Danh Mục Thay Đổi & Thành Phần Kỹ Thuật (v4.0.3 -> v4.5.0)

Bảng kiểm kê toàn bộ **122 scripts mới**, **238 scripts sửa đổi** trong `bin/`, **21 tệp cấu hình** trong `config/`, cùng các phân hệ mở rộng được phát triển trong 2 tháng vừa qua của Omarchy.

---

## 1. PHÂN HỆ QUẢN LÝ CỬA SỔ & WORKSPACE (WINDOW MANAGEMENT & DESKTOP MODES)

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `default/hypr/workspace-modes.lua` | **MỚI** | Module lõi điều phối 3 chế độ: dwindle, scrolling, floating. Quản lý trạng thái bằng tags (`+omarchy-mode-floated`, `+omarchy-floating-workspace`). |
| `bin/omarchy-hyprland-workspace-layout-toggle` | **SỬA ĐỔI** | Script kích hoạt chuyển đổi layout cho active workspace. Lưu trạng thái vào `~/.local/state/omarchy/workspace-layouts/<id>.lua`. |
| `bin/omarchy-hyprland-workspace-layout-current` | **MỚI** | Đọc layout hiện tại của workspace từ tệp trạng thái hoặc fallback về layout mặc định của compositor. |
| `bin/omarchy-hyprland-workspace-layout-default` | **MỚI** | Đọc layout mặc định toàn cục từ cấu hình người dùng. |
| `bin/omarchy-dock` | **MỚI** | Quản lý cấu hình Dock hiển thị trên floating workspaces (vị trí `top/bottom/left/right`, `autohide`, ghim/bỏ ghim app desktop id). |
| `bin/omarchy-hyprland-window-minimize` | **MỚI** | Thu nhỏ cửa sổ trên floating workspace xuống Dock bằng cách chuyển cửa sổ vào special hidden workspace. |
| `bin/omarchy-hyprland-corners` | **MỚI** | Tùy biến bo góc cửa sổ (`rounded`, `sharp`, `theme`) thông qua cờ toggle Hyprland runtime. |
| `bin/omarchy-hyprland-window-transparency` | **MỚI** | Điều khiển độ trong suốt cửa sổ (`opaque`, `transparent`, `glassy`) qua thẻ `+transparent-window`. |
| `bin/omarchy-toggle-animations` | **MỚI** | Bật/tắt toàn bộ hiệu ứng chuyển động của compositor (mặc định tắt trong máy ảo VM). |
| `bin/omarchy-toggle-fullscreen-desktop` | **MỚI** | Chuyển đổi chế độ toàn màn hình desktop ẩn hoàn toàn bar và dock (`Super + Ctrl + Alt + F`). |
| `default/hypr/monitor-workspaces.lua` | **SỬA ĐỔI** | Cấu hình không gian làm việc độc lập cho từng màn hình (`split-monitor-workspaces` logic). |

---

## 2. PHÂN HỆ TỰ ĐỘNG HÓA AI AGENT (AGENTIC OS WORKFLOW)

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `bin/omarchy-agent-account-add` | **MỚI** | Đăng ký tài khoản AI subscription mới (Claude, Codex, Grok). Hỗ trợ `--check`, `--events`, `--reauth`. |
| `bin/omarchy-agent-account-use` | **MỚI** | Chuyển đổi tài khoản active cho các phiên làm việc mới. Bắn notification hiển thị tài khoản đang áp dụng. |
| `bin/omarchy-agent-account-exec` | **MỚI** | Wrapper bọc quanh nhị phân CLI agent. Thiết lập `CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `GROK_HOME` tương ứng với tài khoản được chọn, bảo toàn `mise` shims. |
| `bin/omarchy-agent-account-home` | **MỚI** | Trả về đường dẫn thư mục cấu hình của tài khoản active mà không khởi động Python runtime nếu không có tài khoản phụ. |
| `bin/omarchy-agent-account-list` | **MỚI** | Liệt kê danh sách tất cả các tài khoản đã đăng ký kèm trạng thái đăng nhập, loại gói cước (plan). |
| `bin/omarchy-agent-account-copy` | **MỚI** | Đồng bộ toàn bộ thông tin đăng nhập và cấu hình agent sang máy Omarchy khác qua giao thức SSH an toàn. |
| `bin/omarchy-agent-account-state` | **MỚI** | Quản lý tệp trạng thái tài khoản JSON tại `~/.local/state/omarchy/agents/accounts/<provider>.json`. |
| `bin/omarchy-agent-account-mode` | **MỚI** | Chuyển đổi chế độ phân bổ: manual switch (thủ công) hoặc automatic rollover (tự động chuyển tài khoản khi gần chạm rate limit). |
| `bin/omarchy-agent-usage-*` (23 files) | **MỚI/SỬA** | Các script theo dõi hạn mức (rate limits) theo thời gian thực cho: Claude, Codex, Grok, Devin, Copilot, Cursor, DeepSeek, OpenRouter, Hermes, Ollama, Qwen, v.v. |
| `default/hypr/qconsole.lua` | **MỚI** | Quake-style drop-down terminal console (`Super + ~`) mở cửa sổ dòng lệnh chạy agent mặc định trên lớp phủ bán trong suốt. |

---

## 3. PHÂN HỆ SHELL DESKTOP, STATUSBAR & IPC GIAO TIẾP

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `bin/omarchy-shell` | **SỬA ĐỔI** | Cầu nối IPC gửi lệnh tới giao diện desktop Quickshell. Ưu tiên UNIX socket nhị phân qua `socat` (~5ms), fallback về `qs ipc` (~45ms). |
| `config/omarchy/shell.json` | **SỬA ĐỔI** | Định nghĩa khai báo cấu trúc desktop: thời gian screensaver/lock, vị trí bar, danh sách module bar (`left`, `centerBegin`, `center`, `centerEnd`, `right`), danh sách app ghim trên Dock. |
| `default/omarchy/shortcuts` | **MỚI** | Danh sách phím tắt toàn cục được đăng ký trực tiếp vào Quickshell, loại bỏ bước spawn tiến trình bash trung gian. |
| `bin/omarchy-notification-send` | **SỬA ĐỔI** | Gửi thông báo D-Bus native qua `busctl susssasa{sv}i`. Hỗ trợ in-place update (`-r`), in ID (`-p`), và nút bấm tương tác (`--action`, `--with`, `--exec`). |
| `shell/plugins/panels/elsewhen` | **MỚI** | Plugin đồng hồ thế giới tương tác trực tiếp trên statusbar, tra cứu múi giờ và thời tiết các thành phố trên toàn cầu. |

---

## 4. PHÂN HỆ QUẢN TRỊ HỆ THỐNG, CẬP NHẬT & BẢO MẬT

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `bin/omarchy-update` | **SỬA ĐỔI** | Script cập nhật toàn diện hệ thống. Tích hợp tiến trình nền duy trì timestamp sudo (sudo keepalive) và ghi log PTY qua `script`. |
| `bin/omarchy-update-pacman` | **MỚI** | Bao bọc lệnh pacman trong `systemd-run --scope --quiet --collect` ở tầng PID 1, ngăn chặn việc transaction bị kill khi systemd daemon re-exec. |
| `bin/omarchy-update-keyring` | **SỬA ĐỔI** | Tự động đồng bộ và nạp pacman keyring trước khi thực hiện cập nhật gói hệ thống. |
| `bin/omarchy-security-functions` | **MỚI** | Thư viện kiểm định bảo mật: yêu cầu `bash -p`, xác thực PID cha qua `/proc/$caller/exe` và làm sạch các biến môi trường nguy hiểm (`BASH_ENV`, `ENV`, `BASH_FUNC_*`). |
| `bin/omarchy-system-lid-inhibit` | **MỚI** | Tự động ức chế hành động gập nắp máy (lid close) khi đang cắm màn hình ngoài hoặc đang chạy tác vụ cập nhật quan trọng. |
| `bin/omarchy-kernel` | **MỚI** | Menu lựa chọn và chuyển đổi nhân Linux mặc định (`linux`, `linux-lts`, `linux-zen`, `linux-omarchy`). |
| `bin/omarchy-boot-direct` | **MỚI** | Cấu hình bootloader Limine khởi động trực tiếp trong 1 giây (Quiet Boot), bỏ qua menu đếm lùi 6 giây. |

---

## 5. PHÂN HỆ NHẬN DIỆN PHẦN CỨNG & NỀN TẢNG (HARDWARE ABSTRACTION ENGINE)

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `bin/omarchy-hw-platform` | **MỚI** | Phát hiện chính xác kiến trúc phần cứng: `x86`, `aarch64`, `aarch64-apple`, `aarch64-qualcomm`, `aarch64-n1x`, `aarch64-gb10`. Hỗ trợ chế độ kiểm thử mock fixture. |
| `bin/omarchy-provision-hardware` | **MỚI** | Dịch vụ systemd khởi chạy ở lần boot đầu tiên sau khi cài đặt F1, hoàn thiện cấu hình firmware và initramfs chuyên biệt cho máy đó. |
| `bin/omarchy-hw-match-device-tree` | **MỚI** | Đối chiếu chuỗi compatible trong Device Tree của ARM laptop với cơ sở dữ liệu phần cứng hỗ trợ. |
| `bin/omarchy-hw-apple-silicon` | **MỚI** | Định danh phần cứng Apple Silicon Mac (M1/M2/M3) và nạp profile đồ họa Asahi tương ứng. |
| `bin/omarchy-hw-n1x` | **MỚI** | Nhận diện laptop chip NVIDIA N1X qua ACPI ID `NVDA0200` hoặc PCI ID `10de:2e06`. |
| `bin/omarchy-apply-n1x-gpu-memory` | **MỚI** | Cấu hình phân bổ bộ nhớ GPU động cho chip NVIDIA N1X. |

---

## 6. PHÂN HỆ MẠNG & KẾT NỐI (NETWORK AUTOMATION)

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `bin/omarchy-network-captive-portal` | **MỚI** | Tự động tạm dừng Tailscale exit node qua UNIX socket localapi, mở webapp đăng nhập Wi-Fi nổi, thăm dò `nmcli` và đóng cửa sổ khi có mạng. |
| `bin/omarchy-network-wifi-connected` | **MỚI** | Hook kích hoạt khi Wi-Fi kết nối thành công, kiểm tra captive portal và cập nhật biểu tượng trạng thái mạng. |

---

## 7. PHÂN HỆ BỘ GÕ, DICTATION & ĐA NGÔN NGỮ (INPUT, DICTATION & I18N)

| Thành phần (File Path) | Trạng thái | Chức năng kỹ thuật & Vai trò |
|---|---|---|
| `bin/omarchy-dictation` | **MỚI** | Bộ định tuyến trừu tượng cho tính năng nhập liệu bằng giọng nói (start/stop/toggle), đọc cấu hình từ `$XDG_CONFIG_HOME/omarchy/defaults/dictation`. |
| `bin/omarchy-dictation-superwhisper` | **MỚI** | Adapter tích hợp Superwhisper (hỗ trợ cả mô hình cloud và local offline). |
| `bin/omarchy-dictation-voxtype` | **MỚI** | Adapter tích hợp Voxtype (mô hình whisper cục bộ). |
| `bin/omarchy-input-method` | **MỚI** | Quản lý và chuyển đổi cấu hình bộ gõ Fcitx5 đa ngôn ngữ (Pinyin, Mozc, Hangul, Zhuyin, Cangjie). |
| `bin/omarchy-language` | **MỚI** | Chuyển đổi ngôn ngữ hiển thị desktop tức thì cho 50 ngôn ngữ được hỗ trợ. |
| `bin/omarchy-i18n` | **MỚI** | Tiện ích tra cứu chuỗi ký tự dịch thuật từ các tệp `default/i18n/<lang>/shell.json`. |
