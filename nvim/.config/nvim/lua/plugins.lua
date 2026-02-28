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
    "A7Lavinraj/fyler.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    branch = "stable", -- Use stable branch for production
    lazy = false,      -- Necessary for `default_explorer` to work properly
    opts = {
      views = {
        finder = {
          win = {
            kind = "float",
            kinds = {
              float = {
                height = "70%",
                width = "70%",
                top = "15%",
                left = "15%",
              },
            },
          },
        },
      },
    }
  },
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local configs = require("nvim-treesitter.config") -- Fixed the 's' here

      configs.setup({
        -- Added TSX, TypeScript, and JSON for React/Fullstack work
        ensure_installed = {
          "lua", "vim", "vimdoc", "python",
          "javascript", "typescript", "tsx", "html", "css", "json"
        },

        sync_install = false,
        auto_install = true,

        highlight = {
          enable = true,
          -- Python and React often have long files;
          -- this keeps Neovim fast by not highlighting huge files
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
        },

        indent = {
          enable = true, -- Crucial for Python's whitespace-sensitive syntax
        },

        -- Enable 'autotag' if you install the nvim-ts-autotag plugin
        -- It uses the Treesitter nodes to close your React <div> automatically
      })
    end
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      -- Your cmp setup code goes here
    end
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load for lua files
    opts = {},
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
  -- Treesitter context comment string
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    config = function()
      require('ts_context_commentstring').setup({
        enable_autocmd = false, -- Disable its autocommands because using Comment.nvim integration
      })
    end
  },
  -- Null-ls
  {
    "nvimtools/none-ls.nvim",
    config = function()
      require('config.null-ls')
    end,
    requires = { "nvim-lua/plenary.nvim" },
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
  -- Comments
  {
    'numToStr/Comment.nvim',
    config = function()
      require('config.comment')
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
      "LazyGitConfig",
      "LazyGitCurrentFile",
      "LazyGitFilter",
      "LazyGitFilterCurrentFile",
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
    lazy = false,

    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
        python = { "ruff" },
      }

      -- Helper function to find virtual environment
      local function get_python_path()
        -- Try to find project root
        local root_dir = vim.fs.dirname(vim.fs.find({ "pyproject.toml", "setup.py", ".git" }, {
          upward = true,
          path = vim.fn.expand("%:p:h")
        })[1])

        if root_dir then
          -- Check for common venv locations in project root
          local venv_paths = {
            ".venv/bin/python",
            "venv/bin/python",
            ".virtualenv/bin/python",
          }

          for _, venv_path in ipairs(venv_paths) do
            local full_path = root_dir .. "/" .. venv_path
            if vim.fn.executable(full_path) == 1 then
              return full_path
            end
          end

          -- Try poetry from project directory
          if vim.fn.filereadable(root_dir .. "/pyproject.toml") == 1 then
            local handle = io.popen("cd " .. vim.fn.shellescape(root_dir) .. " && poetry env info -p 2>/dev/null")
            if handle then
              local poetry_venv = handle:read("*a"):gsub("%s+", "")
              handle:close()
              if poetry_venv ~= "" and poetry_venv ~= "nil" then
                local python_path = poetry_venv .. "/bin/python"
                if vim.fn.executable(python_path) == 1 then
                  return python_path
                end
              end
            end
          end
        end

        -- Fallback to system python
        return "python3"
      end

      -- Configure ruff to use venv
      local function get_ruff_cmd()
        local python = get_python_path()
        local venv_dir = vim.fn.fnamemodify(python, ":h:h")
        local ruff_path = venv_dir .. "/bin/ruff"

        if vim.fn.executable(ruff_path) == 1 then
          return ruff_path
        else
          return "ruff"
        end
      end

      -- Override eslint to prefer local installation
      local eslint = lint.linters.eslint
      eslint.cmd = "eslint_d"

      -- Add args to make it use local config
      eslint.args = {
        "--format",
        "json",
        "--stdin",
        "--stdin-filename",
        function() return vim.api.nvim_buf_get_name(0) end,
      }

      -- vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      --   group = vim.api.nvim_create_augroup("LinterAutocmds", { clear = true }),
      --   callback = function()
      --     -- Try local node_modules eslint first
      --     local root_dir = vim.fs.dirname(vim.fs.find({ "package.json",
      --       ".eslintrc.js", ".eslintrc.json" }, {
      --       upward = true,
      --       path = vim.fn.expand("%:p:h")
      --     })[1])
      --
      --     if root_dir then
      --       local local_eslint = root_dir .. "/node_modules/.bin/eslint_d"
      --       if vim.fn.executable(local_eslint) == 1 then
      --         lint.linters.eslint.cmd = local_eslint
      --       end
      --     end
      --
      --     -- Set ruff to use venv for Python files
      --     if vim.bo.filetype == "python" then
      --       lint.linters.ruff.cmd = get_ruff_cmd()
      --     end
      --
      --     lint.try_lint()
      --   end,
      -- })
    end,
  },
  {
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeHide", "UndotreeFocus" },
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight-night'
    end
  }
})
