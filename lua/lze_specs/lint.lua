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
         rust = { "clippy" },
         python = { "ruff" },
         terraform = { "tflint" }, -- cubre .tf y .tofu
         javascript = { "eslint_d" },
         typescript = { "eslint_d" },
         javascriptreact = { "eslint_d" }, -- archivos .jsx
         typescriptreact = { "eslint_d" }, -- archivos .tsx
         go = { "golangcilint" },
         html = { "htmlhint" },
         css = { "stylelint" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
         callback = function()
            require("lint").try_lint()
         end,
      })
   end,
}
