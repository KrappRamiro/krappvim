-- Un bonsái. Con `live` se lo ve crecer (animado); si no, aparece entero.
-- LC_ALL=C: con locale en español, cbonsai lee "0.04" como inválido.
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = p.live and "LC_ALL=C cbonsai -l -t 0.04 -L 40" or "LC_ALL=C cbonsai -p -L 40"
   return { sections = { terminal({ cmd = cmd, height = p.height, animated = p.live }) } }
end
