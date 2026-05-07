-- multicursor.nvim (jake-stewart): multicursor estilo VSCode.
--
-- Flow tipico:
--   1. Parate sobre una palabra
--   2. <C-n> -> selecciona la palabra + agrega un cursor en la PROXIMA ocurrencia
--   3. <C-n> de nuevo -> otra ocurrencia más
--   4. Tipeás -> editás todas a la vez
--   5. <Esc> -> vuelve a un solo cursor
return {
   "multicursor.nvim",
   auto_enable = true,
   keys = {
      { "<C-n>", mode = { "n", "v" } },
      { "<leader>m", mode = { "n", "v" } },
      { "<C-Up>", mode = { "n", "v" } },
      { "<C-Down>", mode = { "n", "v" } },
   },
   after = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      -- Hacer que los cursores SECUNDARIOS se vean distintos del principal.
      -- Tu cursor activo mantiene el estilo default de Vim; los otros se
      -- pintan con un naranja gruvbox-friendly. Re-aplicamos en ColorScheme
      -- para que sobreviva si cambiás de tema.
      local function set_mc_highlights()
         local hl = vim.api.nvim_set_hl
         hl(0, "MultiCursorCursor", { bg = "#fe8019", fg = "#1d2021", bold = true })
         hl(0, "MultiCursorVisual", { bg = "#3c3836" })
         hl(0, "MultiCursorSign", { fg = "#fe8019" })
      end
      set_mc_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
         group = vim.api.nvim_create_augroup("multicursor_hl", { clear = true }),
         callback = set_mc_highlights,
      })

      local map = function(lhs, rhs, desc, modes)
         vim.keymap.set(modes or { "n", "v" }, lhs, rhs, { desc = desc })
      end

      -- Acción principal estilo VSCode: agregar cursor en próxima coincidencia
      map("<C-n>", function() mc.matchAddCursor(1) end, "Multicursor: add next match")
      map("<leader>mN", function() mc.matchAddCursor(-1) end, "Multicursor: add prev match")

      -- Saltearse una coincidencia sin agregarla
      map("<leader>ms", function() mc.matchSkipCursor(1) end, "Multicursor: skip next match")
      map("<leader>mS", function() mc.matchSkipCursor(-1) end, "Multicursor: skip prev match")

      -- Cmd+Shift+L de VSCode: cursor en TODAS las coincidencias del símbolo
      map("<leader>mA", function() mc.matchAllAddCursors() end, "Multicursor: add cursors to all matches")

      -- Agregar cursor en la línea de arriba/abajo (column-style multi-edit)
      map("<C-Up>", function() mc.lineAddCursor(-1) end, "Multicursor: add cursor above")
      map("<C-Down>", function() mc.lineAddCursor(1) end, "Multicursor: add cursor below")

      -- Salir del modo multicursor
      map("<Esc>", function()
         if not mc.cursorsEnabled() then
            mc.enableCursors()
         elseif mc.hasCursors() then
            mc.clearCursors()
         else
            -- pasaje normal del Esc al resto de Vim
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
         end
      end, "Multicursor: clear / fallback Esc", { "n" })

      -- Layer: keymaps que SOLO existen mientras hay cursores activos.
      -- Permite reusar keys que normalmente significan otra cosa (ej: <left>),
      -- sin romper el comportamiento default de Vim cuando no hay multicursor.
      mc.addKeymapLayer(function(layerSet)
         -- Des-agregar: borra el cursor "principal" (el activo). Sirve cuando
         -- te pasaste con <C-n> y querés sacar el último que agregaste.
         layerSet({ "n", "x" }, "<leader>mx", mc.deleteCursor)

         -- Rotar entre los cursores activos (cambia cuál es el "principal").
         -- Útil si tenés varios y querés posicionarte en uno específico.
         layerSet({ "n", "x" }, "<left>", mc.prevCursor)
         layerSet({ "n", "x" }, "<right>", mc.nextCursor)
      end)
   end,
}
