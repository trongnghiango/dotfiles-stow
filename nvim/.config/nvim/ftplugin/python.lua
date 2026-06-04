-- File: ~/.config/nvim/ftplugin/python.lua

-- ════════════════════════════════════════════════════════════════════════════
-- 1. CÁC HÀM HỖ TRỢ (HELPERS)
-- ════════════════════════════════════════════════════════════════════════════

-- Hàm tìm thư mục gốc của dự án (nơi chứa .git hoặc pyproject.toml)
local function get_project_root()
  local root = vim.fs.dirname(
    vim.fs.find({ ".git", "pyproject.toml", "setup.py", "requirements.txt" }, { upward = true })[1]
  )
  return root or vim.fn.getcwd()
end

-- Hàm tìm file requirements.txt (tìm ở thư mục hiện tại hoặc root)
local function find_requirements_file()
  local cwd = vim.fn.getcwd()
  local root = get_project_root()

  -- 1. Kiểm tra ngay tại chỗ đang đứng
  if vim.fn.filereadable(cwd .. "/requirements.txt") == 1 then
    return cwd .. "/requirements.txt"
  end

  -- 2. Kiểm tra ở thư mục gốc dự án
  if vim.fn.filereadable(root .. "/requirements.txt") == 1 then
    return root .. "/requirements.txt"
  end

  return nil
end

-- Hàm chạy lệnh trong Terminal đẹp (Snacks)
local function run_in_terminal(cmd)
  Snacks.terminal(cmd, {
    cwd = get_project_root(), -- Luôn chạy lệnh từ root dự án
    win = {
      position = "bottom",
      height = 0.4,
      border = "rounded",
      title = " Python Output ",
      title_pos = "center",
    },
    interactive = true,
    start_insert = false,
  })
end

-- ════════════════════════════════════════════════════════════════════════════
-- 2. TỰ ĐỘNG KÍCH HOẠT VENV (AUTO-ACTIVATE)
-- ════════════════════════════════════════════════════════════════════════════

local function activate_venv()
  local cwd = get_project_root()
  local venv_names = { ".venv", "venv", "env" }
  local venv_path = nil

  for _, name in ipairs(venv_names) do
    if vim.fn.isdirectory(cwd .. "/" .. name) == 1 then
      venv_path = cwd .. "/" .. name
      break
    end
  end

  if venv_path and vim.env.VIRTUAL_ENV ~= venv_path then
    vim.env.VIRTUAL_ENV = venv_path
    vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
    -- vim.notify("Activated venv: " .. venv_path, vim.log.levels.INFO)
  end
end

activate_venv()

-- ════════════════════════════════════════════════════════════════════════════
-- 3. CÁC LỆNH TIỆN ÍCH (COMMANDS)
-- ════════════════════════════════════════════════════════════════════════════

-- Lệnh :FastApiRun
vim.api.nvim_buf_create_user_command(0, "FastApiRun", function(opts)
  local args = opts.args
  if args == "" then
    if vim.fn.filereadable("main.py") == 1 then
      args = "main:app --reload"
    elseif vim.fn.filereadable("app/main.py") == 1 then
      args = "app.main:app --reload"
    else
      args = "main:app --reload"
    end
  end
  run_in_terminal("python -m uvicorn " .. args)
end, { nargs = "?", desc = "Run FastAPI" })

-- Lệnh :PyRun
vim.api.nvim_buf_create_user_command(0, "PyRun", function(opts)
  local file = vim.api.nvim_buf_get_name(0)
  run_in_terminal("python " .. file .. " " .. (opts.args or ""))
end, { nargs = "?", desc = "Run current file" })

-- Lệnh :PipInstallReq (Đã sửa lỗi Not Found)
vim.api.nvim_buf_create_user_command(0, "PipInstallReq", function()
  local req_file = find_requirements_file()

  if not req_file then
    vim.notify(
      "❌ Lỗi: Không tìm thấy file requirements.txt ở thư mục hiện tại hoặc root!",
      vim.log.levels.ERROR
    )
    return
  end

  vim.notify("📦 Đang cài đặt từ: " .. req_file, vim.log.levels.INFO)
  run_in_terminal("pip install -r " .. req_file)
end, { desc = "Install requirements.txt" })

-- Lệnh :VenvReset (Xóa và tạo lại venv + cài requirements)
vim.api.nvim_buf_create_user_command(0, "VenvReset", function()
  local venv_name = ".venv"
  local req_file = find_requirements_file()
  local cmd = "rm -rf "
    .. venv_name
    .. " && python3 -m venv "
    .. venv_name
    .. " && "
    .. venv_name
    .. "/bin/pip install --upgrade pip"

  if req_file then
    cmd = cmd .. " && " .. venv_name .. "/bin/pip install -r " .. req_file
    vim.notify(
      "♻️  Đang reset venv và cài đặt lại requirements...",
      vim.log.levels.INFO
    )
  else
    vim.notify(
      "♻️  Đang tạo venv trống (không tìm thấy requirements.txt)...",
      vim.log.levels.INFO
    )
  end

  cmd = cmd .. " && echo '\n✅  HOÀN TẤT! Hãy chạy :LspRestart để cập nhật.'"
  run_in_terminal(cmd)
end, { desc = "Reset .venv and reinstall requirements" })
