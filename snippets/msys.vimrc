" Make windows use ~/.vim too, I don't want to use _vimfiles
set runtimepath^=~/.vim,$VIMRUNTIME
" ycm for win
" if !has("gui_running")
	" let g:ycm_server_python_interpreter = '/c/Program Files/Python37/python.exe'
" endif
" Use msys for terminal in win32
if has("win32")
	map te :ter ++close ++rows=12 D:\msys64\msys2_shell.cmd -defterm -here -no-start -msys<CR>
" elseif has("win32unix")
	" set shell=/D/msys64/msys2_shell.cmd\ -defterm\ -here\ -no-start\ -msys\ -shell\ zsh
else
	map te :ter ++close ++rows=12<CR>
endif
