-- 確保標準資料目錄存在
local data_dir = vim.fn.stdpath("data") -- 預設為 ~/.local/share/nvim

-- 將 site 路徑加入 packpath
vim.opt.packpath:append(data_dir .. "/site")

local opt = vim.opt -- for conciseness
-- set hidden
opt.hidden = true

-- tabs & indentation
opt.tabstop = 4 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 4 -- 2 spaces for indent
opt.expandtab = true -- convert tabs to spaces
opt.autoindent = true -- indent a new line the same amount as the line just typed

opt.relativenumber = true -- set relative numbered lines
opt.number = true -- set numbered lines

opt.wrap = false -- disable line wrap

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, it will become case-sensitive

opt.cursorline = true -- highlight the current cursor line

-- turn on termguicolors
opt.termguicolors = true
opt.background = "dark" -- or "light" for light mode
opt.signcolumn = "yes" -- keep the sign column open

-- backspace
opt.backspace = "indent,eol,start" -- allow backspacing over everything in insert mode

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.cursorline = true -- highlight the current cursor line
