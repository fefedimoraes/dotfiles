-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Show whitespaces
vim.opt.list = true
vim.opt.listchars:append({
  space = "·",
  tab = "▷ ",
  trail = "~",
  extends = "◣",
  precedes = "◢",
  nbsp = "␣",
})
