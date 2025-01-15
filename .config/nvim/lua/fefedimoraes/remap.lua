vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('i', '"', '""<left>')
vim.keymap.set('i', "'", "''<left>")
vim.keymap.set('i', '(', '()<left>')
vim.keymap.set('i', '[', '[]<left>')
vim.keymap.set('i', '{', '{}<left>')

vim.keymap.set('v', '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+yg_')
vim.keymap.set('n', '<leader>y', '"+y')
vim.keymap.set('n', '<leader>yy', ' "+yy')

vim.keymap.set('n', '<leader>p', '"+p')
vim.keymap.set('n', '<leader>P', '"+P')
vim.keymap.set('v', '<leader>p', '"+p')
vim.keymap.set('v', '<leader>P', '"+P')

