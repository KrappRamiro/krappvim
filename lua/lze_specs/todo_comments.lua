-- todo-comments.nvim: resalta comentarios tipo `TODO:`, `NOTE:`, `FIX:`,
-- `HACK:`, `WARN:`, `PERF:` con color e ícono en la columna de signos.
-- Solo matchea dentro de comentarios (usa treesitter) y necesita los dos
-- puntos: "TODO: algo" sí, "TODO algo" no (evita falsos positivos).
--
-- La búsqueda en todo el proyecto usa ripgrep y se muestra en el picker de
-- snacks: todo-comments registra la fuente `todo_comments` al hacer setup.
return {
   "todo-comments.nvim",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function()
      local todo = require("todo-comments")
      todo.setup({})

      vim.keymap.set("n", "]t", function()
         todo.jump_next()
      end, { desc = "Next todo comment" })
      vim.keymap.set("n", "[t", function()
         todo.jump_prev()
      end, { desc = "Previous todo comment" })

      vim.keymap.set("n", "<leader>st", function()
         Snacks.picker.todo_comments()
      end, { desc = "Todo comments" })
      vim.keymap.set("n", "<leader>sT", function()
         Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
      end, { desc = "Todo/Fix/Fixme comments" })
   end,
}
