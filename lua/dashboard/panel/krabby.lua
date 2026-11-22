-- Como pokemon, con krabby (más rápido, escrito en Rust).
local terminal = require("dashboard.terminal")

return function(p)
   return {
      sections = {
         terminal({
            cmd = "krabby random --no-title",
            random = p.random,
            height = p.height,
            indent = 4,
         }),
      },
   }
end
