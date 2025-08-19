#!/usr/bin/env bash
#
# CHẠY SCRIPT NÀY TỪ BÊN TRONG THƯ MỤC NÀY.
# Nó sẽ tự động dọn dẹp các symlink cũ và tạo lại các symlink mới
# từ các script trong thư mục con.

# Di chuyển đến thư mục chứa script này để các đường dẫn tương đối hoạt động
cd "$(dirname "$0")"

echo "Đang dọn dẹp các symlink cũ..."
# Tìm và xóa tất cả symlink ở cấp thư mục hiện tại
find . -maxdepth 1 -type l -delete

echo "Đang tạo các symlink mới..."
# Liệt kê các thư mục con chứa script của bạn ở đây
for dir in cron scripts statusbar; do
    # Tìm tất cả các file có thể thực thi trong mỗi thư mục con
    find "$dir" -type f -executable | while read -r script_path; do
        script_name=$(basename "$script_path")
        # Tạo symlink ở thư mục hiện tại, trỏ đến script gốc
        ln -s "$script_path" "$script_name"
        echo "  -> Đã tạo link cho $script_name"
    done
done

echo "Hoàn tất."
