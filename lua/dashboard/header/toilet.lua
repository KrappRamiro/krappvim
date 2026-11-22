-- Texto grande con toilet. Los filtros de color (gay, metal) escriben
-- códigos ANSI, por eso va en una sección terminal y no como texto.
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = ("toilet -f %s"):format(vim.fn.shellescape(p.font))
   if p.filter then
      cmd = cmd .. " -F " .. vim.fn.shellescape(p.filter)
   end
   cmd = cmd .. " " .. vim.fn.shellescape(p.text)
   return {
      sections = { terminal({ cmd = cmd, height = p.height, indent = p.indent, padding = 2 }) },
   }
end
