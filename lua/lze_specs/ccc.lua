-- ccc.nvim: color picker + highlighter para colores hex/rgb/hsl/etc.
-- - :CccPick               -->  UI con sliders, elegís color, lo inserta
-- - :CccConvert            -->  convierte entre formatos (HEX ↔ RGB ↔ HSL)
-- - :CccHighlighterToggle  -->  toggle del highlighter inline (lo dejamos OFF porque tenemos colorizer haciendo lo mismo)

return {
   "ccc.nvim",
   auto_enable = true,
   cmd = { "CccPick", "CccConvert" },
   keys = {
      { "<leader>Cp", mode = "n" },
   },
   after = function()
      require("ccc").setup({
         -- highlighter inline OFF: nvim-colorizer.lua se encarga de eso.
         -- Si querés volver al de ccc, poné auto_enable = true acá y
         -- desactivá colorizer en lze_specs/colorizer.lua.
         highlighter = {
            auto_enable = false,
            lsp = false,
         },
      })

      vim.keymap.set("n", "<leader>Cp", "<cmd>CccPick<cr>", { desc = "[C]olor [P]ick" })

      ---  --- --- --- --- ---

      -- Cheatsheet de shortcuts en una float SEPARADA, pegada debajo de la
      -- de ccc. La de ccc tiene tamaño fijo y no podemos dibujar adentro,
      -- así que abrimos una float adyacente que se cierra cuando ccc cierra.
      -- TODO: Hacer mas lindo esto, queda medio feo
      local CHEATSHEET_LINES = {
         " <CR>   insert      |  q    quit           |  a    toggle alpha ",
         " i    input mode    |  o      output mode  |  r    reset modes ",
         " h/l    ±1          |  s/d  ±5             |  m/,  ±10 ",
         " H/M/L  0/50/100%   |  1-9  10%-90%        |  g    palette ",
      }
      local CHEATSHEET_MIN_WIDTH = 64
      local CHEATSHEET_GAP = 4 -- filas vacias entre el float de ccc y el cheatsheet, basicamente para que no se superpongan

      local augroup = vim.api.nvim_create_augroup("ccc_cheatsheet", { clear = true })
      local hl_ns = vim.api.nvim_create_namespace("ccc_cheatsheet")
      local cheatsheet_win
      local poll_timer

      local function close_cheatsheet()
         if poll_timer then
            poll_timer:stop()
            poll_timer:close()
            poll_timer = nil
         end
         if cheatsheet_win and vim.api.nvim_win_is_valid(cheatsheet_win) then
            vim.api.nvim_win_close(cheatsheet_win, true)
         end
         cheatsheet_win = nil
      end

      local function open_cheatsheet(ccc_buf)
         close_cheatsheet() -- defensive: si quedó alguna abierta de antes, la cerramos

         local ccc_win = vim.fn.bufwinid(ccc_buf)
         if ccc_win == -1 then return end

         -- nvim_win_get_position devuelve [row, col] absolutos en pantalla
         -- (a diferencia de cfg.row/col, que pueden ser relativos a cursor/win)
         local pos = vim.api.nvim_win_get_position(ccc_win)
         local height = vim.api.nvim_win_get_height(ccc_win)
         local width = vim.api.nvim_win_get_width(ccc_win)

         local buf = vim.api.nvim_create_buf(false, true)
         vim.api.nvim_buf_set_lines(buf, 0, -1, false, CHEATSHEET_LINES)
         vim.bo[buf].modifiable = false
         vim.bo[buf].filetype = "ccc-cheatsheet"

         -- Decidir si el cheatsheet va abajo o arriba de ccc según el
         -- espacio disponible. +2 cuenta los bordes (top + bottom).
         local needed_height = #CHEATSHEET_LINES + 2
         local row_below = pos[1] + height + CHEATSHEET_GAP
         local fits_below = row_below + needed_height <= vim.o.lines
         local row = fits_below
               and row_below
            or math.max(0, pos[1] - CHEATSHEET_GAP - needed_height)

         cheatsheet_win = vim.api.nvim_open_win(buf, false, {
            relative = "editor",
            row = row,
            col = pos[2],
            width = math.max(width, CHEATSHEET_MIN_WIDTH),
            height = #CHEATSHEET_LINES,
            style = "minimal",
            border = "rounded",
            focusable = false,
            noautocmd = true,
         })

         -- style = "minimal" no desactiva wrap por default, lo apagamos explicito
         vim.wo[cheatsheet_win].wrap = false

         -- highlight todo el contenido como Comment (gris suave). Usamos
         -- nvim_buf_set_extmark porque nvim_buf_add_highlight quedó deprecada
         -- en nvim 0.11+.
         for i, line in ipairs(CHEATSHEET_LINES) do
            vim.api.nvim_buf_set_extmark(buf, hl_ns, i - 1, 0, {
               end_col = #line,
               hl_group = "Comment",
            })
         end

         -- Polling: cada 200ms chequeamos si la window de ccc sigue viva.
         -- Cuando deja de existir (por el camino que sea: q, <CR>, click
         -- afuera, otro plugin la cerró, etc.) cerramos el cheatsheet.
         -- Latencia: hasta 200ms - imperceptible. Más confiable que stackear
         -- WinClosed/WinLeave/BufHidden, que dependen de cómo ccc cierra.
         poll_timer = vim.uv.new_timer()
         poll_timer:start(200, 200, vim.schedule_wrap(function()
            if not vim.api.nvim_win_is_valid(ccc_win) then
               close_cheatsheet()
            end
         end))
      end

      vim.api.nvim_create_autocmd("FileType", {
         group = augroup,
         pattern = "ccc-ui",
         callback = function(args)
            -- vim.schedule: damos un tick para que ccc termine de posicionar su float
            vim.schedule(function() open_cheatsheet(args.buf) end)
         end,
      })
   end,
}
