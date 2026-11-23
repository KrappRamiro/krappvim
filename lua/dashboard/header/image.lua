-- Imagen con píxeles reales (protocolo kitty: kitty, ghostty, wezterm).
--
-- No devuelve secciones: Snacks.image.placement dibuja la imagen como
-- líneas virtuales debajo de la fila `pos`, y esas líneas empujan hacia
-- abajo el resto del dashboard. Reservar espacio con líneas vacías dejaría
-- un hueco doble.
local util = require("dashboard.util")

-- Llama a `cb` cuando la imagen está convertida. Snacks.image.placement.new
-- con una imagen sin convertir (la primera vez, sin caché) borra el buffer
-- para mostrar "loading", y en el dashboard eso borraba todo el texto.
-- image.new arranca la conversión y queda en memoria: placement.new usa la
-- misma imagen después. Se rinde a los 10 s.
local function when_ready(path, cb)
   local img = Snacks.image.image.new(path)
   local tries = 0
   local timer = assert(vim.uv.new_timer())
   timer:start(
      0,
      50,
      vim.schedule_wrap(function()
         tries = tries + 1
         local ready, failed = img:ready(), img:failed()
         if not (ready or failed or tries > 200) then
            return
         end
         timer:stop()
         if not timer:is_closing() then
            timer:close()
         end
         if ready then
            cb()
         else
            vim.notify("dashboard: no se pudo cargar la imagen " .. path, vim.log.levels.WARN)
         end
      end)
   )
end

return function(p)
   return {
      sections = {},
      on_open = function(d)
         -- Preguntarle a la terminal si soporta imágenes con callback, no
         -- con Snacks.image.supports_terminal() directo: esa versión espera
         -- la respuesta con vim.wait(), y al arrancar eso deja correr antes
         -- de tiempo callbacks de otros plugins (el colorscheme rompía y el
         -- dashboard quedaba vacío).
         Snacks.image.terminal.detect(function()
            if not Snacks.image.supports_terminal() then
               return
            end
            when_ready(p.path, function()
               if not vim.api.nvim_buf_is_valid(d.buf) then
                  return
               end
               -- Dos filas arriba del primer texto (el título), centrada.
               local row = math.max(1, util.first_text_row(d.buf) - 2)
               local col =
                  math.max(0, math.floor((vim.api.nvim_win_get_width(d.win) - p.width) / 2))
               Snacks.image.placement.new(d.buf, p.path, {
                  pos = { row, col },
                  width = p.width,
                  height = p.height,
                  max_width = p.width,
                  max_height = p.height,
               })
            end)
         end)
      end,
   }
end
