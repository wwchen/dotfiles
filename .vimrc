"
" William Chen's .vimrc
"
" Some good articles to read:
"  - http://mislav.uniqpath.com/2011/12/vim-revisited/
"  - https://github.com/eric-wood/dotfiles/blob/master/.vimrc
"

syntax on
set encoding=utf-8
set showcmd                     " display incomplete commands
filetype plugin indent on       " load file type plugins + indentation
colorscheme elflord "desert busybee
set cursorline

set laststatus=2
let g:smartusline_hi_normal = 'guifg=#CCCCCC guibg=#202020 ctermfg=white ctermbg=darkgray'


"" Whitespace
set nowrap
set tabstop=2 shiftwidth=2
set expandtab
set backspace=indent,eol,start  " backspace through everything in insert mode

"" Searching
set showmatch                   " Show parentheses matching
set smartcase
set ignorecase                  " searches are case insensitive...
set ic                          " ... unless they contain at least one capital letter

"" Indenting
set autoindent
set cindent
set number

"" Quick shortcuts
nmap <silent> <leader>i :IndentGuidesToggle<CR>
nmap <leader>o :FufCoverageFile<CR>
nmap <silent> <leader>r :FufRenewCache<CR>
nmap <silent> <leader>p :NERDTreeToggle<CR>
nmap <silent> <leader>b :BundleInstall<CR>
nmap <silent> <leader>B :BundleInstall!<CR>
nmap <silent> <leader>v :set pastetoggle<CR>
nmap <silent> <leader>s :setlocal spell! spelllang=en_us<CR>
nmap <silent> <leader>ev :e ~/.vimrc<CR>
nmap <silent> <leader>sv :source ~/.vimrc<CR>

"
set nobackup
set nowritebackup


"let g:tex_flavor='latex'
"if &ft == "tex"
  " Render the current LaTeX file and open the resulting PDF
"  setlocal spell! spelllang=en_us
  nmap <silent> <leader>w :w !pdflatex '%:p' && pdflatex '%:p' && pdflatex '%:p' && rm '%:p:r.log' && rm '%:p:r.aux'<CR><CR>
au BufWinEnter *.txt,*.tex set spell  " temporary hack
"endif


"""
" vundle stuff
" To get started, clone the repo: git clone http://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
"""
filetype off                   " required!
set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

Bundle 'gmarik/vundle'
Bundle 'nathanaelkane/vim-indent-guides'
Bundle 'scrooloose/nerdtree'
Bundle 'vim-ruby/vim-ruby'
Bundle 'L9'
Bundle 'FuzzyFinder'
Bundle 'vim-scripts/haskell.vim'
Bundle 'hail2u/vim-css3-syntax'
Bundle 'tpope/vim-markdown'
Bundle 'mikewest/vimroom'
"Bundle 'kien/ctrlp.vim'
"http://github.com/kien/ctrlp.vim/zipball/master

filetype plugin indent on      " required! 







"""
" my stuff
"""

"map <C-j> <C-w>j<C-w>_
"map <C-k> <C-w>k<C-w>_

"set statusline=%{fugitive#statusline()}

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



"""
" Tips
"""

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
