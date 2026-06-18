# Tài liệu Dự án: Hệ thống Tự động hóa Môi trường & Làm sạch Sách (Markitdown Cleaner Project)

Tài liệu này ghi lại toàn bộ nội dung thảo luận, quá trình phân tích kỹ thuật và kết quả triển khai hệ thống làm sạch tài liệu tự nâng cấp kết hợp LLM, cùng các thiết lập hệ thống quan trọng trên môi trường **Arch Linux + DWM + startx**.

---

## 1. Nhật ký Sự cố và Giải pháp Hệ thống

### 1.1. Sự cố mất xác thực tài khoản Google (Antigravity 2.0 & Code - OSS)
*   **Triệu chứng:** Mỗi khi tắt máy hoặc khởi động lại, Antigravity 2.0 (ứng dụng Desktop độc lập) và Code - OSS đều bị mất phiên đăng nhập tài khoản Google, bắt buộc người dùng phải đăng nhập thủ công lại.
*   **Phân tích nguyên nhân:** 
    *   Để duy trì đăng nhập, VS Code và Antigravity 2.0 cần lưu trữ Token bảo mật vào **Gnome Keyring** thông qua D-Bus Secret Service.
    *   Do hệ thống sử dụng Window Manager tối giản (DWM) và đăng nhập qua TTY bằng lệnh `startx` (không có Display Manager như GDM/SDDM), Gnome Keyring không được tự động mở khóa (unlock) bằng mật khẩu đăng nhập tại thời điểm khởi động.
    *   Người dùng luôn nhấn **"Cancel"** khi hộp thoại mật khẩu keyring xuất hiện, dẫn đến việc Token chỉ được lưu tạm thời trên bộ nhớ RAM. Khi reboot, RAM bị xóa và token biến mất.
*   **Giải pháp chuyên nghiệp:**
    1.  Tích hợp mở khóa Gnome Keyring vào PAM (Pluggable Authentication Modules) của console login tại `/etc/pam.d/login`.
    2.  Thiết lập mật khẩu của Gnome Keyring (tên là `login`) trùng khớp 100% với mật khẩu đăng nhập Linux của user. Khi đó, PAM sẽ tự động lấy mật khẩu đăng nhập TTY để mở khóa ngầm Keyring, triệt tiêu hoàn toàn các pop-up mật khẩu phiền phức và lưu trữ token vĩnh viễn.

### 1.2. Lỗi direnv auto-activate Python venv
*   **Triệu chứng:** Khi chạy cấu hình `layout virtualenv .venv` trong file `.envrc`, `direnv` báo lỗi:
    `layout_virtualenv: command not found`
*   **Phân tích:** Thư viện chuẩn (stdlib) mặc định của `direnv` không định nghĩa hàm `layout_virtualenv` để nạp môi trường ảo `.venv` tự tạo (từ `python -m venv .venv`).
*   **Giải pháp:** 
    *   Tạo file cấu hình toàn cục của `direnv` tại [shell/.config/direnv/direnvrc](file:///home/ka/.dotfiles/shell/.config/direnv/direnvrc) định nghĩa hàm `layout_virtualenv` tùy chỉnh.
    *   Đồng bộ thông qua GNU Stow vào `~/.config/direnv/direnvrc`. Hàm này tự động thêm đường dẫn `.venv/bin` vào `$PATH` và xuất biến `$VIRTUAL_ENV` khi `cd` vào thư mục, đồng thời tự động gỡ bỏ (deactivate) an toàn khi `cd` ra ngoài.

---

## 2. Công cụ tự động cấu hình hệ thống (`ka-setup`)

Nhằm tránh việc phải cấu hình hệ thống thủ công bằng tay sau khi cài đặt hoặc active dotfiles, một script tự động hóa tên là **`ka-setup`** đã được xây dựng tại [scripts/.local/bin/ka-setup](file:///home/ka/.dotfiles/scripts/.local/bin/ka-setup) với các tiêu chí:

1.  **Tính Idempotent (Chống trùng lặp):** Kiểm tra trạng thái hiện tại của hệ thống trước khi cấu hình. Nếu đã cấu hình rồi sẽ tự động bỏ qua để tránh ghi đè file vô ích.
2.  **Cấu hình PAM tự động:** Tự động sao lưu `/etc/pam.d/login` và chèn dòng cấu hình mở khóa `pam_gnome_keyring.so` vào đúng khối `auth` và `session`.
3.  **Cấu hình Docker tối ưu:**
    *   Kiểm tra cài đặt Docker (hỏi cài đặt qua `pacman` nếu thiếu).
    *   Tự tạo nhóm `docker` và thêm user hiện tại vào nhóm (loại bỏ việc phải dùng `sudo docker`).
    *   Cấu hình **Docker Socket Activation**: Tắt `docker.service` chạy ngầm ngốn tài nguyên hệ thống, thay vào đó kích hoạt `docker.socket`. Docker daemon chỉ được hệ thống đánh thức khi có lệnh gọi (ví dụ từ CLI hoặc extension).

---

## 3. Quy trình làm sạch sách tự nâng cấp (TypeScript + Bun)

### 3.1. Tại sao chuyển từ Python sang TypeScript + Bun?
Mặc dù phiên bản ban đầu được phát triển bằng Python, việc chuyển dịch sang TypeScript chạy trên **Bun** mang lại nhiều lợi thế vượt trội cho môi trường làm việc của bạn:
*   **Không cần Venv/Dependencies rác:** Bun là một binary độc lập duy nhất có khả năng chạy trực tiếp file `.ts` mà không cần biên dịch hay tạo thư mục `node_modules` cồng kềnh trong dotfiles.
*   **Xử lý File & API cực nhanh:** Vấn đề đọc ghi file bằng `Bun.file()` và gọi API bằng `fetch()` tích hợp sẵn nhanh và gọn gàng hơn Python rất nhiều.
*   **Xử lý Regex & String:** Engine của JS (V8) được tối ưu hóa JIT rất mạnh cho các tác vụ thay thế Regex văn bản lớn.

### 3.2. Sơ đồ hoạt động của Pipeline

```mermaid
graph TD
    Input[cuon-sach.md (Raw)] -->|verify_loop.ts| Engine(clean_book.ts)
    Rules[(clean_rules.json)] -->|Load Regex| Engine
    Engine -->|Clean Output| Output[cuon-sach-clean.md]
    Output -->|Extract Samples| Samples[Start/Mid/End Lines]
    Samples -->|Prompt & API Key| LLM[Gemini 2.5 Flash]
    LLM -->|Verify & Detect Garbage| JSON[JSON Rules]
    JSON -->|If not clean| Update[Self-Update Rules]
    Update -->|Append| Rules
    JSON -->|If clean| Done[Done & Success]
```

### 3.3. Chi tiết các tệp trong thư mục `cleaner/`

1.  **[clean_rules.json](file:///home/ka/temps/markitdown/cleaner/clean_rules.json)**:
    Lưu trữ cấu trúc dữ liệu JSON chứa toàn bộ các quy luật Regex làm sạch tổng quát (calibre tags, class attributes, broken link structures, footnote formats) và các luật **tự động phát hiện và chuyển đổi tiêu đề dạng chữ đậm (PHẦN, CHƯƠNG, §, và số tiêu mục) sang các cấp độ Heading của Markdown (`#`, `##`, `###`)**.
2.  **[clean_book.ts](file:///home/ka/temps/markitdown/cleaner/clean_book.ts)**:
    Engine làm sạch. Nó áp dụng các Regex từ file JSON và chạy thuật toán Heuristic thông minh để ghép nối các dòng văn bản bị ngắt dòng vô lý (do cơ chế tọa độ dòng của PDF gốc) thành các đoạn văn liền mạch. Đặc biệt, nó tự động dịch các nhóm tham chiếu ngược (backreference) của Python dạng `\1`, `\2` sang định dạng `$1`, `$2` của JavaScript ở thời điểm chạy để duy trì khả năng tương thích của tệp cấu hình JSON.
3.  **[verify_loop.ts](file:///home/ka/temps/markitdown/cleaner/verify_loop.ts)**:
    Agent điều phối LLM.
    *   **Tối ưu hóa Token cực hạn:** Chỉ cắt 3 mẫu đại diện (Start, Middle, End) tổng cộng 150 dòng để gửi lên LLM thẩm định (tiết kiệm 99% token so với gửi cả cuốn sách).
    *   Nếu phát hiện rác mới, LLM tự động trả về Regex sửa lỗi. `verify_loop.ts` sẽ append trực tiếp luật này vào `clean_rules.json` và chạy lại.
    *   Vòng lặp chạy tối đa 3 lần hoặc dừng ngay khi LLM báo cáo văn bản đã hoàn toàn sạch sẽ.
4.  **[sachsach.ts](file:///home/ka/temps/markitdown/cleaner/sachsach.ts)**:
    Bộ điều phối toàn bộ quy trình (Master Orchestrator).
    *   Nhận diện định dạng đầu vào (`.pdf`, `.epub`, `.md`), tự động điều phối convert qua Calibre & Pandoc trước khi chạy vòng lặp clean & verify.
    *   **Tự xử lý xung đột Virtualenv:** Khi chạy trong môi trường có Python Virtualenv kích hoạt (do `direnv` hoặc thủ công), lệnh gọi Calibre (`ebook-convert` sử dụng shebang `#!/usr/bin/env python3`) sẽ bị trỏ nhầm vào Python của virtualenv - nơi không cài sẵn thư viện hệ thống như `msgpack`, dẫn đến lỗi `ModuleNotFoundError`. `sachsach.ts` tự động làm sạch môi trường bằng cách loại bỏ đường dẫn `.venv/bin` khỏi `PATH` và xóa biến `VIRTUAL_ENV` khi gọi các tiến trình con này, giúp Calibre chạy ổn định trên môi trường Python hệ thống.

### 3.4. Hướng dẫn chạy quy trình Bun
```bash
export GEMINI_API_KEY="your-gemini-api-key"
bun cleaner/sachsach.ts cuon-sach.pdf cuon-sach-clean.md
```
