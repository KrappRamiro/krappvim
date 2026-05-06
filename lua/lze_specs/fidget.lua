-- Extensible UI for Neovim notifications and LSP progress messages
-- Indenpendent from noice and notify API
-- Es la que aparece abajo a la derecha cuando cargan cosas del LSP
return {
   "fidget.nvim",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function(plugin)
      require("fidget").setup({})
   end,
}
