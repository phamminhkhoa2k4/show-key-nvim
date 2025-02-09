local M = {}

---@class Shortcut
---@field title? string
---@field keys string
---@field desc string
---@field group string

---@type Shortcut[]
M.shortcuts = {}

---Register a shortcut
---@param shortcut Shortcut
function M.register(shortcut)
  -- Prevent duplicates
  for i, s in ipairs(M.shortcuts) do
    if s.keys == shortcut.keys then
      M.shortcuts[i] = shortcut
      return
    end
  end

  table.insert(M.shortcuts, shortcut)
end

---Remove a shortcut by its keys
---@param keys string
function M.remove(keys)
  for i, s in ipairs(M.shortcuts) do
    if s.keys == keys then
      table.remove(M.shortcuts, i)
      return true
    end
  end
  return false
end


---Get all shortcuts
---@return Shortcut[]
function M.get_all()
  return M.shortcuts
end

return M
