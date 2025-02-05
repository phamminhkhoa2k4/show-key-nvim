local config = require("show-key.config")
local registry = require("show-key.registry")

local M = {}

M.header_buf = nil
M.header_win = nil
M.body_buf = nil
M.body_win = nil

M.filter_text = ""
M.selected_idx = 1

---Create the floating windows
function M.create_window()
  M.filter_text = ""
  M.selected_idx = 1

  local stats = vim.api.nvim_list_uis()[1]
  local total_width = math.floor(stats.width * config.options.width)
  local total_height = math.floor(stats.height * config.options.height)
  
  local header_height = 3
  local body_height = math.max(1, total_height - header_height)

  local row = math.floor((stats.height - total_height) / 2)
  local col = math.floor((stats.width - total_width) / 2)

  -- 1. Create Header Window
  M.header_buf = vim.api.nvim_create_buf(false, true)
  local header_opts = {
    relative = "editor",
    width = total_width,
    height = header_height,
    row = row,
    col = col,
    style = "minimal",
    border = { "╭", "─", "╮", "│", "", "", "", "│" }, -- Only top borders
    title = " " .. config.options.title .. " ",
    title_pos = "center",
  }
  M.header_win = vim.api.nvim_open_win(M.header_buf, false, header_opts)

  -- 2. Create Body Window
  M.body_buf = vim.api.nvim_create_buf(false, true)
  local body_opts = {
    relative = "editor",
    width = total_width,
    height = body_height,
    row = row + header_height + 1, -- +1 for border adjustment
    col = col,
    style = "minimal",
    border = { "", "", "", "│", "╯", "─", "╰", "│" }, -- Only bottom borders
  }
  
  -- Adjust for combined border look
  if config.options.border == "none" then
    header_opts.border = "none"
    body_opts.border = "none"
    body_opts.row = row + header_height
  end

  M.body_win = vim.api.nvim_open_win(M.body_buf, true, body_opts)

  -- Set buffer options
  for _, b in ipairs({ M.header_buf, M.body_buf }) do
    vim.api.nvim_buf_set_option(b, "buftype", "nofile")
    vim.api.nvim_buf_set_option(b, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(b, "modifiable", false)
  end

  -- Specialized highlights for transparency
  M.setup_highlights()
  
  local win_hl = "Normal:ShowKeyNormal,FloatBorder:ShowKeyBorder"
  vim.api.nvim_win_set_option(M.header_win, "winhighlight", win_hl)
  vim.api.nvim_win_set_option(M.body_win, "winhighlight", win_hl)

  -- Transparency
  if config.options.transparent then
    vim.api.nvim_win_set_option(M.header_win, "winblend", 0)
    vim.api.nvim_win_set_option(M.body_win, "winblend", 0)
  end

  M.setup_keymaps()
  M.render()
end

---Setup highlighting groups
function M.setup_highlights()
  local bg = config.options.transparent and "NONE" or "#1f2335"
  
  vim.api.nvim_set_hl(0, "ShowKeyNormal", { bg = bg })
  vim.api.nvim_set_hl(0, "ShowKeyBorder", { bg = bg, fg = "#7aa2f7" })
  vim.api.nvim_set_hl(0, "ShowKeyHeader", { fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeyGroup", { fg = "#bb9af7", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeyCardTitle", { fg = "#c0caf5", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeyCardDesc", { fg = "#565f89", italic = true })
  vim.api.nvim_set_hl(0, "ShowKeyBadge", { bg = "#3b4261", fg = "#7aa2f7", bold = true })
  vim.api.nvim_set_hl(0, "ShowKeySelected", { bg = "#364a82", bold = true }) -- Brighter highlight
  vim.api.nvim_set_hl(0, "ShowKeySearchIcon", { fg = "#7aa2f7" })
end

---Setup keymaps
function M.setup_keymaps()
  local opts = { buffer = M.body_buf, nowait = true, silent = true }
  
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  
  vim.keymap.set("n", "j", function()
    local shortcuts = M.get_filtered_shortcuts()
    if #shortcuts == 0 then return end
    M.selected_idx = math.min(M.selected_idx + 1, #shortcuts)
    M.render_body()
  end, opts)
  
  vim.keymap.set("n", "k", function()
    local shortcuts = M.get_filtered_shortcuts()
    if #shortcuts == 0 then return end
    M.selected_idx = math.max(M.selected_idx - 1, 1)
    M.render_body()
  end, opts)

  -- Search handling: capture almost any printable character and common symbols
  local exclude = { j = true, k = true, q = true }
  -- ASCII Printable range
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
    if #M.filter_text > 0 then
      M.filter_text = M.filter_text:sub(1, -2)
      M.selected_idx = 1
      M.render()
    end
  end, opts)
end

function M.get_filtered_shortcuts()
  local all = registry.get_all()
  if not M.filter_text or M.filter_text == "" then return all end
  
  local filtered = {}
  local query = M.filter_text:lower()
  for _, s in ipairs(all) do
    local keys = (s.keys or ""):lower()
    local title = (s.title or ""):lower()
    local desc = (s.desc or ""):lower()
    local group = (s.group or ""):lower()
    
    if keys:find(query, 1, true) or 
       title:find(query, 1, true) or 
       desc:find(query, 1, true) or 
       group:find(query, 1, true) then
      table.insert(filtered, s)
    end
  end
  return filtered
end

function M.render()
  M.render_header()
  M.render_body()
end

function M.render_header()
  if not M.header_buf or not vim.api.nvim_buf_is_valid(M.header_buf) then return end
  vim.api.nvim_buf_set_option(M.header_buf, "modifiable", true)
  
  local win_width = vim.api.nvim_win_get_width(M.header_win)
  local search_prompt = M.filter_text == "" and "Type to search..." or M.filter_text
  local lines = {
    string.rep(" ", 2) .. "  " .. search_prompt,
    string.rep(" ", 2) .. string.rep("─", win_width - 4),
    ""
  }
  
  vim.api.nvim_buf_set_lines(M.header_buf, 0, -1, false, lines)
  
  local ns = vim.api.nvim_create_namespace("show-key-header")
  vim.api.nvim_buf_clear_namespace(M.header_buf, ns, 0, -1)
  
  -- Highlight search icon ( is usually 3 bytes in UTF-8)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeySearchIcon", 0, 2, 5)
  
  -- If searching, highlight the search text
  if M.filter_text ~= "" then
    vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyHeader", 0, 7, -1)
  else
    vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyCardDesc", 0, 7, -1)
  end
  
  vim.api.nvim_buf_set_option(M.header_buf, "modifiable", false)
end

function M.render_body()
  if not M.body_buf or not vim.api.nvim_buf_is_valid(M.body_buf) then return end
  vim.api.nvim_buf_set_option(M.body_buf, "modifiable", true)
  
  local ns = vim.api.nvim_create_namespace("show-key-body")
  vim.api.nvim_buf_clear_namespace(M.body_buf, ns, 0, -1)

  local shortcuts = M.get_filtered_shortcuts()
  local lines = {}
  local hls = {} -- To store highlight info {row, col_start, col_end, hl_group}
  local selected_row = nil
  local win_width = vim.api.nvim_win_get_width(M.body_win)

  local current_row = 0
  if #shortcuts == 0 then
    table.insert(lines, "    ∅ No shortcuts found")
    table.insert(hls, { 0, 4, -1, "ShowKeyCardDesc" })
  else
    local current_group = ""
    for i, s in ipairs(shortcuts) do
      if s.group ~= current_group then
        current_group = s.group
        table.insert(lines, "  " .. current_group:upper())
        table.insert(lines, "")
        table.insert(hls, { current_row, 2, -1, "ShowKeyGroup" })
        current_row = current_row + 2
      end
      
      local is_selected = (i == M.selected_idx)
      local title_text = s.title or s.desc
      local title_str = "    " .. title_text
      local desc_str = "      " .. (s.title and s.desc or "")
      local keys_str = s.keys
      
      local pad = win_width - #title_str - #keys_str - 8
      table.insert(lines, title_str .. string.rep(" ", math.max(1, pad)) .. keys_str)
      table.insert(hls, { current_row, 4, #title_str, "ShowKeyCardTitle" })
      table.insert(hls, { current_row, win_width - #keys_str - 4, win_width - 4, "ShowKeyBadge" })

      if s.title and s.desc then
        table.insert(lines, desc_str)
        table.insert(lines, "")
        table.insert(hls, { current_row + 1, 6, -1, "ShowKeyCardDesc" })
      else
        table.insert(lines, "")
      end

      if is_selected then
        selected_row = current_row + 1
        table.insert(hls, { current_row, 0, -1, "ShowKeySelected" })
        if s.title and s.desc then
          table.insert(hls, { current_row + 1, 0, -1, "ShowKeySelected" })
        end
      end
      
      current_row = (s.title and s.desc) and current_row + 3 or current_row + 2
    end
  end

  vim.api.nvim_buf_set_lines(M.body_buf, 0, -1, false, lines)
  
  -- Apply highlights
  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(M.body_buf, ns, hl[4], hl[1], hl[2], hl[3])
  end

  -- Set cursor for auto-scroll
  if selected_row and M.body_win and vim.api.nvim_win_is_valid(M.body_win) then
    vim.api.nvim_win_set_cursor(M.body_win, { math.min(selected_row, #lines), 0 })
  end

  vim.api.nvim_buf_set_option(M.body_buf, "modifiable", false)
end

function M.close()
  if M.header_win and vim.api.nvim_win_is_valid(M.header_win) then
    vim.api.nvim_win_close(M.header_win, true)
  end
  if M.body_win and vim.api.nvim_win_is_valid(M.body_win) then
    vim.api.nvim_win_close(M.body_win, true)
  end
  M.header_win, M.body_win = nil, nil
  M.header_buf, M.body_buf = nil, nil
end

return M
