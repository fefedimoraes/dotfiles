local keys = {
  {
    "<leader>dv",
    function()
      if next(require("diffview.lib").views) == nil then
        vim.cmd("DiffviewOpen")
      else
        vim.cmd("DiffviewClose")
      end
    end,
    desc = "Toggle Diffview window",
  },
}

for i = 1, 10 do
  keys[#keys + 1] = {
    "<leader>d" .. (i % 10),
    function()
      if next(require("diffview.lib").views) == nil then
        vim.cmd("DiffviewOpen HEAD~" .. i)
      else
        vim.cmd("DiffviewClose")
      end
    end,
    desc = "Toggle Diffview HEAD~" .. i,
  }
end

return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", lazy = true },
    },
    keys = keys,
  },
}
