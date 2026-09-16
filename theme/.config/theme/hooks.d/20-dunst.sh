#!/usr/bin/env bash
# Hook 20: Restart dunst để nhận màu mới từ dunstrc managed block

pkill -x dunst 2>/dev/null || true
sleep 0.1
# Restart dunst in background, tách khỏi terminal
setsid -f dunst >/dev/null 2>&1 &
