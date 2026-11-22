-- Texto de figlet con arcoíris animado (lolcat -a).
local terminal = require("dashboard.terminal")

return function(p)
   local cmd = ("figlet -f %s %s | lolcat -a -d 4 -s 40 -F 0.2"):format(
      vim.fn.shellescape(p.font),
      vim.fn.shellescape(p.text)
   )
   return { sections = { terminal({ cmd = cmd, height = p.height, indent = 4, animated = true }) } }
end
