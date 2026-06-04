-- =============================================================================
-- MODULE: LINK COMPLETION (TỐI ƯU HÓA BỘ NHỚ ĐỆM & HIỆU NĂNG)
-- =============================================================================

local vault = require("utils.vault")

-- Bộ nhớ đệm tránh việc quét ổ cứng liên tục khi gõ phím
local completion_cache = {
  data = {},
  last_updated = 0,
  cache_duration = 300, -- Lưu cache trong 5 phút (300 giây)
}

-- Đọc alias tối ưu: Chỉ đọc tối đa 15 dòng đầu của file
local function get_alias_from_file(filepath)
  local f = io.open(filepath, "r")
  if not f then
    return nil
  end

  local alias = nil
  local in_aliases = false
  local line_count = 0

  for line in f:lines() do
    line_count = line_count + 1
    if line_count > 15 then
      break
    end -- Giới hạn đọc tối đa 15 dòng đầu

    if line:match("^aliases:") then
      in_aliases = true
    elseif in_aliases then
      local found = line:match("^%s*-%s*(.+)")
      if found then
        alias = found
        break
      end
      if not line:match("^%s") then
        break
      end
    end
  end
  f:close()
  return alias
end

-- Quét Vault và lưu vào Cache
local function scan_vault_notes()
  local now = os.time()
  -- Nếu cache còn hạn, sử dụng luôn để không bị đơ máy
  if
    #completion_cache.data > 0
    and (now - completion_cache.last_updated) < completion_cache.cache_duration
  then
    return completion_cache.data
  end

  local notes = {}
  local vault_path = vault.get_path()
  local cmd = string.format("cd '%s' && fd -e md . --exclude .git --exclude .obsidian", vault_path)
  local raw = vim.fn.systemlist(cmd)

  for _, path_item in ipairs(raw) do
    local rel_path = path_item:gsub("^/", "")
    local fname = vim.fn.fnamemodify(rel_path, ":t:r")
    local title = get_alias_from_file(vault_path .. "/" .. rel_path) or fname

    table.insert(notes, { rel_path = rel_path, title = title, filename = fname })
  end

  -- Cập nhật Cache
  completion_cache.data = notes
  completion_cache.last_updated = now
  return notes
end

local function open_link_picker()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  local notes = scan_vault_notes()
  if #notes == 0 then
    vim.notify("Vault trống!", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, n in ipairs(notes) do
    table.insert(items, string.format("%-30s │ %s", n.title, n.rel_path))
  end

  vim.ui.select(
    items,
    { prompt = "🔗 Chọn note (Đường dẫn tương đối):" },
    function(_, idx)
      if not idx then
        return
      end
      local note = notes[idx]

      vim.ui.input(
        { prompt = "Tiêu đề hiển thị: ", default = note.title },
        function(input_title)
          if not input_title or input_title == "" then
            return
          end

          local styles = {
            "Wikilink  →  [[" .. note.filename .. "|" .. input_title .. "]]",
            "Markdown  →  [" .. input_title .. "](" .. note.rel_path .. ")",
          }

          vim.ui.select(styles, { prompt = "Định dạng:" }, function(_, style_idx)
            if not style_idx then
              return
            end

            local final_link = ""
            if style_idx == 1 then
              final_link = string.format("[[%s|%s]]", note.filename, input_title)
            else
              local encoded_path = note.rel_path:gsub(" ", "%%20")
              final_link = string.format("[%s](%s)", input_title, encoded_path)
            end

            vim.schedule(function()
              -- Dùng nvim_put để chèn ký tự chuẩn xác và hỗ trợ Undo sạch sẽ
              vim.api.nvim_win_set_cursor(0, { row, col })
              vim.api.nvim_put({ final_link }, "c", true, true)
              vim.cmd("startinsert!")
            end)
          end)
        end
      )
    end
  )
end

-- Keymapping
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set("i", "[[", open_link_picker, { buffer = true, desc = "Insert vault link" })
    vim.keymap.set(
      "n",
      "<leader>jl",
      open_link_picker,
      { buffer = true, desc = "Insert vault link" }
    )
  end,
})
