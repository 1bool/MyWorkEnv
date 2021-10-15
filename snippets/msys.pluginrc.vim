if has("win64")
	Plug 'snakeleon/YouCompleteMe-x64'
else
	Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer' }
endif
