local pink_bg = "#ffe5f3"
local normal = "#5a5475"
local txt = "#3b2f4a"
local accent = "#d63384"

local function recolor_win(win)
  local whl = vim.wo[win].winhighlight or ""
  for pair in whl:gmatch("[^,]+") do
    local _, rhs = pair:match("^%s*([^:]+):([^:]+)%s*$")
    if rhs and rhs ~= "" then
      local spec = { bg = pink_bg, fg = txt }
      local low = rhs:lower()
      if low:find("cursorline") then
        spec = { bg = normal }
      elseif low:find("title") then
        spec = { bg = pink_bg, fg = accent, bold = true }
      elseif low:find("border") then
        spec = { bg = pink_bg, fg = pink_bg }
      elseif low:find("footer") or low:find("header") then
        spec = { bg = pink_bg, fg = txt }
      end
      pcall(vim.api.nvim_set_hl, 0, rhs, spec)
    end
  end
end

local function apply(buf)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    recolor_win(win)
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
