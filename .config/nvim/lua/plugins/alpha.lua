return {
    'goolord/alpha-nvim',
    dependencies = { 'echasnovski/mini.icons' },
    config = function()
        local startify = require('alpha.themes.startify')
        startify.section.header.opts.position = 'center'
        require('alpha').setup(startify.config)
    end
}
