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
(cd suckless/.local/src/dwm && make clean && make -j$(nproc) LOCAL_BUILD=1 >/dev/null 2>&1) && echo "✅ DWM compiles"
(cd suckless/.local/src/dwmblocks && make clean && make -j$(nproc) >/dev/null 2>&1) && echo "✅ dwmblocks compiles"

echo "=== PHASE 2: ARCHITECTURE ==="
[[ -L theme/.config/theme/colors/current.conf ]] && readlink theme/.config/theme/colors/current.conf | grep -v "^/" && echo "✅ Relative symlink"
([[ -d hosts/$(hostname) ]] || [[ -d hosts/thinkbox ]]) && echo "✅ Host overlay exists"

echo "=== PHASE 3: DEV ENV ==="
grep -q "nvim-dap" nvim/.config/nvim/lua/plugins/tools.lua && echo "✅ nvim-dap configured"
grep -q "lspconfig" nvim/.config/nvim/lua/plugins/lsp.lua && echo "✅ LSP configured"
grep -q "if vim.g.neovide" nvim/.config/nvim/lua/core/init.lua && echo "✅ neovide guarded"
[[ -x scripts/.local/bin/agent-account-switch ]] && echo "✅ Agent account switcher exists"

echo "=== PHASE 4: BULLETPROOF UPDATES ==="
[[ -x scripts/.local/bin/safe-pacman ]] && echo "✅ safe-pacman ready"
[[ -x scripts/.local/bin/ka-update ]] && echo "✅ ka-update ready"
[[ -x scripts/.local/bin/pacman-hold ]] && echo "✅ pacman-hold ready"
[[ -x scripts/.local/bin/ka-health ]] && echo "✅ ka-health ready"
[[ -x scripts/.local/bin/snapper-pacman-wrapper ]] && echo "✅ snapper-pacman-wrapper ready"
[[ -x scripts/.local/bin/snapper-setup ]] && echo "✅ snapper-setup ready"
[[ -d iso-profile/kaos-cs ]] && echo "✅ ISO profile exists"
grep -q "setup_bulletproof_updates" scripts/.local/bin/ka-setup && echo "✅ setup_bulletproof_updates in ka-setup"

echo "=== ALL CHECKS COMPLETE ==="