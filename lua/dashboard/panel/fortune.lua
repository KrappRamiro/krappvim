-- Una frase de fortune, opcionalmente dicha por la vaca de cowsay. Con
-- random = 10 snacks guarda diez frases y rota entre ellas.
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = "fortune" .. (p.short and " -s" or "")
   if p.cow then
      cmd = cmd .. " | cowsay"
   else
      -- sin vaca, que la frase entre en una línea del dashboard
      cmd = cmd .. " -n 70"
   end
   return {
      sections = {
         terminal({
            cmd = cmd,
            height = p.height,
            random = 10,
            indent = p.cow and 8 or 10,
            hl = "Comment",
         }),
      },
   }
end
