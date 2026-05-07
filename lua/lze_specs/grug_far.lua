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
   after = function()
      local grugInstanceName = "krappvim-grug-global-instance" -- just to avoid repeating
      require("grug-far").setup({
         -- no-op: el keymap se encarga de abrir la window (flotante) antes
         -- grug_far solamente pone su buffer ahí, asi que no hace falta crear ninguna ventana,
         -- por eso usamos echo '', para que sea un no-op
         windowCreationCommand = "echo ''",
      })

      local function open_float()
         return Snacks.win({
            width = 0.85,
            height = 0.85,
            border = "rounded",
            backdrop = 60,
            enter = true, -- esta ventana queda como la activa
            fixbuf = false, -- permite que grug-far reemplace el buffer
         })
      end

      -- FILL AUTOMATICO DE Files Filter EN GRUG
      -- Esto se encarga de automaticamente rellenar Files Filter con la extension de tu archivo actual
      -- Es un atajo: el 90% de las veces que abrís un buscador estando en un .lua, querés buscar en .lua. Te ahorra tipear ese filtro cada vez.
      -- ┌────────────────── grug-far ───────────────┐
      -- │ Search:        [_____________]            │
      -- │ Replace:       [_____________]            │
      -- │ Files Filter:  [_____________]  ← este    │
      -- │ Flags:         [_____________]            │
      -- ├───────────────────────────────────────────┤
      -- │  (acá aparecen los resultados)            │
      -- └───────────────────────────────────────────┘
      --
      local function getFilesFilter()
         -- fileExtension va a terminar teniendo la extensión del archivo, los posibles valores pueden ser:
         --    archivo con extensión                                -->     "js" o "py" o "lua" etc...
         --    archivo normal pero sin extensión, tipo Makefile     -->     "" (string vacío)
         --    otro tipo de buffer (terminal, help, etc...)         -->     false
         local fileExtension
         if vim.bo.buftype == "" then -- vim.bo.buftype vale "" cuando estas dentro de un archivo normal. Si por ejemplo estuvieras dentro de una terminal, valdria "terminal"
            fileExtension = vim.fn.expand("%:e") -- guardo la extensión
         else
            fileExtension = false -- no es archivo normal, no me sirve
         end

         if not fileExtension then
            return nil -- caso 1: otro tipo de buffer (terminal, help, quickfix, etc)
         elseif fileExtension == "" then
            return nil -- caso 2: archivo sin extensión
         else
            return "*." .. fileExtension -- caso 3: archivo con extensión
         end
      end

      vim.keymap.set({ "n", "v" }, "<leader>sr", function()
         local grug = require("grug-far")

         if grug.has_instance(grugInstanceName) then
            local inst = grug.get_instance(grugInstanceName)
            if not inst then
               vim.notify(
                  "grug-far: has_instance('"
                     .. grugInstanceName
                     .. "') devolvió true pero get_instance() devolvió nil. "
                     .. "Esto no debería pasar salvo que cambie la API interna de grug-far.",
                  vim.log.levels.ERROR
               )
               return
            end
            if inst:is_open() then
               inst:hide()
            else
               open_float()
               inst:open()
            end
            return
         end

         -- ojo: getFilesFilter() lee el buffer actual, así que tenemos que llamarlo
         -- ANTES de open_float(), sino terminás midiendo el buffer scratch de la float
         local filter = getFilesFilter()
         open_float()
         grug.open({
            instanceName = grugInstanceName,
            prefills = {
               filesFilter = filter,
            },
         })
      end, { desc = "Search and Replace (toggle)" })
   end,
}
