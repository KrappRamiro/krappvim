-- Splash animado de milli. snacks dibuja el primer frame como header y,
-- cuando el dashboard está en pantalla, milli busca esas líneas y anima
-- encima.
return function(p)
   local data
   if p.splashFile then
      -- Splash propio generado con `milli export -t lua`
      data = dofile(p.splashFile)
   else
      data = require("milli").load({ splash = p.splash })
   end
   return {
      header = table.concat(data.frames[1], "\n"),
      sections = { { section = "header" } },
      on_open = function(d)
         -- Con `data` (y no el nombre) milli anima el mismo splash que se
         -- dibujó, también con splash = "random".
         require("milli").play(d.buf, { data = data, loop = p.loop })
      end,
   }
end
