local config = require("show-key.config")
local registry = require("show-key.registry")

local M = {}

M.buf = nil
M.win = nil
M.filter_text = ""
M.selected_idx = 1

---Create the floating window
function M.create_window()
  local stats = vim.api.nvim_list_uis()[1]
  local width = math.floor(stats.width * config.options.width)
  local height = math.floor(stats.height * config.options.height)
  local row = math.floor((stats.height - height) / 2)
  local col = math.floor((stats.width - width) / 2)

  M.buf = vim.api.nvim_create_buf(false, true)
  
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = config.options.border,
    title = " " .. config.options.title .. " ",
    title_pos = "center",
  }

  M.win = vim.api.nvim_open_win(M.buf, true, win_opts)
  
  -- Set options for the buffer
  vim.api.nvim_buf_set_option(M.buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(M.buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(M.buf, "modifiable", false)

  M.setup_keymaps()
  M.render()
end

---Setup highlighting groups
function M.setup_highlights()
  vim.api.nvim_set_hl(0, "ShowKeyHeader", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeyGroup", { fg = "#bb9af7", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeyCardTitle", { fg = "#c0caf5", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeyCardDesc", { fg = "#565f89", italic = true })
  vim.api.nvim_set_hl(0, "ShowKeyBadge", { bg = "#3b4261", fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeySelected", { bg = "#292e42", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeySearchIcon", { fg = "#7aa2f7" })
end

---Setup keymaps for the floating window
function M.setup_keymaps()
  local opts = { buffer = M.buf, nowait = true }
  
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  
  vim.keymap.set("n", "j", function()
    M.selected_idx = math.min(M.selected_idx + 1, #M.get_filtered_shortcuts())
    M.render()
  end, opts)
  
  vim.keymap.set("n", "k", function()
    M.selected_idx = math.max(M.selected_idx - 1, 1)
    M.render()
  end, opts)
  
  vim.keymap.set("n", "<CR>", M.execute_selected, opts)

  -- Search handling: capture any printable character
  local exclude = { j = true, k = true, q = true }
  for i = 32, 126 do
    local char = string.char(i)
    if not exclude[char] then
      vim.keymap.set("n", char, function()
        M.filter_text = M.filter_text .. char
        M.selected_idx = 1
        M.render()
      end, opts)
    end
  end
  
  vim.keymap.set("n", "<BS>", function()
    M.filter_text = M.filter_text:sub(1, -2)
    M.selected_idx = 1
    M.render()
  end, opts)
end

---Get shortcuts filtered by filter_text
function M.get_filtered_shortcuts()
  local all = registry.get_all()
  if M.filter_text == "" then return all end
  
  local filtered = {}
  local query = M.filter_text:lower()
  for _, s in ipairs(all) do
    if s.keys:lower():find(query) or s.desc:lower():find(query) or s.group:lower():find(query) then
      table.insert(filtered, s)
    end
  end
  return filtered
end

---Render the shortcuts into the buffer
function M.render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end
  
  vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
  M.setup_highlights()
  
  local ns = vim.api.nvim_create_namespace("show-key")
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)

  local shortcuts = M.get_filtered_shortcuts()
  local lines = {}
  local win_width = vim.api.nvim_win_get_width(M.win)

  -- 1. Search Bar
  table.insert(lines, string.rep(" ", 2) .. "  " .. (M.filter_text == "" and "Type to search... (e.g., <leader>ff)" or M.filter_text))
  table.insert(lines, string.rep(" ", 2) .. string.rep("─", win_width - 4))
  table.insert(lines, "")

  local current_row = 3
  
  if #shortcuts == 0 then
    table.insert(lines, "    ∅ No shortcuts found")
    vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardDesc", current_row, 4, -1)
  else
    local current_group = ""
    for i, s in ipairs(shortcuts) do
      if s.group ~= current_group then
        current_group = s.group
        table.insert(lines, "  " .. current_group:upper())
        table.insert(lines, "")
        
        -- Highlight group header
        vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyGroup", current_row, 2, -1)
        current_row = current_row + 2
      end
      
      local is_selected = (i == M.selected_idx)
      local title_str = "    " .. s.desc
      local keys_str = s.keys
      
      -- Padding for the card
      local pad = win_width - #title_str - #keys_str - 8
      local line = title_str .. string.rep(" ", math.max(1, pad)) .. keys_str
      table.insert(lines, line)
      table.insert(lines, "") -- Spacer between cards

      -- Add highlights for the card
      if is_selected then
        vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeySelected", current_row, 0, -1)
      end
      
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyCardTitle", current_row, 4, #title_str)
      
      -- Badge for keys
      vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeyBadge", current_row, win_width - #keys_str - 4, win_width - 4)

      current_row = current_row + 2
    end
  end

  -- Search icon highlight
  vim.api.nvim_buf_add_highlight(M.buf, ns, "ShowKeySearchIcon", 0, 2, 5)

  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(M.buf, "modifiable", false)
end

---Close the window
function M.close()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, true)
  end
  M.win = nil
  M.buf = nil
end

---Execute the selected shortcut
function M.execute_selected()
  local selection = M.get_filtered_shortcuts()[M.selected_idx]
  M.close()
  
  if selection and selection.action then
    if type(selection.action) == "function" then
      selection.action()
    else
      vim.cmd(selection.action)
    end
  end
end

return M
