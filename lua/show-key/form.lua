local config = require("show-key.config")
local registry = require("show-key.registry")

local M = {}

M.buf = nil
M.win = nil
M.fields = {
  { label = "TITLE", value = "", key = "title" },
  { label = "KEYS", value = "", key = "keys" },
  { label = "DESCRIPTION", value = "", key = "desc" },
  { label = "GROUP", value = "", key = "group" },
}
M.active_field = 1

function M.open()
  -- Reset fields
  for _, f in ipairs(M.fields) do f.value = "" end
  M.active_field = 1

  local screen_w = vim.o.columns
  local screen_h = vim.o.lines
  local width = 60
  local height = 10
  local row = math.floor((screen_h - height) / 2)
  local col = math.floor((screen_w - width) / 2)

  M.buf = vim.api.nvim_create_buf(false, true)
  local opts = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " 󰌌  REGISTER SHORTCUT ",
    title_pos = "center",
    footer = " <Tab>/<C-j>: Next | <S-Tab>/<C-k>: Prev | <CR>: Save | <Esc>: Close ",
    footer_pos = "center",
  }
  M.win = vim.api.nvim_open_win(M.buf, true, opts)
  
  vim.api.nvim_win_set_option(M.win, "winhighlight", "Normal:ShowKeyNormal,FloatBorder:ShowKeyBorder,FloatTitle:ShowKeyHeader,FloatFooter:ShowKeyCardDesc")
  vim.api.nvim_win_set_option(M.win, "scrolloff", 0)
  vim.api.nvim_win_set_option(M.win, "sidescrolloff", 0)
  vim.api.nvim_win_set_option(M.win, "wrap", false)

  M.setup_keymaps()
  M.render()
end

function M.render()
  if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then return end
  vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
  
  local lines = { "" }
  local hls = {}
  local ns = vim.api.nvim_create_namespace("show-key-form")
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)

  for i, field in ipairs(M.fields) do
    local prefix = (i == M.active_field) and " ❯ " or "   "
    local line = string.format("%s%-12s: %s", prefix, field.label, field.value)
    table.insert(lines, line)
    
    local row = #lines - 1
    if i == M.active_field then
      table.insert(hls, { row, 0, 3, "ShowKeyGroup" })
      table.insert(hls, { row, 3, 15, "ShowKeyCardTitle" })
    else
      table.insert(hls, { row, 3, 15, "ShowKeyCardDesc" })
    end
    table.insert(lines, "") -- Spacer
  end

  table.insert(lines, "") -- Extra padding at the bottom

  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  for _, hl in ipairs(hls) do
    vim.api.nvim_buf_add_highlight(M.buf, ns, hl[4], hl[1], hl[2], hl[3])
  end
  
  vim.api.nvim_buf_set_option(M.buf, "modifiable", false)
end

function M.setup_keymaps()
  local opts = { buffer = M.buf, nowait = true, silent = true }
  
  -- Navigation
  vim.keymap.set("n", "<Tab>", function()
    M.active_field = (M.active_field % #M.fields) + 1
    M.render()
  end, opts)
  
  vim.keymap.set("n", "<S-Tab>", function()
    M.active_field = (M.active_field - 2 + #M.fields) % #M.fields + 1
    M.render()
  end, opts)

  -- Typing (Simple capture)
  for i = 32, 126 do
    local char = string.char(i)
    vim.keymap.set("n", char, function()
      M.fields[M.active_field].value = M.fields[M.active_field].value .. char
      M.render()
    end, opts)
  end

  vim.keymap.set("n", "<BS>", function()
    local val = M.fields[M.active_field].value
    if #val > 0 then
      M.fields[M.active_field].value = val:sub(1, -2)
      M.render()
    end
  end, opts)

  -- Actions
  vim.keymap.set("n", "<CR>", function()
    local data = {}
    for _, f in ipairs(M.fields) do data[f.key] = f.value end
    if data.title ~= "" and data.keys ~= "" then
      registry.register(data)
      M.close()
      print("Shortcut registered: " .. data.title)
    else
      print("Title and Keys are required!")
    end
  end, opts)

  -- Field Navigation via Ctrl-j/k (and Tab/S-Tab)
  vim.keymap.set("n", "<C-j>", function()
    M.active_field = (M.active_field % #M.fields) + 1
    M.render()
  end, opts)
  vim.keymap.set("n", "<C-k>", function()
    M.active_field = (M.active_field - 2 + #M.fields) % #M.fields + 1
    M.render()
  end, opts)

  -- Disable scrolling keys and mouse
  local scroll_keys = {
    "<Up>", "<Down>", "<Left>", "<Right>",
    "<ScrollWheelUp>", "<ScrollWheelDown>",
    "<C-f>", "<C-b>", "<C-d>", "<C-u>"
  }
  for _, k in ipairs(scroll_keys) do
    vim.keymap.set("n", k, "<Nop>", opts)
  end

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
