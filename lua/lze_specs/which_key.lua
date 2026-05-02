return {
   "which-key.nvim",
   auto_enable = true,
   -- cmd = { "" },
   event = "DeferredUIEnter",
   -- ft = "",
   -- keys = "",
   -- colorscheme = "",
   after = function(plugin)
      require("which-key").setup({})
      require("which-key").add({
         { "gr", group = "LSP" },
         { "gra", desc = "[C]ode [A]ction" },
         { "grn", desc = "[R]e[n]ame" },
         { "gri", desc = "[G]oto [I]mplementation" },
         { "grx", desc = "[C]odelens [R]un" },

         { "<leader><leader>", group = "buffer commands" },
         { "<leader><leader>_", hidden = true },

         { "<leader>c", group = "[c]ode" },
         { "<leader>c_", hidden = true },

         { "<leader>g", group = "[g]it", icon = "󰊢" },
         { "<leader>g_", hidden = true },

         { "<leader>s", group = "[f]ind" },
         { "<leader>s_", hidden = true },

         { "<leader>s", group = "[s]earch" },
         { "<leader>s_", hidden = true },

         { "<leader>t", group = "[t]oggles" },
         { "<leader>t_", hidden = true },
      })
   end,
}
