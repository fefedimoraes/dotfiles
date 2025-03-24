-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Toggle Wrap
vim.keymap.set({ "n", "v" }, "<C-z>", "<cmd>set wrap!<CR>", { desc = "Toggle Line Wrap" })
