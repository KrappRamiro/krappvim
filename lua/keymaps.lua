-- Keymaps for better default experience
-- snacks keymaps are NOT here
-- See `:help vim.keymap.set()`

-- Moverse entre ventanas (<C-h/j/k/l>), redimensionar (<A-h/j/k/l>) e
-- intercambiar buffers (<A-S-h/j/k/l>): todo eso vive en
-- lze_specs/smart_splits.lua.

-- Moving lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })

-- Better scrolling: media página y después `zz` para dejar el cursor centrado.
-- Funciona porque no hay smooth scroll (snacks.scroll está apagado, ver
-- lze_specs/snacks.lua): el salto es instantáneo y `zz` no compite con nada.
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll Down" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll Up" })

--  Better search results
vim.keymap.set("n", "n", "nzzzv", { desc = "Next Search Result" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Previous Search Result" })

-- Move between buffer
vim.keymap.set("n", "<leader><leader>[", "<cmd>bprev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<leader><leader>]", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader><leader>l", "<cmd>b#<CR>", { desc = "Last buffer" })
vim.keymap.set("n", "<leader><leader>d", "<cmd>bdelete<CR>", { desc = "delete buffer" })

-- Comentar/descomentar con Ctrl+/ (como en VS Code). Por dentro usa el `gc`
-- nativo de Neovim, por eso remap = true (gc y gcc son mappings, no comandos).
-- Se mapea también <C-_> porque varias terminales mandan ese código para
-- Ctrl+/ cuando no usan el protocolo de teclado de kitty.
for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
   -- normal: la línea actual (con count, `3<C-/>` comenta 3 líneas)
   vim.keymap.set("n", lhs, "gcc", { remap = true, desc = "Toggle comment line" })
   -- visual: las líneas seleccionadas, y `gv` vuelve a seleccionarlas
   vim.keymap.set("x", lhs, "gcgv", { remap = true, desc = "Toggle comment selection" })
   -- insert: la línea actual sin salir de insert mode
   vim.keymap.set("i", lhs, "<C-o>gcc", { remap = true, desc = "Toggle comment line" })
end

-- Remap for dealing with word wrap
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set(
   "n",
   "<leader>e",
   vim.diagnostic.open_float,
   { desc = "Open floating diagnostic message" }
)
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- Interaction with system clipboard
vim.keymap.set(
   { "v", "x", "n" },
   "<leader>y",
   '"+y',
   { noremap = true, silent = true, desc = "Yank to clipboard" }
)
vim.keymap.set(
   { "n", "v", "x" },
   "<leader>Y",
   '"+yy',
   { noremap = true, silent = true, desc = "Yank line to clipboard" }
)
vim.keymap.set(
   { "n", "v", "x" },
   "<leader>p",
   '"+p',
   { noremap = true, silent = true, desc = "Paste from clipboard" }
)
vim.keymap.set(
   "i",
   "<C-p>",
   "<C-r><C-p>+",
   { noremap = true, silent = true, desc = "Paste from clipboard from within insert mode" }
)
vim.keymap.set(
   "x",
   "<leader>P",
   '"_dP',
   { noremap = true, silent = true, desc = "Paste over selection without erasing unnamed register" }
)
