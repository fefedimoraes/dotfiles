local macchiato = require('catppuccin.palettes').get_palette('macchiato')
local noice = require('noice')

require('lualine').setup {
    options = {
        theme = 'catppuccin'
    },
    sections = {
        lualine_a = {
            {
                noice.api.statusline.mode.get,
                cond = noice.api.statusline.mode.has,
            },
            'mode',
        }
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
