return {
   {
      "nvim-treesitter",
      lazy = false,
      auto_enable = true,
      after = function(_)
         ---@param buf integer
         ---@param language string
         local function treesitter_try_attach(buf, language)
            -- check if parser exists and load it
            if not vim.treesitter.language.add(language) then
               return false
            end
            -- enables syntax highlighting and other treesitter features
            vim.treesitter.start(buf, language)

            -- enables treesitter based folds
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.wo.foldmethod = "expr"
            -- ensure folds are open to begin with
            vim.o.foldlevel = 99

            -- enables treesitter based indentation
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

            -- Rust: sacamos `0(` y `0[` de indentkeys.
            -- El indent/rust.vim de Neovim pone indentkeys=0{,0},!^F,o,O,0[,0],0(,0).
            -- `0(` significa "si el primer carácter de la línea es `(`, recalculá
            -- la indentación". Esas teclas se pensaron para el motor de rust.vim
            -- (cindent), pero acá el que calcula es treesitter (la línea de arriba).
            -- Pasaba esto: dentro de un `match`, en una línea vacía ya indentada,
            -- escribía `(` para un brazo como `(false, Some(since)) => {`.
            -- mini.pairs completa `()`, y `()` solo dentro del match es un error
            -- de sintaxis. Treesitter calculaba la indentación sobre ese árbol
            -- roto y tiraba la línea a la izquierda. Con `[` pasa lo mismo en
            -- patrones de slice (`[first, ..] =>`).
            -- Para `(` y `[` recalcular no aporta: después de Enter la línea ya
            -- queda bien indentada. Los cierres (`0)`, `0]`, `0}`) se quedan,
            -- porque esos sí tienen que retroceder un nivel al escribirlos.
            if language == "rust" then
               local keys = vim.split(vim.bo[buf].indentkeys, ",", { plain = true })
               keys = vim.tbl_filter(function(key)
                  return key ~= "0(" and key ~= "0["
               end, keys)
               vim.bo[buf].indentkeys = table.concat(keys, ",")
            end

            return true
         end

         local installable_parsers = require("nvim-treesitter").get_available()
         vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
               local buf, filetype = args.buf, args.match
               local language = vim.treesitter.language.get_lang(filetype)
               if not language then
                  return
               end

               if not treesitter_try_attach(buf, language) then
                  if vim.tbl_contains(installable_parsers, language) then
                     -- not already installed, so try to install them via nvim-treesitter if possible
                     require("nvim-treesitter").install(language):await(function()
                        treesitter_try_attach(buf, language)
                     end)
                  end
               end
            end,
         })
      end,
   },
   {
      "nvim-treesitter-textobjects",
      auto_enable = true,
      lazy = false,
      before = function(_)
         -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main?tab=readme-ov-file#using-a-package-manager
         -- Disable entire built-in ftplugin mappings to avoid conflicts.
         -- See https://github.com/neovim/neovim/tree/master/runtime/ftplugin for built-in ftplugins.
         vim.g.no_plugin_maps = true
      end,
      after = function(_)
         require("nvim-treesitter-textobjects").setup({
            select = {
               -- Automatically jump forward to textobj, similar to targets.vim
               lookahead = true,
               selection_modes = {
                  ["@parameter.outer"] = "v", -- charwise
                  ["@function.outer"] = "V", -- linewise
               },
               include_surrounding_whitespace = false,
            },
         })

         -- keymaps
         -- You can use the capture groups defined in `textobjects.scm`
         vim.keymap.set({ "x", "o" }, "am", function()
            require("nvim-treesitter-textobjects.select").select_textobject(
               "@function.outer",
               "textobjects"
            )
         end)
         vim.keymap.set({ "x", "o" }, "im", function()
            require("nvim-treesitter-textobjects.select").select_textobject(
               "@function.inner",
               "textobjects"
            )
         end)
         vim.keymap.set({ "x", "o" }, "ac", function()
            require("nvim-treesitter-textobjects.select").select_textobject(
               "@class.outer",
               "textobjects"
            )
         end)
         vim.keymap.set({ "x", "o" }, "ic", function()
            require("nvim-treesitter-textobjects.select").select_textobject(
               "@class.inner",
               "textobjects"
            )
         end)
         -- You can also use captures from other query groups like `locals.scm`
         vim.keymap.set({ "x", "o" }, "as", function()
            require("nvim-treesitter-textobjects.select").select_textobject(
               "@local.scope",
               "locals"
            )
         end)

         -- NOTE: for more textobjects options, see the following link.
         -- This template is using the new `main` branch of the repo.
         -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/tree/main
      end,
   },
}
