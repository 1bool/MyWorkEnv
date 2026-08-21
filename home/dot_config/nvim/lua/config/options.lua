-- 基础选项（迁移自 ~/.vimrc 的 set 项 + nvim 增强）
local opt = vim.opt

-- 编辑
opt.backspace = "indent,eol,start"
opt.showcmd = true
opt.showmatch = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.autowrite = true
opt.hidden = true
opt.mouse = "a"
opt.hlsearch = true
opt.wildmenu = true
opt.autoindent = true
opt.smartindent = true
opt.smarttab = true

-- 缩进（expandtab 不在全局开，按文件类型在 autocmds 里 setlocal）
opt.shiftwidth = 4
opt.softtabstop = 4
opt.tabstop = 4

-- 外观
opt.termguicolors = true
opt.laststatus = 3          -- 全局状态栏（lualine 需要）
opt.showmode = false        -- 模式由 lualine 显示
opt.signcolumn = "yes"      -- gitsigns 等 sign 用
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.pumblend = 10
opt.pumheight = 10

-- 滚动
opt.scrolloff = 1
opt.sidescrolloff = 5
opt.display = "lastline"

-- 编码 / 换行
opt.fileencodings = "utf-8,gb18030,cp936,big5,default,ucs-bom,latin1"
opt.fileformats = "unix,dos"

-- 缓冲切换
opt.switchbuf = "useopen,usetab,newtab"

-- 系统剪贴板（对应 vimrc 里的 "+ 映射，nvim 直接走 unnamedplus）
opt.clipboard = "unnamedplus"

-- 搜索 / tags
opt.tags = "./tags;"

-- swap / undo 目录
opt.directory = vim.fn.stdpath("state") .. "/swap//"
opt.undodir = vim.fn.stdpath("state") .. "/undo//"
opt.undofile = true

-- 分屏方向
opt.splitright = true
opt.splitbelow = true

-- 折叠
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false
