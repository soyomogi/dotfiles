-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- fairyfloss 用に Snacks Explorer の背景を Normal に合わせる
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    -- Normal の bg を取得
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    local bg = normal and normal.bg
    if not bg then
      return
    end

    -- Snacks Explorer が使う可能性のあるハイライトを上書き
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg })
    vim.api.nvim_set_hl(0, "SnacksNormal", { bg = bg })
    vim.api.nvim_set_hl(0, "SnacksNormalNC", { bg = bg })
    vim.api.nvim_set_hl(0, "SnacksExplorerNormal", { bg = bg })
    vim.api.nvim_set_hl(0, "SnacksExplorerBorder", { bg = bg })
  end,
})
