-- plugin/show-key.lua
if vim.g.loaded_show_key then
  return
end
vim.g.loaded_show_key = 1

vim.api.nvim_create_user_command("ShowKey", function()
  require("show-key").show()
end, { desc = "Show shortcut popup" })
