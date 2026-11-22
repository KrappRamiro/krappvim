-- Un acuario animado (asciiquarium).
local terminal = require("dashboard.terminal")

return function(p)
   return {
      sections = {
         terminal({ cmd = "asciiquarium", height = p.height, width = p.width, animated = true }),
      },
   }
end
