-- Armador del dashboard de snacks a partir de settings.dashboard (Nix).
--
-- Nix ya resolvió el preset y dejó solo los parámetros del kind activo de
-- cada pieza (ver nix/dashboard/default.nix). Acá se traduce eso a la tabla
-- que espera Snacks.dashboard: `preset` (header y teclas) y `sections`.
--
-- Cada pieza vive en su archivo (lua/dashboard/header/<kind>.lua y
-- lua/dashboard/panel/<kind>.lua) y devuelve:
--   { sections = { ... }, header = "texto"?, on_open = function(d)? }
-- `header` es el texto de preset.header (milli, figlet, text). `on_open`
-- corre cuando snacks termina de dibujar (milli, imagen, shader).
local M = {}

-- Arriba de este ancho entran dos paneles de 60 columnas sin que snacks
-- los apile (60 + 4 de separación + 60, más margen).
M.TWO_PANE_COLUMNS = 130

-- Íconos Nerd Font como bytes: escritos literales a veces se pierden.
local ICON = {
   keys = "\239\132\156 ", -- U+F11C (teclado)
   recent = "\239\133\155 ", -- U+F15B (archivo)
   projects = "\239\129\187 ", -- U+F07B (carpeta)
}

local function title_section(text, hl)
   return { text = { { text, hl = hl or "SnacksDashboardTitle" } }, align = "center", padding = 1 }
end

-- Corre una pieza sin dejar que un error rompa el arranque: si falla, el
-- dashboard se dibuja sin ella y queda un aviso en :Noice / <leader>n.
local function piece(where, kind, params, cfg)
   local ok, res = pcall(function()
      return require("dashboard." .. where .. "." .. kind)(params or {}, cfg)
   end)
   if not ok then
      vim.notify(
         ("dashboard: la pieza %s.%s falló y no se muestra: %s"):format(where, kind, tostring(res)),
         vim.log.levels.WARN
      )
      return { sections = {} }
   end
   return res or { sections = {} }
end

-- Una columna o dos, según layout, paneles y ancho de la terminal.
function M.layout(cfg, ctx)
   if #(cfg.panel or {}) == 0 or cfg.layout == "one" then
      return "one"
   end
   if cfg.layout == "two" then
      return "two"
   end
   return (ctx.columns or vim.o.columns) >= M.TWO_PANE_COLUMNS and "two" or "one"
end

local function keys_section(cfg)
   if #(cfg.keys or {}) == 0 then
      return nil
   end
   if cfg.style == "startify" then
      return { { title = "Bookmarks", padding = 1 }, { section = "keys", padding = 1 } }
   elseif cfg.style == "compact" then
      return { icon = ICON.keys, title = "Keymaps", section = "keys", indent = 2, padding = 1 }
   elseif cfg.style == "calm" then
      return { section = "keys", gap = 0, padding = 1 }
   end
   return { section = "keys", gap = 1, padding = 1 }
end

local function recent_section(cfg)
   local r = cfg.recent or {}
   if not r.enable then
      return nil
   end
   local s =
      { section = "recent_files", indent = 2, padding = 1, limit = r.limit, cwd = r.cwd or nil }
   if cfg.style == "startify" then
      return { { title = "MRU", padding = 1 }, s }
   elseif cfg.style == "compact" then
      s.icon, s.title = ICON.recent, "Recent Files"
   end
   return s
end

local function projects_section(cfg)
   local p = cfg.projects or {}
   if not p.enable then
      return nil
   end
   local s = { section = "projects", indent = 2, padding = 1, limit = p.limit }
   if cfg.style == "startify" then
      return { { title = "Sessions", padding = 1 }, s }
   elseif cfg.style == "compact" then
      s.icon, s.title = ICON.projects, "Projects"
   end
   return s
end

local function footer_sections(cfg)
   local f = cfg.footer or {}
   local out = {}
   if f.startup then
      out[#out + 1] = require("dashboard.startup").section()
   end
   if f.version then
      out[#out + 1] = title_section("Neovim v" .. tostring(vim.version()), "SnacksDashboardFooter")
   end
   if f.text then
      out[#out + 1] = title_section(f.text, "SnacksDashboardFooter")
   end
   return out
end

local function add(list, s)
   if s then
      list[#list + 1] = s
   end
end

-- Arma las opciones de Snacks.dashboard. Devuelve (opts, hooks): hooks es
-- la lista de funciones a correr cuando el dashboard se abre.
function M.build(cfg, ctx)
   ctx = ctx or {}
   local hooks = {}
   local opts = { preset = { keys = {} }, sections = {} }
   for _, k in ipairs(cfg.keys or {}) do
      opts.preset.keys[#opts.preset.keys + 1] =
         { icon = k.icon, key = k.key, desc = k.desc, action = k.action }
   end
   if cfg.style == "startify" then
      -- [f] en vez de solo f, como vim-startify
      opts.formats = {
         key = function(item)
            return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
         end,
      }
   end

   local two = M.layout(cfg, ctx) == "two"
   local S = opts.sections

   if cfg.style == "calm" then
      -- Un respiro arriba y la fecha, nada más.
      add(S, { padding = 10 })
      add(S, title_section(os.date("%A %d de %B"), "SnacksDashboardDesc"))
   end

   local h = cfg.header or { kind = "none" }
   if h.kind ~= "none" then
      local res = piece("header", h.kind, h[h.kind], cfg)
      if res.header then
         opts.preset.header = res.header
      end
      vim.list_extend(S, res.sections or {})
      add(hooks, res.on_open)
   end

   if cfg.title then
      add(S, title_section(cfg.title))
   end

   -- Paneles: a la derecha (pane = 2) o, en una columna, antes de las teclas.
   local function panels()
      for _, p in ipairs(cfg.panel or {}) do
         local res = piece("panel", p.kind, p, cfg)
         for _, s in ipairs(res.sections or {}) do
            if two then
               s.pane = 2
            end
            add(S, s)
         end
         add(hooks, res.on_open)
      end
   end

   if not two then
      panels()
   end
   if cfg.style == "startify" then
      -- En startify las teclas van al final, como sus "Bookmarks".
      add(S, recent_section(cfg))
      add(S, projects_section(cfg))
      add(S, keys_section(cfg))
   else
      add(S, keys_section(cfg))
      add(S, recent_section(cfg))
      add(S, projects_section(cfg))
   end
   if two then
      panels()
   end

   vim.list_extend(S, cfg.extraSections or {})
   vim.list_extend(S, footer_sections(cfg))
   return opts, hooks
end

-- Neovim escribe "[Process exited 0]" (virtual text, ver :h terminal-config)
-- en cada terminal que termina. snacks muestra la terminal en vivo la
-- primera vez que corre un comando y cada vez que vence el caché, así que
-- el cartel quedaba encima del dashboard. Se borra solo en las terminales
-- del dashboard. Diferido porque snacks les pone el filetype en el
-- on_exit del job, que puede llegar después del TermClose.
function M.hide_exit_message()
   local ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")
   vim.api.nvim_create_autocmd("TermClose", {
      group = vim.api.nvim_create_augroup("krapp_dashboard_exitmsg", { clear = true }),
      callback = function(ev)
         vim.defer_fn(function()
            if
               vim.api.nvim_buf_is_valid(ev.buf)
               and vim.bo[ev.buf].filetype == "snacks_dashboard"
            then
               vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
            end
         end, 50)
      end,
   })
end

-- Lo que llama lua/lze_specs/snacks.lua: devuelve el `dashboard = { ... }`
-- de Snacks.setup y deja registrados los hooks de apertura. `cfg` es para
-- los tests; normalmente viene de Nix.
function M.setup(cfg)
   cfg = cfg or nixInfo(nil, "settings", "dashboard")
   if not cfg then
      return {}
   end
   local ss = cfg.extras and cfg.extras.screensaver
   if ss and ss.enable then
      require("milli").screensaver(require("dashboard.extras").screensaver_opts(ss))
   end
   if cfg.preset == "ministarter" then
      -- lua/lze_specs/mini.lua configura mini.starter
      return { enabled = false }
   end
   local opts, hooks = M.build(cfg, { columns = vim.o.columns })
   M.hide_exit_message()
   if #hooks > 0 then
      vim.api.nvim_create_autocmd("User", {
         group = vim.api.nvim_create_augroup("krapp_dashboard_hooks", { clear = true }),
         pattern = "SnacksDashboardOpened",
         callback = function()
            -- snacks emite el evento con el dashboard como buffer actual.
            local d = { buf = vim.api.nvim_get_current_buf(), win = vim.api.nvim_get_current_win() }
            for _, hook in ipairs(hooks) do
               local ok, err = pcall(hook, d)
               if not ok then
                  vim.notify("dashboard: " .. tostring(err), vim.log.levels.WARN)
               end
            end
         end,
      })
   end
   return opts
end

return M
