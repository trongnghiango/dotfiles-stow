-- ==============================================================================
-- OMARCHY HYPRLAND LOOK & FEEL — USER OVERRIDES
-- ==============================================================================
-- File: ~/.config/hypr/looknfeel.lua
-- Managed via GNU Stow (hypr package)
-- ==============================================================================

hl.config({
  misc = {
    -- Retain fullscreen/maximize (monocle) state when closing a window
    exit_window_retains_fullscreen = true,
    -- Disable heavy resize animation calculations for instant buttery response
    animate_manual_resizes = false,
    animate_mouse_windowdragging = false,
  },
})

-- ------------------------------------------------------------------------------
-- HIGH-PERFORMANCE SMOOTH ANIMATION PROFILE (Zero-stutter on 60Hz)
-- ------------------------------------------------------------------------------
-- Fast, elegant ease-out bezier curves
hl.curve("smoothOut", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("snappy", { type = "bezier", points = { { 0.25, 1 }, { 0.5, 1 } } })

-- Ultra-Responsive & Crisp Animations: Fast curves, high FPS feel
hl.animation({ leaf = "windows", enabled = true, speed = 3.0, bezier = "smoothOut" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.0, bezier = "smoothOut", style = "popin 95%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.0, bezier = "smoothOut", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.0, bezier = "smoothOut" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.0, bezier = "smoothOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.0, bezier = "smoothOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "smoothOut" })
hl.animation({ leaf = "border", enabled = true, speed = 3.0, bezier = "smoothOut" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.5, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.0, bezier = "smoothOut", style = "fade" })
