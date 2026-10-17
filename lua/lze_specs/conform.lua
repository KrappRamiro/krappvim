return {
   "conform.nvim",
   auto_enable = true,
   -- El campo keys le dice a lze: "si el usuario aprieta <leader>FF, cargá conform.nvim".
   -- Esto tambien es pasado a which-key.nvim automaticamente
   keys = {
      { "<leader>FF", desc = "[F]ormat [F]ile" },
   },
   -- BufWritePre: cargar conform justo antes del primer guardado, así el
   -- format_on_save de abajo ya está registrado (mismo trigger que el ejemplo
   -- de lazy-loading de la doc de conform, doc/recipes.md)
   event = "BufWritePre",
   cmd = { "ConformInfo" },
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
            lua = { "stylua" },
            nix = { "nixfmt" },
            -- ruff_organize_imports: ordena imports (lo que hace `ruff check --select I --fix`)
            -- ruff_format: el formatter en sí. El orden importa, primero imports.
            python = { "ruff_organize_imports", "ruff_format" },
            html = { "prettier" },
            css = { "prettier" },
            scss = { "prettier" },
            javascript = { "prettier" },
            typescript = { "prettier" },
            javascriptreact = { "prettier" },
            typescriptreact = { "prettier" },
            json = { "prettier" },
            jsonc = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            toml = { "taplo" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            typst = { "typstyle" },
            rust = { "rustfmt" },
            -- tofu_fmt y no terraform_fmt: en module.nix solo está opentofu
            terraform = { "tofu_fmt" },
         },

         -- Formatear al guardar. Es una función (no una tabla) para poder
         -- apagarlo: receta "Autoformat with extra features" de la doc de conform.
         -- Toggles en snacks.lua: <leader>tf (global) y <leader>tF (este buffer).
         format_on_save = function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
               return
            end
            return {
               timeout_ms = 1000,
               -- sin formatter configurado para el filetype, usa el del LSP
               lsp_format = "fallback",
            }
         end,
      })

      -- Keymaps
      vim.keymap.set({ "n", "v" }, "<leader>FF", function()
         conform.format({
            -- "fallback": si no hay formatter configurado para el filetype,
            -- usa el del LSP. (`lsp_fallback = true` es el nombre viejo, deprecado)
            lsp_format = "fallback",
            async = false,
            timeout_ms = 1000,
         })
      end, { desc = "[F]ormat [F]ile" })
   end,
}
