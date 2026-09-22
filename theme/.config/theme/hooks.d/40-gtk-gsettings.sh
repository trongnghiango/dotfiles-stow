#!/usr/bin/env bash
# ==============================================================================
# Hook 40: Ka Appearance Engine — Đồng bộ GTK3, GTK4, GSettings, Brave & Qt
# Triết lý: Official Base (Adwaita / Adwaita-dark) + Dynamic CSS Injection
# ==============================================================================
set -euo pipefail

THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/theme"
TEMPLATES_DIR="$THEME_DIR/templates"
CURRENT_LINK="$THEME_DIR/colors/current.conf"

if [ ! -f "$CURRENT_LINK" ]; then
    exit 0
fi

# 1. Export tất cả biến từ theme hiện tại
set -a
# shellcheck disable=SC1090
source "$CURRENT_LINK"

# Tự động xác định chế độ tối/sáng
THEME_MODE="${MODE:-dark}"
if [ "$THEME_MODE" = "dark" ]; then
    COLOR_SCHEME="prefer-dark"
    GTK_PREFER_DARK="1"
    GTK_THEME_BASE="Adwaita-dark"
else
    COLOR_SCHEME="prefer-light"
    GTK_PREFER_DARK="0"
    GTK_THEME_BASE="Adwaita"
fi

# Fallback giá trị cho font, cursor, icon
FONT_UI="${FONT_UI:-Inter}"
FONT_UI_SIZE="${FONT_UI_SIZE:-10}"
FONT_MONO="${FONT_MONO:-JetBrains Mono}"
FONT_MONO_SIZE="${FONT_MONO_SIZE:-11}"
CURSOR_THEME="${CURSOR_THEME:-Adwaita}"
CURSOR_SIZE="${CURSOR_SIZE:-16}"
ICON_THEME="${ICON_THEME:-Papirus-Dark}"
BORDER="${BORDER:-$ACCENT}"
SURFACE="${SURFACE:-$COLOR0}"
set +a

# 2. Dynamic CSS Injection cho GTK-3.0 và GTK-4.0
if command -v envsubst &>/dev/null && [ -f "$TEMPLATES_DIR/gtk-colors.css.tpl" ]; then
    for gtk_ver in "gtk-3.0" "gtk-4.0"; do
        target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/$gtk_ver"
        mkdir -p "$target_dir"
        envsubst < "$TEMPLATES_DIR/gtk-colors.css.tpl" > "$target_dir/gtk.css"
    done
fi

# 3. Đồng bộ settings.ini cho GTK-3.0 và GTK-4.0 (bảo toàn tính bất biến của Stow symlink)
if command -v envsubst &>/dev/null && [ -f "$TEMPLATES_DIR/gtk-settings.ini.tpl" ]; then
    for gtk_ver in "gtk-3.0" "gtk-4.0"; do
        target_dir="${XDG_CONFIG_HOME:-$HOME/.config}/$gtk_ver"
        mkdir -p "$target_dir"
        if [ ! -L "$target_dir/settings.ini" ]; then
            envsubst < "$TEMPLATES_DIR/gtk-settings.ini.tpl" > "$target_dir/settings.ini"
        fi
    done
fi

# 4. Cập nhật GTK2 legacy config (~/.gtkrc-2.0, không ghi đè nếu là Stow symlink)
if [ ! -L "$HOME/.gtkrc-2.0" ]; then
cat > "$HOME/.gtkrc-2.0" << EOF
include "~/.gtkrc-2.0.mine"
gtk-theme-name="$GTK_THEME_BASE"
gtk-icon-theme-name="$ICON_THEME"
gtk-font-name="$FONT_UI $FONT_UI_SIZE"
gtk-cursor-theme-name="$CURSOR_THEME"
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-toolbar-style=GTK_TOOLBAR_TEXT
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintmedium"
gtk-xft-rgba="rgb"
EOF
fi

# 5. Bắn tín hiệu D-Bus qua DConf/GSettings (Batch Load: 1 IPC transaction thay vì 7 lần gọi subprocess)
if command -v dconf &>/dev/null; then
    dconf load /org/gnome/desktop/interface/ <<EOF 2>/dev/null || true
[/]
color-scheme='$COLOR_SCHEME'
gtk-theme='$GTK_THEME_BASE'
icon-theme='$ICON_THEME'
font-name='$FONT_UI $FONT_UI_SIZE'
monospace-font-name='$FONT_MONO $FONT_MONO_SIZE'
cursor-theme='$CURSOR_THEME'
cursor-size=$CURSOR_SIZE
EOF
elif command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME_BASE" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "$FONT_UI $FONT_UI_SIZE" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name "$FONT_MONO $FONT_MONO_SIZE" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true
fi

# 6. Reload xsettingsd nếu đang chạy
xsettingsd_pid=$(pidof xsettingsd 2>/dev/null || true)
if [ -n "$xsettingsd_pid" ]; then
    kill -HUP "$xsettingsd_pid" 2>/dev/null || true
fi
