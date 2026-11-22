-- ============================================================================
-- Leader Keys
-- ============================================================================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- Disable Built-in Plugins
-- ============================================================================
vim.g.loaded_netrw = 0 -- on: 1 ; off: 0
vim.g.loaded_netrwPlugin = 1

-- ============================================================================
-- Disable Providers (silence health check warnings)
-- ============================================================================
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- ============================================================================
-- Editor Behavior
-- ============================================================================
vim.o.background = "dark"
vim.opt.mouse = "a"

-- Clipboard: OSC52 hoạt động qua SSH (không cần xclip/wl-copy).
-- Neovim >= 0.10 có sẵn vim.ui.clipboard.osc52.
if vim.fn.has("nvim-0.10") == 1 then
  local osc52 = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = {
    name = "OSC52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
end
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
vim.opt.updatetime = 300
vim.opt.timeoutlen = 1000
vim.opt.confirm = true
vim.opt.autoread = true
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.smoothscroll = true -- Cuộn mượt hơn (0.10+)
end

-- ============================================================================
-- UI/Display
-- ============================================================================
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.numberwidth = 4
vim.opt.signcolumn = "yes:1"
vim.opt.cursorline = false
vim.opt.wrap = false
vim.opt.breakindent = true
vim.opt.showmode = false
vim.opt.showcmd = false
vim.opt.ruler = true
vim.opt.showtabline = 0
vim.opt.cmdheight = 1
vim.opt.pumheight = 10
vim.opt.fillchars = { eob = " " }
if vim.fn.has("nvim-0.11") == 1 then
  vim.o.winborder = "rounded"
end

-- ============================================================================
-- Search
-- ============================================================================
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ============================================================================
-- Indentation
-- ============================================================================
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true

-- ============================================================================
-- Splits
-- ============================================================================
vim.opt.splitbelow = true
vim.opt.splitright = true

-- ============================================================================
-- Files
-- ============================================================================
vim.opt.fileencoding = "utf-8"
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- ============================================================================
-- Completion
-- ============================================================================
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.conceallevel = 2 -- old 0

-- ============================================================================
-- Other
-- ============================================================================
vim.opt.title = true
vim.opt.guifont = "monospace:h17"

-- ============================================================================
-- Filetype Detection
-- ============================================================================
vim.filetype.add({
  extension = {
    env = "dotenv",
  },
  filename = {
    [".env"] = "dotenv",
    ["env"] = "dotenv",
  },
  pattern = {
    ["[jt]sconfig.*.json"] = "jsonc",
    ["%.env%.[%w_.-]+"] = "dotenv",
  },
})
