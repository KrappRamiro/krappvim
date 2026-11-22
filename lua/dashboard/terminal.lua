-- Sección `terminal` de snacks a partir de los parámetros de una pieza.
--
-- snacks guarda la salida en caché (`ttl`, en segundos) y la muestra al
-- instante en el próximo arranque. Un programa animado no sirve cacheado:
-- con `animated` va `ttl = 0` (nunca se cachea) y el comando termina en un
-- `sleep` largo, porque cuando el proceso termina snacks escribe
-- "[Process exited 0]" encima del dibujo.
return function(p)
   local cmd = p.cmd
   local ttl = p.ttl
   if p.animated then
      ttl = 0
      cmd = cmd .. "; sleep 600"
   end
   return {
      section = "terminal",
      cmd = cmd,
      height = p.height,
      width = p.width,
      ttl = ttl,
      random = p.random,
      indent = p.indent,
      title = p.title,
      icon = p.icon,
      hl = p.hl,
      enabled = p.enabled,
      padding = p.padding or 1,
   }
end
