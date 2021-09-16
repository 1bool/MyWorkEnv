set encoding=utf-8
set guioptions-=r  "remove right-hand scroll bar
if has("gui_win32")
	set formatoptions+=mM
	language messages zh_CN.utf-8
	set langmenu=zh_CN.utf-8
	runtime! delmenu.vim
	runtime! menu.vim
	set guifont=FiraCode_NF:h12:cANSI:qDRAFT
endif
