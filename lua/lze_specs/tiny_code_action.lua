-- tiny-code-action.nvim: reemplaza el dropdown chiquito de Neovim que
-- aparece con vim.lsp.buf.code_action() por un picker decente con diff preview.
-- Apretás <leader>ca, ves la lista de actions a la izquierda y el diff de
-- lo que va a cambiar a la derecha. El keymap como tal se setea en
-- lze_specs/lsp.lua dentro del on_attach del LSP.
return {
   "tiny-code-action",
   auto_enable = true,
   event = "LspAttach",
   after = function()
      require("tiny-code-action").setup({
         backend = "delta", -- diffs con syntax highlight, line numbers
         picker = "snacks", -- usa Snacks.picker (ya tenemos snacks)
         backend_opts = {
            delta = {
               -- delta agrega un header largo con info de hunks; sacamos las
               -- primeras 4 líneas que no aportan en el contexto del picker
               header_lines_to_remove = 4,
               args = { "--line-numbers" },
            },
         },
         resolve_timeout = 100, --Timeout in milliseconds to resolve code actions
         notify = {
            enabled = true,
            on_empty = true, -- avisa cuando no hay code actions disponibles
         },
      })
   end,
}
