local macchiato = require('catppuccin.palettes').get_palette('macchiato')

require('catppuccin').setup({
    flavour = 'macchiato', -- latte, frappe, macchiato, mocha
    background = {         -- :h background
        light = 'latte',
        dark = 'mocha',
    },
    transparent_background = true, -- disables setting the background color.
    show_end_of_buffer = true,     -- shows the '~' characters after the end of buffers
    term_colors = false,           -- sets terminal colors (e.g. `g:terminal_color_0`)
    no_italic = false,             -- Force no italic
    no_bold = false,               -- Force no bold
    no_underline = false,          -- Force no underline
    styles = {                     -- Handles the styles of general hi groups (see `:h highlight-args`):
        comments = { 'italic' },   -- Change the style of comments
        conditionals = { 'italic' },
        loops = {},
        functions = { 'bold' },
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
        -- miscs = {}, -- Uncomment to turn off hard-coded styles
    },
    color_overrides = {},
    custom_highlights = {},
    default_integrations = true,
    integrations = {
        cmp = true,
        fzf = true,
        gitsigns = true,
        mason = true,
        notify = false,
        nvimtree = true,
        treesitter = true,
        indent_blankline = {
            enabled = true,
            scope_color = 'subtext0',
            colored_indent_levels = true,
        },
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
    },
})

-- setup must be called before loading
vim.cmd.colorscheme('catppuccin')

vim.api.nvim_set_hl(0, 'LineNr', { fg = macchiato.overlay0 })
