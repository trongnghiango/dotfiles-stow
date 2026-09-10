#!/usr/bin/env bash
# ==============================================================================
# Hook 40: Đồng bộ Dark/Light và GTK theme sang GSettings (D-Bus) và GTK settings.ini
# Cho phép Brave, Antigravity và các ứng dụng GUI tự động nhận diện theme hệ thống
# mà không cần force cờ cứng.
# ==============================================================================
set -euo pipefail

CURRENT_LINK="${XDG_CONFIG_HOME:-$HOME/.config}/theme/colors/current.conf"
if [ -f "$CURRENT_LINK" ]; then
    # shellcheck disable=SC1090
    source "$CURRENT_LINK"
fi

# 1. Tự động xác định Dark hay Light từ $MODE hoặc qua độ sáng màu nền $BG
if [ -z "${MODE:-}" ] && [ -n "${BG:-}" ]; then
    r=$((16#${BG:0:2}))
    g=$((16#${BG:2:2}))
    b=$((16#${BG:4:2}))
    luma=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
    if [ "$luma" -lt 128 ]; then
        THEME_MODE="dark"
    else
        THEME_MODE="light"
    fi
else
    THEME_MODE="${MODE:-dark}"
fi

if [ "$THEME_MODE" = "dark" ]; then
    COLOR_SCHEME="prefer-dark"
    GTK_PREFER_DARK="1"
else
    COLOR_SCHEME="prefer-light"
    GTK_PREFER_DARK="0"
fi

# 2. Bắn tín hiệu D-Bus qua GSettings -> Brave và Antigravity lập tức đổi màu
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme "$COLOR_SCHEME" 2>/dev/null || true
    if [ -n "${GTK_THEME:-}" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    fi
fi

# 3. Đồng bộ vào cấu hình file GTK-3.0 và GTK-4.0 settings.ini
for gtk_ini in "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" \
               "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"; do
    if [ -f "$gtk_ini" ]; then
        if grep -q "gtk-application-prefer-dark-theme" "$gtk_ini"; then
            sed -i "s/gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$GTK_PREFER_DARK/" "$gtk_ini"
        else
            sed -i "/\[Settings\]/a gtk-application-prefer-dark-theme=$GTK_PREFER_DARK" "$gtk_ini"
        fi

        if [ -n "${GTK_THEME:-}" ]; then
            if grep -q "gtk-theme-name" "$gtk_ini"; then
                sed -i "s/gtk-theme-name=.*/gtk-theme-name=$GTK_THEME/" "$gtk_ini"
            else
                sed -i "/\[Settings\]/a gtk-theme-name=$GTK_THEME" "$gtk_ini"
            fi
        fi
    fi
done

# 4. Reload xsettingsd nếu đang chạy
xsettingsd_pid=$(pidof xsettingsd 2>/dev/null || true)
if [ -n "$xsettingsd_pid" ]; then
    kill -HUP "$xsettingsd_pid" 2>/dev/null || true
fi
