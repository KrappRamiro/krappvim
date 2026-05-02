return {
   "grug-far.nvim",
   auto_enable = true,
   cmd = "GrugFar",
   keys = {
      {
         "<leader>sr",
         mode = { "n", "v" },
      },
   },
   after = function(plugin)
      require("grug-far").setup({
         windowCreationCommand = "enew",
      })

      vim.keymap.set({ "n", "v" }, "<leader>sr", function()
         local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
         require("grug-far").open({
            prefills = {
               filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
         })
      end, { desc = "Search and Replace" })
   end,
}
