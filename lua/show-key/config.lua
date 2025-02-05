local M = {}

---@class ShowKeyConfig
---@field title string The title of the popup
---@field border string|table Border style for the floating window
---@field position "center"|"top"|"bottom" Position of the popup
---@field width number Width percentage (0-1)
---@field height number Height percentage (0-1)
---@field auto_detect boolean Whether to automatically detect keymaps
local default_config = {
  title = "Neovim Shortcuts",
  border = "rounded",
  position = "center",
  transparent = true,
  width = 0.8,
  height = 0.8,
  shortcuts = {},
}

---@type ShowKeyConfig
M.options = {}

---Setup the plugin with user options
---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", default_config, opts or {})
end

return M
