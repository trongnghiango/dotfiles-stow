-- ==============================================================================
-- OMARCHY HYPRLAND LOOK & FEEL — USER OVERRIDES
-- ==============================================================================
-- File: ~/.config/hypr/looknfeel.lua
-- Managed via GNU Stow (hypr package)
-- ==============================================================================

hl.config({
  misc = {
    -- Giữ nguyên trạng thái Fullscreen khi cửa sổ phụ/dialog/screensaver đóng lại
    exit_window_retains_fullscreen = true,

    -- Không cho phép app tự ý kích hoạt và chiếm quyền Fullscreen khi nhận focus sau khi Unlock
    focus_on_activate = false,

    -- Disable heavy resize animation calculations for instant buttery response
    animate_manual_resizes = false,
    animate_mouse_windowdragging = false,
  },
})

-- ------------------------------------------------------------------------------
-- HIGH-PERFORMANCE SMOOTH ANIMATION PROFILE (Tối ưu 60Hz mượt mà, không giật)
-- ------------------------------------------------------------------------------
-- Đường cong giảm tốc tự nhiên (True Deceleration Curves)
hl.curve("smoothOut", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("snappy", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

-- Chuyển động mở/đóng cửa sổ mượt mà, popin 88% tự nhiên không bị giật khựng
hl.animation({ leaf = "windows", enabled = true, speed = 3.5, bezier = "smoothOut" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, bezier = "smoothOut", style = "popin 88%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "smoothOut", style = "popin 88%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "smoothOut" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.0, bezier = "smoothOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.0, bezier = "smoothOut" })
hl.animation({ leaf = "border", enabled = true, speed = 3.0, bezier = "smoothOut" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.0, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.0, bezier = "smoothOut", style = "fade" })
