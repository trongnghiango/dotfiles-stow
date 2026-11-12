# Omarchy Deep Research & Architecture Distillation

> **Báo cáo nghiên cứu hệ thống chuyên sâu dành cho Principal Linux Systems Engineer & Distro Architect**  
> **Thời gian thực hiện nghiên cứu**: Tháng 11/2026 (Cửa sổ nghiên cứu 2 tháng: 08/09/2026 – 08/11/2026)  
> **Phạm vi mã nguồn**: `omacom/omarchy` (`v4.0.3` -> `v4.5.0` Quattro RS và nhánh `quattro`)

---

## 1. TỔNG QUAN NGHIÊN CỨU & BỐI CẢNH KỸ THUẬT

Trong chu kỳ 2 tháng vừa qua (từ phiên bản `v4.0.3` phát hành ngày 08/09/2026 đến `v4.5.0` Quattro RS phát hành ngày 05/11/2026 và các commit mới nhất đến ngày 08/11/2026), dự án **Omarchy Linux** (chuyển đổi từ tổ chức `basecamp/omarchy` sang `omacom/omarchy`) đã trải qua một đợt tái cấu trúc kiến trúc và mở rộng quy mô chưa từng có:

- **Quy mô đóng góp**: Hơn **780 Pull Requests** được sáp nhập từ hơn 180 lập trình viên; **1.402 commits** giữa `v4.0.3` và `v4.5.0`; 122 shell scripts mới và 238 shell scripts được tinh chỉnh trong `bin/`; 114 tệp migration trạng thái hệ thống trong `migrations/`.
- **Bước nhảy kiến trúc (Architectural Leaps)**:
  1. **Dual-Mode Window Management**: Chuyển đổi linh hoạt giữa Tiling (Dwindle/Master), Scrolling và **Floating Workspaces tích hợp Dock**. Triển khai hoàn toàn thông qua cơ chế quản lý thẻ cửa sổ (window tags) và dynamic window rules trong Lua Hyprland runtime mà không cần sửa đổi mã nguồn C++ của compositor.
  2. **Multi-Account AI Agent Subsystem**: Môi trường phân tách đa danh tính cho các Agent LLM (Claude, Codex, Grok, Devin, Copilot, Hermes...) với khả năng cô lập biến môi trường, bảo vệ lịch sử/skills, đồng bộ qua SSH và Quake-style drop-down console.
  3. **Low-Latency Desktop IPC**: Thay thế cơ chế spawn tiến trình tốn kém (~60ms) bằng UNIX Domain Socket nhị phân qua `socat` với phân cách ký tự điều khiển ASCII (`\x1f` Unit Separator, `\x1e` Record Separator), giảm độ trễ IPC xuống dưới **5ms**.
  4. **F1 Sub-10s Installation Architecture**: Chuyển từ cài đặt tuần tự 940+ gói pacman sang giải nén prebuilt root image kết hợp trì hoãn nạp phần cứng vào lần khởi động đầu tiên qua `omarchy-provision-hardware.service`.
  5. **Network Automation & Captive Portal Engine**: Tự động phát hiện captive portal tại khách sạn/sân bay, tạm dừng Tailscale exit node qua UNIX socket localapi, khởi tạo cửa sổ webapp nổi cô lập và đóng tự động ngay khi kết nối Internet phục hồi.
  6. **Hardened Sudo & Session-Isolated Maintenance**: Cơ chế `systemd-run --scope` bảo vệ tiến trình cập nhật pacman khỏi việc bị `SIGKILL` khi systemd re-exec mid-transaction; giữ timestamp sudo ngầm qua vòng lặp kiểm tra PID cha; loại bỏ hoàn toàn `notify-send` để gọi trực tiếp D-Bus typed parameters qua `busctl`.

Báo cáo này không tiếp cận Omarchy dưới góc nhìn của một bản phân phối hoàn chỉnh để cài đặt, mà **mổ xẻ toàn diện mã nguồn thực tế (Reverse-Engineering)**, bóc tách nguyên lý thiết kế và **chắt lọc thành kiến trúc Dotfiles cao cấp** cho một **Personal Linux Operating System** độc lập, tối giản, có thể tái lập (reproducible) và bảo trì bền vững.

---

## 2. CẤU TRÚC BỘ TÀI LIỆU NGHIÊN CỨU

Bộ tài liệu được tổ chức theo đúng cấu trúc tiêu chuẩn:

```text
omarchy-research/
├── README.md                                # Tổng quan, phương pháp, kết luận và trả lời 10 câu hỏi cốt lõi
├── research/
│   ├── timeline.md                          # Trục thời gian 2 tháng: 8 bản phát hành, các mốc commit & PRs
│   ├── feature-inventory.md                 # Bảng kiểm kê chi tiết 122 scripts mới, 238 scripts sửa đổi & configs
│   ├── implementation-analysis.md           # Đào sâu 5 tầng kỹ thuật của các tính năng nổi bật
│   └── source-index.md                      # Chỉ mục tra cứu mã nguồn, commit SHAs, PR IDs, APIs
├── analysis/
│   ├── feature-ranking.md                   # Bảng đánh giá 10 tiêu chí và xếp hạng Top ý tưởng giá trị
│   ├── architecture-distillation.md         # Chắt lọc nguyên lý kiến trúc độc lập nền tảng
│   ├── performance-analysis.md              # Phân tích hiệu năng: CPU, RAM, Latency, IPC, I/O
│   └── anti-patterns.md                     # Các bẫy thiết kế và tính năng phình to cần loại bỏ
├── architecture/
│   ├── personal-os-architecture.md          # Bản thiết kế kiến trúc Personal Linux OS phân tầng
│   ├── dotfiles-structure.md                # Cấu trúc repository dotfiles, quản lý module và máy chủ
│   └── implementation-blueprints.md         # Bản thiết kế triển khai thực tế (Bash, Lua, C, Systemd)
└── roadmap/
    ├── phases.md                            # Lộ trình triển khai 6 giai đoạn từ nền tảng đến tối ưu
    └── production-checklist.md              # Bảng kiểm định chất lượng, an toàn và chống hỏng hóc
```

---

## 3. TRẢ LỜI 10 CÂU HỎI KỸ THUẬT CỐT LÕI (SECTION 16)

Dưới đây là bản tổng hợp kết luận kỹ thuật trả lời trực diện 10 câu hỏi cốt lõi từ kiến trúc sư hệ thống:

### 1. Omarchy đã thực sự cải thiện những khía cạnh nào trong 2 tháng qua?
- **Khả năng thích ứng desktop (Desktop Flexibility)**: Đột phá lớn nhất là việc hỗ trợ đồng thời cả Tiling, Scrolling và Floating Workspaces có Dock mà không làm hỏng tính toàn vẹn của Hyprland.
- **Tốc độ phản hồi giao diện (Responsiveness)**: Loại bỏ độ trễ spawn tiến trình khi mở menu/panel thông qua Quickshell socket IPC và Hyprland global shortcuts.
- **Trải nghiệm AI Agent (Agent-Centric OS)**: Chuyển từ việc gọi CLI đơn lẻ sang hệ sinh thái quản lý đa tài khoản, đo đạc hạn mức theo thời gian thực và Quake drop-down console.
- **Độ tin cậy của quy trình cập nhật hệ thống**: Giải quyết dứt điểm các lỗi kinh điển của Arch Linux như sập phiên khi cập nhật systemd, treo kết nối captive portal khi dùng Tailscale, và hết hạn sudo giữa chừng.
- **Mở rộng nền tảng phần cứng**: Hỗ trợ toàn diện ARM64 (Apple Silicon M1-M3 qua Asahi, Snapdragon X Elite/Plus, NVIDIA N1X/GB10).

### 2. Những thay đổi nào có giá trị kỹ thuật cao nhất?
1. **Kiến trúc quản lý Floating Workspace bằng Window Tags (`default/hypr/workspace-modes.lua`)**: Không cần can thiệp C++ compositor, chỉ dùng tags (`+omarchy-mode-floated`, `+omarchy-floating-workspace`) để chuyển đổi trạng thái cửa sổ hai chiều hoàn hảo.
2. **Kỹ thuật bao bọc cập nhật hệ thống an toàn (`omarchy-update-pacman` & `omarchy-update`)**: Tách giao dịch pacman ra PID 1 system scope bằng `systemd-run --scope --collect` và duy trì sudo keepalive qua subshell giám sát PID cha.
3. **Low-Latency UNIX Socket IPC cho GUI Shell (`bin/omarchy-shell`)**: Dùng `socat` giao tiếp trực tiếp với socket Quickshell qua ký tự phân cách ASCII, đạt tốc độ ~5ms.
4. **Captive Portal Auto-Resolver (`bin/omarchy-network-captive-portal`)**: Tự động pause Tailscale exit node qua UNIX socket localapi và dọn dẹp cửa sổ bằng Hyprland IPC khi mạng online.
5. **Kỹ thuật chống nuốt sự kiện nhả phím (`o.bind_hold` trong `default/hypr/helpers.lua`)**: Tạo bind nhả phím trong suốt, bỏ qua modifier và non-consuming để hỗ trợ Push-to-Talk hoàn hảo.

### 3. Những ý tưởng nào đáng đưa vào personal Linux OS?
- **Adopt (Áp dụng ngay)**:
  - `systemd-run --scope` cho các tác vụ cập nhật gói hệ thống.
  - Sudo timestamp keepalive an toàn trong shell scripts dài.
  - Phân tách cấu hình Hyprland theo lớp (Base Defaults vs User Overrides vs Dynamic State).
  - Tự động hóa xử lý Captive Portal và tạm dừng VPN/Tailscale.
  - D-Bus typed parameters qua `busctl` thay thế hoàn toàn `notify-send`.
  - Quake-style drop-down terminal/agent console gắn phím nóng toàn cục.

### 4. Những ý tưởng nào nên bỏ qua?
- **Reject (Loại bỏ)**:
  - Cơ chế F1 image unpack installer (chỉ phù hợp cho distro ISO thương mại, không có giá trị trên dotfiles của máy cá nhân).
  - Webapps wrapper cho Microsoft 365, YouTube, Google Maps bằng Chromium app mode (gây phân mảnh cấu hình trình duyệt và tiêu tốn tài nguyên nền).
  - Video backgrounds và intro animations khi đổi theme (tiêu tốn CPU/GPU vô ích, trái ngược triết lý minimal và tiết kiệm pin).
  - Cơ chế tự sinh 50 ngôn ngữ i18n động trong shell (phức tạp hóa hệ thống cá nhân chỉ cần tiếng Anh hoặc tiếng Việt).

### 5. Những ý tưởng nào có thể triển khai tốt hơn Omarchy?
- **Quản lý Statusbar & System Popups**: Omarchy dùng Quickshell/QML (tiêu tốn ~80-150MB RAM). Trong kiến trúc cá nhân tối ưu, trạng thái có thể được biểu diễn bằng C thuần (`dwmblocks` in-process < 2.5MB RAM) hoặc Rust/Go daemon cực nhẹ, đọc trực tiếp `/proc` và `/sys` thay vì chạy cả JavaScript runtime.
- **Quản lý Theme Switching**: Omarchy dùng scripts sed/regex ghi đè nhiều nơi. Ta có thể gom màu sắc vào một tệp chuẩn định dạng (ví dụ `colors.toml` hoặc base16 YAML) và dùng template engine tĩnh (như `mustache` hoặc `envsubst`) sinh cấu hình nguyên tử (atomic write).
- **Clipboard Management**: Thay vì phụ thuộc vào tiện ích ngoài, việc sử dụng daemon lắng nghe sự kiện Wayland/X11 thuần C với cơ chế lọc mật khẩu (`x-kde-passwordManagerHint`) mang lại hiệu năng cao hơn gấp nhiều lần.

### 6. Có những workflow nào Omarchy chưa giải quyết tốt?
- **Quản lý Secrets & GPG/SSH Keys**: Omarchy lưu trữ nhiều token và cấu hình tài khoản dưới dạng plain text JSON trong `$HOME/.local/state/` hoặc `$HOME/.config/`, chưa tích hợp chặt chẽ với mật mã hóa TPM2 / `pass` / `gopass`.
- **Reproducibility của Dotfiles**: Omarchy tự coi mình là distro và can thiệp trực tiếp vào `/usr/share/omarchy/`, khiến người dùng khó kiểm soát phiên bản cấu hình cá nhân nếu muốn đồng bộ giữa nhiều máy tính chạy Arch thuần hoặc Debian/Fedora.
- **Tiêu thụ pin và profile máy cổ**: Omarchy hướng tới phần cứng mới (Snapdragon, Apple Silicon, NVIDIA), các hiệu ứng blur, glassy và Quickshell ngốn pin đáng kể trên laptop cũ.

### 7. Nếu xây dựng personal OS từ dotfiles ngay hôm nay, nên bắt đầu từ đâu?
- **Bắt đầu từ Tầng 1 (Foundation)**: Thiết lập cấu hình quản lý dotfiles bằng **GNU Stow** kết hợp cấu trúc thư mục phân tách theo module rõ ràng. Thiết lập cấu hình biến môi trường (`$XDG_CONFIG_HOME`, `$XDG_STATE_HOME`, `$XDG_RUNTIME_DIR`).
- Tiếp theo là **Tầng 2 (Core Workflow)**: Cấu hình Window Manager (Hyprland hoặc DWM), Terminal (Foot/Alacritty) và Shell (Zsh/Bash) với triết lý phím tắt nhất quán.
- Sau đó mới tích hợp **Tầng 3 (Automation)**: Bổ sung các scripts tiện ích độc lập (update an toàn, captive portal, clipboard, notification wrapper).

### 8. Top 5 cải tiến có ROI (Return on Investment) cao nhất là gì?
1. **Cập nhật hệ thống chống sập (`safe-update`)**: Tích hợp `systemd-run --scope` và sudo keepalive loop. Tiết kiệm hàng giờ sửa chữa hệ thống khi pacman bị đứt gãy.
2. **Quake Console Drop-down (`Super + ~`)**: Mở terminal hoặc AI agent tức thì ở mọi workspace mà không làm xáo trộn bố cục cửa sổ đang làm việc.
3. **Notification Wrapper bằng `busctl`**: Hỗ trợ in-place update `-r` và các nút bấm hành động tương tác trực tiếp (`--action`) mà không bị lỗi command injection.
4. **Captive Portal + VPN Auto-Switch**: Xóa bỏ hoàn toàn sự ức chế khi mang laptop ra quán cafe/sân bay mà VPN chặn trang đăng nhập Wi-Fi.
5. **Cơ chế nạp cấu hình phân lớp (Layered Configuration)**: Tách riêng cấu hình mặc định bất biến, cấu hình cá nhân của người dùng và trạng thái sinh ra tại runtime, giúp cập nhật dotfiles không bao giờ bị xung đột (conflict-free).

### 9. Những nguyên lý kiến trúc nào đáng học từ Omarchy?
- **Non-blocking Hot Path**: Tách rời các tác vụ nặng ra khỏi vòng lặp xử lý sự kiện chính của Window Manager.
- **Event-Driven over Polling**: Không bao giờ dùng vòng lặp `while true; sleep 1` để kiểm tra trạng thái; chỉ cập nhật khi nhận tín hiệu (Signal) hoặc sự kiện socket.
- **Process Isolation**: Chạy các ứng dụng và tác vụ con trong systemd scopes (`uwsm-app` hoặc `systemd-run`) để quản lý cgroup và tài nguyên minh bạch.
- **Graceful Degradation**: Mọi script đều phải có khả năng kiểm tra sự tồn tại của công cụ phụ thuộc (`omarchy-cmd-present`) và tự động fallback về phương án an toàn nhất.

### 10. Làm thế nào để giữ hệ thống đơn giản, nhanh, ổn định và dễ bảo trì khi nó phát triển?
- **Áp dụng Học thuyết Một Con Đường (One Path Doctrine)**: Mỗi chức năng chỉ duy trì một công cụ duy nhất. Không lưu trữ nhiều công cụ trùng lặp.
- **Quy trình Vườn ươm Tốt nghiệp (Incubate-to-Graduate)**: Ý tưởng mới bắt đầu từ shell script nhỏ ở tầng cao. Khi đã chứng minh được giá trị sử dụng hàng ngày mới cân nhắc tối ưu hóa hoặc viết lại bằng mã nguồn nhị phân tối giản.
- **Bất biến của File cấu hình tĩnh**: Không cho phép scripts runtime ghi đè lên các tệp đang được quản lý bởi Git/Stow; mọi trạng thái động phải chuyển hướng sang `$XDG_RUNTIME_DIR` hoặc `$XDG_STATE_HOME`.
- **Kiểm định nghiêm ngặt trước khi hợp nhất**: Mọi script sửa đổi cấu hình bắt buộc phải có cờ `--check` hoặc chế độ dry-run để kiểm tra tính đúng đắn trước khi thực thi.

---

*Mời chuyển sang các tệp chi tiết trong thư mục `research/`, `analysis/`, `architecture/` và `roadmap/` để xem toàn bộ dẫn chứng mã nguồn và tài liệu kỹ thuật chuyên sâu.*
