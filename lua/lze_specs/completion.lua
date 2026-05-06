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

            -- Esta seccion controla como blink ordena los resultados del menu de completado
            fuzzy = {
               sorts = {
                  "exact",
                  -- defaults
                  "score",
                  "sort_text",
               },
            },

            -- Muestra el signature de las funciones en el autocompletado, ta god
            signature = {
               enabled = true,
               window = {
                  show_documentation = true,
               },
            },

            completion = {
               menu = {
                  -- Cada línea del menú de completado es un "ítem". Blink te deja controlar cómo se dibuja cada uno.
                  -- con mi config, blink le delega ese trabajo a colorful-menu.nvim.
                  draw = {
                     -- para los ítems del LSP, use treesitter para parsear y colorear el texto interno
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
               -- Cuando abrís el menú de completado y movés el cursor por las opciones,
               -- a la derecha aparece un segundo popup con la documentación de esa opción.
               documentation = {
                  auto_show = true,
               },
            },

            -- La lista de fuyentes que usa blink para generar sugerencias
            sources = {
               default = {
                  "lsp", -- sugerencias del LSP
                  "path", -- rutas de archivo (./src , /home/ , etc...)
                  "buffer", -- palabras que ya estan escritas en el buffer actual
                  "omni", -- fuente generica de palabras de neovim
               },

               providers = {
                  -- el score_offset le agrega mas peso a una opcion que a otra
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
