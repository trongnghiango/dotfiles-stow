# Architecture Distillation: Chắt Lọc Nguyên Lý Kiến Trúc Độc Lập Nền Tảng

Nếu loại bỏ toàn bộ mã nguồn cụ thể, toàn bộ thương hiệu và toàn bộ các tệp shell scripts của Omarchy đi, **những nguyên lý kiến trúc hệ thống Linux nào thực sự có giá trị vĩnh cửu và có thể tái sử dụng trên bất kỳ bản phân phối nào?**

---

## 1. NGUYÊN LÝ 1: CÔ LẬP VÒNG ĐỜI TIẾN TRÌNH (PROCESS LIFECYCLE & CGROUP ISOLATION)

### Vấn đề hệ thống kinh điển
Trong các môi trường Linux desktop truyền thống, khi người dùng khởi chạy một ứng dụng từ menu (Rofi, Wofi, dmenu) hoặc từ một script shell, ứng dụng đó trở thành tiến trình con của shell hoặc compositor. Khi compositor reload, crash hoặc khi phiên người dùng (user session) kết thúc:
- Các tiến trình con bị gửi `SIGHUP` hoặc `SIGKILL` hàng loạt.
- Tác vụ cập nhật hệ thống (`pacman -Syu`) bị giết giữa chừng, gây vỡ database.
- Không kiểm soát được giới hạn tài nguyên (CPU/RAM cgroup) của các ứng dụng riêng lẻ.

### Nguyên lý chắt lọc
**Mọi ứng dụng GUI và mọi tác vụ quản trị nguy cấp phải được khởi chạy dưới dạng Transient Systemd Scope hoặc Service riêng biệt:**
1. **Đối với ứng dụng người dùng**: Sử dụng `uwsm-app -- <command>` hoặc `systemd-run --user --scope --unit=app-<name> <command>`. Việc này đặt ứng dụng vào cgroup riêng dưới `app.slice`, bảo vệ ứng dụng khi compositor reload và tự động dọn dẹp tài nguyên khi tắt.
2. **Đối với giao dịch bảo trì hạt nhân**: Sử dụng `systemd-run --scope --collect pacman "$@"`. Việc này gắn giao dịch trực tiếp vào PID 1 (System Manager), hoàn toàn miễn nhiễm với sự sụp đổ hay re-exec của user session manager.

---

## 2. NGUYÊN LÝ 2: KIẾN TRÚC CẤU HÌNH PHÂN LỚP 3 TẦNG (THREE-TIER LAYERED CONFIGURATION)

### Vấn đề hệ thống kinh điển
Người dùng thường duy trì một repository dotfiles duy nhất. Khi cần tinh chỉnh một cấu hình riêng cho máy laptop (ví dụ độ sáng, pin, màn hình ngoài) hoặc cấu hình nhạy cảm của công ty, họ phải tạo branch Git riêng hoặc sửa trực tiếp vào file cấu hình. Kết quả là việc `git pull` cập nhật dotfiles từ máy này sang máy khác liên tục bị xung đột (git conflicts), hoặc vô tình ghi đè mất cấu hình đặc thù của máy kia.

### Nguyên lý chắt lọc
**Tuyệt đối không bao giờ để mã nguồn cấu hình mặc định (Immutable Defaults), cấu hình người dùng (User Overrides) và trạng thái runtime (Dynamic State) nằm chung trong một tệp tin duy nhất:**

```text
┌─────────────────────────────────────────────────────────────┐
│ TẦNG 1: BASE DEFAULTS (Bất biến, quản lý bởi Git Upstream)   │
│ - Đường dẫn: modules/<module>/default.conf                  │
│ - Trách nhiệm: Thiết lập khung sườn, phím tắt tiêu chuẩn   │
└──────────────────────────────┬──────────────────────────────┘
                               │ (được nạp trước)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ TẦNG 2: USER / HOST OVERRIDES (Tùy biến theo máy cụ thể)    │
│ - Đường dẫn: hosts/<hostname>/override.conf                 │
│ - Trách nhiệm: Ghi đè màn hình, tỷ lệ scale, phím riêng     │
└──────────────────────────────┬──────────────────────────────┘
                               │ (được nạp sau, có quyền override)
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ TẦNG 3: DYNAMIC RUNTIME STATE (Sinh ra trong phiên làm việc)│
│ - Đường dẫn: $XDG_STATE_HOME/<app>/state.conf               │
│ - Trách nhiệm: Ghi nhớ theme hiện tại, layout workspace, v.v│
└─────────────────────────────────────────────────────────────┘
```

**Quy tắc bất biến**:
- Tầng 1 không bao giờ bị sửa đổi cục bộ.
- Tầng 2 chỉ chứa những điểm khác biệt (delta diff).
- Tầng 3 hoàn toàn bị Git bỏ qua (`.gitignore`), chỉ được sinh ra và tiêu thụ bởi runtime scripts.

---

## 3. NGUYÊN LÝ 3: THIẾT KẾ HƯỚNG SỰ KIỆN THAY VÌ POLLING (EVENT-DRIVEN OVER POLLING)

### Vấn đề hệ thống kinh điển
Rất nhiều thanh trạng thái (statusbar) và scripts tự động hóa trên Linux được viết theo kiểu "ngây thơ":
```bash
while true; do
  check_status
  sleep 1
done
```
Vòng lặp này tiêu tốn context switches liên tục, đánh thức CPU khỏi trạng thái tiết kiệm điện (C-states), làm hao pin laptop nghiêm trọng và tạo I/O disk/socket không cần thiết.

### Nguyên lý chắt lọc
**Chuyển đổi 100% các luồng kiểm tra định kỳ sang mô hình Hướng Sự Kiện (Event-Driven):**
1. **Trạng thái Mạng**: Lắng nghe tín hiệu D-Bus từ NetworkManager (`dbus-monitor "type='signal',interface='org.freedesktop.NetworkManager'"`) hoặc udev events thay vì quét `ping` mỗi 5 giây.
2. **Trạng thái Âm lượng & Micro**: Lắng nghe sự kiện PipeWire qua `pactl subscribe` hoặc tín hiệu ALSA.
3. **Thanh Trạng Thái (Statusbar)**: Đặt khoảng thời gian cập nhật bằng 0 (`interval = 0`) cho các khối trạng thái ít biến động (như thông báo, ghi âm, chế độ workspace); chỉ kích hoạt vẽ lại khi nhận tín hiệu thời gian thực (Real-Time Signals như `SIGRTMIN+N`).
4. **Giao tiếp Shell Desktop**: Dùng UNIX Domain Socket với cơ chế blocking read / poll an toàn thay vì ghi file tạm rồi dùng tiến trình khác đọc lặp đi lặp lại.

---

## 4. NGUYÊN LÝ 4: GIAO THỨC IPC KHÔNG GÂY ĐỘ TRỄ (ZERO-OVERHEAD IPC DISPATCH)

### Vấn đề hệ thống kinh điển
Mỗi lần người dùng bấm phím tắt để mở một menu tùy chọn, hệ thống thực hiện một chuỗi thao tác nặng nề:
`Shell -> Fork Process -> Exec Bash/Python -> Load Shared Libs -> Parse JSON/YAML -> X11/Wayland Surface Create -> Render -> Destroy`.
Chuỗi này tốn tối thiểu **60ms đến 250ms**, khiến trải nghiệm desktop có cảm giác nặng nề.

### Nguyên lý chắt lọc
**Duy trì UI Daemon thường trực trong bộ nhớ và giao tiếp qua UNIX Socket với giao thức tối giản:**
- Daemon quản lý giao diện (UI) khởi động cùng phiên làm việc và giữ kết nối sẵn với Wayland Compositor.
- Khi có phím tắt từ Window Manager, tiến trình phát lệnh chỉ gửi một chuỗi byte ngắn gọn qua UNIX Domain Socket (được tối ưu hóa bằng các ký tự điều khiển ASCII như `\x1f` Unit Separator, `\x1e` Record Separator).
- UI Daemon nhận sự kiện trong vòng **< 1ms**, chỉ cần đổi trạng thái hiển thị (`visible = true`) của một widget đã được nạp sẵn vào GPU cache.

---

## 5. NGUYÊN LÝ 5: QUẢN LÝ ĐẶC QUYỀN CÓ RÀNG BUỘC THỜI HẠN (BOUNDED PRIVILEGE LEASING)

### Vấn đề hệ thống kinh điển
Nhiều script quản trị hệ thống Linux tự động hóa bằng cách lạm dụng `NOPASSWD: ALL` trong `/etc/sudoers` (rất nguy hiểm về mặt an ninh) hoặc để tiến trình sudo chạy không kiểm soát, dẫn đến rò rỉ quyền root nếu có tiến trình độc hại chèn vào.

### Nguyên lý chắt lọc
**Cấp phát đặc quyền đúng lúc (Just-In-Time) và ràng buộc thời hạn với tiến trình khởi tạo (Process-Bound Lease):**
1. Người dùng chỉ cần nhập mật khẩu sudo **đúng 1 lần** ở đầu quy trình.
2. Một tiến trình con giám sát được sinh ra độc quyền cho tác vụ đó, liên tục kiểm tra tính sống còn của tiến trình mẹ qua `kill -0 "$parent_pid"`.
3. Chỉ thực hiện `sudo -n true` (chế độ non-interactive) để gia hạn timestamp của Linux kernel.
4. Ngay khi tiến trình mẹ kết thúc (thành công hoặc bị ngắt đột ngột), trap tín hiệu tiêu diệt ngay lập tức tiến trình con giám sát, khép lại phiên đặc quyền an toàn.

---

## 6. NGUYÊN LÝ 6: ĐỘC LẬP TẦNG THẤP VỚI STRICTLY-TYPED D-BUS SIGNATURES

### Vấn đề hệ thống kinh điển
Các lệnh wrapper tiện ích dòng lệnh (như `notify-send`, `nmcli`, `pactl`) thường thay đổi cú pháp, cờ lệnh hoặc cách định dạng văn bản xuất ra (text output) qua các phiên bản phân phối khác nhau, khiến shell scripts rất dễ bị gãy (fragile). Hơn nữa, việc ghép chuỗi văn bản không qua kiểm định rất dễ dẫn tới command injection.

### Nguyên lý chắt lọc
**Giao tiếp trực tiếp với D-Bus Session/System Bus bằng `busctl` với chữ ký tham số tường minh (Typed Signatures):**
- Thay vì bọc `notify-send "hello"`, gọi trực tiếp D-Bus method `org.freedesktop.Notifications.Notify` với chữ ký `susssasa{sv}i`.
- Dữ liệu được truyền dưới dạng các tham số nhị phân có kiểu (String, Uint32, Array, Dictionary Variant), loại bỏ 100% nguy cơ dữ liệu người dùng bị hiểu nhầm thành cờ dòng lệnh (flags).
- Không phụ thuộc vào việc hệ thống cài đặt `libnotify` hay tiện ích nào; chỉ cần hệ thống có `systemd` / `dbus`.
