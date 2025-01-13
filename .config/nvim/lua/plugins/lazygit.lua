return {
    'kdheepak/lazygit.nvim',
    lazy = true,
    cmd = {
        'LazyGit',
        'LazyGitConfig',
        'LazyGitCurrentFile',
        'LazyGitFilter',
        'LazyGitFilterCurrentFile',
    },
    dependencies = {
        'nvim-telescope/telescope.nvim',
        'nvim-lua/plenary.nvim',
    },
    keys = {
        { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' }
    },
    config = function()
        require('telescope').load_extension('lazygit')
    end
}

