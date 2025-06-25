-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Toggle Wrap
vim.keymap.set({ "n", "v" }, "<C-z>", "<cmd>set wrap!<CR>", { desc = "Toggle Line Wrap" })

-- Keeps cursor in the center when moving around
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- when moving down a page
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- when moving up a page
vim.keymap.set("n", "n", "nzzzv") -- when moving to the next search match
vim.keymap.set("n", "N", "Nzzzv") -- when moving to the previous search match
vim.keymap.set("n", "{", "{zz") -- when moving up a block
vim.keymap.set("n", "}", "}zz") -- when moving down a block

-- Replace hovered over word
vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
