-- markview.nvim: render in-buffer de markdown (headings con estilo, listas
-- con bullets, code blocks resaltados, checkboxes, links, tablas con bordes
-- Unicode, etc.). 100% nativo: treesitter + lua, sin servidor ni dependencias
-- externas.
--
-- Killer feature: hybrid mode. En modo normal ves el render bonito; cuando
-- el cursor cae en un nodo, ese nodo vuelve a raw para editarlo cómodo.
--
-- Todos los keymaps viven bajo <leader>M* (declarados también en which-key).
--   Convención: minúscula = buffer actual, mayúscula = global (todos los
--   buffers attachados).
return {
   "markview.nvim",
   auto_enable = true,
   -- Lazy en archivos markdown y en el comando :Markview.
   ft = { "markdown", "Avante", "codecompanion" },
   cmd = { "Markview" },
   keys = {
      -- Toggle render
      { "<leader>Mt", "<cmd>Markview toggle<cr>",       desc = "[t]oggle render (current buffer)" },
      { "<leader>MT", "<cmd>Markview Toggle<cr>",       desc = "[T]oggle render (all buffers)" },
      -- Toggle hybrid mode (raw bajo cursor)
      { "<leader>Mh", "<cmd>Markview hybridToggle<cr>", desc = "Toggle [h]ybrid mode (current)" },
      { "<leader>MH", "<cmd>Markview HybridToggle<cr>", desc = "Toggle [H]ybrid mode (all)" },
      -- Forzar re-render (útil si quedó stale después de un edit grande)
      { "<leader>Mr", "<cmd>Markview render<cr>",       desc = "[r]e-render (current buffer)" },
      { "<leader>MR", "<cmd>Markview Render<cr>",       desc = "[R]e-render (all buffers)" },
      -- Limpiar overlays sin desactivar markview
      { "<leader>Mc", "<cmd>Markview clear<cr>",        desc = "[c]lear overlays (current)" },
      { "<leader>MC", "<cmd>Markview Clear<cr>",        desc = "[C]lear overlays (all)" },
      -- Cambiar entre clear-por-nodo y clear-por-línea en hybrid mode
      { "<leader>Ml", "<cmd>Markview linewiseToggle<cr>", desc = "Toggle [l]inewise hybrid mode" },
      -- Splitview: preview en un split aparte
      { "<leader>Ms", "<cmd>Markview splitToggle<cr>",  desc = "Toggle [s]plitview preview" },
      -- Abrir link bajo cursor (Markdown style: [text](url) o fragment #heading)
      { "<leader>Mo", "<cmd>Markview open<cr>",         desc = "[o]pen link under cursor" },
      -- Debug trace (útil para diagnosticar issues como tablas que no rinden)
      { "<leader>Md", "<cmd>Markview traceShow<cr>",    desc = "Show [d]ebug trace" },
   },
   after = function()
      require("markview").setup({
         preview = {
            -- Modos donde se muestra el render. Excluyo insert (i) para ver
            -- el raw mientras escribís.
            modes = { "n", "no", "c" },
            -- Modos en los que el nodo bajo cursor vuelve a raw markdown.
            hybrid_modes = { "n" },
         },
         experimental = {
            -- Abrir links a archivos de texto (como otros .md) DENTRO de
            -- Neovim en vez de delegar al handler del OS (que abriría .md
            -- con Preview / TextEdit / lo que tengas asociado).
            prefer_nvim = true,
            -- Comando con el que se abre. Opciones útiles:
            --   "edit"   → reemplaza el buffer actual (estilo browsing)
            --   "tabnew" → cada link abre un tab nuevo
            --   "vsplit" → split vertical
            file_open_command = "edit",
         },
      })
   end,
}
