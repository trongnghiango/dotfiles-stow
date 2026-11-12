# Implementation Analysis: Phân Tích Kỹ Thuật Đào Sâu 5 Tầng (5-Layer Deep Dive)

Phân tích chuyên sâu 7 kiến trúc tiêu biểu nhất được Omarchy phát triển trong giai đoạn 08/09/2026 – 08/11/2026 theo phương pháp luận 5 tầng kỹ thuật:
1. **Layer 1 — Feature Discovery**: Vấn đề giải quyết, ngữ cảnh sử dụng thực tế.
2. **Layer 2 — Implementation Analysis**: Chi tiết mã nguồn, tệp tin, sự kiện kích hoạt, quản lý trạng thái, xử lý lỗi.
3. **Layer 3 — Root Design Idea**: Ý tưởng cốt lõi độc lập với nền tảng.
4. **Layer 4 — Engineering Distillation**: Nguyên lý kỹ thuật, I/O, state, failure modes, bảo mật, hiệu năng.
5. **Layer 5 — Personal OS Application**: Cách ứng dụng vào Personal Linux OS qua dotfiles.

---

## 1. DUAL-MODE WORKSPACE ENGINE: FLOATING WORKSPACES TÍCH HỢP DOCK TRONG HYPRLAND

### Layer 1 — Feature Discovery
Hyprland vốn là một Dynamic Tiling Wayland Compositor. Trong phiên bản 4.5, Omarchy bổ sung khả năng chuyển đổi bất kỳ workspace nào giữa **Tiling (Dwindle)**, **Scrolling** và **Floating** chỉ bằng phím tắt `Super + L`. Khi chuyển sang Floating:
- Các cửa sổ tự động nổi, mở rộng với kích thước chuẩn (`width * 0.64`, `height * 0.68`) và xếp so le (cascade).
- Hiển thị thanh tiêu đề (titlebar) đồng màu với theme có đủ nút Close (`×`), Maximize (`□`), Minimize (`−`).
- Xuất hiện một thanh **Dock** ở cạnh dưới hiển thị các ứng dụng đang chạy và các ứng dụng được ghim.
- Cửa sổ thu nhỏ (`Super + M`) sẽ ẩn vào Dock.
- Chế độ di chuột (focus) tự động chuyển từ Follow-Mouse sang Click-to-Focus để tránh vô tình đổi focus khi di chuột qua các cửa sổ xếp đè lên nhau.

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `default/hypr/workspace-modes.lua`, `bin/omarchy-hyprland-workspace-layout-toggle`, `bin/omarchy-dock`.
- **Cơ chế trạng thái (State Management)**:
  Hyprland không có khái niệm floating workspace ở cấp độ compositor C++. Do đó, Omarchy đã giải quyết bằng **Window Tags**:
  - `FLOATED_TAG = "omarchy-mode-floated"`: Đánh dấu cửa sổ nào vốn là tiling nhưng bị script ép sang floating.
  - `WORKSPACE_TAG = "omarchy-floating-workspace"`: Đánh dấu mọi cửa sổ đang hiện diện trên workspace dạng nổi.
  - `OPENED_TAG = "omarchy-mode-opened"`: Đánh dấu cửa sổ mới mở trên floating workspace.
- **Quy trình hoạt động**:
  1. Khi người dùng bấm `Super + L`, script `bin/omarchy-hyprland-workspace-layout-toggle` lấy `ACTIVE_WORKSPACE` qua `hyprctl activeworkspace -j`.
  2. Tính toán layout kế tiếp và gọi `hyprctl eval "o.workspace_mode({ workspace = \"$ACTIVE_WORKSPACE\", mode = \"$NEW_MODE\" })"`.
  3. Trong Lua, hàm `arrange()` duyệt qua danh sách cửa sổ trên workspace:
     - Nếu chuyển sang Floating: Cửa sổ đang tiling được gắn thẻ `+FLOATED_TAG`, chuyển sang float (`hl.dsp.window.float`), định cỡ và căn giữa kèm lệch bậc thang:
       ```lua
       cascade = (cascade + 1) % 5
       hl.dispatch(hl.dsp.window.move({ x = cascade * 24 - 48, y = cascade * 24 - 48, relative = true, window = window }))
       ```
     - Cửa sổ vốn dĩ đã có rule float riêng (hộp thoại, 1Password, Bitwarden) được giữ nguyên, **không gắn `FLOATED_TAG`**.
     - Nếu chuyển ngược lại Tiling: Chỉ những cửa sổ mang thẻ `FLOATED_TAG` mới bị ép tiling trở lại (`tile_for_mode`). Hộp thoại và app có float rule riêng vẫn tiếp tục nổi!
  4. Nạp động plugin titlebar: Gọi `hl.plugin.load("/usr/lib/omarchy-hyprland-titlebars/titlebars.so")` khi có ít nhất một workspace nổi, thiết lập màu sắc từ `~/.local/state/omarchy/current/theme/colors.toml`.
  5. Giám sát sự kiện thời gian thực:
     - `hl.on("window.open")`: Bắt cửa sổ mới mở để unmaximize cửa sổ cũ và xếp so le.
     - `hl.on("window.move_to_workspace")`: Trì hoãn 1ms qua `hl.timer` để cửa sổ tiếp đất an toàn rồi mới đổi tag.
     - `hl.on("workspace.active")`: Đổi `input.follow_mouse = 0` nếu là floating workspace, hoặc trả về giá trị gốc của người dùng nếu là tiling workspace.

### Layer 3 — Root Design Idea
Tận dụng hệ thống tag và sự kiện động của Window Manager để mở rộng tính năng mà **không cần vá (patch) hoặc fork mã nguồn C++ của compositor**. Trạng thái được lưu trực tiếp trên thuộc tính của cửa sổ (`window tags`), giúp hệ thống tự phục hồi ngay cả khi compositor reload hoặc cắm thêm màn hình ngoài.

### Layer 4 — Engineering Distillation
- **Nguyên lý**: Virtual Workspace Mode thông qua Window Tagging & Dynamic Rule Injection.
- **Độ tin cậy & Xử lý lỗi**:
  - Không bao giờ lưu cấu hình vào disk trước khi compositor áp dụng thành công.
  - Tránh xung đột với cửa sổ đặc biệt (special workspaces, scratchpad mang ID âm).
  - Phục hồi an toàn: nếu người dùng chuyển workspace mặc định từ floating về tiling, hàm `M.apply()` quét sạch các thẻ `FLOATED_TAG` còn sót lại để không làm "kẹt" cửa sổ ở trạng thái lơ lửng.

### Layer 5 — Personal OS Application
- **Khả năng áp dụng vào Dotfiles**: **100% khả thi** trên bất kỳ hệ thống Hyprland hiện đại nào (Hyprland v0.41+).
- **Phân loại**: Dotfiles Lua module (`~/.config/hypr/workspace-modes.lua`) + Shell script toggle (`~/.local/bin/hypr-workspace-layout-toggle`).
- **Khuyến nghị kiến trúc**: Có thể áp dụng nguyên lý window tagging này để tạo ra chế độ workspace tùy thích mà không cần phụ thuộc vào distro Omarchy.

---

## 2. GIAO DỊCH CẬP NHẬT AN TOÀN QUA PID 1 SCOPE & SUDO TIMESTAMP KEEPALIVE

### Layer 1 — Feature Discovery
Trên Arch Linux, việc cập nhật hệ thống định kỳ (`pacman -Syu`) thường gặp phải 2 thảm họa kỹ thuật:
1. Gói `systemd` được nâng cấp ở giữa transaction, kích hoạt scriptlet `post_upgrade` thực hiện `systemctl daemon-reexec` cho cả PID 1 lẫn tất cả các systemd user instances. Quá trình re-exec này gửi `SIGKILL` hoặc ngắt kết nối session bus của phiên người dùng, làm tiến trình pacman đang ghi đĩa bị đứt gãy đột ngột, dẫn đến hỏng database và treo hệ điều hành.
2. Quá trình tải gói hoặc biên dịch AUR kéo dài quá thời hạn timeout của sudo (mặc định 5-15 phút), khiến tiến trình cập nhật dừng lại chờ mật khẩu vô thời hạn và thất bại nếu người dùng rời khỏi máy.

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `bin/omarchy-update`, `bin/omarchy-update-pacman`.
- **Cơ chế kỹ thuật**:
  1. **Cô lập giao dịch qua PID 1 Scope (`bin/omarchy-update-pacman`)**:
     ```bash
     scope=()
     if [[ -d /run/systemd/system && ! -L /run/systemd/system ]]; then
       scope=(systemd-run --scope --quiet --collect)
     fi
     exec sudo env "${env_args[@]}" "${scope[@]}" pacman "$@"
     ```
     Lệnh `systemd-run --scope` đẩy tiến trình pacman thành một Transient Scope trực tiếp dưới quyền quản lý của PID 1 (System Manager), hoàn toàn tách rời khỏi user session cgroup (`/user.slice/user-1000.slice/...`). Khi systemd user daemon re-exec hoặc phiên đồ họa bị ngắt, tiến trình pacman vẫn tiếp tục chạy độc lập đến khi hoàn tất!
  2. **Vòng lặp duy trì Sudo Timestamp an toàn (`bin/omarchy-update`)**:
     Thay vì gọi `sudo -v` (vốn vẫn đòi mật khẩu nếu file sudoers cấu hình `verifypw=all`), Omarchy chạy `sudo true` một lần đầu tiên, sau đó kích hoạt tiến trình nền:
     ```bash
     local update_pid=$$
     (
       sleep_pid=""
       trap '[[ -z $sleep_pid ]] || kill "$sleep_pid" 2>/dev/null; exit 0' TERM
       while :; do
         sleep 60 &
         sleep_pid=$!
         wait "$sleep_pid"
         kill -0 "$update_pid" 2>/dev/null || exit 0
         sudo -n true 2>/dev/null || exit 0
       done
     ) &
     sudo_keepalive_pid=$!
     ```
     Tiến trình nền kiểm tra sự tồn tại của tiến trình cha qua `kill -0 "$update_pid"`. Nếu tiến trình update chính kết thúc hoặc bị hủy, subshell tự động thoát ngay lập tức, triệt tiêu hoàn toàn nguy cơ rò rỉ sudo timestamp.
  3. **Ghi log PTY hoàn chỉnh qua `script`**:
     ```bash
     if [[ -z ${OMARCHY_UPDATE_LOGGED:-} ]]; then
       script_command=$(printf '%q ' "$0" "$@")
       exec env OMARCHY_UPDATE_LOGGED=1 script -qefc "$script_command" "/tmp/omarchy-update.log"
     fi
     ```
     Bọc toàn bộ phiên chạy trong một pseudoterminal (PTY) bằng tiện ích `script`, bảo toàn màu sắc ANSI, tiến trình phần trăm và ghi nhật ký toàn vẹn phục vụ chẩn đoán lỗi.

### Layer 3 — Root Design Idea
Phân tách đặc quyền và vòng đời tiến trình: Tách tác vụ nguy cấp (critical maintenance transaction) ra khỏi ngữ cảnh dễ bị tổn thương của phiên đồ họa (user desktop session), đồng thời tự động hóa việc gia hạn quyền hạn một cách an toàn có kiểm soát vòng đời.

### Layer 4 — Engineering Distillation
- **Nguyên lý**: Transient System Scope Isolation & Parent-Monitored Credential Refresh.
- **Bảo mật**: Subshell sudo không bao giờ chạy lệnh nguy hiểm, chỉ chạy `sudo -n true` (non-interactive). Nếu timestamp hết hạn tự nhiên, nó tự thoát chứ không treo hệ thống.
- **Độ tin cậy**: Ngăn chặn 100% tình trạng "Arch Linux broken mid-upgrade due to systemd re-exec".

### Layer 5 — Personal OS Application
- **Khả năng áp dụng vào Dotfiles**: **Bắt buộc phải áp dụng (Must Adopt)** cho bất kỳ hệ thống Arch Linux cá nhân nào.
- **Phân loại**: Shell script đặt tại `scripts/.local/bin/sys-update` hoặc `bin/safe-pacman`.

---

## 3. TỰ ĐỘNG HÓA XỬ LÝ CAPTIVE PORTAL & PAUSE TAILSCALE EXIT NODE

### Layer 1 — Feature Discovery
Khi sử dụng laptop tại quán cà phê, khách sạn hoặc sân bay:
1. Wi-Fi yêu cầu đăng nhập qua Captive Portal (Splash page).
2. Tuy nhiên, nếu laptop đang bật VPN hoặc Tailscale với chế độ **Exit Node**, toàn bộ lưu lượng mạng (kể cả DNS và HTTP kiểm tra captive portal) bị ép đi qua tunnel VPN đã bị Wi-Fi của khách sạn chặn. Kết quả: trình duyệt báo lỗi timeout, không thể mở trang đăng nhập, người dùng bị mất mạng hoàn toàn.
3. Người dùng phải mở terminal, gõ lệnh tắt exit node, mở trình duyệt, đăng nhập Wi-Fi, rồi lại mở terminal bật lại exit node.

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `bin/omarchy-network-captive-portal`.
- **Cơ chế kỹ thuật**:
  1. **Giao tiếp trực tiếp với Tailscale Daemon qua UNIX Domain Socket**:
     Không cần gọi CLI chậm chạp, script gọi thẳng vào socket quản trị cục bộ của Tailscale:
     ```bash
     tailscale_socket=/var/run/tailscale/tailscaled.sock
     curl -fsS --unix-socket "$tailscale_socket" -X POST \
       "http://local-tailscaled.sock/localapi/v0/set-use-exit-node-enabled?enabled=false"
     ```
  2. **Khóa chống chạy trùng lặp (Mutual Exclusion)**:
     Dùng File Descriptor 9 và `flock -n 9` tại `$XDG_RUNTIME_DIR/omarchy-network-captive-portal.lock`.
  3. **Mở Webapp nổi cô lập**:
     Mở cửa sổ trình duyệt độc lập dành riêng cho captive portal qua `omarchy-launch-webapp "$url"`, gán class đặc thù để Hyprland tự động thả nổi giữa màn hình.
  4. **Thăm dò kết nối mạng qua NetworkManager**:
     ```bash
     until [[ $(LC_ALL=C timeout 5 nmcli networking connectivity check 2>/dev/null) == "full" ]]; do
       sleep 2
     done
     ```
     Dùng `LC_ALL=C` để đảm bảo chuỗi trả về luôn là `full` bất kể ngôn ngữ hệ thống.
  5. **Tự động đóng cửa sổ và phục hồi VPN**:
     Ngay khi có mạng (`connectivity == full`), script dùng `hyprctl dispatch` đóng cửa sổ webapp và kích hoạt `trap restore_exit_node EXIT` để bật lại Tailscale exit node qua UNIX socket.

### Layer 3 — Root Design Idea
Tự động hóa luồng giải quyết sự cố mạng ngoại cảnh (network boundary resolution) bằng cách tạm thời hạ cấp lớp bảo vệ (VPN tunnel) chỉ trong thời gian cần thiết, sau đó tự phục hồi nguyên trạng mà không cần con người can thiệp.

### Layer 4 — Engineering Distillation
- **Nguyên lý**: State-Pausing Network Gateway Hook.
- **Dependencies**: `curl`, `nmcli` (hoặc `/sys/class/net`), Tailscale local API socket.
- **Failure Modes**: Nếu người dùng tắt cửa sổ webapp giữa chừng, trap EXIT vẫn đảm bảo Tailscale exit node được bật lại, không để hệ thống ở trạng thái rớt mạng vĩnh viễn.

### Layer 5 — Personal OS Application
- **Khả năng áp dụng vào Dotfiles**: **Rất cao (Adapt & Adopt)**.
- **Phân loại**: Tiện ích shell script trong `scripts/.local/bin/captive-portal-login` gắn vào NetworkManager dispatcher hook.

---

## 4. KIẾN TRÚC THÔNG BÁO D-BUS TRỰC TIẾP QUA `BUSCTL` THAY THẾ `NOTIFY-SEND`

### Layer 1 — Feature Discovery
Lệnh `notify-send` chuẩn của Linux có nhiều lỗ hổng và hạn chế kỹ thuật:
1. `notify-send` phân tích cú pháp tham số dòng lệnh một cách lỏng lẻo. Nếu nội dung tin nhắn của một tiến trình lạ bắt đầu bằng dấu gạch ngang (ví dụ headline là `--hint=...` hoặc `-i`), `notify-send` hiểu nhầm thành cờ lệnh, gây sập hoặc thực thi ngoài ý muốn.
2. Không hỗ trợ cập nhật nội dung thông báo tại chỗ (in-place replacement) một cách ổn định.
3. Không hỗ trợ gắn nút bấm hành động (interactive action buttons) tương tác trực tiếp với các lệnh shell phức tạp mà không bị lỗi command injection.

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `bin/omarchy-notification-send`.
- **Cơ chế kỹ thuật**:
  1. **Gọi D-Bus Native với Typed Signature**:
     Bỏ qua hoàn toàn nhị phân `notify-send`, script tương tác trực tiếp với dịch vụ D-Bus `org.freedesktop.Notifications` qua lệnh `busctl`:
     ```bash
     notify_cmd=(
       busctl --user -- call
       org.freedesktop.Notifications /org/freedesktop/Notifications
       org.freedesktop.Notifications Notify susssasa{sv}i
       "$app_name" "$replaces_id" "$app_icon" "$headline" "$description"
       0
       "$hint_count" "${hints[@]}"
       "$expire_timeout"
     )
     ```
     Chữ ký `susssasa{sv}i` quy định rõ ràng kiểu dữ liệu cho từng đối số:
     - `s`: App name (String)
     - `u`: Replaces ID (Uint32) — truyền ID cũ để cập nhật toast tại chỗ thay vì đẻ thêm toast mới!
     - `s`: App icon (String)
     - `s`: Summary / Headline (String)
     - `s`: Body / Description (String)
     - `as`: Actions array (Array of Strings)
     - `a{sv}`: Hints dictionary (Dictionary String -> Variant)
     - `i`: Expire timeout in ms (Int32)
  2. **Bảo vệ chống Command Injection qua mảng JSON NUL-delimited**:
     Các đối số thực thi khi bấm nút (`--action`, `--exec`) được đóng gói qua `jq -Rsc 'split("\u0000")[:-1]'` từ dòng ký tự NUL (`\0`), đảm bảo mọi khoảng trắng hay ký tự đặc biệt đều được giữ nguyên dạng mảng argv, không bao giờ bị phân rã qua `eval` hay `sh -c`.

### Layer 3 — Root Design Idea
Giao tiếp tầng thấp có định kiểu nghiêm ngặt (Strictly-Typed IPC) loại bỏ lớp biên dịch trung gian kém an toàn, biến hệ thống thông báo desktop thành một giao diện tương tác hai chiều thực sự (interactive two-way interface).

### Layer 4 — Engineering Distillation
- **Ưu điểm**: 0 nguy cơ command injection, cập nhật thanh tiến trình mượt mà với `-r`, tương tác nhanh từ notification card.
- **Khả năng tương thích**: Hoạt động với mọi Notification Daemon tuân thủ chuẩn freedesktop (Dunst, Mako, Swaync, Quickshell).

### Layer 5 — Personal OS Application
- **Khả năng áp dụng vào Dotfiles**: **Adopt ngay lập tức**.
- **Phân loại**: Thay thế toàn bộ các hàm gọi `notify-send` trong dotfiles bằng một wrapper `ka-notify` viết theo kiến trúc này.

---

## 5. LOW-LATENCY UNIX SOCKET IPC CHO DESKTOP SHELL QUA `SOCAT`

### Layer 1 — Feature Discovery
Khi người dùng bấm phím tắt mở menu (như menu kết nối Wi-Fi, chọn theme, chỉnh âm lượng), hầu hết các distro Wayland đều khởi chạy một tiến trình mới (ví dụ `rofi`, `wofi`, hoặc script Python). Việc fork tiến trình, nạp thư viện động, đọc cấu hình và vẽ lại giao diện thường tốn từ **60ms đến 250ms**, tạo cảm giác khựng (stutter) rõ rệt.

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `bin/omarchy-shell`.
- **Cơ chế kỹ thuật**:
  1. Desktop shell (Quickshell) luôn chạy nền và lắng nghe trên một UNIX Domain Socket chuyên dụng:
     `$XDG_RUNTIME_DIR/omarchy-shell-<socket_id>.sock`.
  2. Khi có phím tắt, script `omarchy-shell` kết nối tới socket bằng `socat` với định dạng dữ liệu phân cách bằng ký tự điều khiển ASCII:
     - Ký tự phân cách trường (Unit Separator): `\x1f`
     - Ký tự kết thúc bản ghi (Record Separator): `\x1e`
  3. Đo đạc độ trễ thực tế:
     - `socat` gửi lệnh qua UNIX socket: **~5ms**.
     - Lệnh `qs ipc` chính thức của Quickshell: **~45ms**.
     - Khởi chạy một tiến trình shell/python mới: **~60ms – 180ms**.
  4. Omarchy ưu tiên dùng socket `socat`, chỉ khi socket không phản hồi hoặc lệnh chứa ký tự đặc biệt mới fallback về `qs ipc`.

### Layer 3 — Root Design Idea
Thực hiện IPC phi tập trung thông qua UNIX Domain Socket với giao thức văn bản/ký tự phân tách siêu nhẹ thay vì spawn tiến trình con cho mỗi tương tác người dùng.

### Layer 4 — Engineering Distillation
- **Nguyên lý**: Persistent In-Memory UI Daemon + Microsecond Socket Dispatch.
- **Tài nguyên**: Giảm thiểu hàng ngàn lần fork/exec mỗi ngày, bảo vệ pin laptop và giảm tải CPU.

### Layer 5 — Personal OS Application
- **Ứng dụng**: Trong Personal OS, đối với statusbar hoặc popup menu, ta hoàn toàn có thể áp dụng mô hình này: Một daemon nhỏ (viết bằng C hoặc Rust) lắng nghe trên `$XDG_RUNTIME_DIR/my-shell.sock` để bật/tắt các thẻ trạng thái tức thì trong **< 1ms**.

---

## 6. MULTI-ACCOUNT AGENT ISOLATION & QUAKE DROP-DOWN CONSOLE

### Layer 1 — Feature Discovery
Lập trình viên sử dụng AI Coding Agents thường xuyên gặp phải giới hạn hạn mức (Rate Limits) của Claude Pro/Max, GitHub Copilot hay Codex. Omarchy 4.5 xây dựng một phân hệ hoàn chỉnh cho phép:
- Lưu trữ nhiều tài khoản trên cùng một máy (Personal, Work, Open-Source).
- Quake-style drop-down console (`Super + ~`) mở ngay terminal chạy agent từ bất kỳ màn hình nào.
- Tự động hoặc thủ công chuyển đổi tài khoản phiên làm việc mà không làm mất lịch sử dự án.

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `bin/omarchy-agent-account-exec`, `bin/omarchy-agent-account-home`, `bin/omarchy-agent-account-use`, `default/hypr/qconsole.lua`.
- **Cơ chế kỹ thuật**:
  1. **Cô lập cấu hình qua biến môi trường**:
     Mỗi Agent CLI đọc thư mục cấu hình qua một biến môi trường chuẩn:
     - Claude: `CLAUDE_CONFIG_DIR`
     - Codex: `CODEX_HOME`
     - Grok: `GROK_HOME`
  2. Wrapper `omarchy-agent-account-exec` can thiệp trước khi nhị phân thực thi:
     Đọc tài khoản active từ `~/.local/state/omarchy/agents/accounts/<provider>.json` và gán biến môi trường trỏ tới thư mục cấu hình riêng biệt: `~/.local/share/omarchy/agents/accounts/<provider>/<account-id>/`.
  3. **Tối ưu hóa đường nóng (Hot Path Optimization)**:
     `omarchy-agent-account-home` kiểm tra nhanh sự tồn tại của tệp registry. Nếu chỉ có tài khoản chính mặc định, nó trả về rỗng ngay lập tức bằng shell built-in mà không khởi động Python runtime, giữ thời gian thực thi < 1ms.
  4. **Quake Console Drop-down**:
     `qconsole.lua` tạo một cửa sổ terminal nổi có class riêng (`omarchy-agent-console`), gán phím tắt `Super + ~`, định vị cố định ở nửa trên màn hình với hiệu ứng trượt mượt mà.

### Layer 3 — Root Design Idea
Môi trường hóa danh tính công cụ (Identity Environment Isolation) kết hợp giao diện triệu hồi tức thì (On-Demand Scratchpad).

### Layer 4 — Engineering Distillation
- Không can thiệp vào mã nguồn của công cụ AI đóng gói sẵn; chỉ kiểm soát ngữ cảnh môi trường (Environment Injection) tại tầng shell wrapper.

### Layer 5 — Personal OS Application
- **Khả năng áp dụng vào Dotfiles**: **Adopt**.
- **Phân loại**: Cấu hình Hyprland Scratchpad/Special Workspace cho phím `Super + ~` và wrapper script quản lý biến môi trường trong `scripts/.local/bin/agent-wrapper`.

---

## 7. BIND NHẢ PHÍM KHÔNG NUỐT MODIFIER CHO PUSH-TO-TALK (`o.bind_hold`)

### Layer 1 — Feature Discovery
Khi cấu hình phím giữ để nói (Push-to-Talk) cho Dictation (nhập văn bản bằng giọng nói) hoặc microphone:
Người dùng giữ phím (ví dụ `Right Alt`), nói, rồi nhả phím ra để kết thúc ghi âm.
Tuy nhiên, trong các window manager như Hyprland hay Sway:
Nếu trong khi đang giữ phím, người dùng gõ thêm phím khác hoặc modifier thay đổi (ví dụ vô tình chạm Shift), compositor sẽ **nuốt mất sự kiện nhả phím (release event)**. Kết quả: micro bị kẹt ở trạng thái thu âm mãi mãi!

### Layer 2 — Implementation Analysis
- **Tệp mã nguồn cốt lõi**: `default/hypr/helpers.lua` (hàm `o.bind_hold`).
- **Cơ chế kỹ thuật**:
  ```lua
  function o.bind_hold(keys, press_description, press, release_description, release, options)
    local held = false
    -- ...
    local function on_press()
      held = true
      run(press)
    end
    local function on_release()
      if held then
        held = false
        run(release)
      end
    end
    -- Cấu hình cờ đặc biệt cho nửa Release:
    release_options.release = true
    release_options.transparent = true       -- Không chặn phím đối với các ứng dụng khác
    release_options.ignore_mods = true        -- Bỏ qua trạng thái modifier khi nhả phím
    release_options.non_consuming = true      -- Không nuốt phím
    
    o.bind(keys, press_description, on_press, press_options)
    o.bind(keys, release_description, on_release, release_options)
  end
  ```
  Nhờ kết hợp `transparent = true`, `ignore_mods = true` và cờ trạng thái boolean cục bộ `held`, sự kiện nhả phím được bảo đảm **100% luôn luôn được kích hoạt** ngay khi ngón tay rời khỏi phím, bất kể người dùng có bấm thêm bất kỳ phím nào khác trong lúc giữ.

### Layer 3 — Root Design Idea
Phá vỡ giới hạn của hệ thống phím tắt tiêu chuẩn bằng cách tách rời định tuyến nhấn (press routing) và định tuyến nhả (release routing), đồng thời duy trì máy trạng thái (state machine) ở tầng script.

### Layer 4 — Engineering Distillation
- Giải quyết triệt để lỗi kinh điển của Wayland compositor đối với các phím Push-to-Talk.

### Layer 5 — Personal OS Application
- **Khả năng áp dụng vào Dotfiles**: **Adopt ngay lập tức** vào cấu hình phím tắt Hyprland hoặc sxhkd.
