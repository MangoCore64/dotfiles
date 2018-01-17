set nocompatible

so ~/.vim/plugins.vim
syntax enable

" Make backspace behave like every other editor.
set backspace=indent,eol,start

" The default is \, but I like to use a comma.
let mapleader = ','

" Activate line numbers.
set number relativenumber

" Activate OmniCompletion
set omnifunc=syntaxcomplete#Complete

let NERDTreeHijackNetrw = 0

set encoding=utf-8
set fileencoding=utf-8
set termencoding=utf-8
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set noshowmode
set ruler
set wildmenu
set wildmode=longest:full,full
set confirm
set cursorline
set fdm=marker
set laststatus=2
set statusline=%4*%<\%m%<[%f\%r%h%w]\ [%{&ff},%{&fileencoding},%Y]%=\[Position=%l,%v,%p%%]

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

nmap <silent> <F11> :tabprev<cr>
nmap <silent> <F12> :tabnext<cr>

"-------------Visuals--------------"
" set t_Co=256   " This is may or may not needed.
" set background=dark
colorscheme PaperColor
set background=dark
" set termguicolors
" colorscheme quantum
" let g:quantum_black=1
" let g:quantum_italics=1
" let g:airline_theme='quantum'
" set termguicolors     " enable true colors support
" let ayucolor="light"  " for light version of theme
" let ayucolor="mirage" " for mirage version of theme
" let ayucolor="dark"   " for dark version of theme
" colorscheme ayu

set guioptions-=l
set guioptions-=L
set guioptions-=r
set guioptions-=R

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

"Make it easy to edit the Vimrc file.
nmap <Leader>ev :tabedit $MYVIMRC<cr>

"Add simple highlight removal.
nmap <Leader><space> :nohlsearch<cr>

"Make NERDTree easier to toggle
nmap <Leader>e :NERDTreeToggle<cr>

" nmap <c-R> :CtrlPBufTag<cr>
" nmap <Leader>r :CtrlPMRUFiles<cr>
" nmap <c-P> :FZF $HOME<cr>

"-------------Plugins--------------"
"/
"/ Tagbar
"/
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
"/ easy-align
"/
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)


"/
"/ CtrlP
"/
let g:ctrlp_custom_ignore = 'node_modules\DS_Store\'
let g:ctrlp_match_window = 'order:ttb,min:1,max:30,results:30'

"/
"/ ALE
"/
" Enable completion where available.
" let g:airline#extensions#ale#enabled = 1
" let g:ale_fix_on_save = 1
" nmap <silent> <c-x> <Plug>(ale_previous_wrap)
" nmap <silent> <C-j> <Plug>(ale_next_wrap)

"/
"/ vim-syntastic
"/
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

" let g:syntastic_debug=3
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_php_checkers = ['php', 'phpcs', 'phpmd']
let g:syntastic_perl_checkers = ['perl']
let g:syntastic_enable_perl_checker = 1
"/
"/ vim-gitgutter
"/
let g:gitgutter_highlight_lines = 1

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
let g:airline#extensions#ale#enabled = 1
let g:airline_powerline_fonts = 1
"/
"/ Ack
"/
" let g:ackprg = 'ack --vimgrep --smart-case'
" cnoreabbrev ag Ack
" cnoreabbrev aG Ack
" cnoreabbrev Ag Ack
" cnoreabbrev AG Ack

"/
"/ AG
"/
let g:ackprg = 'ag --vimgrep'

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
" let g:SuperTabDefaultCompletionType = "<C-X><C-O>"
" let g:SuperTabDefaultCompletionType = "<c-n>"
" let g:SuperTabContextDefaultCompletionType = "<c-n>"
" let g:SuperTabDefaultCompletionType = "context"

"-------------Auto-Commands--------------"

"Automatically source the Vimrc file on save.
augroup autosourcing
  autocmd!
  autocmd BufWritePost .vimrc source %
augroup END

highlight WhitespaceEOL ctermbg=red guibg=red
match WhitespaceEOL /\s\+$/
