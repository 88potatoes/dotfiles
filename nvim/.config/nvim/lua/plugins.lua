-- Plugin setup with lazy.nvim

-- Bootstrap lazy.nvim if not installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

-- Set up plugins
require("lazy").setup({
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
    -- There's the notion of an 'Initialization Table'
    -- This 'opts' key automatically calls require("diffview").setup(opts)
    opts = {
      enhanced_diff_hl = true, -- Highly recommended for that GitHub look
      view = {
        merge_tool = {
          layout = "diff3_horizontal",
          disable_diagnostics = true,
        },
      },
      hooks = {
        diff_buf_read = function(bufnr)
          vim.opt_local.foldlevel = 99
          vim.keymap.set('n', ']]', ']c', { buffer = bufnr, desc = "Next Hunk" })
          vim.keymap.set('n', '[[', '[c', { buffer = bufnr, desc = "Prev Hunk" })
        end,
      },
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
        accept_suggestion = "<D-d>",
      }
    }
  },
  {
    "folke/trouble.nvim",
    opts = {}, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Diagnostics (Trouble)",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer Diagnostics (Trouble)",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "Symbols (Trouble)",
      },
      {
        "<leader>cl",
        "<cmd>lsp toggle focus=false win.position=right<cr>",
        desc = "LSP Definitions / references / ... (Trouble)",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Location List (Trouble)",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Quickfix List (Trouble)",
      },
    },
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
          },
          plain = {
            typescriptreact = [[console.log("===%insert_cursor")]],
          }
        },
        batch_log_templates = {
          default = {
            typescriptreact = [[console.log({ %repeat<"===%log_target": %log_target><, > })]],
          }
        }
      })
    end
  },
  { "chrisgrieser/nvim-spider", lazy = true },
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
      vim.diagnostic.config({ virtual_text = false })   -- Disable Neovim's default virtual text diagnostics
    end,
  }
})
