-- nvim-ufo: folds modernos. Reemplaza al `foldexpr` de treesitter que había en
-- lze_specs/treesitter.lua.
-- Por qué: con foldmethod=expr Neovim recalcula los niveles de fold en cada
-- cambio, y por el bug neovim#32759 a veces cierra folds que nadie cerró (por
-- ejemplo, una función nueva escrita debajo de otra que estaba cerrada nace
-- cerrada). ufo usa foldmethod=manual y crea los folds él mismo con los rangos
-- que le da el provider, así que un fold nuevo siempre arranca abierto.

-- Arma el texto de la línea de un fold cerrado: el código de la primera línea
-- (con sus colores) y al final cuántas líneas hay escondidas, por ejemplo
-- `fn main() {  󰁂 12`. Es el handler de ejemplo del README de ufo.
local function fold_text(virt_text, lnum, end_lnum, width, truncate)
   local result = {}
   local suffix = ("  󰁂 %d "):format(end_lnum - lnum)
   local suffix_width = vim.fn.strdisplaywidth(suffix)
   local target_width = width - suffix_width
   local cur_width = 0
   for _, chunk in ipairs(virt_text) do
      local text = chunk[1]
      local text_width = vim.fn.strdisplaywidth(text)
      if target_width > cur_width + text_width then
         table.insert(result, chunk)
      else
         -- no entra: cortamos el texto y rellenamos con espacios para que el
         -- sufijo quede pegado al borde
         text = truncate(text, target_width - cur_width)
         table.insert(result, { text, chunk[2] })
         text_width = vim.fn.strdisplaywidth(text)
         if cur_width + text_width < target_width then
            suffix = suffix .. (" "):rep(target_width - cur_width - text_width)
         end
         break
      end
      cur_width = cur_width + text_width
   end
   table.insert(result, { suffix, "MoreMsg" })
   return result
end

return {
   {
      -- dependencia de ufo: le da promesas y async/await en Lua.
      -- Se carga sola la primera vez que ufo hace require("promise") o require("async").
      "promise-async",
      auto_enable = true,
      on_require = { "promise", "async" },
   },
   {
      "nvim-ufo",
      auto_enable = true,
      -- BufReadPost y NO BufReadPre: ufo se engancha al buffer apenas carga y
      -- guarda su cantidad de líneas. En BufReadPre el archivo todavía no se
      -- leyó (el buffer tiene 1 línea), ufo se quedaba con ese número y
      -- recortaba cada fold cerrado a 1 línea; al editar en cualquier parte del
      -- archivo, ese fold se volvía a abrir solo.
      event = { "BufReadPost", "BufNewFile" },
      on_require = "ufo",
      before = function(_)
         -- El README de ufo pide estos tres. Con foldmethod=manual un foldlevel
         -- bajo cierra folds solo cuando ufo actualiza los rangos, así que va
         -- alto (99) y todo arranca abierto.
         vim.o.foldlevel = 99
         vim.o.foldlevelstart = 99
         vim.o.foldenable = true

         -- La statuscolumn de snacks (lze_specs/snacks.lua) dibuja el icono del
         -- fold, pero solo si foldcolumn no es "0". La statuscolumn reemplaza la
         -- columna de folds nativa, así que "1" no agrega una segunda columna:
         -- solo habilita el icono de snacks.
         vim.o.foldcolumn = "1"
         -- Iconos que usa snacks para los folds (los lee de fillchars).
         -- Van como bytes UTF-8 escapados porque son glifos Nerd Font del área
         -- de uso privado: pegados tal cual se pierden fácil al copiar, y un
         -- campo vacío hace fallar todo el fillchars (E1511).
         --   foldopen  = U+F47C (nf-oct-chevron_down)
         --   foldclose = U+F460 (nf-oct-chevron_right)
         -- fold y foldsep en blanco: sin puntitos en la línea del fold ni
         -- separadores verticales.
         vim.opt.fillchars:append({
            foldopen = "\239\145\188",
            foldclose = "\239\145\160",
            fold = " ",
            foldsep = " ",
         })
      end,
      after = function(_)
         local ufo = require("ufo")
         ufo.setup({
            -- treesitter primero (usa las mismas queries folds.scm que el
            -- foldexpr de antes), indent si el lenguaje no tiene parser.
            -- No usamos el provider lsp: rust-analyzer y otros dan rangos, pero
            -- tardan en arrancar y treesitter ya alcanza.
            provider_selector = function(_, _, buftype)
               -- buffers especiales (dashboard, picker, terminal): sin folds
               if buftype ~= "" then
                  return ""
               end
               return { "treesitter", "indent" }
            end,
            fold_virt_text_handler = fold_text,
            preview = {
               win_config = {
                  -- sin transparencia, como el resto de los floats
                  winblend = 0,
               },
               mappings = {
                  -- dentro del preview: scroll de media página y saltos al
                  -- principio y al final del fold
                  scrollU = "<C-u>",
                  scrollD = "<C-d>",
                  jumpTop = "[",
                  jumpBot = "]",
               },
            },
         })

         -- zR/zM/zm nativos cambian foldlevel, y con ufo foldlevel tiene que
         -- quedar en 99 (ver arriba). Estas versiones abren y cierran los folds
         -- sin tocar foldlevel.
         vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "Abrir todos los folds" })
         vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "Cerrar todos los folds" })
         -- con count, como `set foldlevel=N`: `1zm` deja abierto solo el primer
         -- nivel (por ejemplo, el impl) y cierra lo de adentro. Sin count cierra todo.
         vim.keymap.set(
            "n",
            "zm",
            ufo.closeFoldsWith,
            { desc = "Cerrar folds más hondos que [count]" }
         )

         -- zK: mirar el contenido de un fold cerrado en un float sin abrirlo.
         -- No va en K porque K es el hover del LSP (lsp.lua y rustaceanvim.lua).
         -- Dentro del float: <Tab> entra y sale, <CR> abre el fold y salta ahí,
         -- q cierra.
         vim.keymap.set("n", "zK", function()
            if not ufo.peekFoldedLinesUnderCursor() then
               vim.notify("No hay un fold cerrado en esta línea", vim.log.levels.INFO)
            end
         end, { desc = "Ver fold cerrado (ufo)" })
      end,
   },
}
