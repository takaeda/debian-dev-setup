call plug#begin(stdpath('data') . '/plugged')
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}
Plug 'sheerun/vim-polyglot'
Plug 'preservim/vim-markdown'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
Plug 'github/copilot.vim'
Plug 'preservim/nerdtree'
Plug 'Mofiqul/vscode.nvim'
Plug 'junegunn/gv.vim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
Plug 'pwntester/octo.nvim'
call plug#end()
lua << EOF
require"octo".setup()
EOF

" 基本設定
set number
set relativenumber
set expandtab
set tabstop=4
set shiftwidth=4
set smartindent
set clipboard+=unnamedplus
syntax on
filetype plugin indent on

" Disable compatibility with vi
set nocompatible

" General settings
set nobackup
set autoindent
set ul=0
set showmode
set report=1
set showmatch
set suffixes=.log,.aux,.dvi,.o,.bak,.swp

" Tab and indentation settings
set tabstop=4
set noexpandtab
set smartindent
set smarttab
set shiftwidth=4
set expandtab
set smarttab

" Interface settings
set wildmenu
set nowrapscan
set winheight=5
set history=50
set laststatus=1
set ruler
set incsearch
set modeline
set nobomb

" Key mappings
map <C-g> :buffers<CR>
map <C-k> :bdelete
map <C-x>o <C-w><C-w><C-w>_

" Insert mode mappings
inoremap <C-h> <BS>

" UTF-8 settings
set ambiwidth=double
set fileencoding=utf-8
set encoding=utf-8
set fileencodings=utf-8,euc-jp,japan,shift-jis,iso-2022-jp,cp932,utf-16,ucs-2-internal,ucs-2
set termencoding=utf-8

" Additional key mappings
map Q gq

" クリップボードとの統合
set clipboard+=unnamedplus

" 視覚モードでの選択領域をクリップボードにコピーするキーマッピング
vnoremap <C-c> "+y

" キーマッピング
nnoremap <C-n> :NERDTreeToggle<CR>
"nnoremap <C-p> :Files<CR>

" Coc.nvim の設定
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

syntax enable
set background=dark
colorscheme vscode
let g:vscode_style = "dark"
