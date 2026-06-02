return {
   "mind",
   auto_enable = true,
   cmd = { "MindOpenMain", "MindOpenSmartProject", "MindOpenProject", "MindClose", "MindReloadState" },
   keys = {
      { "<leader>nm", "<cmd>MindOpenMain<cr>",         desc = "Open [m]ain mind tree" },
      { "<leader>np", "<cmd>MindOpenSmartProject<cr>", desc = "Open [p]roject mind tree" },
      { "<leader>nc", "<cmd>MindClose<cr>",            desc = "[c]lose mind tree" },
   },
   after = function()
      require("mind").setup({
         persistence = {
            state_path = vim.fn.expand("~/.local/share/mind.nvim/mind.json"),
            data_dir = vim.fn.expand("~/.local/share/mind.nvim/data"),
         },
      })

      vim.api.nvim_create_autocmd("FileType", {
         pattern = "mind",
         callback = function(ev)
            vim.keymap.set("n", "?", function()
               local lines = {
                  "  mind.nvim keybindings          ",
                  "  ──────────────────────────────  ",
                  "  Navigation                      ",
                  "  <cr>      Open data file        ",
                  "  <s-cr>    Open data file (index)",
                  "  <tab>     Toggle node           ",
                  "  <s-tab>   Toggle parent         ",
                  "  /         Select by path        ",
                  "                                  ",
                  "  Add nodes                       ",
                  "  o         Add below             ",
                  "  O         Add above             ",
                  "  i         Add inside (end)      ",
                  "  I         Add inside (start)    ",
                  "  c         Add inside end (index)",
                  "                                  ",
                  "  Edit                            ",
                  "  r         Rename                ",
                  "  d         Delete node           ",
                  "  D         Delete data file      ",
                  "  u         Make URL              ",
                  "                                  ",
                  "  Icons                           ",
                  "  $         Change icon (menu)    ",
                  "  R         Change icon (direct)  ",
                  "                                  ",
                  "  Links & selection               ",
                  "  l         Copy link             ",
                  "  L         Copy link (index)     ",
                  "  x         Select node           ",
                  "  q         Quit                  ",
                  "                                  ",
                  "  Press q or <esc> to close       ",
               }
               local buf = vim.api.nvim_create_buf(false, true)
               vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
               vim.bo[buf].modifiable = false
               local width = 36
               local height = #lines
               local win = vim.api.nvim_open_win(buf, true, {
                  relative = "editor",
                  width = width,
                  height = height,
                  row = math.floor((vim.o.lines - height) / 2),
                  col = math.floor((vim.o.columns - width) / 2),
                  style = "minimal",
                  border = "rounded",
               })
               for _, key in ipairs({ "q", "<esc>", "?" }) do
                  vim.keymap.set("n", key, function()
                     vim.api.nvim_win_close(win, true)
                  end, { buffer = buf, nowait = true })
               end
            end, { buffer = ev.buf, desc = "Show keybindings" })

            require("which-key").add({
               -- normal navigation
               { "<cr>",    desc = "Open data file",         buffer = ev.buf },
               { "<s-cr>",  desc = "Open data file (index)", buffer = ev.buf },
               { "<tab>",   desc = "Toggle node",            buffer = ev.buf },
               { "<s-tab>", desc = "Toggle parent",          buffer = ev.buf },
               { "/",       desc = "Select by path",         buffer = ev.buf },
               -- adding nodes
               { "o",       desc = "Add node below",         buffer = ev.buf },
               { "O",       desc = "Add node above",         buffer = ev.buf },
               { "i",       desc = "Add node inside (end)",  buffer = ev.buf },
               { "I",       desc = "Add node inside (start)",buffer = ev.buf },
               { "c",       desc = "Add inside end (index)", buffer = ev.buf },
               -- editing
               { "r",       desc = "Rename node",            buffer = ev.buf },
               { "d",       desc = "Delete node",            buffer = ev.buf },
               { "D",       desc = "Delete data file",       buffer = ev.buf },
               { "u",       desc = "Make URL node",          buffer = ev.buf },
               -- icons
               { "$",       desc = "Change icon (menu)",     buffer = ev.buf },
               { "R",       desc = "Change icon (direct)",   buffer = ev.buf },
               -- links & selection
               { "l",       desc = "Copy node link",         buffer = ev.buf },
               { "L",       desc = "Copy node link (index)", buffer = ev.buf },
               { "x",       desc = "Select node",            buffer = ev.buf },
               { "q",       desc = "Quit",                   buffer = ev.buf },
            })
         end,
      })
   end,
}
