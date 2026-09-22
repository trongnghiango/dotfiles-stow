# Handoff — DWMBlocks Dropdown Alignment, Hover Preview & Stability Overhaul

## Focus
Điều tra nguyên nhân gốc rễ (RCA) và khắc phục toàn diện lỗi dropdown của dwmblocks không hiển thị, lỗi lệch tọa độ giữa vạch hover và active underline, lỗi vạch hover không biến mất khi chuột rời bar theo trục Y, vá lỗi tràn số nguyên (integer underflow) gây crash SIGSEGV trong dwmblocks, loại bỏ các cờ đồ họa thực nghiệm gây treo GPU trên ThinkPad X230, và cập nhật tài liệu kiến trúc hệ thống (`AGENTS.md`, `MANUAL.md`).

## Handoff reason
`phase-complete`

## Repo state
- **Branch**: `main`
- **HEAD Commit**: `2320de1ef01b2e27b8ecb1f1769f8f10218a0c61`
- **Dirty/uncommitted files**:
  ```text
  nothing to commit, working tree clean
  ```

## State
Đã điều tra và xử lý triệt để 5 vấn đề cốt lõi trên cụm thanh trạng thái (DWM + dwmblocks + ka-pop):
1. **Khắc phục lỗi crash sập ngầm dwmblocks**: Sửa lỗi integer underflow `active_block_count` khi `poll()` bị ngắt bởi tín hiệu `EINTR` trong `suckless/.local/src/dwmblocks/src/watcher.c`.
2. **Khắc phục lỗi treo cứng hệ thống trên ThinkPad X230**: Khôi phục cấu hình an toàn `PICOM_BACKEND="none"` và loại bỏ các cờ Mesa thực nghiệm (`crocus`, `LIBGL_DRI3_ENABLE`) trong `hardware/profiles/thinkpad-x230.conf` để chống sập GPU Intel HD 4000 (Ivy Bridge).
3. **Triệt tiêu độ lệch giữa Hover và Active Underline (0-pixel drift)**: Xây dựng bộ phân tích hình học khối thống nhất `parse_status_blocks()` trong `bar_status2d.c`, tách rời biểu tượng icon khỏi khoảng trắng phân cách `DELIMITER "  "`.
4. **Chuẩn hóa vùng bấm chuột (Hit-box)**: Tính toán biên giới click theo trung điểm thị giác giữa các icon `(prev_icon_end + cur_icon_start) / 2`, chấm dứt hiện tượng click nhầm vào khoảng trắng của icon liền kề.
5. **Dọn dẹp vạch Hover đa trục**: Bổ sung cơ chế dọn dẹp `hover_block` trong `leavenotify()` và `motionnotify()` (`dwm.c`), giúp vạch hover biến mất tức thì khi chuột trượt xuống dưới theo trục Y ra khỏi thanh bar.
6. **Đồng bộ hóa tài liệu hệ thống**: Cập nhật chi tiết cơ chế hình học thanh bar và xem trước Hover vào `AGENTS.md` và `MANUAL.md`.

## Verification
- **DWM Compilation**: PASS (`make -C suckless/.local/src/dwm clean && make -C suckless/.local/src/dwm`, 0 errors, exit code 0).
- **DWMBlocks Compilation**: PASS (`make -C suckless/.local/src/dwmblocks clean && make -C suckless/.local/src/dwmblocks`, 0 errors, exit code 0).
- **Agent Guard Safety Check**: PASS (`./scripts/.local/bin/agent-guard`, All agent-safety checks passed).
- **Commands to re-verify**:
  ```bash
  # 1. Kiểm tra biên dịch DWM
  make -C suckless/.local/src/dwm clean && make -C suckless/.local/src/dwm -j$(nproc)
  # 2. Kiểm tra biên dịch DWMBlocks
  make -C suckless/.local/src/dwmblocks clean && make -C suckless/.local/src/dwmblocks -j$(nproc)
  # 3. Dọn sạch nhị phân tuân thủ Zero-Binary
  make -C suckless/.local/src/dwm clean && make -C suckless/.local/src/dwmblocks clean
  # 4. Kiểm tra an toàn kiến trúc
  ./scripts/.local/bin/agent-guard
  ```

## Constraints
- **Bắt buộc tuân thủ 7 NGUYÊN TẮC THÉP trong `AGENTS.md`**:
  1. *Zero-Binary trong Git*: CẤM tuyệt đối commit file thực thi nhị phân compiled ELF (`dwm`, `dwmblocks`, `ka-pop`, `*.o`, `build/`). Mọi binary C Native phải được biên dịch cục bộ qua `ka-setup suckless`.
  2. *Bất biến của GNU Stow*: Tuyệt đối CẤM dùng `sed -i` hoặc ghi đè lên các tệp tin là symlink của Stow packages.
  3. *Khung gầm phần cứng máy cổ*: Duy trì `PICOM_BACKEND="none"` và `AUDIO_BACKEND="alsa"` cho ThinkPad X230 (`thinkpad-x230.conf`), không thêm cờ render lạ gây crash GPU.
  4. *Học thuyết Một Con Đường*: Mỗi chức năng duy trì 1 công cụ duy nhất (Native C in-process cho dwmblocks, GTK3 native cho ka-pop), không phục hồi script Bash/Python cũ.

## Risk context
Tier 2 (Internal Core C & Window Manager Logic). Các thay đổi tác động trực tiếp lên vòng lặp sự kiện X11 (`MotionNotify`, `LeaveNotify`, `ButtonPress`) và cơ chế vẽ statusbar.

## Artifacts
- **Commits đã triển khai**:
  - `8e6de43`: `fix: add event bounds checking in dwmblocks watcher and update thinkpad hardware configuration`
  - `baa3f92`: `feat: add hover highlight effect for status bar modules`
  - `767dc7d`: `refactor: introduce StatusBlock struct and helper functions for status2d parsing`
  - `c9566ec`: `fix: reset hover block and redraw bar when leaving bar area`
  - `2320de1`: `docs: update agent and manual documentation`
- **Tệp nguồn chính**:
  - `suckless/.local/src/dwm/dwm.c`: Khai báo `hover_block`, xử lý `leavenotify` và `motionnotify`.
  - `suckless/.local/src/dwm/patch/bar.c`: Truyền động `barg.bar_x` và dọn dẹp hover theo trục X.
  - `suckless/.local/src/dwm/patch/bar_status2d.c`: Phân tích hình học `parse_status_blocks()`, vẽ vạch Hover và Active.
  - `suckless/.local/src/dwm/patch/bar_status2d.h`: Định nghĩa cấu trúc `StatusBlock` và nguyên mẫu hàm.
  - `suckless/.local/src/dwm/patch/bar_statuscmd.c`: Thuật toán bắt click/hover `find_block_at()`.
  - `suckless/.local/src/dwmblocks/src/watcher.c`: Vá lỗi integer underflow `active_block_count`.
  - `hardware/.config/hardware/profiles/thinkpad-x230.conf`: Khôi phục `PICOM_BACKEND="none"`.
  - `AGENTS.md` & `MANUAL.md`: Cập nhật tài liệu kiến trúc và sổ tay người dùng.

## Decisions
- **Quyết định 1**: Dùng chung cấu trúc `StatusBlock` và hàm `parse_status_blocks()` cho toàn bộ các chức năng tính toán statusbar: vẽ underline (Hover/Active), tính vùng hit-box, và định vị cửa sổ popup `ka-pop` (`calblockpos`).
- **Quyết định 2**: Tính ranh giới hit-box bằng trung điểm khoảng cách giữa các icon `(prev_icon_end + cur_icon_start) / 2` thay vì tính gộp khoảng trắng vào icon đứng trước, loại bỏ hoàn toàn việc click nhầm.
- **Quyết định 3**: Xóa sạch `hover_block` ngay khi chuột rời khỏi `bar->win` theo trục Y trong `leavenotify()` và `motionnotify()`.
- **Quyết định 4**: Giữ `PICOM_BACKEND="none"` trên ThinkPad X230 để ngăn chặn GPU ringbuffer lockup.

## Next steps
1. Chạy `ka setup suckless` trên máy đích để biên dịch và cài đặt `dwm` + `dwmblocks` mới nhất vào `/usr/local/bin/`.
2. Khởi động lại phiên làm việc X11 (`Super + Shift + Q` rồi `startx`).
3. Kiểm tra thực tế:
   - Rê chuột vào các icon bên phải (Volume, Battery, CPU...): vạch hover xuất hiện chuẩn xác ôm đáy icon, con trỏ chuyển sang hình bàn tay.
   - Rê chuột ra khỏi bar theo trục X hoặc trục Y xuống cửa sổ bên dưới: vạch hover biến mất tức thì.
   - Click chuột: popup mở ra ngay ngắn, vạch active sáng đậm trùng khớp 100% với vạch hover trước đó.

## Blockers
N/A

## Prior handoff
`docs/handoff/2026-09-21-202445_handoff-multi-distro-engine-adapters-and-modular-c-stack.md`

## Suggested skills
- `git-guardian`: Quản lý an toàn thao tác git và trạng thái repository.
- `ka-ops`: Hỗ trợ tự động hóa kiểm tra sức khỏe hệ thống và triển khai cấu hình phần cứng.
