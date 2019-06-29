"" vimrc : initialization script for vim(1) 


"" Unset 'compatible' to use vim defaults (instead of vi)
if &compatible
  set nocompatible
endif

"" If the +eval feature is missing, this unsets 'compatible'
silent! while 0
  set nocompatible
silent! endwhile

"" Always use utf-8
set encoding=utf-8



"" -- Plugins & Syntax --

""" Activate pathogen
"execute pathogen#infect()
"
"" Detect filetype, load plugins, and apply indentation style
filetype plugin indent on

"" Perform syntax highlighting
syntax enable



"" -- Tabs & Formatting --

"" Insert spaces insted of tab characters
set expandtab

"" No. of columns reserved for line #'s minus (1) for 
set numberwidth=3

"" No. of spaces to use for an indent
set shiftwidth=2

"" No. of spaces to insert for a tab
set softtabstop=2

"" Visual width of a real '\t' tab (i.e. ascii 0x09)
set tabstop=8

"" Line length past which lines are broken automatically 
set textwidth=79



"" -- Patterns & Searching --

"" Do not highlight search results
set nohlsearch

"" Search forward as pattern is typed
set incsearch

"" Ignore case by default
set ignorecase

"" Respect case if pattern contains uppercase
set smartcase

"" Additional bases recognized for increment/decrement
set nrformats=bin,hex



"" -- Info & Verbosity --

"" Display line numbers
set number

"" Display line numbers relative to current line
set relativenumber

"" Display cursor coordinates (e.g. LINE,COLUMN)
set ruler

"" Display most recent command below window
set showcmd

"" Briefly jump to match upon completing pair in 'matchpairs'
set showmatch

"" Highlight specified columns relative to 'textwidth'
set colorcolumn=+1,+2,+3,+4,+5,+6,+7,+8

"" Show @@@ in-place of lines that do not fit entirely in window
if v:version >= 800
  set display=truncate
endif

"" Always show status line
set laststatus=2



"" -- Cursor Movement --

"" Attempt to preserve cursor position when moving linewise
set nostartofline

"" Allow backspacing over everything in insert mode
set backspace=indent,eol,start

"" Lines of padding between cursor and edge of window
set scrolloff=4

"" If 'nowrap' is set, minimum number of columnss to scroll at a time
set sidescroll=1

"" If 'nowrap' is set, columns of padding between cursor and edge of window
set sidescrolloff=4

"" Allow visual-block selection of empty columns
set virtualedit=block



"" -- Buffers --

"" Re-read open file if it was changed by another program
set autoread

"" Hide closed buffers rather than unloading them
set hidden

"" Split off new windows below the current
set splitbelow

"" Split off new windows to the right of the current
set splitright



"" -- Completion --

"" Enable command completion
set wildmenu

"" Ignore case for filename completions
set wildignorecase

"" Insert-mode completion behavior
set completeopt=menu,preview,noselect

"" Cmdline-mode completion behavior
set wildmode=list:longest,full



"" -- Key Timeout --

"" Time out on mappings and keycodes
set timeout

"" Time in ms to wait for completion of a mapping
set timeoutlen=1597

"" Time in ms to wait for completion of a key code
set ttimeoutlen=144



"" -- History  --

"" Number of search patterns and ``:'' commands to remember (max: 10000)
set history=10000

"" Number of modifications to remember for any given file
set undolevels=2500

"" Always save the whole buffer for undo when reloading it
set undoreload=-1

"" Max characters that may be typed between swapfile syncs
set updatecount=144



"" -- Swap / Undo --

"" Check undofile capability and use if using swapfile
if has('persistent_undo')
  let &undofile = &swapfile
endif


"" Clear swap / undo directory preferences
set directory=
set undodir=


"" Append MYVIMRUNTIME if non-null
if $MYVIMRUNTIME != ''
  set directory+=$MYVIMRUNTIME/swap/
  set   undodir+=$MYVIMRUNTIME/undo/
endif


"" Append XDG_DATA_HOME if non-null
if $XDG_DATA_HOME != ''
  set directory+=$XDG_DATA_HOME/vim/swap/
  set   undodir+=$XDG_DATA_HOME/vim/undo/
endif


"" Append XDG_CACHE_HOME if non-null
if $XDG_CACHE_HOME != ''
  set directory+=$XDG_CACHE_HOME/vim/swap/
  set   undodir+=$XDG_CACHE_HOME/vim/undo/
endif


"" Append first element of 'runtimepath'
if ! empty(split(&runtimepath, ','))
  if empty(&directory)
    let &directory = split(&runtimepath, ',')[0] . '/swap/'
  else
    let &directory .= ',' . split(&runtimepath, ',')[0] . '/swap/'
  endif
  if empty(&undodir)
    let &undodir = split(&runtimepath, ',')[0] . '/undo/'
  else
    let &undodir .= ',' . split(&runtimepath, ',')[0] . '/undo/'
  endif
endif


"" Append TMPDIR if non-null
if $TMPDIR != ''
  set directory+=$TMPDIR/
  set   undodir+=$TMPDIR/
endif


"" Append default tmp directories
set directory+=/var/tmp/,/tmp/
set   undodir+=/var/tmp/,/tmp/


"" Make the primary swap directory
if ! isdirectory(split(&directory, ',')[0])
  silent! call system('/usr/bin/env mkdir -pm 700 '
        \ . shellescape(split(&directory, ',')[0]))
endif

"" Make the primary undo directory
if ! isdirectory(split(&undodir, ',')[0])
  silent! call system('/usr/bin/env mkdir -pm 700 '
        \ . shellescape(split(&undodir, ',')[0]))
endif



"" -- Terminal --

"" F**k terminal bells
set belloff=backspace,cursor,complete,error,esc,showmatch,wildmode



"" -- Mouse --

"" Enable the mouse
if has('mouse')
  set mouse=a
endif



"" -- Colors --

"" Set terminal colorscheme
if &t_Co == 16777216 || $COLORTERM == 'truecolor' || $COLORTERM == '24bit'
  "colorscheme spacegray
  colorscheme desertP
elseif $TERM =~ '\v^(iterm|linux|rxvt|st|tmux|vte|xterm)(-.*)?$'
  let &t_Co = 256
  "colorscheme spacegray
  colorscheme desertP
endif



"" -- Python --

""" Set the default python version for pyx commands
"if v:version >= 800
"  if has('python3')
"    set pyxversion=3 " Prefer Python3
"  elseif has('python2')
"    set pyxversion=2 " Python2 will do
"  endif
"endif

let g:python_recommended_style = 1  " PEP8 compliance
let g:python_highlight_all = 1      " Enable all available highlighting


"" Define mapping to set python modeline at end of file
autocmd FileType python
  \ nnoremap <leader>ml Go<CR># vi:ft=python:et:sts=4:sw=4:ts=8<ESC><C-o>



"" -- C / C++ --
let g:c_comment_strings = 1 " Allow strings & numbers inside comments
let g:c_gnu             = 1 " Highlight GNU specific items
let g:c_space_errors    = 1 " Highlight space errors (?)

"" Set local options when opening a C or C++ file
autocmd FileType c,cpp setlocal sts=8 sw=8


"" Define mapping to set C modeline at end of file
autocmd FileType c
  \ nnoremap <leader>ml Go<CR>// vi:ft=c:et:sts=8:sw=8:ts=8<ESC><C-o>

"" Define mapping to set C++ modeline at end of file
autocmd FileType cpp
  \ nnoremap <leader>ml Go<CR>// vi:ft=cpp:et:sts=8:sw=8:ts=8<ESC><C-o>



"" -- Readline --

let g:readline_has_bash = 1 " Highlight additions available through bash


"" Define mapping to set sed modeline at end of file
autocmd FileType sed
  \ nnoremap <leader>ml Go<CR># vi:ft=readline:et:sts=2:sw=2:ts=8<ESC><C-o>



"" -- Sh --

let g:is_posix          = 1 " Highlighting for ambiguous *.sh files
let g:sh_fold_enabled   = 3 " Folding mode (functions, if/do/for)
let g:sh_no_error       = 1 " Relax error detection


"" Define mapping to set sh modeline at end of file
autocmd FileType sh
  \ nnoremap <leader>ml Go<CR># vi:ft=sh:et:sts=2:sw=2:ts=8<ESC><C-o>



"" -- Sed --

let g:highlight_sedtabs = 1 " Highlight real tabs in sed scripts


"" Define mapping to set sed modeline at end of file
autocmd FileType sed
  \ nnoremap <leader>ml Go<CR># vi:ft=sed:et:sts=2:sw=2:ts=8<ESC><C-o>



"" -- Man --

"" Set local options when opening a manpage
autocmd FileType man setlocal colorcolumn= nohidden noswapfile noundofile

"" Load the Man plugin
runtime ftplugin/man.vim

"" K command opens man pages in vim
set keywordprg=:Man



"" -- help --

"" Set local options when opening a manpage
autocmd FileType help
  \ setlocal colorcolumn= nohidden noswapfile noundofile



"" -- Powerline --

if has('python3')
  let g:powerline_pycmd = 'py3'
elseif has('python')
  let g:powerline_pycmd = 'py'
else
  let g:powerline_pycmd = ''
endif



"" -- Mappings--

"" Key to act as <leader> in mappings
let g:mapleader = ','         


"" Next / Previous Tab
nnoremap <silent><ESC>[1;3C :tabnext<CR>
nnoremap <silent><ESC>[1;3D  :tabprev<CR>


"" Toggle search highlighting
nnoremap <silent><F3> :set hlsearch!<CR>


"" Toggle syntax highlighting
nnoremap <silent><F7> :if exists('g:syntax_on')<Bar>
  \syntax off<Bar>else<Bar>syntax enable<Bar>endif<CR>


"" Quote word before or at the cursor (see :help word)
"" Note: 'selection' must be inclusive or exclusive
nnoremap <leader>' vl<ESC>bi'<ESC>ea'<ESC>l
nnoremap <leader>" vl<ESC>bi"<ESC>ea"<ESC>l
nnoremap <leader>[ vl<ESC>bi[<ESC>ea]<ESC>l
nnoremap <leader>{ vl<ESC>bi{<ESC>ea}<ESC>l
nnoremap <leader>( vl<ESC>bi(<ESC>ea)<ESC>l
nnoremap <leader>< vl<ESC>bi<<ESC>ea><ESC>l

"" Quote WORD before or at the cursor (see :help WORD)
"" Note: 'selection' must be inclusive or exclusive
nnoremap <leader><leader>' vl<ESC>Bi'<ESC>Ea'<ESC>l
nnoremap <leader><leader>" vl<ESC>Bi"<ESC>Ea"<ESC>l
nnoremap <leader><leader>[ vl<ESC>Bi[<ESC>Ea]<ESC>l
nnoremap <leader><leader>{ vl<ESC>Bi{<ESC>Ea}<ESC>l
nnoremap <leader><leader>( vl<ESC>Bi(<ESC>Ea)<ESC>l
nnoremap <leader><leader>< vl<ESC>Bi<<ESC>Ea><ESC>l


"" Search forward for the current visual selection
"" Note: Jumping to a tag does not set the current search pattern
vnoremap <silent> * :<C-U>let old_reg=getreg('"')<Bar>
  \let old_regtype=getregtype('"')<CR>
  \gvy/<C-R><C-R>
  \=substitute(escape(@",'/\.*$^~['),'\_s\+','\\_s\\+','g')<CR><CR>
  \gV:call setreg('"',old_reg,old_regtype)<CR>

"" Search backward for the current visual selection
"" Note: Jumping to a tag does not set the current search pattern
vnoremap <silent> # :<C-U>let old_reg=getreg('"')<Bar>
  \let old_regtype=getregtype('"')<CR>
  \gvy?<C-R><C-R>
  \=substitute(escape(@",'?\.*$^~['),'\_s\+','\\_s\\+','g')<CR><CR>
  \gV:call setreg('"',old_reg,old_regtype)<CR>



"" -- Misc --

"" Allow options to be set from a modeline
set modeline

"" Restrict editor if SWIM owns this file (this should be last)
set secure