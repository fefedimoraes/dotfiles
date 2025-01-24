require('lualine').setup {
    options = {
        theme = 'catppuccin'
    },
    tabline = {
        lualine_a = { },
        lualine_b = { 'buffers' },
        lualine_c = { },
        lualine_x = {},
        lualine_y = { 'windows' },
        lualine_z = { 'tabs' }
    },
}

