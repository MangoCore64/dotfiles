vim.g.mapleader = " "

local keymap = vim.keymap -- for conciseness

-- remap jk key to <ESC>
keymap.set("i", "jk", "<ESC>", { desc = "Escape insert mode with jk" })

keymap.set("n", "<leader>ch", ":nohl<CR>", { desc = "Clear search highlight" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

-- split window
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make split windows equal width & height" })
keymap.set("n", "<leader>sx", ":close<CR>", { desc = "Close current split window" })

-- move window
keymap.set("n", "<leader>h", "<C-w>h", { desc = "Move to left window" })
keymap.set("n", "<leader>l", "<C-w>l", { desc = "Move to right window" })
keymap.set("n", "<leader>k", "<C-w>k", { desc = "Move to up window" })
keymap.set("n", "<leader>j", "<C-w>j", { desc = "Move to down window" })





-- plugin custom setting --
-- vim-bufterline
-- quick bnext and bprev 、bclose with space n & p & c
keymap.set("n", "<leader>n", ":bn<CR>", { desc = "Next buffer" })
keymap.set("n", "<leader>p", ":bp<CR>", { desc = "Previous buffer" })
keymap.set("n", "<leader>x", ":bd<CR>", { desc = "Close buffer" })

