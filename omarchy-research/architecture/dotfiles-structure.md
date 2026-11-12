# Dotfiles Structure & Configuration Engine: Thiết Kế Kho Lưu Trữ Cấu Hình

Thiết kế cấu trúc repository dotfiles, phân tích so sánh các công cụ quản lý cấu hình và phương thức xử lý đa thiết bị (multi-host) an toàn.

---

## 1. PHÂN TÍCH SO SÁNH CÁC CÔNG CỤ QUẢN LÝ DOTFILES

| Công cụ | Cơ chế hoạt động | Ưu điểm | Nhược điểm | Đánh giá kiến trúc |
|---|---|---|---|---|
| **GNU Stow** | Tạo Symlink nguyên tử từ cấu trúc thư mục vào `$HOME` | Cực kỳ đơn giản, trực quan, không phụ thuộc runtime nặng, theo dõi file bằng `ls -l` dễ dàng | Thiếu templating tích hợp sẵn; cần script phụ trợ cho host-specific | **KHUYẾN NGHỊ CAO NHẤT (Adopt)** |
| **chezmoi** | Kho source riêng + sinh file thật vào `$HOME` qua template Go | Hỗ trợ template mạnh mẽ, tích hợp mã hóa password manager tốt | Gây đứt gãy tính "sửa file là ăn ngay"; phải chạy `chezmoi apply` sau mỗi lần sửa; dễ nhầm lẫn giữa source và target | Thích hợp cho fleet quản trị, hơi cồng kềnh cho cá nhân |
| **Home Manager (Nix)** | Khai báo toàn bộ môi trường bằng ngôn ngữ Nix | Tính tái lập (reproducibility) tuyệt đối, rollback hoàn hảo | Kéo theo Nix store hàng chục Gigabyte; độ dốc học tập (learning curve) cực cao; không dùng được standard Arch packages | Quá phức tạp (Overkill) |
| **Plain Git Bare Repo** | `git --git-dir=$HOME/.cfg --work-tree=$HOME` | Không cần symlink, file nằm thẳng tại `$HOME` | Dễ làm rác thư mục `$HOME`; lệnh git dễ bị nhầm lẫn; khó phân module tách rời | Dễ gây lỗi thao tác |

### Quyết định kỹ thuật: **GNU Stow + Layered Scripts**
- **Lý do**: GNU Stow giữ đúng triết lý của UNIX: "Làm một việc và làm thật tốt". Stow chỉ làm nhiệm vụ tạo symlink.
- Các yêu cầu nâng cao (như templating, host-specific override) được giải quyết nhẹ nhàng thông qua cơ chế phân lớp cấu hình (Layered Configuration) bằng native include (`source` trong shell, `include` trong i3/hyprland/sway, `require` trong Lua) thay vì phụ thuộc vào một công cụ biên dịch trung gian.

---

## 2. CẤU TRÚC KHO LƯU TRỮ DOTFILES ĐỀ XUẤT

Repository được tổ chức theo các gói Stow (Stow packages) độc lập, có thể bật/tắt tùy ý:

```text
dotfiles/
├── bootstrap/                          # Kịch bản cài đặt và thiết lập máy mới
│   ├── arch-bootstrap.sh               # Cài đặt các gói tối thiểu
│   ├── stow-all.sh                     # Triển khai toàn bộ symlink
│   └── verify.sh                       # Kiểm tra tính toàn vẹn của symlink
│
├── modules/                            # Các gói GNU Stow độc lập
│   ├── shell/                          # Môi trường dòng lệnh
│   │   ├── .config/zsh/.zshrc
│   │   ├── .config/zsh/.zshenv
│   │   └── .config/shell/profile
│   ├── hyprland/                       # Window Manager
│   │   ├── .config/hypr/hyprland.conf
│   │   ├── .config/hypr/bindings.conf
│   │   └── .config/hypr/rules.conf
│   ├── terminal/                       # Trình giả lập dòng lệnh
│   │   └── .config/foot/foot.ini
│   ├── statusbar/                      # Thanh trạng thái
│   │   └── .config/waybar/config.jsonc
│   ├── notifications/                  # Hệ thống thông báo
│   │   └── .config/dunst/dunstrc
│   ├── git/                            # Cấu hình kiểm soát phiên bản
│   │   ├── .config/git/config
│   │   └── .config/git/ignore
│   ├── nvim/                           # Trình biên tập mã nguồn Neovim
│   │   └── .config/nvim/init.lua
│   └── agent-workspace/                # Cấu hình AI Coding Agents
│       ├── .config/agent/default.conf
│       └── .config/agent/skills/
│
├── scripts/                            # Các tiện ích nhị phân cá nhân
│   └── .local/bin/
│       ├── safe-pacman                 # Cập nhật hệ thống chống sập
│       ├── ka-notify                   # D-Bus native notification wrapper
│       ├── captive-portal-resolver     # Tự động hóa đăng nhập Wi-Fi
│       ├── agent-account-switch        # Chuyển đổi tài khoản AI Agent
│       └── drop-down-console           # Điều phối Quake console
│
├── hardware/                           # Cấu hình chuyên biệt theo máy (Host Profiles)
│   ├── profiles/
│   │   ├── thinkpad-t480.conf          # Máy làm việc chính (glx, pipewire)
│   │   ├── thinkpad-x230.conf          # Máy phụ cổ điển (alsa, no-picom)
│   │   └── desktop-workstation.conf    # Máy bàn đa màn hình
│   └── current-host.conf -> profiles/thinkpad-t480.conf (Symlink động)
│
├── tests/                              # Bộ kiểm thử tự động
│   ├── lint-shell.sh                   # Chạy shellcheck cho toàn bộ scripts
│   └── test-symlinks.sh                # Kiểm tra symlink bị gãy (broken links)
│
└── Makefile                            # Giao diện điều khiển thuận tiện (make install, make test)
```

---

## 3. CƠ CHẾ BẬT / TẮT MODULE VÀ ĐỒNG BỘ NGUYÊN TỬ

### Cách thức áp dụng một module:
Mỗi thư mục con trong `modules/` là một gói Stow độc lập. Để áp dụng:
```bash
cd dotfiles/modules
stow -v -R -t "$HOME" shell hyprland terminal git
```
- `-v`: Hiển thị chi tiết hành động.
- `-R`: Restow (gỡ liên kết cũ và liên kết lại mới nhất).
- `-t "$HOME"`: Thư mục đích.

### Cách gỡ bỏ một module:
```bash
stow -D -t "$HOME" hyprland
```
Lệnh trên sẽ xóa sạch các liên kết mềm mà không chạm vào các module khác.

---

## 4. XỬ LÝ CẤU HÌNH THEO TỪNG MÁY (HOST-SPECIFIC CONFIGURATION)

Để giải quyết bài toán đa thiết bị mà không làm phình to code:
1. **Liên kết Profile Phần cứng Hiện tại**:
   Thư mục `hardware/current-host.conf` là một symlink trỏ vào cấu hình tương ứng trong `hardware/profiles/`.
   Khi bootstrap máy mới, script hỏi tên máy hoặc tự động nhận diện CPU/Motherboard qua `/sys/class/dmi/id/product_name` và tạo symlink thích hợp.
2. **Native Include trong Cấu hình Ứng dụng**:
   - **Trong Shell (`.zshrc`)**:
     ```bash
     [[ -f "$HOME/.config/hardware/current-host.conf" ]] && source "$HOME/.config/hardware/current-host.conf"
     ```
   - **Trong Hyprland (`hyprland.conf`)**:
     ```ini
     # Nạp cấu hình màn hình riêng của máy hiện tại
     source = ~/.config/hypr/hosts/current-monitors.conf
     ```
   - **Trong Git (`~/.config/git/config`)**:
     ```gitconfig
     [include]
         path = ~/.config/git/config.local
     ```

---

## 5. BẢO VỆ TÍNH TOÀN VẸN VÀ CHỐNG PHÁ HỎNG MÔI TRƯỜNG ĐANG CHẠY

1. **Nguyên tắc "Dry-Run First"**:
   Trước khi chạy Stow trên máy thật, luôn chạy với cờ giả lập:
   ```bash
   stow -n -v -t "$HOME" <module>
   ```
   Nếu có tệp tin trùng lặp vốn có từ trước trong `$HOME`, Stow sẽ báo lỗi xung đột và từ chối ghi đè.
2. **Sao lưu Tự động (Backup on Conflict)**:
   Script bootstrap sẽ phát hiện các tệp tin thường (regular files) không phải symlink đang nằm cản đường, tự động di chuyển chúng vào `$HOME/.dotfiles-backup/<timestamp>/` trước khi tạo liên kết mới.
3. **Tuyệt đối không dùng `sed -i` trên symlink**:
   Các script sinh màu động hay trạng thái phải ghi vào `$XDG_STATE_HOME/theme.conf` và để ứng dụng `source` tệp đó, bảo vệ tính bất biến của kho mã nguồn Git.
