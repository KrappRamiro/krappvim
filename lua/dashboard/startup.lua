-- Reemplazo de `section = "startup"` de snacks, que hace
-- require("lazy.stats") y rompe en kvim (usamos lze, no lazy.nvim).
--
-- Mide la edad del proceso: /proc/uptime (segundos desde que arrancó la
-- máquina) menos el campo 22 de /proc/self/stat (cuándo arrancó kvim, en
-- ticks de 1/100 s). Se calcula la primera vez que snacks dibuja la sección,
-- o sea cuando el dashboard ya está en pantalla, no al cargar este archivo.
local M = {}

local ms

local function read(path)
   local f = io.open(path)
   if not f then
      return nil
   end
   local s = f:read("*a")
   f:close()
   return s
end

function M.ms()
   if ms then
      return ms
   end
   local stat, uptime = read("/proc/self/stat"), read("/proc/uptime")
   if not stat or not uptime then
      return nil
   end
   -- El nombre del proceso (campo 2) va entre paréntesis y puede tener
   -- espacios, así que se cuenta desde el ")": campo 3 y 19 más = campo 22.
   local fields = stat:match("%) (%S+" .. string.rep(" %S+", 19) .. ")")
   local start = tonumber(fields and fields:match("(%d+)$"))
   local up = tonumber(uptime:match("^(%S+)"))
   if not start or not up then
      return nil
   end
   ms = math.floor((up - start / 100) * 1000)
   return ms
end

-- Sección función: snacks la evalúa al dibujar. Si a la primera no hay
-- dato (no es Linux), no muestra nada.
function M.section()
   return function()
      local n = M.ms()
      if not n then
         return {}
      end
      return {
         text = {
            { "\239\131\167 ", hl = "SnacksDashboardSpecial" }, -- U+F0E7 (rayo)
            { "kvim listo en ", hl = "SnacksDashboardFooter" },
            { n .. " ms", hl = "SnacksDashboardSpecial" },
         },
         align = "center",
         padding = 1,
      }
   end
end

return M
