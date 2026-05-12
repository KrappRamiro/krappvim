return {
   "which-key.nvim",
   auto_enable = true,
   -- cmd = { "" },
   event = "DeferredUIEnter",
   -- ft = "",
   -- keys = "",
   -- colorscheme = "",
   after = function(plugin)
      require("which-key").setup({
         preset = "modern",
         delay = 100,
         win = {
            border = "rounded",
            padding = { 1, 2 },
            title = true,
            title_pos = "center",
         },
         layout = {
            width = { min = 20 },
            spacing = 6,
            align = "center",
         },
         icons = {
            mappings = true,
            colors = true,
            breadcrumb = "»",
            separator = "→",
            group = "+ ",
         },
         show_help = true,
         show_keys = true,
      })
      require("which-key").add({
         { "gr", group = "LSP", icon = "󰒋" },
         { "gra", desc = "[C]ode [A]ction" },
         { "grn", desc = "[R]e[n]ame" },
         { "gri", desc = "[G]oto [I]mplementation" },
         { "grx", desc = "[C]odelens [R]un" },

         { "<leader><leader>", group = "buffer commands", icon = "󰓩" },
         { "<leader><leader>_", hidden = true },

         { "<leader>c", group = "[c]ode", icon = "󰘦" },
         { "<leader>c_", hidden = true },
         { "<leader>cR", desc = "[R]ename file (LSP-aware)" },

         { "<leader>g", group = "[g]it", icon = "󰊢" },
         { "<leader>g_", hidden = true },
         { "<leader>gB", desc = "Git [B]rowse (open in browser)" },

         { "<leader>f", group = "[f]ind", icon = "󰈞" },
         { "<leader>f_", hidden = true },

         { "<leader>s", group = "[s]earch", icon = "󰍉" },
         { "<leader>s_", hidden = true },

         { "<leader>t", group = "[t]oggles", icon = "󰔡" },
         { "<leader>t_", hidden = true },
         { "<leader>th", desc = "Toggle inlay [H]ints" },
         { "<leader>tH", desc = "Toggle [H]ardtime" },
         { "<leader>tl", desc = "Toggle [l]ensline view" },
         { "<leader>tC", desc = "Toggle [C]olor highlighter" },
         { "<leader>tD", desc = "Toggle [D]im (focus current scope)" },

         { "<leader>M", group = "[M]arkdown (markview)", icon = "󰽛" },
         { "<leader>M_", hidden = true },
         -- Toggle render
         { "<leader>Mt", desc = "[t]oggle render (current buffer)" },
         { "<leader>MT", desc = "[T]oggle render (all buffers)" },
         -- Hybrid mode
         { "<leader>Mh", desc = "Toggle [h]ybrid mode (current)" },
         { "<leader>MH", desc = "Toggle [H]ybrid mode (all)" },
         -- Re-render forzado
         { "<leader>Mr", desc = "[r]e-render (current buffer)" },
         { "<leader>MR", desc = "[R]e-render (all buffers)" },
         -- Clear overlays
         { "<leader>Mc", desc = "[c]lear overlays (current)" },
         { "<leader>MC", desc = "[C]lear overlays (all)" },
         -- Linewise hybrid toggle
         { "<leader>Ml", desc = "Toggle [l]inewise hybrid mode" },
         -- Splitview
         { "<leader>Ms", desc = "Toggle [s]plitview preview" },
         -- Open link
         { "<leader>Mo", desc = "[o]pen link under cursor" },
         -- Debug
         { "<leader>Md", desc = "Show [d]ebug trace" },

         { "<leader>C", group = "[C]olor", icon = "󰸌" },
         { "<leader>C_", hidden = true },
         { "<leader>Cp", desc = "[C]olor [P]ick (ccc)" },

         { "<leader>m", group = "[m]ulticursor", icon = "󰆿" },
         { "<leader>m_", hidden = true },
         { "<leader>mN", desc = "Add cursor on prev match" },
         { "<leader>ms", desc = "[s]kip next match" },
         { "<leader>mS", desc = "Skip prev match" },
         { "<leader>mA", desc = "[A]dd cursors to all matches" },

      })
   end,
}
