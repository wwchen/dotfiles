"
" William Chen's .vimrc
"
" Some good articles to read:
"  - http://mislav.uniqpath.com/2011/12/vim-revisited/
"  - https://github.com/eric-wood/dotfiles/blob/master/.vimrc
"

set nocompatible                " not Vi-compatible
set nolist

"" Display
set encoding=utf-8
set number                      " show line number
set linebreak
set showcmd                     " display incomplete commands
set textwidth=0
set wrapmargin=0

colorscheme elflord "desert busybee

"" Code
syntax on
filetype plugin indent on       " load file type plugins + indentation
set cursorline

"" Spacing and Indentation
set autoindent
set expandtab
set tabstop=2
set shiftwidth=2
"set backspace=indent,eol,start  " backspace through everything in insert mode

"" Searching
set showmatch                   " Show parentheses matching
set smartcase
set ignorecase                  " searches are case insensitive...
set ic                          " ... unless they contain at least one capital letter
set incsearch                   " matched string is highlighted
set hlsearch                    " hilight search

"" Bottom menubar
set ruler                       " show row,col in statusbar
set wildmenu                    " tab completion with possible matches shown above
set laststatus=2
let g:smartusline_hi_normal = 'guifg=#CCCCCC guibg=#202020 ctermfg=white ctermbg=darkgray'


"====================================
" <leader> keystrokes and remappings
"====================================
nmap <silent> <leader>i :IndentGuidesToggle<CR>
nmap <silent> <leader>p :NERDTreeToggle<CR>          " nerd tree
nmap <leader>o :FufCoverageFile<CR>                  " fuzzy search
nmap <silent> <leader>r :FufRenewCache<CR>
nmap <silent> <leader>b :BundleInstall<CR>           " vundle
nmap <silent> <leader>B :BundleInstall!<CR>          " vundle
nmap <silent> <leader>v :set pastetoggle<CR>
nmap <silent> <leader>s :setlocal spell! spelllang=en_us<CR>
nmap <silent> <leader>ev :e ~/.vimrc<CR>
nmap <silent> <leader>sv :source ~/.vimrc<CR>

"====================================
" Vundle
"====================================
" These need to be set up first, otherwise settings that
" refer to certain plugins aren't loaded and we get errors
" To get started, execute: git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim && vim +PluginInstall +qall

set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'L9'
Bundle 'FuzzyFinder'
Bundle 'nathanaelkane/vim-indent-guides'
Bundle 'scrooloose/nerdtree'
Bundle 'tpope/vim-rails'
"Bundle 'tpope/vim-markdown'
"Bundle 'mikewest/vimroom'
Bundle 'vim-ruby/vim-ruby'
Bundle 'tomasr/molokai'
"Bundle 'ChrisYip/Better-CSS-Syntax-for-Vim'
"Bundle 'kien/ctrlp.vim'
"Bundle 'Lokaltog/vim-powerline'
"Bundle 'pangloss/vim-javascript'
"Bundle 'cakebaker/scss-syntax.vim'

call vundle#end()            " required
filetype plugin indent on    " required
" To ignore plugin indent changes, instead use:
"filetype plugin on
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
"====================================



"====================================
" Other unused neat stuff
"====================================

"map <C-j> <C-w>j<C-w>_
"map <C-k> <C-w>k<C-w>_

"au FileType tex map <buffer> <F7> :w<CR>:!pdflatex %<CR>
"au FileType c   map <buffer> <F7> :make<CR>
"au FileType cpp map <buffer> <F7> :w<CR>:!g++ -g -Wall %<CR>
"map <F7> :w<CR>:!g++ -g -Wall %<CR>


" Highlight long lines
" ref: http://vim.wikia.com/wiki/VimTip812
"au BufWinEnter *.c,*.cpp,*.h let w:m1=matchadd('Search', '\%<101v.\%>92v', -1)
"au BufWinEnter *.c,*.cpp,*.h let w:m2=matchadd('ErrorMsg', '\%>100v.\+', -1)

"au BufWinEnter *.txt,*.tex set textwidth=100
"au BufWinEnter *.txt,*.tex set spell

" Vim folding
" ref: http://www.linux.com/archive/feature/114138
"au BufWinLeave * mkview
"au BufWinEnter * silent loadview



"====================================
" Tips
"====================================

"http://stackoverflow.com/questions/1269603/to-switch-from-vertical-split-to-horizontal-split-fast-in-vim
"To change two vertically split windows to horizonally split
"    ^Wt^WK
"Horizontally to vertically:
"    ^Wt^WH
"where ^W means "hit Ctrl-W". Explanations:
"
"    ^Wt     makes the first (topleft) window current
"    ^WK     moves the current window to full-width at the very top
"    ^WH     moves the current window to full-height at far left

" 
