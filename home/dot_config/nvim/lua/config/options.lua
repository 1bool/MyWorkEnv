-- 基础选项（迁移自 ~/.vimrc 的 set 项 + nvim 增强）

-- leader 键：必须在任何 <leader> 映射生效前设置（本文件由 init.lua 最先 require）
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

-- 按键时序：空格当 leader 后，按完前缀要等下一次按键；默认 1000ms 会让组合键
-- 有明显停顿，调小到 300ms 手感更顺（也缓解 nvim-claude 的 <Space>cp 歧义延迟）
opt.timeoutlen = 300

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

-- shell 修正：MSYS2 下 nvim 用 bash/zsh 作 &shell，但 shellcmdflag 仍是
-- cmd.exe 的 /s /c，导致 vim.fn.system() 跑 POSIX 命令失败
-- （nvim-claude 的 `which tmux` 就因此报 "tmux not found"）。
-- 只有 &shell 是 POSIX shell 时才改成 -c；真 Windows 的 cmd.exe/powershell 保持默认。
if vim.fn.has("win32") == 1 then
  local sh = (vim.o.shell or ""):lower()
  if sh:match("bash") or sh:match("zsh") or sh:match("fish")
      or sh:match("dash") or sh:match("[/\\]sh$") then
    opt.shellcmdflag = "-c"
    opt.shellxquote = ""
  end
end

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
