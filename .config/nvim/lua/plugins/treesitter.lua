return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function ()
        local configs = require('nvim-treesitter.configs')

        configs.setup({
            ensure_installed = {
                'bash',
                'c',
                'css',
                'csv',
                'diff',
                'editorconfig',
                'gitignore',
                'gnuplot',
                'html',
                'http',
                'java',
                'javascript',
                'json',
                'kotlin',
                'lua',
                'markdown',
                'markdown_inline',
                'query',
                'sql',
                'tmux',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vimdoc',
                'yaml',
            },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end
}

