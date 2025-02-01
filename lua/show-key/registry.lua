local M = {}

---@class Shortcut
---@field keys string
---@field desc string
---@field group string
---@field action? function|string
---@field source "manual"|"auto"

---@type Shortcut[]
M.shortcuts = {}

---Register a manual shortcut
---@param shortcut Shortcut
function M.register(shortcut)
  shortcut.source = "manual"
  table.insert(M.shortcuts, shortcut)
end

---Get all shortcuts
---@return Shortcut[]
function M.get_all()
  return M.shortcuts
end

return M
