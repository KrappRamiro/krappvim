-- sidekick.nvim: terminal integrada para CLIs de IA (claude, claude-work,
-- kiro-cli...) con prompts que le pasan contexto del editor: archivo, línea,
-- selección, diagnostics, la función bajo el cursor, etc.
--
-- La otra mitad del plugin, las "Next Edit Suggestions" de Copilot, está
-- apagada: necesita cuenta de Copilot y el copilot-language-server (unfree).
--
-- Se carga lazy: con cualquiera de los keymaps de abajo, con :Sidekick, o
-- cuando algo hace require("sidekick...") (la acción del picker de snacks y
-- el componente de lualine).
return {
   "sidekick.nvim",
   auto_enable = true,
   cmd = { "Sidekick" },
   on_require = { "sidekick" },
   keys = {
      -- Saltar entre el código y la CLI (si la CLI no está abierta, la abre).
      -- Funciona desde cualquier modo, incluso desde adentro de la terminal.
      {
         "<c-.>",
         function()
            require("sidekick.cli").focus()
         end,
         mode = { "n", "t", "i", "x" },
         desc = "Sidekick focus",
      },
      {
         "<leader>aa",
         function()
            require("sidekick.cli").toggle()
         end,
         desc = "Toggle AI CLI",
      },
      {
         "<leader>as",
         function()
            -- solo las CLIs instaladas en esta máquina (kiro-cli existe solo en gocloud)
            require("sidekick.cli").select({ filter = { installed = true } })
         end,
         desc = "Select AI CLI",
      },
      {
         "<leader>ad",
         function()
            require("sidekick.cli").close()
         end,
         desc = "Detach AI CLI session",
      },
      -- {this}: en un archivo manda la posición del cursor (@archivo#L10),
      -- con selección visual manda el rango seleccionado.
      {
         "<leader>at",
         function()
            require("sidekick.cli").send({ msg = "{this}" })
         end,
         mode = { "n", "x" },
         desc = "Send this (cursor / selection)",
      },
      {
         "<leader>af",
         function()
            require("sidekick.cli").send({ msg = "{file}" })
         end,
         desc = "Send file",
      },
      {
         "<leader>av",
         function()
            require("sidekick.cli").send({ msg = "{selection}" })
         end,
         mode = { "x" },
         desc = "Send visual selection",
      },
      {
         "<leader>ap",
         function()
            require("sidekick.cli").prompt()
         end,
         mode = { "n", "x" },
         desc = "Pick a prompt",
      },
      -- Accesos directos a cada CLI
      {
         "<leader>ac",
         function()
            require("sidekick.cli").toggle({ name = "claude", focus = true })
         end,
         desc = "Toggle Claude (personal)",
      },
      {
         "<leader>aw",
         function()
            require("sidekick.cli").toggle({ name = "claude_work", focus = true })
         end,
         desc = "Toggle Claude (work)",
      },
      {
         "<leader>ak",
         function()
            require("sidekick.cli").toggle({ name = "kiro", focus = true })
         end,
         desc = "Toggle Kiro CLI",
      },
   },
   after = function()
      -- claude-work es un wrapper de claude (ver claude.nix en nixos-config)
      -- que cambia CLAUDE_CONFIG_DIR. Reusamos la config que sidekick trae
      -- para claude (sobre todo `format`, que traduce las referencias
      -- @archivo :L10-L20 al formato @archivo#L10-20 que entiende Claude).
      local claude_file = vim.api.nvim_get_runtime_file("sk/cli/claude.lua", false)[1]
      local claude = claude_file and dofile(claude_file) or {}

      require("sidekick").setup({
         -- Next Edit Suggestions de Copilot: apagadas (ver arriba)
         nes = { enabled = false },
         copilot = { status = { enabled = false } },

         cli = {
            -- recarga los buffers cuando la IA edita archivos en disco
            watch = true,
            picker = "snacks",
            win = {
               layout = "right",
               split = {
                  -- 40% del ancho: la UI de claude se rompe con menos de ~80 columnas
                  width = 0.4,
               },
            },
            tools = {
               claude_work = vim.tbl_extend("force", claude, {
                  cmd = { "claude-work" },
               }),
               kiro = {
                  cmd = { "kiro-cli", "chat" },
                  url = "https://kiro.dev/docs/cli/",
               },
            },
            -- Se suman a los prompts que trae sidekick (explain, fix, tests,
            -- review, diagnostics...). Se eligen con <leader>ap o con <c-p>
            -- desde adentro de la CLI.
            prompts = {
               refactor = "Refactor {this} to be more readable and maintainable, without changing its behavior",
               security = "Review {file} for security issues",
               commit = "Write a commit message for my staged changes",
            },
         },
      })
   end,
}
