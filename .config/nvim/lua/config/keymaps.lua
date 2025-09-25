local snacks = require("snacks")

-- デフォルト無効化
vim.keymap.del("n", "<space><space>")

-- 挙動再設定
vim.keymap.set("n", "<space><space>", function()
  snacks.picker.git_files()
end, { desc = "Find Git Files" })
