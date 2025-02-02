local M = {}

---@class Shortcut
---@field keys string
---@field desc string
---@field group string
---@field action? function|string
---@field source "manual"|"auto"

---@type Shortcut[]
M.shortcuts = {}

---Register a shortcut
---@param shortcut Shortcut
function M.register(shortcut)
  -- Prevent duplicates, prioritize manual over auto
  for i, s in ipairs(M.shortcuts) do
    if s.keys == shortcut.keys then
      if shortcut.source == "manual" then
        M.shortcuts[i] = shortcut -- Overwrite auto with manual
      end
      return
    end
  end

  table.insert(M.shortcuts, shortcut)
end

---Get all shortcuts
---@return Shortcut[]
function M.get_all()
  return M.shortcuts
end

return M
