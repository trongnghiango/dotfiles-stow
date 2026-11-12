# Research Timeline: Omarchy Linux Evolution (08/09/2026 – 08/11/2026)

## 1. Mốc Thời Gian & Khung Nghiên Cứu

- **Ngày bắt đầu nghiên cứu**: 08/09/2026 (Đánh dấu bằng bản phát hành `v4.0.3`)
- **Ngày kết thúc nghiên cứu**: 08/11/2026 (Bản phát hành chính thức `v4.5.0` Quattro RS ngày 05/11/2026 và các bản vá hotfix hậu phát hành)
- **Tổng số Pull Requests hợp nhất trong khung thời gian**: **781 PRs**
- **Tổng số commits sáp nhập**: **1.402 commits** (giữa tag `v4.0.3` và `v4.5.0`, cùng 30+ commits bổ sung trên nhánh `quattro`)

---

## 2. Nhật Ký Tiến Hóa Theo Trục Thời Gian

### Giai đoạn 1: Ổn định hóa Quattro 4.0 và Định hình Kiến trúc Mới (08/09/2026 – 30/09/2026)

- **08/09/2026 — Phát hành `v4.0.3` (Commit `0534987009`)**:
  - Bản vá lỗi sau khi Omarchy 4.0 (Quattro) ra mắt.
  - Sửa lỗi tương thích font chữ legacy, vá luồng xác thực plugin.
  - Bắt đầu triển khai dự án **Omarchy M** (nhóm phụ trách porting lên Apple Silicon M1/M2/M3).
- **15/09/2026 — Phát hành `v4.0.4` (Commit `c668141e9c`)**:
  - Tối ưu hóa khởi động terminal và tra cứu nhị phân qua `mise`.
  - Cải thiện quản lý tiến trình nền và cản trở sleep (sleep inhibition) khi đang tải package.
- **Cuối tháng 09/2026**:
  - Hợp nhất PR #10537 (@ryanrhughes): Giới thiệu hàm `o.rebind` cho Hyprland, cho phép người dùng thay thế keybinding mặc định của distro mà không phải sao chép toàn bộ tệp cấu hình.
  - Hợp nhất PR #11651 (@dhh): Bảo vệ các giao dịch cập nhật pacman khỏi sự cố người dùng vô tình đăng xuất (session teardown).
  - Hợp nhất PR #11658 (@dhh): Chuyển thuật toán kiểm soát tắc nghẽn TCP mặc định sang **BBR** và I/O scheduler sang **kyber** trên ổ đĩa vật lý NVMe/SATA.

---

### Giai đoạn 2: Bùng nổ Tính năng, Tái cấu trúc Shell & Agent OS (01/10/2026 – 19/10/2026)

- **Đầu tháng 10/2026**:
  - Tái cấu trúc toàn bộ phân tầng `default/hypr/`: Chuyển từ cấu hình Hyprland phẳng sang module Lua hướng đối tượng với hàm bọc `o.*` (`o.bind`, `o.window`, `o.workspace_mode`).
  - Hợp nhất PR #13423 (@dhh): Tối ưu hóa việc lấy đường dẫn tiến trình của cửa sổ đang active qua `/proc/$pid/cwd` để mở terminal mới ngay tại thư mục làm việc hiện tại, giảm độ trễ từ 180ms xuống < 15ms.
  - Hợp nhất PR #13992 & #14233 (@dhh): Bổ sung hỗ trợ đầy đủ cho Grok; cho phép các tiến trình con CLI tự động thừa kế tài khoản Agent LLM đã chọn thông qua biến môi trường.
- **18/10/2026 — Phát hành `v4.0.5` (Commit `94a8fbc2d6`)**:
  - Giới thiệu menu quản lý Appearance tổng hợp, thay thế menu Style cũ.
  - Vá lỗi tương thích cho các ứng dụng Electron / XWayland khi chạy trên màn hình fractional scaling.
- **19/10/2026 — Phát hành `v4.0.6` (Commit `237f1b4071`)**:
  - Bản vá hotfix khẩn cấp cho một số thiết bị gặp trục trặc boot entry sau nâng cấp.

---

### Giai đoạn 3: Chu kỳ Release Candidate v4.5.0 (20/10/2026 – 04/11/2026)

- **20/10/2026 — Phát hành `v4.5.0-rc1` (Commit `03ff1eff38`)**:
  - Công bố tính năng đột phá: **Floating workspaces with a dock** (Không gian làm việc dạng nổi tích hợp Dock).
  - Hợp nhất PR #15655 (@ryanrhughes): Multi-monitor per-display workspaces (`Super + 1-0` đi tới workspace của màn hình hiện tại).
  - Ra mắt 4 ứng dụng mặc định mới viết bằng C++/Qt Quick: **Hype** (trình chiếu Markdown), **Monologue** (quay camera nhanh), **Signed** (ký PDF điện tử), **Disktree** (bản đồ trực quan dung lượng đĩa).
  - Giới thiệu **Elsewhen** (đồng hồ thế giới và theo dõi múi giờ đồng nghiệp) tích hợp trên statusbar.
  - Hỗ trợ kiến trúc ARM64 cho máy chủ NVIDIA DGX Spark và laptop chip NVIDIA N1X (Dell XPS 16 Creator, ASUS ProArt P14).
- **27/10/2026 — Phát hành `v4.5.0-rc2` (Commit `5978d93ae7`)**:
  - Hợp nhất PR #16186 (@dhh): Cơ chế tự động phát hiện Captive Portal và tạm dừng Tailscale exit node.
  - Hợp nhất PR #16466 & #16470 (@dhh): Rebuild hệ thống thông báo với các nút bấm tương tác (`--action`, `--with`), hiệu ứng panel trồi lên từ thanh statusbar.
  - Hợp nhất PR #16681 (@emirb): Tích hợp dịch vụ đo tốc độ mạng chuyên dụng `speed.omarchy.org`.
  - Ra mắt bộ gõ tiếng Á Đông hoàn chỉnh (Fcitx5): Hỗ trợ Pinyin, Mozc (Nhật), Hangul (Hàn), Zhuyin/Cangjie (Đài Loan/Hồng Kông).
- **02/11/2026 — Phát hành `v4.5.0-rc3` (Commit `8d19ad75ac`)**:
  - Hợp nhất PR #17000 (@dhh): Gộp phiên xác thực sudo: chỉ hỏi mật khẩu 1 lần duy nhất cho toàn bộ chu trình update 10 phút, tự duy trì timestamp bằng tiến trình nền.
  - Thử nghiệm thành công trình cài đặt mới "F1": Unpack prebuilt root image, thiết lập kỷ lục cài đặt Arch Linux trong **7 giây** trên laptop AMD Strix Point.
  - Rút ngắn thời gian chờ boot loader Limine từ 6 giây xuống 1 giây (Quiet Boot).

---

### Giai đoạn 4: Phát hành Chính thức v4.5.0 Quattro RS & Hoàn thiện (05/11/2026 – 08/11/2026)

- **05/11/2026 — Phát hành `v4.5.0` (Tag Commit `ac2690cd7b`, Tag Object `97e664bd97`)**:
  - DHH chính thức công bố bản phát hành **Omarchy 4.5 (Quattro RS)**.
  - Tổng kết: 740+ PRs hợp nhất từ 180+ contributors chỉ trong 12 tuần.
  - Ra mắt trình cài đặt native cho Apple Silicon Mac (M1/M2/M3) qua gói cài đặt macOS và Homebrew tap `omacom/mac/omarchy`.
  - Tích hợp mặc định **Superwhisper** làm engine nhận diện giọng nói (dictation), kích hoạt qua phím `Alt + Space` hoặc giữ `Right Alt` (Push-to-Talk).
  - Hỗ trợ dịch tự động 50 ngôn ngữ hệ thống.
  - Ra mắt hai theme mặc định mới: **Jade Horse** (thay thế Osaka Jade) và **Starship**.
- **06/11/2026 – 08/11/2026 — Chuỗi Commit Hotfix & Polish trên nhánh `quattro`**:
  - Commit `9d883445bd` (PR #17925): Điều chỉnh phím tắt Superwhisper độc lập với compositor.
  - Commit `e284b835c6` (PR #17662): Hiển thị prompt mở khóa đĩa LUKS trên Snapdragon X2.
  - Commit `95277264ec` & `9044b7e8ea`: Xử lý cảnh báo mount `efivarfs` trên laptop Snapdragon.
  - Commit `b5883f774d` (PR #18079): Thiết lập audio UCM, sleep và mở khóa đĩa cho ASUS Zenbook 14 UX3480QA.
  - Commit `9305a184f6` (PR #18091): Chuẩn hóa thuật toán tính vạch sóng Wi-Fi của NetworkManager.
  - Commit `d9cc361cdd` (PR #18101): Đọc tệp dịch ngôn ngữ đồng bộ để không bị mất dữ liệu khi chuyển đổi locale.

---

## 3. Phân Tích Xu Hướng Phát Triển

Từ nhật ký 2 tháng, ta nhận thấy Omarchy có 3 chuyển dịch tư duy rõ rệt:
1. **Từ "Distro đóng băng" sang "Trải nghiệm thích ứng"**: Nhận thức được việc ép buộc tiling 100% gây rào cản lớn cho người dùng chuyển từ macOS/Windows, Omarchy đã xây dựng chế độ Floating Workspace tích hợp Dock mượt mà.
2. **Từ "Script rời rạc" sang "Event-driven IPC"**: Thay vì mỗi lần bấm phím lại fork một tiến trình bash hay python, toàn bộ shell statusbar chuyển sang giao tiếp socket UNIX domain qua `socat` với định dạng tách thẻ nhị phân/ASCII.
3. **Từ "Desktop thuần túy" sang "Agent Workstation"**: Biến Linux thành trạm làm việc tối ưu cho các lập trình viên sử dụng AI coding agents (Claude, Codex, Devin, Grok, Copilot), giải quyết bài toán cạn hạn mức (rate limit) bằng cơ chế multi-account và Quake console.
