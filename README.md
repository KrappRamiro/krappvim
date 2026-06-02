# krapp.vim

Personal Neovim configuration built with [nix-wrapper-modules](https://birdeehub.github.io/nix-wrapper-modules/wrapperModules/neovim.html).
Lazy-loaded via [lze](https://github.com/BirdeeHub/lze).

---

## Plugins

### Core

| Plugin | Function |
|--------|----------|
| [lze](https://github.com/BirdeeHub/lze) | Lazy-loading library |
| [lzextras](https://github.com/BirdeeHub/lzextras) | Extra handlers for lze (LSP handler, `on_require`, etc.) |
| [vim-sleuth](https://github.com/tpope/vim-sleuth) | Auto-detects `tabstop`/`shiftwidth` per file |
| [mini.nvim](https://github.com/echasnovski/mini.nvim) | Collection of 40+ small focused plugins  |

### UI

| Plugin | Function |
|--------|----------|
| [gruvbox.nvim](https://github.com/ellisonleao/gruvbox.nvim) | Colorscheme |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Statusline |
| [noice.nvim](https://github.com/folke/noice.nvim) | Replaces the default UI for messages, cmdline, and popupmenu with floats |
| [nui.nvim](https://github.com/MunifTanjim/nui.nvim) | UI component library (dependency of noice and others) |
| [dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim) | VS Code-style breadcrumb bar at the top of the window |
| [fidget.nvim](https://github.com/j-hui/fidget.nvim) | LSP progress notifications in the bottom-right corner |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Popup showing available keybindings as you type a prefix |
| [tiny-inline-diagnostic](https://github.com/rachartier/tiny-inline-diagnostic.nvim) | Pretty inline diagnostics rendered next to the offending line |
| [milli.nvim](https://github.com/Amansingh-afk/milli.nvim) | Animated ASCII splash screen for the snacks dashboard |

### Navigation & Search

| Plugin | Function |
|--------|----------|
| [snacks.nvim](https://github.com/folke/snacks.nvim) | Kitchen sink: fuzzy picker, file explorer, dashboard, terminal, lazygit, image viewer, scroll animation, git browse, LSP rename, and more |
| [flash.nvim](https://github.com/folke/flash.nvim) | Jump anywhere on screen with 1 or 2 key labels |
| [hop.nvim](https://github.com/smoka7/hop.nvim) | EasyMotion-style navigation |
| [grug-far.nvim](https://github.com/MagicDuck/grug-far.nvim) | Project-wide find & replace with live preview |

### Editing

| Plugin | Function |
|--------|----------|
| [nvim-surround](https://github.com/kylechui/nvim-surround) | Add, change, and delete surrounding pairs (`()`, `""`, tags, etc.) |
| [multicursor.nvim](https://github.com/jake-stewart/multicursor.nvim) | Multiple cursors — `Ctrl+D` to add next match, like VS Code |
| [ccc.nvim](https://github.com/uga-rosa/ccc.nvim) | Color picker and convertor (hex, rgb, hsl, etc.) |
| [nvim-colorizer.lua](https://github.com/catgoose/nvim-colorizer.lua) | Highlights color codes inline (`#FF0000` shows with a red background) |
| [hardtime.nvim](https://github.com/m4xshen/hardtime.nvim) | Corrects bad motion habits (hjkl spam, repeated arrows) |

### LSP & Completions

| Plugin | Function |
|--------|----------|
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Easy configuration for Neovim's built-in LSP client |
| [lazydev.nvim](https://github.com/folke/lazydev.nvim) | Improves Lua LSP for Neovim config files (loads correct type definitions) |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Fast completion engine |
| [colorful-menu.nvim](https://github.com/xzbdmw/colorful-menu.nvim) | Adds syntax-colored labels to completion menu items |
| [tiny-code-action](https://github.com/rachartier/tiny-code-action.nvim) | LSP code actions with a Snacks picker and delta diff preview |

### Formatting & Linting

| Plugin | Function |
|--------|----------|
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Formatter runner (prettier, stylua, ruff, nixfmt, rustfmt, etc.) |
| [nvim-lint](https://github.com/mfussenegger/nvim-lint) | Linter runner (selene, eslint_d, shellcheck, statix, etc.) |

### Treesitter

| Plugin | Function |
|--------|----------|
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax tree parsing — enables accurate highlighting, folding, and text objects |
| [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) | Treesitter-based text objects (`af` = around function, `ac` = around class, etc.) |

### Git

| Plugin | Function |
|--------|----------|
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git change indicators in the gutter, hunk navigation, blame, and staging |

### Markdown

| Plugin | Function |
|--------|----------|
| [markview.nvim](https://github.com/OXY2DEV/markview.nvim) | In-buffer markdown rendering (headings, tables, code blocks, checkboxes) with hybrid mode — raw under cursor, rendered everywhere else |

### Notes

| Plugin | Function |
|--------|----------|
| [mind.nvim](https://github.com/Selyss/mind.nvim) | Hierarchical tree-based note organizer — `<leader>nm` for main tree, `<leader>np` for project tree |

### Context & Annotations

| Plugin | Function |
|--------|----------|
| [lensline.nvim](https://github.com/lensline.nvim) | Displays contextual info above functions: LSP reference count, last git author |

### Debugging & Profiling

| Plugin | Function |
|--------|----------|
| [vim-startuptime](https://github.com/dstein64/vim-startuptime) | Benchmarks startup time, breaking it down per plugin |

---

## LSP Servers

Managed via `nvim-lspconfig`, binaries provided by Nix.

| Server | Languages |
|--------|-----------|
| `lua_ls` | Lua |
| `nixd` | Nix |
| `bashls` | Shell / Bash |
| `rust_analyzer` | Rust (with clippy) |
| `basedpyright` | Python |
| `terraformls` | Terraform / OpenTofu |
| `ts_ls` | JavaScript / TypeScript |
| `html` | HTML |
| `cssls` | CSS / SCSS / Less |
| `gopls` | Go |

---

## Building

```bash
nix build .
```

Run as `kvim`.
