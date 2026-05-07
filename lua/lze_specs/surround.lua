return {
   "nvim-surround",
   auto_enable = true,
   event = "DeferredUIEnter",
   after = function()
      require("nvim-surround").setup()
   end,
}
