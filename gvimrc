set background=light
colorscheme hybrid_material
let g:airline_theme = 'hybrid'
" let g:airline_theme = 'papercolor'

" For airline
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.crypt = '🔒'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.maxlinenr = '☰'
let g:airline_symbols.maxlinenr = ''
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.spell = 'Ꞩ'
let g:airline_symbols.notexists = '∄'
let g:airline_symbols.whitespace = 'Ξ'
let g:airline_symbols.space = "\ua0"
" powerline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

if has("gui_gtk2")
	set guifont=Fira\ Mono\ for\ Powerline\ 11\\,Input\ Mono\ Condensed\\,\ Regular\ Condensed\ 12\\,Monospace\ 11
elseif has("gui_macvim")
	set guifont=InputMonoCondensed:h13,Cousine\ for\ Powerline:h12
elseif has("gui_win32")
	set guifont=InputMonoCondensed:h12:cANSI
endif

source $HOME/.gvimrc.local
