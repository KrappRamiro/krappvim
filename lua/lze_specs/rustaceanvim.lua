-- rustaceanvim: reemplaza al bloque `rust_analyzer` que estaba en lsp.lua.
-- Arranca rust-analyzer por su cuenta y suma el comando `:RustLsp`, con cosas
-- que el LSP estándar de Neovim no trae: expandir macros, abrir docs.rs,
-- explicar un error con el índice de errores de Rust, correr tests, etc.
--
-- OJO: no puede convivir con un spec "rust_analyzer" de nvim-lspconfig. Serían
-- dos clientes rust-analyzer en el mismo buffer (diagnósticos y completado
-- duplicados). El cliente de rustaceanvim se llama "rust-analyzer" (con guión).
--
-- No tiene setup(): es un "filetype plugin". Lee `vim.g.rustaceanvim` cuando
-- se abre el primer archivo .rs, por eso la config va en `before` (que corre
-- antes de que el plugin cargue) y no en `after`.
--
-- Doc de la versión instalada: :help rustaceanvim
-- No configuramos debug (nvim-dap): el firmware del ESP32 no corre en la PC.

-- Keymaps que solo existen en buffers Rust. Todo bajo <leader>r (el grupo está
-- declarado en which_key.lua), menos K y J que pisan a los de siempre con la
-- versión de rust-analyzer.
local function on_attach(_, bufnr)
   local function map(keys, cmd, desc)
      vim.keymap.set("n", keys, cmd, { buffer = bufnr, silent = true, desc = "Rust: " .. desc })
   end
   local function rust_lsp(args, bang)
      return function()
         vim.cmd.RustLsp({ args = args, bang = bang })
      end
   end

   -- K: el hover normal más las acciones (ir a la implementación, correr el
   -- test, etc). Entrás a la ventana con otra K y elegís con <CR>.
   map("K", rust_lsp({ "hover", "actions" }), "Hover con acciones")
   -- J: une líneas entendiendo Rust (saca la coma o las llaves que sobran)
   map("J", rust_lsp({ "joinLines" }), "Unir líneas")

   -- entender errores
   map("<leader>re", rust_lsp({ "explainError" }), "[e]xplicar el error (índice de Rust)")
   map("<leader>rd", rust_lsp({ "renderDiagnostic" }), "[d]iagnóstico como en cargo build")
   map("<leader>rD", rust_lsp({ "relatedDiagnostics" }), "[D]iagnósticos relacionados")

   -- entender código
   map("<leader>rm", rust_lsp({ "expandMacro" }), "expandir [m]acro")
   map("<leader>ro", rust_lsp({ "openDocs" }), "[o]pen docs.rs")
   map("<leader>rp", rust_lsp({ "parentModule" }), "módulo [p]adre")
   map("<leader>rC", rust_lsp({ "openCargo" }), "abrir [C]argo.toml")

   -- correr: la mayúscula repite lo último (`:RustLsp!`)
   map("<leader>rr", rust_lsp({ "runnables" }), "[r]unnables (elegir qué correr)")
   map("<leader>rR", rust_lsp({ "runnables" }, true), "[R]epetir el último runnable")
   map("<leader>rc", rust_lsp({ "run" }), "correr lo que está bajo el [c]ursor")
   map("<leader>rt", rust_lsp({ "testables" }), "[t]ests (elegir cuál)")
   map("<leader>rT", rust_lsp({ "testables" }, true), "repetir el último [T]est")

   -- editar
   -- <leader>ca sigue siendo el code action de siempre (tiny-code-action).
   -- Este agrupa las acciones por categoría, como las manda rust-analyzer.
   map("<leader>ra", rust_lsp({ "codeAction" }), "code [a]ction agrupadas")
   map("<leader>rk", rust_lsp({ "moveItem", "up" }), "mover item arriba")
   map("<leader>rj", rust_lsp({ "moveItem", "down" }), "mover item abajo")
end

return {
   "rustaceanvim",
   auto_enable = true,
   ft = "rust",
   before = function(_)
      -- El spec de nvim-lspconfig define, en su `before`, los keymaps comunes a
      -- todos los LSP (gd, grr, <leader>rn...), los inlay hints y la carga de
      -- blink (para que el server reciba las capabilities de completado).
      -- Normalmente lo dispara el primer server de lsp.lua; como rust-analyzer
      -- ya no pasa por ahí, lo cargamos a mano.
      nixInfo.lze.trigger_load("nvim-lspconfig")

      ---@type rustaceanvim.Opts
      vim.g.rustaceanvim = {
         tools = {
            -- clippy en vez de `cargo check` al guardar. Es el default si
            -- encuentra cargo-clippy, lo dejamos escrito para que se vea.
            -- lint.lua no corre clippy, así no hay diagnósticos duplicados.
            enable_clippy = true,
         },
         server = {
            on_attach = on_attach,
            default_settings = {
               -- la clave lleva guión, por eso necesita la sintaxis ["..."]
               ["rust-analyzer"] = {
                  cargo = {
                     allFeatures = true,
                  },
               },
            },
         },
      }
   end,
   after = function(_)
      -- rustaceanvim arranca el LSP desde su ftplugin/rust.lua. Neovim corre
      -- los ftplugin ANTES de que lze cargue el plugin (los dos escuchan el
      -- mismo evento FileType), así que para el archivo que disparó la carga
      -- ese ftplugin todavía no existía y rust-analyzer no arrancaba.
      -- Lo corremos a mano para este buffer. Los próximos .rs ya lo encuentran.
      if vim.bo.filetype ~= "rust" then
         return
      end
      for _, file in ipairs(vim.api.nvim_get_runtime_file("ftplugin/rust.*", true)) do
         if file:find("rustaceanvim", 1, true) then
            vim.cmd.source(file)
         end
      end
   end,
}
