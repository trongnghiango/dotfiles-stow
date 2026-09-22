#!/usr/bin/env bash
# Hook 30: Trigger DWMBlocks refresh tất cả modules
# Một số modules đọc màu từ Xresources lúc render — signal buộc chúng refresh

# RTMIN+1 = signal toàn bộ dwmblocks refresh (clock + tất cả modules)
pkill -RTMIN+1 -x dwmblocks 2>/dev/null || true
