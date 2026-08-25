-- LSP 配置（nvim 0.11+ 内置 vim.lsp.config，替代已弃用的 lspconfig）
-- 语言：C（clangd）、Python（basedpyright）

-- LSP 键位（挂到 LspAttach 事件）
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local o = { noremap = true, silent = true, buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, o)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, o)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, o)
    vim.keymap.set("n", "gh", vim.lsp.buf.hover, o)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, o)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, o)
  end,
})

-- C/C++：clangd
vim.lsp.config.clangd = {
  cmd = { "clangd" },
  filetypes = { "c", "cpp" },
  root_markers = { ".git", "compile_commands.json" },
}
vim.lsp.enable("clangd")

-- Python：basedpyright（完整 LSP：符号/定义/引用/重命名/类型检查；ruff 只做 lint+format，走 nvim-lint/conform）
vim.lsp.config.basedpyright = {
  -- MSYS2 的 basedpyright-langserver 是 POSIX shell 脚本，nvim(Windows) spawn 不了，改用 .cmd 启动器
  cmd = vim.fn.has("win32") == 1 and { "basedpyright-langserver.cmd", "--stdio" }
    or { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "requirements.txt" },
}
vim.lsp.enable("basedpyright")
