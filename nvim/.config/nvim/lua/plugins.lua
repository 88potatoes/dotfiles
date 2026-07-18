-- Plugin setup with lazy.nvim

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- Set up plugins
require("lazy").setup({
  -- Local dev plugins — remove `dir` to use the GitHub remote version
  {
    "88potatoes/agent-comments.nvim",
    dir = vim.fn.expand("~/Code/agent-comments.nvim"),
    config = function()
      require("agent-comments").setup()
    end,
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      picker = { enabled = true },
    },
  },
  {
    "mikavilpas/yazi.nvim",
    dependencies = {
      "folke/snacks.nvim"
    },
    keys = {
      {
        "<leader>ll",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
    },
    opts = {
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
    },
    init = function()
      vim.g.loaded_netrwPlugin = 1
    end,
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,
  },
  {
    'saghen/blink.cmp',
    version = "v1.9.0",
    opts = {
      keymap = {
        preset = 'none', -- The Notion of a Clean Slate
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' }, -- CR is the 'Enter' key
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
      completion = {
        menu = { border = 'rounded' },
        documentation = { window = { border = 'rounded' }, auto_show = true },
      },
    },
  },
  -- Mason
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate", -- :MasonUpdate updates registry contents
    config = function()
      require("config.lsp.init").setup()
    end,
  },
  -- Mason LSP Config
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "prismals" },
        automatic_installation = true,
        -- TS LSP is selected explicitly in lua/config/lsp/init.lua.
        -- Prevent mason-lspconfig from auto-starting vtsls/ts_ls beside tsgo.
        automatic_enable = {
          exclude = { "vtsls", "ts_ls" },
        },
      })
    end,
  },
  -- Surround
  {
    "kylechui/nvim-surround",
    version = "^3.0.0",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end
  },
  {
    "sindrets/diffview.nvim",
    opts = {
      file_panel = {
        win_config = {
          position = "left",
          width = 35,
        },
      },
      hooks = {
        diff_buf_win_enter = function(_, winid, _)
          -- Turn off cursor line for diffview windows because of bg conflict
          -- https://github.com/neovim/neovim/issues/9800
          vim.wo[winid].culopt = 'number'
        end,
      },
      enhanced_diff_hl = true,
    },
  },
  -- LazyGit
  {
    "kdheepak/lazygit.nvim",
    lazy = true,
    cmd = {
      "LazyGit",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  -- Supermaven
  {
    "supermaven-inc/supermaven-nvim",
    opts = {
      keymaps = {
        accept_suggestion = "<D-z>",
      }
    }
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost", "InsertLeave" }, -- The Notion of Lazy Events
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        python = { "ruff" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-night'

      -- -- Softer diff backgrounds for diffview
      -- vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1a2f1a" })
      -- vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#2f1a1a" })
      -- vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1a1a2f" })
      -- vim.api.nvim_set_hl(0, "DiffText", { bg = "#2a2a4f" })
    end
  },
  {
    'dmmulroy/ts-error-translator.nvim',
    config = function()
      require("ts-error-translator").setup({
        auto_attach = true,
        servers = {
          "vtsls",
        },
      })
    end
  },
  {
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("timber").setup({
        log_templates = {
          default = {
            typescriptreact = [[console.log("===%log_target", %log_target)]],
            tsx = [[console.log("===%log_target", %log_target)]],
            javascript = [[console.log("===%log_target", %log_target)]],
            typescript = [[console.log("===%log_target", %log_target)]],
          },
          plain = {
            typescriptreact = [[console.log("===%insert_cursor")]],
            tsx = [[console.log("===%insert_cursor")]],
            javascript = [[console.log("===$insert_cursor")]],
            typescript = [[console.log("===$insert_cursor")]],
          }
        },
        batch_log_templates = {
          default = {
            typescriptreact = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
            tsx = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
            javascript = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
            typescript = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
          }
        }
      })
    end
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    opts = {
      formatters_by_ft = {
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        lua = { "stylua" },
        python = { "ruff_format" },
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
  },
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup()
      vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
    end,
  },
  {
    "f-person/git-blame.nvim",
    -- load the plugin at startup
    event = "VeryLazy",
    -- Because of the keys part, you will be lazy loading this plugin.
    -- The plugin will only load once one of the keys is used.
    -- If you want to load the plugin at startup, add something like event = "VeryLazy",
    -- or lazy = false. One of both options will work.
    opts = {
      -- your configuration comes here
      -- for example
      enabled = true, -- if you want to enable the plugin
      message_template = " <summary> • <date> • <author> • <<sha>>", -- template for the blame message, check the Message template section for more options
      date_format = "%m-%d-%Y %H:%M:%S", -- template for the date, check Date format section for more options
      virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    },

  }
})
