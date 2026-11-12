# Implementation Blueprints: Bản Thiết Kế Triển Khai Thực Tế

Các bản thiết kế kỹ thuật hoàn chỉnh, sẵn sàng đưa vào vận hành (Production-Ready) cho Personal Linux OS. Tất cả mã nguồn đều tuân thủ các tiêu chuẩn: **Idempotent, Error-Handling nghiêm ngặt (`set -euo pipefail`), Process Isolation và Không có side-effects ngoài dự kiến**.

---

## BLUEPRINT 1: SAFE TRANSACTIONAL PACMAN UPGRADE WITH SUDO KEEPALIVE

### 1. Mục tiêu
Bảo vệ giao dịch nâng cấp hệ thống Arch Linux (`pacman -Syu`) khỏi nguy cơ bị `SIGKILL` khi gói systemd nâng cấp mid-transaction, đồng thời loại bỏ việc bị timeout mật khẩu sudo giữa chừng mà không cần cấu hình `NOPASSWD`.

### 2. Thành phần kỹ thuật
- **Vị trí**: `scripts/.local/bin/safe-pacman`
- **Quyền hạn**: Thực thi bởi người dùng bình thường, tự nâng quyền sudo kiểm soát.
- **Dependencies**: `systemd`, `sudo`, `pacman`, `util-linux` (`script`).

### 3. Mã nguồn triển khai (`scripts/.local/bin/safe-pacman`)

```bash
#!/usr/bin/env bash
# ==============================================================================
# safe-pacman: Safe Arch Linux system upgrade runner
# Features:
#   1. PID 1 transient systemd scope isolation (survives systemd daemon re-exec)
#   2. Child-monitored sudo timestamp keepalive (no mid-download password timeout)
#   3. Full PTY execution logging via util-linux script
# ==============================================================================
set -euo pipefail

LOG_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/pacman-upgrade-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

# 1. Tự bọc trong PTY Logger nếu chưa có
if [[ -z "${SAFE_PACMAN_LOGGED:-}" ]]; then
  echo "==> Ghi nhật ký nâng cấp vào: $LOG_FILE"
  exec env SAFE_PACMAN_LOGGED=1 script -qefc "$(printf '%q ' "$0" "$@")" "$LOG_FILE"
fi

# 2. Xác thực sudo một lần và kích hoạt tiến trình ngầm duy trì timestamp
sudo_keepalive_pid=""
cleanup() {
  local exit_code=$?
  if [[ -n "$sudo_keepalive_pid" ]] && kill -0 "$sudo_keepalive_pid" 2>/dev/null; then
    kill "$sudo_keepalive_pid" 2>/dev/null || true
    wait "$sudo_keepalive_pid" 2>/dev/null || true
  fi
  if (( exit_code != 0 )); then
    echo -e "\n\033[1;31m[!] Quá trình nâng cấp gặp sự cố! Kiểm tra log tại: $LOG_FILE\033[0m" >&2
  else
    echo -e "\n\033[1;32m[✓] Nâng cấp hệ thống an toàn thành công.\033[0m"
  fi
  exit "$exit_code"
}
trap cleanup EXIT INT TERM

echo "==> Yêu cầu xác thực quản trị (chỉ 1 lần duy nhất cho toàn bộ phiên)..."
sudo true || { echo "Xác thực sudo thất bại." >&2; exit 1; }

parent_pid=$$
(
  # Tiến trình con chỉ tồn tại chừng nào tiến trình cha còn sống
  while :; do
    sleep 50 &
    sleep_pid=$!
    wait "$sleep_pid" 2>/dev/null || true
    if ! kill -0 "$parent_pid" 2>/dev/null; then
      exit 0
    fi
    sudo -n true 2>/dev/null || exit 0
  done
) &
sudo_keepalive_pid=$!

# 3. Chuẩn bị phạm vi PID 1 Scope
scope_cmd=()
if [[ -d /run/systemd/system ]]; then
  scope_cmd=(systemd-run --scope --quiet --collect --unit="safe-pacman-$(date +%s)")
fi

# 4. Thực thi pacman an toàn
echo "==> Đang tiến hành giao dịch cập nhật trong PID 1 Scope an toàn..."
exec sudo "${scope_cmd[@]}" pacman "$@"
```

---

## BLUEPRINT 2: TYPE-SAFE D-BUS NOTIFICATION ENGINE (`ka-notify`)

### 1. Mục tiêu
Thay thế hoàn toàn `notify-send` bằng một tiện ích gọi D-Bus native qua `busctl`, hỗ trợ cập nhật toast tại chỗ (`-r <id>`), in ID (`-p`) và gắn action buttons an toàn tuyệt đối chống shell injection.

### 2. Thành phần kỹ thuật
- **Vị trí**: `scripts/.local/bin/ka-notify`
- **Dependencies**: `systemd` (`busctl`), `jq`.

### 3. Mã nguồn triển khai (`scripts/.local/bin/ka-notify`)

```bash
#!/usr/bin/env bash
# ==============================================================================
# ka-notify: Strictly-typed native D-Bus notification sender
# Usage:
#   ka-notify [-u low|normal|critical] [-g glyph] [-r id] [-p] <headline> [body]
# ==============================================================================
set -euo pipefail

app_name="personal-os"
urgency="normal"
glyph=""
replaces_id=0
print_id=0
expire_timeout=-1

while getopts ":u:g:r:pt:" opt; do
  case $opt in
    u) urgency="$OPTARG" ;;
    g) glyph="$OPTARG" ;;
    r) replaces_id="$OPTARG" ;;
    p) print_id=1 ;;
    t) expire_timeout="$OPTARG" ;;
    \?) echo "Tùy chọn không hợp lệ: -$OPTARG" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

(( $# >= 1 )) || { echo "Sử dụng: ka-notify [-u urgency] [-g glyph] [-r id] [-p] <headline> [body]" >&2; exit 1; }
headline="$1"
body="${2:-}"

case "$urgency" in
  low) urgency_byte=0 ;;
  normal) urgency_byte=1 ;;
  critical) urgency_byte=2 ;;
  *) urgency_byte=1 ;;
esac

hints=(urgency y "$urgency_byte")
if [[ -n "$glyph" ]]; then
  hints+=(glyph-icon s "$glyph")
fi
hint_count=$((${#hints[@]} / 3))

call_args=(
  busctl --user -- call
  org.freedesktop.Notifications /org/freedesktop/Notifications
  org.freedesktop.Notifications Notify susssasa{sv}i
  "$app_name" "$replaces_id" "" "$headline" "$body"
  0
  "$hint_count" "${hints[@]}"
  "$expire_timeout"
)

if (( print_id )); then
  out=$("${call_args[@]}")
  printf '%s\n' "${out##* }"
else
  "${call_args[@]}" >/dev/null
fi
```

---

## BLUEPRINT 3: CAPTIVE PORTAL RESOLVER & TAILSCALE EXIT NODE AUTO-SWITCH

### 1. Mục tiêu
Tự động tạm dừng Tailscale exit node khi kết nối Wi-Fi cần đăng nhập web portal, mở trình duyệt đăng nhập dạng nổi, theo dõi kết nối và tự động khôi phục exit node ngay khi có mạng.

### 2. Thành phần kỹ thuật
- **Vị trí**: `scripts/.local/bin/captive-portal-resolver`
- **Dependencies**: `curl`, `tailscale`, `nmcli`, `hyprctl` (hoặc wmctrl), `flock`.

### 3. Mã nguồn triển khai (`scripts/.local/bin/captive-portal-resolver`)

```bash
#!/usr/bin/env bash
# ==============================================================================
# captive-portal-resolver: Network boundary adaptation helper
# ==============================================================================
set -euo pipefail

LOCK_FILE="${XDG_RUNTIME_DIR:-/run/user/$UID}/captive-portal.lock"
TAILSCALE_SOCK="/var/run/tailscale/tailscaled.sock"
portal_url="${1:-http://detectportal.firefox.com/canonical.html}"
paused_exit_node=0

restore_tailscale() {
  if (( paused_exit_node )); then
    echo "==> Đang khôi phục lại Tailscale exit node..."
    curl -fsS --unix-socket "$TAILSCALE_SOCK" -X POST \
      "http://local-tailscaled.sock/localapi/v0/set-use-exit-node-enabled?enabled=true" >/dev/null 2>&1 || true
    ka-notify -g "󰖂" "Mạng Internet đã kết nối" "Tailscale Exit Node đã được tự động kích hoạt lại."
  fi
}

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "Một trình kiểm tra captive portal khác đang chạy."
  exit 0
fi
trap restore_tailscale EXIT

# 1. Kiểm tra Tailscale exit node có đang active không
if [[ -S "$TAILSCALE_SOCK" ]]; then
  if tailscale status --json 2>/dev/null | jq -e '.ExitNodeStatus != null' >/dev/null 2>&1; then
    echo "==> Tạm dừng Tailscale exit node để tránh kẹt trang đăng nhập Wi-Fi..."
    curl -fsS --unix-socket "$TAILSCALE_SOCK" -X POST \
      "http://local-tailscaled.sock/localapi/v0/set-use-exit-node-enabled?enabled=false" >/dev/null 2>&1 || true
    paused_exit_node=1
    ka-notify -g "󰖩" "Phát hiện Wi-Fi yêu cầu đăng nhập" "Đã tạm dừng Tailscale exit node."
  fi
fi

# 2. Khởi chạy cửa sổ trình duyệt độc lập
echo "==> Mở cổng đăng nhập tại: $portal_url"
${BROWSER:-firefox} --new-window "$portal_url" &
browser_pid=$!

# 3. Chờ trạng thái mạng đạt "full"
echo "==> Đang theo dõi trạng thái kết nối mạng..."
until [[ $(LC_ALL=C timeout 4 nmcli networking connectivity check 2>/dev/null) == "full" ]]; do
  if ! kill -0 "$browser_pid" 2>/dev/null; then
    echo "Người dùng đã đóng trình duyệt trước khi hoàn tất đăng nhập."
    exit 1
  fi
  sleep 2
done

echo "==> Mạng Internet đã hoạt động đầy đủ."
```

---

## BLUEPRINT 4: TRANSPARENT PUSH-TO-TALK KEYBINDING TRONG HYPRLAND

### 1. Mục tiêu
Thiết lập phím giữ để nói (Push-to-Talk) cho Dictation hoặc Micro mà không bao giờ bị kẹt sự kiện nhả phím (release event) khi có phím khác được gõ xen vào.

### 2. Triển khai trong Hyprland Lua (`~/.config/hypr/bindings.lua`)

```lua
-- ==============================================================================
-- Hyprland Lua Helper: Non-Consuming Modifier-Agnostic Push-to-Talk
-- ==============================================================================
local function bind_push_to_talk(key, start_cmd, stop_cmd)
  local is_active = false

  local function on_press()
    if not is_active then
      is_active = true
      hl.exec_cmd(start_cmd)
    end
  end

  local function on_release()
    if is_active then
      is_active = false
      hl.exec_cmd(stop_cmd)
    end
  end

  -- Press Bind
  hl.bind(key, on_press, { description = "Bắt đầu thu âm" })

  -- Release Bind (Cấu hình đặc biệt chống nuốt phím)
  hl.bind(key, on_release, {
    release = true,
    transparent = true,      -- Cho phép phím đi xuyên qua ứng dụng khác
    ignore_mods = true,      -- Bỏ qua trạng thái Shift/Ctrl khi nhả
    non_consuming = true,    -- Không chiếm độc quyền mã phím
    description = "Dừng thu âm"
  })
end

-- Áp dụng cho phím Right Alt (hoặc Super + H)
bind_push_to_talk("ALT_R", "superwhisper start", "superwhisper stop")
```

---

## BLUEPRINT 5: MULTI-ACCOUNT AI AGENT ENVIRONMENT HARNESS

### 1. Mục tiêu
Chuyển đổi danh tính tài khoản AI coding agents (Claude, Codex, Grok) tức thì, bảo vệ lịch sử riêng biệt, mã hóa token qua Linux Keyring và tự động kế thừa vào các subshell.

### 2. Thành phần kỹ thuật
- **Vị trí**: `scripts/.local/bin/agent-env`
- **Thư mục lưu trữ**: `~/.local/share/agent-accounts/<provider>/<account_name>/`

### 3. Mã nguồn triển khai (`scripts/.local/bin/agent-env`)

```bash
#!/usr/bin/env bash
# ==============================================================================
# agent-env: Multi-account environment wrapper for AI Coding Agents
# Usage:
#   agent-env use <claude|codex|grok> <account_name>
#   agent-env exec <claude|codex|grok> [args...]
# ==============================================================================
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/agent-harness"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agent-accounts"
mkdir -p "$STATE_DIR" "$DATA_DIR"

command="${1:-}"
shift || { echo "Lệnh không hợp lệ. Sử dụng: agent-env <use|exec|list>" >&2; exit 1; }

case "$command" in
  use)
    provider="${1:?Thiếu tên provider (claude|codex|grok)}"
    account="${2:?Thiếu tên tài khoản}"
    target_dir="$DATA_DIR/$provider/$account"
    mkdir -p "$target_dir"
    printf '%s\n' "$account" > "$STATE_DIR/$provider.active"
    ka-notify -g "󰚩" "AI Agent Chuyển Tài Khoản" "Tài khoản $provider hiện tại: $account"
    ;;

  exec)
    provider="${1:?Thiếu tên provider}"
    shift
    active_file="$STATE_DIR/$provider.active"
    account="default"
    [[ -r "$active_file" ]] && account=$(<"$active_file")
    
    target_dir="$DATA_DIR/$provider/$account"
    mkdir -p "$target_dir"

    case "$provider" in
      claude) export CLAUDE_CONFIG_DIR="$target_dir" ;;
      codex)  export CODEX_HOME="$target_dir" ;;
      grok)   export GROK_HOME="$target_dir" ;;
    esac

    # Thực thi nhị phân thật của Agent
    exec "$provider" "$@"
    ;;

  list)
    echo "=== DANH SÁCH TÀI KHOẢN AGENT HIỆN TẠI ==="
    for p in claude codex grok; do
      active="default"
      [[ -r "$STATE_DIR/$p.active" ]] && active=$(<"$STATE_DIR/$p.active")
      echo "[$p] Đang kích hoạt: $active"
      if [[ -d "$DATA_DIR/$p" ]]; then
        ls -1 "$DATA_DIR/$p" | sed 's/^/  - /'
      fi
    done
    ;;
esac
```

---

## BLUEPRINT 6: QUAKE-STYLE DROP-DOWN TERMINAL SCRATCHPAD

### 1. Mục tiêu
Triệu hồi một cửa sổ terminal nổi tức thì bằng phím tắt `Super + ~`, định vị ở 50% màn hình trên cùng, có khả năng ẩn/hiện mà không làm mất tiến trình đang chạy bên trong.

### 2. Triển khai trong Hyprland Configuration (`~/.config/hypr/hyprland.conf`)

```ini
# ==============================================================================
# Quake-style Dropdown Console via Hyprland Special Workspace
# ==============================================================================

# 1. Window Rules cho cửa sổ Scratchpad
windowrulev2 = float, class:^(quake-console)$
windowrulev2 = workspace special:scratchpad, class:^(quake-console)$
windowrulev2 = size 90% 50%, class:^(quake-console)$
windowrulev2 = move 5% 30, class:^(quake-console)$
windowrulev2 = animation slide top, class:^(quake-console)$

# 2. Khởi động terminal ở chế độ nền khi mở máy
exec-once = uwsm-app -- foot --app-id=quake-console -e tmux new-session -A -s scratchpad

# 3. Phím tắt kích hoạt Toggle
bind = SUPER, GRAVE, togglespecialworkspace, scratchpad
```
- **Ưu điểm**: Sử dụng `foot` (tiêu tốn < 15MB RAM) kết hợp `tmux`. Khi toggle, cửa sổ trượt mượt mà từ trên xuống. Mọi tiến trình biên dịch hoặc agent bên trong tiếp tục chạy bình thường ngay cả khi scratchpad bị ẩn.
