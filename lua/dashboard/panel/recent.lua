-- Archivos recientes con título (en el panel; los de abajo de las teclas
-- son la opción `recent`).
return function(p)
   return {
      sections = {
         {
            icon = "\239\133\155 ", -- U+F15B (archivo)
            title = "Recent Files",
            section = "recent_files",
            limit = p.limit,
            indent = 2,
            padding = 1,
         },
      },
   }
end
