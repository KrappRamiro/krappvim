return {
   "lualine.nvim",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function(plugin)
      require("lualine").setup({
         options = {
            icons_enabled = true,
            theme = nixInfo("onedark_dark", "settings", "colorscheme"),
            component_separators = "|",
            section_separators = "",
         },
         sections = {
            lualine_c = {
               { "filename", path = 1, status = true },
            },
            lualine_x = {
               {
                  -- shows "recording @q" when recording a macro
                  function() return require("noice").api.status.mode.get() end,
                  cond = function() return require("noice").api.status.mode.has() end,
               },
            },
         },
         inactive_sections = {
            lualine_b = {
               { "filename", path = 3, status = true },
            },
            lualine_x = { "filetype" },
         },
         tabline = {
            lualine_a = { "buffers" },
            -- if you use lualine-lsp-progress, I have mine here instead of fidget
            -- lualine_b = { 'lsp_progress', },
            lualine_z = { "tabs" },
         },
      })
   end,
}
