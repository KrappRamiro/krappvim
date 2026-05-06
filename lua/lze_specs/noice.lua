-- Noice replaces the cmdline, messages, and popupmenu UI with floating windows.
-- nui.nvim is a required dependency for rendering those UI components.
return {
   {
      "nui.nvim",
      auto_enable = true,
      dep_of = { "noice.nvim" },
   },
   {
      "noice.nvim",
      auto_enable = true,
      event = "DeferredUIEnter",
      after = function(_)
         -- vim.notify() calls are handled by snacks notifier (top-right popups)
         -- instead of noice's built-in notify view
         vim.notify = Snacks.notifier.notify

         require("noice").setup({
            lsp = {
               -- use treesitter to render markdown in LSP hover and signature popups
               override = {
                  ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                  ["vim.lsp.util.stylize_markdown"] = true,
               },
            },
            presets = {
               -- donde poner la UI:
               --   false lo pone en el centro de la pantalla
               --   true lo pone arriba
               command_palette = false,
               -- Ojo! aplica a mensajes de Neovim internos (como output de comandos ex), no a vim.notify().
               long_message_to_split = true, -- long messages open in a split instead of a popup
               inc_rename = false, -- we don't have inc-rename.nvim
               lsp_doc_border = true, -- border on LSP hover/signature popups
            },
         })
      end,
   },
}
