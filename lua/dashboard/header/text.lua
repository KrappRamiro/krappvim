-- Arte fijo: el texto tal cual, sin correr nada.
return function(p)
   return { header = p.text, sections = { { section = "header" } } }
end
