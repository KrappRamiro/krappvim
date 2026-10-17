-- crates.nvim: ayuda con las dependencias dentro de Cargo.toml
--   * completa nombres de crates (busca en crates.io), versiones y features
--   * muestra al lado de cada dependencia si hay una versión más nueva
--   * code actions (<leader>ca): actualizar versión, expandir a tabla, etc.
--
-- Usa un "language server in-process": crates.nvim se registra como un cliente
-- LSP más, así blink lo toma con su fuente "lsp" sin configurar nada extra.
-- Es el modo que recomienda la doc (las fuentes de nvim-cmp/coq están deprecadas).
-- Ver :help crates-config-lsp
return {
   "crates.nvim",
   auto_enable = true,
   -- solo carga cuando abrís un Cargo.toml (mismo trigger que usa LazyVim)
   event = "BufRead Cargo.toml",
   after = function()
      require("crates").setup({
         -- completa nombres de crates buscando en crates.io
         completion = {
            crates = {
               enabled = true,
            },
         },
         lsp = {
            enabled = true,
            actions = true,
            completion = true,
            hover = true,
         },
      })
   end,
}
