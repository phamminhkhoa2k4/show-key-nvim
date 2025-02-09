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
    title = "  DELETE SHORTCUT ",
    title_pos = "center",
    footer = "  j/k: Move | Enter: Delete | Backspace: Undo | Esc: Close ",
    footer_pos = "center",
  })

  local hl_win = "Normal:ShowKeyNormal,FloatBorder:ShowKeyBorder,CursorLine:ShowKeySelectedBorder"
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

  if #shortcuts == 0 then
    table.insert(lines, "  ∅ No shortcuts found")
  else
    for _, s in ipairs(shortcuts) do
      local title = s.title or s.desc or "No Title"
      local line = string.format("  %-30s  [%s]", title, s.keys)
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
    local row = i + 1 -- 0-indexed, +2 for header+sep, -1
    -- Highlight keys portion (approximate)
    local s = shortcuts[i]
    local title = s.title or s.desc or "No Title"
    local title_w = 2 + vim.api.nvim_strwidth(title)
    vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardTitle", row, 2, 2 + #(s.title or s.desc or "No Title"))
    vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyBadge", row, 34 + 3, -1)
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

  -- Navigation: raw j/k (let Neovim handle cursor movement natively)
  vim.keymap.set("n", "j", function()
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
    local cur = vim.api.nvim_win_get_cursor(M.win)
    local next_row = math.min(cur[1] + 1, #M.current_list + 2)
    next_row = math.max(next_row, 3) -- Don't go above first item row
    vim.api.nvim_win_set_cursor(M.win, { next_row, 0 })
  end, opts)

  vim.keymap.set("n", "k", function()
    if not M.win or not vim.api.nvim_win_is_valid(M.win) then return end
    local cur = vim.api.nvim_win_get_cursor(M.win)
    local next_row = math.max(cur[1] - 1, 3) -- Minimum row is 3 (first item)
    vim.api.nvim_win_set_cursor(M.win, { next_row, 0 })
  end, opts)

  -- Delete
  vim.keymap.set("n", "<CR>", function()
    local idx = M.get_selected_idx()
    if not idx then return end
    local item = M.current_list[idx]
    if item then
      registry.remove(item.keys)
      M.render()
      -- Re-clamp cursor
      if M.win and vim.api.nvim_win_is_valid(M.win) then
        local cur = vim.api.nvim_win_get_cursor(M.win)
        local max_row = math.max(3, #M.current_list + 2)
        vim.api.nvim_win_set_cursor(M.win, { math.min(cur[1], max_row), 0 })
      end
      vim.notify("Deleted: " .. (item.title or item.keys), vim.log.levels.INFO)
    end
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
