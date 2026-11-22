-- Chequeo de un preset del dashboard, sobre un kvim armado con ese preset
-- (checks.dashboard-<preset> en flake.nix):
--   - el armador no tira error ni avisa que una pieza falló
--   - cada programa que corren sus secciones está en el PATH de kvim
--   - los extras pedidos (drop, cellular-automaton, splash del registro)
--     cargan sin red
-- Sale con código 1 (cquit) si algo falla.
local cfg = nixInfo(nil, "settings", "dashboard")
local errors = {}

local function fail(msg)
   errors[#errors + 1] = msg
end

local orig_notify = vim.notify
vim.notify = function(msg, level)
   if level and level >= vim.log.levels.WARN then
      fail("aviso: " .. tostring(msg))
   end
end

local dash = require("dashboard")
local ok, opts = pcall(dash.build, cfg, { columns = 200 })
if not ok then
   fail("build: " .. tostring(opts))
   opts = { sections = {} }
end

-- Recorre secciones anidadas y evalúa las secciones función (startup).
local function walk(sections, fn)
   for _, s in ipairs(sections) do
      if type(s) == "function" then
         s = s()
      end
      if type(s) == "table" then
         fn(s)
         walk(s, fn)
      end
   end
end

-- Programas de un comando de shell: el primero de cada tramo separado por
-- | ; &&, sin asignaciones de entorno (LC_ALL=C cbonsai).
local function programs(cmd)
   local out = {}
   for part in (cmd .. ";"):gmatch("([^|;&]+)") do
      local words = vim.split(vim.trim(part), "%s+")
      local i = 1
      while words[i] and words[i]:find("^[%w_]+=") do
         i = i + 1
      end
      if words[i] and words[i] ~= "" then
         out[#out + 1] = words[i]
      end
   end
   return out
end

walk(opts.sections, function(s)
   if s.cmd then
      for _, prog in ipairs(programs(s.cmd)) do
         if vim.fn.executable(prog) ~= 1 then
            fail(("falta %s en el PATH (cmd: %s)"):format(prog, s.cmd))
         end
      end
   end
end)

if cfg.preset == "ministarter" then
   local setup = dash.setup(cfg)
   if setup.enabled ~= false then
      fail("ministarter: snacks dashboard sigue habilitado")
   end
end

-- Extras: el plugin tiene que estar en el build y cargar.
local function load(plugin, mod)
   local loaded, err = pcall(function()
      vim.cmd.packadd(plugin)
      return require(mod)
   end)
   if not loaded then
      fail(plugin .. ": " .. tostring(err))
   end
   return loaded
end
if cfg.overlay.drop.enable and load("drop", "drop") then
   require("drop").setup(require("dashboard.extras").drop_opts(cfg.overlay.drop))
end
if cfg.extras.cellularAutomaton.enable then
   load("cellular-automaton.nvim", "cellular-automaton")
end
if cfg.header.kind == "milli" then
   local found, err = pcall(require("milli").load, { splash = cfg.header.milli.splash })
   if not found then
      fail("milli: " .. tostring(err))
   end
end

vim.notify = orig_notify
if #errors > 0 then
   io.write("dashboard-check " .. cfg.preset .. ": FALLÓ\n" .. table.concat(errors, "\n") .. "\n")
   vim.cmd.cquit(1)
end
io.write("dashboard-check " .. cfg.preset .. ": ok\n")
vim.cmd.quitall({ bang = true })
