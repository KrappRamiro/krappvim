-- Cualquier comando: su salida (con colores) arriba del dashboard.
local terminal = require("dashboard.terminal")

return function(p)
   return { sections = { terminal(p) } }
end
