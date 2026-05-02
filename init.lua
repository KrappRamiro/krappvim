-- NOTE: Welcome to your neovim configuration!
-- The first 100ish lines are setup,
-- the rest is usage of lze and various core plugins!
vim.loader.enable() -- <- bytecode caching
do
   -- Set up a global in a way that also handles non-nix compat
   local ok
   ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
   if not ok then
      package.loaded[vim.g.nix_info_plugin_name] = setmetatable({}, {
         __call = function(_, default)
            return default
         end,
      })
      _G.nixInfo = require(vim.g.nix_info_plugin_name)
      -- If you always use the fetcher function to fetch nix values,
      -- rather than indexing into the tables directly,
      -- it will use the value you specified as the default
      -- TODO: for non-nix compat, vim.pack.add in another file and require here.
   end
   nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil
   ---@module 'lzextras'
   ---@type lzextras | lze
   nixInfo.lze = setmetatable(require("lze"), getmetatable(require("lzextras")))
   function nixInfo.get_nix_plugin_path(name)
      return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
   end
end
nixInfo.lze.register_handlers({
   {
      -- adds an `auto_enable` field to lze specs
      -- if true, will disable it if not installed by nix.
      -- if string, will disable if that name was not installed by nix.
      -- if a table of strings, it will disable if any were not.
      spec_field = "auto_enable",
      set_lazy = false,
      modify = function(plugin)
         if vim.g.nix_info_plugin_name then
            if type(plugin.auto_enable) == "table" then
               for _, name in pairs(plugin.auto_enable) do
                  if not nixInfo.get_nix_plugin_path(name) then
                     plugin.enabled = false
                     break
                  end
               end
            elseif type(plugin.auto_enable) == "string" then
               if not nixInfo.get_nix_plugin_path(plugin.auto_enable) then
                  plugin.enabled = false
               end
            elseif type(plugin.auto_enable) == "boolean" and plugin.auto_enable then
               if not nixInfo.get_nix_plugin_path(plugin.name) then
                  plugin.enabled = false
               end
            end
         end
         return plugin
      end,
   },
   {
      -- we made an options.settings.cats with the value of enable for our top level specs
      -- give for_cat = "name" to disable if that one is not enabled
      spec_field = "for_cat",
      set_lazy = false,
      modify = function(plugin)
         if vim.g.nix_info_plugin_name then
            if type(plugin.for_cat) == "string" then
               plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
            end
         end
         return plugin
      end,
   },
   -- From lzextras. This one makes it so that
   -- you can set up lsps within lze specs,
   -- and trigger lspconfig setup hooks only on the correct filetypes
   -- It is (unfortunately) important that it be registered after the above 2,
   -- as it also relies on the modify hook, and the value of enabled at that point
   nixInfo.lze.lsp,
})

-- NOTE: This config uses lzextras.lsp handler https://github.com/BirdeeHub/lzextras?tab=readme-ov-file#lsp-handler
-- Because we have the paths, we can set a more performant fallback function
-- for when you don't provide a filetype to trigger on yourself.
-- If you do provide a filetype, this will never be called.
nixInfo.lze.h.lsp.set_ft_fallback(function(name)
   local lspcfg = nixInfo.get_nix_plugin_path("nvim-lspconfig")
   if lspcfg then
      local ok, cfg = pcall(dofile, lspcfg .. "/lsp/" .. name .. ".lua")
      return (ok and cfg or {}).filetypes or {}
   else
      -- the less performant thing we are trying to avoid at startup
      return (vim.lsp.config[name] or {}).filetypes or {}
   end
end)

-- NOTE: These 2 should be set up before any plugins with keybinds are loaded.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- allow .nvim.lua in current dir and parents (project config)
vim.o.exrc = false -- can be toggled off in that file to stop it from searching further

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Set highlight on search
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Indent
vim.opt.cpoptions:append("I")
-- No need to set smarttab, irrelevant with expandtab
vim.o.expandtab = true -- transform tabs into spaces
-- No need for smartindent and autoindent, treesitter handles that
-- No need for tabstop, softtabstop or shiftwidth, sleuth takes care of them

-- stops line wrapping from being confusing
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"
vim.wo.relativenumber = true

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
-- Safeguard in case blink fails to load
vim.o.completeopt = "menu,preview,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Disable auto comment on enter ]]
-- See :help formatoptions
vim.api.nvim_create_autocmd("FileType", {
   desc = "remove formatoptions",
   callback = function()
      -- c is autowrap comments
      -- o is used when you use o or O to make a new line
      vim.opt.formatoptions:remove({ "c", "o" })
   end,
})

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
   callback = function()
      vim.highlight.on_yank()
   end,
   group = highlight_group,
   pattern = "*",
})

-- netrw is neovim file browser.
-- we configure it as a safeguard in case snacks file explorer fails
vim.g.netrw_liststyle = 0
vim.g.netrw_banner = 0

-- [[ Basic Keymaps ]]

require("keymaps")

-- NOTE: You will likely want to break this up into more files.
-- You can call this more than once.
-- You can also include other files from within the specs via an `import` spec.
-- see https://github.com/BirdeeHub/lze?tab=readme-ov-file#structuring-your-plugins
nixInfo.lze.load({
   { import = "lze_specs.mini_icons" },
   { import = "lze_specs.colorschemes" },
   { import = "lze_specs.lsp" },
   { import = "lze_specs.treesitter" },
   { import = "lze_specs.completion" },
   { import = "lze_specs.snacks" },
   { import = "lze_specs.conform" },
   { import = "lze_specs.lint" },
   { import = "lze_specs.surround" },
   { import = "lze_specs.startuptime" },
   { import = "lze_specs.fidget" },
   { import = "lze_specs.lualine" },
   { import = "lze_specs.gitsigns" },
   { import = "lze_specs.which_key" },
   { import = "lze_specs.grug_far" },
})
