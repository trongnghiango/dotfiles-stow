---@class CoreTransparency
---Clean transparency management for floating windows, popups, sidebars, and pickers.
local M = {}

---Groups that should have their background cleared for seamless compositor blur
M.groups = {
  -- Core Editor & Floating Windows
  "Normal",
  "NormalFloat",
  "NormalNC",
  "FloatBorder",
  "FloatTitle",
  "Pmenu",
  "Terminal",
  "EndOfBuffer",
  "FoldColumn",
  "Folded",
  "SignColumn",
  "LineNr",
  "CursorLineNr",
  "WhichKeyFloat",

  -- Snacks UI & Picker
  "SnacksPicker",
  "SnacksPickerBorder",
  "SnacksPickerPreview",
  "SnacksPickerPreviewBorder",
  "SnacksPickerBoxBorder",
  "SnacksPickerList",
  "SnacksPickerListBorder",
  "SnacksDashboardNormal",
  "SnacksNotifierNormal",
  "SnacksNotifierBorder",
  "SnacksTerminalNormal",
  "SnacksTerminalBorder",

  -- Telescope
  "TelescopeBorder",
  "TelescopeNormal",
  "TelescopePromptBorder",
  "TelescopePromptTitle",

  -- File Explorers
  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeVertSplit",
  "NeoTreeWinSeparator",
  "NeoTreeEndOfBuffer",
  "NvimTreeNormal",
  "NvimTreeVertSplit",
  "NvimTreeEndOfBuffer",

  -- Notification Body & Borders
  "NotifyINFOBody",
  "NotifyERRORBody",
  "NotifyWARNBody",
  "NotifyTRACEBody",
  "NotifyDEBUGBody",
  "NotifyINFOTitle",
  "NotifyERRORTitle",
  "NotifyWARNTitle",
  "NotifyTRACETitle",
  "NotifyDEBUGTitle",
  "NotifyINFOBorder",
  "NotifyERRORBorder",
  "NotifyWARNBorder",
  "NotifyTRACEBorder",
  "NotifyDEBUGBorder",
}

---Clear background for a highlight group while preserving foreground and styles
---@param name string
function M.clear_bg(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl then
    hl.bg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

---Apply transparency to all registered groups
function M.apply()
  if vim.g.transparent_enabled == false then
    return
  end

  for _, name in ipairs(M.groups) do
    M.clear_bg(name)
  end
end

---Setup autocmds to automatically maintain transparency on colorscheme changes
function M.setup()
  local group = vim.api.nvim_create_augroup("OmarchyTransparency", { clear = true })

  vim.api.nvim_create_autocmd({ "ColorScheme", "UIEnter" }, {
    group = group,
    callback = function()
      vim.schedule(function()
        M.apply()
      end)
    end,
  })

  -- Apply immediately on setup
  M.apply()
end

return M
