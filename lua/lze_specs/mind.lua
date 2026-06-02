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
   end,
}
