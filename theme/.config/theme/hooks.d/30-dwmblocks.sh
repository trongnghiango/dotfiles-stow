#!/usr/bin/env bash
# Hook 30: Trigger DWMBlocks refresh tất cả modules
# Một số modules đọc màu từ Xresources lúc render — signal buộc chúng refresh

# SIGUSR1 = signal toàn bộ dwmblocks refresh tất cả modules in-process
pkill -USR1 -x dwmblocks 2>/dev/null || true
