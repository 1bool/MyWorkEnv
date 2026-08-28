-- lazy.nvim 插件清单（全原生；语言工具走系统包）

-- 与 ~/.config/shell/models.env 导出的模型 env 联动（单一来源；不设兜底）
-- Claude Code 用 model[...] 标注上下文窗口（如 deepseek-v4-pro[1m]），但发给 API 时只发基础名；
-- 网关只注册了 deepseek-v4-pro（无 [1m]），带 [1m] 会报 model_not_found，故这里同样剥掉 [...]。
local function strip_ctx(name)
  return name and name:gsub("%[[^%]]*%]$", "") or name
end
local cc_main_model = strip_ctx(os.getenv("ANTHROPIC_MODEL"))
local cc_fast_model = strip_ctx(os.getenv("ANTHROPIC_DEFAULT_HAIKU_MODEL"))

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
      { "<leader>t", "<cmd>NvimTreeToggle<CR>", desc = "文件树开关" },
      { "<F6>", "<cmd>NvimTreeToggle<CR>", desc = "文件树开关" },
    },
    opts = {
      view = { width = 40 },
      update_focused_file = { enable = true },
      reload_on_bufenter = vim.fn.has("win32") == 1, -- Windows fs watcher 易漏刷，进 buffer 时重载
      actions = { open_file = { quit_on_open = true } }, -- 打开文件后自动关闭文件树
    },
  },

  -- ── 模糊查找 ──
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<CR>", desc = "找文件" },
      { "<leader>*", "<cmd>Telescope grep_string<CR>", desc = "搜光标词" },
      { "<leader>f", "<cmd>Telescope buffers<CR>", desc = "缓冲列表" },
    },
  },

  -- ── 符号大纲（右侧固定栏，类似 vim tagbar；可开关，默认不打开） ──
  {
    "stevearc/aerial.nvim",
    branch = vim.fn.has("nvim-0.12") == 1 and nil or "nvim-0.11", -- 仅旧版 nvim(<0.12，Ubuntu) 走 nvim-0.11 分支；0.12+（Windows/mac）用 master
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-web-devicons" },
    keys = {
      { "<leader>s", "<cmd>AerialToggle<CR>", desc = "符号大纲（右侧栏）" },
      { "<F7>", "<cmd>AerialToggle<CR>", desc = "符号大纲（右侧栏）" },
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { default_direction = "right" },
    },
  },

  -- ── Git ──
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" }, -- 行号栏 diff 符号要在进 buffer 时就加载（之前 keys 懒加载会漏）
    opts = {},
  },
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>g", "<cmd>Git<CR>", desc = "Git 状态" },
      { "<leader>d", "<cmd>Gdiffsplit<CR>", desc = "当前文件 diff" },
    },
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
    -- Windows(nvim 0.12)：main 新版（ABI-15 语法 + nvim 内置高亮，需系统 tree-sitter CLI）
    -- Linux(Ubuntu 旧 nvim)：version="*"（0.10.0 tag，configs API，自带编译）
    version = vim.fn.has("win32") == 0 and "*" or nil,
    build = ":TSUpdate",
    config = function()
      local langs = { "c", "cpp", "python", "bash", "make", "lua", "yaml", "diff", "markdown" }
      if vim.fn.has("win32") == 1 then
        -- 新版 API（main）：parser 装到 <data>/site/parser（在 runtimepath 上），高亮走 nvim 内置 vim.treesitter.start()
        -- indent（experimental）新版未迁移，暂用内置缩进，需要时再补。
        require("nvim-treesitter").setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
        require("nvim-treesitter").install(langs)
        vim.api.nvim_create_autocmd("FileType", {
          callback = function() pcall(vim.treesitter.start) end,
        })
      else
        -- 旧版 API（0.10.0 tag）
        require("nvim-treesitter.configs").setup({
          ensure_installed = langs,
          highlight = { enable = true },
          indent = { enable = true },
        })
      end
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      if vim.fn.has("win32") == 1 then
        -- 新版 API（main）：setup 设选项，keymap 手动绑 select_textobject
        require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
        local ts_select = require("nvim-treesitter-textobjects.select")
        for _, m in ipairs({ "x", "o" }) do
          vim.keymap.set(m, "af", function() ts_select.select_textobject("@function.outer", "textobjects") end)
          vim.keymap.set(m, "if", function() ts_select.select_textobject("@function.inner", "textobjects") end)
          vim.keymap.set(m, "ac", function() ts_select.select_textobject("@class.outer", "textobjects") end)
          vim.keymap.set(m, "ic", function() ts_select.select_textobject("@class.inner", "textobjects") end)
        end
      else
        -- 旧版 API（configs）
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
      end
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
            -- 网关 base_url 可能带尾斜杠；若直接用 "${url}/v1/messages" 会拼成 //v1/messages（404/200 错误路由），
            -- 这里先去掉尾斜杠，保证单斜杠 /v1/messages（真实端点，无鉴权时返回 401）。
            local base = os.getenv("ANTHROPIC_BASE_URL") or ""
            base = base:gsub("/+$", "")
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key = "ANTHROPIC_API_KEY",
              },
              url = base .. "/v1/messages",
              headers = {
                ["x-api-key"] = "${api_key}",
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
                      local name = strip_ctx(os.getenv(var))
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
        chat = {
          adapter = { name = "anthropic", model = cc_main_model },
          -- 默认加载文件工具组，AI 才能直接改/建/删文件（否则只聊天，无工具可用）
          tools = { opts = { default_tools = { "files" } } },
        },
        inline = { adapter = { name = "anthropic", model = cc_main_model } },
        background = { adapter = { name = "anthropic", model = cc_fast_model } },
      },
      -- 非代码文本回复用中文（system prompt 里的语言指令）
      opts = { language = "Chinese" },
    },
  },
}
