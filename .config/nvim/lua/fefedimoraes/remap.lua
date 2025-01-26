vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Opens File Explorer
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

-- Auto-completes closing "brackets"-like
vim.keymap.set('i', '"', '""<left>')
vim.keymap.set('i', "'", "''<left>")
vim.keymap.set('i', '(', '()<left>')
vim.keymap.set('i', '[', '[]<left>')
vim.keymap.set('i', '{', '{}<left>')

-- Yanks to clipboard
vim.keymap.set('v', '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+yg_')
vim.keymap.set('n', '<leader>y', '"+y')
vim.keymap.set('n', '<leader>yy', ' "+yy')

-- Pastes from clipboard
vim.keymap.set('n', '<leader>p', '"+p')
vim.keymap.set('n', '<leader>P', '"+P')
vim.keymap.set('v', '<leader>p', '"+p')
vim.keymap.set('v', '<leader>P', '"+P')

-- Moves selected lines up and down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- Navigate in Insert / Command mode using Ctrl + hjkl
vim.keymap.set({ 'i', 'c' }, '<C-h>', '<Left>')
vim.keymap.set({ 'i', 'c' }, '<C-j>', '<Down>')
vim.keymap.set({ 'i', 'c' }, '<C-k>', '<Up>')
vim.keymap.set({ 'i', 'c' }, '<C-l>', '<Right>')
vim.keymap.set({ 'i', 'c' }, '<C-b>', '<S-Left>')
vim.keymap.set({ 'i', 'c' }, '<C-w>', '<S-Right>')

-- Keeps cursor in the center when moving around
vim.keymap.set('n', 'J', 'mzJ`z')       -- when collapsing lines with J
vim.keymap.set('n', '<C-d>', '<C-d>zz') -- when moving down a page
vim.keymap.set('n', '<C-u>', '<C-u>zz') -- when moving up a page
vim.keymap.set('n', 'n', 'nzzzv')       -- when moving to the next search match
vim.keymap.set('n', 'N', 'Nzzzv')       -- when moving to the previous search match
vim.keymap.set('n', '{', '{zz')         -- when moving up a block
vim.keymap.set('n', '}', '}zz')         -- when moving down a block

-- Overwrites selected text with contents from register,
-- while keeping the register value
vim.keymap.set('x', '<leader>p', [["_dP]])

-- Delete into void register
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])

-- Format file
vim.keymap.set('n', '<leader>f', vim.lsp.buf.format)

-- Quick fix list
vim.keymap.set('n', '<F8>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<S-F8>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

-- Replace hovered over word
vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Source current file
vim.keymap.set('n', '<leader><leader>', function()
    vim.cmd('so')
end)

