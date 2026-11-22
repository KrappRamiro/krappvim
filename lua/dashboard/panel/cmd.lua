-- Cualquier comando en el panel.
local terminal = require("dashboard.terminal")

return function(p)
   return { sections = { terminal(p) } }
end
