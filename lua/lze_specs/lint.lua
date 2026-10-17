return {
   "nvim-lint",
   auto_enable = true,
   event = "FileType",
   after = function()
      require("lint").linters_by_ft = {
         -- selene es un linter para Lua. Por default no conoce la API de
         -- Neovim, así que necesita dos archivos en la raíz del repo
         --
         --   selene.toml  -->   qué std usar, qué lints permitir
         --   vim.yml      -->   declara los globals (vim, Snacks, nixInfo, jit)
         --
         -- Si aparece un warning `X is not defined` por un global nuevo,
         -- agregalo al vim.yml.
         --
         -- Referencia: https://github.com/LazyVim/LazyVim
         lua = { "selene" },
         nix = { "statix", "deadnix" },
         sh = { "shellcheck" },
         bash = { "shellcheck" },
         -- rust: sin linter acá. rust-analyzer ya corre clippy (check.command
         -- en lsp.lua); el linter "clippy" de nvim-lint compilaba el proyecto
         -- entero otra vez en cada guardado y duplicaba los diagnostics.
         -- python: ruff corre como LSP (lsp.lua), da los mismos diagnostics
         -- mientras escribís y además code actions.
         terraform = { "tflint" }, -- cubre .tf y .tofu
         javascript = { "eslint_d" },
         typescript = { "eslint_d" },
         javascriptreact = { "eslint_d" }, -- archivos .jsx
         typescriptreact = { "eslint_d" }, -- archivos .tsx
         go = { "golangcilint" },
         html = { "htmlhint" },
         css = { "stylelint" },
      }

      -- BufReadPost: lintea apenas abrís el archivo, no recién al guardar.
      -- No usamos InsertLeave/TextChanged porque algunos linters (deadnix,
      -- tflint, golangcilint) leen el archivo del disco y darían resultados
      -- viejos. Ver la sección "Usage" del README de nvim-lint.
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
         group = vim.api.nvim_create_augroup("krappvim_lint", { clear = true }),
         callback = function()
            require("lint").try_lint()
         end,
      })
      -- este plugin carga en FileType, o sea DESPUÉS del BufReadPost del
      -- primer archivo, así que ese lo linteamos a mano
      require("lint").try_lint()
   end,
}
