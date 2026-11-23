-- Tests del armador del dashboard (lua/dashboard). Corre headless:
--   nix build && ./result/bin/kvim --headless -c "luafile scripts/dashboard-test.lua"
-- Cada función test_* corre con pcall; al final imprime las fallas y sale
-- con código 1 (cquit) si hubo alguna. No dibuja nada: revisa la tabla que se le pasa a
-- Snacks.dashboard.

local failures = {}
local tests = {}

local function check(cond, msg)
   if not cond then
      error(msg, 2)
   end
end

-- Config que llega de Nix en este build (el default, sin opciones).
local DEFAULT = nixInfo(nil, "settings", "dashboard")

-- Copia del default con cambios encima. `panel` y `keys` se reemplazan
-- enteros (como en Nix), el resto se mezcla.
local function cfg_with(over)
   local cfg = vim.deepcopy(DEFAULT)
   for k, v in pairs(over or {}) do
      if
         type(v) == "table"
         and type(cfg[k]) == "table"
         and k ~= "panel"
         and k ~= "keys"
         and k ~= "header"
      then
         cfg[k] = vim.tbl_deep_extend("force", cfg[k], v)
      else
         cfg[k] = v
      end
   end
   return cfg
end

local CTX = { columns = 200 }

local function build(over, ctx)
   -- Fuerza a recargar los módulos: algunos tests ponen stubs.
   return require("dashboard").build(cfg_with(over), ctx or CTX)
end

-- Todas las secciones aplanadas (snacks permite secciones anidadas).
local function flat(sections, out)
   out = out or {}
   for _, s in ipairs(sections) do
      if type(s) == "table" then
         out[#out + 1] = s
         flat(s, out)
      end
   end
   return out
end

local function text_of(s)
   if type(s) ~= "table" or type(s.text) ~= "table" then
      return nil
   end
   local parts = {}
   for _, t in ipairs(s.text) do
      parts[#parts + 1] = type(t) == "table" and t[1] or t
   end
   return table.concat(parts)
end

-- Secciones función (startup) evaluadas, como hace snacks al dibujar.
local function resolved(sections)
   local out = {}
   for _, s in ipairs(flat(sections)) do
      out[#out + 1] = s
   end
   for _, s in ipairs(sections) do
      if type(s) == "function" then
         out[#out + 1] = s()
      end
   end
   return out
end

function tests.test_default_matches_today()
   local opts = build()
   check(opts.sections[1].section == "header", "primera sección no es header")
   local frame = table.concat(require("milli").load({ splash = "blackhole" }).frames[1], "\n")
   check(opts.preset.header == frame, "preset.header no es el frame 1 de blackhole")
   local all = resolved(opts.sections)
   local has = {}
   for _, s in ipairs(all) do
      if s.section then
         has[s.section] = s
      end
      local t = text_of(s)
      if t == "── krapp.vim ──" then
         has.title = true
      end
      if t and t:find("^Neovim v") then
         has.version = true
      end
   end
   check(has.title, "falta el título")
   check(has.keys and has.keys.gap == 1, "falta keys con gap = 1")
   check(has.recent_files, "falta recent_files")
   check(has.version, "falta el footer con la versión")
   check(#opts.preset.keys == 5, "no hay 5 teclas")
end

-- figlet no tiene color, así que su salida va como texto del header: snacks
-- lo centra (una sección terminal queda pegada a la izquierda).
function tests.test_figlet_header()
   local opts =
      build({ header = { kind = "figlet", figlet = { text = "krapp.vim", font = "slant" } } })
   check(opts.sections[1].section == "header", "figlet no usa la sección header")
   local want = table.concat(vim.fn.systemlist({ "figlet", "-f", "slant", "krapp.vim" }), "\n")
   check(vim.trim(opts.preset.header) == vim.trim(want), "preset.header no es la salida de figlet")
end

function tests.test_cmd_animated_never_cached()
   local opts = build({
      header = {
         kind = "cmd",
         cmd = { cmd = "cmatrix", height = 10, ttl = 3600, animated = true, indent = 0 },
      },
   })
   local s = opts.sections[1]
   check(s.ttl == 0, "ttl no es 0")
   check(s.cmd:find("; sleep 600$") ~= nil, "cmd no termina en ; sleep 600")
end

function tests.test_bad_piece_is_skipped()
   local notified = {}
   local orig = vim.notify
   vim.notify = function(msg, level)
      notified[#notified + 1] = { msg = msg, level = level }
   end
   package.loaded["dashboard.header.text"] = function()
      error("pieza rota")
   end
   local ok, opts = pcall(build, { header = { kind = "text", text = { text = "x" } } })
   package.loaded["dashboard.header.text"] = nil
   vim.notify = orig
   check(ok, "build tiró error: " .. tostring(opts))
   for _, s in ipairs(flat(opts.sections)) do
      check(s.section ~= "header", "quedó una sección header")
   end
   check(opts.preset.header == nil, "quedó preset.header")
   check(#notified == 1 and notified[1].level == vim.log.levels.WARN, "no avisó con WARN")
end

function tests.test_no_startup_section()
   local opts = build({ footer = { startup = true } })
   for _, s in ipairs(resolved(opts.sections)) do
      check(s.section ~= "startup", "hay section = startup (rompe en kvim)")
   end
end

function tests.test_startup_line()
   local opts = build({ footer = { startup = true } })
   local found
   for _, s in ipairs(resolved(opts.sections)) do
      local t = text_of(s)
      if t and t:find("kvim listo en %d+ ms") then
         found = true
      end
   end
   check(found, "falta la línea de arranque")
end

function tests.test_extra_sections_appended()
   local opts =
      build({ extraSections = { { text = "x" } }, footer = { startup = false, version = true } })
   local n = #opts.sections
   check(text_of(opts.sections[n]):find("^Neovim v"), "la última no es el footer")
   check(opts.sections[n - 1].text == "x", "extraSections no está antes del footer")
end

function tests.test_milli_splash_file()
   local file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h")
      .. "/fixtures/splash.lua"
   local opts = build({
      header = { kind = "milli", milli = { splash = "blackhole", loop = true, splashFile = file } },
   })
   local frame = table.concat(dofile(file).frames[1], "\n")
   check(opts.preset.header == frame, "no usó el splashFile")
end

-- Paneles y layout (Task 4)

local POKEMON = { kind = "pokemon", random = 10, height = 30 }

local function with_pane2(opts)
   local out = {}
   for _, s in ipairs(flat(opts.sections)) do
      if s.pane == 2 then
         out[#out + 1] = s
      end
   end
   return out
end

function tests.test_two_panes()
   local opts = build({ panel = { POKEMON }, layout = "two" }, { columns = 200 })
   local right = with_pane2(opts)
   check(#right == 1, "esperaba una sección en el panel 2, hay " .. #right)
   local s = right[1]
   check(s.random == 10, "random no es 10")
   check(
      s.cmd:find("pokemon%-colorscripts %-r %-%-no%-title") ~= nil,
      "cmd de pokemon: " .. tostring(s.cmd)
   )
end

function tests.test_auto_narrow_is_one_column()
   local opts = build({ panel = { POKEMON }, layout = "auto" }, { columns = 100 })
   check(#with_pane2(opts) == 0, "con 100 columnas no tiene que haber panel 2")
end

function tests.test_auto_wide_is_two_columns()
   local opts = build({ panel = { POKEMON }, layout = "auto" }, { columns = 200 })
   check(#with_pane2(opts) == 1, "con 200 columnas tiene que haber panel 2")
end

function tests.test_empty_panel_two_layout()
   local ok, opts = pcall(build, { panel = {}, layout = "two" })
   check(ok, "build tiró error: " .. tostring(opts))
   check(#with_pane2(opts) == 0, "panel vacío no tiene que poner panel 2")
end

function tests.test_cbonsai_live()
   local opts =
      build({ panel = { { kind = "cbonsai", live = true, height = 22 } }, layout = "one" })
   local s
   for _, x in ipairs(flat(opts.sections)) do
      if x.cmd and x.cmd:find("cbonsai") then
         s = x
      end
   end
   check(s, "no hay sección cbonsai")
   check(s.cmd:find("^LC_ALL=C cbonsai %-l") ~= nil, "cmd: " .. s.cmd)
   check(s.ttl == 0, "ttl no es 0")
   check(s.cmd:find("; sleep 600$") ~= nil, "no termina en sleep")
end

function tests.test_github_needs_git_root()
   local opts = build({
      panel = { { kind = "github", sections = { "commits", "issues", "prs", "diff" }, limit = 3 } },
      layout = "two",
   })
   local right = with_pane2(opts)
   check(#right == 4, "esperaba 4 secciones de github, hay " .. #right)
   local orig = Snacks.git.get_root
   Snacks.git.get_root = function()
      return nil
   end
   local enabled_outside = false
   for _, s in ipairs(right) do
      local e = s.enabled
      check(type(e) == "function", "enabled no es función")
      enabled_outside = enabled_outside or e()
   end
   Snacks.git.get_root = function()
      return "/repo"
   end
   local enabled_inside = true
   for _, s in ipairs(right) do
      enabled_inside = enabled_inside and s.enabled()
   end
   Snacks.git.get_root = orig
   check(not enabled_outside, "github aparece fuera de un repo")
   check(enabled_inside, "github no aparece dentro de un repo")
end

function tests.test_every_panel_kind_builds()
   local kinds = {
      { kind = "pokemon", random = 10, height = 30 },
      { kind = "krabby", random = 10, height = 30 },
      { kind = "fastfetch", modules = "OS", logo = "nixos_small", height = 10 },
      { kind = "github", sections = { "commits" }, limit = 3 },
      { kind = "git", height = 5 },
      { kind = "colorscript", name = "square", height = 5 },
      { kind = "fortune", cow = true, short = true, height = 10 },
      { kind = "cbonsai", live = false, height = 22 },
      { kind = "aquarium", height = 20, width = 100 },
      { kind = "cmatrix", height = 14, width = 70, color = "cyan" },
      { kind = "lolcat", text = "krapp.vim", font = "slant", height = 7 },
      { kind = "recent", limit = 8 },
      { kind = "projects", limit = 5 },
      { kind = "cmd", cmd = "echo hola", height = 2, ttl = 3600, animated = false, indent = 0 },
   }
   local orig = vim.notify
   local warned = {}
   vim.notify = function(msg)
      warned[#warned + 1] = msg
   end
   for _, p in ipairs(kinds) do
      local opts = build({ panel = { p }, layout = "two" })
      check(#with_pane2(opts) > 0, p.kind .. " no armó secciones")
   end
   vim.notify = orig
   check(#warned == 0, "hubo avisos: " .. table.concat(warned, " | "))
end

-- Overlay, extras y mini.starter (Task 5)

function tests.test_drop_config()
   local opts =
      require("dashboard.extras").drop_opts({ enable = true, theme = "snow", screensaver = 60 })
   check(vim.deep_equal(opts.filetypes, { "snacks_dashboard" }), "filetypes no es snacks_dashboard")
   check(opts.theme == "snow", "theme no es snow")
   check(opts.screensaver == 60000, "screensaver no pasó a milisegundos")
   local off =
      require("dashboard.extras").drop_opts({ enable = true, theme = "auto", screensaver = false })
   check(off.screensaver == false, "screensaver false no quedó false")
end

function tests.test_screensaver_opts()
   local e = require("dashboard.extras")
   local s = e.screensaver_opts({ enable = true, shader = "rain", splash = nil, after = 120 })
   check(s.shader == "rain" and s.after == 120 and s.splash == nil, "shader: " .. vim.inspect(s))
   local t = e.screensaver_opts({ enable = true, shader = "rain", splash = "fire", after = 120 })
   check(
      t.splash == "fire" and t.shader == nil,
      "con splash no tiene que ir shader: " .. vim.inspect(t)
   )
end

function tests.test_ministarter_disables_snacks()
   local cfg = cfg_with({ preset = "ministarter", header = { kind = "none" } })
   local opts = require("dashboard").setup(cfg)
   check(opts.enabled == false, "snacks dashboard sigue habilitado")
   require("dashboard.extras").ministarter(cfg)
   local starter = require("mini.starter")
   check(starter.config ~= nil, "mini.starter no quedó configurado")
   local items = starter.config.items
   check(type(items) == "table" and #items == #cfg.keys, "items no son las teclas")
   check(
      items[1].action == "lua Snacks.picker.smart()",
      "action sin ':' inicial: " .. tostring(items[1].action)
   )
end

-- El hook de image corre dentro de SnacksDashboardOpened, que al arrancar
-- dispara snacks en pleno startup. La detección de la terminal de snacks
-- hace vim.wait(): ahí adentro corren callbacks de otros plugins antes de
-- tiempo (el colorscheme) y el dashboard quedaba vacío. El hook tiene que
-- diferir la detección.
function tests.test_image_hook_does_not_wait()
   local opts, hooks =
      build({ header = { kind = "image", image = { path = "/x.png", width = 10, height = 5 } } })
   check(#hooks == 1, "image no registró hook")
   local img = Snacks.image
   local orig_supports, orig_detect = img.supports_terminal, img.terminal.detect
   local sync = 0
   img.supports_terminal = function()
      sync = sync + 1
      return false
   end
   img.terminal.detect = function(cb)
      if not cb then
         sync = sync + 1
      end
   end
   local buf = vim.api.nvim_create_buf(false, true)
   hooks[1]({ buf = buf, win = vim.api.nvim_get_current_win() })
   img.supports_terminal, img.terminal.detect = orig_supports, orig_detect
   vim.api.nvim_buf_delete(buf, { force = true })
   check(sync == 0, "el hook detectó la terminal de forma síncrona (vim.wait)")
   check(opts.sections ~= nil, "sin secciones")
end

-- Snacks.image.placement.new con una imagen todavía sin convertir (la
-- primera vez, sin caché) borra el buffer para mostrar "loading", y el
-- dashboard quedaba vacío. El hook espera a que la imagen esté lista.
function tests.test_image_waits_until_ready()
   local _, hooks =
      build({ header = { kind = "image", image = { path = "/x.png", width = 10, height = 5 } } })
   local img = Snacks.image
   local orig = {
      supports = img.supports_terminal,
      detect = img.terminal.detect,
      new = img.image.new,
      placement = img.placement.new,
   }
   local ready, placed = false, 0
   img.supports_terminal = function()
      return true
   end
   img.terminal.detect = function(cb)
      cb()
   end
   img.image.new = function()
      return {
         ready = function()
            return ready
         end,
         failed = function()
            return false
         end,
      }
   end
   img.placement.new = function()
      placed = placed + 1
   end
   local buf = vim.api.nvim_create_buf(false, true)
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "", "", "", "título" })
   local ok, err = pcall(function()
      hooks[1]({ buf = buf, win = vim.api.nvim_get_current_win() })
      vim.wait(200)
      check(placed == 0, "puso la imagen antes de que esté lista")
      ready = true
      vim.wait(1000, function()
         return placed > 0
      end)
      check(placed == 1, "no puso la imagen cuando estuvo lista")
   end)
   img.supports_terminal, img.terminal.detect = orig.supports, orig.detect
   img.image.new, img.placement.new = orig.new, orig.placement
   vim.api.nvim_buf_delete(buf, { force = true })
   assert(ok, err)
end

-- Neovim marca con "[Process exited 0]" (virtual text) cada terminal que
-- termina. snacks muestra la terminal en vivo la primera vez que corre un
-- comando y cuando vence el caché, y el cartel quedaba sobre el dashboard.
-- En las terminales del dashboard se borra; en las demás queda.
function tests.test_exit_message_hidden_in_dashboard()
   require("dashboard").hide_exit_message()
   local ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")
   local function run(ft)
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_call(buf, function()
         vim.fn.jobstart("true", { term = true })
      end)
      vim.bo[buf].filetype = ft
      vim.wait(2000, function()
         return #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {}) > 0
      end)
      -- Deja correr lo diferido (el borrado es asíncrono).
      vim.wait(300)
      return #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
   end
   check(run("snacks_dashboard") == 0, "el cartel quedó en la terminal del dashboard")
   check(run("") > 0, "se borró el cartel de una terminal común")
end

-- Corre todos en orden alfabético para que la salida sea estable.
local names = vim.tbl_keys(tests)
table.sort(names)
for _, name in ipairs(names) do
   -- Cada test arranca con los módulos del dashboard sin cargar.
   for mod in pairs(package.loaded) do
      if mod == "dashboard" or mod:find("^dashboard%.") then
         package.loaded[mod] = nil
      end
   end
   local ok, err = pcall(tests[name])
   if not ok then
      failures[#failures + 1] = name .. ": " .. tostring(err)
   end
end

if #failures > 0 then
   io.write("dashboard-test: " .. #failures .. " fallas\n" .. table.concat(failures, "\n") .. "\n")
   vim.cmd.cquit(1)
end
io.write("dashboard-test: " .. #names .. " tests ok\n")
vim.cmd.quitall({ bang = true })
