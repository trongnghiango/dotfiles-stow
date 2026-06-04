local M = {}

-- Đường dẫn mặc định nếu bạn mở nvim trực tiếp mà không qua Bash Launcher
local DEFAULT_VAULT = vim.fn.expand("~/Repos/github.com/trongnghiango/zettelkasten-notes-sync-git")

function M.get_path()
  -- 1. Kiểm tra biến môi trường MY_VAULT_PATH (do Bash Launcher set)
  local env_path = os.getenv("MY_VAULT_PATH")
  if env_path and env_path ~= "" then
    return env_path
  end

  -- 2. Fallback về đường dẫn mặc định
  return DEFAULT_VAULT
end

-- Hàm bổ trợ để resolve đường dẫn file trong vault
function M.resolve(rel_path)
  local root = M.get_path()
  -- Nếu rel_path đã là đường dẫn tuyệt đối, trả về luôn
  if rel_path:sub(1, 1) == "/" then
    return rel_path
  end
  -- Nếu không, nối với root của vault
  return root .. "/" .. rel_path
end

return M
