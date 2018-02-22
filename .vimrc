"----------Plugin----------"
" Specify a directory for plugins
" Avoid using standard Vim directory names like 'plugin'
call plug#begin('~/.vim/plugged')
    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
    Plug 'kien/ctrlp.vim', { 'on': 'NERDTreeToggle' }

    " Plug 'junegunn/fzf.vim'
    Plug 'scrooloose/nerdcommenter'
    Plug 'itchyny/lightline.vim'
    " Plug 'vim-airline/vim-airline'
    " Plug 'vim-airline/vim-airline-themes'
    " Plug 'vim-syntastic/syntastic'
    Plug 'mileszs/ack.vim'
    " Plug 'skwp/greplace.vim'
    Plug 'tpope/vim-surround'
    Plug 'tpope/vim-fugitive'
    Plug 'terryma/vim-multiple-cursors'
    Plug 'airblade/vim-gitgutter'
    " Plug 'w0rp/ale'
    Plug 'ervandew/supertab'
    " Plug 'ajh17/VimCompletesMe'
    Plug 'c9s/perlomni.vim', { 'for': 'perl' }
    Plug 'NLKNguyen/papercolor-theme'
    " Plug 'jiangmiao/auto-pairs'
    Plug 'majutsushi/tagbar'
    Plug 'nathanaelkane/vim-indent-guides'
    Plug 'christoomey/vim-tmux-navigator'
    " Plug 'vim-perl/vim-perl', { 'for': 'perl', 'do': 'make clean carp dancer highlight-all-pragmas moose test-more try-tiny'  }
    Plug 'jeffkreeftmeijer/vim-numbertoggle'
    Plug 'joshdick/onedark.vim'
    Plug 'sheerun/vim-polyglot'
    Plug 'morhetz/gruvbox'
    Plug 'kshenoy/vim-signature'

" Initialize plugin system
call plug#end()
"----------Plugin End----------"


"----------Basic Seting----------"
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
set foldmethod=marker
set laststatus=2
set statusline=%4*%<\%m%<[%f\%r%h%w]\ [%{&ff},%{&fileencoding},%Y]%=\[Position=%l,%v,%p%%]
set noshowmode
set pastetoggle=<F9>

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
" set t_Co=256   " This is may or may not needed.
set background=dark
" colorscheme PaperColor
let g:gruvbox_contrast_dark = "hard"
colorscheme gruvbox


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

"Set simpler mappings to switch between splits.
nmap <C-J> <C-W><C-J>
nmap <C-K> <C-W><C-K>
nmap <C-H> <C-W><C-H>
nmap <C-L> <C-W><C-L>

"-------------Mappings--------------"
"-------------Normal Mode-----------"
"
nnoremap <F5> :!perl -c %
nnoremap <F6> :!php -l %
" Uppercase current word
nnoremap <c-u> viwU
" Make it easy to edit the vimrc and source file.
nnoremap <Leader>ev :vsplit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC<cr>
" Add simple highlight removal.
nnoremap <Leader><space> :nohlsearch<cr>
" Make NERDTree easier to toggle
nnoremap <Leader>e :NERDTreeToggle<cr>
" Go to the beginning and end of the current line
nnoremap H ^
nnoremap L $
" Go to next or previous tab
noremap <silent> <space>p :tabprev<cr>
noremap <silent> <space>n :tabnext<cr>
"-------------Visual Mode-----------"
" Wrap selected text with double quotes/single quotes
vnoremap " s""<esc>`<pl
vnoremap ' s''<esc>`<pl

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
let g:tagbar_ctags_bin = '$HOME/bin/ctags'
nmap <F8> :TagbarToggle<CR>
let g:tagbar_type_css = {
\ 'ctagstype' : 'Css',
    \ 'kinds'     : [
        \ 'c:classes',
        \ 's:selectors',
        \ 'i:identities'
    \]
\}


"/
"/ CtrlP
"/
let g:ctrlp_custom_ignore = 'node_modules\DS_Store\'
let g:ctrlp_match_window = 'order:ttb,min:1,max:30,results:30'

"/
"/ ALE
"/
" Set this. Airline will handle the rest."
" let g:airline#extensions#ale#enabled = 1
" " navigate between errors quickly
" nmap <silent> <Space>j <Plug>(ale_previous_wrap)
" nmap <silent> <Space>k <Plug>(ale_next_wrap)

" let g:ale_echo_msg_error_str = 'E'
" let g:ale_echo_msg_warning_str = 'W'
" let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
"
" let g:ale_set_loclist = 0
" let g:ale_set_quickfix = 1
"
" let g:ale_open_list = 1

" let g:ale_lint_on_text_changed = 'never'
" Don't run linters on opening a file
" let g:ale_lint_on_enter = 0
"
" let g:ale_fixers = {
" \    'php': ['php -l'],
" \    'perl': ['perl -c'],
" \}

" let g:ale_fix_on_save = 1
"/
"/ vim-syntastic
"/
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*

" let g:syntastic_debug=3
" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 1
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
" " let g:syntastic_php_checkers = ['php', 'phpcs', 'phpmd']
" let g:syntastic_mode_map = { 'passive_filetypes': ['php']  }
" let g:syntastic_perl_checkers = ['perl']
" let g:syntastic_enable_perl_checker = 1
"/
"/ vim-gitgutter
"/
" let g:gitgutter_highlight_lines = 1
let g:gitgutter_realtime = 0
let g:gitgutter_eager = 0

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
"/ Airline
"/
" Set this. Airline will handle the rest.
let g:airline_powerline_fonts = 1
"/
"/ Ack
"/
if executable('ag')
    let g:ackprg = 'ag --vimgrep --smart-case'
endif
cnoreabbrev ag Ack
cnoreabbrev aG Ack
cnoreabbrev Ag Ack
noreabbrev AG Ack

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
let g:SuperTabDefaultCompletionType = "<C-X><C-O>"
let g:SuperTabDefaultCompletionType = "<c-n>"
let g:SuperTabContextDefaultCompletionType = "<c-n>"
let g:SuperTabDefaultCompletionType = "context"

"/
"/ lightline
"/
let g:lightline = {
    \ 'active': {
    \   'left': [
	\		[ 'mode', 'paste' ],
    \       [ 'gitbranch', 'readonly', 'filename', 'modified' ]
    \   ],
    \ },
    \ 'component_function': {
    \   'gitbranch': 'fugitive#head'
    \ },
    \ 'subseparator': { 'left': '⮁', 'right': '⮃'  },
    \ }


"-------------Auto-Commands--------------"
"Automatically source the Vimrc file on save.
augroup autosourcing
  autocmd!
  autocmd BufWritePost .vimrc source %
augroup END

highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/

" Auto remove trailing whitespace
" 先註解掉這功能，避免diff時不好找差異
" autocmd BufWritePre * :%s/\s\+$//e
