-- dropbar.nvim: breadcrumb interactivo en el winbar de cada ventana.
-- Muestra "Class > Method > IfBlock" usando treesitter y LSP, y permite
-- abrir un picker para saltar a cualquier símbolo del archivo.
return {
   "dropbar.nvim",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function()
      require("dropbar").setup({
         menu = {
            keymaps = {
               -- navegación vim-style entre menús/submenús:
               --   h  →  cerrar el menú actual (volver al padre)
               --   l  →  abrir el item bajo el cursor (entrar al hijo)
               -- el `<C-w>q` para `h` reusa el mismo handler que el `q`
               -- por default. Para `l` replicamos la lógica del `<CR>`.
               ["h"] = "<C-w>q",
               ["l"] = function()
                  local utils = require("dropbar.utils")
                  local menu = utils.menu.get_current()
                  if not menu then return end
                  local cursor = vim.api.nvim_win_get_cursor(menu.win)
                  local component = menu.entries[cursor[1]]:first_clickable(cursor[2])
                  if component then
                     menu:click_on(component, nil, 1, "l")
                  end
               end,
            },
         },
      })

      local api = require("dropbar.api")

      -- abre el picker interactivo: te muestra todos los símbolos del archivo
      -- y podés saltar a cualquiera. Convención de LazyVim: <leader>;
      vim.keymap.set("n", "<leader>;", api.pick, { desc = "Symbol picker (dropbar)" })

      -- saltar al inicio del contexto actual (ej: línea de la función donde estás)
      vim.keymap.set("n", "[;", api.goto_context_start, { desc = "Go to start of current context" })

      -- seleccionar el próximo contexto (siguiente función / bloque)
      vim.keymap.set("n", "];", api.select_next_context, { desc = "Select next context" })
   end,
}
