-- Keymaps for better default experience
-- snacks keymaps are NOT here
-- See `:help vim.keymap.set()`

-- Moving between windoes
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Moving lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Moves Line Down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Moves Line Up" })

-- Better scrolling
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
