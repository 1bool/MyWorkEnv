if v:version >= 802
	if has("win64")
		Plug 'snakeleon/YouCompleteMe-x64'
	else
		Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clangd-completer' }
	endif
endif
