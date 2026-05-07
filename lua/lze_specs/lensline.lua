-- lensline.nvim: muestra info contextual arriba (o inline) de cada función:
-- ref count via LSP, último autor git, complejidad, diagnostics, etc.
-- Provider-based: cada item es un provider que se puede prender/apagar
-- independiente.
--
-- Comandos relevantes (lensline expone dos niveles de toggle):
--   :LenslineToggleView    →  muestra/esconde el visual (providers siguen
--                             corriendo en background) — el más común
--   :LenslineToggleEngine  →  enable/disable completo (libera recursos)
--   :LenslineProfile <n>   →  cambiar entre profiles configurados acá
return {
   "lensline.nvim",
   auto_enable = true,
   event = "LspAttach",
   cmd = {
      "LenslineEnable",
      "LenslineDisable",
      "LenslineToggleEngine",
      "LenslineShow",
      "LenslineHide",
      "LenslineToggleView",
      "LenslineProfile",
   },
   keys = {
      { "<leader>tl", mode = "n" },
   },
   after = function()
      require("lensline").setup({
         profiles = {
            {
               name = "default",
               providers = {
                  -- Cuántas veces se referencia esta función (LSP)
                  {
                     name = "usages",
                     enabled = true,
                     include = { "refs" },
                     breakdown = true, --  "5 refs, 2 defs, 1 impls" en lugar de "8 usages" 
                     show_zero = true,
                  },
                  -- Último autor git que tocó esta función
                  {
                     name = "last_author",
                     enabled = true,
                  },
                  -- Otros providers disponibles si los querés activar:
                  --   { name = "diagnostics", enabled = true, min_level = "WARN" },
                  --   { name = "complexity",  enabled = true, min_level = "L" },
               },
               style = {
                  separator = " • ",
                  highlight = "Comment",
                  prefix = "┃ ",
                  placement = "above", -- "above" | "inline"  , no lo pongo inline porque choca con tiny_inline_diagnostic
                  use_nerdfont = true,
                  render = "all", -- "all" | "focused"
               },
            },
         },
         silence_lsp = true, -- suprime spam de algunos LSPs (ej: pyright)
      })

      -- Toggle visual (más comun y barato): esconde lenses pero deja los
      -- providers corriendo en background. Ideal cuando solo querés un
      -- buffer "limpio" momentáneo.
      vim.keymap.set("n", "<leader>tl", "<cmd>LenslineToggleView<cr>", { desc = "Toggle [l]ensline view" })
   end,
}
