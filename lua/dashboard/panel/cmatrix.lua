-- Lluvia de Matrix (cmatrix), animada.
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = "cmatrix -b -u 4 -C " .. vim.fn.shellescape(p.color)
   return {
      sections = { terminal({ cmd = cmd, height = p.height, width = p.width, animated = true }) },
   }
end
