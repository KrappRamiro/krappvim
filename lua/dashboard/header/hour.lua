-- Header según la hora: un comando de noche, otro de mañana y otro de tarde.
local terminal = require("dashboard.terminal")

return function(p)
   local h = tonumber(os.date("%H"))
   local cmd = h < 6 and p.night or h < 13 and p.morning or p.afternoon
   return {
      sections = { terminal({ cmd = cmd, height = p.height, indent = p.indent, padding = 2 }) },
   }
end
