local config = require("show-key.config")
local registry = require("show-key.registry")

local M = {}

---Setup the plugin
---@param opts? ShowKeyConfig
function M.setup(opts)
  config.setup(opts)
end

---Register a list of shortcuts
---@param shortcuts Shortcut[]
function M.register_shortcuts(shortcuts)
  for _, s in ipairs(shortcuts) do
    registry.register(s)
  end
end

---Show the shortcut popup
function M.show()
  -- Placeholder for UI window creation
  vim.notify("show-key: Showing shortcuts popup (UI coming soon)", vim.log.levels.INFO)
end

return M
