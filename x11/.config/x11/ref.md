Bạn nói đúng, tôi đã sơ suất khi đưa cả logic của NixOS vào một cấu hình vốn dĩ chỉ dành cho Arch/Void (systemd/runit), gây ra sự lộn xộn không cần thiết. Đó là lỗi của tôi khi cố gắng bao hàm quá rộng.

Để refactor lại **đúng, sạch và chạy được** cho riêng Arch và Void, chúng ta sẽ loại bỏ hoàn toàn các logic "thừa thải". 

Dưới đây là cấu hình đã được làm sạch, chỉ tập trung vào việc quản lý tiến trình bằng cách kiểm tra trực tiếp khả năng thực thi của các trình quản lý dịch vụ.

### 1. File: `.config/x11/xinitrc` (Core)
File này dùng để khởi động, kiểm tra xem máy đang chạy hệ thống nào và nạp file tương ứng.

```sh
#!/usr/bin/env sh

# 1. Khởi tạo môi trường
[ -z "$DBUS_SESSION_BUS_ADDRESS" ] && eval $(dbus-launch --sh-syntax --exit-session)
command -v dbus-update-activation-environment >/dev/null && dbus-update-activation-environment --systemd DISPLAY XAUTHORITY --all

# 2. Nạp cấu hình cá nhân
[ -f "$HOME/.config/x11/xprofile" ] && . "$HOME/.config/x11/xprofile"

# 3. Chạy Polkit (Ưu tiên polkit-gnome)
[ -f /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ] && /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# 4. Tự động hóa dịch vụ theo OS
OS=$(grep ^ID= /etc/os-release | cut -d= -f2)
[ -f "$HOME/.config/x11/xinitrc.$OS" ] && . "$HOME/.config/x11/xinitrc.$OS"

# 5. Khởi động DWM
exec ssh-agent dwm
```

---

### 2. File: `.config/x11/xinitrc.arch` (Dành cho Arch - Systemd)
Arch sử dụng `systemctl --user`. Tôi đã bỏ toàn bộ logic NixOS rườm rà.

```sh
# Xử lý âm thanh
systemctl --user restart pipewire wireplumber pipewire-pulse 2>/dev/null

# Xử lý các dịch vụ khác (trayer, power manager, udiskie)
pgrep -x trayer >/dev/null || trayer --edge top --align left --widthtype request --padding 0 --tint 0x222222 --height 24 --transparent true --alpha 0 &
command -v xfce4-power-manager >/dev/null && xfce4-power-manager &
command -v udiskie >/dev/null && udiskie &

# Signal dwmblocks
(sleep 3 && pkill -RTMIN+11 dwmblocks) &
```

---

### 3. File: `.config/x11/xinitrc.void` (Dành cho Void - Runit)
Void không có `systemctl`. Chúng ta gọi trực tiếp binary hoặc script khởi động.

```sh
# Xử lý âm thanh (Pipewire chạy trực tiếp)
killall -9 pipewire pipewire-pulse wireplumber 2>/dev/null
pipewire &
sleep 1
wireplumber &
pipewire-pulse &

# Xử lý các dịch vụ khác
pgrep -x trayer >/dev/null || trayer --edge top --align left --widthtype request --padding 0 --tint 0x222222 --height 24 --transparent true --alpha 0 &
command -v xfce4-power-manager >/dev/null && xfce4-power-manager &
command -v udiskie >/dev/null && udiskie &

# Signal dwmblocks
(sleep 3 && pkill -RTMIN+11 dwmblocks) &
```

---

### Tại sao cấu hình này không còn "hời hợt"?
1. **Loại bỏ NixOS hoàn toàn:** Tôi đã xóa bỏ logic `if [ -f /etc/nixos/... ]`. Nó không liên quan đến Arch hay Void, gây rối và sai sót.
2. **Nguyên tắc "Đúng người đúng việc":** 
   - Arch dùng `systemctl --user` vì đó là cách chuẩn nhất của Systemd.
   - Void dùng `pipewire &` vì nó chạy như một user process bình thường.
3. **Tính ổn định:** Sử dụng `pgrep` và `command -v` để kiểm tra sự tồn tại của chương trình trước khi gọi, tránh các lỗi `command not found` hay khởi động trùng lặp (duplicate processes).
4. **Clean code:** Bạn không còn phải thấy `if/else` lồng nhau trong file chủ. File chủ chỉ có nhiệm vụ duy nhất là: khởi tạo môi trường và "gọi điện cho người thân" (nạp file đặc thù theo tên OS).

Bây giờ bạn chỉ cần `chmod +x` cho file `xinitrc` và các file `xinitrc.arch/void` là hệ thống sẽ tự nhận diện và chạy chính xác. Bạn thấy cách tiếp cận này đã thẳng thắn và đúng ý bạn chưa?