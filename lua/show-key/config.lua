local M = {}

---@field styles table Highlight groups customization
local default_config = {
  title = "Neovim Shortcuts",
  border = "rounded",
  position = "center",
  transparent = true,
  width = 0.8,
  height = 0.8,
  shortcuts = {},
  styles = {
    header = { fg = "#7aa2f7", bold = true },
    group = { fg = "#bb9af7", bold = true },
    card_title = { fg = "#c0caf5", bold = true },
    card_desc = { fg = "#565f89", italic = true },
    badge = { bg = "#3b4261", fg = "#7aa2f7", bold = true },
    border = { fg = "#7aa2f7" },
    selected_border = { fg = "#7aa2f7" },
    search_icon = { fg = "#7aa2f7" },
  },
}

---@type ShowKeyConfig
M.options = {}

---Setup the plugin with user options
---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", default_config, opts or {})
end

return M
