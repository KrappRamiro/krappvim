return {
   "lualine.nvim",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function()
      -- ── helper: contador de búsqueda ────────────────────────────────────
      -- Cuando hacés / o ? y navegás por resultados, muestra "3/15".
      -- Solo aparece si hay highlight de búsqueda activo (después de un /).
      local function search_count()
         if vim.v.hlsearch == 0 then return "" end
         local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
         if not ok or next(result) == nil then return "" end
         local denom = math.min(result.total, result.maxcount)
         return string.format("Search: %d/%d", result.current, denom)
      end

      -- ── helper: indicador de macro recording ────────────────────────────
      -- Reemplaza el de noice (que usaba undefined-field). Esta versión
      -- usa la API estable de Vim: vim.fn.reg_recording() devuelve el
      -- registro activo o "" si no hay grabación.
      local function macro_recording()
         local reg = vim.fn.reg_recording()
         return reg ~= "" and ("recording @" .. reg) or ""
      end

      require("lualine").setup({
         options = {
            icons_enabled = true,
            theme = nixInfo("onedark_dark", "settings", "colorscheme"),
            -- separadores estilo powerline (necesitan nerd font, ya tenés)
            component_separators = { left = "│", right = "│" },
            section_separators = { left = "", right = "" },
         },
         sections = {
            lualine_c = {
               { "filename", path = 1, status = true },
            },
            lualine_x = {
               { macro_recording }, -- "recording @q" cuando grabás macro
               { search_count }, -- "3/15" cuando navegás búsquedas
               "encoding", -- utf-8, latin1, etc.
               "fileformat", -- unix, dos, mac
               "filetype", -- lua, typescript, etc.
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
