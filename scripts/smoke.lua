-- Smoke test: arranca kvim headless, fuerza la carga de los plugins lazy y
-- falla si algo tiró un error. Lo corre `nix flake check` (ver flake.nix).
--
-- Uso manual:
--   nix build && ./result/bin/kvim --headless -c "luafile scripts/smoke.lua"
-- Sale con código 0 si está todo bien, 1 si hubo errores (los imprime).

local errors = {}

-- los plugins avisan sus errores con vim.notify, así que lo interceptamos
local function record(msg, level)
   if level and level >= vim.log.levels.ERROR then
      table.insert(errors, tostring(msg))
   end
end
vim.notify = record

local function step(name, fn)
   local ok, err = pcall(fn)
   if not ok then
      table.insert(errors, name .. ": " .. tostring(err))
   end
end

-- plugins con event = "DeferredUIEnter": headless no tiene UI, lo disparamos
step("DeferredUIEnter", function()
   vim.api.nvim_exec_autocmds("User", { pattern = "DeferredUIEnter" })
end)
-- algunos plugins reemplazan vim.notify al cargar (noice lo apunta a snacks)
vim.notify = record

-- un buffer por filetype dispara los specs con `ft`, treesitter, lint y la
-- config de cada LSP (el server puede no arrancar en el sandbox, no importa)
for _, ft in ipairs({ "lua", "nix", "rust", "python", "toml", "markdown", "sh" }) do
   step("filetype " .. ft, function()
      vim.cmd.enew()
      vim.bo.filetype = ft
   end)
end

-- cada archivo de lze_specs tiene que cargar y devolver una tabla
local spec_dir = nixInfo.settings.config_directory .. "/lua/lze_specs"
for name in vim.fs.dir(spec_dir) do
   local mod = "lze_specs." .. name:gsub("%.lua$", "")
   step(mod, function()
      assert(type(require(mod)) == "table", mod .. " no devuelve una tabla")
   end)
end

vim.defer_fn(function()
   -- No miramos v:errmsg: los ftplugin de Neovim usan `silent! unmap` y lo
   -- dejan en "E31: No such mapping" aunque no haya ningún problema.
   if #errors > 0 then
      io.write("SMOKE TEST FAILED\n" .. table.concat(errors, "\n") .. "\n")
      vim.cmd.cquit(1)
   end
   io.write("smoke test ok\n")
   vim.cmd.quitall({ bang = true })
end, 1500)
