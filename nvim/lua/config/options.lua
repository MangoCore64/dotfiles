vim.cmd("let g:netrw_liststyle = 3")
vim.cmd("let g:netrw_banner = 0") -- hide banner
vim.cmd("let g:netrw_browse_split = 4") -- <cr> on a bookmark opens in previous window
vim.cmd("let g:netrw_altv = 1") -- open splits to the right
vim.cmd("let g:netrw_winsize = 25") -- 25% width

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
-- 禁用 netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
