-- Neovim 入口
-- 自举 lazy.nvim（首次从 GitHub 克隆；直连失败时用 GH_PROXY 重试）

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local url = "https://github.com/folke/lazy.nvim.git"
  local proxy = vim.env.GH_PROXY or ""
  local function clone(src)
    local out = vim.fn.system({
      "git", "clone", "--filter=blob:none",
      src,
      "--branch=stable",
      lazypath,
    })
    return vim.v.shell_error == 0, out
  end
  -- 直连失败且设置了 GH_PROXY 时，用代理重试（直接开 nvim 也能自举）
  local ok, out = clone(url)
  if not ok and proxy ~= "" then
    vim.fn.delete(lazypath, "rf")
    ok, out = clone(proxy .. url)
  end
  if not ok then
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
