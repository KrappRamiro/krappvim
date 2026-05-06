return {
     "tiny-inline-diagnostic.nvim",
     auto_enable = true,
     event = "DeferredUIEnter",
     after = function()
        vim.diagnostic.config({ virtual_text = false })
        require("tiny-inline-diagnostic").setup()
     end,
  }
