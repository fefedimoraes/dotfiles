return {
  "folke/sidekick.nvim",
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "tmux",
        enabled = true,
      },
      tools = {
        kiro = {
          cmd = { "kiro-cli" },
        },
      },
    },
    nes = {
      enabled = false,
    },
  },
}
