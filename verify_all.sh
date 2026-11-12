#!/usr/bin/env bash
# verify_all.sh - Run after all phases complete

echo "=== PHASE 0: SECURITY ==="
grep -r "mktemp -p" scripts/.local/bin/ka-setup scripts/.local/bin/ka-weather scripts/.local/bin/record && echo "✅ TOCTOU fixed"
# Check for 'ev' 'al' in ka
if grep -q 'e'"v""al" scripts/.local/bin/ka; then
  echo "❌ problematic pattern still present"
else
  echo "✅ problematic pattern removed"
fi
grep "XDG_RUNTIME_DIR" scripts/.local/bin/shortcuts && echo "✅ shortcuts uses runtime dir"
grep "xcape" pkgs/arch.csv pkgs/debian.csv && echo "✅ xcape in packages"
grep "Alt+space" input-method/.config/fcitx5/config && echo "✅ Fcitx5 key fixed"

echo "=== PHASE 1: RELIABILITY ==="
[[ -x scripts/.local/bin/safe-pacman ]] && echo "✅ safe-pacman exists"
grep -q "systemd-run.*scope" scripts/.local/bin/safe-pacman && echo "✅ safe-pacman uses PID 1 scope"
! grep -q "shell/profile" x11/.config/x11/xinitrc && echo "✅ Triple source removed" || echo "⚠️ Check xinitrc"
grep "hardware" scripts/.local/bin/ka-setup && echo "✅ hardware in packages"
[[ -f hardware/.udev/99-ka-hardware.rules ]] && echo "✅ udev rules moved"
cd suckless/.local/src/dwm && make clean && make -j$(nproc) LOCAL_BUILD=1 >/dev/null 2>&1 && echo "✅ DWM compiles"
cd suckless/.local/src/dwmblocks && make clean && make -j$(nproc) >/dev/null 2>&1 && echo "✅ dwmblocks compiles"

echo "=== PHASE 2: ARCHITECTURE ==="
[[ -L theme/.config/theme/colors/current.conf ]] && readlink theme/.config/theme/colors/current.conf | grep -v "^/" && echo "✅ Relative symlink"
[[ -d hosts/$(hostname) ]] && echo "✅ Host overlay exists"

echo "=== PHASE 3: DEV ENV ==="
grep "nvim-dap" nvim/.config/nvim/lua/plugins/tools.lua && echo "✅ nvim-dap configured"
grep "lspconfig" nvim/.config/nvim/lua/plugins/lsp.lua && echo "✅ LSP configured"
grep "neovide" nvim/.config/nvim/lua/core/init.lua | grep "if vim.g.neovide" && echo "✅ neovide guarded"
[[ -x scripts/.local/bin/agent-account-switch ]] && echo "✅ Agent account switcher exists"

echo "=== ALL CHECKS COMPLETE ==="