-- Imagen convertida en caracteres con chafa: anda en cualquier terminal.
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = ("chafa %s --format symbols --symbols %s --size %dx%d --stretch"):format(
      vim.fn.shellescape(p.path),
      vim.fn.shellescape(p.symbols),
      p.width,
      p.height
   )
   -- Centrada en el panel de 60 columnas de snacks.
   local indent = math.max(0, math.floor((60 - p.width) / 2))
   return { sections = { terminal({ cmd = cmd, height = p.height, indent = indent }) } }
end
