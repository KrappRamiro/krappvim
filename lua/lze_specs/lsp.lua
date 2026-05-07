-- ────────────────────────────────────────────────────────────────────────
-- Cómo agregar un LSP server nuevo a este archivo
-- ────────────────────────────────────────────────────────────────────────
--
-- Cada server es un bloque con esta estructura:
--
--    {
--       "<NOMBRE_DEL_SERVER>",         -- ej: "rust_analyzer"
--       lsp = {
--          filetypes = { "<FT1>", ... }, -- los filetypes que dispara este server
--          settings = {
--             <NOMBRE_INTERNO> = {      -- el namespace de settings de este LSP
--                -- acá van las opciones del server
--             },
--          },
--       },
--    },
--
-- Dos cosas a tener en cuenta:
--
--   * "<NOMBRE_DEL_SERVER>" es el nombre que usa lspconfig.
--     No se inventa, son nombres específicos. La lista de valores posibles está en:
--     :help lspconfig-all
--     o en
--     https://github.com/neovim/nvim-lspconfig/tree/master/lsp
--
--   * settings: cada LSP tiene su propio namespace (Lua, nixd, python, rust-analyzer, etc).
--     Las opciones del server van envueltas en una tabla con la clave que ese
--     server espera.
--
-- Y obviamente, agregar el binario del server en module.nix
-- (config.specs.general.extraPackages).
-- ────────────────────────────────────────────────────────────────────────
return {
   {
      "nvim-lspconfig",
      auto_enable = true,
      -- NOTE: define a function for lsp,
      -- and it will run for all specs with type(plugin.lsp) == table
      -- when their filetype trigger loads them
      lsp = function(plugin)
         vim.lsp.config(plugin.name, plugin.lsp or {})
         vim.lsp.enable(plugin.name)
      end,
      -- set up our on_attach function once before the spec loads
      before = function(_)
         -- Inlay hints: anotaciones inline (nombres de params, tipos inferidos)
         -- que el LSP envía. Por default Neovim NO las muestra aunque el LSP
         -- las mande, hay que activarlas explícitamente.
         vim.lsp.inlay_hint.enable(true)

         -- Toggle global de inlay hints. Vive bajo <leader>t* (toggles).
         -- El group está declarado en which_key.lua.
         vim.keymap.set("n", "<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
         end, { desc = "Toggle inlay [H]ints" })

         vim.lsp.config("*", {
            on_attach = function(_, bufnr)
               -- we create a function that lets us more easily define mappings specific
               -- for LSP related items. It sets the mode, buffer and description for us each time.
               local nmap = function(keys, func, desc)
                  if desc then
                     desc = "LSP: " .. desc
                  end
                  vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
               end

               nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
               -- usa tiny-code-action.nvim (picker snacks + diff preview con delta)
               -- en lugar del default vim.lsp.buf.code_action que tira un dropdown
               -- chiquito sin preview
               nmap("<leader>ca", function() require("tiny-code-action").code_action() end, "[C]ode [A]ction")
               nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
               nmap("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
               nmap("grr", function()
                  Snacks.picker.lsp_references()
               end, "[G]oto [R]eferences")
               nmap("gI", function()
                  Snacks.picker.lsp_implementations()
               end, "[G]oto [I]mplementation")
               nmap("<leader>ds", function()
                  Snacks.picker.lsp_symbols()
               end, "[D]ocument [S]ymbols")
               nmap("<leader>ws", function()
                  Snacks.picker.lsp_workspace_symbols()
               end, "[W]orkspace [S]ymbols")

               -- See `:help K` for why this keymap
               nmap("K", vim.lsp.buf.hover, "Hover Documentation")
               -- C-k freed for window nav, hover is usually better than signature_help (but it depends on LSP implementation)
               -- See https://github.com/neovim/neovim/discussions/25711
               -- nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

               -- Lesser used LSP functionality
               nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
               nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
               nmap(
                  "<leader>wr",
                  vim.lsp.buf.remove_workspace_folder,
                  "[W]orkspace [R]emove Folder"
               )
               nmap("<leader>wl", function()
                  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
               end, "[W]orkspace [L]ist Folders")

               -- Create a command `:Format` local to the LSP buffer
               vim.api.nvim_buf_create_user_command(bufnr, "Format", function(_)
                  vim.lsp.buf.format()
               end, { desc = "Format current buffer with LSP" })
            end,
         })
      end,
   },
   {
      "mason.nvim",
      enabled = not nixInfo.isNix,
      priority = 100, -- <- run lsp hook before lspconfig's hook
      on_plugin = { "nvim-lspconfig" },
      lsp = function(plugin)
         vim.cmd.MasonInstall(plugin.name)
      end,
   },
   {
      -- lazydev makes your Lua LSP load only the relevant definitions for a file.
      -- It also gives us a nice way to correlate globals we create with files.
      "lazydev.nvim",
      auto_enable = true,
      cmd = { "LazyDev" },
      ft = "lua",
      after = function(_)
         require("lazydev").setup({
            library = {
               {
                  words = { "nixInfo%.lze" },
                  path = nixInfo("lze", "plugins", "start", "lze") .. "/lua",
               },
               {
                  words = { "nixInfo%.lze" },
                  path = nixInfo("lzextras", "plugins", "start", "lzextras") .. "/lua",
               },
               {
                  words = { "Snacks" },
                  path = nixInfo.get_nix_plugin_path("snacks.nvim") .. "/lua",
               },
               {
                  words = { "noice" },
                  path = nixInfo.get_nix_plugin_path("noice.nvim") .. "/lua",
               },
            },
         })
      end,
   },

   --- LSP START GOING HERE

   {
      -- name of the lsp
      "lua_ls",
      lsp = {
         -- if you provide the filetypes it doesn't ask lspconfig for the filetypes
         -- (meaning it doesn't call the callback function we defined in the main init.lua)
         filetypes = { "lua" },
         settings = {
            Lua = {
               signatureHelp = { enabled = true },
               diagnostics = {
                  globals = { "nixInfo", "vim" },
                  disable = { "missing-fields" },
               },
            },
         },
      },
   },
   {
      "nixd",
      enabled = nixInfo.isNix, -- mason doesn't have nixd
      lsp = {
         filetypes = { "nix" },
         settings = {
            nixd = {
               nixpkgs = {
                  expr = [[import <nixpkgs> {}]],
               },
               options = {},
               formatting = {
                  command = { "nixfmt" },
               },
               diagnostic = {
                  suppress = {
                     "sema-escaping-with",
                  },
               },
            },
         },
      },
   },
   {
      -- NOTE: bashls usa shellcheck por dentro para diagnostics, así que se solapa
      -- con `sh = { "shellcheck" }` y `bash = { "shellcheck" }` en lint.lua.
      -- Si querés evitar duplicados, sacalos de lint.lua.
      "bashls",
      lsp = {
         filetypes = { "sh", "bash" },
      },
   },
   {
      -- NOTE: si ves diagnosticos duplicados, es porque tanto el LSP como el Linter estan dando diagnosticos y se estan solapando
      "rust_analyzer",
      lsp = {
         filetypes = { "rust" },
         settings = {
            -- la clave lleva guión, por eso necesita la sintaxis ["..."]
            ["rust-analyzer"] = {
               check = {
                  command = "clippy", -- usa clippy en lugar de cargo check
               },
               cargo = {
                  allFeatures = true,
               },
            },
         },
      },
   },
   {
      -- basedpyright es un fork comunitario de pyright con más features
      -- (mejor inferencia, más diagnostics, configurables sin licencia comercial)
      "basedpyright",
      lsp = {
         filetypes = { "python" },
         settings = {
            basedpyright = {
               analysis = {
                  typeCheckingMode = "strict", -- "off" | "basic" | "standard" | "strict" | "all"
                  autoImportCompletions = true,
                  diagnosticMode = "openFilesOnly",
               },
            },
         },
      },
   },
   {
      -- maneja tanto Terraform como OpenTofu (.tf, .tfvars, .tofu)
      "terraformls",
      lsp = {
         filetypes = { "terraform", "terraform-vars", "tf" },
      },
   },
   {
      -- un solo server cubre js, jsx, ts, tsx
      "ts_ls",
      lsp = {
         filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
         settings = {
            -- inlayHints es que te aparezca un texto gris dando info adicional, como cuando tenes esta funcion
            --     function greet(name: string, age: number) { ... }
            -- y la llamas asi
            --     greet("Alice", 30)
            -- Con inlay hints ves:
            --     greet(name: "Alice", age: 30)
            --            ^              ^
            --            gris           gris
            --            (no están realmente en el archivo)


            typescript = {
               inlayHints = {
                  includeInlayParameterNameHints = "literals",
                  includeInlayFunctionParameterTypeHints = true,
                  includeInlayVariableTypeHints = false,
               },
            },
            javascript = {
               inlayHints = {
                  includeInlayParameterNameHints = "literals",
                  includeInlayFunctionParameterTypeHints = true,
               },
            },
         },
      },
   },
   {
      "html",
      lsp = {
         filetypes = { "html" },
         settings = {
            html = {
               format = {
                  enable = false, -- preferimos prettier (en conform.lua)
               },
            },
         },
      },
   },
   {
      "cssls",
      lsp = {
         filetypes = { "css", "scss", "less" },
         settings = {
            css = { validate = true },
            scss = { validate = true },
            less = { validate = true },
         },
      },
   },
   {
      "gopls",
      lsp = {
         filetypes = { "go", "gomod", "gowork", "gotmpl" },
         settings = {
            gopls = {
               gofumpt = true, -- usar gofumpt (más estricto que gofmt)
               usePlaceholders = true, -- placeholder snippets en autocompletado
               staticcheck = true, -- correr staticcheck via gopls
               analyses = {
                  unusedparams = true,
                  shadow = true,
               },
            },
         },
      },
   },
}
