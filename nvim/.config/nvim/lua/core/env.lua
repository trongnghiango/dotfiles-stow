-- ============================================================================
-- ENV — Phát hiện môi trường để dùng CHUNG một cấu hình cho desktop và server
-- ============================================================================
-- Mục tiêu: không tách nvim/ thành 2 bản giữa main và server-minimal.
--   Desktop → full: LSP/linter đầy đủ, tự tải parser, checker plugin.
--   Server  → minimal: chỉ tool prebuilt, không tự tải gì, clipboard OSC52.
-- Override tay: KA_NVIM_FULL=1 (ép full) hoặc KA_NVIM_FULL=0 (ép minimal).

local M = {}

local function var_set(name)
  local v = vim.env[name]
  return v ~= nil and v ~= ""
end

-- SSH, hoặc không có UI nào (headless) → coi là "remote".
M.remote = var_set("SSH_CONNECTION") or var_set("SSH_TTY") or #vim.api.nvim_list_uis() == 0

-- Provider clipboard native (X11/Wayland): desktop thường có, server headless thì không.
M.native_clipboard = vim.fn.executable("wl-copy") == 1
  or vim.fn.executable("xclip") == 1
  or vim.fn.executable("xsel") == 1

local override = vim.env.KA_NVIM_FULL
if override == "1" then
  M.full = true
elseif override == "0" then
  M.full = false
else
  M.full = not M.remote
end

-- OSC52 qua SSH (và cả desktop khi thiếu provider native).
M.use_osc52 = M.remote or not M.native_clipboard

function M.has(feature)
  return vim.fn.has(feature) == 1
end

return M
