if has('win32') || has('win64')
	" Make windows use ~/.vim too, I don't want to use _vimfiles
	set runtimepath^=~/.vim
endif
runtime! pluginrc.vim

" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
	au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") |
				\	exe "normal! g'\"" | endif
endif

" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
if has("autocmd")
	filetype plugin indent on
endif

" Normally we use vim-extensions. If you want true vi-compatibility
" remove change the following statements
set nocompatible	" Use Vim defaults instead of 100% vi compatibility
set backspace=2		" more powerful backspacing

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.
set ignorecase		" Do case insensitive matching
set smartcase		" Do smart case matching
set incsearch		" Incremental search
set autowrite		" Automatically save before commands like :next and :make
set hidden		" Hide buffers when they are abandoned
set mouse=a		" Enable mouse usage (all modes)

" By default, searching starts after you enter the string. With the option:
set incsearch
set hlsearch " turns on search highlighting
set tags=./tags;/
set encoding=utf-8
set termencoding=utf-8
set t_Co=256
set laststatus=2 " For powerline always show

" Easier to switch window
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-H> <C-W>h
noremap <C-L> <C-W>l

" Easier to switch buffer
set switchbuf=usetab,newtab
map gn :bn<cr>
map gp :bp<cr>
map gd :bd<cr>
nnoremap <C-TAB> :sbnext<CR>
nnoremap <C-S-TAB> :sbprevious<CR>

" Open file explorer
map ge :Texplore<CR>

" Open buffer explorer
map gb :BufExplorer<CR>

" Man
runtime ftplugin/man.vim
nnoremap K :Man <cword><cr>

" Some people like the visual feedback shown in the status line
" by the following alternative for your vimrc
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" Toggle line number
nmap <C-N><C-N> :setlocal invnumber<CR>

" Toggle background
map <Leader>b :let &background = ( &background == "dark"? "light" : "dark" )<CR>

if has("autocmd")
	autocmd BufEnter,BufWrite,FileType c,cpp,python,sh,java,javascript,perl,ruby,php,make,vim
				\ setlocal number | setlocal cursorline
	autocmd VimEnter,FileType * call PluginSetup()
	autocmd BufEnter,BufWrite,FileType c,cpp,python,sh,java,javascript,perl,ruby,php,make,vim nested TagbarOpen
	autocmd FilterWritePre * nested if &diff | TagbarClose
endif

function! PluginSetup()
	if exists(":TagbarToggle")
		let g:Tagbar_title = "[Tagbar]"
		let g:tagbar_width = 36
		let g:tagbar_zoomwidth = 0
		nnoremap <silent> <F7> :TagbarToggle<CR>
	endif
	if exists(":NERDTreeToggle")
		let g:NERDTree_title="[NERDTree]"
		let NERDTreeWinSize=36 "设置 NERDTree 子窗口宽度
		let NERDTreeWinPos="left" "设置 NERDTree 子窗口位置
		let NERDTreeShowBookmarks = 1
		nnoremap <silent> <F6> :NERDTreeToggle<CR>
	endif
	if exists(":Grepper")
		" When search with git, search from top level of the repository
		"let g:grepper.git =
		"\ { 'grepprg': 'git grep -nI $* -- `git rev-parse --show-toplevel`' }
		nnoremap gs   :Grepper -highlight -cword -noprompt<cr>
		nmap <F3> <plug>(GrepperOperator)
		xmap <F3> <plug>(GrepperOperator)
	endif
	if exists(":YcmCompleter")
		let g:ycm_seed_identifiers_with_syntax = 1 " Completion for programming language's keyword
		let g:ycm_autoclose_preview_window_after_completion = 1
		let g:ycm_autoclose_preview_window_after_insertion = 1
		nnoremap <Leader>g :YcmCompleter GoTo<CR>
		nnoremap <Leader>] :YcmCompleter GoToDefinition<CR>
		nnoremap <Leader>r :YcmCompleter GoToReferences<CR>
		nnoremap <Leader>y :YcmCompleter GetType<CR>
		nnoremap <Leader>d :YcmCompleter GetDoc<CR>
		nnoremap <F5> :YcmForceCompileAndDiagnostics<CR>
	endif
	if exists(":IndentGuidesToggle")
		"let g:indent_guides_enable_on_vim_startup=1 " 随 vim 自启动
		let g:indent_guides_start_level=2 "从第二层开始可视化显示缩进
		let g:indent_guides_guide_size=1 " 色块宽度
		" 快捷键 i 开/关缩进可视化
		nmap <silent> <Leader>i <Plug>IndentGuidesToggle
	endif
endfunction

" air-line
let g:airline_powerline_fonts = 1
"let g:Powerline_symbols = 'fancy'
let g:airline#extensions#tabline#enabled = 1

"set statusline=%{fugitive#statusline()} " fugitive status
command! Gtdiff tabedit %|Gvdiff " git diff in tab

" syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" auto cd
let g:rooter_change_directory_for_non_project_files = 'current'
let g:rooter_use_lcd = 1
let g:rooter_silent_chdir = 1

let g:ctrlp_cmd = 'CtrlPMRU' " MRU file list as ctrlp default

let python_highlight_all = 1 " python-syntax

try
	colorscheme landscape
catch /^Vim\%((\a\+)\)\=:E185/
	" Fallback to desert
	colorscheme desert
endtry
