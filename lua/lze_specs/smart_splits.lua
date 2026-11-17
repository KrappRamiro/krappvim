-- smart-splits.nvim: moverse, redimensionar e intercambiar splits con teclas
-- direccionales (h/j/k/l), en vez de los <C-w>... nativos.
-- Ventajas sobre <C-w>h/j/k/l a pelo:
-- - en el borde da la vuelta (at_edge = "wrap"): <C-l> en la ventana de más a
--   la derecha te lleva a la de más a la izquierda.
-- - el resize es "intuitivo": <A-l> siempre mueve el borde hacia la derecha,
--   sin importar si la ventana está a la izquierda o a la derecha.
-- - si algún día usás tmux, zellij, wezterm o kitty, detecta el multiplexer y
--   <C-h/j/k/l> cruza de un split de nvim a un pane del multiplexer sin
--   cambiar de tecla (eso necesita configurar también el multiplexer, ver el
--   README del plugin). En ghostty sin multiplexer se queda dentro de nvim.
--
-- Teclas:
-- - <C-h/j/k/l>    mover el foco (normal y terminal mode)
-- - <A-h/j/k/l>    redimensionar
-- - <A-S-h/j/k/l>  intercambiar el buffer con la ventana vecina (el cursor
--                  viaja con el buffer)
local function maps()
   local ss = require("smart-splits")
   return {
      -- se pasan funciones (no "<cmd>lua ...") para que los counts anden:
      -- `5<A-l>` agranda 5 veces
      { "<C-h>", ss.move_cursor_left, "Move to left window" },
      { "<C-j>", ss.move_cursor_down, "Move to bottom window" },
      { "<C-k>", ss.move_cursor_up, "Move to top window" },
      { "<C-l>", ss.move_cursor_right, "Move to right window" },
      { "<A-h>", ss.resize_left, "Resize left" },
      { "<A-j>", ss.resize_down, "Resize down" },
      { "<A-k>", ss.resize_up, "Resize up" },
      { "<A-l>", ss.resize_right, "Resize right" },
      { "<A-S-h>", ss.swap_buf_left, "Swap buffer left" },
      { "<A-S-j>", ss.swap_buf_down, "Swap buffer down" },
      { "<A-S-k>", ss.swap_buf_up, "Swap buffer up" },
      { "<A-S-l>", ss.swap_buf_right, "Swap buffer right" },
   }
end

return {
   "smart-splits.nvim",
   auto_enable = true,
   -- lze registra estas teclas como "stubs": la primera vez que apretás una,
   -- carga el plugin, corre `after` (que pone los mappings de verdad) y
   -- repite la tecla. Así no carga nada al arrancar.
   keys = {
      { "<C-h>", mode = { "n", "t" } },
      { "<C-j>", mode = { "n", "t" } },
      { "<C-k>", mode = { "n", "t" } },
      { "<C-l>", mode = { "n", "t" } },
      "<A-h>",
      "<A-j>",
      "<A-k>",
      "<A-l>",
      "<A-S-h>",
      "<A-S-j>",
      "<A-S-k>",
      "<A-S-l>",
   },
   after = function(_)
      require("smart-splits").setup({
         -- Nombres de la v3 (en la v2 eran `at_edge` y
         -- `cursor_follows_swapped_bufs`, ahora agrupados por tema).
         -- en el borde, dar la vuelta al otro lado
         move = { at_edge = "wrap" },
         -- al intercambiar, el cursor se va con el buffer que moviste
         swap = { move_cursor = true },
      })

      for _, m in ipairs(maps()) do
         vim.keymap.set("n", m[1], m[2], { desc = m[3] })
      end

      -- En terminal mode (:term, terminal flotante de snacks) primero hay que
      -- salir a normal mode con <C-\><C-n>, si no la tecla le llega al shell.
      for _, m in ipairs({
         { "<C-h>", "left" },
         { "<C-j>", "down" },
         { "<C-k>", "up" },
         { "<C-l>", "right" },
      }) do
         vim.keymap.set(
            "t",
            m[1],
            "<C-\\><C-n><cmd>lua require('smart-splits').move_cursor_" .. m[2] .. "()<CR>",
            { desc = "Move to " .. m[2] .. " window" }
         )
      end
   end,
}
