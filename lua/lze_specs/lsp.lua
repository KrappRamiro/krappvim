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
-- (config.specs.general.runtimePkgs).
-- ────────────────────────────────────────────────────────────────────────

-- nixd: de dónde saca los paquetes y las opciones para completar.
-- Usamos el flake de nixos-config, así completa con el MISMO nixpkgs y las
-- MISMAS opciones que usa el sistema. Si el repo no está clonado en esta
-- máquina, nixd sigue andando con <nixpkgs> y sin completado de opciones.
-- Ver https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
local nixd_nixpkgs_expr = [[import <nixpkgs> { }]]
local nixd_options = {}
do
   local flake = vim.fs.normalize("~/nixos-config")
   if vim.uv.fs_stat(flake .. "/flake.nix") then
      local host = vim.uv.os_gethostname()
      nixd_nixpkgs_expr = ([[import (builtins.getFlake "%s").inputs.nixpkgs { }]]):format(flake)
      nixd_options = {
         -- en un host NixOS: las opciones de ese host (por hostname)
         nixos = {
            expr = ([[(builtins.getFlake "%s").nixosConfigurations."%s".options or { }]]):format(
               flake,
               host
            ),
         },
         -- home-manager integrado en NixOS expone sus opciones como submódulo
         -- de `home-manager.users`; en un host sin NixOS (ubuntu-gocloud)
         -- usamos homeConfigurations.krapp
         home_manager = {
            expr = ([[
               let
                 f = builtins.getFlake "%s";
                 host = f.nixosConfigurations."%s" or null;
               in
               if host != null
               then host.options.home-manager.users.type.getSubOptions [ ]
               else f.homeConfigurations.krapp.options
            ]]):format(flake, host),
         },
      }
   end
end

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
         -- blink.cmp, al cargarse, registra sus capabilities extra con
         -- vim.lsp.config("*", ...) (ver plugin/blink-cmp.lua en blink).
         -- Si un LSP arranca ANTES de que blink cargue (pasa al abrir un archivo
         -- directo con `kvim archivo`, porque blink carga en DeferredUIEnter),
         -- ese cliente se queda sin esas capabilities. Forzamos la carga acá,
         -- que corre antes de cualquier vim.lsp.enable().
         nixInfo.lze.trigger_load("blink.cmp")

         -- Inlay hints: anotaciones inline (nombres de params, tipos inferidos)
         -- que el LSP envía. Por default Neovim NO las muestra aunque el LSP
         -- las mande, hay que activarlas explícitamente.
         vim.lsp.inlay_hint.enable(true)

         -- Toggle global de inlay hints. Vive bajo <leader>t* (toggles).
         -- El group está declarado en which_key.lua.
         vim.keymap.set("n", "<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
         end, { desc = "Toggle inlay [H]ints" })

         vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(ev)
               local bufnr = ev.buf
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
               nmap("<leader>ca", function()
                  require("tiny-code-action").code_action()
               end, "[C]ode [A]ction")
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
      -- blink hace require("lazydev.integrations.blink") (ver completion.lua),
      -- con esto lze carga lazydev en ese momento en vez de tirar
      -- "module not found" si todavía no abriste un archivo Lua
      on_require = "lazydev",
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

   {
      -- catálogo de schemas para jsonls, yamlls y taplo (ver sus before_init).
      -- No tiene setup: solo hace falta que esté cargado cuando lo piden.
      "SchemaStore.nvim",
      auto_enable = true,
      on_require = "schemastore",
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
         -- Sin LD_LIBRARY_PATH: shells de devenv (ej. proyectos ESP32 Xtensa) la
         -- exportan con una libstdc++ vieja, que le gana al RUNPATH de nixd y lo
         -- crashea con "GLIBCXX_3.4.35 not found".
         cmd = { "env", "-u", "LD_LIBRARY_PATH", "nixd" },
         filetypes = { "nix" },
         settings = {
            nixd = {
               nixpkgs = {
                  expr = nixd_nixpkgs_expr,
               },
               -- completado y hover de opciones (`programs.git.enable`, etc),
               -- armado arriba de todo en este archivo
               options = nixd_options,
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
               -- ruff (LSP, más abajo) ya ordena imports, así no aparecen dos
               -- code actions de "organize imports". Ver docs de ruff para Neovim.
               disableOrganizeImports = true,
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
         init_options = {
            terraform = { path = vim.fn.exepath("tofu") },
         },
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
   {
      "yamlls",
      lsp = {
         filetypes = { "yaml" },
         -- Los schemas vienen de SchemaStore.nvim (catálogo empaquetado por nix,
         -- sin bajar nada de internet en cada arranque). Matchean por nombre de
         -- archivo: docker-compose.yml, .github/workflows/*.yml, etc.
         -- Se inyectan en before_init para no cargar el catálogo hasta que
         -- arranque el server. Mismo patrón que LazyVim (extras/lang/yaml.lua).
         before_init = function(_, config)
            config.settings.yaml.schemas = vim.tbl_deep_extend(
               "force",
               config.settings.yaml.schemas or {},
               require("schemastore").yaml.schemas()
            )
         end,
         settings = {
            yaml = {
               -- hay que apagar el schemaStore propio de yamlls para que no se
               -- pise con el de SchemaStore.nvim
               schemaStore = {
                  enable = false,
                  url = "",
               },
               validate = true,
               keyOrdering = false, -- no quejarse si las claves no están en orden alfabético
            },
            redhat = {
               telemetry = { enabled = false },
            },
         },
      },
   },
   {
      -- jsonls viene en vscode-langservers-extracted (ya instalado).
      -- Valida y autocompleta package.json, tsconfig.json, .eslintrc, etc.
      -- con los schemas de SchemaStore.nvim (mismo patrón que yamlls).
      "jsonls",
      lsp = {
         filetypes = { "json", "jsonc" },
         before_init = function(_, config)
            config.settings.json.schemas = config.settings.json.schemas or {}
            vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
         end,
         settings = {
            json = {
               validate = { enable = true },
            },
         },
      },
   },
   {
      -- taplo: LSP de TOML. Con los schemas de SchemaStore autocompleta las
      -- claves de Cargo.toml, pyproject.toml, rust-analyzer.toml, etc.
      -- Las versiones y features de crates las completa crates.nvim (crates.lua).
      "taplo",
      lsp = {
         filetypes = { "toml" },
         -- taplo por default baja el catálogo de SchemaStore.org, pero SchemaStore
         -- cambió el formato y taplo 0.9/0.10 ya no lo puede leer
         -- ("data did not match any variant of untagged enum SchemaCatalog",
         -- https://github.com/tamasfe/taplo/issues/799). Sin catálogo no hay
         -- schema para Cargo.toml y por eso solo completaba palabras del buffer.
         --
         -- Workaround: apagamos el catálogo y le pasamos las asociaciones
         -- archivo -> schema armadas desde SchemaStore.nvim (que nix ya empaqueta).
         -- taplo matchea con regex, así que traducimos los globs de `fileMatch`.
         before_init = function(_, config)
            ---@param glob string ej: "Cargo.toml", "**/.cargo/config.toml", "*.cv.toml"
            local function glob_to_regex(glob)
               local body = glob:gsub("^%*%*/", "")
               body = body:gsub("[%.%+%(%)%|%^%$%{%}%[%]\\%?]", "\\%0")
               body = body:gsub("%*%*/", "\0"):gsub("%*", "[^/]*"):gsub("%z", "(.*/)?")
               -- "/" adelante: matchea el nombre completo del archivo en cualquier carpeta
               return "/" .. body .. "$"
            end

            local associations = {}
            for _, schema in ipairs(require("schemastore").json.schemas()) do
               for _, glob in ipairs(schema.fileMatch or {}) do
                  if glob:match("%.toml$") then
                     associations[glob_to_regex(glob)] = schema.url
                  end
               end
            end

            config.settings.evenBetterToml =
               vim.tbl_deep_extend("force", config.settings.evenBetterToml or {}, {
                  schema = {
                     catalogs = {},
                     associations = associations,
                  },
               })
         end,
         settings = {
            -- "evenBetterToml" es la sección de config que lee taplo
            -- (nombre heredado de la extensión de VS Code)
            evenBetterToml = {},
         },
      },
   },
   {
      "dockerls",
      lsp = {
         filetypes = { "dockerfile" },
      },
   },
   {
      -- tinymist: LSP de Typst (completado, hover, preview, go to definition)
      -- El formateo lo sigue haciendo typstyle via conform.
      "tinymist",
      lsp = {
         filetypes = { "typst" },
      },
   },
   {
      -- marksman: links entre archivos markdown, headings, referencias.
      -- No pisa a markview (que solo renderiza).
      "marksman",
      lsp = {
         filetypes = { "markdown" },
      },
   },
   {
      -- ruff como LSP (reemplaza a ruff en nvim-lint): diagnostics mientras
      -- escribís, más code actions para arreglar lints y ordenar imports.
      -- basedpyright sigue haciendo tipos, hover y go to definition.
      "ruff",
      lsp = {
         filetypes = { "python" },
         on_attach = function(client, _)
            -- basedpyright da un hover mucho más completo, apagamos el de ruff.
            -- Sacado de https://docs.astral.sh/ruff/editors/setup/#neovim
            client.server_capabilities.hoverProvider = false
         end,
      },
   },
}
