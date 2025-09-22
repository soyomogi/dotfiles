return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    picker = {
      source = {
        explorer = { hidden = true },
      },
    },
  },
  keys = {
    {
      "<leader>e",
      function()
        Snacks.explorer({ hidden = true })
      end,
      desc = "Explorer (show hidden by default)",
    },
  },
}
