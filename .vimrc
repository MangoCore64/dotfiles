"----------Plugin----------"
" Specify a directory for plugins
" Avoid using standard Vim directory names like 'plugin'
" 注意：所有插件已鎖定穩定版本以確保相容性和安全性
call plug#begin('~/.vim/plugged')
    " 延遲載入 ALE，僅在編輯時載入
    Plug 'dense-analysis/ale', { 'on': [], 'tag': 'v4.0.0' }
    " GitGutter 保持原樣但會調整更新頻率
    Plug 'airblade/vim-gitgutter'
    " File search and fuzzy finder
    Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim', { 'tag': '1.7.0' }

    " Theme
    Plug 'NLKNguyen/papercolor-theme', { 'tag': 'v1.0' }
    " Statusline
    Plug 'itchyny/lightline.vim'

    " Editing plugins
    Plug 'tpope/vim-surround', { 'tag': 'v2.2' }
    Plug 'terryma/vim-multiple-cursors', { 'tag': 'v2.2' }
    Plug 'ervandew/supertab', { 'tag': '3.0.0' }
    Plug 'ap/vim-buftabline', { 'tag': 'v1.2' }

    Plug 'Exafunction/codeium.vim', { 'branch': 'main' }
    Plug 'pasky/claude.vim', { 'commit': '62e5c6f' }
" Initialize plugin system
call plug#end()
"----------Plugin End----------"

"----------Basic Seting----------"
" Security enhancements
set nomodeline
set modelines=0
set viminfo='100,<50,s10,h,f1

" Performance optimizations
set synmaxcol=200
set lazyredraw
set ttyfast
" Make backspace behave like every other editor.
set backspace=indent,eol,start

" The default is \, but I like to use a comma.
let mapleader = ','

" Activate line numbers.
set number relativenumber

" Activate OmniCompletion
set omnifunc=syntaxcomplete#Complete

let NERDTreeHijackNetrw = 0
autocmd BufRead,BufNewFile *tmux.conf set filetype=tmux-conf
set encoding=utf-8
set fileencoding=utf-8
set termencoding=utf-8
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set ruler
set wildmenu
set wildmode=longest:full,full
set confirm
set cursorline
set laststatus=2
set statusline=%4*%<\%m%<[%f\%r%h%w]\ [%{&ff},%{&fileencoding},%Y]%=\[Position=%l,%v,%p%%]
set noshowmode
set pastetoggle=<F9>
" set nowrap
set clipboard=unnamedplus
" set foldmethod=indent
set foldmethod=manual
set foldnestmax=2

if !&scrolloff
    set scrolloff=1
endif
if !&sidescrolloff
    set sidescrolloff=5
endif
if &history < 1000
    set history=1000
endif
set autoread

" enable mouse in the console
set mouse=a

" Use space to replace tab
set expandtab

" Disable scanning of all included files
set complete-=i

" Set fileencodings
set fileencodings=ucs-bom,utf-8,gbk,big5


"-------------Visuals--------------"
set background=dark
colorscheme PaperColor

highlight Normal guibg=NONE ctermbg=NONE
highlight SignColumn guibg=NONE ctermbg=NONE
set signcolumn="no"

if !has('gui_running')
    set t_Co=256
endif

set guioptions-=l
set guioptions-=L
set guioptions-=r
set guioptions-=R

" 設定成對括號的顏色
hi MatchParen cterm=bold ctermbg=yellow ctermfg=black

"-------------Search--------------"
" Highlight all matched terms.
set hlsearch

" Incrementally highlight, as we type.
set incsearch

"-------------Split Management--------------"
" Make splits default to below
set splitbelow

" And to the right. This feels more natural.
set splitright

set hidden

" mapping of code folding
nnoremap <space> za
vnoremap <space> zf

"Set simpler mappings to switch between splits.
" nmap <C-J> <C-W><C-J>
" nmap <C-K> <C-W><C-K>
" nmap <C-H> <C-W><C-H>
" nmap <C-L> <C-W><C-L>

"-------------Mappings--------------"
"-------------Normal Mode-----------"
" Buffer List move
nnoremap <silent>[b :bprevious<CR>
nnoremap <silent>]b :bnext<CR>
nnoremap <silent>[B :bfirst<CR>
nnoremap <silent>]B :blast<CR>

" Uppercase current word
nnoremap <c-u> viwU
" Remove trailing space
nnoremap <leader>t :%s/\s\+$//e<cr>
" Make it easy to edit the vimrc and source file.
nnoremap <Leader>ev :vsplit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC<cr>
" Add simple highlight removal.
nnoremap <Leader><space> :nohlsearch<cr>
" Make NERDTree easier to toggle
" nnoremap <Leader>e :NERDTreeToggle<cr>
" Go to the beginning and end of the current line
nnoremap H ^
nnoremap L $
" Go to next or previous buffer
noremap <silent> <space>p :bprev<cr>
noremap <silent> <space>n :bnext<cr>
"-------------Visual Mode-----------"
" Wrap selected text with double quotes/single quotes
vnoremap " s""<esc>`<pl
vnoremap ' s''<esc>`<pl
" Back to normal mode
vnoremap jk <ESC>
vnoremap <ESC> <C-c>
"-------------Insert Mode-----------"
" Delete current line
inoremap <c-d> <esc>ddi
" Uppercase current word
inoremap <c-u> <esc>viwU<esc>i
" Back to normal mode
inoremap jk <ESC>
" Disable arrow keys
inoremap <UP> <nop>
inoremap <DOWN> <nop>
inoremap <RIGHT> <nop>
inoremap <LEFT> <nop>

" nmap <c-R> :CtrlPBufTag<cr>
" nmap <Leader>r :CtrlPMRUFiles<cr>
" nmap <c-P> :FZF $HOME<cr>

"-------------Plugins--------------"
"/
"/ Tagbar
"/
"let g:tagbar_ctags_bin = '/bin/ctags'
"nmap <F8> :TagbarToggle<CR>
"let g:tagbar_type_css = {
"\ 'ctagstype' : 'Css',
"    \ 'kinds'     : [
"        \ 'c:classes',
"        \ 's:selectors',
"        \ 'i:identities'
"    \]
"\}


"/
"/ CtrlP
"/
let g:ctrlp_custom_ignore = 'node_modules\DS_Store\'
let g:ctrlp_match_window = 'order:ttb,min:1,max:30,results:30'

"/
"/ ALE
"/
" ALE 延遲載入設定
augroup load_ale_plugin
    autocmd!
    autocmd InsertEnter * call plug#load('ale') | autocmd! load_ale_plugin
augroup END

" 啟用或禁用 ALE
let g:ale_enabled = 1
" 設置檢查器運行的頻率
let g:ale_lint_delay = 500
let g:ale_sign_column_always = 1

let g:ale_echo_msg_error_str = 'Error'
let g:ale_echo_msg_warning_str = 'Warning'
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'

let g:ale_sign_error = '✘'
let g:ale_sign_warning = '⚠'
" 啟用自動修復功能
let g:ale_fix_on_save = 1
" 設置可用的修復器
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint'],
\   'perl': ['perltidy'],
\   'php': ['php_cs_fixer'],
\}
" 啟用檢查器和修復器的提示信息
let g:ale_hover_cursor = 1
highlight ALEErrorSign ctermbg=NONE ctermfg=red
highlight ALEWarningSign ctermbg=NONE ctermfg=yellow

"/ vim-gitgutter
"/
" GitGutter 性能優化
let g:gitgutter_realtime = 0
let g:gitgutter_eager = 0
let g:gitgutter_update_delay = 1000
let g:gitgutter_max_signs = 500

highlight GitGutterAdd ctermbg=NONE ctermfg=green
highlight GitGutterChange ctermbg=NONE ctermfg=yellow
highlight GitGutterDelete ctermbg=NONE ctermfg=red
highlight GitGutterChangeDelete ctermbg=NONE ctermfg=yellow
"/
"/
"/ Nerdcommenter
"/
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code
" indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_perl = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a
" region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

"/
"/ Ack
"/
"if executable('ag')
"    let g:ackprg = 'ag --vimgrep --smart-case'
"endif
"cnoreabbrev ag Ack
"cnoreabbrev aG Ack
"cnoreabbrev Ag Ack
"noreabbrev AG Ack

cnoreabbrev Ack Ack!
nnoremap <Leader>a :Ack!<Space>
"/
"/ vim-indent-guides
"/
" visually displaying indent levels
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

"/
"/ Greplace
"/
set grepprg=ack
let g:grep_cmd_opts = '--noheading'

"/
"/ SuperTab
"/
let g:SuperTabDefaultCompletionType = "context"
let g:SuperTabContextDefaultCompletionType = "<c-n>"

"/
"/ lightline
"/
let g:lightline = {
    \ 'active': {
    \   'left': [
	\		[ 'mode', 'paste' ],
    \       [ 'readonly', 'filename' ]
    \   ],
    \ },
    \ 'component_function': {
    \   'filename': 'LightlineFilename',
    \ },
    \ 'subseparator': { 'left': '|', 'right': '|'  },
    \ }

function! LightlineFilename()
    let filename = expand('%:t') !=# '' ? expand('%:t') : '[No Name]'
    let modified = &modified ? ' +' : ''
    return filename . modified
endfunction


"/
"/ vim-sneak
"/
let g:sneak#label = 1
map f <Plug>Sneak_s
map F <Plug>Sneak_S

"/
"/ vim-lion
"/
let b:lion_squeeze_spaces = 1

"-------------Auto-Commands--------------"
"Automatically source the Vimrc file on save.
augroup autosourcing
  autocmd!
  autocmd BufWritePost .vimrc source %
augroup END

highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/


" 解決tmux.conf的syntax highlight失效的問題
au BufRead,BufNewFile .tmux.conf set filetype=tmux
" Auto remove trailing whitespace
" 先註解掉這功能，避免diff時不好找差異
" autocmd BufWritePre * :%s/\s\+$//e



" nmap zuz <Plug>(FastFoldUpdate)
" let g:fastfold_savehook = 1
" let g:fastfold_fold_command_suffixes =  ['x','X','a','A','o','O','c','C']
" let g:fastfold_fold_movement_commands = [']z', '[z', 'zj', 'zk']
"
" let g:markdown_folding = 1
" let g:tex_fold_enabled = 1
" let g:vimsyn_folding = 'af'
" let g:xml_syntax_folding = 1
" let g:javaScript_fold = 1
" let g:sh_fold_enabled= 7
" let g:ruby_fold = 1
" let g:perl_fold = 1
" let g:perl_fold_blocks = 1
" let g:r_syntax_folding = 1
" let g:rust_fold = 1
" let g:php_folding = 1
