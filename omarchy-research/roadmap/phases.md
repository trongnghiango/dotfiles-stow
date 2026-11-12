# Production-Quality Roadmap: Lộ Trình Triển Khai Hệ Thống Cá Nhân

Lộ trình triển khai **Personal Linux Operating System** qua 6 giai đoạn rõ ràng. Mỗi giai đoạn đều có mục tiêu cụ thể, tiêu chí nghiệm thu (Acceptance Criteria) và Định nghĩa Hoàn thành (Definition of Done) nhằm đảm bảo hệ thống luôn trong trạng thái ổn định và có thể vận hành hàng ngày (production-ready).

---

## GIAI ĐOẠN 1: FOUNDATION (NỀN TẢNG KIẾN TRÚC & QUẢN LÝ CẤU HÌNH)

- **Mục tiêu**: Thiết lập cấu trúc kho lưu trữ dotfiles chuẩn mực, cơ chế liên kết mềm GNU Stow và phân lớp biến môi trường XDG.
- **Modules liên quan**: `bootstrap/`, `hardware/`, `modules/shell/`.
- **Dependencies**: `git`, `stow`, `bash`, `zsh`.
- **Nhiệm vụ cụ thể (Tasks)**:
  1. Khởi tạo cấu trúc repository dotfiles theo chuẩn Stow packages.
  2. Xây dựng script `bootstrap/arch-bootstrap.sh` tự động cài đặt các công cụ nền tảng.
  3. Cấu hình biến môi trường chuẩn trong `.zshenv` / `.bashrc` (`XDG_CONFIG_HOME`, `XDG_STATE_HOME`, `XDG_DATA_HOME`, `XDG_RUNTIME_DIR`).
  4. Thiết lập cơ chế Host Profile (`hardware/current-host.conf`) nhận diện phần cứng.
- **Rủi ro (Risks)**: Xung đột với các tệp cấu hình cũ đã có sẵn trong `$HOME`.
- **Biện pháp giảm thiểu**: Cơ chế tự động sao lưu (Auto-backup) vào `~/.dotfiles-backup/<date>/` trước khi tạo symlink.
- **Tiêu chí nghiệm thu (Acceptance Criteria)**: Chạy `stow -n -v` (dry-run) không có lỗi xung đột; biến môi trường XDG được nạp chính xác sau khi login.
- **Definition of Done (DoD)**: Một máy tính mới có thể clone repository và chạy `./bootstrap/stow-all.sh` là có ngay môi trường shell chuẩn hóa.

---

## GIAI ĐOẠN 2: CORE WORKFLOW (WINDOW MANAGEMENT & DESKTOP INTERACTION)

- **Mục tiêu**: Xây dựng môi trường đồ họa tốc độ cao, bàn phím làm trung tâm (keyboard-driven), bố cục cửa sổ dự đoán được.
- **Modules liên quan**: `modules/hyprland/`, `modules/terminal/`, `modules/statusbar/`.
- **Dependencies**: `hyprland` (hoặc `dwm`), `foot` (hoặc `alacritty`), `uwsm`, `pipewire`.
- **Nhiệm vụ cụ thể (Tasks)**:
  1. Tích hợp `uwsm` quản lý vòng đời phiên đồ họa qua `systemd --user`.
  2. Phân tách cấu hình Hyprland theo lớp (base rules, keybindings, monitors).
  3. Triển khai phím tắt tiêu chuẩn: Điều hướng không gian làm việc, di chuyển cửa sổ, quản lý âm lượng, độ sáng.
  4. Triển khai thanh trạng thái nhẹ (Waybar hoặc C native statusbar) với cơ chế event-driven (0 polling).
  5. Cấu hình terminal `foot` với độ trễ mở dấu nhắc lệnh < 8ms.
- **Rủi ro (Risks)**: Sai lệch độ phân giải hoặc scale trên màn hình phụ / màn hình ngoài.
- **Biện pháp giảm thiểu**: Tách riêng cấu hình `monitors.conf` theo từng máy trong `hosts/`.
- **Tiêu chí nghiệm thu**: Mở terminal tức thì (< 10ms); bấm phím âm lượng/độ sáng cập nhật trạng thái ngay mà không giật màn hình.
- **Definition of Done**: Có thể làm việc cả ngày bằng bàn phím mà không cần chạm chuột để chuyển đổi cửa sổ.

---

## GIAI ĐOẠN 3: AUTOMATION (TIỆN ÍCH DÒNG LỆNH & QUẢN TRỊ HỆ THỐNG)

- **Mục tiêu**: Tự động hóa các thao tác lặp lại và bảo vệ hệ thống khỏi các lỗi vận hành kinh điển.
- **Modules liên quan**: `scripts/.local/bin/`, `modules/notifications/`.
- **Dependencies**: `busctl`, `systemd-run`, `sudo`, `nmcli`, `tailscale`.
- **Nhiệm vụ cụ thể (Tasks)**:
  1. Triển khai wrapper `safe-pacman` với PID 1 transient scope và sudo keepalive ngầm.
  2. Xây dựng tiện ích thông báo native `ka-notify` thay thế `notify-send` qua `busctl`.
  3. Triển khai script `captive-portal-resolver` tự động tạm dừng Tailscale exit node khi vào Wi-Fi quán cafe.
  4. Thiết lập tính năng Push-to-Talk `o.bind_hold` cho micro/dictation.
- **Rủi ro (Risks)**: Tiến trình sudo ngầm không tự thoát nếu bị ngắt bất thường.
- **Biện pháp giảm thiểu**: Ràng buộc kiểm tra PID cha `kill -0 $parent` trong subshell và trap tín hiệu EXIT/TERM.
- **Tiêu chí nghiệm thu**: Chạy cập nhật hệ thống khi đang tải file nặng không bị timeout sudo; captive portal tự mở và tự đóng khi có mạng.
- **Definition of Done**: Toàn bộ các script tiện ích đều có cờ `--help` hoặc hướng dẫn cú pháp rõ ràng, vượt qua `shellcheck`.

---

## GIAI ĐOẠN 4: DEVELOPER ENVIRONMENT & AGENT WORKSTATION

- **Mục tiêu**: Biến hệ thống thành trạm làm việc lý tưởng cho lập trình viên và người dùng AI coding agents.
- **Modules liên quan**: `modules/nvim/`, `modules/git/`, `modules/agent-workspace/`.
- **Dependencies**: `neovim`, `tmux`, `mise`, `git`.
- **Nhiệm vụ cụ thể (Tasks)**:
  1. Thiết lập Quake-style drop-down console (`Super + ~`) chạy ngầm tmux scratchpad.
  2. Xây dựng bộ công cụ quản lý đa tài khoản AI Agent (`agent-env`) cô lập biến môi trường.
  3. Cấu hình Git với include file cục bộ (`config.local`) để phân tách email cá nhân và công ty.
  4. Tối ưu hóa Neovim khởi động trong < 30ms.
- **Rủi ro (Risks)**: Xung đột đường dẫn nhị phân giữa `mise` shims và hệ điều hành.
- **Biện pháp giảm thiểu**: Nạp shims tĩnh vào `$PATH`, không gọi hàm eval hook nặng ở login shell.
- **Tiêu chí nghiệm thu**: Bấm `Super + ~` terminal trượt xuống ngay tức khắc; chuyển đổi tài khoản AI agent thành công trong 1 lệnh.
- **Definition of Done**: Lập trình viên có thể mở dự án, commit code, và tương tác với coding agent hoàn toàn mượt mà.

---

## GIAI ĐOẠN 5: RELIABILITY, BACKUP & RECOVERY

- **Mục tiêu**: Đảm bảo hệ thống có khả năng tự phục hồi, chống hỏng hóc và có bản lưu trữ dự phòng.
- **Modules liên quan**: `tests/`, `system/systemd/`.
- **Dependencies**: `btrfs` (hoặc `rsync`), `snapper` / `btrbk`, `shellcheck`.
- **Nhiệm vụ cụ thể (Tasks)**:
  1. Tích hợp snapshot tự động trước khi chạy `safe-pacman` (nếu dùng Btrfs).
  2. Xây dựng bộ test tự động kiểm tra symlink gãy (`tests/test-symlinks.sh`).
  3. Viết script kiểm tra cú pháp toàn bộ shell scripts bằng `shellcheck`.
  4. Cấu hình Limine/Systemd-boot với timeout ngắn (1s) nhưng giữ phím để chọn snapshot cứu hộ.
- **Rủi ro (Risks)**: Snapshot đĩa đầy làm nghẽn dung lượng lưu trữ.
- **Biện pháp giảm thiểu**: Thiết lập chính sách dọn dẹp snapshot tự động (chỉ giữ 5 bản gần nhất).
- **Tiêu chí nghiệm thu**: Cố tình ngắt điện khi đang cài gói và có thể rollback về trạng thái trước đó an toàn.
- **Definition of Done**: Toàn bộ mã nguồn dotfiles vượt qua CI kiểm thử tĩnh (static analysis) không có cảnh báo nghiêm trọng.

---

## GIAI ĐOẠN 6: OPTIMIZATION & PERFORMANCE PROFILING

- **Mục tiêu**: Cắt giảm tối đa tài nguyên dư thừa, tối ưu hóa thời lượng pin laptop và giảm độ trễ về 0.
- **Modules liên quan**: Toàn bộ hệ thống.
- **Dependencies**: `systemd-analyze`, `powertop`, `strace`.
- **Nhiệm vụ cụ thể (Tasks)**:
  1. Đo lường thời gian khởi động hệ thống qua `systemd-analyze blame` và tắt các dịch vụ không cần thiết.
  2. Tối ưu hóa C-states và CPU governor qua profile phần cứng (Powersave trên máy pin, Performance trên máy bàn).
  3. Loại bỏ mọi background daemon tiêu tốn > 5MB RAM nếu có thể thay bằng on-demand script.
  4. Tinh chỉnh I/O scheduler sang `kyber` và TCP sang `bbr`.
- **Rủi ro (Risks)**: Tối ưu quá đà làm giảm độ ổn định phần cứng.
- **Biện pháp giảm thiểu**: Đo đạc bằng công cụ khách quan trước và sau mỗi thay đổi (A/B testing).
- **Tiêu chí nghiệm thu**: Dung lượng RAM idle của toàn bộ desktop < 80MB; thời gian khởi động shell < 8ms; laptop duy trì pin > 6-8 tiếng làm việc.
- **Definition of Done**: Hệ thống đạt trạng thái cân bằng hoàn hảo: Tối giản, Cực nhanh, Ổn định vĩnh cửu.
