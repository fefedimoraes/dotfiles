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
            height = 22,
            indent = 12,
            padding = 1,
          },
          {
            section = "keys",
            gap = 1,
            padding = 1,
          },
          {
            section = "startup",
          },
        },
      },
    },
  },
}
