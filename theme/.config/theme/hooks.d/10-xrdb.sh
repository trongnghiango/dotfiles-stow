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

# Bắn tín hiệu SIGHUP để DWM reload xrdb in-process (<1ms, 0 flicker, không restart session)
pkill -HUP -x dwm 2>/dev/null || true
