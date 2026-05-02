-- If you ask yourself "hey, why are you returning an object", its because this will be loaded by lze specs. and lze specs expects an object
return {
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

      require("snacks").setup({
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
         git = {},
         terminal = {},
         -- detects the "scope" your cursor is currently inside (a function body, an if block, a loop, etc.)
         -- It doesn't do anything visible on its own. It's used by the indent module to know which indentation guide line to highlight as "current."
         scope = {},
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
            left = { "mark", "git" }, -- priority of signs on the left (high to low)
            right = { "sign", "fold" }, -- priority of signs on the right (high to low)
            folds = {
               open = false, -- show open fold icons
               git_hl = false, -- use Git Signs hl for fold icons
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
               header = [[
 ██ ▄█▀ ██▀███   ▄▄▄       ██▓███   ██▓███      ██▒   █▓ ██▓ ███▄ ▄███▓
 ██▄█▒ ▓██ ▒ ██▒▒████▄    ▓██░  ██▒▓██░  ██▒   ▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓███▄░ ▓██ ░▄█ ▒▒██  ▀█▄  ▓██░ ██▓▒▓██░ ██▓▒    ▓██  █▒░▒██▒▓██    ▓██░
▓██ █▄ ▒██▀▀█▄  ░██▄▄▄▄██ ▒██▄█▓▒ ▒▒██▄█▓▒ ▒     ▒██ █░░░██░▒██    ▒██
▒██▒ █▄░██▓ ▒██▒ ▓█   ▓██▒▒██▒ ░  ░▒██▒ ░  ░      ▒▀█░  ░██░▒██▒   ░██▒
▒ ▒▒ ▓▒░ ▒▓ ░▒▓░ ▒▒   ▓▒█░▒▓▒░ ░  ░▒▓▒░ ░  ░      ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░▒ ▒░  ░▒ ░ ▒░  ▒   ▒▒ ░░▒ ░     ░▒ ░           ░ ░░   ▒ ░░  ░      ░
░ ░░ ░   ░░   ░   ░   ▒   ░░       ░░               ░░   ▒ ░░      ░
░  ░      ░           ░  ░                           ░   ░         ░
                                                    ░                  ]],
               keys = {
                  { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.picker.smart()" },
                  { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                  { icon = " ", key = "g", desc = "Grep", action = ":lua Snacks.picker.grep()" },
                  { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.picker.recent()" },
                  { icon = " ", key = "q", desc = "Quit", action = ":qa" },
               },
            },
            sections = {
               { section = "header" },
               { section = "keys", gap = 1, padding = 1 },
               { section = "recent_files", indent = 2, padding = 1 },
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

      vim.keymap.set("n", "<c-\\>", function()
         Snacks.terminal.open()
      end, { desc = "Snacks Terminal" })

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
   end,
}
