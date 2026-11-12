# Personal Linux OS Architecture: Thiết Kế Kiến Trúc Hệ Thống Cá Nhân

Bản thiết kế kiến trúc phân tầng dành cho một **Personal Linux Operating System** độc lập, được xây dựng và kiểm soát hoàn toàn thông qua **Dotfiles**, hướng tới sự tối giản (minimal), dự đoán được (predictable), hiệu năng cao (high-performance) và bảo trì bền vững (maintainable).

---

## 1. MÔ HÌNH KIẾN TRÚC TỔNG THỂ (THE ARCHITECTURAL STACK)

Hệ thống được thiết kế thành 6 tầng độc lập với ranh giới trách nhiệm (separation of concerns) rõ ràng:

```text
┌────────────────────────────────────────────────────────────────────────┐
│ TẦNG 6: DEVELOPER ENVIRONMENT & AGENT WORKSTATION                      │
│ - Trình biên tập: Neovim / Helix / VS Code                             │
│ - Terminal Workflow: Foot / Alacritty + Tmux / Zellij                  │
│ - Agent Harness: Quake Console, Isolated Agent Configs, Token Vault    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ TẦNG 5: AUTOMATION & CUSTOM CLI SYSTEM                                 │
│ - Tiện ích hệ thống: safe-pacman, captive-portal-resolver, ka-notify   │
│ - Menu điều khiển: On-demand launcher, dmenu/rofi socket hooks         │
│ - Hardware Profiling: Tự động nhận diện cấu hình máy và pin            │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ TẦNG 4: WINDOW MANAGEMENT & DESKTOP WORKFLOW                           │
│ - Compositor: Hyprland (Wayland) hoặc DWM (X11)                        │
│ - Bố cục: Dynamic Tiling kết hợp Floating Scratchpads                  │
│ - Phím tắt toàn cục: Phân tách rõ ràng giữa Core WM và Ứng dụng        │
│ - Giao diện trạng thái: Statusbar hướng sự kiện (0 fork polling)       │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ TẦNG 3: USER ENVIRONMENT & SESSION LIFECYCLE                           │
│ - Session Manager: uwsm (Universal Wayland Session Manager)            │
│ - Daemons người dùng: PipeWire, Dunst, Keyring qua systemd --user     │
│ - Biến môi trường chuẩn XDG: XDG_CONFIG_HOME, XDG_STATE_HOME, PATH    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ TẦNG 2: CONFIGURATION ENGINE (DOTFILES MANAGEMENT)                     │
│ - Cơ chế triển khai: GNU Stow liên kết mềm nguyên tử (Symlinks)        │
│ - Cấu trúc 3 tầng: Base Defaults -> Host Overrides -> Runtime State    │
│ - Kiểm định: Linter, shell check, dry-run validation trước khi apply   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│ TẦNG 1: BASE OPERATING SYSTEM & HARDWARE ABSTRACTION                   │
│ - Phân phối nền: Arch Linux (Rolling Release, Pacman)                  │
│ - Khởi động & Quản trị dịch vụ: Systemd, Limine/Systemd-boot           │
│ - Kernel & Tối ưu I/O: Linux Zen/LTS + TCP BBR + Kyber Scheduler       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. NGUYÊN TẮC THIẾT KẾ CỐT LÕI (CORE PRINCIPLES)

1. **Học thuyết Một Con Đường (One Path Doctrine)**:
   - Mỗi nhu cầu chỉ duy trì đúng một công cụ tốt nhất. Không cài đặt song song nhiều ứng dụng cùng chức năng (ví dụ: không duy trì cả Alacritty, Kitty và Foot cùng lúc; chọn 1 terminal duy nhất).
2. **Quy trình Vườn Ươm Tốt Nghiệp (Incubate & Graduate)**:
   - Ý tưởng mới bắt đầu từ một shell script nhỏ ở tầng cao (`scripts/.local/bin/`).
   - Nếu chứng minh được tần suất sử dụng hàng ngày và giá trị thực tế, nó sẽ được tối ưu hóa, loại bỏ subshell và tích hợp sâu vào hệ thống. Nếu không hiệu quả, xóa bỏ ngay lập tức.
3. **Bất biến của Tệp Cấu Hình Tĩnh (Immutability of Static Dotfiles)**:
   - Nghiêm cấm mọi script runtime dùng lệnh ghi đè (`sed -i`) lên các tệp tin đang được quản lý bởi Git.
   - Mọi trạng thái động (dynamic state) phát sinh trong quá trình sử dụng bắt buộc phải ghi vào `$XDG_RUNTIME_DIR` (RAM tmpfs) hoặc `$XDG_STATE_HOME` (ổ đĩa).
4. **Không Thêm Daemon Nền Khi Chưa Thực Sự Cần Thiết**:
   - Ưu tiên cơ chế chạy theo nhu cầu (On-Demand Execution) hoặc lắng nghe sự kiện (Event-Driven).
   - Tuyệt đối không chạy tiến trình nền liên tục thăm dò tài nguyên (Zero Polling Daemons).
5. **Cấp phát Quyền Tối Thiểu (Principle of Least Privilege)**:
   - 99% tác vụ desktop chạy hoàn toàn trong không gian người dùng (User Space).
   - Tác vụ cần quyền root chỉ được cấp phát có thời hạn ngắn và kiểm soát chặt chẽ vòng đời qua PID tiến trình cha.

---

## 3. THIẾT KẾ CÁC PHÂN HỆ CHÍNH

### A. Phân Hệ Quản Lý Phiên Làm Việc (Session Lifecycle via `uwsm`)
- Thay vì để Window Manager tự gọi lệnh `exec` khởi chạy tiến trình con, hệ thống sử dụng **`uwsm` (Universal Wayland Session Manager)** làm cầu nối giữa compositor và `systemd --user`.
- Khi người dùng đăng nhập TTY, lệnh khởi động thực thi:
  ```bash
  exec uwsm start hyprland.desktop
  ```
- **Lợi ích**:
  - Mỗi ứng dụng được mở qua phím tắt (như `uwsm-app -- foot`) tự động trở thành một systemd transient scope riêng biệt.
  - Khi compositor reload hoặc crash, các ứng dụng đang chạy (trình duyệt, editor) không bị tắt theo.
  - Tận dụng đầy đủ khả năng quản lý tài nguyên (cgroups) của systemd.

### B. Phân Hệ Giao Diện Trạng Thái & Thông Báo (Status & Notifications)
- **Statusbar**:
  - Không sử dụng các framework QML/Electron nặng nề.
  - Triển khai thanh trạng thái bằng nhị phân C native (`dwmblocks`) hoặc Waybar tối giản.
  - Toàn bộ các khối trạng thái ít biến động (như thông báo, ghi âm, cập nhật) sử dụng cơ chế **interval = 0**; chỉ cập nhật khi nhận tín hiệu thời gian thực (`SIGRTMIN+N`).
- **Notification Daemon**:
  - Sử dụng Dunst hoặc Mako.
  - Mọi script trong hệ thống tương tác với hệ thống thông báo qua wrapper `ka-notify` gọi trực tiếp D-Bus native bằng `busctl`, hỗ trợ cập nhật tại chỗ (`-r <id>`) và gắn nút hành động an toàn.

### C. Phân Hệ AI Agent & Developer Workflow
- **Quake Drop-down Console (`Super + ~`)**:
  - Cửa sổ terminal nổi chuyên dụng được cấu hình làm việc với các coding agents.
  - Bấm `Super + ~` để triệu hồi ngay tại vị trí con trỏ màn hình hiện tại; bấm lại để giấu đi mà không mất ngữ cảnh phiên làm việc.
- **Cô lập danh tính Agent qua Biến Môi Trường**:
  - Phân tách cấu hình tài khoản cá nhân và công việc bằng cách chuyển hướng `CLAUDE_CONFIG_DIR`, `CODEX_HOME` qua shell wrapper.
  - Khóa token nhạy cảm trong hệ thống quản lý mật khẩu an toàn (`pass` / Linux Keyring), nạp vào bộ nhớ tạm thời khi gọi lệnh.
