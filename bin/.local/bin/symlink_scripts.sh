#!/usr/bin/env bash

# Thư mục gốc chứa các script
SRC_DIR="$HOME/dotfiles/bin/.local/bin"

# ĐÍCH đến để tạo symlink bây giờ cũng chính là thư mục gốc đó.
# Script này giờ chỉ có tác dụng tạo các symlink "phẳng" (như backup)
# từ các script nằm trong thư mục con (như personal-scripts/backup.sh)
# tất cả đều bên trong kho dotfiles.
DEST_DIR="$HOME/dotfiles/bin/.local/bin"
# Đích đến là thư mục thật
DEST_DIR="$HOME/.local/bin"

find "$SRC_DIR" -type f -executable | while read -r script_path; do
    script_name=$(basename "${script_path%.sh}")
    dest_path="$DEST_DIR/$script_name"

    if [ ! -L "$dest_path" ]; then
        echo "Creating symlink for: $script_name"
        ln -s "$script_path" "$dest_path"
    fi
done
echo "Done."

