-- Un pokémon al azar (pokemon-colorscripts). Con `random = N`, snacks
-- guarda N salidas distintas y muestra una en cada arranque.
local terminal = require("dashboard.terminal")

return function(p)
   return {
      sections = {
         terminal({
            cmd = "pokemon-colorscripts -r --no-title",
            random = p.random,
            height = p.height,
            indent = 4,
         }),
      },
   }
end
