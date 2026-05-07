-- nvim-colorizer.lua (catgoose's fork): highlightea color codes inline.
-- Ej: en CSS verás `#FF0000` con fondo rojo, `bg-red-500` con el color
-- de Tailwind, `rgb(0,255,0)` en verde, etc.
return {
   "nvim-colorizer.lua",
   auto_enable = true,
   event = "DeferredUIEnter",
   cmd = { "ColorizerToggle", "ColorizerAttachToBuffer", "ColorizerDetachFromBuffer" },
   keys = {
      { "<leader>tC", mode = "n" },
   },
   after = function()
      require("colorizer").setup({
         filetypes = { "*" }, -- atacha a todos; cambialo si querés solo ciertos
         user_default_options = {
            RGB = true, -- #RGB
            RRGGBB = true, -- #RRGGBB
            RRGGBBAA = true, -- #RRGGBBAA con alpha
            names = false, -- "Blue", "Red", etc. (false para no highlightear esos)
            rgb_fn = true, -- rgb()/rgba()
            hsl_fn = true, -- hsl()/hsla()
            css = true, -- css/scss/etc
            tailwind = true, -- bg-red-500, text-blue-700, etc
         },
      })

      vim.keymap.set("n", "<leader>tC", "<cmd>ColorizerToggle<cr>", { desc = "Toggle [C]olor highlighter" })
   end,
}
