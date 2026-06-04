-- .config/nvim/ftplugin/go.lua
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- ════════════════════════════════════════════════════════════════════════════
-- Helpers & Utilities
-- ════════════════════════════════════════════════════════════════════════════

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Go Tools" })
end

local function get_module_root()
  local filepath = vim.api.nvim_buf_get_name(0)
  local dir = vim.fn.fnamemodify(filepath, ":h")
  while dir ~= "/" do
    if vim.fn.filereadable(dir .. "/go.mod") == 1 then
      return dir
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return vim.fn.getcwd() -- Fallback
end

local function get_package_path()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return "."
  end
  return vim.fn.fnamemodify(filepath, ":h")
end

-- Chạy lệnh trong Snacks Terminal (Cho các lệnh cần output dài hoặc tương tác)
local function run_in_terminal(cmd, opts)
  opts = opts or {}
  Snacks.terminal(cmd, {
    cwd = opts.cwd or get_module_root(),
    win = {
      position = "bottom",
      height = 0.4,
      border = "rounded",
      title = " Go Output ",
      title_pos = "center",
    },
    interactive = true, -- Giữ terminal mở sau khi chạy xong để xem log
    start_insert = false, -- Không tự động vào chế độ insert
  })
end

-- Chạy lệnh ngầm (Cho các lệnh automation: fmt, tags, mod tidy...)
local function run_async(cmd, opts)
  opts = opts or {}
  local on_exit = opts.on_exit or function() end
  local cwd = opts.cwd or get_module_root()

  vim.system(cmd, { text = true, cwd = cwd }, function(result)
    vim.schedule(function()
      on_exit(result)
    end)
  end)
end

-- ════════════════════════════════════════════════════════════════════════════
-- Build & Run
-- ════════════════════════════════════════════════════════════════════════════

-- GoBuild: go build (Dùng terminal để xem lỗi nếu có)
vim.api.nvim_buf_create_user_command(0, "GoBuild", function(opts)
  local args = opts.args ~= "" and opts.args or "./..."
  run_in_terminal("go build -v " .. args)
end, { nargs = "?", desc = "go build" })

-- GoRun: go run
vim.api.nvim_buf_create_user_command(0, "GoRun", function(opts)
  local args = opts.args ~= "" and opts.args or "."
  run_in_terminal("go run " .. args)
end, { nargs = "?", desc = "go run" })

-- GoGenerate: go generate
vim.api.nvim_buf_create_user_command(0, "GoGenerate", function(opts)
  local args = opts.args ~= "" and opts.args or "./..."
  notify("Running: go generate " .. args)
  run_async({ "go", "generate", args }, {
    on_exit = function(result)
      if result.code == 0 then
        notify("Generate completed")
        vim.cmd("checktime")
      else
        -- Nếu lỗi, hiện thông báo lỗi chi tiết
        notify("Generate failed:\n" .. (result.stderr or result.stdout), vim.log.levels.ERROR)
      end
    end,
  })
end, { nargs = "?", desc = "go generate" })

-- ════════════════════════════════════════════════════════════════════════════
-- Testing
-- ════════════════════════════════════════════════════════════════════════════

-- GoTest: go test
vim.api.nvim_buf_create_user_command(0, "GoTest", function(opts)
  local args = opts.args ~= "" and opts.args or "./..."
  run_in_terminal("go test -v " .. args)
end, { nargs = "?", desc = "go test" })

-- GoTestFunc: test function under cursor
vim.api.nvim_buf_create_user_command(0, "GoTestFunc", function()
  local func_name = nil
  local node = vim.treesitter.get_node()
  while node do
    if node:type() == "function_declaration" then
      local name_node = node:field("name")[1]
      if name_node then
        func_name = vim.treesitter.get_node_text(name_node, 0)
        break
      end
    end
    node = node:parent()
  end

  if not func_name or not func_name:match("^Test") then
    notify("Cursor not inside a Test function", vim.log.levels.WARN)
    return
  end

  -- Sử dụng regex ^Name$ để chạy chính xác test đó
  local pkg = get_package_path()
  run_in_terminal(string.format("go test -v -run ^%s$ %s", func_name, pkg))
end, { desc = "Test function under cursor" })

-- GoTestFile: test current package/file location
vim.api.nvim_buf_create_user_command(0, "GoTestFile", function()
  local pkg = get_package_path()
  run_in_terminal("go test -v " .. pkg)
end, { desc = "Test current package" })

-- GoCoverage: test with coverage and open HTML
vim.api.nvim_buf_create_user_command(0, "GoCoverage", function(opts)
  local args = opts.args ~= "" and opts.args or "./..."
  -- Chain commands: chạy test -> tạo profile -> mở html
  local cmd = "go test -coverprofile=coverage.out "
    .. args
    .. " && go tool cover -html=coverage.out"
  run_in_terminal(cmd)
end, { nargs = "?", desc = "go test with coverage" })

-- ════════════════════════════════════════════════════════════════════════════
-- Module Management
-- ════════════════════════════════════════════════════════════════════════════

-- GoModTidy
vim.api.nvim_buf_create_user_command(0, "GoModTidy", function()
  notify("Running: go mod tidy")
  run_async({ "go", "mod", "tidy" }, {
    on_exit = function(result)
      if result.code == 0 then
        notify("go mod tidy completed")
        vim.cmd("checktime") -- Reload buffer nếu file go.mod thay đổi
      else
        notify("go mod tidy failed:\n" .. (result.stderr or result.stdout), vim.log.levels.ERROR)
      end
    end,
  })
end, { desc = "go mod tidy" })

-- GoModInit
vim.api.nvim_buf_create_user_command(0, "GoModInit", function(opts)
  if opts.args == "" then
    notify("Usage: GoModInit <module-name>", vim.log.levels.WARN)
    return
  end
  notify("Running: go mod init " .. opts.args)
  run_async({ "go", "mod", "init", opts.args }, {
    cwd = vim.fn.getcwd(), -- Init thường chạy ở root folder hiện tại
    on_exit = function(result)
      if result.code == 0 then
        notify("go mod init completed")
        vim.cmd("checktime")
      else
        notify("go mod init failed:\n" .. (result.stderr or result.stdout), vim.log.levels.ERROR)
      end
    end,
  })
end, { nargs = 1, desc = "go mod init <module>" })

-- GoGet
vim.api.nvim_buf_create_user_command(0, "GoGet", function(opts)
  if opts.args == "" then
    notify("Usage: GoGet <package>", vim.log.levels.WARN)
    return
  end
  notify("Running: go get " .. opts.args)
  run_async({ "go", "get", opts.args }, {
    on_exit = function(result)
      if result.code == 0 then
        notify("Installed: " .. opts.args)
        vim.cmd("checktime")
      else
        notify("go get failed:\n" .. (result.stderr or result.stdout), vim.log.levels.ERROR)
      end
    end,
  })
end, { nargs = 1, desc = "go get <package>" })

-- ════════════════════════════════════════════════════════════════════════════
-- Code Tools
-- ════════════════════════════════════════════════════════════════════════════

-- GoVet
vim.api.nvim_buf_create_user_command(0, "GoVet", function(opts)
  local args = opts.args ~= "" and opts.args or "./..."
  -- Dùng terminal để dễ đọc danh sách lỗi nếu nhiều
  run_in_terminal("go vet " .. args)
end, { nargs = "?", desc = "go vet" })

-- GoLint (golangci-lint)
vim.api.nvim_buf_create_user_command(0, "GoLint", function(opts)
  local args = opts.args ~= "" and opts.args or "./..."
  run_in_terminal("golangci-lint run " .. args)
end, { nargs = "?", desc = "golangci-lint run" })

-- GoDoc
vim.api.nvim_buf_create_user_command(0, "GoDoc", function(opts)
  local target = opts.args
  if target == "" then
    target = vim.fn.expand("<cword>")
  end
  if target == "" then
    notify("Usage: GoDoc <symbol> or cursor on symbol", vim.log.levels.WARN)
    return
  end
  run_in_terminal("go doc " .. target)
end, { nargs = "?", desc = "go doc <symbol>" })

-- GoImpl
vim.api.nvim_buf_create_user_command(0, "GoImpl", function(opts)
  if opts.args == "" then
    notify(
      "Usage: GoImpl <recv> <interface> (e.g., GoImpl 's *Service' io.Reader)",
      vim.log.levels.WARN
    )
    return
  end
  if vim.fn.executable("impl") == 0 then
    notify("Tool 'impl' not found. Run :GoInstallBinaries", vim.log.levels.ERROR)
    return
  end

  local output = vim.fn.system("impl " .. opts.args)
  if vim.v.shell_error == 0 then
    local lines = vim.split(output, "\n")
    local row = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, row, row, false, lines)
    -- Format lại code vừa chèn
    vim.cmd("silent! normal! ==")
    notify("Implementation inserted")
  else
    notify("impl failed: " .. output, vim.log.levels.ERROR)
  end
end, { nargs = "+", desc = "Generate interface implementation" })

-- GoIfErr
vim.api.nvim_buf_create_user_command(0, "GoIfErr", function()
  -- Check iferr tool
  if vim.fn.executable("iferr") == 1 then
    local pos = vim.fn.getcurpos()
    local byte_offset = vim.fn.line2byte(pos[2]) + pos[3] - 1
    local output = vim.fn.system(string.format("iferr -pos %d", byte_offset))

    if vim.v.shell_error == 0 and output ~= "" then
      local lines = vim.split(output, "\n")
      -- Remove empty last line from split
      if lines[#lines] == "" then
        table.remove(lines)
      end

      vim.api.nvim_buf_set_lines(0, pos[2], pos[2], false, lines)
      vim.cmd("silent! normal! ==")
      return
    end
  end

  -- Fallback simple template
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = { "if err != nil {", "\treturn err", "}" }
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
  vim.cmd("silent! normal! ==")
end, { desc = "Insert if err != nil block" })

-- GoModernize
vim.api.nvim_buf_create_user_command(0, "GoModernize", function()
  local filepath = vim.api.nvim_buf_get_name(0)
  vim.cmd("silent write")
  notify("GoModernize: running...")
  run_async({
    "go",
    "run",
    "golang.org/x/tools/gopls/internal/analysis/modernize/cmd/modernize@latest",
    "-fix",
    filepath,
  }, {
    on_exit = function(result)
      if result.code == 0 then
        vim.cmd("checktime")
        notify("GoModernize: completed")
      else
        notify("GoModernize failed: " .. (result.stderr or result.stdout), vim.log.levels.ERROR)
      end
    end,
  })
end, { desc = "Run gopls modernize -fix" })

-- GoFillStruct (Helper cho Code Action)
vim.api.nvim_buf_create_user_command(0, "GoFillStruct", function()
  vim.lsp.buf.code_action({
    filter = function(action)
      return action.title:match("Fill") ~= nil
    end,
    apply = true,
  })
end, { desc = "Fill struct fields" })

-- GoAddTags / GoRemoveTags
local function modify_tags(args, mode)
  local tags = args ~= "" and args or "json"
  if vim.fn.executable("gomodifytags") == 0 then
    notify("Tool 'gomodifytags' not found. Run :GoInstallBinaries", vim.log.levels.ERROR)
    return
  end

  local filepath = vim.api.nvim_buf_get_name(0)
  local line = vim.fn.line(".")
  vim.cmd("silent write")

  local flag = mode == "add" and "-add-tags" or "-remove-tags"
  local cmd = string.format("gomodifytags -file %s -line %d %s %s", filepath, line, flag, tags)

  local output = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    vim.cmd("edit!")
    notify("Tags " .. (mode == "add" and "added: " or "removed: ") .. tags)
  else
    notify("gomodifytags failed: " .. output, vim.log.levels.ERROR)
  end
end

vim.api.nvim_buf_create_user_command(0, "GoAddTags", function(opts)
  modify_tags(opts.args, "add")
end, { nargs = "?", desc = "Add struct tags" })
vim.api.nvim_buf_create_user_command(0, "GoRemoveTags", function(opts)
  modify_tags(opts.args, "remove")
end, { nargs = "?", desc = "Remove struct tags" })

-- ════════════════════════════════════════════════════════════════════════════
-- Navigation
-- ════════════════════════════════════════════════════════════════════════════

local function alt_file(cmd)
  local filepath = vim.api.nvim_buf_get_name(0)
  local alt
  if filepath:match("_test%.go$") then
    alt = filepath:gsub("_test%.go$", ".go")
  else
    alt = filepath:gsub("%.go$", "_test.go")
  end
  if vim.fn.filereadable(alt) == 1 then
    vim.cmd(cmd .. " " .. alt)
  else
    notify("Alt file not found: " .. vim.fn.fnamemodify(alt, ":t"), vim.log.levels.WARN)
  end
end

vim.api.nvim_buf_create_user_command(0, "GoAlt", function()
  alt_file("edit")
end, { desc = "Switch test/source" })
vim.api.nvim_buf_create_user_command(0, "GoAltV", function()
  alt_file("vsplit")
end, { desc = "Switch test/source (vsplit)" })

-- ════════════════════════════════════════════════════════════════════════════
-- Tool Installation
-- ════════════════════════════════════════════════════════════════════════════

local go_tools = {
  { name = "goimports", url = "golang.org/x/tools/cmd/goimports@latest" },
  { name = "gomodifytags", url = "github.com/fatih/gomodifytags@latest" },
  { name = "impl", url = "github.com/josharian/impl@latest" },
  { name = "iferr", url = "github.com/koron/iferr@latest" },
  { name = "gotests", url = "github.com/cweill/gotests/gotests@latest" },
  { name = "golangci-lint", url = "github.com/golangci/golangci-lint/cmd/golangci-lint@latest" },
  { name = "dlv", url = "github.com/go-delve/delve/cmd/dlv@latest" },
  { name = "staticcheck", url = "honnef.co/go/tools/cmd/staticcheck@latest" },
  { name = "govulncheck", url = "golang.org/x/vuln/cmd/govulncheck@latest" },
}

local function install_tools_async(tools, index, action, on_complete)
  index = index or 1
  if index > #tools then
    on_complete()
    return
  end

  local tool = tools[index]
  notify(string.format("[%d/%d] %s: %s", index, #tools, action, tool.name))

  run_async({ "go", "install", tool.url }, {
    on_exit = function(result)
      if result.code ~= 0 then
        notify(
          string.format("Failed to install %s: %s", tool.name, result.stderr or ""),
          vim.log.levels.ERROR
        )
      end
      install_tools_async(tools, index + 1, action, on_complete)
    end,
  })
end

vim.api.nvim_buf_create_user_command(0, "GoInstallBinaries", function()
  notify("Installing Go binaries...")
  install_tools_async(go_tools, 1, "Installing", function()
    notify("All Go binaries installed!", vim.log.levels.INFO)
  end)
end, { desc = "Install all Go tools" })

vim.api.nvim_buf_create_user_command(0, "GoUpdateBinaries", function()
  notify("Updating Go binaries...")
  install_tools_async(go_tools, 1, "Updating", function()
    notify("All Go binaries updated!", vim.log.levels.INFO)
  end)
end, { desc = "Update all Go tools" })
