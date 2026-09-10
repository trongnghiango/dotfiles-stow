-- ==============================================================================
-- DEEPSEEK HARNESS (DSH) AS DEFAULT AGENT OVERRIDE
-- ==============================================================================
-- File: ~/.config/hypr/custom.d/20-dsh-agent.lua
-- Mục đích: Ghi đè hotkey agent mặc định của Omarchy sang DeepSeek Harness
-- ==============================================================================

-- 1. Unbind phím tắt Agent mặc định của Omarchy
hl.unbind("SUPER + SHIFT + CTRL + A")

-- 2. Gán lại phím gọi Agent mặc định sang DSH (Cửa sổ nổi Floating TUI / Focus)
o.bind("SUPER + SHIFT + CTRL + A", "DeepSeek Harness Agent", "dsh-agent --float")

-- 3. Phím tắt mở nhanh Web Dashboard DSH (port :3080)
o.bind("SUPER + SHIFT + D", "DeepSeek Harness Web Dashboard", "dsh-agent --web")

-- 4. Window Rules: Tự động cho cửa sổ TUI của Agent nổi và căn giữa
o.window({ class = "^org\\.omarchy\\.dsh$" }, {
  float = true,
  size = "1200 800",
  center = true,
})
