return {
   "conform.nvim",
   auto_enable = true,
   -- El campo keys le dice a lze: "si el usuario aprieta <leader>FF, cargá conform.nvim".
   -- Esto tambien es pasado a which-key.nvim automaticamente
   keys = {
      { "<leader>FF", desc = "[F]ormat [F]ile" },
   },
   after = function(plugin)
      local conform = require("conform")

      conform.setup({
         -- ft es filetype
         formatters_by_ft = {
            -- NOTE: download some formatters
            -- and configure them here
            --
            -- EXAMPLES:
            --   Conform will run multiple formatters sequentially
            --     python = { "isort", "black" },
            --   Use a sub-list to run only the first available formatter
            --     javascript = { { "prettierd", "prettier" } },
            --
            lua = nixInfo(nil, "settings", "cats", "lua") and { "stylua" } or nil,
            nix = { "nixfmt" },
            python = { "ruff" },
            html = { "prettier" },
            css = { "prettier" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            typst = { "typstyle" },
            rust = { "rustfmt" },
            terraform = { "terraform_fmt" },
         },
      })

      -- Keymaps
      vim.keymap.set({ "n", "v" }, "<leader>FF", function()
         conform.format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 1000,
         })
      end, { desc = "[F]ormat [F]ile" })
   end,
}
