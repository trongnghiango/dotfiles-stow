# Source Index: Chỉ Mục Nguồn Tham Chiếu Kỹ Thuật (Verified Citations)

Toàn bộ thông tin trong báo cáo được truy vấn, đối soát và xác thực trực tiếp từ mã nguồn chính thức của **Omarchy Linux** trên GitHub (`omacom/omarchy`, tiền thân là `basecamp/omarchy`).

---

## 1. CÁC BẢN PHÁT HÀNH & COMMIT HASHES CHÍNH THỨC (RELEASE TAGS)

| Phiên bản (Tag) | Ngày phát hành (UTC) | Commit SHA | Ghi chú & Đột phá kỹ thuật |
|---|---|---|---|
| `v4.0.3` | 2026-09-08 19:50:46 | `0534987009061cbe2dacdde4ad564092ab698d12` | Mốc bắt đầu nghiên cứu (Tree SHA: `139193701d7ddc948c12dfa2d15de070546ee520`) |
| `v4.0.4` | 2026-09-15 21:39:29 | `c668141e9c20a4b3d7d745eb11b518bb2021c327` | Bản vá hiệu năng khởi động terminal và mise resolver |
| `v4.0.5` | 2026-10-18 02:50:41 | `94a8fbc2d6fa5c2f3273e5fbf9727ec29509df65` | Giới thiệu Appearance menu, cải tiến fractional scaling |
| `v4.0.6` | 2026-10-19 22:49:53 | `237f1b40713be2d02958742b789d71b87eb572dc` | Hotfix bootloader entry cho thiết bị UEFI |
| `v4.5.0-rc1` | 2026-10-20 08:54:48 | `03ff1eff38c291dc573b9e404b93ca31ef6cbe8a` | Release Candidate 1: Công bố Floating Workspaces with Dock, ARM ISO |
| `v4.5.0-rc2` | 2026-10-27 23:07:38 | `5978d93ae7c617b0d778d9b1584cfc8d415170d1` | Release Candidate 2: Captive portal auto-detection, Notification rebuild |
| `v4.5.0-rc3` | 2026-11-02 07:15:22 | `8d19ad75ac196e8ab3c94f5fb2b9d07399580b2a` | Release Candidate 3: F1 7-second installer, single sudo prompt 10-min |
| `v4.5.0` | 2026-11-05 05:36:53 | `ac2690cd7be4f47e4a255f5e2e78d904d436b068` | Bản phát hành chính thức Quattro RS (Tree SHA: `5679` objects) |

---

## 2. CHỈ MỤC PULL REQUESTS TIÊU BIỂU (MERGED PRS IN 2-MONTH WINDOW)

### Quản lý Cửa sổ & Desktop Workflow
- **PR #15655** (@ryanrhughes): Multi-monitor per-display workspaces (`Super + 1-0` theo màn hình active, `Super + Arrows` di chuyển giữa các màn hình).
- **PR #10537** (@ryanrhughes): Hàm `o.rebind` ghi đè keybinding mặc định của Hyprland.
- **PR #16143** (@zihaomu): Sửa lỗi floating workspace chiếm đoạt cửa sổ đầu tiên có sẵn float rule.
- **PR #16397** (@omarchybot): Khắc phục lỗi compositor giật lag khi `Super + L` đảo layout workspace.
- **PR #16470** (@dhh): Menu panel trồi lên từ thanh statusbar và chuyển đổi mượt mà với hiệu ứng phản hồi nút bấm.
- **PR #15517** (@outfoxxed): Cơ chế kéo thả sắp xếp các widget trên thanh bar.
- **PR #16991** (@dhh): Khắc phục lỗi thanh bar ẩn bắt sự kiện click chuột ở cạnh trên cửa sổ toàn màn hình.

### Quản trị Hệ thống, Nâng cấp & Bảo mật
- **PR #11651** (@dhh): Bảo vệ giao dịch cập nhật pacman khỏi việc người dùng đăng xuất giữa chừng (`omarchy-update-pacman`).
- **PR #17000** (@dhh): Hỏi mật khẩu sudo 1 lần duy nhất cho toàn bộ chu trình update 10 phút qua keepalive loop.
- **PR #16568** (@omarchybot): Gộp cả kiểm tra AUR và bootloader vào chung phiên sudo duy nhất.
- **PR #17311** (@emirb): Tự động cập nhật Omarchy keyring trước mỗi lần nâng cấp hệ thống.
- **PR #14428** (@dhh): Tự động dọn dẹp các gói mồ côi (orphan packages) an toàn.
- **PR #11658** (@dhh): Chuyển TCP sang BBR và I/O scheduler sang kyber.
- **PR #8374** (@Chessing234): Di chuyển trạng thái quay màn hình ra khỏi `/tmp` dùng chung để chống tấn công phân quyền.
- **PR #8170** (@Adolanium): Từ chối tên hook và file trạng thái chứa ký tự đường dẫn (`../`) chống Path Traversal.

### Phân hệ AI Agent & Quake Console
- **PR #13992** (@dhh): Tích hợp Grok vào Agent panel ngang hàng với Claude và Codex.
- **PR #14233** (@dhh): Áp dụng tài khoản Agent đã chọn cho toàn bộ các tiến trình con CLI qua biến môi trường.
- **PR #15722** (@Stegi56): Hiển thị hạn mức chi tiêu cá nhân và thời gian đếm lùi đặt lại giới hạn (countdown reset).
- **PR #16593** (@dhh): Khắc phục lỗi Agent không nhận diện được các công cụ `mise` được cài đặt sau khi Agent khởi động.

### Tự động hóa Mạng & Nhận diện Giọng nói
- **PR #16186** (@dhh): Tự động phát hiện Captive Portal và tạm dừng Tailscale exit node.
- **PR #16466** (@dhh): Hỗ trợ action buttons cho lệnh `omarchy-notification-send`.
- **PR #17188** (@dhh): Gán `Alt + Space` làm phím kích hoạt dictation trên mọi backend.

---

## 3. CHỈ MỤC TỆP TIN & MÃ NGUỒN CỐT LÕI ĐÃ ĐƯỢC PHÂN TÍCH

| Tệp tin | Vị trí trong Git Tree (`v4.5.0`) | Vai trò kỹ thuật chính |
|---|---|---|
| `workspace-modes.lua` | `default/hypr/workspace-modes.lua` | Quản lý logic Tiling vs Floating bằng Window Tags trong Hyprland |
| `helpers.lua` | `default/hypr/helpers.lua` | Thư viện bọc Hyprland: `o.bind`, `o.rebind`, `o.bind_hold`, `o.window` |
| `omarchy-dock` | `bin/omarchy-dock` | Quản lý cấu hình thanh Dock trên floating workspaces |
| `omarchy-shell` | `bin/omarchy-shell` | Giao tiếp IPC socket nhị phân UNIX domain qua `socat` tới Quickshell |
| `shell.json` | `config/omarchy/shell.json` | Cấu hình khai báo bố cục statusbar, dock và timeout màn hình |
| `omarchy-update` | `bin/omarchy-update` | Trình cập nhật hệ thống với vòng lặp duy trì sudo ngầm và PTY log |
| `omarchy-update-pacman` | `bin/omarchy-update-pacman` | Thực thi pacman dưới dạng PID 1 systemd scope chống sập |
| `omarchy-network-captive-portal` | `bin/omarchy-network-captive-portal` | Điều phối đăng nhập Wi-Fi công cộng và tạm dừng Tailscale exit node |
| `omarchy-notification-send` | `bin/omarchy-notification-send` | Gọi D-Bus `Notify` native qua `busctl` với tham số typed |
| `omarchy-agent-account-exec` | `bin/omarchy-agent-account-exec` | Cô lập danh tính Agent qua biến môi trường và duy trì `mise` shims |
| `omarchy-hw-platform` | `bin/omarchy-hw-platform` | Nhận diện kiến trúc phần cứng (x86, Apple Silicon, Snapdragon, N1X) |

---

## 4. TÀI LIỆU CHÍNH THỨC & THÔNG BÁO TỪ TÁC GIẢ

- **Official Release Announcement**: [Omarchy 4.5 floats, speaks 50 languages, and runs on your Mac](https://omarchy.org/news/2026/11/omarchy-4-5/) (Đăng bởi DHH ngày 04/11/2026).
- **Official Documentation**: [Omarchy Manual & Theming Guides](https://omarchy.org/manual/).
- **Official Plugin Registry**: [Omarchy Plugins Portal](https://plugins.omarchy.org).
- **Upstream Repositories**:
  - `omacom/omarchy`: Kho mã nguồn chính.
  - `omacom/hype`: Trình chiếu Markdown bằng C++/Qt Quick.
  - `omacom/monologue`: Trình quay camera nhanh bằng C++/Qt Quick.
  - `omacom/signed`: Ứng dụng ký và điền form PDF bằng C++/Qt Quick.
  - `omacom/gliff`: Điều khiển desktop từ xa qua giao thức SSH (viết bằng Rust).
