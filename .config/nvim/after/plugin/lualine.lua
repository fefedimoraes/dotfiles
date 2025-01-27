local macchiato = require('catppuccin.palettes').get_palette('macchiato')

require('lualine').setup {
    options = {
        theme = 'catppuccin'
    },
    tabline = {
        lualine_a = {},
        lualine_b = {
            {
                'buffers',
                buffers_color = {
                    inactive = { fg = macchiato.overlay0, bg = macchiato.base }
                }
            }
        },
        lualine_c = {},
        lualine_x = {},
        lualine_y = { 'windows' },
        lualine_z = { 'tabs' }
    },
}

