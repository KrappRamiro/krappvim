-- Imagen con píxeles reales (protocolo kitty: kitty, ghostty, wezterm).
--
-- No devuelve secciones: Snacks.image.placement dibuja la imagen como
-- líneas virtuales debajo de la fila `pos`, y esas líneas empujan hacia
-- abajo el resto del dashboard. Reservar espacio con líneas vacías dejaría
-- un hueco doble.
local util = require("dashboard.util")

return function(p)
   return {
      sections = {},
      on_open = function(d)
         if not (Snacks.image and Snacks.image.supports_terminal()) then
            return
         end
         -- Dos filas arriba del primer texto (el título), centrada.
         local row = math.max(1, util.first_text_row(d.buf) - 2)
         local col = math.max(0, math.floor((vim.api.nvim_win_get_width(d.win) - p.width) / 2))
         Snacks.image.placement.new(d.buf, p.path, {
            pos = { row, col },
            width = p.width,
            height = p.height,
            max_width = p.width,
            max_height = p.height,
         })
      end,
   }
end
