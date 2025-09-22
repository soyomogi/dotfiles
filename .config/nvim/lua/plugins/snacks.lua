return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.api.nvim_set_hl(0, "SnacksTerminal", { bg = "#ffe5f3", fg = "#3b2f4a" })
        vim.api.nvim_set_hl(0, "SnacksTerminalBorder", { bg = "#ffe5f3", fg = "#ffe5f3" })
      end,
    })
  end,
  opts = {
    picker = {
      source = {
        explorer = { hidden = true },
      },
    },
    terminal = {
      win = {
        style = "split",
        position = "bottom",
        height = 12,
        wo = {
          winhighlight = table.concat({
            "Normal:SnacksTerminal",
            "NormalNC:SnacksTerminal",
            "SignColumn:SnacksTerminal",
            "EndOfBuffer:SnacksTerminal",
          }, ","),
          number = false,
          relativenumber = false,
        },
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
