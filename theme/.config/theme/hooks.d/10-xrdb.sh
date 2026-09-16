#!/usr/bin/env bash
# Hook 10: Merge Xresources vào X server + reload DWM màu sắc
#
# Luồng:
#   xrdb -merge xresources  →  load xresources chính (font, alpha, include colors)
#   xrdb -merge colors      →  override với màu mới (phòng khi include không hoạt động)
#   kill -HUP dwm           →  DWM gọi lại loadxrdb() qua restartsig patch → reload màu
#                              mà KHÔNG restart session (cửa sổ vẫn còn nguyên)

XRESOURCES="${XDG_CONFIG_HOME:-$HOME/.config}/x11/xresources"
XRES_COLORS="${XDG_CONFIG_HOME:-$HOME/.config}/x11/xresources.d/colors"

# Merge xresources chính (font, alpha + #include colors)
[ -f "$XRESOURCES" ] && xrdb -merge "$XRESOURCES" 2>/dev/null

# Merge riêng colors file để đảm bảo màu mới được load
[ -f "$XRES_COLORS" ] && xrdb -merge "$XRES_COLORS" 2>/dev/null

# Reload DWM qua SIGHUP (patch/restartsig.c: sighup → quit({.i=1}) → restart với exec)
# DWM sẽ gọi loadxrdb() khi khởi động lại, đọc màu mới từ X resource database
dwm_pid=$(pidof dwm 2>/dev/null || true)
if [ -n "$dwm_pid" ]; then
    kill -HUP "$dwm_pid"
fi
