-- If you ask yourself "hey, why are you returning an object", its because this will be loaded by lze specs. and lze specs expects an object
return {
   -- milli.nvim: animated ASCII splash usado por el dashboard de snacks abajo.
   -- Lo cargamos eager con priority > snacks (1000) para garantizar que
   -- esté en runtimepath antes de que snacks corra su `after` y lo requiera.
   -- Spec name "milli" (no "milli.nvim") porque lze matchea por exact name
   -- en su on_require hook.
   {
      "milli",
      auto_enable = true,
      lazy = false,
      priority = 1001,
   },
   {
   "snacks.nvim",
   auto_enable = true,
   -- snacks makes a global, and then lazily loads itself
   lazy = false,
   -- priority only affects startup plugins
   -- unless otherwise specified by a particular handler
   priority = 1000,
   after = function(plugin)
      -- Define colors for indent
      vim.api.nvim_set_hl(0, "MySnacksIndent", { fg = "#32a88f" })

      -- milli.nvim: animated ASCII splash para el dashboard.
      -- Cargamos el primer frame para usarlo como header "anchor" - milli
      -- lo necesita para localizar dónde animar después del setup.
      -- El nombre del splash tiene que coincidir con el de milli.snacks() abajo.
      local SPLASH = "blackhole"
      local milli_splash = require("milli").load({ splash = SPLASH })
      local splash_header = table.concat(milli_splash.frames[1], "\n")

      require("snacks").setup({
         -- Detecta archivos grandes (>1.5MB por default) y desactiva treesitter,
         -- LSP, indent guides, etc. para que no se cuelgue al abrir un log enorme.
         bigfile = {},
         -- Renderiza el archivo antes de cargar plugins lentos (treesitter, LSP).
         -- `nvim foo.lua` se siente instantáneo aunque el resto del setup tarde.
         quickfile = {},
         -- Reemplaza `vim.ui.input` (los prompts feos del default, ej: rename de
         -- LSP) con un float lindo.
         input = {},
         -- Resalta automáticamente las referencias del símbolo bajo el cursor
         -- vía LSP. `]]` y `[[` saltan entre ellas.
         words = {},
         -- Smooth scrolling para `<C-d>`, `<C-u>`, `<C-f>`, `<C-b>`, `gg`, `G`, etc.
         scroll = {},
         -- Abrir el archivo / línea / commit / repo actual en el browser (GitHub).
         -- Keymap: `<leader>gB` (n + v).
         gitbrowse = {},
         -- LSP-integrated file rename: actualiza imports en otros archivos.
         -- Keymap: `<leader>cR`.
         rename = {},
         -- Image viewer dentro de Neovim (markdown, LaTeX, etc.). Solo funciona
         -- en kitty / wezterm / ghostty. Necesita `imagemagick` (ya en module.nix).
         image = {},
         -- File explorer
         explorer = {
            replace_netrw = true,
            trash = true, -- Use the system trash when deleting files
         },
         -- Picker is a fuzzy finder
         picker = {
            sources = {
               explorer = {
                  auto_close = true,
               },
            },
         },
         -- Importante tenerlo habilitado! porque lo use noice para redirigir las notificaciones
         notifier = {
            enabled = true,
         },
         git = {},
         terminal = {},
         -- detects the "scope" your cursor is currently inside (a function body, an if block, a loop, etc.)
         -- It doesn't do anything visible on its own. It's used by the indent module to know which indentation guide line to highlight as "current."
         scope = {},
         -- dims inactive scopes to focus on the current one. Toggled via <leader>tD.
         dim = {},
         indent = {
            scope = {
               hl = "MySnacksIndent",
            },
            chunk = {
               enabled = true,
               hl = "MySnacksIndent",
            },
         },
         statuscolumn = {
            left = { "mark", "git" },   -- priority of signs on the left (high to low)
            right = { "sign", "fold" }, -- priority of signs on the right (high to low)
            folds = {
               open = false,            -- show open fold icons
               git_hl = false,          -- use Git Signs hl for fold icons
            },
            git = {
               -- patterns to match Git signs
               -- Snacks doesn't hardcode which plugin provides git signs.
               -- It looks for highlight groups matching these patterns to know "this sign is a git sign".
               -- It supports both gitsigns.nvim (GitSign) and mini.diff (MiniDiffSign)
               patterns = { "GitSign", "MiniDiffSign" },
            },
            refresh = 50, -- refresh at most every 50ms
         },
         dashboard = {
            preset = {
               -- frame 0 del splash; milli después anima sobre estas mismas líneas
               header = splash_header,
               keys = {
                  { icon = " ", key = "f", desc = "Find File",    action = ":lua Snacks.picker.smart()" },
                  { icon = " ", key = "n", desc = "New File",     action = ":ene | startinsert" },
                  { icon = " ", key = "g", desc = "Grep",         action = ":lua Snacks.picker.grep()" },
                  { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
                  { icon = " ", key = "q", desc = "Quit",         action = ":qa" },
               },
            },
            sections = {
               { section = "header" },
               {
                  text = { { "── krapp.vim ──", hl = "SnacksDashboardTitle" } },
                  align = "center",
                  padding = 1,
               },
               { section = "keys",         gap = 1,    padding = 1 },
               { section = "recent_files", indent = 2, padding = 1 },
               {
                  text = {
                     { "Neovim v" .. tostring(vim.version()), hl = "SnacksDashboardFooter" },
                  },
                  align = "center",
                  padding = 1,
               },
            },
         },
         -- make sure lazygit always reopens the correct program
         -- hopefully this can be removed one day
         lazygit = {
            config = {
               os = {
                  editPreset = "nvim-remote",
                  edit = vim.v.progpath
                      .. [=[ --server "$NVIM" --remote-send '<cmd>lua nixInfo.lazygit_fix({{filename}})<CR>']=],
                  editAtLine = vim.v.progpath
                      .. [=[ --server "$NVIM" --remote-send '<cmd>lua nixInfo.lazygit_fix({{filename}}, {{line}})<CR>']=],
                  openDirInEditor = vim.v.progpath
                      .. [=[ --server "$NVIM" --remote-send '<cmd>lua nixInfo.lazygit_fix({{dir}})<CR>']=],
                  -- this one isnt a remote command, make sure it gets our config regardless of if we name it nvim or not
                  editAtLineAndWait = nixInfo(vim.v.progpath, "progpath")
                      .. " +{{line}} {{filename}}",
               },
            },
         },
      })

      -- Arranca la animación del splash sobre el header del dashboard.
      -- Tiene que correr DESPUÉS de Snacks.setup() para que el buffer del
      -- dashboard exista y milli encuentre el anchor (frame 0 = splash_header).
      require("milli").snacks({ splash = SPLASH, loop = true })

      -- Handle the backend of those remote commands.
      -- hopefully this can be removed one day
      nixInfo.lazygit_fix = function(path, line)
         local prev = vim.fn.bufnr("#")
         local prev_win = vim.fn.bufwinid(prev)
         vim.api.nvim_feedkeys("q", "n", false)
         if line then
            vim.api.nvim_buf_call(prev, function()
               vim.cmd.edit(path)
               local buf = vim.api.nvim_get_current_buf()
               vim.schedule(function()
                  if buf then
                     vim.api.nvim_win_set_buf(prev_win, buf)
                     vim.api.nvim_win_set_cursor(0, { line or 0, 0 })
                  end
               end)
            end)
         else
            vim.api.nvim_buf_call(prev, function()
               vim.cmd.edit(path)
               local buf = vim.api.nvim_get_current_buf()
               vim.schedule(function()
                  if buf then
                     vim.api.nvim_win_set_buf(prev_win, buf)
                  end
               end)
            end)
         end
      end

      -- NOTE: we aren't loading this lazily, and the keybinds already are so it is fine to just set these here

      -- snacks general stuff
      vim.keymap.set("n", "-", function()
         Snacks.explorer.open()
      end, { desc = "Snacks file explorer" })

      -- toggle: misma terminal abre/cierra, preservando el buffer y el historial.
      -- Funciona en modo normal y desde adentro de la propia terminal.
      vim.keymap.set({ "n", "t" }, "<c-\\>", function()
         Snacks.terminal.toggle()
      end, { desc = "Toggle terminal" })

      vim.keymap.set("n", "<leader>gl", function()
         Snacks.lazygit.open()
      end, { desc = "Snacks LazyGit" })

      -- [s]earch
      vim.keymap.set("n", "<leader>sf", function()
         Snacks.picker.smart()
      end, { desc = "Smart Find Files" })

      vim.keymap.set("n", "<leader><leader>s", function()
         Snacks.picker.buffers()
      end, { desc = "Search Buffers" })

      -- [f]ind
      vim.keymap.set("n", "<leader>ff", function()
         Snacks.picker.files()
      end, { desc = "Find Files" })

      vim.keymap.set("n", "<leader>fg", function()
         Snacks.picker.git_files()
      end, { desc = "Find Git Files" })

      -- Grep
      vim.keymap.set("n", "<leader>sg", function()
         Snacks.picker.grep()
      end, { desc = "Grep" })

      vim.keymap.set("n", "<leader>sB", function()
         Snacks.picker.grep_buffers()
      end, { desc = "Grep Open Buffers" })

      -- The two following keybindings are the same one, but have different descriptions for each mode
      vim.keymap.set("n", "<leader>sw", function()
         Snacks.picker.grep_word()
      end, { desc = "Grep word under cursor" })

      vim.keymap.set("x", "<leader>sw", function()
         Snacks.picker.grep_word()
      end, { desc = "Grep visual selection" })

      -- [s]earch
      vim.keymap.set("n", "<leader>sb", function()
         Snacks.picker.lines()
      end, { desc = "Current buffer lines" })

      vim.keymap.set("n", "<leader>sd", function()
         Snacks.picker.diagnostics()
      end, { desc = "Diagnostics" })

      vim.keymap.set("n", "<leader>sD", function()
         Snacks.picker.diagnostics_buffer()
      end, { desc = "Buffer Diagnostics" })

      vim.keymap.set("n", "<leader>sh", function()
         Snacks.picker.help()
      end, { desc = "Help Pages" })

      vim.keymap.set("n", "<leader>sj", function()
         Snacks.picker.jumps()
      end, { desc = "Jumps" })

      vim.keymap.set("n", "<leader>sk", function()
         Snacks.picker.keymaps()
      end, { desc = "Keymaps" })

      vim.keymap.set("n", "<leader>sl", function()
         Snacks.picker.loclist()
      end, { desc = "Location List" })

      vim.keymap.set("n", "<leader>sm", function()
         Snacks.picker.marks()
      end, { desc = "Marks" })

      vim.keymap.set("n", "<leader>sq", function()
         Snacks.picker.qflist()
      end, { desc = "Quickfix List" })

      vim.keymap.set("n", "<leader>sR", function()
         Snacks.picker.resume()
      end, { desc = "Resume last opened picker" })

      vim.keymap.set("n", "<leader>su", function()
         Snacks.picker.undo()
      end, { desc = "History of undo's" })

      -- Abre el archivo (o línea/selección) actual en el browser, en el remoto
      -- correspondiente (GitHub, GitLab, Bitbucket).
      vim.keymap.set({ "n", "v" }, "<leader>gB", function()
         Snacks.gitbrowse()
      end, { desc = "Git Browse (open in browser)" })

      -- Rename file con awareness de LSP: actualiza imports en otros archivos.
      vim.keymap.set("n", "<leader>cR", function()
         Snacks.rename.rename_file()
      end, { desc = "[R]ename file (LSP-aware)" })

      -- Toggle Snacks.dim (focus on current scope, dim everything else)
      local _dim_enabled = false
      Snacks.toggle({
         name = "Dim",
         get = function() return _dim_enabled end,
         set = function(state)
            _dim_enabled = state
            if state then
               Snacks.dim()
            else
               Snacks.dim.disable()
            end
         end,
      }):map("<leader>tD")
   end,
   },
}
