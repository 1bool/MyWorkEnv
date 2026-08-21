-- 通用键位（迁移自 ~/.vimrc；插件相关键位见 plugins/init.lua 的 keys）
local map = vim.keymap.set
local silent = { noremap = true, silent = true }

-- 剪贴板（对应 vimrc 的 "+ 映射；options 里已设 unnamedplus）
map("v", "<S-Del>", '"+x')
map("v", "<C-x>", '"+x')
map("v", "<C-Insert>", '"+y')
map("v", "<C-c>", '"+y')
map({ "n", "v" }, "<S-Insert>", '"+gP')
map("i", "<C-v>", '<Esc>"+gPa')
map("c", "<C-v>", '<C-r>+')

-- 窗口切换
map({ "n", "v" }, "<C-j>", "<C-w>j", silent)
map({ "n", "v" }, "<C-k>", "<C-w>k", silent)
map({ "n", "v" }, "<C-h>", "<C-w>h", silent)
map({ "n", "v" }, "<C-l>", "<C-w>l", silent)

-- 缓冲切换
map("n", "gn", ":bn<CR>", silent)
map("n", "gp", ":bp<CR>", silent)
map("n", "gx", ":bd<CR>", silent)
map("n", "<C-TAB>", ":sbnext<CR>", silent)
map("n", "<C-S-TAB>", ":sbprevious<CR>", silent)

-- Man
map("n", "K", "<cmd>Man <cword><CR>", silent)

-- 粘贴切换
map("n", "<F2>", ":set invpaste paste?<CR>", silent)

-- 行号切换
map("n", "<C-n><C-n>", ":setlocal invnumber<CR>", silent)

-- 窗口尺寸
map("n", "wK", ":resize -5<CR>", silent)
map("n", "wJ", ":resize +5<CR>", silent)
map("n", "wH", ":vertical resize -5<CR>", silent)
map("n", "wL", ":vertical resize +5<CR>", silent)

-- 明暗切换
map("n", "<leader>b", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, silent)

-- 鼠标前进后退
map("n", "<X1Mouse>", "<C-o>", silent)
map("n", "<X2Mouse>", "<C-i>", silent)

-- 终端
map("n", "te", "<cmd>terminal<CR>", silent)
