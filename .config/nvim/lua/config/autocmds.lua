vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter" }, {
  callback = function()
    if vim.bo.buftype == "terminal" then
      -- SnacksのTerminalと同じ見た目を適用
      vim.api.nvim_set_hl(0, "SnacksTerminal", { bg = "#ffe5f3", fg = "#3b2f4a" })
      vim.api.nvim_set_hl(0, "SnacksTerminalBorder", { bg = "#ffe5f3", fg = "#ffe5f3" })
      vim.wo.winhighlight = table.concat({
        "Normal:SnacksTerminal",
        "NormalNC:SnacksTerminal",
        "SignColumn:SnacksTerminal",
        "EndOfBuffer:SnacksTerminal",
        "FloatBorder:SnacksTerminalBorder",
      }, ",")
      vim.wo.number = false
      vim.wo.relativenumber = false
    else
      -- 他のバッファに戻ったらもとの色へ
      vim.wo.winhighlight = ""
    end
  end,
})
