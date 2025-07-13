return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = { hidden = true },
        },
      },
      dashboard = {
        sections = {
          {
            section = "terminal",
            align = "center",
            cmd = "cat ~/.config/nvim/neovim-logo.cat",
            height = 20,
            indent = 12,
            padding = 1,
          },
          {
            section = "keys",
            gap = 1,
            padding = 1,
          },
          {
            icon = " ",
            title = "Recent Files",
            section = "recent_files",
            indent = 2,
            padding = 1,
          },
          {
            icon = " ",
            title = "Projects",
            section = "projects",
            indent = 2,
            padding = 1,
          },
          {
            icon = " ",
            title = "Git Status",
            section = "terminal",
            enabled = function()
              return Snacks.git.get_root() ~= nil
            end,
            cmd = "git status --short --branch --renames",
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          {
            section = "startup",
          },
        },
      },
    },
  },
}
