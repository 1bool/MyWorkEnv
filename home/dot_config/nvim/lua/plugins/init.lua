-- lazy.nvim 插件清单（全原生；语言工具走系统包）

return {
  -- ── 主题（默认 solarized8；其余立即加载不抢 colorscheme，<leader>sc 打开 themery 菜单切换） ──
  {
    "lifepillar/vim-solarized8",
    name = "solarized8",
    priority = 1000,
    config = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("solarized8")
    end,
  },
  { "catppuccin/nvim", name = "catppuccin", lazy = false },
  { "folke/tokyonight.nvim", name = "tokyonight", lazy = false },
  { "neanias/everforest-nvim", name = "everforest", lazy = false },
  { "ChrisMGeo/lagoon.nvim", name = "lagoon", lazy = false },
  { "calind/selenized.nvim", name = "selenized", lazy = false },
  { "navarasu/onedark.nvim", name = "onedark", lazy = false },
  { "NLKNguyen/papercolor-theme", name = "papercolor", lazy = false },

  -- ── 主题菜单 + 跟随系统（themery 管选择/持久化；auto-dark-mode 跟随系统 light/dark） ──
  {
    "zaldih/themery.nvim",
    lazy = false,
    keys = { { "<leader>sc", "<cmd>Themery<CR>", desc = "切换主题" } },
    config = function()
      require("themery").setup({
        themes = {
          "solarized8",
          { name = "papercolor", colorscheme = "PaperColor" },
          { name = "catppuccin", colorscheme = "catppuccin", before = [[ require("catppuccin").setup({ flavour = "auto" }) ]] },
          { name = "tokyonight", colorscheme = "tokyonight", before = [[ require("tokyonight").setup({ style = "night" }) ]] },
          "everforest",
          "lagoon",
          "selenized",
          { name = "onedark", colorscheme = "onedark", before = [[ require("onedark").setup({ style = "dark" }) ]] },
        },
        livePreview = true,
      })
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    opts = {
      -- 跟随系统：切 background 后重放当前 colorscheme（solarized8/catppuccin/tokyonight/
      -- everforest/selenized 都读 background 自动切 light/dark；lagoon 纯 dark 不受影响）
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", {})
        if vim.g.colors_name then pcall(vim.cmd, "colorscheme " .. vim.g.colors_name) end
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", {})
        if vim.g.colors_name then pcall(vim.cmd, "colorscheme " .. vim.g.colors_name) end
      end,
    },
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
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
          n = {
            ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous,
          },
        },
      },
    },
  },

  -- ── 符号大纲（右侧固定栏，类似 vim tagbar；可开关，默认不打开） ──
  {
    "stevearc/aerial.nvim",
    branch = vim.fn.has("nvim-0.12") == 1 and nil or "nvim-0.11", -- 仅旧版 nvim(<0.12，Ubuntu) 走 nvim-0.11 分支；0.12+（Windows/mac）用 master
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-web-devicons" },
    keys = {
      { "<leader>o", "<cmd>AerialToggle<CR>", desc = "符号大纲（右侧栏）" },
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
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "跳转" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "语法跳转" },
    },
    opts = {},
  },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },

  -- ── 终端 ──
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    cmd = "ToggleTerm",
    keys = {
      { "<leader>tt", "<cmd>ToggleTerm<CR>", desc = "开关终端" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<CR>", desc = "浮动终端" },
      { "<leader>th", "<cmd>ToggleTerm direction=horizontal<CR>", desc = "水平终端" },
    },
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<C-\>]],
        direction = "horizontal",
      })
    end,
  },

  -- ── 键位提示 ──
  { "folke/which-key.nvim", opts = {} },

  -- ── UI 增强 ──
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
    opts = {
      lsp = { override = { ["vim.lsp.util.convert_input_to_markdown_lines"] = true, ["vim.lsp.util.stylize_markdown"] = true } },
      presets = { bottom_search = true, command_palette = true, long_message_to_split = true },
    },
  },
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { options = { mode = "buffers" } },
  },

  -- ── 编辑增强 ──
  {
    "kevinhwang91/nvim-ufo",
    event = "VeryLazy",
    dependencies = { "kevinhwang91/promise-async" },
    opts = {
      provider_selector = function() return { "treesitter", "indent" } end,
    },
  },
  {
    "mbbill/undotree",
    keys = { { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "撤销树" } },
  },

  -- ── AI 助手（claudecode.nvim：Claude Code 官方 IDE 协议集成） ──
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    config = true,
    -- cmd 让 lazy.nvim 生成命令桩，:ClaudeCode* 在首次按键前即可用
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      { "<leader>c", nil, desc = "Claude Code" },
      { "<leader>cc", "<cmd>ClaudeCode<CR>", desc = "开关终端" },
      { "<leader>cf", "<cmd>ClaudeCodeFocus<CR>", desc = "聚焦/隐藏" },
      { "<leader>cr", "<cmd>ClaudeCode --resume<CR>", desc = "恢复会话" },
      { "<leader>cC", "<cmd>ClaudeCode --continue<CR>", desc = "继续会话" },
      { "<leader>cm", "<cmd>ClaudeCodeSelectModel<CR>", desc = "选择模型" },
      { "<leader>cb", "<cmd>ClaudeCodeAdd %<CR>", desc = "加入当前文件" },
      { "<leader>cs", "<cmd>ClaudeCodeSend<CR>", mode = "v", desc = "选区发给 Claude" },
      {
        "<leader>cs",
        "<cmd>ClaudeCodeTreeAdd<CR>",
        desc = "加入文件",
        ft = { "NvimTree", "neo-tree", "oil", "netrw" },
      },
      { "<leader>ca", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "接受 diff" },
      { "<leader>cd", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "拒绝 diff" },
    },
  },

  -- ── AI 助手（opencode.nvim：OpenCode 集成，<leader>a 系列） ──
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    config = function()
      -- 修复 opencode.nvim Windows 下 server discovery 用 vim.fn.json_decode 在 fast event 报 E5560（上游 bug）。
      -- 改成 vim.json.decode（Lua 版，允许 fast event 调用）；升级插件后此函数会重打补丁。
      local win_lua = vim.fn.stdpath("data") .. "/lazy/opencode.nvim/lua/opencode/server/discovery/process/windows.lua"
      local f = io.open(win_lua, "r")
      if f then
        local c = f:read("*a")
        f:close()
        if c:find("vim.fn.json_decode", 1, true) then
          local w = io.open(win_lua, "w")
          if w then w:write(c:gsub("vim.fn.json_decode", "vim.json.decode")) w:close() end
        end
      end
      vim.keymap.set({ "n", "x" }, "<leader>ai", function() require("opencode").ask("@this: ") end, { desc = "提问 OpenCode" })
      vim.keymap.set({ "n", "x" }, "<leader>as", function() require("opencode").select() end, { desc = "选择 OpenCode" })
      vim.keymap.set({ "n", "x" }, "<leader>ap", function() require("opencode").prompt() end, { desc = "提示 OpenCode" })
      vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end, { expr = true, desc = "追加范围到 OpenCode" })
    end,
  },

  -- ── AI 助手（editor-context：让 OpenCode agent 读取 nvim 光标/选区/诊断） ──
  {
    "talldan/opencode-nvim-editor-context",
    config = function()
      require("editor-context").setup()
    end,
  },
}
