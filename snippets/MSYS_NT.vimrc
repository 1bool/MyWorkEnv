" Make windows use ~/.vim too, I don't want to use _vimfiles
set runtimepath^=~/.vim,$VIMRUNTIME
"
" ycm for win
if !has("gui_running")
	let g:ycm_server_python_interpreter = '/c/Program Files/Python37/python.exe'
endif

set encoding=utf-8
