# Production Readiness Checklist: Bảng Kiểm Định Vận Hành An Toàn

Bảng kiểm soát chất lượng kỹ thuật dành cho **Personal Linux OS**, giúp kiểm tra, triển khai và nâng cấp dotfiles trên máy thật mà **không bao giờ làm phá hỏng môi trường đang sử dụng**.

---

## 1. PHÂN LOẠI CÁC MỨC ĐỘ THAO TÁC AN TOÀN

| Phân loại | Hành động cụ thể | Quy tắc bắt buộc |
|---|---|---|
| **CÓ THỂ TỰ ĐỘNG HÓA 100% (Fully Automated)** | - Kiểm tra cú pháp shell (`shellcheck`)<br>- Kiểm tra liên kết mềm bị đứt gãy (`test-symlinks`)<br>- Format mã nguồn (`shfmt`, `stylua`)<br>- Xóa tệp bộ nhớ đệm tạm thời trong `$XDG_RUNTIME_DIR` | Được phép chạy trong Git pre-commit hooks hoặc Makefile |
| **YÊU CẦU XÁC NHẬN CỦA CON NGƯỜI (Requires Confirmation)** | - Cập nhật toàn bộ gói hệ thống (`safe-pacman`)<br>- Xóa các gói mồ côi (`pacman -Rns $(pacman -Qdtq)`)<br>- Thay đổi profile phần cứng (`hardware/profiles/`)<br>- Gỡ bỏ một module Stow (`stow -D`) | Bắt buộc phải có prompt hỏi `[y/N]` rõ ràng trước khi chạy |
| **TUYỆT ĐỐI CẤM THỰC HIỆN TỰ ĐỘNG (Never Automated)** | - `rm -rf` các thư mục dữ liệu cá nhân (`$HOME/Documents`, `$XDG_DATA_HOME`)<br>- Tự động ghi đè file cấu hình bằng lệnh `sed -i` vào symlink<br>- Tự động kích hoạt reboot / poweroff sau khi cài đặt<br>- Tự động đẩy private keys hoặc token vào Git | Phải chặn bằng linter và pre-commit guards |

---

## 2. QUY TRÌNH KIỂM ĐỊNH MÁY THẬT KHÔNG GÂY HỎNG HÓC (NON-DESTRUCTIVE TESTING)

Khi thử nghiệm dotfiles trên máy tính đang làm việc hàng ngày:

### Bước 1: Dry-Run Symlink Verification
Tuyệt đối không chạy `stow` trực tiếp. Luôn chạy qua chế độ mô phỏng không ghi đĩa:
```bash
# Cờ -n tương đương --no-folding / dry-run
stow -n -v -t "$HOME" <module_name>
```
Nếu có bất kỳ tệp tin thực tế nào đang nằm tại đích, Stow sẽ dừng lại và cảnh báo xung đột (conflict). Ta di chuyển tệp cũ vào thư mục backup trước khi liên kết.

### Bước 2: Kiểm Tra Tĩnh Toàn Bộ Mã Nguồn (Static Code Audit)
Chạy bộ kiểm tra không phá hủy:
```bash
# 1. Kiểm tra cú pháp toàn bộ shell scripts
find scripts/ -type f -name "*.sh" -o -perm -111 -exec shellcheck {} +

# 2. Kiểm tra cú pháp cấu hình Hyprland
hyprctl configcheck 2>&1

# 3. Kiểm tra cú pháp Lua (nếu dùng Neovim / Hyprland Lua)
luacheck modules/nvim/ modules/hyprland/

# 4. Kiểm tra symlink gãy (Broken links)
find -L "$HOME" -maxdepth 3 -type l -exec echo "Broken symlink: {}" \;
```

### Bước 3: Thử Nghiệm Trong Cửa Sổ Cách Ly (Nested Wayland Compositor)
Trước khi khởi động lại máy hoặc đăng xuất để thử cấu hình Window Manager mới:
- Chạy Hyprland lồng nhau trong một cửa sổ riêng biệt ngay trên desktop hiện tại:
  ```bash
  Hyprland --config "$HOME/.dotfiles/modules/hyprland/.config/hypr/hyprland.conf"
  ```
- Nếu cấu hình có lỗi cú pháp hoặc crash, chỉ có cửa sổ phụ bị tắt; toàn bộ công việc và phiên làm việc hiện tại của bạn được bảo đảm an toàn 100%.

---

## 3. CHECKLIST TRƯỚC KHI ĐƯA VÀO VẬN HÀNH (GO-LIVE CHECKLIST)

### A. Nền tảng & Hệ thống Tệp
- [ ] Mọi đường dẫn trong script đều dùng `$HOME` hoặc biến XDG, không hardcode `/home/username`.
- [ ] Không có file nào trong Git chứa token API, mật khẩu, hoặc private SSH keys (đã kiểm tra qua `gitleaks` hoặc `git-guardian`).
- [ ] Tệp `.gitignore` đã loại trừ toàn bộ thư mục `.local/state/`, `.cache/`, và `*.log`.
- [ ] Thư mục `hardware/current-host.conf` đã trỏ đúng vào profile của máy hiện tại.

### B. Shell & Quản lý Tiến trình
- [ ] Mọi script shell đều bắt đầu bằng `set -euo pipefail` (trừ trường hợp chủ đích bắt lỗi).
- [ ] Không có script nào sử dụng `eval` trên chuỗi đầu vào không đáng tin cậy.
- [ ] Tiến trình cập nhật hệ thống được bọc qua `systemd-run --scope` và có cơ chế dọn dẹp sudo keepalive khi thoát.
- [ ] Script kiểm tra mạng captive portal có trap khôi phục trạng thái mạng khi thoát.

### C. Trải nghiệm & Hiệu năng
- [ ] Thời gian khởi động shell (`time zsh -i -c exit`) đo đạc thực tế dưới 10ms.
- [ ] Thanh trạng thái không có khối nào chạy polling vô hạn dưới 5 giây.
- [ ] Phím tắt Quake console (`Super + ~`) hoạt động mượt mà và không làm mất tiến trình nền.
- [ ] Phím Push-to-Talk không bị kẹt thu âm khi gõ kèm phím khác.

---

## 4. KẾ HOẠCH ROLLBACK KHẨN CẤP (EMERGENCY ROLLBACK PLAN)

Nếu một lần cập nhật dotfiles hoặc nâng cấp hệ điều hành làm hỏng môi trường đồ họa:
1. **Chuyển sang TTY dự phòng**: Nhấn `Ctrl + Alt + F2` (hoặc `F3`) để vào giao diện dòng lệnh nguyên bản.
2. **Gỡ bỏ liên kết module gây lỗi**:
   ```bash
   cd ~/.dotfiles/modules
   stow -D -t "$HOME" <module_bi_loi>
   ```
3. **Khôi phục cấu hình dự phòng**:
   ```bash
   cp -r ~/.dotfiles-backup/latest/* ~/
   ```
4. **Rollback Snapshot hệ thống (nếu nâng cấp gói Arch bị lỗi)**:
   - Khởi động lại máy, tại menu Limine/Systemd-boot giữ phím mũi tên xuống để chọn Btrfs Snapshot trước thời điểm nâng cấp.
   - Hoặc khởi động vào snapshot và chạy `snapper rollback`.
