-- Neovim 入口
-- 自举 lazy.nvim（首次会从 GitHub 克隆；走 justfile 里设好的 GH_PROXY insteadOf 镜像）

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" },
    }, true, {})
  end
end
vim.opt.rtp:prepend(lazypath)

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lsp")

require("lazy").setup("plugins")
