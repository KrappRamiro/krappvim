-- Es un search and replace muy copado
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
         windowCreationCommand = "enew", -- enew significa "dame un buffer nuevo en la ventana actual"
      })

      local function open_float()
         return Snacks.win({
            width = 0.85,
            height = 0.85,
            border = "rounded",
            backdrop = 60,
            enter = true,   -- hace que esta ventana sea la activa
            fixbuf = false, -- permite que grug-far reemplace el buffer
         })
      end

      local function cleanup_orphans()
         vim.schedule(function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
               if vim.api.nvim_buf_get_name(buf) == ""
                  and vim.bo[buf].buftype == ""
                  and not vim.bo[buf].modified
                  and #vim.fn.win_findbuf(buf) == 0
               then
                  vim.api.nvim_buf_delete(buf, { force = true })
               end
            end
         end)
      end

      vim.keymap.set({ "n", "v" }, "<leader>sr", function()
         local grug = require("grug-far")
         local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")

         if grug.has_instance("main") then
            local inst = grug.get_instance("main")
            if not inst then
               vim.notify("grug-far: instance 'main' not found", vim.log.levels.ERROR)
               return
            end
            if inst:is_open() then
               -- already visible: hide it (buffer is preserved)
               inst:hide()
               return
            else
               -- hidden: re-open in a new float
               open_float()
               inst:open()
               cleanup_orphans()
               return
            end
         end

         -- first time: create float and open grug-far
         open_float()
         grug.open({
            instanceName = "main",
            windowCreationCommand = "enew",
            prefills = {
               filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
         })
         cleanup_orphans()
      end, { desc = "Search and Replace (toggle)" })
   end,
}
