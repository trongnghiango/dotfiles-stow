-- ==============================================================================
-- OMARCHY HYPRLAND KEYBINDINGS — DWM HYBRID POWER-USER STACK (CLEAN NO-CONFLICT)
-- ==============================================================================
-- File: ~/.config/hypr/bindings.lua
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. UNBIND ALL OVERRIDDEN OMARCHY DEFAULTS
-- ------------------------------------------------------------------------------
hl.unbind("SUPER + W")
hl.unbind("SUPER + K")
hl.unbind("SUPER + J")
hl.unbind("SUPER + L")
hl.unbind("SUPER + SPACE")
hl.unbind("SUPER + SHIFT + SPACE")
hl.unbind("SUPER + D")
hl.unbind("SUPER + E")
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + M")
hl.unbind("SUPER + Z")
hl.unbind("SUPER + F")

-- ------------------------------------------------------------------------------
-- 2. WINDOW MANAGEMENT & SIZING (Chuẩn DWM)
-- ------------------------------------------------------------------------------
-- Đóng cửa sổ đang chọn (DWM killclient)
o.bind("SUPER + Q", "Close active window", hl.dsp.window.close())

-- Chuyển đổi Floating / Tiling (Hỗ trợ cả SUPER + T lẫn SUPER + SHIFT + SPACE)
o.bind("SUPER + T", "Toggle floating/tiling", hl.dsp.window.float({ action = "toggle" }))
o.bind("SUPER + SHIFT + SPACE", "Toggle floating/tiling", hl.dsp.window.float({ action = "toggle" }))

-- Đổi hướng chia nhánh Tiling (Ngang ⟷ Dọc)
o.bind("SUPER + BACKSLASH", "Toggle window split (Horizontal/Vertical)", hl.dsp.layout("togglesplit"))

-- Ẩn / Hiện thanh Top Bar (DWM togglebar)
o.bind_toggle("SUPER + B", "Toggle top bar", "bar")

-- Phóng to MAXIMIZED (Monocle [M] - VẪN GIỮ THANH TOPBAR STATUS)
o.bind("SUPER + M", "Toggle maximized (keep topbar)", hl.dsp.window.fullscreen({ mode = "maximized" }))
o.bind("SUPER + Z", "Toggle maximized (keep topbar)", hl.dsp.window.fullscreen({ mode = "maximized" }))

-- Phóng to FULLSCREEN (True Fullscreen - CHE TOÀN MÀN HÌNH & TOPBAR)
o.bind("SUPER + F", "Toggle true fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- ------------------------------------------------------------------------------
-- 3. VIM STACK NAVIGATION & MOVING (h / j / k / l)
-- ------------------------------------------------------------------------------
-- Di chuyển con trỏ (Focus window theo hướng Vim)
o.bind("SUPER + H", "Focus left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + L", "Focus right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + J", "Focus below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus above window", hl.dsp.focus({ direction = "u" }))

-- Đổi vị trí cửa sổ (Swap window)
o.bind("SUPER + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))

-- ------------------------------------------------------------------------------
-- 4. RESIZE RATIO (DWM setmfact)
-- ------------------------------------------------------------------------------
-- Thu hẹp / Mở rộng độ rộng cửa sổ Master
o.bind("SUPER + ALT + H", "Shrink master window", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
o.bind("SUPER + ALT + L", "Expand master window", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))

-- ------------------------------------------------------------------------------
-- 5. APP LAUNCHERS & MENUS
-- ------------------------------------------------------------------------------
-- Terminal & Trình duyệt Web
o.bind("SUPER + RETURN", "Terminal", { omarchy = "terminal" })
o.bind("SUPER + W", "Web Browser", { omarchy = "browser" })

-- Trình quản lý File (LF) & Trình chọn Emoji
o.bind("SUPER + E", "File Manager (LF)", { tui = "lf" })
o.bind("SUPER + SHIFT + E", "Omarchy Emojis", "omarchy-shell shell toggle omarchy.emojis")

-- Launcher & Menu (Chuẩn lệnh 'omarchy-menu toggle')
o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle")
o.bind("SUPER + D", "Omarchy App Launcher", "omarchy-menu toggle apps")
o.bind("SUPER + F1", "Omarchy Keybindings Help", "omarchy-menu-keybindings")
o.bind("SUPER + SLASH", "Omarchy Keybindings Help", "omarchy-menu-keybindings")

-- ------------------------------------------------------------------------------
-- 6. MULTI-MONITORS & SCRATCHPAD
-- ------------------------------------------------------------------------------
-- Chuyển màn hình (DWM comma / period)
o.bind("SUPER + COMMA", "Focus left monitor", hl.dsp.focus({ monitor = "-1" }))
o.bind("SUPER + PERIOD", "Focus right monitor", hl.dsp.focus({ monitor = "+1" }))
o.bind("SUPER + SHIFT + COMMA", "Move workspace left", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + PERIOD", "Move workspace right", hl.dsp.workspace.move({ monitor = "r" }))

-- Scratchpad (Ẩn/Hiện cửa sổ nổi nhanh)
o.bind("SUPER + GRAVE", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + GRAVE", "Send to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
