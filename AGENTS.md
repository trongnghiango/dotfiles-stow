# AGENTS.md — dotfiles

> **Học thuyết Một Con Đường & Kỷ Luật Kỹ Thuật**: Tài liệu này mô tả CHÍNH XÁC 100% hành vi của mã nguồn trong kho lưu trữ. Mọi khẳng định kỹ thuật đều có dẫn chứng cụ thể đến từng dòng mã nguồn. Không được phép làm tròn sự thật hoặc tuyên bố các tính năng không có thật trong mã nguồn.

---

## 1. BẢN ĐỒ KIẾN TRÚC & PHÂN TẦNG THỰC TẾ

Hệ thống được tổ chức thành 24 gói GNU Stow triển khai liên kết mềm (symlink) vào `$HOME`:

```
[ Nhân Linux & Giao tiếp /sys, /dev, /proc ]
                       │
       [ TTY1 Login / PAM (pam_gnome_keyring) ]
                       │
     [ Zsh Login: ~/.zshenv -> .zprofile -> shell/profile ]
                       │
             [ exec startx "$XINITRC" ]
                       │
     [ x11/.config/x11/xinitrc (Session Initializer) ]
        ├── D-Bus session bus (xinitrc:13-21)
        ├── Hardware driver overrides (xinitrc:47-53)
        ├── Xresources merge via xrdb (xinitrc:68-71)
        ├── Polkit agent & Keyring (xinitrc:76-96)
        ├── PipeWire audio cluster (xinitrc.$OS)
        ├── Session daemons (dunst, picom, fcitx5, udiskie, etc.)
        └── exec ssh-agent dwm (xinitrc:178)
```

---

## 2. KIỂM TOÁN TÍNH NĂNG STATUSBAR & TIẾN TRÌNH C (DWMBLOCKS)

### Khối hiển thị thực tế trong `suckless/.local/src/dwmblocks/blocks.h`
Chỉ có **8 blocks** thực sự được đăng ký trong mảng `blocks[]` (`blocks.h:14-21`):

1. **`ka-forecast`** (`native_blocks.c:367`): In-process C, đọc tệp bộ nhớ đệm `~/.cache/weatherreport` (0 fork, 0 subshell).
2. **`ka-memory`** (`native_blocks.c:126`): In-process C, đọc trực tiếp `/proc/meminfo` (0 fork, 0 subshell).
3. **`ka-cpu`** (`native_blocks.c:76`): In-process C, đọc vi sai hai lần từ `/proc/stat` (0 fork, 0 sleep).
4. **`ka-network`** (`native_blocks.c:206`): In-process C, đọc `/proc/net/wireless` và `/sys/class/net` (0 fork).
5. **`ka-battery`** (`native_blocks.c:140`): In-process C, đọc trạng thái từ `/sys/class/power_supply` (0 fork).
6. **`ka-volume`** (`native_blocks.c:298`): In-process C, đọc giá trị phần cứng trực tiếp qua thư viện ALSA (`libasound`, hàm `snd_mixer_selem_get_playback_volume`) (0 fork, 0 subshell).
7. **`sb-record`** (`native_blocks.c:454`): In-process C, kiểm tra sự tồn tại của file PID quay màn hình `$XDG_RUNTIME_DIR/record/omarecord.pid` (0 fork).
8. **`ka-clock`** (`native_blocks.c:283`): In-process C, gọi trực tiếp hàm thư viện C `time()` và `localtime()` (0 fork).

> [!CAUTION]
> **Khối `sb-notify` (`native_blocks.c:414`) KHÔNG PHẢI zero-fork**: Hàm này gọi `exec_capture` 2 lần, thực hiện `fork()` và chạy `/usr/bin/dunstctl`. Khối này hiện **CHƯA ĐƯỢC ĐĂNG KÝ** trong `blocks.h:14-21`.

---

## 3. CÁC QUY TẮC BẮT BUỘC DÀNH CHO AI AGENT

Mọi AI Agent khi làm việc trong repository này **BẮT BUỘC TUÂN THỦ**:

1. **Học thuyết Một Con Đường (One Path Doctrine)**: Mỗi chức năng chỉ duy trì một công cụ duy nhất. Không duy trì các bản sao song song bằng Bash/Python khi đã có bản C native.
2. **Bất biến của GNU Stow**: Tuyệt đối **CẤM dùng `sed -i`** hoặc ghi đè lên bất kỳ tệp tin nào là liên kết mềm trỏ vào các gói Stow. Mọi cấu hình động phải được sinh ra ngoài cây Stow và `source`/`include` tĩnh.
3. **Cấm tuyệt đối lệnh `eval`**: Không sử dụng `eval` trên dữ liệu đọc từ file cấu hình hoặc bookmark của người dùng. Luôn dùng vòng lặp `while IFS= read -r line` an toàn.
4. **Không dùng `/tmp` cho tệp trạng thái hoặc socket**: Mọi file PID, socket IPC, log daemon và file trạng thái bắt buộc phải nằm trong `$XDG_RUNTIME_DIR/<app>/` (phân quyền riêng tư `0700` theo UID).
5. **Tự soi chiếu qua `state.json`**: Trạng thái hệ thống được đồng bộ hóa tại `$XDG_RUNTIME_DIR/ka/state.json`. Đọc trực tiếp file này thay vì dùng `grep`/`pidof` mò mẫm.
6. **Mọi script thay đổi cấu hình phải có `--check`**: Cho phép agent chạy giả lập dry-run để kiểm tra trước khi ghi đè thật.
7. **Chạy kiểm tra `agent-guard`**: Trước khi kết thúc phiên, chạy `./scripts/.local/bin/agent-guard` để xác nhận không vi phạm bất kỳ nguyên tắc an toàn nào.
---

## 4. CẤU HÌNH PHẦN CỨNG & NGÂN SÁCH BỘ NHỚ (MÁY CỔ VS MÁY HIỆN ĐẠI)

### Ngân sách tài nguyên & Phân loại cấu hình (`hardware/profiles/`)
Cấu hình phần cứng được quản lý qua `ka-profile` và nạp tự động tại `xinitrc`:

- **Profile máy cổ 10+ năm (`thinkpad-x230.conf`)**:
  - `AUDIO_BACKEND="alsa"`: Bỏ qua cụm daemon PipeWire, tiết kiệm **~60MB RAM** và giảm tối đa context switch.
  - `PICOM_BACKEND="none"`: Tắt hẳn tiến trình `picom` trong `xinitrc`, tiết kiệm **~30MB RAM** và tránh lỗi xé hình/crash GPU Intel HD 4000.
  - `DEFAULT_BROWSER="firefox-esr"`: Trình duyệt tiết kiệm bộ nhớ thay cho Chromium fork.
  - `CPU_GOVERNOR="powersave"` và `BATTERY_THRESHOLDS="50-60"`: Được `ka-profile` áp dụng trực tiếp xuống `/sys`.
- **Profile máy hiện đại (`thinkpad-t480.conf`, `generic.conf`...)**:
  - `AUDIO_BACKEND="pipewire"`, `PICOM_BACKEND="glx"`, `DEFAULT_BROWSER="brave"`.

### Kích thước nhị phân & Dung lượng RAM thực tế đo đạc
- **`ka-clipd`**: Kích thước nhị phân 22 KB (text: 8.8KB, bss: 12.3KB), RAM thực tế **~1.1 MB RSS**, 0.0% CPU idle (lắng nghe sự kiện XFixes).
- **`dwmblocks`**: Kích thước nhị phân 27 KB (text: 26.1KB), RAM thực tế **~2.2 MB RSS** (in-process C blocks).
- **`ka-pop`**: Kích thước nhị phân 41 KB (text: 39.4KB), chạy theo nhu cầu on-demand (**0 MB RAM khi idle**, ~35 MB khi mở thẻ GTK3).
- **`dwm 6.8`**: RAM thực tế **~15 MB RSS**.
