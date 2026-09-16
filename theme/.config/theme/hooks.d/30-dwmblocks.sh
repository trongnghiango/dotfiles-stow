#!/usr/bin/env bash
# Hook 30: Trigger DWMBlocks refresh tất cả modules
# Một số modules đọc màu từ Xresources lúc render — signal buộc chúng refresh

dwmblocks_pid=$(pidof dwmblocks 2>/dev/null || true)
if [ -n "$dwmblocks_pid" ]; then
    # RTMIN+1 = signal toàn bộ dwmblocks refresh (clock + tất cả modules)
    pkill -RTMIN+1 dwmblocks 2>/dev/null || true
fi
