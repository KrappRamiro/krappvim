-- Ayudas para las piezas que dibujan encima del dashboard ya armado.
local M = {}

-- Primera fila (1 = primera línea) con texto visible, o 1 si no hay.
function M.first_text_row(buf)
   for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      if l:match("%S") then
         return i
      end
   end
   return 1
end

return M
