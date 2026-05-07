-- hop.nvim: jumps con labels asignadas a TODO el viewport de una.
-- Apretás `s`, ves labels en cada palabra del viewport, apretás la label
-- y saltás. Ideal cuando ya estás mirando dónde querés ir.
return {
   "hop.nvim",
   auto_enable = true,
   keys = {
      { "s", mode = "n" },
   },
   after = function()
      require("hop").setup({})
      vim.keymap.set("n", "s", "<cmd>HopWord<cr>", { desc = "Hop word" })
   end,
}
