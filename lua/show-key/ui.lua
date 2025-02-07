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
  
  local header_height = 5
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
    focusable = false, -- Prevent focus and scrolling
  }
  M.header_win = vim.api.nvim_open_win(M.header_buf, false, header_opts)
  vim.api.nvim_win_set_option(M.header_win, "winhighlight", "Normal:ShowKeyNormal,FloatBorder:ShowKeyBorder")
  vim.api.nvim_win_set_option(M.header_win, "scrolloff", 0)
  vim.api.nvim_win_set_option(M.header_win, "sidescrolloff", 0)
  vim.api.nvim_win_set_option(M.header_win, "wrap", false)
  vim.api.nvim_win_set_cursor(M.header_win, {1, 0}) -- Lock at top
  vim.api.nvim_win_set_option(M.header_win, "cursorline", false)
  vim.api.nvim_win_set_option(M.header_win, "cursorcolumn", false)
  -- 2. Create Body Window
  M.body_buf = vim.api.nvim_create_buf(false, true)
  local body_opts = {
    relative = "editor",
    width = total_width,
    height = body_height,
    row = row + header_height + 1, 
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

  -- Auto-close when focus leaves
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = M.body_buf,
    once = true,
    callback = function()
      M.close()
    end,
  })
end

---Setup highlighting groups
function M.setup_highlights()
  local bg = config.options.transparent and "NONE" or "#1f2335"
  local s = config.options.styles
  
  -- Base
  vim.api.nvim_set_hl(0, "ShowKeyNormal", { bg = bg })
  
  -- Dynamic styles from config
  vim.api.nvim_set_hl(0, "ShowKeyBorder", vim.tbl_extend("force", { bg = bg }, s.border))
  vim.api.nvim_set_hl(0, "ShowKeyHeader", s.header)
  vim.api.nvim_set_hl(0, "ShowKeyGroup", s.group)
  vim.api.nvim_set_hl(0, "ShowKeyCardTitle", s.card_title)
  vim.api.nvim_set_hl(0, "ShowKeyCardDesc", s.card_desc)
  vim.api.nvim_set_hl(0, "ShowKeyBadge", s.badge)
  vim.api.nvim_set_hl(0, "ShowKeyBracket", vim.tbl_extend("force", { bg = s.badge.bg or "NONE" }, s.key_bracket))
  vim.api.nvim_set_hl(0, "ShowKeySelected", { bg = "NONE" })
  vim.api.nvim_set_hl(0, "ShowKeySelectedBorder", vim.tbl_extend("force", { bg = bg }, s.selected_border))
  vim.api.nvim_set_hl(0, "ShowKeySearchIcon", s.search_icon)
end

---Setup keymaps
function M.setup_keymaps()
  local opts = { buffer = M.body_buf, nowait = true, silent = true }
  
  vim.keymap.set("n", "q", M.close, opts)
  vim.keymap.set("n", "<Esc>", M.close, opts)
  
  vim.keymap.set("n", "j", function()
    local shortcuts = M.get_filtered_shortcuts()
    if #shortcuts == 0 then return end
    M.selected_idx = math.min(M.selected_idx + 2, #shortcuts)
    M.render_body()
  end, opts)
  
  vim.keymap.set("n", "k", function()
    local shortcuts = M.get_filtered_shortcuts()
    if #shortcuts == 0 then return end
    M.selected_idx = math.max(M.selected_idx - 2, 1)
    M.render_body()
  end, opts)

  vim.keymap.set("n", "l", function()
    local shortcuts = M.get_filtered_shortcuts()
    if #shortcuts == 0 then return end
    -- Move to right if on left
    if M.selected_idx % 2 ~= 0 then
      M.selected_idx = math.min(M.selected_idx + 1, #shortcuts)
      M.render_body()
    end
  end, opts)

  vim.keymap.set("n", "h", function()
    local shortcuts = M.get_filtered_shortcuts()
    if #shortcuts == 0 then return end
    -- Move to left if on right
    if M.selected_idx % 2 == 0 then
      M.selected_idx = math.max(M.selected_idx - 1, 1)
      M.render_body()
    end
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
  
  local title_text = config.options.title:upper()
  local title_icon = "󰌌"
  local full_title = title_icon .. "  " .. title_text
  local title_padding = math.floor((win_width - vim.api.nvim_strwidth(full_title)) / 2)
  local title_line = string.rep(" ", title_padding) .. full_title
  
  local inner_width = win_width - 8
  local border_top = "  ╭" .. string.rep("─", inner_width) .. "╮"
  local search_line = "  │   " .. search_prompt .. string.rep(" ", math.max(0, inner_width - #search_prompt - 4)) .. "│"
  local border_bot = "  ╰" .. string.rep("─", inner_width) .. "╯"
  local separator = string.rep("─", win_width)

  local lines = {
    title_line,
    border_top,
    search_line,
    border_bot,
    separator
  }
  
  vim.api.nvim_buf_set_lines(M.header_buf, 0, -1, false, lines)
  
  local ns = vim.api.nvim_create_namespace("show-key-header")
  vim.api.nvim_buf_clear_namespace(M.header_buf, ns, 0, -1)
  
  -- Title Highlights (Row 0)
  local icon_start = title_padding
  local text_start_h = icon_start + #title_icon + 2
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyGroup", 0, icon_start, icon_start + #title_icon)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyHeader", 0, text_start_h, -1)
  
  -- Search Box Highlights (Rows 1, 2, 3)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyBorder", 1, 2, -1)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyBorder", 2, 2, 5) 
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyBorder", 2, win_width - 4, -1)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyBorder", 3, 2, -1)
  
  -- Highlight search icon (Row 2)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeySearchIcon", 2, 4, 7)
  
  -- Highlight search text (Row 2)
  local text_start = 9
  if M.filter_text ~= "" then
    vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyHeader", 2, text_start, text_start + #M.filter_text)
  else
    vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyCardDesc", 2, text_start, text_start + #search_prompt)
  end

  -- Separator Highlight (Row 4)
  vim.api.nvim_buf_add_highlight(M.header_buf, ns, "ShowKeyBorder", 4, 0, -1)
  
  vim.api.nvim_buf_set_option(M.header_buf, "modifiable", false)
end

function M.render_body()
  if not M.body_buf or not vim.api.nvim_buf_is_valid(M.body_buf) then return end
  vim.api.nvim_buf_set_option(M.body_buf, "modifiable", true)
  
  local ns = vim.api.nvim_create_namespace("show-key-body")
  vim.api.nvim_buf_clear_namespace(M.body_buf, ns, 0, -1)

  local shortcuts = M.get_filtered_shortcuts()
  local lines = {}
  local hls = {} 
  local selected_row = nil
  local win_width = vim.api.nvim_win_get_width(M.body_win)
  
  -- Calculate column width based on window width
  -- Left margin (2) | Card 1 | Separator (3) | Card 2 | Right margin (2)
  local col_width = math.floor((win_width - 7) / 2)
  local inner_w = col_width - 4

  local function get_card_lines(s)
    local title_text = s.title or s.desc
    local keys_str = "[" .. s.keys .. "]"
    local desc_text = s.title and s.desc or ""
    
    local sw = vim.api.nvim_strwidth
    
    -- Truncate title
    while sw(title_text) > (inner_w - sw(keys_str) - 2) do
      title_text = title_text:sub(1, #title_text - 1)
    end
    
    -- Truncate desc
    while sw(desc_text) > inner_w do
      desc_text = desc_text:sub(1, #desc_text - 1)
    end

    local top = "╭" .. string.rep("─", inner_w + 2) .. "╮"
    local mid1 = "│ " .. title_text .. string.rep(" ", inner_w - sw(title_text) - sw(keys_str)) .. keys_str .. " │"
    local mid2 = "│ " .. desc_text .. string.rep(" ", inner_w - sw(desc_text)) .. " │"
    local bot = "╰" .. string.rep("─", inner_w + 2) .. "╯"

    return { 
      top = top, mid1 = mid1, mid2 = mid2, bot = bot,
      title = title_text, desc = desc_text, keys = keys_str 
    }
  end

  local current_row = 0
  if #shortcuts == 0 then
    table.insert(lines, "    ∅ No shortcuts found")
    table.insert(hls, { 0, 4, -1, "ShowKeyCardDesc" })
  else
    local groups = {}
    local group_order = {}
    for _, s in ipairs(shortcuts) do
      if not groups[s.group] then
        groups[s.group] = {}
        table.insert(group_order, s.group)
      end
      table.insert(groups[s.group], s)
    end

    for _, gname in ipairs(group_order) do
      local g_shortcuts = groups[gname]
      table.insert(lines, "  " .. gname:upper())
      table.insert(lines, "")
      table.insert(hls, { current_row, 2, -1, "ShowKeyGroup" })
      current_row = current_row + 2

      for i = 1, #g_shortcuts, 2 do
        local s1 = g_shortcuts[i]
        local s2 = g_shortcuts[i+1]
        
        local idx1 = 0
        for k, v in ipairs(shortcuts) do if v == s1 then idx1 = k break end end
        local idx2 = 0
        if s2 then
          for k, v in ipairs(shortcuts) do if v == s2 then idx2 = k break end end
        end

        local c1 = get_card_lines(s1)
        local c2 = s2 and get_card_lines(s2) or { top="", mid1="", mid2="", bot="", keys="" }
        
        local left_margin = "  "
        local sep = "   "
        table.insert(lines, left_margin .. c1.top .. sep .. c2.top)
        table.insert(lines, left_margin .. c1.mid1 .. sep .. c2.mid1)
        table.insert(lines, left_margin .. c1.mid2 .. sep .. c2.mid2)
        table.insert(lines, left_margin .. c1.bot .. sep .. c2.bot)
        table.insert(lines, "")

        -- Helper to add highlights for a card
        local function add_card_hls(s, idx, row, card, is_second_col, first_card_widths)
          if not card.top or card.top == "" then return end
          local left_margin_len = 2
          local sep_len = 3
          
          local border_hl = idx == M.selected_idx and "ShowKeySelectedBorder" or "ShowKeyBorder"

          -- Calculate start offsets for each line
          local off = {}
          if not is_second_col then
            off.top = left_margin_len
            off.mid1 = left_margin_len
            off.mid2 = left_margin_len
            off.bot = left_margin_len
          else
            off.top = left_margin_len + first_card_widths.top + sep_len
            off.mid1 = left_margin_len + first_card_widths.mid1 + sep_len
            off.mid2 = left_margin_len + first_card_widths.mid2 + sep_len
            off.bot = left_margin_len + first_card_widths.bot + sep_len
          end

          -- 1. Selection Background (Optional/Subtle)
          if idx == M.selected_idx then
            selected_row = row + 1
            table.insert(hls, { row, off.top, off.top + #card.top, "ShowKeySelected" })
            table.insert(hls, { row + 1, off.mid1, off.mid1 + #card.mid1, "ShowKeySelected" })
            table.insert(hls, { row + 2, off.mid2, off.mid2 + #card.mid2, "ShowKeySelected" })
            table.insert(hls, { row + 3, off.bot, off.bot + #card.bot, "ShowKeySelected" })
          end

          -- 2. Borders
          table.insert(hls, { row, off.top, off.top + #card.top, border_hl })
          table.insert(hls, { row + 1, off.mid1, off.mid1 + 4, border_hl }) 
          table.insert(hls, { row + 1, off.mid1 + #card.mid1 - 4, off.mid1 + #card.mid1, border_hl })
          table.insert(hls, { row + 2, off.mid2, off.mid2 + 4, border_hl }) 
          table.insert(hls, { row + 2, off.mid2 + #card.mid2 - 4, off.mid2 + #card.mid2, border_hl })
          table.insert(hls, { row + 3, off.bot, off.bot + #card.bot, border_hl })
          
          -- 3. Content
          local key_start = off.mid1 + #card.mid1 - #card.keys - 4
          local keys_raw_len = #s.keys -- Length of keys without brackets
          
          table.insert(hls, { row + 1, off.mid1 + 4, off.mid1 + 4 + #card.title, "ShowKeyCardTitle" })
          
          -- Shortcut Keycap: [ Keys ]
          table.insert(hls, { row + 1, key_start, key_start + 1, "ShowKeyBracket" }) -- [
          table.insert(hls, { row + 1, key_start + 1, key_start + 1 + keys_raw_len, "ShowKeyBadge" }) -- Keys
          table.insert(hls, { row + 1, key_start + 1 + keys_raw_len, key_start + 2 + keys_raw_len, "ShowKeyBracket" }) -- ]
          
          if card.desc ~= "" then
            table.insert(hls, { row + 2, off.mid2 + 4, off.mid2 + 4 + #card.desc, "ShowKeyCardDesc" })
          end
        end

        local c1_widths = { top = #c1.top, mid1 = #c1.mid1, mid2 = #c1.mid2, bot = #c1.bot }
        add_card_hls(s1, idx1, current_row, c1, false)
        if s2 then
          add_card_hls(s2, idx2, current_row, c2, true, c1_widths)
        end

        current_row = current_row + 5
      end
    end
  end

  vim.api.nvim_buf_set_lines(M.body_buf, 0, -1, false, lines)
  for _, hl in ipairs(hls) do
    if hl[1] < #lines then
      pcall(vim.api.nvim_buf_add_highlight, M.body_buf, ns, hl[4], hl[1], hl[2], hl[3])
    end
  end

  if selected_row and M.body_win and vim.api.nvim_win_is_valid(M.body_win) then
    vim.api.nvim_win_set_cursor(M.body_win, { math.min(selected_row + 1, #lines), 0 })
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
