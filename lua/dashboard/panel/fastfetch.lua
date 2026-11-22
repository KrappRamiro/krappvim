-- Datos del sistema con fastfetch (logo, kernel, memoria).
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = ("fastfetch --logo %s -s %s"):format(
      vim.fn.shellescape(p.logo),
      vim.fn.shellescape(p.modules)
   )
   return { sections = { terminal({ cmd = cmd, height = p.height, indent = 6 }) } }
end
