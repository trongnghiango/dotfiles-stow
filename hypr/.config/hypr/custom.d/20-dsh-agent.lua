-- ==============================================================================
-- DEEPSEEK HARNESS (DSH) WINDOW RULES
-- ==============================================================================
-- File: ~/.config/hypr/custom.d/20-dsh-agent.lua
-- Mục đích: Tự động cho cửa sổ TUI của Agent nổi và căn giữa
-- Lưu ý: Phím tắt gọi DSH được tập trung quản lý tại ~/.config/hypr/bindings.lua
-- ==============================================================================

o.window({ class = "^org\\.omarchy\\.dsh$" }, {
  float = true,
  size = "1200 800",
  center = true,
})
