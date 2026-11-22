-- git status del repo actual (solo dentro de un repo).
local terminal = require("dashboard.terminal")

return function(p)
   return {
      sections = {
         terminal({
            icon = "\238\156\165 ", -- U+E725 (rama)
            title = "Git Status",
            cmd = "git status --short --branch --renames",
            height = p.height,
            indent = 3,
            enabled = function()
               return Snacks.git.get_root() ~= nil
            end,
         }),
      },
   }
end
