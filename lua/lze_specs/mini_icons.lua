return {
   "mini.nvim",
   auto_enable = true,
   lazy = false,
   after = function(_)
      require("mini.icons").setup()
   end,
}
