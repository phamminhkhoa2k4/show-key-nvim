local config = require("show-key.config")
local registry = require("show-key.registry")

local M = {}

---Setup the plugin
---@param opts? ShowKeyConfig
function M.setup(opts)
  config.setup(opts)
  if config.options.shortcuts then
    M.register_shortcuts(config.options.shortcuts)
  end
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
  require("show-key.ui").create_window()
end

---Open the shortcut registration form
function M.register_form()
  require("show-key.form").open()
end

return M
