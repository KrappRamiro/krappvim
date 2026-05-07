-- flash.nvim: navegación con search labels (treesitter mode).
-- - S (n/x/o):  treesitter  →  selecciona el nodo más cercano del árbol
-- - r (o):      remote      →  motion en una ubicación remota (avanzado)
-- - R (o/x):    treesitter search
-- - <c-s> (c):  toggle flash mientras buscás con / o ?
-- (HopWord ocupa la `s` para jumps simples, ver lze_specs/hop.lua)
return {
   "flash.nvim",
   auto_enable = true,
   keys = {
      { "S", mode = { "n", "x", "o" } },
      { "r", mode = "o" },
      { "R", mode = { "o", "x" } },
      { "<c-s>", mode = "c" },
   },
   after = function()
      require("flash").setup({})

      local flash = require("flash")

      -- Importante (de la docu oficial): NO usar :lua en los keymaps.
      -- Hay que pasar funciones para que dot-repeat (.) funcione bien.
      vim.keymap.set({ "n", "x", "o" }, "S", function() flash.treesitter() end, { desc = "Flash Treesitter" })
      vim.keymap.set("o", "r", function() flash.remote() end, { desc = "Remote Flash" })
      vim.keymap.set({ "o", "x" }, "R", function() flash.treesitter_search() end, { desc = "Treesitter Search" })
      vim.keymap.set("c", "<c-s>", function() flash.toggle() end, { desc = "Toggle Flash Search" })
   end,
}
