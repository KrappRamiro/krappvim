-- hardtime.nvim: te corrige malos hábitos de motion en Vim. Cuando spameás
-- hjkl, presionás keys "lentas" (j/k 10 veces en lugar de 10j), o usás
-- arrows en lugar de hjkl, te tira un hint o lo bloquea según config.
--
-- Por default arranca ENABLED. Si te molesta, lo apagás con <leader>tH.
return {
   "hardtime.nvim",
   auto_enable = true,
   event = "DeferredUIEnter",
   cmd = { "Hardtime" },
   keys = {
      { "<leader>tH", mode = "n" },
   },
   after = function()
      require("hardtime").setup({
         -- defaults razonables. Algunas opciones útiles si querés tunear:
         --   max_count = 3      -- veces que podés repetir hjkl seguido
         --   disable_mouse = true  -- bloquea totalmente el mouse
         --   restriction_mode = "block"  -- "hint" (warn) o "block" (no deja)
      })

      vim.keymap.set("n", "<leader>tH", "<cmd>Hardtime toggle<cr>", { desc = "Toggle [H]ardtime" })
   end,
}
