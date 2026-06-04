return {
  dir = vim.fn.stdpath("config"),
  name = "python-custom-tools",
  lazy = false,
  priority = 1000,
  config = function()
    -- ══════════════════════════════════════════════════════════════════════
    -- 1. HÀM HỖ TRỢ (HELPERS)
    -- ══════════════════════════════════════════════════════════════════════

    local function get_project_root()
      local cwd = vim.fn.getcwd()
      local root = vim.fs.dirname(
        vim.fs.find({ ".git", "requirements.txt", "pyproject.toml" }, { upward = true })[1]
      )
      return root or cwd
    end

    local function run_in_terminal(cmd)
      if _G.Snacks then
        Snacks.terminal(cmd, {
          cwd = get_project_root(),
          win = {
            position = "bottom",
            height = 0.4,
            border = "rounded",
            title = " Python Manager ",
          },
          interactive = true,
          start_insert = false,
        })
      else
        vim.cmd("split | terminal " .. cmd)
      end
    end

    -- HÀM QUAN TRỌNG: Chọn Python Builder
    -- Ưu tiên python3.11 (AUR) -> Fallback về python3 (System)
    local function get_python_builder()
      if vim.fn.executable("python3.11") == 1 then
        return "python3.11"
      elseif vim.fn.executable("python3.10") == 1 then
        return "python3.10"
      else
        return "python3" -- Fallback (3.14)
      end
    end

    -- ══════════════════════════════════════════════════════════════════════
    -- 2. AUTO-ACTIVATE & PATH
    -- ══════════════════════════════════════════════════════════════════════
    local function activate_venv()
      local root = get_project_root()
      local venv_path = root .. "/.venv"

      if vim.fn.isdirectory(venv_path) == 1 then
        vim.env.VIRTUAL_ENV = venv_path
        vim.env.PATH = venv_path .. "/bin:" .. vim.env.PATH
      end
    end

    activate_venv()
    vim.api.nvim_create_autocmd("DirChanged", { callback = activate_venv })

    -- ══════════════════════════════════════════════════════════════════════
    -- 3. CÁC LỆNH (ĐÃ UPDATE CHO ARCH AUR)
    -- ══════════════════════════════════════════════════════════════════════

    -- Lệnh: :VenvReset
    -- Tự động dùng python3.11 để tạo venv nếu có trong máy
    vim.api.nvim_create_user_command("VenvReset", function()
      local root = get_project_root()
      local venv_folder = ".venv"
      local builder = get_python_builder() -- Lấy python3.11 hoặc python3
      local venv_pip = venv_folder .. "/bin/pip"

      -- Thông báo rõ ràng
      if builder == "python3" then
        vim.notify(
          "⚠️  Cảnh báo: Không tìm thấy python3.11. Đang dùng Python hệ thống (3.14?)!",
          vim.log.levels.WARN
        )
      else
        vim.notify(
          "💎 Tuyệt vời! Đang dùng "
            .. builder
            .. " để tạo môi trường ổn định.",
          vim.log.levels.INFO
        )
      end

      local cmd = "rm -rf " .. venv_folder
      -- Tạo venv bằng builder (vd: python3.11 -m venv .venv)
      cmd = cmd .. " && " .. builder .. " -m venv " .. venv_folder
      cmd = cmd .. " && echo '✅ Created .venv using " .. builder .. "'"
      cmd = cmd .. " && " .. venv_pip .. " install --upgrade pip"

      if vim.fn.filereadable(root .. "/requirements.txt") == 1 then
        cmd = cmd .. " && " .. venv_pip .. " install -r requirements.txt"
        cmd = cmd .. " && echo '✅ Installed requirements.txt'"
      end

      cmd = cmd .. " && echo '\n🎉 Xong! Restart LSP (:LspRestart).'"
      run_in_terminal(cmd)
    end, { desc = "Reset venv using Python 3.11 if avail" })

    -- Lệnh: :PipInstallReq
    vim.api.nvim_create_user_command("PipInstallReq", function()
      local root = get_project_root()
      local pip_cmd = root .. "/.venv/bin/pip"

      if vim.fn.filereadable(pip_cmd) == 0 then
        vim.notify("❌ Chưa có .venv. Chạy :VenvReset trước!", vim.log.levels.ERROR)
        return
      end

      -- Kiểm tra version sau khi cài
      run_in_terminal(pip_cmd .. " install -r requirements.txt && python --version")
    end, { desc = "Install requirements" })

    -- Lệnh: :FastApiRun
    vim.api.nvim_create_user_command("FastApiRun", function(opts)
      local root = get_project_root()
      local python_cmd = root .. "/.venv/bin/python"

      if vim.fn.filereadable(python_cmd) == 0 then
        vim.notify("❌ Chưa có .venv!", vim.log.levels.ERROR)
        return
      end

      local args = opts.args
      if args == "" then
        args = "main:app --reload"
      end
      run_in_terminal(python_cmd .. " -m uvicorn " .. args)
    end, { nargs = "?", desc = "Run FastAPI" })
  end,
}
