-- lazy.nvim 插件清单（全原生；语言工具走系统包）

-- 与 ~/.config/shell/models.env 导出的模型 env 联动（单一来源；不设兜底）
local cc_main_model = os.getenv("ANTHROPIC_MODEL")
local cc_fast_model = os.getenv("ANTHROPIC_DEFAULT_HAIKU_MODEL")

return {
  -- ── 主题（solarized8：高对比 dark 模式） ──
  {
    "lifepillar/vim-solarized8",
    name = "solarized8",
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("solarized8")
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
        ensure_installed = { "c", "cpp", "python", "bash", "make", "lua", "yaml", "diff", "markdown", "markdown_inline" },
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

  -- ── AI 助手（CodeCompanion） ──
  {
    "olimorris/codecompanion.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
    keys = {
      { "<leader>aa", "<cmd>CodeCompanionChat<CR>", desc = "AI 对话" },
      { "<leader>ai", "<cmd>CodeCompanion<CR>", desc = "AI 内联改写" },
    },
    opts = {
      -- 隐私：token / base_url 从 ~/.zprofile.local 导出的环境变量读取，不进仓库。
      -- 模型名从 ~/.config/shell/models.env 导出的 env 读取（与 Claude Code 共用同一来源）。
      adapters = {
        http = {
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key = "ANTHROPIC_AUTH_TOKEN",
                url = "ANTHROPIC_BASE_URL",
              },
              url = "${url}/v1/messages",
              headers = {
                authorization = "Bearer ${api_key}",
              },
              -- 网关不支持 GET /v1/models（404），禁用模型列表拉取，改用 env 静态列表
              schema = {
                model = {
                  choices = function()
                    local models = {}
                    for _, var in ipairs({
                      "ANTHROPIC_MODEL",
                      "ANTHROPIC_DEFAULT_SONNET_MODEL",
                      "ANTHROPIC_DEFAULT_HAIKU_MODEL",
                      "ANTHROPIC_DEFAULT_OPUS_MODEL",
                    }) do
                      local name = os.getenv(var)
                      if name and name ~= "" then
                        models[name] = { opts = {} }
                      end
                    end
                    return models
                  end,
                },
              },
            })
          end,
        },
      },
      interactions = {
        chat = { adapter = { name = "anthropic", model = cc_main_model } },
        inline = { adapter = { name = "anthropic", model = cc_main_model } },
        background = { adapter = { name = "anthropic", model = cc_fast_model } },
      },
    },
  },
}
