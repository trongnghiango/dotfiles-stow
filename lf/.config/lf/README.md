# 📖 Hướng Dẫn Sử Dụng lf File Manager (Tối Ưu Cho Developer & DevOps)

Hệ thống quản lý file `lf` trong bộ dotfiles của bạn được thiết kế theo trường phái tối giản, vận hành bằng phím tắt kiểu Vim, tích hợp sâu với các công cụ Unix mạnh mẽ (`fzf`, `7z`, `archivemount`, `ripdrag`, `ueberzug`).

---

## 🎮 1. Cẩm Nang Tra Cứu Phím Tắt Nhanh

### 🧭 Điều hướng & Thao tác Cơ bản
| Phím tắt | Hành động | Chi tiết |
| :--- | :--- | :--- |
| `h` / `j` / `k` / `l` | Trái / Xuống / Lên / Phải | Điều hướng cấu trúc thư mục (kiểu Vim) |
| `<c-y>` / `<c-e>` | Cuộn lên / Cuộn xuống | Di chuyển màn hình mà không đổi con trỏ |
| `g` | Lên đỉnh | Nhảy lên đầu danh sách file |
| `G` | Xuống đáy | Nhảy xuống cuối danh sách file |
| `.` | Hiện/Ẩn file ẩn | Bật/tắt hiển thị file `.*` |
| `r` / `rr` | Đổi tên | Đổi tên file/thư mục đơn lẻ |
| `y` / `d` / `p` | Yank / Cut / Paste | Copy / Di chuyển file |
| `D` | Xóa an toàn | Đưa file vào **Thùng rác hệ thống** (`trash-put`) |
| `U` | Copy Full Path | Sao chép đường dẫn tuyệt đối vào Clipboard |
| `u` | Copy File Name | Sao chép chỉ tên file vào Clipboard |

### 🔍 Tìm kiếm & Nhảy nhanh
| Phím tắt | Hành động | Chi tiết |
| :--- | :--- | :--- |
| `f` | Tìm kiếm mờ | Mở `fzf` để tìm và nhảy nhanh đến file/thư mục trong 3 cấp thư mục con |
| `/` | Tìm kiếm tại chỗ | Gõ ký tự để tìm trực tiếp trong thư mục hiện tại |

### 📦 Nén & Giải nén nâng cao
| Phím tắt | Hành động | Chi tiết |
| :--- | :--- | :--- |
| `zz` | Nén nâng cao | Nén file/thư mục bằng 7z (đa luồng, đặt pass, chia nhỏ) |
| `zx` | Giải nén tự động | Tự động giải nén (tự nhận diện part `.001`) |
| `zf` | Giải nén tương tác | Xem trước cấu trúc file nén và chọn file cần giải nén bằng `fzf` |
| `zm` | Mount file nén | Mount file nén thành thư mục ảo để đọc ghi trực tiếp |
| `zu` | Gỡ mount | Gỡ mount thư mục ảo khi xong việc |

### 🔗 Kéo thả & Tích hợp GUI
| Phím tắt | Hành động | Chi tiết |
| :--- | :--- | :--- |
| `<c-d>` | Kéo thả đồ họa | Kích hoạt `ripdrag` để kéo file thả vào Browser, Discord, Email |

---

## 🐚 2. Cách Chạy Lệnh Linux Trực Tiếp Trong `lf`

Khi đang ở trong `lf`, bạn không cần thoát ra ngoài shell để chạy lệnh Linux. Bạn có 4 cách tương tác sau:

1. **Lệnh Shell tạm thời (Không dừng màn hình):**
   - Nhấn `:` sau đó gõ `! <lệnh>`. Ví dụ: `:!touch test.txt`
   - Lệnh này chạy ngầm và không hiển thị đầu ra (output).
2. **Lệnh Shell tương tác (Dừng màn hình hiển thị output):**
   - Nhấn `$` (hoặc gõ `:shell`). Lệnh này sẽ mở ra màn hình shell thô để chạy lệnh.
   - Ví dụ: `$git status` -> sẽ dừng màn hình để bạn xem trạng thái git, nhấn `Enter` để quay lại `lf`.
3. **Mở terminal con tại thư mục hiện tại:**
   - Nhấn `Enter` (hoặc `!`) trên thư mục hiện tại hoặc nhấn `$` không có đối số để rơi vào shell hoàn chỉnh.
4. **Biến môi trường hữu ích có sẵn trong lệnh:**
   - `$f`: File hiện tại đang được trỏ.
   - `$fx`: Danh sách các file đang được chọn (bằng phím `Space`).
   - `$PWD`: Đường dẫn thư mục hiện tại.

---

## 🛠 3. Các Workflow Thường Dùng (Dành cho Dev / DevOps / AI)

### Workflow 1: Backup / Đóng gói mã nguồn & Dataset (Dev/AI)
1. Dùng `Space` để đánh dấu các thư mục/tập tin chứa mã nguồn và dataset.
2. Nhấn `zz`.
3. Giao diện nén hiển thị:
   - **Tên file nén**: Nhấn `Enter` để lấy tên mặc định dạng `[Tên_Thư_Mục]_[Ngày-Tháng].7z`.
   - **Mật khẩu**: Nhập mật khẩu nếu muốn bảo mật dữ liệu (sử dụng `-mhe=on` mã hóa cả cấu trúc file bên trong).
   - **Chia nhỏ (Split)**: Nếu muốn upload lên Drive/Github release, gõ dung lượng cắt (VD: `50m` hoặc `2g`), nếu không nhấn `Enter`.
   - **Mức nén**: Gõ `9` (siêu nén) để lưu trữ tối đa.
4. `7z` đa luồng sẽ tự động tận dụng tối đa số luồng CPU hiện có để backup nhanh nhất.

### Workflow 2: Trích xuất Dataset dung lượng lớn bị chia nhỏ (AI / DevOps)
Nhiều dataset lớn tải từ Internet bị chia thành `.7z.001`, `.7z.002`...
1. Tìm đến file bất kỳ (ví dụ: `data.7z.003`).
2. Nhấn `zx`.
3. Script tự động xác định file `.001` nguồn (`data.7z.001`), gộp các part và giải nén sạch sẽ vào thư mục `data`.

### Workflow 3: Đọc lướt Code / Tài liệu bên trong file nén (Dev / Sysadmin)
Thay vì giải nén hàng chục GB chỉ để đọc 1 file cấu hình hoặc file log:
1. Di chuyển con trỏ tới file nén (`.zip`, `.7z`, `.rar`).
2. Nhấn `zm` (Mount).
3. Hệ thống sẽ tự động mount file nén thành thư mục ảo `[tên_file]_mounted` và tự `cd` vào đó.
4. Duyệt tìm file log/config, nhấn `l` hoặc `Enter` để mở xem bằng Neovim.
5. Khi xem xong, lùi ra ngoài thư mục mount, di chuyển con trỏ tới thư mục mount đó và nhấn `zu` (Unmount) để dọn dẹp điểm mount ảo.

### Workflow 4: Đổi tên hàng loạt ảnh/file logs theo pattern (AI / Data Scientist)
Khi bạn cần rename hàng loạt ảnh dataset (ví dụ: `cat.jpg` thành `cat_001.jpg`):
1. Dùng `Space` chọn toàn bộ các file cần đổi tên.
2. Nhấn `rb` (Bulk Rename).
3. `lf` sẽ gom danh sách tên file mở vào một buffer Neovim.
4. Sử dụng sức mạnh chỉnh sửa cột của Neovim (ví dụ: `Ctrl+v` hoặc lệnh thay thế `:s/old/new/`) để chỉnh sửa tên file.
5. Lưu và thoát (`:wq`), `lf` sẽ tự đối chiếu dòng cũ - dòng mới và thực hiện lệnh `mv` an toàn.

---

## 💡 4. Mẹo Nhỏ & Lối Tắt (Quick Links)

Hệ thống phím tắt `C` (Change directory) và `E` (Edit Config) giúp bạn nhảy việc siêu nhanh:

- `Ccf`: Nhảy thẳng tới thư mục cấu hình `~/.config`.
- `CD`: Nhảy tới thư mục `~/Downloads`.
- `Ch`: Nhảy về thư mục Home `~`.
- `Ecfl`: Mở file cấu hình chính `lfrc` của `lf` bằng Neovim để chỉnh sửa ngay lập tức.
- `Ecfz`: Mở cấu hình Zsh `.zshrc`.
- `Ecfv`: Mở cấu hình Neovim `init.lua`.
- `Ecfh`: Mở hướng dẫn sử dụng `lf` này.
