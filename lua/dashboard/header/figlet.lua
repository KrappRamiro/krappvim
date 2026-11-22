-- Texto grande con figlet. Como no tiene color, la salida va como texto del
-- header y snacks la centra (una sección terminal queda a la izquierda).
return function(p)
   local out = vim.fn.systemlist({ "figlet", "-f", p.font, p.text })
   if vim.v.shell_error ~= 0 then
      error("figlet falló: " .. table.concat(out, " "))
   end
   return { header = table.concat(out, "\n"), sections = { { section = "header" } } }
end
