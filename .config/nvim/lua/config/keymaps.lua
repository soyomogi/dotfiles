local snacks = require("snacks")

-- デフォルト無効化
vim.keymap.del("n", "<space><space>")

-- 挙動再設定
vim.keymap.set("n", "<space><space>", function()
  snacks.picker.git_files()
end, { desc = "Find Git Files" })

-- terminalからnormal mode に切り替え
vim.keymap.set("t", "<C-q>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- :file! を <leader> + r にする
local map = vim.keymap.set
local opts = { noremap = true, silent = true, desc = "Rename buffer file" }

map("n", "<leader>r", function()
  -- 入力プロンプトで新しいファイル名を取得
  local new_name = vim.fn.input("新しいファイル名を入力: ", vim.fn.expand("%:p"))
  if new_name ~= "" then
    vim.cmd("file! " .. new_name)
    print("ファイル名を変更しました: " .. new_name)
  end
end, opts)
