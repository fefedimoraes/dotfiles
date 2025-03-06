local telescope = require('telescope')
local themes = require('telescope.themes')
local telescopeBuiltin = require('telescope.builtin')

telescope.setup({
    extensions = {
        file_browser = {
            theme = 'ivy',
            hijack_netrw = true,
            hidden = { file_browser = true, folder_browser = true },
        },
        ['ui-select'] = {
            themes.get_cursor {}
        }
    },
})

telescope.load_extension('file_browser')
telescope.load_extension('notify')
telescope.load_extension('ui-select')

vim.keymap.set('n', '<leader>fe', telescope.extensions.file_browser.file_browser, { desc = 'Telescope file explorer' })
vim.keymap.set('n', '<space>fE', ':Telescope file_browser path=%:p:h select_buffer=true<CR>', { desc = 'Telescope file explorer (current buffer directory)' })
vim.keymap.set('n', '<leader>ff', telescopeBuiltin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', telescopeBuiltin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', telescopeBuiltin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', telescopeBuiltin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>fn', function () telescope.extensions.notify.notify(themes.get_dropdown {}) end, { desc = 'Telescope notifications' })

