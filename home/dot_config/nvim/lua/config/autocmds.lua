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
