-- autocmd（迁移自 ~/.vimrc）
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- 回到上次退出位置
autocmd("BufReadPost", {
  callback = function()
    local pos = vim.fn.line([['"]])
    if pos > 1 and pos <= vim.fn.line("$") then
      vim.cmd([[normal! g'"]])
    end
  end,
})

-- 文件类型缩进（对应 vimrc 的 autocmd FileType ... setlocal expandtab shiftwidth=4）
local indent_fts = {
  "c", "cpp", "python", "sh", "java", "javascript",
  "perl", "ruby", "php", "make", "vim", "go",
}
local g = augroup("filetype_indent", { clear = true })
autocmd({ "BufEnter", "BufWrite", "FileType" }, {
  group = g,
  pattern = indent_fts,
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.cursorline = true
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

-- 自动把 cwd 切到项目根目录（git root 等），跟随 buffer 切换
-- 用 nvim 内置 vim.fs.root()（0.10+），零依赖；找不到项目根时保持原 cwd 不变。
-- 用全局 cd 而非 lcd，这样 nvim-claude 里启动的 Claude 拿到的 cwd 也会跟着变。
local proot_group = augroup("project_root_cd", { clear = true })
autocmd({ "BufEnter", "VimEnter" }, {
  group = proot_group,
  callback = function()
    local root = vim.fs.root(0, { ".git", ".hg", ".svn", "_darcs", ".bzr" })
    if root then
      vim.api.nvim_set_current_dir(root)
    end
  end,
})
