local snacks = require("snacks")

-- デフォルト無効化
vim.keymap.del("n", "<space><space>")

-- 挙動再設定
vim.keymap.set("n", "<space><space>", function()
  snacks.picker.git_files()
end, { desc = "Find Git Files" })

-- terminalからnormal mode に切り替え
vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
