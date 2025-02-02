local registry = require("show-key.registry")

local M = {}

---Scan all global and buffer-local keymaps
function M.scan()
  -- Scan global mappings
  local global_maps = vim.api.nvim_get_keymap("n") -- Only normal mode for now
  M._process_maps(global_maps)

  -- Scan buffer-local mappings
  local buf_maps = vim.api.nvim_buf_get_keymap(0, "n")
  M._process_maps(buf_maps)
end

---Process a list of Neovim keymaps and add them to the registry
---@param maps table[]
function M._process_maps(maps)
  for _, map in ipairs(maps) do
    if map.desc and map.desc ~= "" then -- Only include maps with a description
      local group = "Uncategorized"
      
      -- Simple grouping logic based on leader or common prefixes
      if map.lhs:sub(1, 1) == " " then
        group = "Leader"
      elseif map.lhs:find("^<leader>") then
        group = "Leader"
      elseif map.lhs:find("^g") then
        group = "Go"
      elseif map.lhs:find("^z") then
        group = "Folds/Spell"
      elseif map.lhs:find("^[") or map.lhs:find("^]") then
        group = "Navigation"
      end

      registry.register({
        keys = map.lhs,
        desc = map.desc,
        group = group,
        source = "auto",
        action = map.callback or map.rhs,
      })
    end
  end
end

return M
