-- mini.nvim es una colección de módulos chicos; acá activamos los que usamos.
-- Todos viven en el mismo plugin, por eso van en un solo spec.
return {
   "mini.nvim",
   auto_enable = true,
   lazy = false,
   after = function(_)
      require("mini.icons").setup()

      -- mini.pairs: autocierre de pares. Escribís ( y aparece (), escribís )
      -- al lado de un ) y lo "saltea" en vez de duplicarlo, <BS> entre ()
      -- borra los dos. Ver :help mini.pairs
      -- Con la config default ya no inserta pares después de \ ni la ' después
      -- de una letra (para que "don't" no quede "don''t").
      require("mini.pairs").setup()

      -- En Rust la ' también se usa para lifetimes (&'a str, <'a>), y ahí
      -- autocerrar molesta: quedaría &''a. La doc de mini.pairs dice que un
      -- mapping global se revierte por buffer mapeando la tecla a sí misma.
      vim.api.nvim_create_autocmd("FileType", {
         group = vim.api.nvim_create_augroup("krappvim_minipairs_rust", { clear = true }),
         pattern = "rust",
         callback = function(args)
            vim.keymap.set("i", "'", "'", { buffer = args.buf, desc = "Literal ' (lifetimes)" })
         end,
      })
   end,
}
