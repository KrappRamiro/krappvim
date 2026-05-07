return {
   "tiny-inline-diagnostic",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function()
      vim.diagnostic.config({ virtual_text = false })
      require("tiny-inline-diagnostic").setup({
         options = {

            show_source = {
               enabled = true, -- Shows from where the error msg originates
            },

            -- Display the diagnostic code of diagnostics (e.g., "F401", "no-dupe-args")
            show_code = true,

            -- Color the arrow to match the severity of the first diagnostic
            set_arrow_to_diag_color = true,

            -- Show all diagnostics on the current cursor line, not just those under the cursor
            show_all_diags_on_cursorline = true,

            multilines = {
               enabled = true, -- Enable support for multiline diagnostic messages
               always_show = true, -- Always show messages on all lines of multiline diagnostics
            },
         },
      })
   end,
}
