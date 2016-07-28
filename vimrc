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
"set shiftwidth=4
"set tabstop=4
"set sts=4
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
set switchbuf=usetab
map gn :bn<cr>
map gp :bp<cr>
map gd :bd<cr>
nnoremap <C-TAB> :bnext<CR>
nnoremap <C-S-TAB> :bprevious<CR>

" Open file explorer
map ge :Explore<CR>

" Open buffer explorer
map gb :BufExplorer<CR>

" Man
source $VIMRUNTIME/ftplugin/man.vim
nnoremap K :Man <cword><cr>

" Some people like the visual feedback shown in the status line
" by the following alternative for your vimrc
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
set showmode

" Toggle line number
nmap <C-N><C-N> :setlocal invnumber<CR>

if has("autocmd")
	autocmd BufEnter,BufWrite,FileType c,cpp,python,sh,java,javascript,perl,ruby,php,make,vim
				\ setlocal number
				\ | setlocal cursorline
				\ | TagbarOpen
	autocmd VimEnter,FileType * call PlugInSetup()
	"autocmd! VIMEnter,FileType python,c,cpp,java,javascript,sh,ruby,perl,php call IDE()
	autocmd FileType python let python_highlight_all = 1
endif

function! PlugInSetup()
	if exists(":TagbarToggle")
		let g:Tagbar_title = "[Tagbar]"
		let g:tagbar_width = 36
		let g:tagbar_zoomwidth = 0
		nnoremap <silent> <F7> :TagbarToggle<CR>
		" For call by winmanager
		function! Tagbar_Start()  
			q
			exec 'Tagbar'  
		endfunction
		function! Tagbar_IsValid()  
			return 1  
		endfunction
	endif
	if exists(":NERDTreeToggle")
		let g:NERDTree_title="[NERDTree]"
		"设置 NERDTree 子窗口宽度
		let NERDTreeWinSize=36
		"设置 NERDTree 子窗口位置
		let NERDTreeWinPos="left"
		let NERDTreeShowBookmarks = 1
		nnoremap <silent> <F6> :NERDTreeToggle<CR>
		" For call by winmanager
		function! NERDTree_Start()  
			exec 'NERDTree'  
		endfunction
		function! NERDTree_IsValid()  
			return 1  
		endfunction
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
		nnoremap <Leader>gg :YcmCompleter GoTo<CR>
		nnoremap <Leader>gd :YcmCompleter GoToDefinition<CR>
		nnoremap <Leader>gr :YcmCompleter GoToReferences<CR>
		nnoremap <Leader>gh :YcmCompleter GetDoc<CR>
		nnoremap <F5> :YcmForceCompileAndDiagnostics<CR>
	endif
	if exists(":WMToggle")
		let g:winManagerWidth = 40
		let g:winManagerWindowLayout="NERDTree|Tagbar,BufExplorer"
		function! IDE()
			let g:tagbar_vertical_save = g:tagbar_vertical
			let g:tagbar_vertical = 30
			if IsWinManagerVisible()
				WMToggle
			else
				WMToggle
				q
				1wincmd w
			endif
			let g:tagbar_vertical = g:tagbar_vertical_save
		endfunction
		nnoremap <silent> <F4> :call IDE()<CR>
	endif
	if exists(":IndentGuidesToggle")
		" 随 vim 自启动
		"let g:indent_guides_enable_on_vim_startup=1
		" 从第二层开始可视化显示缩进
		let g:indent_guides_start_level=2
		" 色块宽度
		let g:indent_guides_guide_size=1
		" 快捷键 i 开/关缩进可视化
		nmap <silent> <Leader>i <Plug>IndentGuidesToggle
	endif
endfunction

" air-line
let g:airline_powerline_fonts = 1
"let g:Powerline_symbols = 'fancy'
let g:airline#extensions#tabline#enabled = 1

" fugitive status
"set statusline=%{fugitive#statusline()}

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

" MRU file list as ctrlp default
let g:ctrlp_cmd = 'CtrlPMRU'

colorscheme vividchalk
