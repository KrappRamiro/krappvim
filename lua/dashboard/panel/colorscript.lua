-- Un dibujo de dwt1-shell-color-scripts (`colorscript -l` los lista).
local terminal = require("dashboard.terminal")

return function(p)
   return {
      sections = {
         terminal({ cmd = "colorscript -e " .. vim.fn.shellescape(p.name), height = p.height }),
      },
   }
end
