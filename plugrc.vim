let g:plug_window = "vertical botright new"
call plug#begin()
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/syntastic'
Plug 'vim-scripts/a.vim', { 'for': ['c', 'h', 'cpp', 'hpp'] }
Plug 'jlanzarotta/bufexplorer'
"Plug 'vim-scripts/winmanager'
Plug 'vim-airline/vim-airline'
Plug 'tpope/vim-fugitive'
Plug 'mhinz/vim-grepper'
Plug 'mhinz/vim-startify'
if has('win32') || has('win64')
	Plug '~/.vim/plugged/vim-ycm-windows'
else
	Plug 'Valloric/YouCompleteMe', { 'do': './install.py --clang-completer' }
endif
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable', 'on': [ 'YcmGenerateConfig', 'CCGenerateConfig' ]}
Plug 'airblade/vim-rooter'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'hdima/python-syntax' ", { 'for': 'py' }
Plug 'nathanaelkane/vim-indent-guides'
Plug 'majutsushi/tagbar'
Plug 'jeffkreeftmeijer/vim-numbertoggle'
Plug 'michaeljsmith/vim-indent-object'
Plug 'jiangmiao/auto-pairs'
"Plug 'flazz/vim-colorschemes'
Plug 'NLKNguyen/papercolor-theme'
Plug 'morhetz/gruvbox'
Plug 'w0ng/vim-hybrid'
Plug 'junegunn/seoul256.vim'
Plug 'reedes/vim-colors-pencil'
Plug 'altercation/vim-colors-solarized'
Plug 'tpope/vim-vividchalk'
Plug 'itchyny/landscape.vim'
Plug 'kristijanhusak/vim-hybrid-material'
call plug#end()
