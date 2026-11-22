-- Shader de milli (lluvia, plasma, fuego, estrellas) arriba del dashboard.
--
-- milli.shader pinta un buffer entero, así que reservamos `height` líneas
-- vacías y, ya abierto el dashboard, ponemos encima una ventana flotante
-- con el shader. La ventana se cierra cuando se va el dashboard.
local util = require("dashboard.util")

return function(p)
   return {
      sections = { { padding = p.height } },
      on_open = function(d)
         local win_w = vim.api.nvim_win_get_width(d.win)
         local width = math.min(win_w, 80)
         -- Las líneas reservadas terminan justo arriba del primer texto.
         local row = math.max(0, util.first_text_row(d.buf) - 1 - p.height)
         local buf = vim.api.nvim_create_buf(false, true)
         local win = vim.api.nvim_open_win(buf, false, {
            relative = "win",
            win = d.win,
            row = row,
            col = math.floor((win_w - width) / 2),
            width = width,
            height = p.height,
            style = "minimal",
            focusable = false,
            zindex = 10,
         })
         -- Sin esto se ven números de línea y la columna de estado de
         -- snacks cortando el dibujo.
         vim.wo[win].statuscolumn = ""
         vim.wo[win].winhighlight = "Normal:SnacksDashboardNormal"
         require("milli").shader(
            buf,
            { shader = p.name, fps = p.fps, cols = width, rows = p.height }
         )
         vim.api.nvim_create_autocmd({ "BufWipeout", "BufHidden" }, {
            buffer = d.buf,
            once = true,
            callback = function()
               if vim.api.nvim_win_is_valid(win) then
                  vim.api.nvim_win_close(win, true)
               end
            end,
         })
      end,
   }
end
