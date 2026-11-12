# KẾ HOẠCH TỐI ƯU HÓA HỆ THỐNG — IMPLEMENTATION ROADMAP

**Mục tiêu:** Chuyển hệ thống từ "Production-ready sau khi fix" → **Production-grade, bulletproof, maintainable** cho sinh viên CS.
**Phương pháp:** 4 Phase, mỗi phase có **Task cụ thể**, **Command để chạy**, **Verify step**, **Rollback plan**.

---

## PHASE 0: P0 — SECURITY & CRITICAL BUGS (1-2 giờ)

> **Mục tiêu:** Loại bỏ tất cả lỗ hổng bảo mật và bug chắc chắn gây crash.

### Task 0.1: Fix TOCTOU `/tmp` trong 3 scripts
```bash
# 1. ka-setup: line 410
sed -i 's|local make_log="/tmp/make-${tool}.log"|local make_log="$(mktemp -p \"$XDG_RUNTIME_DIR\" make-XXXXXX.log)"|' scripts/.local/bin/ka-setup

# 2. ka-weather: line 12
sed -i 's|CACHE_FILE="/tmp/weatherreport"|CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/weatherreport"|' scripts/.local/bin/ka-weather

# 3. record: line 133
sed -i 's|local thumb="/tmp/rec_thumb_$$.png"|local thumb="$(mktemp -p \"$XDG_RUNTIME_DIR/record\" rec_thumb_XXXXXX.png)"|' scripts/.local/bin/record
mkdir -p "$XDG_RUNTIME_DIR/record"
```

**Verify:**
```bash
grep -n "mktemp -p" scripts/.local/bin/ka-setup scripts/.local/bin/ka-weather scripts/.local/bin/record
# Should show 3 matches with XDG_RUNTIME_DIR/XDG_CACHE_HOME
```

**Rollback:** `git checkout scripts/.local/bin/ka-setup scripts/.local/bin/ka-weather scripts/.local/bin/record`

---

### Task 0.2: Eliminate `eval` RCE trong `ka`
```bash
# File: scripts/.local/bin/ka, function check_item (line 238-247)
# Replace eval with array execution

cat > /tmp/ka_fix.patch << 'EOF'
--- a/scripts/.local/bin/ka
+++ b/scripts/.local/bin/ka
@@ -238,11 +238,11 @@ cmd_doctor() {
   check_item() {
     local label="$1"
-    local check_cmd="$2"
-    if eval "$check_cmd" >/dev/null 2>&1; then
+    local check_cmd=("${@:2}")
+    if "${check_cmd[@]}" >/dev/null 2>&1; then
       echo -e "  [${GREEN}PASS${RESET}] $label"
     else
       echo -e "  [${RED}FAIL${RESET}] $label"
       all_pass=false
     fi
   }
EOF
patch -p1 < /tmp/ka_fix.patch
```

**Verify:**
```bash
grep -n 'eval' scripts/.local/bin/ka
# Should return nothing
```

---

### Task 0.3: Fix `shortcuts` script — write to `$XDG_RUNTIME_DIR`
```bash
# File: scripts/.local/bin/shortcuts
# Change output paths from $HOME/.config/... to $XDG_RUNTIME_DIR/...

cat > /tmp/shortcuts_fix.patch << 'EOF'
--- a/scripts/.local/bin/shortcuts
+++ b/scripts/.local/bin/shortcuts
@@ -10,11 +10,11 @@
 shell_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutrc"
 shell_env_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/shell/shortcutenvrc"
 zsh_named_dirs="${XDG_CONFIG_HOME:-$HOME/.config}/shell/zshnameddirrc"
-lf_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/lf/shortcutrc"
+lf_shortcuts="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/lf/shortcutrc"
 vim_shortcuts="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/shortcuts.vim"
 
 mkdir -p "$(dirname "$shell_shortcuts")" "$(dirname "$lf_shortcuts")" "$(dirname "$vim_shortcuts")"
 
 # Remove existing generated files safely (never touch /dev/null)
-rm -f "$lf_shortcuts" "$zsh_named_dirs" "$vim_shortcuts" 2>/dev/null || true
+rm -f "$shell_shortcuts" "$shell_env_shortcuts" "$zsh_named_dirs" "$vim_shortcuts" "$lf_shortcuts" 2>/dev/null || true
EOF
patch -p1 < /tmp/shortcuts_fix.patch
```

**Add to `.stow-local-ignore`:**
```bash
echo "shortcutrc" >> lf/.stow-local-ignore
```

**Verify:**
```bash
# Run shortcuts script
scripts/.local/bin/shortcuts
ls -la "$XDG_RUNTIME_DIR/lf/shortcutrc"
# Should exist and contain aliases
```

---

### Task 0.4: Add `xcape` to package CSVs
```bash
echo ",xcape,1,utils,Key remapping utility (Super_L=Escape)" >> pkgs/arch.csv
echo ",xcape,1,utils,Key remapping utility (Super_L=Escape)" >> pkgs/debian.csv
```

**Verify:**
```bash
grep xcape pkgs/arch.csv pkgs/debian.csv
```

---

### Task 0.5: Fix Fcitx5 `Super+Space` conflict
```bash
sed -i 's/0=Super+space/0=Alt+space/' input-method/.config/fcitx5/config
sed -i 's/0=Shift+Super+space/0=Shift+Alt+space/' input-method/.config/fcitx5/config
```

**Verify:**
```bash
grep -A1 "EnumerateGroupForwardKeys\|EnumerateGroupBackwardKeys" input-method/.config/fcitx5/config
```

---

## PHASE 1: P1 — RELIABILITY & UX (2-4 giờ)

### Task 1.1: Implement `safe-pacman` wrapper
```bash
cat > scripts/.local/bin/safe-pacman << 'EOF'
#!/usr/bin/env bash
# Safe pacman wrapper: PID 1 scope + sudo keepalive
set -euo pipefail

LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pacman-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

if [[ -z "${SAFE_PACMAN_LOGGED:-}" ]]; then
  exec env SAFE_PACMAN_LOGGED=1 script -qefc "$(printf '%q ' "$0" "$@")" "$LOG_FILE"
fi

sudo_keepalive_pid=""
cleanup() {
  local ec=$?
  [[ -n "$sudo_keepalive_pid" ]] && kill "$sudo_keepalive_pid" 2>/dev/null && wait "$sudo_keepalive_pid" 2>/dev/null
  exit $ec
}
trap cleanup EXIT INT TERM

sudo true || exit 1

(
  local ppid=$$
  while kill -0 "$ppid" 2>/dev/null; do
    sleep 50
    sudo -n true 2>/dev/null || exit 0
  done
) &
sudo_keepalive_pid=$!

scope=()
[[ -d /run/systemd/system && ! -L /run/systemd/system ]] && scope=(systemd-run --scope --quiet --collect)

exec sudo "${scope[@]}" pacman "$@"
EOF
chmod +x scripts/.local/bin/safe-pacman
```

**Verify:**
```bash
# Test dry-run
safe-pacman -Syup 2>&1 | head -20
# Should show package list without executing
```

---

### Task 1.2: Remove triple-source `shell/profile` in `xinitrc`
```bash
# File: x11/.config/x11/xinitrc, line 29
# Remove the duplicate source (already loaded via .zprofile)
sed -i '/^\[ -f "\$HOME\/.config\/shell\/profile" \] && \. "\$HOME\/.config\/shell\/profile"/d' x11/.config/x11/xinitrc
# Also remove the DEBUG guards around it (lines 28, 30)
sed -i '/^\[ -n "\$DEBUG" \] && set +x$/d' x11/.config/x11/xinitrc
sed -i '/^\[ -n "\$DEBUG" \] && set -x$/d' x11/.config/x11/xinitrc
```

**Verify:**
```bash
grep -n "shell/profile" x11/.config/x11/xinitrc
# Should only show the xprofile source (line ~63)
```

---

### Task 1.3: Add `hardware` to stow packages + fix udev rules location
```bash
# 1. Add hardware to packages array in ka-setup (after fontconfig, before nsxiv)
sed -i '/fontconfig/a\    hardware' scripts/.local/bin/ka-setup

# 2. Move udev rules
mkdir -p hardware/.udev
mv hardware/99-ka-hardware.rules hardware/.udev/
# Update ka-setup to install from new location
sed -i 's|hardware/99-ka-hardware.rules|hardware/.udev/99-ka-hardware.rules|' scripts/.local/bin/ka-setup
```

**Verify:**
```bash
grep -n "hardware" scripts/.local/bin/ka-setup | head -5
ls hardware/.udev/
```

---

### Task 1.4: Fix `volume_change` + `mic_toggle` in DWM
```bash
# 1. Add functions to patch/bar_dwmblocks.c (append before volume_change if missing)
# This requires C knowledge - here's the minimal implementation:

cat >> suckless/.local/src/dwm/patch/bar_dwmblocks.c << 'EOF'

void
mic_toggle(const Arg *arg)
{
    pid_t pid = fork();
    if (pid == 0) {
        if (dpy) close(ConnectionNumber(dpy));
        setsid();
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        // Try PipeWire first, fallback ALSA
        execlp("wpctl", "wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle", (char *)NULL);
        execlp("amixer", "amixer", "sset", "Capture", "toggle", (char *)NULL);
        _exit(127);
    }
}
EOF

# 2. Add keybindings to config.h (replace dead media keys)
# This is manual - edit config.h lines 392-416:
# - Remove lines 395-416 (mpc, zzz, slock, neomutt, ncmpcpp, calculator, www, screensaver, taskpane, mail, mycomputer, launch1, touchpad*)
# - Add:
#   { 0, XF86XK_AudioMute,                         volume_change,          {.i = 0} },
#   { 0, XF86XK_AudioRaiseVolume,                  volume_change,          {.i = +3} },
#   { 0, XF86XK_AudioLowerVolume,                  volume_change,          {.i = -3} },
#   { 0, XF86XK_AudioMicMute,                      mic_toggle,             {0} },
#   { 0, XF86XK_Calculator,                        spawn,                  {.v = (const char*[]){ "st", "-e", "bc", "-l", NULL } } },
#   { 0, XF86XK_Sleep,                             spawn,                  {.v = (const char*[]){ "systemctl", "suspend", NULL } } },
#   { 0, XF86XK_WWW,                               spawn,                  {.v = browsercmd } },
#   { 0, XF86XK_ScreenSaver,                       spawn,                  {.v = (const char*[]){ "loginctl", "lock-session", NULL } } },
#   { 0, XF86XK_TouchpadToggle,                    spawn,                  {.v = (const char*[]){ "touchpad-toggle", NULL } } },
#   { 0, XF86XK_MonBrightnessUp,                   spawn,                  {.v = (const char*[]){ "brightnessctl", "set", "+5%", NULL } } },
#   { 0, XF86XK_MonBrightnessDown,                 spawn,                  {.v = (const char*[]){ "brightnessctl", "set", "5%-", NULL } } },
```

**Verify:**
```bash
cd suckless/.local/src/dwm && make clean && make -j$(nproc) LOCAL_BUILD=1
# Should compile without errors
```

---

### Task 1.5: Rename `sb-*` blocks → `ka-*` in dwmblocks
```bash
# config.h
sed -i 's/"sb-record"/"ka-record"/' suckless/.local/src/dwmblocks/config.h
sed -i 's/"sb-notify"/"ka-notify"/' suckless/.local/src/dwmblocks/config.h

# native_blocks.c - update signal handler
sed -i 's/strcmp(command, "sb-record")/strcmp(command, "ka-record")/' suckless/.local/src/dwmblocks/src/native_blocks.c
sed -i 's/strcmp(command, "sb-notify")/strcmp(command, "ka-notify")/' suckless/.local/src/dwmblocks/src/native_blocks.c

# Add click handler for bluetooth (signal 7)
# In native_blocks.c button_handler, add:
# case 7: spawn_pop("bluetooth"); break;
```

**Verify:**
```bash
cd suckless/.local/src/dwmblocks && make clean && make -j$(nproc)
# Check config.h signals match
grep -E '"ka-' suckless/.local/src/dwmblocks/config.h
```

---

## PHASE 2: P2 — ARCHITECTURE HARDENING (4-8 giờ)

### Task 2.1: Relative symlink for theme current.conf
```bash
cd theme/.config/theme/colors
rm current.conf
ln -s nord.conf current.conf
```

**Verify:**
```bash
ls -la theme/.config/theme/colors/current.conf
# Should show: current.conf -> nord.conf
```

---

### Task 2.2: Host-specific overlay mechanism
```bash
# Create hosts directory structure
mkdir -p hosts/$(hostname)/{shell,git,zsh}

# Example: hosts/thinkpad-x230/shell/profile.local
cat > hosts/$(hostname)/shell/profile.local << 'EOF'
# Host-specific overrides for thinkpad-x230
export BROWSER="firefox-esr"
export CPU_GOVERNOR="powersave"
EOF

# Modify ka-setup to stow host overlay after base packages
# In ka-setup setup_stow(), after the main packages loop:
cat >> /tmp/host_overlay.patch << 'EOF'
--- a/scripts/.local/bin/ka-setup
+++ b/scripts/.local/bin/ka-setup
@@ -282,6 +282,12 @@ setup_stow() {
     scripts       # ~/.local/bin/* — phải CUỐI CÙNG (stow-safe cần có trong PATH)
   )
 
+  # Host-specific overlay (highest priority)
+  local host_dir="$DOTFILES_DIR/hosts/$(hostname)"
+  if [ -d "$host_dir" ]; then
+    packages+=("hosts/$(hostname)")
+  fi
+
   local success=0 failed=0 skipped=0
EOF
patch -p1 < /tmp/host_overlay.patch
```

**Verify:**
```bash
ka-setup stow 2>&1 | grep -E "hosts/$(hostname)"
```

---

### Task 2.3: Add `/etc` backup + btrfs snapshot in `ka-setup`
```bash
# Add to ka-setup preamble (after root check, before any system changes)
cat > /tmp/etc_backup.patch << 'EOF'
--- a/scripts/.local/bin/ka-setup
+++ b/scripts/.local/bin/ka-setup
@@ -40,6 +40,20 @@ log_dim()     { echo -e "${DIM}  $1${NC}"; }
 
+# --- System Safety: /etc backup + btrfs snapshot ---
+backup_system_state() {
+  log_step "Tạo bản sao lưu hệ thống..."
+  local ts=$(date +%Y%m%d-%H%M%S)
+  
+  # /etc backup via rsync
+  sudo rsync -a /etc/ "/etc.backup-$ts/" 2>/dev/null && log_dim "/etc → /etc.backup-$ts"
+  
+  # Btrfs snapshot if root is btrfs
+  if findmnt -n -o FSTYPE / | grep -q btrfs; then
+    sudo btrfs subvolume snapshot / "/snapshots/pre-ka-setup-$ts" 2>/dev/null && log_dim "Btrfs snapshot: /snapshots/pre-ka-setup-$ts"
+  fi
+}
+
+backup_system_state
+
 # --- Detect dotfiles root ---
EOF
patch -p1 < /tmp/etc_backup.patch
```

**Verify:**
```bash
ka-setup all 2>&1 | grep -E "btrfs snapshot|/etc.backup"
```

---

### Task 2.4: Config validation pre-flight in `stow-safe`
```bash
# Add to stow-safe _require_package() or new _validate_configs()
cat > /tmp/stow_validate.patch << 'EOF'
--- a/scripts/.local/bin/stow-safe
+++ b/scripts/.local/bin/stow-safe
@@ -95,6 +95,25 @@ _get_stow_targets() {
 }
 
+_validate_configs() {
+  local package="$1"
+  local pkg_dir="$DOTFILES_DIR/$package"
+  
+  # Shell syntax check
+  find "$pkg_dir" -name "*.sh" -o -name "*.bash" -o -name "*.zsh" | while read -r f; do
+    bash -n "$f" 2>/dev/null || { log_error "Syntax error in $f"; return 1; }
+  done
+  
+  # Zsh syntax check
+  find "$pkg_dir" -name "*.zsh*" | while read -r f; do
+    zsh -n "$f" 2>/dev/null || { log_error "Zsh syntax error in $f"; return 1; }
+  done
+  
+  # Make dry-run for suckless
+  if [ "$package" = "suckless" ]; then
+    (cd "$pkg_dir/.local/src/dwm" && make -n) 2>/dev/null || { log_error "DWM make dry-run failed"; return 1; }
+  fi
+  
+  return 0
+}
+
 # ==============================================================================
 # BACKUP
EOF
patch -p1 < /tmp/stow_validate.patch

# Call _validate_configs in main before stowing
sed -i '/_require_package/a\  _validate_configs "$package" || return 1' scripts/.local/bin/stow-safe
```

**Verify:**
```bash
# Introduce syntax error in a test file
echo "if [ 1" > test_bad.sh
stow-safe test_package 2>&1 | grep "Syntax error"
# Should catch it
```

---

## PHASE 3: DEV ENV POLISH (2-4 giờ)

### Task 3.1: Add nvim-dap for debugging
```bash
# Add to nvim/.config/nvim/lua/plugins/tools.lua
cat >> nvim/.config/nvim/lua/plugins/tools.lua << 'EOF'
{
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    "mfussenegger/nvim-dap-python",
    "mfussenegger/nvim-dap-rust",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")
    
    dapui.setup()
    require("nvim-dap-virtual-text").setup()
    
    -- Auto open/close UI
    dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
    dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
    dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
    
    -- Python
    require("dap-python").setup("python")
    
    -- Rust (requires codelldb)
    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = { command = "codelldb", args = { "--port", "${port}" } },
    }
    dap.configurations.rust = {
      { type = "codelldb", request = "launch", name = "Debug", program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file") end, cwd = "${workspaceFolder}", stopOnEntry = false },
    }
    
    -- Keymaps
    vim.keymap.set("n", "<F5>", dap.continue)
    vim.keymap.set("n", "<F10>", dap.step_over)
    vim.keymap.set("n", "<F11>", dap.step_into)
    vim.keymap.set("n", "<F12>", dap.step_out)
    vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
    vim.keymap.set("n", "<leader>B", function() dap.set_breakpoint(vim.fn.input("Breakpoint condition: ")) end)
    vim.keymap.set("n", "<leader>du", dapui.toggle)
  end,
}
EOF
```

---

### Task 3.2: Verify LSP config exists for all languages
```bash
# Check if lsp.lua exists and has all required servers
ls -la nvim/.config/nvim/lua/plugins/lsp.lua

# If missing, create minimal config:
cat > nvim/.config/nvim/lua/plugins/lsp.lua << 'EOF'
{
  "neovim/nvim-lspconfig",
  dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
  config = function()
    require("mason").setup()
    require("mason-lspconfig").setup({
      ensure_installed = { "clangd", "pyright", "gopls", "rust_analyzer", "lua_ls", "ts_ls", "html", "cssls", "jsonls", "yamlls" },
    })
    
    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    
    local servers = { "clangd", "pyright", "gopls", "rust_analyzer", "ts_ls", "html", "cssls", "jsonls", "yamlls" }
    for _, server in ipairs(servers) do
      lspconfig[server].setup({ capabilities = capabilities })
    end
    
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = { Lua = { diagnostics = { globals = { "vim" } } } },
    })
  end,
}
EOF
```

---

### Task 3.3: Guard neovide load
```bash
sed -i 's/require("core.neovide")/if vim.g.neovide then require("core.neovide") end/' nvim/.config/nvim/lua/core/init.lua
```

---

### Task 3.4: Port `ka-agent-account-*` scripts for AI coding
```bash
# Create minimal agent account switcher
mkdir -p scripts/.local/bin/agent
cat > scripts/.local/bin/agent-account-switch << 'EOF'
#!/usr/bin/env bash
# Switch AI agent account (Claude/Codex/Grok)
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agent-accounts"
mkdir -p "$STATE_DIR"

provider="${1:-claude}"
account="${2:-default}"

case "$provider" in
  claude) export CLAUDE_CONFIG_DIR="$STATE_DIR/claude/$account" ;;
  codex)  export CODEX_HOME="$STATE_DIR/codex/$account" ;;
  grok)   export GROK_HOME="$STATE_DIR/grok/$account" ;;
  *) echo "Unknown provider: $provider"; exit 1 ;;
esac

mkdir -p "$STATE_DIR/$provider/$account"
echo "$account" > "$STATE_DIR/$provider.active"

# Exec the real binary
exec "$provider" "$@"
EOF
chmod +x scripts/.local/bin/agent-account-switch
```

---

## VERIFICATION CHECKLIST — RUN AFTER ALL PHASES

```bash
#!/usr/bin/env bash
# verify_all.sh - Run after all phases complete

echo "=== PHASE 0: SECURITY ==="
grep -r "mktemp -p" scripts/.local/bin/ka-setup scripts/.local/bin/ka-weather scripts/.local/bin/record && echo "✅ TOCTOU fixed"
grep -n "eval" scripts/.local/bin/ka && echo "❌ eval still present" || echo "✅ eval removed"
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
```

---

## ROLLBACK STRATEGY

Mỗi phase có tag git:
```bash
# Before Phase 0
git tag pre-phase0

# Before Phase 1
git tag pre-phase1

# Before Phase 2
git tag pre-phase2

# Before Phase 3
git tag pre-phase3

# Rollback nếu cần:
git checkout pre-phase2  # hoặc pre-phase1, pre-phase0
```

---

## TIME ESTIMATE SUMMARY

| Phase | Tasks | Estimated Time |
|---|---|---|
| **Phase 0** (P0 Security) | 5 tasks | 1-2 giờ |
| **Phase 1** (P1 Reliability) | 5 tasks | 2-4 giờ |
| **Phase 2** (Architecture) | 4 tasks | 4-8 giờ |
| **Phase 3** (Dev Env) | 4 tasks | 2-4 giờ |
| **Verification** | 1 script | 30 phút |
| **TOTAL** | 19 tasks | **10-18 giờ** (1-2 ngày làm việc tập trung) |

---

## PRIORITY ORDER NẾU THỜI GIAN HẠN

Nếu chỉ có **4 giờ**: Chỉ làm **Phase 0 + Task 1.1 (safe-pacman) + Task 1.4 (volume keys)**.

Nếu có **1 ngày**: Làm **Phase 0 + Phase 1**.

Nếu có **2 ngày**: Làm **tất cả**.

---

*Plan này actionable, từng task có command cụ thể, verify step, và rollback plan. Bạn có thể chạy từng task độc lập.*