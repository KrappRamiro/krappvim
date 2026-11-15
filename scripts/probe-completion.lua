-- Muestra qué sugiere blink.cmp, en qué orden y con qué puntaje, en un
-- proyecto real. Sirve para medir cambios al ranking de completion.lua en vez
-- de adivinar: correlo antes y después del cambio y compará.
--
-- Uso (desde la raíz del proyecto a probar, con su toolchain en el PATH):
--
--   PROBE_CASES=casos.lua PROBE_OUT=salida.txt \
--     /ruta/a/krappvim/result/bin/kvim --headless src/main.rs \
--     -c "luafile /ruta/a/krappvim/scripts/probe-completion.lua"
--
-- Si el proyecto usa direnv/devenv, anteponé `direnv exec .` al comando.
--
-- casos.lua devuelve una lista. Cada caso inserta una línea temporal DESPUÉS
-- de la línea `line` (1-based) y pide el completado al final de `text`:
--
--   return {
--      { line = 41, text = "        ", title = "match arm vacío" },
--      { line = 95, text = "    display.in", title = "método con prefijo" },
--   }
--
-- Variables opcionales:
--   PROBE_LSP   nombre del cliente LSP a esperar (default: rust_analyzer)
--   PROBE_WAIT  segundos de espera a que el LSP indexe (default: 60)
--   PROBE_TOP   cuántos items listar por caso (default: 12)
--
-- El buffer nunca se guarda. Columnas de la salida:
--   score  puntaje final (fuzzy + off + proximity/frecency)
--   off    score_offset del item (provider + transform_items)
--   sort   sortText que mandó el LSP

local cases = dofile(assert(os.getenv("PROBE_CASES"), "falta PROBE_CASES"))
local out_path = assert(os.getenv("PROBE_OUT"), "falta PROBE_OUT")
local lsp_name = os.getenv("PROBE_LSP") or "rust_analyzer"
local wait_s = tonumber(os.getenv("PROBE_WAIT")) or 60
local top = tonumber(os.getenv("PROBE_TOP")) or 12

local out = {}
local function finish()
   vim.fn.writefile(out, out_path)
   vim.cmd.quitall({ bang = true })
end

local function dump(title)
   local items = require("blink.cmp.completion.list").items
   table.insert(out, ("== %s (%d items)"):format(title, #items))
   for i = 1, math.min(top, #items) do
      local it = items[i]
      table.insert(
         out,
         ("%2d %-34s score=%-4s off=%-4s sort=%-8s src=%s"):format(
            i,
            it.label,
            tostring(it.score),
            tostring(it.score_offset),
            tostring(it.sortText),
            it.source_id
         )
      )
   end
end

local function run_case(index)
   local case = cases[index]
   if not case then
      return finish()
   end
   vim.cmd.stopinsert()
   vim.api.nvim_buf_set_lines(0, case.line, case.line, false, { case.text })
   vim.api.nvim_win_set_cursor(0, { case.line + 1, #case.text })
   vim.cmd.startinsert({ bang = true })
   vim.defer_fn(function()
      require("blink.cmp").show()
      -- 3s: el LSP puede tardar en responder en proyectos grandes
      vim.defer_fn(function()
         dump(case.title or case.text)
         require("blink.cmp").hide()
         vim.cmd.stopinsert()
         vim.api.nvim_buf_set_lines(0, case.line, case.line + 1, false, {})
         vim.defer_fn(function()
            run_case(index + 1)
         end, 500)
      end, 3000)
   end, 1500)
end

-- esperamos a que el LSP esté conectado y le damos tiempo de indexar
local elapsed = 0
local timer = assert(vim.uv.new_timer(), "no se pudo crear el timer")
timer:start(
   1000,
   1000,
   vim.schedule_wrap(function()
      elapsed = elapsed + 1
      if elapsed < wait_s then
         return
      end
      timer:stop()
      if #vim.lsp.get_clients({ bufnr = 0, name = lsp_name }) == 0 then
         table.insert(out, "ERROR: el LSP " .. lsp_name .. " no se conectó al buffer")
         return finish()
      end
      run_case(1)
   end)
)
