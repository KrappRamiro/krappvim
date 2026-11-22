-- Lo que acompaña al dashboard sin ser una sección: drop.nvim encima,
-- el protector de pantalla de milli y el preset ministarter.
local M = {}

-- Opciones de require("drop").setup. drop se prende solo en los filetypes
-- que le pasamos: el del dashboard de snacks.
function M.drop_opts(d)
   return {
      theme = d.theme,
      filetypes = { "snacks_dashboard" },
      -- En Nix son segundos (más fácil de leer); drop quiere milisegundos.
      screensaver = d.screensaver and d.screensaver * 1000 or false,
   }
end

-- Opciones de require("milli").screensaver: un shader o un splash.
function M.screensaver_opts(s)
   if s.splash then
      return { splash = s.splash, after = s.after }
   end
   return { shader = s.shader, after = s.after }
end

-- mini.starter en vez de snacks (preset ministarter). Las teclas de
-- settings.dashboard pasan a ser los items del starter.
function M.ministarter(cfg)
   local items = {}
   for _, k in ipairs(cfg.keys or {}) do
      items[#items + 1] = {
         name = k.desc,
         -- mini.starter corre la acción como comando de Vim, sin el ":"
         action = (k.action:gsub("^:", "")),
         section = "Teclas",
      }
   end
   local starter = require("mini.starter")
   starter.setup({
      header = cfg.title or "",
      items = items,
      footer = cfg.footer and cfg.footer.text or "",
      content_hooks = {
         starter.gen_hook.adding_bullet(),
         starter.gen_hook.aligning("center", "center"),
      },
   })
end

return M
