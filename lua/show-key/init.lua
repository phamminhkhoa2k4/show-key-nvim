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
  if config.options.auto_detect then
    require("show-key.scanner").scan()
  end

  -- Placeholder for UI window creation
  local all = registry.get_all()
  vim.notify(string.format("show-key: Found %d shortcuts. UI coming soon.", #all), vim.log.levels.INFO)
end

return M
