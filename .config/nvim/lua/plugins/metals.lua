return {
  {
    "scalameta/nvim-metals",
    ft = { "scala", "sbt" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local metals = require("metals")
      local metals_config = metals.bare_config()

      -- nvim-cmp の LSP capabilities を統合 (補完が効く)
      metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- LazyVim の標準LSPキーマップをそのまま使う
      metals_config.init_options = { statusBarProvider = "on" }

      -- scala / sbt ファイルを開いたときに metals 起動
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "scala", "sbt" },
        callback = function()
          metals.initialize_or_attach(metals_config)
        end,
      })
    end,
  },
}
