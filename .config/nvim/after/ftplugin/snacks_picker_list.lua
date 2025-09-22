local bg, sel, fg, accent = "#ffe5f3", "#5a5475", "#3b2f4a", "#d63384"

local function tint(win)
  local whl = vim.wo[win].winhighlight or ""
  for pair in whl:gmatch("[^,]+") do
    local _, rhs = pair:match("^%s*([^:]+):([^:]+)%s*$")
    if rhs and rhs:match("^SnacksPicker") then
      local spec = { bg = bg, fg = fg }
      local low = rhs:lower()
      if low:find("cursorline") then
        spec = { bg = sel }
      elseif low:find("title") then
        spec = { bg = bg, fg = accent, bold = true }
      elseif low:find("border") then
        spec = { bg = bg, fg = bg }
      elseif low:find("footer") or low:find("header") then
        spec = { bg = bg, fg = fg }
      end
      pcall(vim.api.nvim_set_hl, 0, rhs, spec)
    end
  end
end

local function apply(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    tint(win)
  end
end

apply(vim.api.nvim_get_current_buf())
vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
  callback = function()
    if vim.bo.filetype == "snacks_picker_list" then
      apply(vim.api.nvim_get_current_buf())
    end
  end,
})
