local registry = require("show-key.registry")

local M = {}

M.buf = nil
M.win = nil
M.filter_text = ""
M.current_list = {} -- Tracks the sorted filtered list

function M.open()
  M.filter_text = ""
  M.current_list = {}

  local screen_w = vim.o.columns
  local screen_h = vim.o.lines
  local width = 64
  local height = 22
  local row = math.floor((screen_h - height) / 2)
  local col = math.floor((screen_w - width) / 2)

  M.buf = vim.api.nvim_create_buf(false, true)
  M.win = vim.api.nvim_open_win(M.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " 󰌌  DELETE SHORTCUT ",
    title_pos = "center",
    footer = " <Tab>: Next | <S-Tab>: Prev | <CR>: Delete | <Esc>: Close ",
    footer_pos = "center",
  })

  local hl_win = "Normal:ShowKeyNormal,FloatBorder:ShowKeyBorder,CursorLine:ShowKeySelectedBorder,FloatTitle:ShowKeyHeader,FloatFooter:ShowKeyCardDesc"
  vim.api.nvim_win_set_option(M.win, "winhighlight", hl_win)
  vim.api.nvim_win_set_option(M.win, "cursorline", true)
  vim.api.nvim_win_set_option(M.win, "wrap", false)

  M.setup_keymaps()
  M.render()
  -- Place cursor on first content line (after search header)
  if vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_set_cursor(M.win, { 3, 0 })
  end
end

function M.get_filtered()
  local all = registry.get_all()
  if M.filter_text == "" then return all end
  local filtered = {}
  local query = M.filter_text:lower()
  for _, s in ipairs(all) do
    local t = (s.title or ""):lower()
    local k = (s.keys or ""):lower()
    local d = (s.desc or ""):lower()
    if t:find(query, 1, true) or k:find(query, 1, true) or d:find(query, 1, true) then
      table.insert(filtered, s)
    end
  end
  return filtered
end

function M.render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end
  vim.api.nvim_buf_set_option(M.buf, "modifiable", true)

  local ns = vim.api.nvim_create_namespace("show-key-delete")
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)

  local prompt = M.filter_text == "" and "Search: _" or ("Search: " .. M.filter_text .. "_")
  local sep = string.rep("─", 62)
  local lines = { prompt, sep }

  local shortcuts = M.get_filtered()
  M.current_list = shortcuts

  -- Get selected index from cursor if possible, else default to 1
  local selected_idx = 1
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    local cur = vim.api.nvim_win_get_cursor(M.win)
    selected_idx = math.max(1, math.min(#shortcuts, cur[1] - 2))
  end

  if #shortcuts == 0 then
    table.insert(lines, "  ∅ No shortcuts found")
  else
    for i, s in ipairs(shortcuts) do
      local title = s.title or s.desc or "No Title"
      local prefix = (i == selected_idx) and " ❯ " or "   "
      local line = string.format("%s%-27s  [%s]", prefix, title, s.keys)
      -- Pad line to full width
      line = line .. string.rep(" ", math.max(0, 62 - vim.api.nvim_strwidth(line)))
      table.insert(lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)

  -- Highlights
  if M.filter_text == "" then
    vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardDesc", 0, 0, -1)
  else
    vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyHeader", 0, 8, 8 + #M.filter_text)
    vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardDesc", 0, 0, 8)
  end
  vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyBorder", 1, 0, -1)

  for i = 1, #shortcuts do
    local row = i + 1
    local s = shortcuts[i]
    if i == selected_idx then
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyGroup", row, 0, 4)
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardTitle", row, 4, 4 + #(s.title or s.desc or "No Title"))
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyBadge", row, 34 + 3, -1)
    else
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardDesc", row, 4, 4 + #(s.title or s.desc or "No Title"))
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyBadge", row, 34 + 3, -1)
    end
  end

  vim.api.nvim_buf_set_option(M.buf, "modifiable", false)
end

function M.get_selected_idx()
  if not M.win or not vim.api.nvim_win_is_valid(M.win) then return nil end
  local cur = vim.api.nvim_win_get_cursor(M.win)
  local row = cur[1] -- 1-indexed
  -- Row 1 = search prompt, Row 2 = separator, Row 3+ = items
  local idx = row - 2
  if idx < 1 or idx > #M.current_list then return nil end
  return idx
end

function M.setup_keymaps()
  local opts = { buffer = M.buf, nowait = true, silent = true }

  -- Navigation: Tab/Shift-Tab (j/k removed as per request)
  vim.keymap.set("n", "<Tab>", function()
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
    local cur = vim.api.nvim_win_get_cursor(M.win)
    local next_row = cur[1] + 1
    if next_row > #M.current_list + 2 then next_row = 3 end -- Loop back
    vim.api.nvim_win_set_cursor(M.win, { next_row, 0 })
    M.render()
  end, opts)

  vim.keymap.set("n", "<S-Tab>", function()
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
    local cur = vim.api.nvim_win_get_cursor(M.win)
    local next_row = cur[1] - 1
    if next_row < 3 then next_row = #M.current_list + 2 end -- Loop to bottom
    vim.api.nvim_win_set_cursor(M.win, { next_row, 0 })
    M.render()
  end, opts)

  -- Delete with confirmation
  vim.keymap.set("n", "<CR>", function()
    local idx = M.get_selected_idx()
    if not idx then return end
    local item = M.current_list[idx]
    if not item then return end

    local screen_w = vim.o.columns
    local screen_h = vim.o.lines
    local width = 44
    local height = 6
    local row = math.floor((screen_h - height) / 2)
    local col = math.floor((screen_w - width) / 2)

    local c_buf = vim.api.nvim_create_buf(false, true)
    local c_win = vim.api.nvim_open_win(c_buf, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = " CONFIRM ",
      title_pos = "center",
      footer = " <Tab>: Toggle | <CR>: Confirm ",
      footer_pos = "center",
    })

    vim.api.nvim_win_set_option(c_win, "winhighlight", "Normal:ShowKeyNormal,FloatBorder:ShowKeyBorder,FloatTitle:ShowKeyHeader,CursorLine:ShowKeySelectedBorder,FloatFooter:ShowKeyCardDesc")
    vim.api.nvim_win_set_option(c_win, "cursorline", true)
    vim.api.nvim_win_set_option(c_win, "winblend", 0)

    local function render_confirm(choice)
      vim.api.nvim_buf_set_option(c_buf, "modifiable", true)
      local yes_prefix = (choice == "YES") and " ❯ " or "   "
      local no_prefix = (choice == "NO") and " ❯ " or "   "
      local lines = {
        string.format("  Delete shortcut: %s?", item.keys),
        "",
        string.format("%sYES", yes_prefix),
        string.format("%sNO", no_prefix),
        "",
      }
      vim.api.nvim_buf_set_lines(c_buf, 0, -1, false, lines)
      
      local ns = vim.api.nvim_create_namespace("show-key-confirm")
      vim.api.nvim_buf_clear_namespace(c_buf, ns, 0, -1)
      if choice == "YES" then
        vim.api.nvim_buf_add_highlight(c_buf, ns, "ShowKeyGroup", 2, 0, 4)
        vim.api.nvim_buf_add_highlight(c_buf, ns, "ShowKeyHeader", 2, 4, -1)
      else
        vim.api.nvim_buf_add_highlight(c_buf, ns, "ShowKeyGroup", 3, 0, 4)
        vim.api.nvim_buf_add_highlight(c_buf, ns, "ShowKeyHeader", 3, 4, -1)
      end
      vim.api.nvim_buf_set_option(c_buf, "modifiable", false)
      vim.api.nvim_win_set_cursor(c_win, { (choice == "YES") and 3 or 4, 0 })
    end

    local current_choice = "NO"
    render_confirm(current_choice)

    local function close_confirm()
      if vim.api.nvim_win_is_valid(c_win) then vim.api.nvim_win_close(c_win, true) end
    end

    local c_opts = { buffer = c_buf, nowait = true, silent = true }
    
    -- Navigation: Tab/Shift-Tab
    vim.keymap.set("n", "<Tab>", function()
      current_choice = (current_choice == "YES") and "NO" or "YES"
      render_confirm(current_choice)
    end, c_opts)
    vim.keymap.set("n", "<S-Tab>", function()
      current_choice = (current_choice == "YES") and "NO" or "YES"
      render_confirm(current_choice)
    end, c_opts)

    vim.keymap.set("n", "<CR>", function()
      close_confirm()
      if current_choice == "YES" then
        registry.remove(item.keys)
        M.render()
        if M.win and vim.api.nvim_win_is_valid(M.win) then
          local cur = vim.api.nvim_win_get_cursor(M.win)
          local max_row = math.max(3, #M.current_list + 2)
          vim.api.nvim_win_set_cursor(M.win, { math.min(cur[1], max_row), 0 })
        end
        vim.notify("Deleted: " .. (item.title or item.keys), vim.log.levels.INFO)
      end
    end, c_opts)

    vim.keymap.set("n", "<Esc>", close_confirm, c_opts)
    vim.keymap.set("n", "q", close_confirm, c_opts)
  end, opts)

  -- Search
  local search_exclude = { j = true, k = true, q = true }
  for i = 32, 126 do
    local char = string.char(i)
    if not search_exclude[char] then
      vim.keymap.set("n", char, function()
        M.filter_text = M.filter_text .. char
        M.render()
        -- Reset cursor to first item after search
        if M.win and vim.api.nvim_win_is_valid(M.win) then
          vim.api.nvim_win_set_cursor(M.win, { 3, 0 })
        end
      end, opts)
    end
  end

  vim.keymap.set("n", "<BS>", function()
    if #M.filter_text > 0 then
      M.filter_text = M.filter_text:sub(1, -2)
      M.render()
      if M.win and vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_set_cursor(M.win, { 3, 0 })
      end
    end
  end, opts)

  vim.keymap.set("n", "<Esc>", M.close, opts)
  vim.keymap.set("n", "q", M.close, opts)
end

function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win, M.buf = nil, nil
end

return M
