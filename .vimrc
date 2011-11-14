"http://stackoverflow.com/questions/164847/what-is-in-your-vimrc
"https://github.com/shad/vim
"nore ; :
"nore , ;

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

syntax on
set tabstop=2
set shiftwidth=2
set expandtab
set autoindent
set cindent
"set pastetoggle=<C-p>         " go to Insert mode, <C-p>, and paste to retain indentation
set number
"set mouse=a
set mouse-=a
set comments=sl:/*,mb:*,elx:*/
"set hlsearch
set showmatch                 " Show parentheses matching
set ignorecase
set smartcase
set encoding=utf-8
set nobackup
set nowritebackup
set ic    " case insensitive for quick searches
"autocmd CursorMoved * silent! exe printf('match IncSearch /\<%s\>/', expand('<cword>'))
filetype indent on
"map <C-j> <C-w>j<C-w>_
"map <C-k> <C-w>k<C-w>_
colorscheme elflord
"colorscheme desert 
"colorscheme busybee

set statusline=%{fugitive#statusline()}

au FileType tex map <buffer> <F7> :w<CR>:!pdflatex %<CR>
au FileType c   map <buffer> <F7> :make<CR>
au FileType cpp map <buffer> <F7> :w<CR>:!g++ -g -Wall %<CR>
"map <F7> :w<CR>:!g++ -g -Wall %<CR>


" For mini buffer explorer
let g:miniBufExplMapWindowNavVim = 1
let g:miniBufExplMapWindowNavArrows = 1
let g:miniBufExplMapCTabSwitchBufs = 1
let g:miniBufExplModSelTarget = 1

" Highlight long lines
" ref: http://vim.wikia.com/wiki/VimTip812
au BufWinEnter *.c,*.cpp,*.h let w:m1=matchadd('Search', '\%<101v.\%>92v', -1)
au BufWinEnter *.c,*.cpp,*.h let w:m2=matchadd('ErrorMsg', '\%>100v.\+', -1)

"au BufWinEnter *.txt,*.tex set textwidth=100
"au BufWinEnter *.txt,*.tex set spell

" Vim folding
" ref: http://www.linux.com/archive/feature/114138
"au BufWinLeave * mkview
"au BufWinEnter * silent loadview





" Highlight all instances of word under cursor, when idle.
" Useful when studying strange source code.
" Type z/ to toggle highlighting on/off.
" nnoremap z/ :if AutoHighlightToggle()<Bar>set hls<Bar>endif<CR>
" function! AutoHighlightToggle()
"   let @/ = ''
"   if exists('#auto_highlight')
"     au! auto_highlight
"     augroup! auto_highlight
"     setl updatetime=4000
"     echo 'Highlight current word: off'
"     return 0
"   else
"     augroup auto_highlight
"       au!
"       au CursorHold * let @/ = '\<'.expand('<cword>').'\>'
"     augroup end
"     setl updatetime=500
"     echo 'Highlight current word: ON'
"     return 1
" 	endif
" endfunction
" 
