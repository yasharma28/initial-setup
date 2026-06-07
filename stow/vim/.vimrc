" == .vimrc — portable fallback ==
" Neovim is the daily editor; this exists for bare servers where only plain vim
" is available. Deliberately dependency-free (no plugin manager, no plugins) so
" it works on a fresh box with nothing installed. Keep it that way.

set nocompatible
filetype plugin indent on
syntax on

" --- UI ---
set number relativenumber
set cursorline
set scrolloff=8
set showcmd
set laststatus=2
set wildmenu
set wildmode=list:longest

" --- Search ---
set incsearch
set hlsearch
set ignorecase
set smartcase          " case-sensitive only when the query has a capital

" --- Indentation (4 spaces; 2 for web/markup) ---
set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
autocmd FileType html,css,yaml,json setlocal tabstop=2 shiftwidth=2

" --- Files ---
set nobackup nowritebackup noswapfile
set undofile
set undodir=~/.vim/undodir   " shared with nvim
if !isdirectory($HOME . '/.vim/undodir') | call mkdir($HOME . '/.vim/undodir', 'p') | endif
set modelines=0              " ignore in-file modelines (CVE-class footgun)

" --- Keymaps ---
let mapleader = " "
inoremap jj <Esc>
" Center the screen after search jumps
nnoremap n nzz
nnoremap N Nzz
" Move between splits without the <C-w> prefix
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
