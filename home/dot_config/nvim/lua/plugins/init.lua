-- lazy.nvim 插件清单（全原生；语言工具走系统包）
return {
  -- ── 主题（沿用 vim 的 solarized） ──
  {
    "shaunsingh/solarized.nvim",
    name = "solarized",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("solarized")
    end,
  },

  -- ── 状态栏 / 图标 ──
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "nvim-lualine/lualine.nvim", opts = { options = { theme = "auto" } } },

  -- ── 文件树 ──
  {
    "nvim-tree/nvim-tree.lua",
    keys = {
      { "tf", "<cmd>NvimTreeToggle<CR>", desc = "文件树开关" },
      { "<F6>", "<cmd>NvimTreeToggle<CR>", desc = "文件树开关" },
      { "ge", "<cmd>NvimTreeFocus<CR>", desc = "聚焦文件树" },
    },
    opts = { view = { width = 40 }, update_focused_file = { enable = true } },
  },

  -- ── 模糊查找 ──
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "找文件" },
      { "gb", "<cmd>Telescope buffers<CR>", desc = "缓冲列表" },
      { "gs", "<cmd>Telescope live_grep<CR>", desc = "全局 grep" },
      { "<leader>*", "<cmd>Telescope grep_string<CR>", desc = "搜光标词" },
      { "<leader>f", "<cmd>Telescope buffers<CR>", desc = "缓冲列表" },
      { "<leader>m", "<cmd>Telescope oldfiles<CR>", desc = "历史" },
      { "tt", "<cmd>Telescope lsp_document_symbols<CR>", desc = "符号大纲" },
      { "<F7>", "<cmd>Telescope lsp_document_symbols<CR>", desc = "符号大纲" },
    },
  },

  -- ── Git ──
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      { "<leader>d", "<cmd>Gitsigns diff_this<CR>", desc = "当前文件 diff" },
    },
    opts = {},
  },
  {
    "NeogitOrg/neogit",
    keys = { { "<leader>g", "<cmd>Neogit<CR>", desc = "Git 状态" } },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- ── 补全 ──
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "L3MON4D3/LuaSnip", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
  { "hrsh7th/cmp-nvim-lsp", lazy = true },
  { "hrsh7th/cmp-buffer", lazy = true },
  { "hrsh7th/cmp-path", lazy = true },
  { "L3MON4D3/LuaSnip", lazy = true },

  -- ── 诊断列表 ──
  {
    "folke/trouble.nvim",
    keys = { { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "诊断列表" } },
    opts = {},
  },

  -- ── Lint（ruff / shellcheck，走系统包） ──
  {
    "mfussenegger/nvim-lint",
    config = function()
      require("lint").linters_by_ft = {
        python = { "ruff" },
        sh = { "shellcheck" },
      }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
        callback = function() require("lint").try_lint() end,
      })
    end,
  },

  -- ── 格式化（ruff format / clang-format，走系统包） ──
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          python = { "ruff_format" },
          c = { "clang_format" },
          cpp = { "clang_format" },
        },
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function(args) require("conform").format({ bufnr = args.buf }) end,
      })
    end,
  },

  -- ── 语法高亮 / 文本对象 ──
  {
    "nvim-treesitter/nvim-treesitter",
    version = "*", -- 锁稳定版：master 已把 configs.lua 改名/移除，导致 require('nvim-treesitter.configs') 失败
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "python", "bash", "make" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      })
    end,
  },

  -- ── 编辑 ──
  { "numToStr/Comment.nvim", opts = {} },
  { "kylechui/nvim-surround", opts = {} },
  { "windwp/nvim-autopairs", opts = {} },
  {
    "ggandor/leap.nvim",
    keys = { { "s", "<Plug>(leap-forward-to)", desc = "跳转" } },
    opts = {},
  },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

  -- ── 键位提示 ──
  { "folke/which-key.nvim", opts = {} },

  -- ── Claude Code ──
  {
    "zolinthecow/nvim-claude",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "ClaudeChat", "ClaudeSendBuffer", "ClaudeSendSelection", "ClaudeBg" },
    opts = {},
    submodules = false, -- 跳过 C++ 子模块 cursor_cpp（镜像克隆不了，且非目标语言）
  },
}
