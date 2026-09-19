# Handoff — DWM 6.8 Backporting Plan & Clean Code Implementation

## Focus
Kế hoạch chi tiết và tài liệu bàn giao để session mới triển khai ngay lập tức Phương án B: Vá ngược toàn diện các bản vá bảo mật và logic mới nhất từ upstream DWM 6.8 vào bản DWM chính của hệ thống, bảo toàn 100% kiến trúc Flexipatch và cơ chế Omarchy OS Popover Dropdown.

## Handoff reason
`user-initiated`

## Repo state
- **Branch**: `main`
- **HEAD Commit**: `1134a88651b16e0d1ade56c731319101d4603a13`
- **Working Tree**: Sạch hoàn toàn (`git status --short` is empty)

## State
Hệ thống statusbar và popover dropdown đã được tối ưu hóa toàn diện: loại bỏ hoàn toàn độ trễ `sleep 0.2` của `ka-cpu` chuyển sang tính toán delta tức thì (`0.001s`), giải quyết triệt để lỗi click bị nuốt trong `dwmblocks`, trang bị hiệu ứng loading trực quan (`󱑖`) cho CPU/Memory dropdown, và loại bỏ hiện tượng rò rỉ tiêu đề dropdown lên thanh statusbar. Thư mục `suckless/.local/src/dwm68/` đã được thiết lập với mã nguồn DWM 6.8 gốc sạch làm đối chiếu. Người dùng đã lựa chọn triển khai Phương án B (Backporting tinh hoa 6.8 vào bản DWM chính) và yêu cầu bàn giao kế hoạch triển khai an toàn tuyệt đối.

## Verification
- Biên dịch DWM chính hiện tại:
  ```bash
  cd suckless/.local/src/dwm && make clean && make
  ```
  *(Kết quả: PASS, không có lỗi)*
- Biên dịch Dwmblocks:
  ```bash
  cd suckless/.local/src/dwmblocks && make clean && make
  ```
  *(Kết quả: PASS)*
- Biên dịch DWM 6.8 gốc (thư mục đối chiếu):
  ```bash
  cd suckless/.local/src/dwm68 && make clean && make
  ```
  *(Kết quả: PASS)*
- Cú pháp Python & Bash scripts:
  ```bash
  python3 -m py_compile scripts/.local/bin/dwmblocks-scripts/dwm-dropdown
  bash -n scripts/.local/bin/set-dns
  bash -n scripts/.local/bin/dwmblocks-scripts/ka-cpu
  ```
  *(Kết quả: PASS)*

## Constraints
- **Không đập đi xây lại**: Giữ nguyên vẹn 100% cấu trúc modular `patch/` của Flexipatch hiện tại.
- **Bảo toàn cơ chế Omarchy OS Popover Dropdown**: Giữ nguyên vẹn các patch `bar_status2d`, `bar_statuscmd`, vạch underline động, `isinsideclient`, `killdropdown`.
- **Zero Downtime**: Giữ bản nhị phân hiện tại `/usr/local/bin/dwm` hoạt động bình thường, chỉ hoán đổi và gửi `kill -HUP` khi bản build mới đã vượt qua 100% kiểm tra biên dịch.
- **Clean Code & Truy nguyên nguồn gốc**: Mọi đoạn mã vá ngược đều phải có chú thích commit upstream rõ ràng.

## Risk context
**Tier 2 (Mã nguồn Window Manager cốt lõi)**: Chỉnh sửa mã nguồn C của DWM. Cần sao lưu trước khi chạm vào file và kiểm tra biên dịch `make` nghiêm ngặt trước khi `sudo make install`.

## Artifacts
- **Mã nguồn DWM chính (Cần nâng cấp)**: `suckless/.local/src/dwm/`
- **Mã nguồn DWM 6.8 sạch (Đối chiếu upstream)**: `suckless/.local/src/dwm68/`
- **Tập tin cấu hình DWM**: `suckless/.local/src/dwm/config.h` và `suckless/.local/src/dwm/config.mk`
- **Các patch thanh trạng thái liên quan**:
  - `suckless/.local/src/dwm/patch/bar_wintitle.c`
  - `suckless/.local/src/dwm/patch/bar_statuscmd.c`
  - `suckless/.local/src/dwm/patch/bar_status2d.c`
  - `suckless/.local/src/dwmblocks/src/block.c`

## Decisions
1. **Lựa chọn Phương án B (Backporting tinh hoa 6.8)**:
   - Thay vì mạo hiểm merge lại 35+ patch phức tạp từ đầu (nguy cơ phát sinh regression bug cao), trích xuất và vá ngược trực tiếp 8 bản vá quan trọng nhất từ upstream 6.8 vào nhánh DWM chính.
2. **Danh mục 8 bản vá Upstream 6.8 cần áp dụng**:
   - **Patch 1 (Bảo mật - Quan trọng nhất)**: Commits `244fa85` + `a9aa0d8` + `c3dd6a8` — Sửa lỗi Heap Buffer Overflow trong `getatomprop()` khi đọc thuộc tính X11 atoms rỗng hoặc không phải 32-bit.
   - **Patch 2 (EWMH Focus)**: Commit `397d618` — Luôn cập nhật atom `_NET_ACTIVE_WINDOW` trong `setfocus()` ngay cả với client đặt cờ `neverfocus` (giúp Steam, game Proton, Wine và thanh tác vụ nhận diện cửa sổ active chuẩn xác).
   - **Patch 3 (An toàn kiểu dữ liệu)**: Commit `5c9f303` — Sửa kiểu truy cập trong `getstate()` sang `long *` và kiểm tra `format == 32` trước khi đọc `WM_STATE`.
   - **Patch 4 (Bộ vẽ đồ họa X11)**: Commit `cfb8627` — Chặn lỗi tràn số âm không dấu (`unsigned integer underflow`) trong `drw_text()` (`drw.c`) khi `w < lpad`.
   - **Patch 5 (Bảo toàn lỗi hệ thống)**: Commit `fcb2476` — Lưu `saved_errno` trong `die()` (`util.c`) để `perror` luôn in đúng mã lỗi kernel.
   - **Patch 6 (Chuẩn C99 Strict Prototypes)**: Commit `5687f46` — Thêm `void` vào `updateclientlist(void)`.
   - **Patch 7 (Quản lý đa màn hình)**: Commit `2bb919e` — Tự động resize cửa sổ Fullscreen sang kích thước màn hình đích trong `sendmon()`.
   - **Patch 8 (Version Bump)**: Cập nhật `VERSION = 6.8` trong `suckless/.local/src/dwm/config.mk`.

## Next steps (Dành cho Agent ở Session mới thực hiện ngay)
1. **Bước 1 — Tạo bản sao lưu an toàn**:
   ```bash
   cp -a suckless/.local/src/dwm suckless/.local/src/dwm-pre68-backup
   ```
2. **Bước 2 — Áp dụng Patch 1 (`getatomprop` heap overflow fix)**:
   Mở `suckless/.local/src/dwm/dwm.c`, tìm hàm `getatomprop()` (khoảng dòng 1389):
   - Thay đổi tham số đọc: khai báo `int format;` và `unsigned long nitems, dl;`.
   - Gọi: `XGetWindowProperty(..., &da, &format, &nitems, &dl, &p)`.
   - Kiểm tra an toàn: `if (nitems > 0 && format == 32) atom = *(long *)p;`.
3. **Bước 3 — Áp dụng Patch 2 (`_NET_ACTIVE_WINDOW` in `setfocus`)**:
   Mở `suckless/.local/src/dwm/dwm.c`, tìm hàm `setfocus()`:
   - Đưa dòng cập nhật property `_NET_ACTIVE_WINDOW` ra ngoài khối `if (!c->neverfocus)` để luôn cập nhật cho X11 root window.
4. **Bước 4 — Áp dụng Patch 3 (`getstate` format 32 check)**:
   Mở `suckless/.local/src/dwm/dwm.c`, tìm hàm `getstate()`:
   - Thêm điều kiện `if (n != 0 && format == 32) result = *(long *)p;`.
5. **Bước 5 — Áp dụng Patch 4, 5, 6 (`drw.c`, `util.c`, `sendmon`)**:
   - Trong `suckless/.local/src/dwm/drw.c` (`drw_text`): Thêm `if (w < lpad) return x + w;`.
   - Trong `suckless/.local/src/dwm/util.c` (`die`): Thêm `int saved_errno = errno;` và dùng `strerror(saved_errno)`.
   - Trong `suckless/.local/src/dwm/dwm.c` (`sendmon`): Thêm `if (c->isfullscreen) resizeclient(c, m->mx, m->my, m->mw, m->mh);`.
6. **Bước 6 — Nâng phiên bản `VERSION = 6.8`**:
   - Cập nhật dòng 2 trong `suckless/.local/src/dwm/config.mk`: `VERSION = 6.8`.
7. **Bước 7 — Biên dịch và nạp bản mới**:
   ```bash
   cd suckless/.local/src/dwm && make clean && make
   sudo make install
   kill -HUP $(pidof dwm)
   ```
8. **Bước 8 — Xác thực kết quả**:
   - Kiểm tra `dwm -v` hiển thị: `dwm-6.8`.
   - Thử mở lại các cửa sổ, kiểm tra statusbar và dropdown popover hoạt động trơn tru.

## Blockers
None. Toàn bộ mã nguồn và giải pháp kỹ thuật đã được phân tích, đối chiếu và chuẩn bị sẵn sàng.

## Prior handoff
`docs/handoff/2026-09-17-142906_handoff-screen-recording-clean-deps-and-git-sync.md`

## Suggested skills
- `git-guardian`: Hướng dẫn tuân thủ quy trình Git an toàn tuyệt đối khi commit kết quả sau khi hoàn thành.
- `ka-execute`: Hỗ trợ định tuyến thực thi từng bước an toàn theo ranh giới kỹ thuật.
