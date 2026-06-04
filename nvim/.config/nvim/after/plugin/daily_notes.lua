-- =============================================================================
-- CẤU HÌNH OBSIDIAN PURE LUA (TỐI ƯU HÓA UTF-8 TIẾNG VIỆT & HÀNH VI CHÈN LINK)
-- =============================================================================

local vault = require("utils.vault")

-- 1. Hàm sinh ID theo chuẩn Timestamp
local function generate_timestamp_id()
  return os.date("%Y%m%d%H%M")
end

-- 2. Hàm chuyển tiếng Việt có dấu sang không dấu (Đã tối ưu hóa thuật toán duyệt UTF-8)
local function to_slug(str)
  if not str then
    return ""
  end

  str = vim.fn.tolower(str)

  local map = {
    ["à"] = "a",
    ["á"] = "a",
    ["ạ"] = "a",
    ["ả"] = "a",
    ["ã"] = "a",
    ["â"] = "a",
    ["ầ"] = "a",
    ["ấ"] = "a",
    ["ậ"] = "a",
    ["ẩ"] = "a",
    ["ẫ"] = "a",
    ["ă"] = "a",
    ["ằ"] = "a",
    ["ắ"] = "a",
    ["ặ"] = "a",
    ["ẳ"] = "a",
    ["ẵ"] = "a",
    ["è"] = "e",
    ["é"] = "e",
    ["ẹ"] = "e",
    ["ẻ"] = "e",
    ["ẽ"] = "e",
    ["ê"] = "e",
    ["ề"] = "e",
    ["ế"] = "e",
    ["ệ"] = "e",
    ["ể"] = "e",
    ["ễ"] = "e",
    ["ì"] = "i",
    ["í"] = "i",
    ["ị"] = "i",
    ["ỉ"] = "i",
    ["ĩ"] = "i",
    ["ò"] = "o",
    ["ó"] = "o",
    ["ọ"] = "o",
    ["ỏ"] = "o",
    ["õ"] = "o",
    ["ô"] = "o",
    ["ồ"] = "o",
    ["ố"] = "o",
    ["ộ"] = "o",
    ["ổ"] = "o",
    ["ỗ"] = "o",
    ["ơ"] = "o",
    ["ờ"] = "o",
    ["ớ"] = "o",
    ["ợ"] = "o",
    ["ở"] = "o",
    ["ỡ"] = "o",
    ["ù"] = "u",
    ["ú"] = "u",
    ["ụ"] = "u",
    ["ủ"] = "u",
    ["ũ"] = "u",
    ["ư"] = "u",
    ["ừ"] = "u",
    ["ứ"] = "u",
    ["ự"] = "u",
    ["ử"] = "u",
    ["ữ"] = "u",
    ["ỳ"] = "y",
    ["ý"] = "y",
    ["ỵ"] = "y",
    ["ỷ"] = "y",
    ["ỹ"] = "y",
    ["đ"] = "d",
  }

  local result = {}
  -- Sử dụng Regex Pattern của Lua để duyệt từng ký tự UTF-8 (Nhanh và không lỗi)
  for char in str:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    table.insert(result, map[char] or char)
  end

  str = table.concat(result)
  -- Lọc bỏ ký tự đặc biệt, thay khoảng trắng bằng gạch ngang
  str = str:gsub("[^a-z0-9]", "-"):gsub("%-+", "-"):gsub("^%-", ""):gsub("%-$", "")
  return str
end

-- =============================================================================
-- PHẦN 1: DAILY NOTES (:Daily)
-- =============================================================================

local function create_daily_note()
  local vault_path = vault.get_path()
  vim.cmd("cd " .. vim.fn.fnameescape(vault_path))

  local filename = os.date("%Y-%m-%d-%A") .. ".md"
  local year, month = os.date("%Y"), os.date("%m")
  local sub_dir = "1-Journal/" .. year .. "/" .. month
  local full_path = sub_dir .. "/" .. filename

  if vim.fn.isdirectory(sub_dir) == 0 then
    vim.fn.mkdir(sub_dir, "p")
  end

  vim.cmd("edit " .. vim.fn.fnameescape(full_path))
end

local function insert_daily_template()
  local lines_check = vim.api.nvim_buf_get_lines(0, 0, 1, false)
  if #lines_check > 0 and lines_check[1] ~= "" then
    return
  end

  local filename = vim.fn.expand("%:t:r")
  local y, m, d = string.match(filename, "^(%d+)-(%d+)-(%d+)")
  if not y then
    return
  end

  local t = os.time({ year = y, month = m, day = d })
  local timestamp_id = generate_timestamp_id()
  local date_slug = os.date("%Y-%m-%d-%A", t)
  local full_id = timestamp_id .. "-" .. date_slug

  local function make_link(timestamp)
    local label = os.date("%Y-%m-%d", timestamp)
    local path = string.format(
      "1-Journal/%s/%s/%s.md",
      os.date("%Y", timestamp),
      os.date("%m", timestamp),
      os.date("%Y-%m-%d-%A", timestamp)
    )
    return string.format("[%s](%s)", label, path)
  end

  local lines = {
    "---",
    "id: " .. full_id,
    "aliases:",
    "  - " .. date_slug,
    "tags:",
    "  - daily",
    "date: " .. os.date("%Y-%m-%d", t),
    "---",
    "",
    "# " .. os.date("%A, %d %B %Y", t),
    "",
    "<< " .. make_link(t - 86400) .. " | " .. make_link(t + 86400) .. " >>",
    "",
    "## 📝 Notes",
    "- ",
    "",
    "## ✅ Tasks",
    "- [ ] ",
  }

  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.cmd("normal! G$")
  vim.cmd("write")
end

-- =============================================================================
-- PHẦN 2: NEW NOTE TỪ 0-INBOX
-- =============================================================================

local function create_inbox_note()
  vim.ui.input({ prompt = "New Note Title (Vietnamese OK): " }, function(input)
    if not input or input == "" then
      return
    end

    local clean_title = to_slug(input)
    local timestamp_id = generate_timestamp_id()
    local full_id = timestamp_id .. "-" .. clean_title
    local filename = full_id .. ".md"

    local vault_path = vault.get_path()
    local inbox_dir_rel = "0-Inbox"
    local full_path = vault_path .. "/" .. inbox_dir_rel .. "/" .. filename

    local content_lines = {
      "---",
      "id: " .. full_id,
      "aliases:",
      "  - " .. input,
      "date: " .. os.date("%Y-%m-%d"),
      "type: inbox-note",
      'summary: ""',
      "keywords: []",
      'status: "raw"',
      "---",
      "",
      "# " .. input,
      "",
      "## 🤖 AI Summary",
      "> ",
      "",
      "## 📝 Notes",
      "- ",
    }

    if vim.fn.isdirectory(vault_path .. "/" .. inbox_dir_rel) == 0 then
      vim.fn.mkdir(vault_path .. "/" .. inbox_dir_rel, "p")
    end

    if vim.fn.filereadable(full_path) == 1 then
      vim.notify("Note already exists!", vim.log.levels.WARN)
      return
    end

    vim.fn.writefile(content_lines, full_path)

    local rel_path = inbox_dir_rel .. "/" .. filename
    local link_text = "[" .. input .. "](" .. rel_path .. ")"

    if vim.bo.modifiable then
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local final_link = (line:match("^%s*$") and "" or " ") .. link_text

      -- Dùng nvim_put thay thế cho việc cắt chuỗi buffer thủ công
      vim.api.nvim_put({ final_link }, "c", true, true)
      vim.cmd("startinsert!")
    else
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
      vim.cmd("normal! Go")
      vim.cmd("startinsert!")
    end
  end)
end

local function insert_new_inbox_link()
  vim.ui.input({ prompt = "Tiêu đề ghi chú mới: " }, function(input)
    if not input or input == "" then
      return
    end

    local file_id = generate_timestamp_id() .. "-" .. to_slug(input)
    local wiki_link = string.format("[[%s|%s]]", file_id, input)

    local col = vim.api.nvim_win_get_cursor(0)[2]
    local line = vim.api.nvim_get_current_line()
    local char_under_cursor = line:sub(col + 1, col + 1)

    if char_under_cursor == "-" or line:sub(col, col) == "-" then
      wiki_link = " " .. wiki_link
    end

    vim.api.nvim_put({ wiki_link }, "c", true, true)
    vim.cmd("startinsert")
  end)
end

-- =============================================================================
-- PHẦN 3: XỬ LÝ FOLLOW LINK (BẰNG ENTER)
-- =============================================================================

local function follow_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local target = nil

  -- Tìm Wikilink
  local s_wiki, e_wiki = 1, 0
  while true do
    s_wiki, e_wiki = line:find("%[%[(.-)%]%]", e_wiki + 1)
    if not s_wiki then
      break
    end
    if col >= s_wiki and col <= e_wiki then
      target = line:sub(s_wiki + 2, e_wiki - 2)
      break
    end
  end

  -- Tìm Markdown link
  if not target then
    local s_md, e_md = 1, 0
    while true do
      s_md, e_md = line:find("%[(.-)%]%((.-)%)", e_md + 1)
      if not s_md then
        break
      end
      if col >= s_md and col <= e_md then
        local _, path = line:match("%[(.-)%]%((.-)%)", s_md)
        target = path
        break
      end
    end
  end

  -- Nếu không đứng trên link, trả về nút Enter mặc định
  if not target or target == "" then
    local key = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
    vim.api.nvim_feedkeys(key, "n", false)
    return
  end

  local vault_path = vault.get_path()
  local decoded_target = target:gsub("%%20", " ")
  local clean_name = vim.split(decoded_target, "|")[1]
  local name_no_ext = clean_name:gsub("%.md$", "")
  local slug = to_slug(name_no_ext)

  local direct_path = vault_path
    .. "/"
    .. (clean_name:match("%.md$") and clean_name or clean_name .. ".md")

  if vim.fn.filereadable(direct_path) == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(direct_path))
  else
    -- Sử dụng tìm kiếm fd tốc độ cao
    local find_cmd = string.format("cd '%s' && fd -e md '%s' | head -n 1", vault_path, slug)
    local found_rel_path = vim.fn.system(find_cmd):gsub("\n", "")

    if found_rel_path ~= "" then
      vim.cmd("edit " .. vim.fn.fnameescape(vault_path .. "/" .. found_rel_path))
    else
      -- Tạo mới note tự động nếu không tìm thấy
      local ts = generate_timestamp_id()
      local filename = ts .. "-" .. slug .. ".md"
      local new_path = vault_path .. "/0-Inbox/" .. filename

      if vim.fn.isdirectory(vault_path .. "/0-Inbox") == 0 then
        vim.fn.mkdir(vault_path .. "/0-Inbox", "p")
      end

      local lines = {
        "---",
        "id: " .. ts .. "-" .. slug,
        "aliases: [" .. name_no_ext .. "]",
        "date: " .. os.date("%Y-%m-%d"),
        "type: inbox-note",
        'summary: ""',
        "keywords: []",
        'status: "raw"',
        "---",
        "",
        "# " .. name_no_ext,
        "",
        "## 📝 Notes",
        "- ",
      }
      vim.fn.writefile(lines, new_path)
      vim.cmd("edit " .. vim.fn.fnameescape(new_path))
      vim.api.nvim_win_set_cursor(0, { #lines, 2 })
      vim.cmd("startinsert!")
    end
  end
end

-- =============================================================================
-- MAPPINGS & COMMANDS
-- =============================================================================

vim.api.nvim_create_user_command("Daily", create_daily_note, {})

vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*/1-Journal/*.md",
  callback = insert_daily_template,
})

vim.keymap.set("n", "<leader>jn", create_inbox_note, { desc = "Create new note in 0-Inbox" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.keymap.set(
      "n",
      "<leader>ni",
      insert_new_inbox_link,
      { buffer = true, desc = "Insert New Inbox Link" }
    )
    vim.keymap.set("n", "<CR>", follow_link, { buffer = true, silent = true })
  end,
})

vim.opt.conceallevel = 2
