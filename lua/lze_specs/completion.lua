return {
   {
      "colorful-menu.nvim",
      auto_enable = true,
      on_plugin = { "blink.cmp" },
   },
   {
      "blink.cmp",
      auto_enable = true,
      event = "DeferredUIEnter",
      after = function(_)
         require("blink.cmp").setup({
            -- Default key mappings
            -- <C-space> to open
            --
            -- <C-y> to accept
            -- <C-e> to hide
            --
            -- <C-p> previous option
            -- <C-n> next option
            --
            -- <C-k> show signature
            --
            -- <Tab> Snippet forward
            -- <S-Tab> Snipper backward
            keymap = {
               preset = "default",
            },

            -- en vim, cmdline" es cualquier cosa que abrís con una tecla especial que cambia el modo y te pone a escribir abajo (con noice, es un popup en el medio xd):
            --   :  -->  comandos ex (:w, :q, :colorscheme, etc.)
            --   /  -->  búsqueda hacia adelante
            --   ?  -->  búsqueda hacia atrás
            --   @  -->  ejecutar un macro (:@q por ejemplo)
            --   !  -->  comandos de shell (:!ls)
            --   =  -->  expresiones de Lua/Vimscript
            cmdline = {
               enabled = true,
               completion = {
                  menu = {
                     -- con esto, no hace falta tocal <C-space> para que aparezca el menu de autocompletado
                     auto_show = true,
                  },
               },
               -- Source selection for completion
               sources = function()
                  local type = vim.fn.getcmdtype()
                  -- When searching forward and/or backward, use the buffer as a source
                  if type == "/" or type == "?" then
                     return { "buffer" }
                  end
                  -- When typing comands, use the cmdline as a source
                  if type == ":" or type == "@" then
                     return { "cmdline" }
                  end
                  -- And if there is no match, use nothing :(
                  return {}
               end,
            },

            fuzzy = {
               sorts = {
                  "exact",
                  -- defaults
                  "score",
                  "sort_text",
               },
            },

            signature = {
               enabled = true,
               window = {
                  show_documentation = true,
               },
            },
            completion = {
               menu = {
                  draw = {
                     treesitter = { "lsp" },
                     components = {
                        label = {
                           text = function(ctx)
                              return require("colorful-menu").blink_components_text(ctx)
                           end,
                           highlight = function(ctx)
                              return require("colorful-menu").blink_components_highlight(ctx)
                           end,
                        },
                     },
                  },
               },
               documentation = {
                  auto_show = true,
               },
            },
            sources = {
               default = { "lsp", "path", "buffer", "omni" },
               providers = {
                  path = {
                     score_offset = 50,
                  },
                  lsp = {
                     score_offset = 40,
                  },
               },
            },
         })
      end,
   },
}
