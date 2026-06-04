-- .config/nvim/lua/utils/web_dev.lua
local M = {}

-- Tự động phát hiện Package Manager (pnpm > yarn > bun > npm)
local function get_package_manager()
  local root = vim.fn.getcwd()
  if vim.fn.filereadable(root .. "/pnpm-lock.yaml") == 1 then
    return "pnpm"
  end
  if vim.fn.filereadable(root .. "/yarn.lock") == 1 then
    return "yarn"
  end
  if vim.fn.filereadable(root .. "/bun.lockb") == 1 then
    return "bun"
  end
  return "npm"
end

-- Hàm setup các lệnh cho buffer hiện tại
function M.setup_commands()
  local pm = get_package_manager()

  -- Helper chạy lệnh trong Snacks Terminal
  local function run_term(cmd)
    Snacks.terminal(cmd, {
      win = { position = "bottom", height = 0.4, border = "rounded" },
      interactive = true,
      start_insert = true,
    })
  end

  -- 1. Lệnh :NpmInstall (Tự động dùng đúng pnpm/yarn/npm)
  vim.api.nvim_buf_create_user_command(0, "NpmInstall", function(opts)
    local args = opts.args or ""
    local cmd = pm .. " install " .. args
    if pm == "yarn" and args == "" then
      cmd = "yarn"
    end -- yarn install chỉ là yarn
    run_term(cmd)
  end, { nargs = "?", desc = "Install dependencies with detected PM" })

  -- 2. Lệnh :NpmRun (Quét package.json và hiện menu chọn script)
  vim.api.nvim_buf_create_user_command(0, "NpmRun", function()
    local package_json = vim.fn.getcwd() .. "/package.json"
    if vim.fn.filereadable(package_json) == 0 then
      vim.notify("No package.json found", vim.log.levels.WARN)
      return
    end

    -- Đọc và parse package.json
    local content = vim.fn.readfile(package_json)
    local json = vim.json.decode(table.concat(content, ""))

    if not json.scripts then
      vim.notify("No scripts found in package.json", vim.log.levels.WARN)
      return
    end

    -- Tạo danh sách script để chọn
    local scripts = {}
    for name, cmd in pairs(json.scripts) do
      table.insert(scripts, { name = name, cmd = cmd })
    end

    -- Dùng picker để chọn script đẹp mắt
    vim.ui.select(scripts, {
      prompt = "Run Script (" .. pm .. ")",
      format_item = function(item)
        return string.format("%-15s %s", item.name, item.cmd)
      end,
    }, function(item)
      if item then
        run_term(pm .. " run " .. item.name)
      end
    end)
  end, { desc = "Select and run package.json script" })

  -- 3. Lệnh :NodeRun (Chạy file hiện tại bằng node/bun/ts-node)
  vim.api.nvim_buf_create_user_command(0, "NodeRun", function()
    local file = vim.api.nvim_buf_get_name(0)
    local ext = vim.fn.fnamemodify(file, ":e")
    local cmd = ""

    if ext == "ts" or ext == "tsx" then
      if pm == "bun" then
        cmd = "bun run " .. file
      else
        -- Fallback nếu không có bun
        cmd = "npx ts-node " .. file
      end
    else
      cmd = "node " .. file
    end

    run_term(cmd)
  end, { desc = "Run current file with node/bun" })

  -- 4. Lệnh :TypeCheck (Chỉ dành cho TS)
  if vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact" then
    vim.api.nvim_buf_create_user_command(0, "TypeCheck", function()
      run_term("npx tsc --noEmit --pretty")
    end, { desc = "Run TypeScript type checking" })
  end
end

return M
